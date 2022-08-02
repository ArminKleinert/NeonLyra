#!/usr/bin/env ruby
# frozen_string_literal: true

require 'singleton'
require 'set'

class LyraModule
  attr_reader :name, :abstract_name, :bindings
  def initialize(name, abstract_name, bindings)
    @name, @abstract_name, @bindings = name, abstract_name, bindings
  end
end

class LyraError < StandardError
  attr_reader :info, :internal_trace

  def initialize(msg, info = :error, trace = nil)
    @info = info
    if trace.nil?
      @internal_trace = LYRA_CALL_STACK
    else
      @internal_trace = trace
    end
    super(msg)
  end
end

module Unwrapable
end

module Lazy
end

module Enumerable
  def to_cons_list
    if is_a?(ConsList)
      self
    else
      list(*to_a)
    end
  end
end

module ConsList
  include Enumerable

  def each
    lst = self
    until lst.empty?
      yield lst.car
      lst = lst.cdr
    end
    self
  end
  
  def index(o)
    lst = self
    idx = 0
    lst.each do |e|
      if o == e
        return idx
      end
      idx += 1
    end
    -1
  end

  def each_with_index
    lst = self
    i = 0
    until lst.empty?
      yield lst.car, i
      lst = lst.cdr
      i += 1
    end
    self
  end

  def to_s
    "(#{inject { |x, y| "#{elem_to_s(x)} #{elem_to_s(y)}" }})"
  end

  def inspect
    "(#{inject("") { |x, y| "#{x} #{elem_to_pretty(y)}" }[1..-1]})"
  end

  def nth(i)
    self[i]
  end

  def [](i)
    if i.is_a? Integer
      if i >= size
        nil
      elsif i < 0
        nil
      else
        each do |e|
          if i == 0
            return e
          end
          i -= 1
        end
        raise "Should never happen."
      end
    else
      # if i is a range
      list(*to_a[i])
    end
  end

  def nth_rest(i)
    c = self
    while !c.empty? && i > 0
      i -= 1
      c = c.cdr
    end
    if c.empty?
      nil
    else
      c
    end
  end

  def +(c)
    list_append self, c
  end

  def ==(c)
    if c.is_a? ConsList
      c0 = self
      until c0.empty? || c.empty?
        return false if c0.car != c.car
        c0 = c0.cdr
        c = c.cdr
      end
      # If both lists are empty and all elements were equal to far, then the lists must be equal
      c0.empty? && c.empty?
    else
      false
    end
  end

  def force
    each do
    end
  end
end

class EmptyList
  include Singleton, Enumerable, ConsList

  def car
    nil
  end

  def cdr
    self
  end

  def empty?
    true
  end

  def size
    0
  end
end

class List
  include Enumerable, ConsList

  def initialize(head, tail, size)
    @car = head
    @cdr = tail
    @size = size
  end

  def car
    @car
  end

  def cdr
    if @cdr.is_a?(LyraFn)
      temp = @cdr.call(list, nil)
      unless temp.is_a?(ConsList) || temp.is_a?(Proc)
        raise LyraError.new("Tail must be a list but is #{temp}.", :"illegal-argument")
      end
      @cdr = temp
    end
    @cdr
  end

  def size
    if @size == -1
      # Tail was lazy, so calculate its size
      force # force evaluation
      @size = cdr.size + 1
    end
    @size
  end

  # ONLY PROVIDED FOR THE EVALUATION FUNCTION!!!
  def set_car!(c)
    @car = c
  end

  # ONLY PROVIDED FOR THE EVALUATION FUNCTION!!!
  def set_cdr!(tail)
    @cdr = tail
    force
    @size = tail.size + 1
  end

  def self.create(head, tail)
    if tail.is_a? LazyList
      List.send :new, head, tail, -1
    elsif tail.is_a? ConsList
      List.send :new, head, tail, tail.size + 1
    elsif tail.is_a? LyraFn
      List.send :new, head, tail, -1
    else
      raise LyraError.new("Illegal cdr.", :"illegal-argument")
    end
  end

  private_class_method :new

  def empty?
    false
  end
end

def list_append(*lists)
  lists = lists.delete_if(&:empty?)
  if lists.empty?
    EmptyList.instance
  else
    lists.map(&:to_cons_list).inject { |l0, l1| ListPair.new(l0, l1) }
  end
end

