#!/usr/bin/env ruby
# frozen_string_literal: true

require_relative 'types.rb'
require_relative 'reader.rb'
require_relative 'core.rb'
require_relative 'env.rb'

$enable_aggressive_optimizations = false

IMPORTED_MODULES = []

# nil is not a valid pair but will be used as a separator between
# local LYRA_ENV and global LYRA_ENV.
unless Object.const_defined?(:LYRA_ENV)
  LYRA_ENV = Env.global_env
  LYRA_CALL_STACK = [] # Call stack starts as empty list.
  setup_core_functions
end

RECUR_FUNC = CompoundFunc.new(:recur, Env.global_env, false, 0, -1) do |*_|
  raise "Internal error: recur must not be called directly."
end
Env.global_env.set! :recur, RECUR_FUNC

# Parses and evaluates a string as Lyra-source code.
def eval_str(s, env = LYRA_ENV)
  ast = make_ast(tokenize(s))
  eval_keep_last(ast, env)
end

def top_env(env)
  env.next_module_env
end

# Turns 2 lists into a combined one.
#   `pairs(list(1,2,3), list(4,5,6)) => ((1 . 4) (2 . 5) (3 . 6))`
# If the first list is longer than the second, all remaining 
# elements from the second are added the value for the last element
# of the first list:
#   `pairs(list(1,2,3), list(4,5,6,7)) => ((1 . 4) (2 . 5) (3 6 7))`
# The intended use for this function is for adding function arguments
# to the environment. The latter case makes it easy to pass
# variadic arguments.
def pairs(cons0, cons1, expect_v_args = false)
  res = []
  until cons0.empty?
    if expect_v_args && cons0.size == 1
      res << list(cons0.car, cons1)
    else
      res << list(cons0.car, cons1.car)
    end
    cons0 = cons0.cdr
    cons1 = cons1.cdr
  end
  #puts res
  res
end

def ev_module(expr)
  expr = expr.cdr
  name = expr.car

  raise "Syntax error: Module name must be a symbol but is #{name}." unless name.is_a?(Symbol)

  return name if IMPORTED_MODULES.include? name

  module_env = Env.create_module_env name
  expr = expr.cdr
  bindings = expr.car
  forms = expr.cdr
  raise "Syntax error: Module bindings must be a list." unless bindings.is_a?(ConsList)
  raise "Syntax error: Module forms must be a list." unless bindings.is_a?(ConsList)

  eval_keep_last forms, module_env

  global = Env.global_env
  bindings.each do |binding|
    #check_for_redef(binding.car, global)
    global.set! binding.car, eval_ly(binding.cdr.car, module_env)
  end

  name
end

# Takes a List (list of expressions), calls eval_ly on each element
# and return a new list.
def eval_list(expr_list, env, force_eval)
  raise "Syntax error: Expression must be a list." unless expr_list.is_a?(ConsList)
  l = []
  until expr_list.empty?
    l << eval_ly(first(expr_list), env, force_eval, true)
    expr_list = rest(expr_list)
  end
  list(*l)
end

# Completely removes atoms and nil from the ast if they are not needed.
def optimize_cdr(expr_list, env)
  this_cdr = expr_list.cdr
  if this_cdr.cdr.empty?
    # Do not remove the last element in the list!
    false
  elsif this_cdr.car.is_a? Symbol
    # If it's a symbol, try to find it and then remove it
    eval_ly this_cdr.car, env
    expr_list.set_cdr! this_cdr.cdr
    true
  elsif atom?(this_cdr.car) || this_cdr.car.nil?
    # If it's any atomic type or nil, remove it
    expr_list.set_cdr! this_cdr.cdr
    true
  else
    # If it can't be easily deleted, remove it anyways.
    false
  end
end

# Similar to eval_list, but only returns the last evaluated value.
def eval_keep_last(expr_list, env)
  raise "Syntax error: Expression must be a list." unless expr_list.is_a?(ConsList)

  return list if expr_list.empty?

  until expr_list.cdr.empty?
    if $enable_aggressive_optimizations
      # Try to optimize pure function-call.
      # This even removes impure arguments in the call, so be careful.
      # Example:
      #   (->string 1) becomes nil
      #   (->string (readln!)) also becomes nil without ever executing the function
      if expr_list.car.is_a?(ConsList) && expr_list.car.car.is_a?(Symbol)
        fn = env.safe_find expr_list.car.car
        unless fn == NOT_FOUND_IN_LYRA_ENV
          if fn.pure?
            expr_list.set_car! nil
          end
        end
      end

      optimize_cdr(expr_list, env)
    end

    eval_ly expr_list.car, env, false, true
    expr_list = expr_list.cdr
  end

  eval_ly expr_list.car, env
