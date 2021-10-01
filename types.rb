
require 'singleton'

class EmptyList
  include Singleton, Enumerable
  
  def car
    self
  end
  def cdr
    self
  end
  def to_s
    "()"
  end
  def each(&block)
    self
  end
  def empty?
    true
  end
  def inspect
    to_s
  end
  def size
    0
  end
end

class List
  include Enumerable

  attr_reader :size
  attr_reader :car
  attr_reader :cdr

  def initialize(head, tail, size)
    @car = head
    @cdr = tail
    @size = size
  end
  
  def self.create(head,tail)
    List.send :new, head, (tail ? tail : EmptyList.instance), (tail ? tail.size : 0) + 1
  end
  
  private_class_method :new
  
  def self.empty_list
    EmptyList.instance
  end
  
  def empty?
    false
  end
  
  def each(&block)
    lst = self
    until lst.empty?
      yield lst.car
      lst = lst.cdr
    end
    self
  end

  def to_s
    s = ""
    each do |e|
      s << e.to_s
      s << " "
    end
    "(" + s[0 .. -2] + ")"
  end
  
  def inspect
    to_s
  end
end

def cons(e, l)
  List.create(e, l ? l : EmptyList.instance)
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
  e.is_a?(List) ? e.car : EmptyList.instance
end

def cdr(e)
  e.is_a?(List) ? e.cdr : EmptyList.instance
end

Box = Struct.new(:value) do
  def to_s
    "(box #{value.to_s})"
  end
end

# Convenience functions.
def first(c); c.car; end
def second(c); c.cdr.car; end
def third(c); c.cdr.cdr.car; end
def fourth(c); c.cdr.cdr.cdr.car; end
def rest(c); c.cdr; end

# Thrown when a tail-call should be done.
class TailCall < StandardError
  attr_reader :args
  def initialize(args)
    @args = args
  end
end

# Parent for both native and user-defined functions.
class LyraFn
end

# A Lyra-function. It knows its argument-count (minimum and maximum),
# body (the executable function), name and whether it is a macro or not.
class CompoundFunc < LyraFn
  attr_reader :arg_counts # Range of (minimum .. maximum)
  attr_reader :body # Executable ((List<Any>, Env) -> Any)
  attr_accessor :name # Symbol
  attr_reader :ismacro # Boolean
  
  def initialize(name, definition_env, ismacro, min_args, max_args=min_args, &body)
    @definition_env = definition_env
    @arg_counts = (min_args .. max_args)
    @body = body
    @name = name
    @ismacro = ismacro
  end
  
  def call(args, env)
    # Check argument counts
    args_given = args.size
    raise "#{@name}: Too few arguments. (Given #{args_given}, expected #{@arg_counts})" if args_given < arg_counts.first
    raise "#{@name}: Too many arguments. (Given #{args_given}, expected #{@arg_counts})" if arg_counts.last >= 0 && args_given > arg_counts.last
    
    begin
      # Execute the body and return
      body.call(args, env)
    rescue TailCall => tailcall
      unless native?
        # Do a tail-call. (Thanks for providing `retry`, Ruby!)
        args = tailcall.args
        retry
      end
    rescue
      $stderr.puts "#{@name} failed with error: #{$!}"
      $stderr.puts "Arguments: #{args}"
      raise
    end
  end
  
  def to_s
    "<#{@ismacro ? "macro" : "function"} #{@name}>"
  end
  
  def native?
    false
  end
  
  def pure?
    # TODO
    false
  end
end

class NativeLyraFn
  attr_reader :arg_counts # Range of (minimum .. maximum)
  attr_accessor :name # Symbol
  attr_reader :body # Executable (Any[] -> Any)
  
  def initialize(name, min_args, max_args=min_args, &body)
    @arg_counts = (min_args .. max_args)
    @body = body
    @name = name
  end
  
  def call(args)
    # Check argument counts
    args_given = args.size
    raise "#{@name}: Too few arguments. (Given #{args_given}, expected #{@arg_counts})" if args_given < @arg_counts.first
    raise "#{@name}: Too many arguments. (Given #{args_given}, expected #{@arg_counts})" if @arg_counts.last >= 0 && args_given > @arg_counts.last
    
    begin
      # Execute the body and return
      body.call(args)
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
  
  def pure?
    name.end_with? "!"
  end
end

module Enumerable
  def to_cons_list
    if is_a?(List) || is_a?(EmptyList)
      self
    else
      list(*to_a)
    end
  end
end

def atom?(x)
  x.is_a?(Numeric) || x.is_a?(String) || x.is_a?(Symbol) || true == x || false == x
end

LyraType = Struct.new(:type_id, :name, :attrs) do
  def to_s
    "#{attrs.inject("(#{name}") {|x,y| "#{x} #{elem_to_s(y)}"}})"
  end
end

LYRA_TYPE_COUNTER = Box.new 0xEA7C0FFE

def new_lyra_type(name, attrs, env)
  attrs = attrs.to_a
  counter = LYRA_TYPE_COUNTER.value
  env.set! :"make-#{name}", NativeLyraFn.new(:"make-#{name}", attrs.size) { |attrs, _| LyraType.new(counter, name, attrs.to_a)  }
  env.set! :"#{name}?", NativeLyraFn.new(:"#{name}?", 1) { |o, _| o.car.is_a?(LyraType) && o.car.type_id == counter }
  
  attrs.each_with_index do |attr, i|
    fn_name = :"#{name}-#{attr}"
    env.set! fn_name, NativeLyraFn.new(fn_name, 1) { |e, _| e.car.attrs[i] }
  end
  
  LYRA_TYPE_COUNTER.value = LYRA_TYPE_COUNTER.value + 1
  
  name
end
