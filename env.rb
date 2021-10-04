#!/usr/bin/env ruby
# frozen_string_literal: true

NOT_FOUND_IN_LYRA_ENV = BasicObject.new

Boxed = Struct.new :val
GLOBAL_ENV = Boxed.new nil

class Env

  attr_reader :module_name, :next_module_env

  def initialize(module_name, parent0 = nil, parent1 = nil, module_env = nil, is_module_env = false)
    @module_name, @next_module_env = module_name, module_env
    @parent0, @parent1 = parent0, parent1
    @inner = Hash.new(NOT_FOUND_IN_LYRA_ENV)
    #@next_module_env = @parent0.next_module_env if module_env.nil? && !@parent0.nil?
    if @next_module_env.nil?
      if @parent0.nil? || is_module_env
        @next_module_env = self
      else
        @next_module_env = @parent0.next_module_env
      end
    end
  end

  def self.create_module_env(module_name)
    e = Env.new(module_name, global_env, nil, nil, true)
    #e.next_module_env = e
    e
  end

  def self.global_env
    unless GLOBAL_ENV.frozen?
      e = Env.new :global
      # e.next_module_env = e
      GLOBAL_ENV.val = e
      GLOBAL_ENV.freeze
    end
    GLOBAL_ENV.val
  end

  def safe_find(sym, include_global = true)
    v = @inner[sym]
    if NOT_FOUND_IN_LYRA_ENV == v && !@parent0.nil?
      v = @parent0.safe_find(sym)
    end
    if NOT_FOUND_IN_LYRA_ENV == v && !@parent1.nil?
      v = @parent1.safe_find(sym)
    end
    if NOT_FOUND_IN_LYRA_ENV == v && self != @next_module_env
      v = @next_module_env.safe_find(sym)
    end
    if NOT_FOUND_IN_LYRA_ENV == v && self != Env.global_env && include_global
      v = Env.global_env.safe_find(sym)
    end
    v
  end

  def find(sym)
    v = safe_find(sym)
    raise "Symbol not found: #{sym}" if NOT_FOUND_IN_LYRA_ENV == v
    v
  end

  def is_defined?(sym, include_global = true)
    NOT_FOUND_IN_LYRA_ENV != safe_find(sym, include_global)
  end

  def set!(sym, val)
    @inner[sym] = val
    self
  end

  def set_multi!(pairs)
    pairs.each do |b|
      set!(b.car, b.cdr.car)
    end
    self
  end

  def is_the_global_env?
    object_id == Env.global_env.object_id
  end
end