class ListPair
  include Enumerable, ConsList

  def initialize(list0, list1)
    @list0 = list0
    @list1 = list1
  end

  def car
    @list0.car
  end

  def cdr
    list_append @list0.cdr, @list1
  end

  # ONLY PROVIDED FOR THE EVALUATION FUNCTION!!!
  def set_car!(c)
    @list0.set_car! c
  end

  # ONLY PROVIDED FOR THE EVALUATION FUNCTION!!!
  def set_cdr!(tail)
    @list1 = EmptyList.instance
    @list0.set_cdr! tail
  end

  def size
    @list0.size + @list1.size
  end

  def empty?
    @list0.empty? && @list1.empty?
  end

  def each(&block)
    @list0.each(&block)
    @list1.each(&block)
    self
  end

  def compact
    l0 = @list0.is_a?(ListPair) ? @list0.compact : @list0
    l1 = @list1.is_a?(ListPair) ? @list1.compact : @list1
    l0 = l0.to_a
    l0.reverse_each do |e|
      l1 = cons(e, l1)
    end
    l1
  end
end

class LazyList
  include Enumerable, ConsList, Lazy

  def initialize(head, tail_fn)
    @car = head
    @cdr_or_tail_fn = tail_fn
    @tail_evaluated = false
  end

  def car
    @car
  end

  def cdr
    if @tail_evaluated
      @cdr_or_tail_fn
    else
      temp = @cdr_or_tail_fn.call
      unless temp.is_a?(ConsList) || temp.is_a?(Proc)
        raise LyraError.new("Tail must be a list but is #{temp}.", :"illegal-argument")
      end
      @cdr_or_tail_fn = temp
      @tail_evaluated = true
      @cdr_or_tail_fn
    end
  end

  def size
    cdr.size + 1
  end

  def evaluate
    each do
    end
    self
  end

  def self.create(head, tail_fn)
    LazyList.send :new, head, tail_fn
  end

  private_class_method :new

  def empty?
    false
  end
end

def cons(e, l)
  if l.is_a?(ConsList)
    List.create(e, l)
  elsif l.is_a?(LyraFn)
    List.create(e, l)
  else
    raise LyraError.new("Tail must be a list but is #{l}.", :"illegal-argument")
  end
end

def cons?(l)
  l.respond_to?(:car) && l.respond_to?(:cdr)
end

def list(*args)
  if args.empty?
    EmptyList.instance
  else
    lst = EmptyList.instance
    args.reverse_each do |e|
      lst = cons e, lst
    end
    lst
  end
end

def car(e)
  if e.respond_to?(:car) 
    e.car
  else
    EmptyList.instance
  end
end

def cdr(e)
  if e.respond_to?(:cdr) 
    e.cdr
  else
    EmptyList.instance
  end
end

class Box
  include Unwrapable
  attr_accessor :value

  def initialize(value)
    @value = value
  end

  def to_s
    "(box #{elem_to_pretty(@value)})"
  end

  def unwrap
    @value
  end
end

# Convenience functions.
def first(c)
  c.car
end

def second(c)
  c.cdr.car
end

def third(c)
  c.cdr.cdr.car
end

def fourth(c)
  c.cdr.cdr.cdr.car
end

def rest(c)
  c.cdr
end

# Thrown when a tail-call should be done.
class TailCall < StandardError
  attr_reader :args

  def initialize(args)
    @args = args
  end
end

# Parent for both native and user-defined functions.
class LyraFn
  def apply_to(args, env)
    call(args, env)
  end
end

class LazyObj < LyraFn
  include Lazy

  attr_reader :expr, :executed

  def initialize(expr, env)
    @expr, @env = expr, env
    @executed = false
  end

  def evaluate
    if @executed
      @expr
    else
      @expr = eval_ly(@expr, @env, true)
      @executed = true
      @expr
    end
  end

  def to_s
    "(lazy #{elem_to_s(expr)})"
  end

  def inspect
    to_s
  end

  def native?
    true
  end

  def pure?
    true
  end

  def is_macro
    true
  end

  def name
    to_s
  end

  def call(_, _)
    evaluate
  end

  def arg_counts
    0..0
  end
end

class LazyLyraFn < Proc
  def self.create(f, env)
    LazyLyraFn.new { |args|
      if args.nil?
        args = EmptyList.instance
      end
      f.call(args, env) }
  end
end

