#!/usr/bin/env ruby
# frozen_string_literal: true

require_relative 'types.rb'
require_relative 'env.rb'
require 'set'

FUNC_MAP = {}
FuncMapEntry = Struct.new :fallback, :inner

def find_fn(func_name, type_name)
  f = FUNC_MAP[func_name]
  if f.nil?
    raise "Function not found: #{f}"
  else
    specific = f.inner[type_name]
    if specific.nil?
      raise "No candidate on function #{f} with type #{type_name}." unless f.fallback
      f.fallback
    else
      specific
    end
  end
end

def add_fn(func_name, type_name, implementation)
  entry = FUNC_MAP[func_name]
  unless entry
    entry = FuncMapEntry.new nil, {}
    FUNC_MAP[func_name] = FuncMapEntry.new nil, {}
  end

  entry.inner[type_name] = implementation
end

def def_generic_fn(func_name, fallback)
  entry = FuncMapEntry.new fallback,{}
  raise "Function #{func_name} is already defined." if FUNC_MAP.include? func_name
  FUNC_MAP[func_name] = entry
end

def type_name_of (x)
  case x.class
  when NilClass
    "::nothing"
  when TrueClass, FalseClass
    "::bool"
  when LyraType
    "::" + x.name
  when Array
    "::vector"
  else
    "::" + x.class.to_s.downcase
  end
end

def lyra_eq?(x, y)
  if atom?(x) && atom?(y)
    x == y
  elsif x.is_a?(Enumerable)
    if y.is_a?(Enumerable)
      if x.class == y.class
        x == y
      else
        x.to_a == y.to_a
      end
    elsif y.is_a?(LyraType)
      x.to_a == y.attrs
    else
      false
    end
  elsif y.is_a?(Enumerable)
    lyra_eq?(y,x)
  else
    x == y
  end
end

def elem_to_s(e)
  if e == true
    "#t"
  elsif e == false
    "#f"
  elsif e.nil?
    ""
  elsif e.is_a? Array
    "[#{e.map { |x| elem_to_s(x)}.join(" ")}]"
  elsif e.is_a? Hash
    "Map[" + e.map{|k,v| "#{elem_to_s(k)} #{elem_to_s(v)}"}.join(" , ") + "]"
  elsif e.is_a? Set
    "Set[#{e.map { |x| elem_to_s(x)}.join(" ")}]"
  else
    e.to_s
  end
end

def eager(x)
  x.is_a?(LazyObj) ? x.evaluate : x
end

