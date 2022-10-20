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
    raise LyraError.new("Function not found: #{f}")
  else
    specific = f.inner[type_name]
    if specific.nil?
      raise LyraError.new("No candidate on function #{f} with type #{type_name}.") unless f.fallback
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
    FUNC_MAP[func_name] = entry
  end

  entry.inner[type_name] = implementation
end

def def_generic_fn(func_name, fallback)
  entry = FuncMapEntry.new fallback, {}
  raise LyraError.new("Function #{func_name} is already defined.") if FUNC_MAP.include? func_name
  FUNC_MAP[func_name] = entry
end

NOTHING_TYPE = TypeName.new "::nothing", 0
BOOL_TYPE = TypeName.new "::bool", 1
VECTOR_TYPE = TypeName.new "::vector", 2
MAP_TYPE = TypeName.new "::map", 3
LIST_TYPE = TypeName.new "::list", 4
FUNCTION_TYPE = TypeName.new "::function", 5
INTEGER_TYPE = TypeName.new "::integer", 6
FLOAT_TYPE = TypeName.new "::float", 7
SET_TYPE = TypeName.new "::set", 8
TYPE_NAME_TYPE = TypeName.new "::typename", 9
STRING_TYPE = TypeName.new "::string", 10
SYMBOL_TYPE = TypeName.new "::symbol", 11
BOX_TYPE = TypeName.new "::box", 12
RATIO_TYPE = TypeName.new "::rational", 13
ERROR_TYPE = TypeName.new "::error", 14
CHAR_TYPE = TypeName.new "::char", 15
KEYWORD_TYPE = TypeName.new "::keyword", 16
#ALIAS_TYPE = TypeName.new "::alias", 17
DELAY_TYPE = TypeName.new "::delay", 18

def type_of(x)
  if x.nil?
    NOTHING_TYPE
  elsif !!x == x
    BOOL_TYPE
  elsif x.is_a? LyraChar
    CHAR_TYPE
  elsif x.is_a? Symbol
    SYMBOL_TYPE
  elsif x.is_a? LyraType
    x.name
  elsif x.is_a? Array
    VECTOR_TYPE
  elsif x.is_a? String
    STRING_TYPE
  elsif x.is_a? Hash
    MAP_TYPE
  elsif x.is_a? ConsList
    LIST_TYPE
  elsif x.is_a? LyraFn
    FUNCTION_TYPE
  elsif x.is_a? Integer
    INTEGER_TYPE
  elsif x.is_a? Float
    FLOAT_TYPE
  elsif x.is_a? Rational
    RATIO_TYPE
  elsif x.is_a? Set
    SET_TYPE
  elsif x.is_a? Box
    BOX_TYPE
  elsif x.is_a? TypeName
    TYPE_NAME_TYPE
  elsif x.is_a? LyraError
    ERROR_TYPE
  elsif x.is_a? Keyword
    KEYWORD_TYPE
#  elsif x.is_a? Alias
#    ALIAS_TYPE
  elsif x.is_a? LyraDelay
    DELAY_TYPE
  else
    raise LyraError.new("No name for type #{x.class} for object #{elem_to_s(x)}")
  end
end

def type_id_of(x)
  type_of(x).type_id
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
    lyra_eq?(y, x)
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
    "[#{e.map { |x| elem_to_s(x) }.join(" ")}]"
  elsif e.is_a? Hash
    "{" + e.map { |k, v| "#{elem_to_s(k)} #{elem_to_s(v)}" }.join(" ") + "}"
  elsif e.is_a? Set
    '#{' + "#{e.map { |x| elem_to_s(x) }.join(" ")}}"
  else
    e.to_s
  end
end