# A Lyra-function. It knows its argument-count (minimum and maximum),
# body (the executable function), name and whether it is a macro or not.
class CompoundFunc < LyraFn
  attr_reader :args_expr
  attr_reader :arg_counts # Range of (minimum .. maximum)
  attr_accessor :name # Symbol
  attr_reader :is_macro # Boolean

  def initialize(name, args_expr, body_expr, definition_env, is_macro, min_args, max_args = min_args, is_hash_lambda = false)
    @args_expr = args_expr
    @body_expr = body_expr
    @definition_env = definition_env
    @arg_counts = (min_args..max_args)
    @name = name.to_sym
    @is_macro = is_macro
    @is_hash_lambda = is_hash_lambda
  end

  def call(args, env)
    # Check argument counts
    args_given = args.size
    raise LyraError.new("#{@name}: Too few arguments. (Given #{args_given}, expected #{@arg_counts})", :arity) if args_given < arg_counts.first
    raise LyraError.new("#{@name}: Too many arguments. (Given #{args_given}, expected #{@arg_counts})", :arity) if arg_counts.last >= 0 && args_given > arg_counts.last

    begin
      env1 = Env.new(nil, @definition_env, env).set!(:"*current-function*", @name).set!(@name, self)
      if @is_hash_lambda
        env1.set_multi_anonymous! args
      else
        env1.set_multi!(@args_expr, args, @arg_counts.last < 0)
      end

      # Execute the body and return
      #body.call(args, env1)
      eval_keep_last(@body_expr, env1)
    rescue TailCall => tail_call
      unless native?
        # Do a tail-call. (Thanks for providing `retry`, Ruby!)
        args = tail_call.args
        retry
      end
    rescue
      #$stderr.puts "#{@name} failed with error: #{$!}"
      #$stderr.puts "Arguments: #{args}"
      raise
    end
  end

  def to_s
    "<#{@is_macro ? "macro" : "function"} #{@name}>"
  end

  def inspect
    to_s
  end

  def native?
    false
  end

  def pure?
    @name[-1] != "!"
  end
end

class NativeLyraFn < LyraFn
  attr_reader :arg_counts # Range of (minimum .. maximum)
  attr_reader :name # Symbol
  attr_reader :body # Executable (Any[] -> Any)

  def initialize(name, min_args, max_args = min_args, &body)
    @arg_counts = (min_args..max_args)
    @body = body
    @name = name.to_s.freeze
  end

  def call(args, env)
    # Check argument counts
    args_given = args.size
    raise LyraError.new("#{@name}: Too few arguments. (Given #{args_given}, expected #{@arg_counts})", :arity) if args_given < @arg_counts.first
    raise LyraError.new("#{@name}: Too many arguments. (Given #{args_given}, expected #{@arg_counts})", :arity) if @arg_counts.last >= 0 && args_given > @arg_counts.last

    begin
      # Execute the body and return
      body.call(args, env)
    rescue
      #$stderr.puts "#{@name} failed with error: #{$!}"
      #$stderr.puts "Arguments: #{args}"
      raise
    end
  end

  def to_s
    "<function #{@name}>"
  end

  def inspect
    to_s
  end

  def native?
    true
  end

  def is_macro
    false
  end

  def pure?
    @name[-1] != "!"
  end
end

class PartialLyraFn < LyraFn

  def initialize(func, args)
    @func, @args = func, args
    @name = func.name
  end

  def call(args, env)
    @func.call(@args + args, env)
  end

  def to_s
    cons(:partial, cons(@func, @args)).to_s
  end

  def name
    to_s
  end

  def native?
    @func.native?
  end

  def pure?
    @func.pure?
  end

  def is_macro
    @func.is_macro
  end
end

class MemoizedLyraFn < LyraFn
  def initialize(func)
    @func = func
    @memory = {}
  end

  def call(args, env)
    lookup = args.size == 1 ? args.car : args
    prev = @memory[lookup]
    if prev
      prev
    else
      res = @func.call(args, env)
      @memory[lookup] = res
      res
    end
  end

  def to_s
    @func.to_s
  end

  def native?
    @func.native?
  end

  def pure?
    @func.pure?
  end

  def is_macro
    @func.is_macro
  end

  def name
    @func.name
  end
end

class GenericFn < LyraFn
  attr_reader :name

  def initialize(name, _, anchor_idx, fallback)
    @implementations = []
    @fallback = fallback
    @name, @anchor_idx = name.to_s.freeze, anchor_idx
  end

  def call(args, env)
    # Potential for speedup?
    type = type_id_of(args[@anchor_idx])
    fn = @implementations[type]

    begin
      if fn
        LYRA_CALL_STACK.push fn
        res = fn.call args, env
        LYRA_CALL_STACK.pop
      else
        LYRA_CALL_STACK.push @fallback
        res = @fallback.call args, env
        LYRA_CALL_STACK.pop
      end
    rescue
      #$stderr.puts "#{@name} failed with error: #{$!}"
      #$stderr.puts "Arguments: #{args}"
      raise
    end
    res
  end

  def to_s
    "<function #{@name}>"
  end

  def native?
    false
  end

  def pure?
    @name[-1] != "!"
  end

  def is_macro
    false
  end

  def add_implementation!(type, impl)
    if @implementations[type.type_id]
      raise LyraError.new("#{@name} is already defined for type #{type}.", :reimplementation)
    else
      @implementations[type.type_id] = impl
    end
  end
end

class WrappedLyraError
  attr_reader :msg, :info, :trace

  def initialize(msg, info, trace = nil)
    @msg, @info, @trace = msg, info, trace
    if trace
      @trace = LYRA_CALL_STACK.clone
    end
  end
end