end

def ev_define_fn(expr, env, is_macro)
  unless first(first(expr)).is_a?(Symbol)
    raise "Syntax error: Name of function in define must be a symbol."
  end

  name = first(first(expr))
  args_expr = rest(first(expr))
  body = rest(expr)

  # Create the function
  res = ev_lambda(args_expr, body, env, is_macro)
  res.name = name

  # Add the entry to the global environment.
  top_env(env).set!(name, res)

  name
end

def ev_define_generic(expr, env)
  if expr.size != 3
    raise "Syntax error: Invalid format of def-generic."
  end
  
  ref_arg = first(expr)
  unless ref_arg.is_a? Symbol
    raise "Syntax error: Generic function reference argument must be a symbol."
  end
  
  args_expr = second(expr)
  unless args_expr.is_a?(List)
    raise "Syntax error: Signature of generic function must be a list."
  end
  
  name = first(args_expr)
  unless name.is_a?(Symbol)
    raise "Syntax error: Name of generic function in define must be a symbol."
  end

  args = rest(args_expr)
  anchor_idx = args.to_a.index(ref_arg)
  unless anchor_idx
    raise "Syntax error: Argument #{ref_arg} not found for generic function #{name}."
  end
  
  fallback = eval_ly(third(expr), env)
  unless fallback.is_a?(LyraFn)
    raise "Syntax error: Fallback for generic function #{name} must be a function."
  end

  res = GenericFn.new name, args.size, anchor_idx, fallback
  top_env(env).set!(name, res)

  name
end

def ev_define_with_type(expr, env, is_macro)
  if is_macro || !second(expr).is_a?(Symbol) || expr.size < 3
    raise "Syntax error: Generic function implementation must have the format (define ::type global_name impl) and must not be a macro."
  end
  global_name = second(expr)
  impl_name = third(expr)
  impl = eval_ly(impl_name, env)
  
  fn = eval_ly(global_name, env)
  unless fn.is_a? GenericFn
    raise "Syntax error: No generic function #{global_name} found."
  end
  
  unless impl.is_a? LyraFn
    raise "Syntax error: Implementation of function #{global_name} must be a function."
  end
  
  fn.add_implementation! eval_ly(first(expr),env), impl

  third(expr)
end

# Defines a new function or variable and puts it into the global LYRA_ENV.
# If `is_macro` is true, the function will not evaluate its arguments right away.
def ev_define(expr, env, is_macro)
  unless expr.size >= 2
    raise "Syntax error: No name and no body for define or def-macro."
  end
  unless first(expr).is_a?(List) || first(expr).is_a?(Symbol) || first(expr).is_a?(TypeName)
    raise "Syntax error: First element in define or def-macro must be a list or symbol."
  end

  if first(expr).is_a?(List)
    # Form is `(define (...) ...)` (Function definition)
    ev_define_fn(expr, env, is_macro)
  elsif first(expr).is_a?(Symbol) && expr.size == 3
    # Form is `(define .. (...) ...)` (Generic function definition)
    ev_define_with_type(expr, env, is_macro)
  else
    # Form is `(define .. ...)` (Variable definition)
    name = first(expr) # Get the name
    val = second(expr)
    res = eval_ly(val, env) # Get and evaluate the value.
    
    # Add the entry to the global environment.
    top_env(env).set!(name, res)
    name
  end
end

# args_expr has the format `(args...)`
# body_expr has the format `expr...`
def ev_lambda(args_expr, body_expr, definition_env, is_macro = false)
  arg_arr = args_expr.to_a
  arg_count = arg_arr.size
  max_args = arg_count

  unless arg_arr.all?{|x| x.is_a? Symbol}
    raise "Syntax error: Arguments for lambda must be symbols."
  end

  # Check for variadic arguments.
  # The arguments of a function are variadic if the second to last
  # symbol in the argument list is `&`.
  if arg_count >= 2
    varargs = arg_arr[-2] == :"&"
    if varargs
      # Remove the `&` from the arguments.
      last = arg_arr[-1]
      arg_arr = arg_arr[0..-3]
      arg_arr << last
      args_expr = list(*arg_arr)

      # Set the new argument numbers for minimum
      # and maximum number of arguments.
      # -1 means infinite.
      max_args = -1
      arg_count -= 2
    end
  end

  CompoundFunc.new("", definition_env, is_macro, arg_count, max_args) do |args, environment|
    # Makes pairs of the argument names and given arguments and
    # adds these pairs to the local environment.
    if max_args < 0
      arg_pairs = pairs(args_expr, args, true)
    else
      arg_pairs = pairs(args_expr, args)
    end

    env1 = Env.new(nil, definition_env, environment).set_multi!(arg_pairs)

    # Execute all commands in the body and return the last
    # value.
    eval_keep_last(body_expr, env1)
  end
