require_relative 'types.rb'
require_relative 'reader.rb'
require_relative 'core.rb'
require_relative 'env.rb'

IMPORTED_MODULES = []

# nil is not a valid pair but will be used as a separator between
# local LYRA_ENV and global LYRA_ENV.
unless Object.const_defined?(:LYRA_ENV)
  LYRA_ENV = Env.global_env
  $lyra_call_stack = EmptyList.instance # Call stack starts as empty list.
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
def pairs(cons0, cons1, expect_vargs = false)
  res = []
  until cons0.empty?
    if expect_vargs && cons0.size == 1
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
  return name if IMPORTED_MODULES.include? name

  module_env = Env.createModuleEnv name
  expr = expr.cdr
  bindings = expr.car
  forms = expr.cdr

  eval_keep_last forms, module_env

  global = Env.global_env
  bindings.each do |binding|
    #check_for_redef(binding.car, global)
    global.set! binding.car, eval_ly(binding.cdr.car, module_env)
  end

  name
end

# Append two lists. Complexity depends on the first list.
# TODO Potential candidate for optimization?
def append(c0, c1)
  if c0.empty?
    c1
  else
    cons(first(c0), append(c0.cdr, c1))
  end
end

def reverse(list)
  acc = list
  until list.empty?
    acc = cons(first(list), acc)
    list = rest(list)
  end
  acc
end

# Takes a List (list of expressions), calls eval_ly on each element
# and return a new list.
def eval_list(expr_list, env, force_eval)
  l = []
  until expr_list.empty?
    l << eval_ly(first(expr_list), env, force_eval, true)
    expr_list = rest(expr_list)
  end
  list(*l)
end

# Similar to eval_list, but only returns the last evaluated value.
# TODO Potential candidate for optimization?
def eval_keep_last(expr_list, env)
  if expr_list.empty?
    # No expressions in the list -> Just return nil
    list
  elsif rest(expr_list).empty?
    # Only one expression left -> Execute it and return.
    eval_ly(first(expr_list), env)
  else
    # At least 2 expressions left -> Execute the first and recurse
    eval_ly(first(expr_list), env, true)
    eval_keep_last(rest(expr_list), env)
  end
end

# Defines a new function or variable and puts it into the global LYRA_ENV.
# If `is_macro` is true, the function will not evaluate its arguments right away.
def ev_define(expr, env, is_macro)
  if first(expr).is_a?(List)
    # Form is `(define (...) ...)` (Function definition)
    name = first(first(expr))
    args_expr = rest(first(expr))
    body = rest(expr)

    # Create the function
    res = ev_lambda(args_expr, body, env, is_macro)
    res.name = name
  else
    # Form is `(define .. ...)` (Variable definition)
    name = first(expr) # Get the name
    val = second(expr)
    res = eval_ly(val, env) # Get and evaluate the value.
  end

  # Add the entry to the global environment.
  top_env(env).set!(name, res)

  name
end

