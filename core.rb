require_relative 'types.rb'
require_relative 'env.rb'

# Sets up the core functions and variables. The functions defined here are
# of the type NativeLyraFn instead of LyraFn. They can not make use of tail-
# recursion and are supposed to be very simple.
def setup_core_functions
  def add_fn(name, min_args, max_args=min_args, &body)
    #LYRA_ENV.add(name, NativeLyraFn.new(name, false, min_args, max_args, &body))
    fn = NativeLyraFn.new(name, min_args, max_args) do |args,env|
      body.call(args.to_a)
    end
    LyraEnv.global_env.add(name, fn)
  end
  def add_var(name, value)
    LyraEnv.global_env.add(name, value)
  end

  # "Primitive" operators. They are overridden in the core library of
  # Lyra as `=`, `<`, `>`, ... and can be extended there later on for
  # different types.
  add_fn(:"=", 2)             { |x, y| x == y }
  add_fn(:"<", 2)             { |x, y| x < y }
  add_fn(:">", 2)             { |x, y| x > y }
  add_fn(:"+", 2)             { |x, y| x + y }
  add_fn(:"-", 2)             { |x, y| x - y }
  add_fn(:"*", 2)             { |x, y| x * y }
  add_fn(:"/", 2)             { |x, y| x / y }
  add_fn(:"rem", 2)           { |x, y| x % y }
  add_fn(:"bit-and", 2)       { |x, y| x & y }
  add_fn(:"bit-or", 2)        { |x, y| x | y }
  add_fn(:"bit-xor", 2)       { |x, y| x ^ y }
  add_fn(:"bit-shl", 2)       { |x, y| x << y }
  add_fn(:"bit-shr", 2)       { |x, y| x >> y }

  true
end