# Sets up the core functions and variables. The functions defined here are
# of the type NativeLyraFn instead of LyraFn. They can not make use of tail-
# recursion and are supposed to be very simple.
def setup_core_functions
  def add_fn(name, min_args, max_args = min_args, &body)
    fn = NativeLyraFn.new(name, min_args, max_args) do |args, _|
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

  add_fn(:"list-size", 1) { |x| x.size }
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
  add_fn(:"<=", 2) { |x, y| x <= y }
  add_fn(:">=", 2) { |x, y| x >= y }
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

  gen_sym_counter = 0
  add_fn(:gensym, 0) { "gen_sym_#{LYRA_VERSION}_#{gen_sym_counter += 1}".to_sym }
  add_fn(:seq, 1) { |x| (!x.is_a?(Enumerable) || x.empty?) ? nil : x.to_cons_list }

  add_fn(:"always-true", 0, -1) { |*_| true }
  add_fn(:"always-false", 0, -1) { |*_| false }

  add_fn(:box, 1) { |x| Box.new(x) }
  add_fn(:unbox, 1) { |b| b.value }
  add_fn(:unwrap, 1) { |b| b.value } # Intended for use with any boxing type
  add_fn(:"box-set!", 2) { |b, x| b.value = x; b }

  add_fn(:eager, 1) { |x| eager x }
  #add_fn_with_env(:lazy, 1) { |xs, env| LazyObj.new xs.car, env }
  add_fn(:partial, 1, -1) { |x, *params| params.empty? ? x : PartialLyraFn.new(x, params.to_cons_list) }

  add_fn(:nothing, 0, -1) { |*_| nil }

  add_fn_with_env(:"defined?", 1) { |x, env| env.safe_find(x.car) != NOT_FOUND_IN_LYRA_ENV }
  add_fn(:"box?", 1) { |m| m.is_a? Box }
  add_fn(:"nothing?", 1) { |m| m.nil? }
  add_fn(:"nil?", 1) { |x| x.nil? }
  add_fn(:"null?", 1) { |x| x.nil? || x.is_a?(EmptyList) }
  add_fn(:"collection?", 1) { |x| x.is_a?(Enumerable) }
  add_fn(:"sequence?", 1) { |x| x.is_a?(ConsList) || x.is_a?(Array) }
  add_fn(:"list?", 1) { |x| x.is_a? ConsList }
  add_fn(:"vector?", 1) { |x| x.is_a? Array }
  add_fn(:"int?", 1) { |x| x.is_a? Integer }
  add_fn(:"float?", 1) { |x| x.is_a? Float }
  add_fn(:"number?", 1) { |x| x.is_a? Numeric }
  add_fn(:"string?", 1) { |x| x.is_a? String }
  add_fn(:"symbol?", 1) { |x| x.is_a? Symbol }
  add_fn(:"char?", 1) { |x| x.is_a?(String) && x.size == 1 }
  add_fn(:"boolean?", 1) { |x| (!!x) == x }
  add_fn(:"map?", 1) { |x| x.is_a? Hash }
  add_fn(:"set?", 1) { |x| x.is_a? Set }
  add_fn(:"empty?", 1) { |x| x.is_a?(Enumerable) && x.empty? }
  add_fn(:"function?", 1) { |x| x.is_a?(LyraFn) }

  add_fn(:id, 1) { |x| x }
  add_fn(:"id-fn", 1) { |x| NativeLyraFn.new("", 0) { x } }
  add_fn(:hash, 1) { |x| x.hash }
  add_fn(:"eq?", 2) { |x, y| lyra_eq?(x, y) }

  add_fn(:symbol, 1) { |x| x.respond_to?(:to_sym) ? x.to_sym : nil }
  add_fn(:"->symbol", 1) { |x| x.respond_to?(:to_sym) ? x.to_sym : nil }
  add_fn(:"->int", 1) { |x|
    begin
      Integer(x || "");
    rescue ArgumentError, TypeError
      nil
    end }
  add_fn(:"->float", 1) { |x|
    begin
      Float(x || "");
    rescue ArgumentError, TypeError
      nil
    end }
  add_fn(:"->string", 1) { |x| elem_to_s x }
  add_fn(:"->bool", 1) { |x| !(x.nil? || x == false || (x.is_a?(EmptyList))) }
  add_fn(:"->list", 1) { |x| x.is_a?(Enumerable) ? x.to_cons_list : nil }
  add_fn(:"->vector", 1) { |x| x.is_a?(Enumerable) ? x.to_a : nil }
  add_fn(:"->char", 1) { |x| (x.is_a?(Integer)) ? x.chr : nil }
  add_fn(:"->map", 1) { |x| x.is_a?(Enumerable) ? Hash[*x] : nil }
  add_fn(:"->set", 1) { |x| x.is_a?(Enumerable) ? Set[*x] : nil }

  add_fn(:"vector", 0, -1) { |*xs| xs }
  add_fn(:"vector-size", 1) { |xs| xs.size }
  add_fn(:"vector-nth", 2) { |xs, i| xs[i] }
  add_fn(:"vector-add", 2) { |xs, y| xs + [y] }
  add_fn(:"vector-append", 2) { |xs, ys| xs + ys }
  add_fn(:"vector-includes?", 2) { |xs, ys| xs.include? ys }

  add_fn_with_env(:"iterate-seq", 3) do |xs, env|
    func, acc, vec = xs.to_a
    vec.each_with_index do |x, i|
      acc = func.call(list(acc, x, i), env)
    end
    acc
  end
  add_fn_with_env(:"iterate-seq-p", 4) do |xs, env|
    pred, func, acc, vec = xs.to_a
    vec.each_with_index do |x, i|
      break unless pred.call(list(acc, x, i), env)
      acc = func.call(list(acc, x, i), env)
    end
    acc
  end

  add_fn(:"map-of", 0, -1) { |*xs| xs.to_h }
  add_fn(:"map-size", 1) { |m| m.size }
  add_fn(:"map-get", 2) { |m, k| m[k] }
  add_fn(:"map-set", 3) { |m, k, v| m2 = Hash[m]; m2[k] = v; m2 }
  add_fn(:"map-remove", 2) { |m, k| m.select { |k1, _| k != k1 } }
  add_fn(:"map-keys", 1) { |m| m.keys }
  add_fn(:"map-merge", 2) { |m, m2| Hash[m].merge!(m2) }
  add_fn(:"map-has-key?",2) { |m,k| m.has_key? k}
  add_fn(:"map-has-value?",2) { |m,v| m.has_value? v}
  add_fn(:"map-entries",1) { |m| m.to_a}

  add_fn(:"set-of", 0,-1) { |*xs| xs.to_set}
  add_fn(:"set-size",1) { |s| s.size}
  add_fn(:"set-add", 2) { |s, e| s.add e }
  add_fn(:"set-union",2) { |s0,s1| s0 | s1}
  add_fn(:"set-difference",2) { |s0,s1| s0 - s1}
  add_fn(:"set-intersection",2) { |s0,s1| s0 & s1}
  add_fn(:"set-includes?", 2) { |s, e| s.include? e }
  add_fn(:"set-subset?", 2) { |s0, s1| s0 <= s1 }
  add_fn(:"set-true-subset?", 2) { |s0, s1| s0 < s1 }
  add_fn(:"set-superset?", 2) { |s0, s1| s0 >= s1 }
  add_fn(:"set-true-superset?", 2) { |s0, s1| s0 > s1 }

  add_fn(:size, 1) { |c| c.is_a?(Enumerable) ? c.size : nil }
  add_fn(:"contains?", 2) { |c, e| c.include? e }

  add_fn(:first, 1) { |c|
    if c.is_a?(Enumerable)
      c.is_a?(List) ? c.car : c[0]
    else
      nil
    end }
  add_fn(:rest, 1) { |c|
    if c.is_a?(Enumerable)
      if c.is_a?(List)
        c.cdr
      else
        c.empty? ? c : c.to_a[1..-1]
      end
    else
      nil
    end }
  add_fn(:last, 1) { |c| c.is_a?(Enumerable) ? c[c.size - 1] : nil }
  add_fn(:"but-last", 1) { |c| c.is_a?(Enumerable) ? c[0..-2] : nil }
  add_fn(:nth, 1) { |c, i| c.is_a?(Enumerable) ? c[i] : nil }

  add_fn(:append, 2) do |x, y|
    if x.is_a? String
      x + elem_to_s(y)
    elsif !x.is_a?(Enumerable) || !y.is_a?(Enumerable)
      nil
    elsif x.is_a? List
      x + y
    elsif x.is_a? Array
      x + y.to_a
    else
      x.to_cons_list + y.to_cons_list
    end
  end

  add_fn(:"print!", 1) { |x| print elem_to_s(x) }
  add_fn(:"println!", 1) { |x| puts elem_to_s(x) }
  add_fn(:"readln!", 0) { gets }
  add_fn(:"file-read!", 1) { |name| IO.read name }
  add_fn(:"file-write!", 2) { |name, text| IO.write name, text }
  add_fn(:"file-append!", 2) { |name, text| File.open(name, 'a') { |f| f.write(text) } }

  add_fn(:copy, 1) { |x| x.is_a?(Box) ? x.clone : x }

  add_fn(:memoize, 1) { |fn| MemoizedLyraFn.new fn }

  add_var(:Nothing, nil)

  add_fn(:load!, 1) { |file| eval_file(file, Env.global_env) }
  add_fn(:"read-string", 1) do |s|
    tokens = tokenize(s)
    ast = make_ast(tokens)
    if tokens[0] == "(" && ast.size > 1
      ast
    else
      ast[0]
    end
  end
  add_fn_with_env(:"eval!", 1) { |x, env| eval_ly first(x), env }

  add_var(:"very-long-list", (0...5).to_a)

  add_fn_with_env(:"measure!", 2) { |args, env|
    median = lambda do |arr|
      arr.sort!
      len = arr.size
      (arr[(len - 1) / 2] + arr[len / 2]) / 2
    end

    res = []
    args.car.times do
      t0 = Time.now
      args.cdr.car.call(list, env)
      t1 = Time.now
      res << (t1 - t0) * 1000.0
    end
    median.call(res) }

  # This is here to register it as a function and make it possible to remove it later.
  add_fn(:quote, 1) { |_| raise "quote must not be called as a function." }

  add_fn(:typename, 1) { |x| type_name_of(x) }

  add_fn(:ljust, 2) { |x, n| elem_to_s(x).ljust(n) }

  true
end
