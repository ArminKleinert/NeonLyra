require_relative 'types.rb'
require_relative 'env.rb'
require 'set'

LYRA_VERSION = "0_0_1"

def elem_to_s(e)
  if e == true
    "#t"
  elsif e == false
    "#f"
  elsif e.is_a? Array
    "[#{e.inject{|x,y| "#{elem_to_s(x)} #{elem_to_s(y)}"}}]"
  else
    e.to_s
  end
end

# Sets up the core functions and variables. The functions defined here are
# of the type NativeLyraFn instead of LyraFn. They can not make use of tail-
# recursion and are supposed to be very simple.
def setup_core_functions
  def add_fn(name, min_args, max_args = min_args, &body)
    fn = NativeLyraFn.new(name, min_args, max_args) do |args, env|
      body.call(*args.to_a)
    end
    Env.global_env.set!(name, fn)
  end

  def add_fn_with_env(name, min_args, max_args = min_args, &body)
    fn = NativeLyraFn.new(name, min_args, max_args, &body)
    Env.global_env.set!(name, fn)
  end

  def add_var(name, value)
    Env.global_env.set!(name, value)
  end

  add_fn(:cons, 2) { |x, y| cons(x, y) }
  add_fn(:car, 1) { |x| x.car }
  add_fn(:cdr, 1) { |x| x.cdr }

  # "Primitive" operators. They are overridden in the core library of
  # Lyra as `=`, `<`, `>`, ... and can be extended there later on for
  # different types.
  add_fn(:"=", 2) { |x, y| x == y }
  add_fn(:"/=", 2) { |x, y| x != y }
  add_fn(:"ref=", 2) { |x, y| x.object_id == y.object_id }
  add_fn(:"<", 2) { |x, y| x < y }
  add_fn(:">", 2) { |x, y| x > y }
  add_fn(:"+", 2) { |x, y| x + y }
  add_fn(:"-", 2) { |x, y| x - y }
  add_fn(:"*", 2) { |x, y| x * y }
  add_fn(:"/", 2) { |x, y| x / y }
  add_fn(:"rem", 2) { |x, y| x % y }
  add_fn(:"bit-and", 2) { |x, y| x & y }
  add_fn(:"bit-or", 2) { |x, y| x | y }
  add_fn(:"bit-xor", 2) { |x, y| x ^ y }
  add_fn(:"bit-shl", 2) { |x, y| x << y }
  add_fn(:"bit-shr", 2) { |x, y| x >> y }

  gensym_counter = 0
  add_fn(:gensym, 0) { "gensym_#{LYRA_VERSION}_#{gensym_counter += 1}".to_sym }
  add_fn(:seq, 1) { |x| (!x.is_a?(Enumerable) || x.empty?) ? nil : x.to_cons_list }

  add_fn(:"always-true", 0, -1) { |*xs| true }
  add_fn(:"always-false", 0, -1) { |*xs| false }

  add_fn(:box, 1) { |x| Box.new(x) }
  add_fn(:unbox, 2) { |b| b.value }
  add_fn(:unwrap, 2) { |b| b.value } # Intended for use with any boxing type
  add_fn(:"box-set!", 2) { |b, x| b.value = x; b }

  add_fn(:eager, 1) { |x| x.is_a?(LazyObj) ? x.evaluate : x }
  add_fn_with_env(:lazy, 1) { |xs,env| LazyObj.new xs.car, env }
  add_fn(:partial, 1) { |x, *params| params.empty? ? x : PartialLyraFn.new(x,params.to_cons_list) }

  add_fn(:nothing, 0, -1) { |*_| nil }

  add_fn(:"box?", 1) { |m| m.is_a? Box }
  add_fn(:"nothing?", 1) { |m| m.nil? || m.value.nil? }
  add_fn(:"nil?", 1) { |x| x.nil? }
  add_fn(:"null?", 1) { |x| x.nil? || x.is_a?(EmptyList) }
  add_fn(:"collection?", 1) { |x| x.is_a?(Enumerable) }
  add_fn(:"sequence?", 1) { |x| x.is_a?(List) || x.is_a?(Array) }
  add_fn(:"list?", 1) { |x| x.is_a? List }
  add_fn(:"vector?", 1) { |x| x.is_a? Array }
  add_fn(:"int?", 1) { |x| x.is_a? Integer }
  add_fn(:"float?", 1) { |x| x.is_a? Float }
  add_fn(:"number?", 1) { |x| x.is_a? Numeric }
  add_fn(:"string?", 1) { |x| x.is_a? String }
  add_fn(:"symbol?", 1) { |x| x.is_a? Symbol }
  add_fn(:"char?", 1) { |x| x.is_a?(String) && x.size == 1 }
  add_fn(:"boolean?", 1) { |x| x == true || x == false }
  add_fn(:"map?", 1) { |x| x.is_a? Hash }
  add_fn(:"set?", 1) { |x| x.is_a? Set }
  add_fn(:"empty?", 1) { |x| x.is_a?(Enumerable) && x.empty? }
  add_fn(:"function?", 1) { |x| x.is_a?(LyraFn) }

  add_fn(:id, 1) { |x| x }
  add_fn(:"id-fn", 1) { |x| NativeLyraFn.new("", 0) { x } }
  add_fn(:hash, 1) { |x| x.hash }
  add_fn(:"eq?", 2) { |x, y| x == y }

  add_fn(:symbol, 1) { |x| x.respond_to?(:to_sym) ? x.to_sym : nil }
  add_fn(:"->symbol", 1) { |x| x.respond_to?(:to_sym) ? x.to_sym : nil }
  add_fn(:"->int", 1) { |x|
    begin
      Integer(x || "");
    rescue ArgumentError
      nil
    end }
  add_fn(:"->float", 1) { |x|
    begin
      Float(x || "");
    rescue ArgumentError
      nil
    end }
  add_fn(:"->string", 1) { |x| elem_to_s x }
  add_fn(:"->bool", 1) { |x| !!x }
  add_fn(:"->list", 1) { |x| x.is_a?(Enumerable) ? x.to_cons_list : nil }
  add_fn(:"->vector", 1) { |x| x.is_a?(Enumerable) ? x.to_a : nil }
  add_fn(:"->char", 1) { |x| (x.is_a?(Integer)) ? x.chr : nil }
  add_fn(:"->map", 1) { |x| Hash[*x] }
  add_fn(:"->set", 1) { |x| Set[*x] }

  add_fn(:"vector", 0, -1) { |*xs| xs }
  add_fn(:"vector-size", 1) { |xs| xs.size }
  add_fn(:"vector-nth", 2) { |xs, i| xs[i] }
  add_fn(:"vector-add", 2) { |xs, y| xs + [y] }
  add_fn(:"vector-append", 2) { |xs, ys| xs + ys }

  add_fn(:"map-of", 0, -1) { |*xs| xs.to_h }
  add_fn(:"map-size", 1) { |m| m.size }
  add_fn(:"map-get", 2) { |m, k| m[k] }
  add_fn(:"map-set", 3) { |m, k, v| m2 = Hash[m]; m2[k, v]; m2 }
  add_fn(:"map-remove", 2) { |m, k| m.select { |k1, v| k != k1 } }
  add_fn(:"map-keys", 1) { |m| m.keys }
  add_fn(:"map-merge", 2) { |m, m2| Hash[m].merge!(m2) }
  
  add_fn(:size, 1) { |c| c.is_a?(Enumerable) ? c.size : nil }
  
  add_fn(:first, 1) {|c| c.is_a?(Enumerable) ? (c.is_a?(List) ? c.car : c[0]) : nil }
  add_fn(:rest, 1) {|c| c.is_a?(Enumerable) ? (c.is_a?(List) ? c.cdr : c[1..-1]) : nil }
  add_fn(:last, 1) {|c| c.is_a?(Enumerable) ? c[c.size-1] : nil }
  add_fn(:"but-last", 1) {|c| c.is_a?(Enumerable) ? c[0 .. -2] : nil }
  add_fn(:nth, 1) {|c,i| c.is_a?(Enumerable) ? c[i] : nil }

  add_fn(:append, 2) {|x,y| x+y} # TODO Checks etc.

  add_fn(:"println!", 1) { |x| puts elem_to_s(x) }
  
  add_fn(:copy, 1) {|x| x.is_a?(Box) ? x.clone : x }

  add_var(:Nothing, nil)

  true
end