end

# Evaluation function
def eval_ly(expr, env, force_eval = false, is_in_call_params = false)
  if expr.nil? || (expr.is_a?(ConsList) && expr.empty?)
    expr
  elsif expr.is_a?(Symbol)
    env.find expr # Get associated value from env
  elsif atom?(expr) || expr.is_a?(LyraFn)
    #force_eval ? eager(expr) : expr
    expr
  elsif expr.is_a? Array
    if expr.all? { |x| !x.is_a?(Symbol) && atom?(x) }
      # Nothing to evaluate.
      expr
    else
      expr.map { |x| eval_ly x, env, force_eval, true }
    end
  elsif expr.is_a?(ConsList)
    # The expression is a cons and probably starts with a symbol.
    # The evaluate function will try to treat the symbol as a function
    # and execute it.
    # If the first expression in the cons is another cons, that one
    # will be evaluated first and then run as a function too.
    #   Example: ((lambda (n) (+ n 1)) 15)
    # If the cons is empty or does not start with a symbol or another
    # cons, an error is thrown.

    # Try to match the symbol.
    case first(expr)
    when :if
      # Form is `(if predicate then-branch else-branch)`.
      # If the predicate holds true, the then-branch is executed.
      # Otherwise, the else-branch is executed.
      raise "if needs 3 arguments." if expr.size < 4 # includes the 'if
      pres = eval_ly(second(expr), env, force_eval)
      #uts "In if: " + pres.to_s
      if pres != false && pres != nil && !pres.is_a?(EmptyList)
        # The predicate was true
        eval_ly(third(expr), env, force_eval)
      else
        # The predicate was not true
        eval_ly(fourth(expr), env, force_eval)
      end
    when :cond
      clauses = rest(expr)
      result = nil
      until clauses.empty?
        unless first(clauses).size == 2
          raise "Syntax error: Clause in cond must have exactly 2 bindings."
        end
        predicate = eval_ly(first(first(clauses)), env, force_eval)
        if predicate
          result = eval_ly(second(first(clauses)), env, force_eval)
          break
        end
        clauses = rest(clauses)
      end
      result
    when :lambda
      raise "lambda without bindings." if expr.cdr.empty?

      # Defines an anonymous function.
      # Form: `(lambda (arg0 arg1 ...) body...)`
      # If the body is empty, the lambda returns nil.
      args_expr = second(expr)
      body_expr = rest(rest(expr))
      ev_lambda(args_expr, body_expr, env)
    when :define
      # Creates a new function and adds it to the global environment.
      # Form: `(define name value)` (For variables)
      #    or `(define (name arg0 arg1 ...) body...)` (For functions)
      # If the body is empty, the function returns nil.
      ev_define(rest(expr), env, false)
    when :"def-generic"
      ev_define_generic(rest(expr), env)
    when :"let*"
      raise "Syntax error: let* needs at least 1 argument." if expr.cdr.empty?
      bindings = second(expr)
      raise "Syntax error: let bindings must be a list." unless bindings.is_a?(ConsList) || bindings.is_a?(EmptyList)

      body = rest(rest(expr))
      env1 = env
      unless bindings.empty?
        env1 = Env.new(nil, env)
        bindings.each do |b|
          raise "Syntax error: Binding in let* must have 2 parts." unless b.size == 2
          raise "Syntax error: Name of binding in let* must be a symbol." unless b.car.is_a? Symbol
          env1.set!(b.car, eval_ly(b.cdr.car, env1, force_eval))
        end
      end

      # Execute the body.
      eval_keep_last(body, env1)
=begin
    when :"let1"
      raise "Syntax error: let1 needs at least 1 argument." if expr.cdr.empty?
      raise "Syntax error: let1 bindings must be a non-empty list." unless second(expr).is_a?(ConsList)

      raise "Syntax error: Binding in let* must have 2 parts." unless first(second(expr)).is_a? Symbol

      name = first(second(expr))
      val = eval_ly(second(second(expr)), env, force_eval) # Evaluate the value.
      env1 = Env.new nil, env
      env1.set!(name, val)
      eval_keep_last(rest(rest(expr)), env1) # Evaluate the body.
