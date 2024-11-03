#!/usr/bin/env ruby
# frozen_string_literal: true

require_relative 'types.rb'
require_relative 'reader.rb'
require_relative 'core.rb'
require_relative 'env.rb'

$show_expand_macros = false
$enable_aggressive_optimizations = false

IMPORTED_MODULES = []

LYRA_CALL_STACK = [] # Call stack starts as empty list.

# nil is not a valid pair but will be used as a separator between
# local LYRA_ENV and global LYRA_ENV.
unless Object.const_defined?(:LYRA_ENV)
  LYRA_ENV = Env.global_env
  setup_core_functions
end

# The code below reserves some names that have special handlers.
# They must not be called by the code directly.
begin
  f = lambda do |name|
    r = CompoundFunc.new(
      name, list(:xs), list(:"error!", "#{name} must not be called directly.", :"invalid-call"),
      nil, false, 0, -1)
    Env.global_env.set! name, r
  end

  f.call :recur
  temp = Env.global_env.find :recur
  raise unless temp.is_a?(LyraFn) # Make the type checker shut up
  RECUR_FUNC = temp

  f.call :"lambda*"
  #f.call :"let"
  f.call :"let*"
  f.call :"if"
  f.call :"def-type"
  f.call :"define"
  f.call :"def-impl"
  f.call :"def-generic"
  f.call :"defmacro"
  f.call :"module"
  f.call :"quote"
  #f.call :"quasiquote"
  f.call :"unquote"
  f.call :"lazy"
  f.call :"try*"
  f.call :"catch"
  f.call :"expand-macro"

#  f.call :"lambda"
#  f.call :"cond"

  # A placeholder which does nothing. Used to fill space in a list when a cell's entry is not needed.
  DO_NOTHING_AND_RETURN = gensym(:id)
  f.call DO_NOTHING_AND_RETURN
end

# Parses and evaluates a string as Lyra-source code.
def eval_str(s, env = LYRA_ENV)
  ast = make_ast(tokenize(s))
  eval_keep_last(ast, env)
end

def top_env(env)
  env.next_module_env
end

def ev_module(expr)
  expr = expr.cdr
  name = expr.car

  raise LyraError.new("Syntax error: Module name must be a symbol but is #{name}.", :syntax) unless name.is_a?(Symbol)

  already_parsed = IMPORTED_MODULES.map(&:name).include? name
  #return name if IMPORTED_MODULES.include? name
  if already_parsed
    return IMPORTED_MODULES.first{|m|m.name == name}
  end

  module_env = Env.create_module_env name
  expr = expr.cdr
  #meta = expr.car # Currently unused.
  forms = expr.cdr
  
  abstract_name = gensym(:module)
  
  begin
    eval_keep_last forms, module_env
  rescue => e
    $stderr.puts "Error while parsing module #{name}:"
    raise e
  end

  global = Env.global_env

  #binding_out = nil
  #binding_from = nil
  out_bindings = []
  bindings = module_env.public_module_vars
  bindings.each do |key, val|
    binding_out = key
    #binding_from = key

    # Turn binding name "function" into "module/function".
    # E.g. list->vector from module core.vector becomes core.vector/list->vector.
    # No such transformation is done for the namespace lyra.core.
    #unless already_parsed
    unless name == :"lyra.core"
      binding_out = (abstract_name.to_s + "/" + binding_out.to_s).to_sym
    end

    global.set! binding_out, val

    out_bindings << binding_out
  end

  mod = LyraModule.new(name, abstract_name, out_bindings)
  IMPORTED_MODULES << mod
  list(mod.name, mod.abstract_name)
end

# Takes a List (list of expressions), calls eval_ly on each element
# and return a new list.
def eval_list(expr_list, env)
  raise LyraError.new("Syntax error: Expression must be a list.", :syntax) unless expr_list.is_a?(ConsList)
  l = []
  until expr_list.empty?
    l << eval_ly(first(expr_list), env, true)
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
  raise LyraError.new("Syntax error: Expression must be a list.", :syntax) unless expr_list.is_a?(ConsList)

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

    eval_ly expr_list.car, env, true
    expr_list = expr_list.cdr
  end

  eval_ly expr_list.car, env
