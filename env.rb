#!/usr/bin/env ruby
# frozen_string_literal: true

NOT_FOUND_IN_LYRA_ENV = BasicObject.new

Boxed = Struct.new :val
GLOBAL_ENV = Boxed.new nil

class Env

  attr_reader :module_name, :next_module_env, :inner

  def initialize(module_name, parent0 = nil, parent1 = nil, module_env = nil, is_module_env = false)
    @module_name, @next_module_env = module_name, module_env
    @parent0, @parent1 = parent0, parent1
    @inner = Hash.new(NOT_FOUND_IN_LYRA_ENV)
    #@next_module_env = @parent0.next_module_env if module_env.nil? && !@parent0.nil?
    if @next_module_env.nil?
      if @parent0.nil? || is_module_env
        @next_module_env = self
      else
        # &. gets rid of the "Method invocation 'next_module_env' may produce 'NoMethodError" warning
        @next_module_env = @parent0&.next_module_env
      end
    end
  end

  def self.create_module_env(module_name)
    Env.new(module_name, global_env, nil, nil, true)
  end

  def self.global_env
    unless GLOBAL_ENV.frozen?
      e = Env.new :global
      GLOBAL_ENV.val = e
      GLOBAL_ENV.freeze
    end
    GLOBAL_ENV.val
  end

  def safe_find(sym, include_global = true)
    return NOT_FOUND_IN_LYRA_ENV if self == Env.global_env && !include_global
    v = @inner[sym]
    if NOT_FOUND_IN_LYRA_ENV == v && !@parent0.nil?
      v = @parent0.safe_find(sym, include_global)
    end
    if NOT_FOUND_IN_LYRA_ENV == v && !@parent1.nil?
      v = @parent1.safe_find(sym, include_global)
    end
    if NOT_FOUND_IN_LYRA_ENV == v && self != @next_module_env
      v = @next_module_env.safe_find(sym, include_global)
    end
    if NOT_FOUND_IN_LYRA_ENV == v && self != Env.global_env && include_global
      v = Env.global_env.safe_find(sym)
    end
    v
  end

  def find(sym)
    v = safe_find(sym)
    raise LyraError.new("Symbol not found: #{sym}") if NOT_FOUND_IN_LYRA_ENV == v
    v
  end

  def is_defined?(sym, include_global = true)
    NOT_FOUND_IN_LYRA_ENV != safe_find(sym, include_global)
  end

  def set!(sym, val)
    if sym != :"_" # Ignore the _ symbol.
      if @inner.include? sym
        raise LyraError.new("Symbol already defined: #{sym}")
      else
        @inner[sym] = val
      end
    end
    self
  end

  ANONYMOUS_ARG_NAMES = Array.new(16) { |i| :"%#{i+1}" }.freeze
  ANONYMOUS_ARG_REST = :"%&"
  ANONYMOUS_ARG_ALL = :"%&&"

  def set_multi!(keys, values, varargs)
    until keys.empty?
      if varargs && keys.cdr.empty?
        set! keys.car, values
      else
        set! keys.car, values.car
      end
      keys = keys.cdr
      values = values.cdr
    end
    self
  end

  def set_multi_anonymous!(values)
    anon_count = 0
    
    set! ANONYMOUS_ARG_ALL, values
    
    until values.empty? || anon_count >= 15
      set! ANONYMOUS_ARG_NAMES[anon_count], values.car
      anon_count += 1
      values = values.cdr
    end

    rest_arg_names = ANONYMOUS_ARG_NAMES[anon_count .. -1]
    unless rest_arg_names.nil?
      rest_arg_names.each do |k|
        set! k, nil
      end
    end

    set! ANONYMOUS_ARG_REST, values
    self
  end

  def is_the_global_env?
    object_id == Env.global_env.object_id
  end
end
