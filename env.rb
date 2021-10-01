

NOT_FOUND_IN_LYRA_ENV = BasicObject.new

Boxed = Struct.new :val
GLOBAL_ENV = Boxed.new nil

class Env
  
  attr_reader :module_name, :next_module_env
  
  def initialize(module_name, parent0 = nil, parent1 = nil, module_env = nil)
    @module_name, @next_module_env = module_name, module_env
    @parent0, @parent1 = parent0, parent1
    @inner = Hash.new(NOT_FOUND_IN_LYRA_ENV)
    #@next_module_env = @parent0.next_module_env if module_env.nil? && !@parent0.nil?
    if module_env.nil?
      if @parent0.nil?
        @next_module_env = self
      else
        @next_module_env = @parent0.next_module_env
      end
    end
    
  end
  
  def self.createModuleEnv(module_name)
    e = Env.new(module_name, global_env)
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
  
  def safe_find(sym)
    v = @inner[sym]
    if NOT_FOUND_IN_LYRA_ENV == v && !@parents0.nil?
      v = @parents0.safe_find(sym)
    end
    if NOT_FOUND_IN_LYRA_ENV == v && !@parents1.nil?
      v = @parents1.safe_find(sym)
    end
    if NOT_FOUND_IN_LYRA_ENV == v && self != @next_module_env
      v = @next_module_env.safe_find(sym)
    end
    v
  end
  
  def find(sym)
    v = safe_find(sym)
    raise "Symbol not found: #{sym}" if NOT_FOUND_IN_LYRA_ENV == v
    v
  end
  
  def is_defined?(sym)
    NOT_FOUND_IN_LYRA_ENV != safe_find(sym)
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
  
  # TODO Remove
  def add(sym, val)
    @inner[sym] = val
    self
  end
  
  
  # TODO Remove
  def add_pairs(pairs)
    pairs.each do |p|
      add(p.car, p.cdr.car)
    end
    self
  end
end