end

def ev_define_fn(expr, env, is_macro)
  first_of_expr = first(expr)

  unless first_of_expr.is_a?(ConsList) && first(first_of_expr).is_a?(Symbol)
    raise LyraError.new("Syntax error: Name of function in define must be a symbol.", :syntax)
  end

  name = first(first_of_expr)
  args_expr = rest(first_of_expr)
  body = rest(expr)

  unless name.is_a?(Symbol)
    raise # Make the type checker shut up. This condition has already been checked. But you do you, rbs.
  end

  # Create the function
  res = ev_lambda(name, args_expr, body, env, is_macro)

  # Add the entry to the global environment.
  top_env(env).set!(name, res)

  name
end

# Generic functions in Lyra have their implementation chosen at runtime by the so called "anchor argument".
# See the following implementation:
#   (def-generic xs (on-each f xs) (lambda (f xs) (error! "Invalid call to on-each." 'argument)))
# This function is called "on-each", its arguments are "f" and "xs".
# "xs" is the so called "anchor". When Lyra calls a generic function, it looks at the type of xs to find
# the correct implementation. If none is found, it uses the fallback-function (the lambda).
# To add implementations:
#   (def-impl ::list on-each (lambda (f xs) (foldl (lambda (_ x) (f x)) 0 xs) xs))
# This adds an implementation for "on-each" to the "list" type.
def ev_define_generic(expr, env)
  if expr.size != 3
    raise LyraError.new("Syntax error: Invalid format of def-generic.", :syntax)
  end

  ref_arg = first(expr)
  unless ref_arg.is_a? Symbol
    raise LyraError.new("Syntax error: Generic function reference argument must be a symbol.", :syntax)
  end

  args_expr = second(expr)
  unless args_expr.is_a?(ConsList)
    raise LyraError.new("Syntax error: Signature of generic function must be a list.", :syntax)
  end

  name = first(args_expr)
  unless name.is_a?(Symbol)
    raise LyraError.new("Syntax error: Name of generic function in define must be a symbol.", :syntax)
  end

  args = rest(args_expr)
  anchor_idx = args.to_a.index(ref_arg)
  unless anchor_idx
    raise LyraError.new("Syntax error: Argument #{ref_arg} not found for generic function #{name}.", :syntax)
  end

  fallback = eval_ly(third(expr), env)
  unless fallback.is_a?(LyraFn)
    raise LyraError.new("Syntax error: Fallback for generic function #{name} must be a function.", :syntax)
  end

  res = GenericFn.new name, args.size, anchor_idx, fallback
  top_env(env).set!(name, res)

  name
end

def ev_define_with_type(expr, env, is_macro)
  if is_macro || !second(expr).is_a?(Symbol) || expr.size < 3
    raise LyraError.new("Syntax error: Generic function implementation must have the format (define ::type global_name impl) and must not be a macro.", :syntax)
  end

  global_name = second(expr)
  impl_name = third(expr)
  impl = eval_ly(impl_name, env)

  fn = eval_ly(global_name, env)
  unless fn.is_a? GenericFn
    raise LyraError.new("Syntax error: No generic function #{global_name} found.", :syntax)
  end

  unless impl.is_a? LyraFn
    raise LyraError.new("Syntax error: Implementation of generic function #{global_name} must be a function.", :syntax)
  end

  name = eval_ly(first(expr), env)
  unless name.is_a? TypeName
    raise LyraError.new("Syntax error: Implementation type name for generic function #{global_name} must be a typename.", :syntax)
  end

  fn.add_implementation! name, impl

  third(expr)
end