def elem_to_pretty(e)
  if e == true
    "true"
  elsif e == false
    "false"
  elsif e.nil?
    "nil"
  elsif e.is_a? List
    "(#{e.map { |x| elem_to_pretty(x) }.join(" ")})"
  elsif e.is_a? Array
    "[#{e.map { |x| elem_to_pretty(x) }.join(" ")}]"
  elsif e.is_a? Hash
    "{" + e.map { |k, v| "#{elem_to_pretty(k)} #{elem_to_pretty(v)}" }.join(" ") + "}"
  elsif e.is_a? Set
    '#{' + e.map { |x| elem_to_pretty(x) }.join(" ") + '}'
  elsif e.is_a? Symbol
    e.to_s
  else
    e.inspect
  end
end

def eager(x)
  x.is_a?(Lazy) ? x.evaluate : x
end

def lyra_buildin_eq?(x, y)
  atom?(x) && atom?(y) ? x == y : x.object_id == y.object_id
end

GENSYM_CNT = [0]

def gensym(x)
  "gen_sym_#{x}_#{GENSYM_CNT[0] += 1}".to_sym
end

def div(x, y)
  if atom?(x) && atom?(y)
    if y == 0
      (0.0 / 0.0) # NaN
    else
      x / y
    end
  else
    nil
  end
end

def rem(x, y)
  if atom?(x) && atom?(y)
    if y == 0
      (0.0 / 0.0) # NaN
    else
      x % y
    end
  else
    nil
  end
end

def truthy?(x)
  (x != false && !x.nil? && !x.is_a?(EmptyList))
end

def string_to_chars(s)
  s.is_a?(String) ? s.chars.map { |c| LyraChar.conv(c) || "\0" } : nil
end