=end
    when :let
      raise "Syntax error: let needs at least 1 argument." if expr.cdr.empty?
      bindings = second(expr)
      raise "Syntax error: let bindings must be a list." unless bindings.is_a?(ConsList) || bindings.is_a?(EmptyList)

      body = rest(rest(expr))
      env1 = Env.new(nil, env)
      unless bindings.empty?
        # Evaluate bindings in order using the old environment.
        bindings.each do |b|
          raise "Syntax error: Binding in let must have 2 parts." unless b.size == 2
          raise "Syntax error: Name of binding in let must be a symbol." unless b.car.is_a? Symbol
          env1.set!(b.car, eval_ly(b.cdr.car, env, force_eval))
        end
      end

      # Execute the body.
      eval_keep_last(body, env1)
    when :"def-type"
      expr = expr.cdr
      raise "Syntax error: def-type without a name." if expr.empty?
      new_lyra_type(expr.car, expr.cdr, env.next_module_env)
    when :quote
      # Quotes a single expression so that it is not evaluated when
      # passed.
      if rest(expr).empty? || !(rest(rest(expr)).empty?)
        raise "Syntax error: quote takes exactly 1 argument"
      end
      second(expr)
    when :"def-macro"
      # Same as define, but the 'is_macro' parameter is true.
      # Form: `(def-macro (name arg0 arg1 ...) body...)`
      ev_define(rest(expr), env, true)
=begin
    when :apply
      # Form: (apply func & args)
      # (apply f x0 x1 x2 (list x3 x4 x5)) becomes (f x0 x1 x2 x3 x4 x5)
      # apply is not to be used with macros!
      fn = eval_ly(second(expr), env, force_eval, true)
      args = rest(rest(expr)).to_a
      if args.empty?
        eval_ly list(fn), env, force_eval, is_in_call_params
      elsif !args[-1].is_a? Enumerable
        eval_ly list(cdr(expr)), env,force_eval,is_in_call_params
      else
        args1 = eval_ly(args[-1], env, force_eval, true).to_cons_list
        args[0...-1].reverse_each do |e|
          args1 = cons(eval_ly(e, env, force_eval, true), args1)
        end
        fn.apply_to args1, env
      end
=end
    when :module
      ev_module expr
    when :lazy
      LazyObj.new expr.cdr.car, env
    else
      # Here, the expression will have a form like the following:
      # (func arg0 arg1 ...)
      # The function corresponding to the symbol ('func in this example)
      # is fetched from the environment.
      # If the function is a macro, the arguments are not evaluated before
      # executing the macro. Otherwise, the arguments are evaluated and
      # the function is called.

      # Find value of symbol in env and call it as a function
      func = eval_ly(first(expr), env, force_eval)
      func = eval_ly(func, env, force_eval) while func.is_a?(Symbol)

      # The arguments which will be passed to the function.
      args = rest(expr)

      # If `expr` had the form `((...) ...)`, then the result of the
      # inner list must be executed too.
      func = eval_ly(func, env, force_eval) if func.is_a?(ConsList)
      
      raise "Runtime error: Expected a function, got #{elem_to_s(func)}" unless func.is_a?(LyraFn)

      # If the function is not pure, force evaluation.
      force_eval = true unless func.pure?

      if func.native?
        LYRA_CALL_STACK.push func
        args = eval_list(args, env, force_eval)
        r = func.call(args, env)
        LYRA_CALL_STACK.pop
        r
      elsif func.is_macro
        # The macro is first called and the resulting expression
        # is then executed.
        r1 = func.call(args, env)
        #puts r1
        expr.set_car! :id
        expr.set_cdr! list(r1)
        eval_ly(r1, env, force_eval)
      else
        # Check whether a tail-call is possible
        # A tail-call is possible if the function is not natively implemented
        # and the same function is at the front of the call stack.
        # So `(define (crash n) (crash (inc n)))` will tail call,
        # but `(define (crash) (inc (crash)))` will not.
        # Notice that the special commands if, let* and let (and all macros
        # which boil down to them, like `begin`) do not go on the callstack.
        # So `(define (do-times n f)
        #       (if (= 0 n) '() (begin (f) (do-times (dec n) f))))`
        # will also tail call.
        if !is_in_call_params && (!LYRA_CALL_STACK.empty?) && ((func == LYRA_CALL_STACK.last) || func == RECUR_FUNC)
          # Evaluate arguments that will be passed to the call.
          args = eval_list(args, env, force_eval)
          # Tail call
          raise TailCall.new(args)
        else
          LYRA_CALL_STACK.push func

          # Evaluate arguments that will be passed to the call.
          args = eval_list(args, env, force_eval)

          # Call the function with the new arguments
          r = func.call(args, env)

          # Remove from the callstack.
          LYRA_CALL_STACK.pop

          r
        end
      end
    end
  else
    raise "Unknown type. (Object is #{expr})"
  end
end