class TypeName
  attr_reader :name, :type_id

  def initialize(name, type_id)
    @name, @type_id = name.to_sym, type_id
    @name.freeze
  end

  def to_s
    @name.to_s
  end

  def to_sym
    @name.to_sym
  end
end

def atom?(x)
  x.is_a?(Numeric) || x.is_a?(String) || x.is_a?(Symbol) || !!x == x || x.is_a?(LazyObj) || x.is_a?(LyraChar) || x.is_a?(Keyword) || x.is_a?(LyraFn)
end

class LyraDelay
    include Lazy, Unwrapable
  
  def initialize(thread)
    @thread = thread
  end
  
  # if the thread is alive, return nil
  # otherwise, return its value
  def unbox
    @thread.alive? ? nil : @thread.value
  end
  
  def value
    unbox
  end
  
  # Eagerly run the thread with no timeout
  # if the thread fails (with an error), return the error
  # otherwise, return the value
  def evaluate
    v = @thread.value
    if v.is_a?(Exception)
      WrappedLyraError.new v.message, :thread
    else
      v
    end
  end
  
  # Wait `seconds` seconds before killing the thread
  # (if necessary) and getting its value
  def with_timeout(seconds)
    @thread.join(seconds)
    if @thread.alive?
      sleep seconds
    end
    if @thread.alive?
      @thread.kill
    end
    @thread.value
  end
end

class LyraChar
  attr_reader :chr

  def self.conv(s)
    if s.is_a?(LyraChar)
      s
    elsif s.is_a?(String) || s.is_a?(Integer)
      LyraChar.new(s)
    else
      nil
    end
  end

  def initialize(s)
    if s.is_a?(String)
      @chr = s.size == 0 ? 0.chr : s[0]
    elsif s.is_a?(Integer)
      @chr = s.chr
    else
      raise "Illegal argument type for LyraChar.new: #{s.class}"
    end
  end

  def to_i
    ord
  end

  def to_s
    @chr
  end

  def inspect
    '\\' + @chr
  end

  def ord
    @chr.ord
  end

  def ==(other)
    if other.is_a?(LyraChar)
      @chr == other.chr
    else
      false
    end
  end

  def eql?(other)
    if other.is_a?(LyraChar)
      @chr.eql?(other.chr)
    else
      false
    end
  end

  def hash
    @chr.hash
  end
end

KEYWORDS = Hash.new

class Keyword < LyraFn
  attr_reader :name

  def initialize(name)
    @name = name
  end

  def self.create(name)
    name = name.to_sym
    res = KEYWORDS[name]
    if res.nil?
      res = Keyword.new(name)
      KEYWORDS[name] = res
    else
      res
    end
  end

  def ==(other)
    if other.is_a?(Keyword)
      @name == other.name
    else
      false
    end
  end

  def eql?(other)
    self == other
  end

  def to_s
    @name.inspect
  end

  def inspect
    @name.inspect
  end

  def to_sym
    @name
  end

  def hash
    @name.hash
  end

  def call(args, env)
    if args.size != 1
      raise LyraError.new("#{@name}: Keyword can only be called on 1 argument.", :arity)
    end
    env.safe_find("get").call(list(args[0], self), env)
  end

  def native?
    true
  end

  def pure?
    true
  end

  def is_macro
    false
  end
end

class LyraType
  include Unwrapable

  attr_reader :name, :type_id, :attrs

  def initialize(type_id, name, attrs)
    @type_id, @name, @attrs = type_id, name, attrs
    @attrs.freeze
  end

  def to_s
    "[LyraType #{@type_id} #{@name} attrs=#{@attrs.to_s}]"
  end

  def inspect
    to_s
  end

  def unwrap
    @attrs
  end
end

LYRA_TYPE_COUNTER = Box.new 20

def new_lyra_type(name, attrs, env)
  attrs = attrs.to_a
  counter = LYRA_TYPE_COUNTER.value
  t = TypeName.new(:"::#{name}", counter)
  env.set! :"make-#{name}", NativeLyraFn.new(:"make-#{name}", attrs.size) { |params, _| LyraType.new(counter, t, params.to_a) }
  env.set! :"#{name}?", NativeLyraFn.new(:"#{name}?", 1) { |o, _| o.car.is_a?(LyraType) && o.car.type_id == counter }
  env.set! :"unwrap-#{name}", NativeLyraFn.new(:"unwrap-#{name}", 1) { |o, _| o.attrs }

  attrs.each_with_index do |attr, i|
    fn_name = :"#{name}-#{attr}"
    env.set! fn_name, NativeLyraFn.new(fn_name, 1) { |e, _| e.car.attrs[i] }
  end
  env.set! t.to_sym, t

  LYRA_TYPE_COUNTER.value = LYRA_TYPE_COUNTER.value + 1

  name
end