# Defines a new function or variable and puts it into the global LYRA_ENV.
# If `is_macro` is true, the function will not evaluate its arguments right away.
def ev_define(expr, env, is_macro)
  unless expr.size >= 2
    raise LyraError.new("Syntax error: No name and no body for define or defmacro.", :syntax)
  end
  first_expr = first(expr)
  unless first_expr.is_a?(ConsList) || first_expr.is_a?(Symbol) #|| first_expr.is_a?(TypeName)
    raise LyraError.new("Syntax error: First element in define or defmacro must be a list or symbol, but is #{first_expr.class}.", :syntax)
  end

  if first_expr.is_a?(ConsList)
    # Form is `(define (...) ...)` (Function definition)
    ev_define_fn(expr, env, is_macro)
  #elsif first_expr.is_a?(Symbol) && expr.size == 3
    # Form is `(define .. (...) ...)` (Generic function definition)
    #  ev_define_with_type(expr, env, is_macro)
  else
    # Form is `(define .. ...)` (Variable definition)
    name = first_expr # Get the name
    val = second(expr)
    res = eval_ly(val, env) # Get and evaluate the value.

    unless first_expr.is_a?(Symbol) #|| first_expr.is_a?(TypeName)
      raise LyraError.new("Trying to add a list to environment. This does not work.", :syntax)
    end

    # Add the entry to the global environment.
    top_env(env).set!(name, res)
    name
  end
end

# args_expr has the format `(args...)`
# body_expr has the format `expr...`
def ev_lambda(name, args_expr, body_expr, definition_env, is_macro = false)
  # This function will call the array indexing methods a lot, so converting to an array first helps out.
  # TODO Maybe first checking whether the list is already a random_access type be faster? (e.g. for CdrCodedLists)
  arg_arr = args_expr.to_a

  arg_count = arg_arr.size
  max_args = arg_count
  is_hash_lambda = false # Enable % arguments.

  unless arg_arr.all? { |x| x.is_a? Symbol }
    raise LyraError.new("Syntax error: Arguments for lambda must be symbols but are #{args_expr}", :syntax)
  end

  a = arg_arr.reject { |a| a == :"_" }
  unless a.uniq.size == a.size
    raise LyraError.new("Syntax error: Non-unique argument names in lambda expression.", :syntax)
  end

  # Check for variadic arguments.
  # The arguments of a function are variadic if the second to last
  # symbol in the argument list is `&`.
  if arg_count >= 2
    varargs = arg_arr[-2] == :"&"
    if arg_arr[-1] == 0.chr.to_sym
      is_hash_lambda = true
    end
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

  if body_expr.is_a?(EmptyList)
    body_expr = list(nil)
  end

  CompoundFunc.new(name, args_expr, body_expr, definition_env, is_macro, arg_count, max_args, is_hash_lambda)
end

# Form: (try* <expr> (catch <ex-name> <validator> <body>)
#       (try* <expr> (catch <ex-name> <body>)
def eval_try_star(expr, env)
  if expr.size != 3
    raise LyraError.new("try* requires 2 expressions.", :syntax)
  end

  body = expr.cdr.car
  clause = expr.cdr.cdr.car

  # Try to find catch clause
  if clause.is_a?(ConsList) && clause.car == :catch
    validator = clause.cdr.car
    clause = clause.cdr
    exception_name = clause.cdr.car
    clause = clause.cdr
    unless exception_name.is_a?(Symbol)
      raise LyraError.new("Error in try*: exception name must be a symbol.", :syntax)
    end

    begin
      # Try to execute body
      res = eval_ly(body, env)
    rescue LyraError => error
      # Error caught
      # Register error in new env
      env1 = Env.new(gensym(:"ERROR_ENV"), env)
      error1 = WrappedLyraError.new(error.message, error.info, error.internal_trace)
      env1.set!(exception_name, error1)

      # If first expression after the error name is a function, use it to try and validate the error.
      # If this returns a falsy value, the catch is not executed and the error is re-thrown
      run_clause = true
      unless validator.nil? || validator == :"_"
        validator = eval_ly(validator, env1, true)
        if validator.is_a?(LyraFn)
          run_clause = eval_ly(list(validator, error1), env1, true)
        else
          raise LyraError.new("Validator in try* must be 'Nothing', '_' or a function.", :syntax)
        end
      end

      #Run clause if validated or re-throw
      if run_clause
        res = eval_keep_last(clause, env1)
      else
        raise error
      end
    end
    res
  else
    raise LyraError.new("No catch-clause in try*", :syntax)
  end
