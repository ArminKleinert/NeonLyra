#!/usr/bin/env ruby
# frozen_string_literal: true

require 'singleton'

class LazyObj
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
    elem_to_s(evaluate)
  end
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
    to_s
  end

  def nth(i)
    if i >= size
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
  end

  def [](i)
    if i.is_a? Integer
      nth(i)
    else
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
    res = c.to_cons_list
    to_a.reverse_each do |e|
      res = cons(e, res)
    end
    res
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
    @cdr
  end

  def size
    @size
  end

  # ONLY PROVIDED FOR THE EVALUATION FUNCTION!!!
  def set_car!(c)
    @car = c
  end

  # ONLY PROVIDED FOR THE EVALUATION FUNCTION!!!
  def set_cdr!(tail)
    @cdr = tail
    @size = tail.size + 1
  end

  def self.create(head, tail)
    raise "Illegal cdr" unless tail.is_a? ConsList
    List.send :new, head, tail, tail.size + 1
  end

  private_class_method :new

  def empty?
    false
  end
end

def cons(e, l)
  raise "Tail must be a list." unless l.is_a?(ConsList)
  List.create(e, l)
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
  e.is_a?(ConsList) ? e.car : EmptyList.instance
end

def cdr(e)
  e.is_a?(ConsList) ? e.cdr : EmptyList.instance
end

Box = Struct.new(:value) do
  def to_s
    "(box #{elem_to_s(value)})"
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

# A Lyra-function. It knows its argument-count (minimum and maximum),
# body (the executable function), name and whether it is a macro or not.
class CompoundFunc < LyraFn
  attr_reader :arg_counts # Range of (minimum .. maximum)
  attr_reader :body # Executable ((List<Any>, Env) -> Any)
  attr_accessor :name # Symbol
  attr_reader :is_macro # Boolean

  def initialize(name, definition_env, is_macro, min_args, max_args = min_args, &body)
    @definition_env = definition_env
    @arg_counts = (min_args..max_args)
    @body = body
    @name = name.to_s.freeze
    @is_macro = is_macro
  end

  def name=(n)
    @name = n.to_s.freeze
  end

  def call(args, env)
    # Check argument counts
    args_given = args.size
    raise "#{@name}: Too few arguments. (Given #{args_given}, expected #{@arg_counts})" if args_given < arg_counts.first
    raise "#{@name}: Too many arguments. (Given #{args_given}, expected #{@arg_counts})" if arg_counts.last >= 0 && args_given > arg_counts.last

    begin
      # Execute the body and return
      body.call(args, env)
    rescue TailCall => tail_call
      unless native?
        # Do a tail-call. (Thanks for providing `retry`, Ruby!)
        args = tail_call.args
        retry
      end
    rescue
      $stderr.puts "#{@name} failed with error: #{$!}"
      $stderr.puts "Arguments: #{args}"
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
    # TODO
    !@name.end_with?("!")
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
    raise "#{@name}: Too few arguments. (Given #{args_given}, expected #{@arg_counts})" if args_given < @arg_counts.first
    raise "#{@name}: Too many arguments. (Given #{args_given}, expected #{@arg_counts})" if @arg_counts.last >= 0 && args_given > @arg_counts.last

    begin
      # Execute the body and return
      body.call(args, env)
    rescue
      $stderr.puts "#{@name} failed with error: #{$!}"
      $stderr.puts "Arguments: #{args}"
      raise
    end
  end

  def to_s
    "<function #{@name}>"
  end

  def native?
    true
  end

  def is_macro
    false
  end

  def pure?
    !@name.end_with?("!")
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
end

class GenericFn < LyraFn
  attr_reader :name
  
  def initialize(name, args, anchor_idx, fallback)
    @implementations = []
    @fallback = fallback
    @name, @anchor_idx = name.to_s.freeze, anchor_idx
  end

  def call(args, env)
    # Potential for speedup?
    type = type_id_of(args[@anchor_idx])
    fn = @implementations[type]
    #puts "#{@name} #{@anchor_idx} #{@implementations.keys} #{args.map{|e|type_name_of(e)}} #{type} #{@implementations.has_key?(type)} #{@implementations[type]} #{@implementations.default}"
    if fn
      fn.call args, env
    else
      @fallback.call args,env
    end
  end

  def to_s
    "<function #{@name}>"
  end

  def native?
    false
  end

  def pure?
    !@name.end_with?("!")
  end

  def is_macro
    false
  end

  def add_implementation!(type, impl)
    # TODO Check redifinition
    @implementations[type.type_id] = impl
  end
end

class TypeName
  attr_reader :name, :type_id
  def initialize(name,type_id)
    @name ,@type_id= name.to_sym,type_id
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
  x.is_a?(Numeric) || x.is_a?(String) || x.is_a?(Symbol) || !!x == x || x.is_a?(LyraType) || x.is_a?(Box) || x.is_a?(LazyObj)
end

class LyraType
  attr_reader :name,:type_id,:attrs
  def initialize(type_id,name,attrs)
    @type_id,@name,@attrs = type_id,name,attrs
    @attrs.freeze
  end
end

LYRA_TYPE_COUNTER = Box.new 20

def new_lyra_type(name, attrs, env)
  attrs = attrs.to_a
  counter = LYRA_TYPE_COUNTER.value
  t = TypeName.new(("::"+name).to_sym,counter)
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