# args_expr has the format `(args...)`
# body_expr has the format `expr...`
def ev_lambda(args_expr, body_expr, definition_env, is_macro = false)
  arg_arr = args_expr.to_a
  arg_count = arg_arr.size
  max_args = arg_count

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
  if expr.nil? || (expr.is_a?(List) && expr.empty?)
    list # nil evaluates to nil
  elsif expr.is_a?(Symbol)
    env.find expr # Get associated value from env
  elsif atom?(expr) || expr.is_a?(LyraFn)
    expr
  elsif expr.is_a? Array
    if expr.all? { |x| !x.is_a?(Symbol) && atom?(x) }
      expr
    else
      expr.map { |x| eval_ly x, env, force_eval, true }
    end
  elsif expr.is_a?(List)
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
        predicate = eval_ly(first(first(clauses)), env, force_eval)
        if predicate
          result = eval_ly(second(first(clauses)), env, force_eval)
          break
        end
        clauses = rest(clauses)
      end
      result
    when :lambda
      raise "lambda must take at least 1 argument." if expr.cdr.empty?

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
    when :"let*"
      raise "let* needs at least 1 argument." if expr.cdr.empty?
      bindings = second(expr)
      raise "let bindings must be a list." unless bindings.is_a?(List) || bindings.is_a?(EmptyList)

      body = rest(rest(expr))
      env1 = env
      unless bindings.empty?
        env1 = Env.new(nil, env)
        bindings.each do |b|
          env1.set!(b.car, eval_ly(b.cdr.car, env1, force_eval))
        end
      end

      # Execute the body.
      eval_keep_last(body, env1)
    when :"let1"
      raise "let1 needs at least 1 argument." if expr.cdr.empty?
      raise "let1 bindings must be a non-empty list." unless second(expr).is_a?(List)

      name = first(second(expr))
      val = eval_ly(second(second(expr)), env, force_eval) # Evaluate the value.
      env1 = Env.new nil, env
      env1.set!(name, val)
      eval_keep_last(rest(rest(expr)), env1) # Evaluate the body.
    when :let
      raise "let needs at least 1 argument." if expr.cdr.empty?
      bindings = second(expr)
      raise "let bindings must be a list." unless bindings.is_a?(List) || bindings.is_a?(EmptyList)

      body = rest(rest(expr))
      env1 = env
      unless bindings.empty?
        env1 = Env.new(nil, env)
        # Evaluate bindings in order using the old environment.
        bindings.each do |b|
          env1.set!(b.car, eval_ly(b.cdr.car, env, force_eval))
        end
      end

      # Execute the body.
      eval_keep_last(body, env1)
    when :"def-type"
      expr = expr.cdr
      new_lyra_type(expr.car, expr.cdr, env.next_module_env)
    when :quote
      # Quotes a single expression so that it is not evaluated when
      # passed.
      if rest(expr).empty? || !(rest(rest(expr)).empty?)
        raise "quote takes exactly 1 argument"
      end
      second(expr)
    when :"def-macro"
      # Same as define, but the 'is_macro' parameter is true.
      # Form: `(def-macro (name arg0 arg1 ...) body...)`
      ev_define(rest(expr), env, true)
    when :apply
=begin
      fn = second(expr)
      args = rest(rest(expr))
      args1 = nil
      until args.cdr.empty?
        #args1 = cons(eval_ly(args.car, env, force_eval, true), args1)
        args1 = cons(args.car, args1)
        args = args.cdr
      end
      last_arg = args.car
      args1 = reverse(args1) + last_arg.to_cons_list
      expr = cons(fn, args1)
      eval_ly(expr, env, force_eval)
=end
      raise "apply is not implemented."
    when :module
      ev_module expr
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

      # The arguments which will be passed to the function.
      args = rest(expr)

      # If `expr` had the form `((...) ...)`, then the result of the
      # inner list must be executed too.
      func = eval_ly(func, env, force_eval) if func.is_a?(List)

      if func.native?
        $lyra_call_stack = cons(func, $lyra_call_stack)
        args = eval_list(args, env, force_eval)
        r = func.call(args, env)
        $lyra_call_stack = $lyra_call_stack.cdr
        r
      elsif func.is_macro
        # The macro is first called and the resulting expression
        # is then executed.
        r1 = func.call(args, env)
        #puts r1
        # TODO Figure out how to do macro-expand here without setting car or cdr...
        eval_ly(r1, env, force_eval)
      else
        # Check whether a tailcall is possible
        # A tailcall is possible if the function is not natively implemented
        # and the same function is at the front of the call stack.
        # So `(define (crash n) (crash (inc n)))` will tail call,
        # but `(define (crash) (inc (crash)))` will not.
        # Notice that the special commands if, let* and let (and all macros
        # which boil down to them, like `begin`) do not go on the callstack.
        # So `(define (dotimes n f)
        #       (if (= 0 n) '() (begin (f) (dotimes (dec n) f))))`
        # will also tail call.
        if !is_in_call_params && (!$lyra_call_stack.empty?) && ((func == $lyra_call_stack.car) || func == RECUR_FUNC)
          # Evaluate arguments that will be passed to the call.
          args = eval_list(args, env, force_eval)
          # Tail call
          raise TailCall.new(args)
        else
          $lyra_call_stack = cons(func, $lyra_call_stack)

          # Evaluate arguments that will be passed to the call.
          args = eval_list(args, env, force_eval)

          # Call the function with the new arguments
          r = func.call(args, env)

          # Remove from the callstack.
          $lyra_call_stack = $lyra_call_stack.cdr

          r
        end
      end
    end
  else
    raise "Unknown type. (Object is #{expr})"
  end
end