end

# The expression is a cons and probably starts with a symbol.
# The evaluate function will try to treat the symbol as a function
# and execute it.
# If the first expression in the cons is another cons, that one
# will be evaluated first and then run as a function too.
#   Example: ((lambda (n) (+ n 1)) 15)
# If the cons is empty or does not start with a symbol or another
# cons, an error is thrown.
def eval_list_expr(expr, env, is_in_call_params = false)
  # Try to match the symbol.
  case first(expr)
  when :if
    # Form is `(if predicate then-branch else-branch)`.
    # If the predicate holds true, the then-branch is executed.
    # Otherwise, the else-branch is executed.
    raise LyraError.new("if needs 3 arguments.", :syntax) if expr.size != 4 # includes the 'if
    pred = eval_ly(second(expr), env, true)
    if truthy?(pred)
      # The predicate was true
      eval_ly(third(expr), env)
    else
      # The predicate was not true
      eval_ly(fourth(expr), env)
    end
  when DO_NOTHING_AND_RETURN
    eval_ly(second(expr), env)
  when :"lambda*"
    raise LyraError.new("lambda* without name.", :syntax) if expr.cdr.empty?
    raise LyraError.new("lambda* #{second(expr)}: no bindings.", :syntax) if expr.cdr.cdr.empty?
    raise LyraError.new("lambda* #{second(expr)}: name must be a symbol.", :syntax) unless second(expr).is_a?(Symbol)

    # Defines an anonymous function.
    # Form: `(lambda* name (arg0 arg1 ...) body...)`
    # If the body is empty, the lambda returns nil.
    name = second(expr)
    args_expr = second(rest(expr))
    body_expr = rest(rest(rest(expr)))

    raise LyraError.new("Syntax error: lambda* name must be a symbol.", :syntax) unless name.is_a?(Symbol)
    raise LyraError.new("Syntax error: lambda* arguments must be a list.", :syntax) unless args_expr.is_a?(ConsList)
    ev_lambda(name, args_expr, body_expr, env)
  when :define
    # Creates a new function and adds it to the global environment.
    # Form: `(define name value)` (For variables)
    #    or `(define (name arg0 arg1 ...) body...)` (For functions)
    # If the body is empty, the function returns nil.
    ev_define(rest(expr), env, false)
  when :"def-impl"
    ev_define_with_type(rest(expr), env, false)
  when :"def-generic"
    ev_define_generic(rest(expr), env)
  when :"let*"
    raise LyraError.new("Syntax error: let* needs at least 1 argument.", :syntax) if expr.cdr.empty?
    bindings = second(expr)
    raise LyraError.new("Syntax error: let bindings must be a list.", :syntax) unless bindings.is_a?(ConsList) || bindings.is_a?(EmptyList)

    body = rest(rest(expr))
    env1 = env
    unless bindings.empty?
      env1 = Env.new(gensym(:"ANONYMOUS_ENV"), env)
      bindings.each do |b|
        raise LyraError.new("Syntax error: Binding in let* must have 2 parts.", :syntax) unless b.is_a?(ConsList) && b.size == 2
        raise LyraError.new("Syntax error: Name of binding in let* must be a symbol.", :syntax) unless b.car.is_a?(Symbol)
        env1.set!(b.car, eval_ly(b.cdr.car, env1, true))
      end
    end

    # Execute the body.
    eval_keep_last(body, env1)
  when :"def-type"
    expr = expr.cdr
    raise LyraError.new("Syntax error: def-type without a name.") if expr.empty?
    new_lyra_type(expr.car, expr.cdr, env.next_module_env)
  when :quote
    # Quotes a single expression so that it is not evaluated when
    # passed.
    if rest(expr).empty? || !(rest(rest(expr)).empty?)
      raise LyraError.new("Syntax error: quote takes exactly 1 argument")
    end
    second(expr)
  when :"defmacro"
    # Same as define, but the 'is_macro' parameter is true.
    # Form: `(defmacro (name arg0 arg1 ...) body...)`
    ev_define(rest(expr), env, true)
  when :module
    ev_module expr
  #when :lazy
  #  if expr.cdr.size != 1
  #    raise LyraError.new("Wrong number of arguments for lazy. (Expected 1, got #{expr.cdr.size})")
  #  end
  #  LazyObj.new expr.cdr.car, env
  when :"try*"
    eval_try_star(expr, env)
  when :"expand-macro"
    func = eval_ly(expr.cdr.car, env, true)
    args = expr.cdr.cdr
    if func.nil? || !func.is_a?(LyraFn) || !func.is_macro
      raise LyraError.new("expand-macro expects a macro as its first argument.", :"invalid-call")
    end
    LYRA_CALL_STACK.push func
    # The macro is first called and the resulting expression
    # is then executed.
    r1 = func.call(args, env)
    LYRA_CALL_STACK.pop
    expr.set_car! DO_NOTHING_AND_RETURN
    expr.set_cdr! list(r1)
    r1
  else
    # Here, the expression will have a form like the following:
    # (func arg0 arg1 ...)
    # The function corresponding to the symbol ('func in this example)
    # is fetched from the environment.
    # If the function is a macro, the arguments are not evaluated before
    # executing the macro. Otherwise, the arguments are evaluated and
    # the function is called.

    # Find value of symbol in env and call it as a function
    func = eval_ly(first(expr), env)
    func = eval_ly(func, env) while func.is_a?(Symbol)

    # The arguments which will be passed to the function.
    args = rest(expr)

    # If `expr` had the form `((...) ...)`, then the result of the
    # inner list must be executed too.
    func = eval_ly(func, env) if func.is_a?(ConsList)

    raise LyraError.new("Runtime error: Expected a function, got #{elem_to_pretty(func)} in #{elem_to_pretty(expr)}", :expected_function) unless func.is_a?(LyraFn)

    if func.native?
      LYRA_CALL_STACK.push func
      args = eval_list(args, env)

      # Call the function with the new arguments
      r = func.call(args, env)

      LYRA_CALL_STACK.pop
      r
    elsif func.is_macro
      LYRA_CALL_STACK.push func
      # The macro is first called and the resulting expression
      # is then executed.
      r1 = func.call(args, env)
      LYRA_CALL_STACK.pop
      puts elem_to_pretty(r1) if $show_expand_macros
      if LYRA_CALL_STACK.none?(&:is_macro)
        expr.set_car! DO_NOTHING_AND_RETURN
        expr.set_cdr! list(r1)
      end
      eval_ly(r1, env)
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
        args = eval_list(args, env)
        # Tail call
        raise TailCall.new(args)
      else
        LYRA_CALL_STACK << func

        # Evaluate arguments that will be passed to the call.
        args = eval_list(args, env)

        # Call the function with the new arguments
        r = func.call(args, env)
        
        # Remove from the callstack.
        raise unless LYRA_CALL_STACK.is_a? Array # Make the type checker shut up
        LYRA_CALL_STACK.pop(1)

        r
      end
    end
  end
end

# Evaluation function
def eval_ly(expr, env, is_in_call_params = false)
  if expr.nil? || (expr.is_a?(ConsList) && expr.empty?)
    expr
  elsif expr.is_a?(Symbol)
    env.find(expr) # Get associated value from env
  elsif atom?(expr) || expr.is_a?(LyraFn) || expr.is_a?(WrappedLyraError) || expr.is_a?(Box) || expr.is_a?(Lazy)
    expr
  elsif expr.is_a?(Array)
    if expr.all? { |x| !x.is_a?(Symbol) && atom?(x) }
      # Nothing to evaluate.
      expr
    else
      expr.map { |x| eval_ly x, env, true }
    end
  elsif expr.is_a?(Hash)
    (expr.map { |k, v| eval_ly [k, v], env, true }).to_h
  elsif expr.is_a?(Set)
    (expr.map { |x| eval_ly x, env, true }).to_set
  elsif expr.is_a?(ConsList)
    eval_list_expr(expr, env, is_in_call_params)
  elsif expr.is_a?(LyraType)
    expr
  else
    raise LyraError.new("Unknown type. (Object is #{expr})")
  end
end