def apply_op_to_list(xs, &op)
  unless xs.empty?
    until xs.size <= 1
      x = xs[0]
      y = xs[1]
      xs = xs[1..-1]

      unless yield(x, y)
        return false
      end
    end
  end
  true
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

  add_fn_with_env(:delay, 1, 1) do |f, env|
    if f.car.is_a? LyraFn
      LyraDelay.new(Thread.new{eval_ly(f, env)})
    else
      raise LyraError.new("Invalid call to delay. Expected a function, but got #{elem_to_pretty(f)}", :"invalid-call")
    end
  end

  add_fn(:"delay-timeout", 2) do |timeout, d|
    d.with_timeout timeout
  end

  add_fn(:"list-size", 1) { |x| cons?(x) ? x.size : (raise LyraError.new("Invalid call to list-size.", :"invalid-call")) }
  add_fn(:cons, 2) { |x, xs| cons(x, xs) }
  add_fn(:car, 1) { |x| cons?(x) ? x.car : (raise LyraError.new("Invalid call to car. Got #{x}.", :"invalid-call")) }
  add_fn(:cdr, 1) { |x| cons?(x) ? x.cdr : (raise LyraError.new("Invalid call to cdr. Got #{x}.", :"invalid-call")) }

  add_fn(:"list-concat", 0, -1) { |*xs| list_append *xs }

  add_fn(:"not", 1) { |x| !(truthy? x) }

  # "Primitive" operators. They are overridden in the core library of
  # Lyra as `=`, `<`, `>`, ... and can be extended there later on for
  # different types.
  add_fn(:"=", 1, -1) { |*xs| apply_op_to_list(xs, &method(:lyra_buildin_eq?)) }
  add_fn(:"/=", 1, -1) { |*xs| !apply_op_to_list(xs, &method(:lyra_buildin_eq?)) }
  add_fn(:"ref=", 2) { |x, y| x.object_id == y.object_id }
  add_fn(:"<", 1, -1) { |*xs| apply_op_to_list(xs, &:<) }
  add_fn(:">", 1, -1) { |*xs| apply_op_to_list(xs, &:>) }
  add_fn(:"<=", 1, -1) { |*xs| apply_op_to_list(xs, &:<=) }
  add_fn(:">=", 1, -1) { |*xs| apply_op_to_list(xs, &:>=) }
  add_fn(:"+", 1, -1) { |*xs| xs.inject(&:+) }
  add_fn(:"-", 1, -1) { |*xs| xs.size == 1 ? -xs[0] : xs.inject(&:-) }
  add_fn(:"*", 1, -1) { |*xs| xs.inject(&:*) }
  add_fn(:"/", 1, -1) { |*xs| xs.inject{|x,y| div(x,y)} }
  add_fn(:"rem", 1, -1) { |*xs| xs.inject{|x,y| rem(x,y)} }
  add_fn(:"bit-and", 2) { |x, y| (x.is_a?(Integer) && y.is_a?(Integer)) ? x & y : nil }
  add_fn(:"bit-or", 2) { |x, y| (x.is_a?(Integer) && y.is_a?(Integer)) ? x | y : nil }
  add_fn(:"bit-xor", 2) { |x, y| (x.is_a?(Integer) && y.is_a?(Integer)) ? x ^ y : nil }
  add_fn(:"bit-shl", 2) { |x, y| (x.is_a?(Integer) && y.is_a?(Integer)) ? x << y : nil }
  add_fn(:"bit-shr", 2) { |x, y| (x.is_a?(Integer) && y.is_a?(Integer)) ? x >> y : nil }
  add_fn(:abs, 1) { |x| x.is_a?(Numeric) ? x.abs : x }

  add_fn(:numerator, 1) { |x| x.is_a?(Rational) ? x.numerator : x }
  add_fn(:denominator, 1) { |x| x.is_a?(Rational) ? x.denominator : 1 }

  add_fn(:gensym, 1) { |x| gensym(x) }
  add_fn(:seq, 1) { |x| (!x.is_a?(Enumerable) || x.empty?) ? nil : x.to_cons_list }

  add_fn(:"always-true", 0, -1) { |*_| true }
  add_fn(:"always-false", 0, -1) { |*_| false }

  add_fn(:box, 1) { |x| Box.new(x) }
  add_fn(:unbox, 1) { |b| b.is_a?(Unwrapable) ? b.value : nil }
  add_fn(:"buildin-unwrap", 1) { |b|
    b.is_a?(Unwrapable) ? b.unwrap : b } # Intended for use with any boxing type
  add_fn(:"box-set!", 2) { |b, x| b.value = x; b }

  add_fn(:eager, 1) { |x| eager x }
  add_fn(:evaluated?, 1) { |x| x.executed }
  #add_fn_with_env(:lazy, 1) { |xs, env| LazyObj.new xs.car, env }
  add_fn(:partial, 1, -1) { |x, *params| params.empty? ? x : PartialLyraFn.new(x, params.to_cons_list) }

  add_fn(:nothing, 0, -1) { |*_| nil }

  add_fn(:"buildin-take", 2) do |n, xs|
    if xs.empty? || n == 0
      list
    elsif xs.is_a?(ConsList)
      ys = []
      until xs.empty? || n == 0
        ys << xs.car
        xs = xs.cdr
        n -= 1
      end
      ys.to_cons_list
    else
      xs.to_a[0...n].to_cons_list
    end
  end

  add_fn(:"atom?", 1) { |x| atom?(x) }

  add_fn_with_env(:"defined?", 1) { |x, env| env.safe_find(x.car) != NOT_FOUND_IN_LYRA_ENV }
  add_fn(:"box?", 1) { |m| m.is_a? Box }
  add_fn(:"nothing?", 1) { |m| m.nil? }
  add_fn(:"nil?", 1) { |x| x.nil? }
  add_fn(:"null?", 1) { |x| x.nil? || x.is_a?(EmptyList) }
  add_fn(:"list?", 1) { |x| x.is_a? ConsList }
  add_fn(:"buildin-vector?", 1) { |x| x.is_a? Array }
  add_fn(:"int?", 1) { |x| x.is_a? Integer }
  add_fn(:"float?", 1) { |x| x.is_a? Float }
  add_fn(:"rational?", 1) { |x| x.is_a? Rational }
  add_fn(:"buildin-string?", 1) { |x| x.is_a? String }
  add_fn(:"symbol?", 1) { |x| x.is_a? Symbol }
  add_fn(:"char?", 1) { |x| x.is_a?(LyraChar) }
  add_fn(:"boolean?", 1) { |x| (!!x) == x }
  add_fn(:"map?", 1) { |x| x.is_a? Hash }
  add_fn(:"buildin-set?", 1) { |x| x.is_a? Set }
  add_fn(:"function?", 1) { |x| x.is_a?(LyraFn) }
  add_fn(:"lazy?", 1) { |x| x.is_a?(Lazy) }
  add_fn(:"lazy-obj?", 1) { |x| x.is_a?(LazyObj) }
  add_fn(:"keyword?", 1) { |x| x.is_a?(Keyword) }

  add_fn(:"keyword-name", 1) { |x| x.is_a?(Keyword) ? x.to_sym : nil }

  add_fn(:id, 1) { |x| x }
  add_fn(:hash, 1) { |x| x.hash }
  #add_fn(:"eq?", 2) { |x, y| lyra_eq?(x, y) }

  # Can be bootstrapped.
  #add_fn_with_env(:"all?", 2) { |x, env| x.cdr.car.to_a.all?{|e|truthy?(eval_ly(x.car,env,true)) } }
  #add_fn_with_env(:"none?", 2) { |x, env| !x.cdr.car.to_a.any?{|e|!truthy?(eval_ly(x.car,env,true)) } }
  #add_fn_with_env(:"any?", 2) { |x, env| x.cdr.car.to_a.any?{|e|truthy?(eval_ly(x.car,env,true)) } }

  add_fn(:"buildin->symbol", 1) { |x| x.respond_to?(:to_sym) ? x.to_sym : nil }
  add_fn(:"buildin->int", 1) { |x|
    begin
      Integer(x || "");
    rescue ArgumentError, TypeError
      nil
    end }
  add_fn(:"buildin->float", 1) { |x|
    begin
      Float(x || "");
    rescue ArgumentError, TypeError
      nil
    end }
  add_fn(:"buildin->rational", 1) do |x|
    if x.is_a?(String) && x.size == 0
      nil
    else
      begin
        Rational(x);
      rescue ArgumentError, TypeError
        nil
      end
    end
  end
  add_fn(:"buildin->string", 1) { |x| elem_to_s x }
  add_fn(:"buildin->pretty-string", 1) { |x| elem_to_pretty x }
  add_fn(:"buildin->keyword", 1) { |x| x.respond_to?(:to_sym) ? Keyword.create(x) : nil }
  add_fn(:"buildin->bool", 1) { |x| !(x.nil? || x == false || (x.is_a?(EmptyList))) }
  add_fn(:"buildin->list", 1) { |x| x.is_a?(Enumerable) ? x.to_cons_list : nil }
  add_fn(:"buildin->vector", 1) { |x| x.is_a?(Enumerable) ? x.to_a : nil }
  add_fn(:"buildin->char", 1) { |x| LyraChar.conv(x) }
  add_fn(:"buildin->map", 1) { |x| x.is_a?(Enumerable) ? Hash[*x] : nil }
  add_fn(:"buildin->set", 1) { |x| x.is_a?(Enumerable) ? Set[*x] : nil }
  
  add_fn(:"buildin-vector", 0, -1) { |*xs| xs }
  add_fn(:"buildin-vector-size", 1) { |xs| xs.size }
  add_fn(:"buildin-vector-range", 3) { |s, e, xs| r = xs[s...e]; r.nil? ? [] : r }
  add_fn(:"buildin-vector-nth", 2) { |xs, i| xs[i] }
  add_fn(:"buildin-vector-add", 2) { |xs, y| xs + [y] }
  add_fn(:"buildin-vector-append", 2) { |xs, ys| (xs.nil? || ys.nil?) ? nil : xs + ys }
  add_fn(:"buildin-vector-includes?", 2) { |xs, ys| xs.include? ys }
  add_fn(:"buildin-vector-eq?", 2) { |v, v1| v == v1 }

  add_fn(:"buildin-string-size", 1) { |xs| xs.size }
  add_fn(:"buildin-string-range", 3) { |s, e, xs| r = xs[s...e]; r.nil? ? [] : r }
  add_fn(:"buildin-string-nth", 2) { |xs, i| xs[i] }
  add_fn(:"buildin-string-add", 2) { |xs, y| xs + y.to_s }
  add_fn(:"buildin-string-append", 2) { |xs, ys| (xs.nil? || ys.nil?) ? nil : xs + ys.to_s }
  add_fn(:"buildin-string-includes?", 2) { |xs, ys| xs.include? ys }
  add_fn(:"buildin-string-eq?", 2) { |v, v1| v == v1 }
  add_fn(:"buildin-string-split-at", 2) { |s, pat| s.split(pat) }
  add_fn(:"buildin-string-chars", 1) { |s| string_to_chars(s) }

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
      temp = list(acc, x, i)
      break unless pred.call(temp, env)
      acc = func.call(temp, env)
    end
    acc
  end

  add_fn(:"map-of", 0, -1) { |*xs| xs.each_slice(2).to_a.to_h }
  add_fn(:"map-size", 1) { |m| m.size }
  add_fn(:"map-get", 2) { |m, k| m.is_a?(Hash) ? m[k] : raise("#{m} is not a map.") }
  add_fn(:"map-set", 3) { |m, k, v| m2 = Hash[m]; m2[k] = v; m2 }
  add_fn(:"map-remove", 2) { |m, k| m.select { |k1, _| k != k1 } }
  add_fn(:"map-keys", 1) { |m| m.keys }
  add_fn(:"map-merge", 2) { |m, m2| Hash[m].merge!(m2) }
  add_fn(:"map-has-key?", 2) { |m, k| m.has_key? k }
  add_fn(:"map-has-value?", 2) { |m, v| m.has_value? v }
  add_fn(:"map-entries", 1) { |m| m.to_a }
  add_fn(:"map->vector", 1) { |m| m.to_a }
  add_fn(:"map-eq?", 2) { |m, m1| m == m1 }

  add_fn(:"buildin-set-of", 0, -1) { |*xs| xs.to_set }
  add_fn(:"buildin-set-size", 1) { |s| s.size }
  add_fn(:"buildin-set-add", 2) { |s, e| s.add e }
  add_fn(:"buildin-set-union", 2) { |s0, s1| s0 | s1 }
  add_fn(:"buildin-set-difference", 2) { |s0, s1| s0 - s1 }
  add_fn(:"buildin-set-intersection", 2) { |s0, s1| s0 & s1 }
  add_fn(:"buildin-set-includes?", 2) { |s, e| s.include? e }
  add_fn(:"buildin-set-subset?", 2) { |s0, s1| s0 <= s1 }
  add_fn(:"buildin-set-true-subset?", 2) { |s0, s1| s0 < s1 }
  add_fn(:"buildin-set-superset?", 2) { |s0, s1| s0 >= s1 }
  add_fn(:"buildin-set-true-superset?", 2) { |s0, s1| s0 > s1 }
  add_fn(:"buildin-set->vector", 1) { |s| s.to_a }
  add_fn(:"buildin-set-eq?", 2) { |s, s1| s == s1 }

  def foldr(f, v, xs, env)
    xs.to_a.reverse_each do |e|
      v = f.call(list(e, v), env)
    end
    v
  end

  add_fn_with_env(:"buildin-foldr", 3) do |args, env|
    f = args.car
    v = args.cdr.car
    xs = args.cdr.cdr.car
    foldr(f, v, xs, env)
  end

  add_fn_with_env(:"buildin-foldl", 3) do |args, env|
    f = args.car
    v = args.cdr.car
    xs = args.cdr.cdr.car
    xs.each do |x|
      v = f.call(list(v, x), env)
    end
    v
  end

  add_fn(:"buildin-contains?", 2) { |c, e| c.include? e }

  add_fn(:"buildin-nth", 2) { |c, i| c.is_a?(Enumerable) ? c[i] : nil }

  add_fn(:"buildin-strcat", 2) { |s, e| s.to_s + elem_to_s(e) }

  add_fn(:"buildin-append", 2) do |x, y|
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

  add_fn(:"buildin-print!", 1) { |x| print elem_to_s(x) }
  add_fn(:"readln!", 0) { gets }
  add_fn(:"file-read!", 1) { |name| IO.read name }
  add_fn(:"file-write!", 2) { |name, text| IO.write name, text }
  add_fn(:"file-append!", 2) { |name, text| File.open(name, 'a') { |f| f.write(text) } }

  add_fn(:copy, 1) { |x| x.is_a?(Box) ? x.clone : x }

  add_fn(:memoize, 1) { |fn| MemoizedLyraFn.new fn }

  add_var(:Nothing, nil)

  add_fn_with_env(:"load!", 1) do |xs, env|
    file = xs.car
    prefix = xs.cdr.car
    eval_str(IO.read(file), Env.global_env)
  end

  add_fn_with_env(:"import!", 2) do |xs, env|
    mod_name = xs.car.to_sym
    alias_name = xs.cdr.car

    mod = IMPORTED_MODULES.lazy

    if mod.respond_to?(:filter)
      mod = mod.filter{|e|e.name == mod_name}.to_a.first
    else
      # select is an older version of filter. It forces the creation of an array and does not preserve  the lazyness of the Enumerable.
      mod = mod.select{|e|e.name == mod_name}.first
    end

    if !mod.nil?
      binds = mod.bindings
      ttt = []
      binds.each do |bind1|
        bind = bind1.to_s.split("/", 2)[-1]
        bind = if alias_name.empty?
          bind.to_sym
        else
          (alias_name + "/" + bind).to_sym
        end
        ttt << bind

        env.next_module_env.set! bind, Env.global_env.find(bind1)
        #puts "#{alias_name} #{alias_name.empty?} #{bind1} #{bind}"
      end

      list(mod.name, mod.abstract_name)
    else
      nil
    end
  end

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

  add_fn_with_env(:"measure!", 2) { |args, env|
    median = lambda do |arr|
      arr.sort!
      len = arr.size
      (arr[(len - 1) / 2] + arr[len / 2]) / 2
    end

    runs = args.car
    f = args.cdr.car
    res = Array.new(runs)
    runs.times do |i|
      t0 = Time.now
      f.call(list, env)
      t1 = Time.now
      res[i] = (t1 - t0) * 1000.0
    end
    median.call(res) }

  add_fn(:sqrt, 1) { |n| Math.sqrt(n) }

  add_fn(:ljust, 2) { |x, n| elem_to_s(x).ljust(n) }

  add_fn_with_env(:"apply-to", 2) { |xs, env| first(xs).call(second(xs).force, env) }

  [NOTHING_TYPE, BOOL_TYPE, VECTOR_TYPE, MAP_TYPE, LIST_TYPE, FUNCTION_TYPE,
   INTEGER_TYPE, FLOAT_TYPE, RATIO_TYPE, SET_TYPE, TYPE_NAME_TYPE, STRING_TYPE,
   SYMBOL_TYPE, BOX_TYPE, ERROR_TYPE, CHAR_TYPE, KEYWORD_TYPE,
   DELAY_TYPE].each do |t|
    add_var t.to_sym, t
  end

  add_fn_with_env(:"class", 1) { |x, _| type_of(x.car) }

  add_fn(:"error!", 1, 3) { |msg, info, trace| raise LyraError.new(msg, info, trace) }

  add_fn(:"error-msg", 1) { |e| e.msg }
  add_fn(:"error-info", 1) { |e| e.info }
  add_fn(:"error-trace", 1) { |e| e.trace }

  add_fn(:"exit!", 1) { |s| exit(s) }

  add_fn(:"callstack", 0) { LYRA_CALL_STACK }
  true
end
