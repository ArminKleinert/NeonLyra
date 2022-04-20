#!/usr/bin/env ruby
# frozen_string_literal: true

require_relative 'types.rb'
require_relative 'reader.rb'
require_relative 'core.rb'
require_relative 'env.rb'

$show_expand_macros = false
$enable_aggressive_optimizations = false

IMPORTED_MODULES = []

# nil is not a valid pair but will be used as a separator between
# local LYRA_ENV and global LYRA_ENV.
unless Object.const_defined?(:LYRA_ENV)
  LYRA_ENV = Env.global_env
  LYRA_CALL_STACK = [] # Call stack starts as empty list.
  setup_core_functions
end

begin
  f = lambda do |name|
    r = CompoundFunc.new(
      name, list(:xs), list(:"error", "#{name} must not be called directly.", :"invalid-call"),
      nil, false, 0, -1)
    Env.global_env.set! name, r
  end

  f.call :recur
  RECUR_FUNC = Env.global_env.find :recur
  f.call :"lambda*"
  f.call :"let"
  f.call :"let*"
  f.call :"if"
  f.call :"def-type"
  f.call :"define"
  f.call :"def-impl"
  f.call :"def-generic"
  f.call :"def-macro"
  f.call :"lazy-seq"
  f.call :"module"
  f.call :"quote"
  f.call :"lazy"
  f.call :"try*"
  f.call :"catch"
  f.call :"expand-macro"

  f.call :"lambda"
  f.call :"cond"
  
  DO_NOTHING_AND_RETURN = gensym(:id)
  f.call DO_NOTHING_AND_RETURN
end

# destructure [:a,:b,:c,:"&",:xs], [1,2,3,4,5,6,7,8,9,10]
#   [[[:a, 1], [:b, 2], [:c, 3], [:xs, 4]], [:xs, [5, 6, 7, 8, 9, 10]]]
# destructure [:a,:b,:c,:xs], [1,2,3,4,5,6,7,8,9,10]
#   [[[:a, 1], [:b, 2], [:c, 3], [:xs, 4]], [nil, nil]]
# destructure [:a,:b,:c], [1,2]
#   [[[:a, 1], [:b, 2], [:c, nil]], [nil, nil]]
def destructure(names, args)
  xs = []
  rest_args = nil

  # TODO Make sure that :& is the second to last, if it is given at all.
  i = names.index :&
  puts i
  names = [names[0...i], i.nil? ? nil : names[-1]]

  args.each do |e|
    xs << e
  end

  rest_args = i.nil? ? nil : xs[names[0].size..-1]
  xs = xs[0...names[0].size]
  args.fill(names.size..args.size)
  [names[0].zip(xs), [names[1], rest_args]]
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

  return name if IMPORTED_MODULES.include? name
  IMPORTED_MODULES << name

  module_env = Env.create_module_env name
  expr = expr.cdr
  bindings = expr.car
  forms = expr.cdr
  raise LyraError.new("Syntax error: Module bindings must be a list.", :syntax) unless bindings.is_a?(ConsList)
  raise LyraError.new("Syntax error: Module forms must be a list.", :syntax) unless bindings.is_a?(ConsList)

  eval_keep_last forms, module_env

  global = Env.global_env
  bindings.each do |binding|
    #check_for_redef(binding.car, global)
    if binding.is_a? ConsList
      global.set! binding.car, eval_ly(binding.cdr.car, module_env)
    elsif binding.is_a? Symbol
      global.set! binding, eval_ly(binding, module_env)
    else
      raise LyraError.new("Syntax error: Module binding must be a list or symbol.", :syntax)
    end
  end

  name
end

# Takes a List (list of expressions), calls eval_ly on each element
# and return a new list.
def eval_list(expr_list, env, force_eval)
  raise LyraError.new("Syntax error: Expression must be a list.", :syntax) unless expr_list.is_a?(ConsList)
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
def eval_keep_last(expr_list, env, force_eval = false)
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

    eval_ly expr_list.car, env, force_eval, true
    expr_list = expr_list.cdr
  end

  eval_ly expr_list.car, env, force_eval
end

def ev_define_fn(expr, env, is_macro)
  unless first(first(expr)).is_a?(Symbol)
    raise LyraError.new("Syntax error: Name of function in define must be a symbol.", :syntax)
  end

  name = first(first(expr))
  args_expr = rest(first(expr))
  body = rest(expr)

  # Create the function
  res = ev_lambda(name, args_expr, body, env, is_macro)

  # Add the entry to the global environment.
  top_env(env).set!(name, res)

  name
end

def ev_define_generic(expr, env)
  if expr.size != 3
    raise LyraError.new("Syntax error: Invalid format of def-generic.", :syntax)
  end

  ref_arg = first(expr)
  unless ref_arg.is_a? Symbol
    raise LyraError.new("Syntax error: Generic function reference argument must be a symbol.", :syntax)
  end

  args_expr = second(expr)
  unless args_expr.is_a?(List)
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
    raise LyraError.new("Syntax error: Implementation of function #{global_name} must be a function.", :syntax)
  end

  fn.add_implementation! eval_ly(first(expr), env), impl

  third(expr)
end

# Defines a new function or variable and puts it into the global LYRA_ENV.
# If `is_macro` is true, the function will not evaluate its arguments right away.
def ev_define(expr, env, is_macro)
  unless expr.size >= 2
    raise LyraError.new("Syntax error: No name and no body for define or def-macro.", :syntax)
  end
  unless first(expr).is_a?(List) || first(expr).is_a?(Symbol) || first(expr).is_a?(TypeName)
    raise LyraError.new("Syntax error: First element in define or def-macro must be a list or symbol.", :syntax)
  end

  if first(expr).is_a?(List)
    # Form is `(define (...) ...)` (Function definition)
    ev_define_fn(expr, env, is_macro)
    #elsif first(expr).is_a?(Symbol) && expr.size == 3
    # Form is `(define .. (...) ...)` (Generic function definition)
    #  ev_define_with_type(expr, env, is_macro)
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
def ev_lambda(name, args_expr, body_expr, definition_env, is_macro = false)
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

# Evaluation function
def eval_ly(expr, env, force_eval = false, is_in_call_params = false)
  if expr.nil? || (expr.is_a?(ConsList) && expr.empty?)
    expr
  elsif expr.is_a?(Symbol)
    x = env.find(expr) # Get associated value from env
    if x.is_a?(Alias)
      x.get(env)
    else
      x
    end
  elsif expr.is_a?(Lazy) && force_eval
    expr.evaluate
  elsif atom?(expr) || expr.is_a?(LyraFn) || expr.is_a?(WrappedLyraError)
    expr
  elsif expr.is_a?(Array)
    if force_eval
      expr.map { |x| eval_ly x, env, force_eval, true }
    elsif expr.all? { |x| !x.is_a?(Symbol) && atom?(x) }
      # Nothing to evaluate.
      expr
    else
      expr.map { |x| eval_ly x, env, force_eval, true }
    end
  elsif expr.is_a?(Hash)
    (expr.map { |k, v| eval_ly [k, v], env, force_eval, true }).to_h
  elsif expr.is_a?(Set)
    (expr.map { |x| eval_ly x, env, force_eval, true }).to_set
  elsif expr.is_a?(Alias)
    expr.get(env)
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
      raise LyraError.new("if needs 3 arguments.", :syntax) if expr.size != 4 # includes the 'if
      pred = eval_ly(second(expr), env, force_eval, true)
      if !force_eval && pred.is_a?(LazyObj)
        #puts pred
        expr = LazyObj.new expr, env
        eval_ly(expr, env)
      elsif pred != false && !pred.nil? && !pred.is_a?(EmptyList)
        # The predicate was true
        eval_ly(third(expr), env, force_eval)
      else
        # The predicate was not true
        eval_ly(fourth(expr), env, force_eval)
      end

    when :cond
      clauses = rest(expr)
      result = nil
      until clauses.size == 0
        p = eval_ly(first(clauses), env, force_eval, true)
        if clauses.size == 1
          result = p
        elsif !force_eval && p.is_a?(LazyObj)
          expr = LazyObj.new expr, env
          result = eval_ly(expr, env)
          break
        elsif p
          result = eval_ly(second(clauses), env, force_eval)
          break
        end
        clauses = rest(rest(clauses))
      end
      result

    when DO_NOTHING_AND_RETURN
      eval_ly(second(expr), env, force_eval)
    when :lambda
      raise LyraError.new("lambda without bindings.", :syntax) if expr.cdr.empty?

      # Defines an anonymous function.
      # Form: `(lambda (arg0 arg1 ...) body...)`
      # If the body is empty, the lambda returns nil.
      args_expr = second(expr)
      body_expr = rest(rest(expr))
      ev_lambda(gensym("lambda"), args_expr, body_expr, env)
    when :"lambda*"
      raise LyraError.new("lambda* without name.", :syntax) if expr.cdr.empty?
      raise LyraError.new("lambda* without bindings.", :syntax) if expr.cdr.cdr.empty?
      raise LyraError.new("lambda* name must be a symbol.", :syntax) if !second(expr).is_a?(Symbol)

      # Defines an anonymous function.
      # Form: `(lambda* name (arg0 arg1 ...) body...)`
      # If the body is empty, the lambda returns nil.
      name = second(expr)
      args_expr = second(rest(expr))
      body_expr = rest(rest(rest(expr)))
      fn = ev_lambda(name.to_sym, args_expr, body_expr, env)
      fn
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
        env1 = Env.new(nil, env)
        bindings.each do |b|
          raise LyraError.new("Syntax error: Binding in let* must have 2 parts.", :syntax) unless b.is_a?(List) && b.size == 2
          raise LyraError.new("Syntax error: Name of binding in let* must be a symbol.", :syntax) unless b.car.is_a?(Symbol)
          env1.set!(b.car, eval_ly(b.cdr.car, env1, force_eval, true))
        end
      end

      # Execute the body.
      eval_keep_last(body, env1)
    when :let
      raise LyraError.new("Syntax error: let needs at least 1 argument.") if expr.cdr.empty?
      bindings = second(expr)
      raise LyraError.new("Syntax error: let bindings must be a list.") unless bindings.is_a?(ConsList) || bindings.is_a?(Array)

      body = rest(rest(expr))
      env1 = Env.new(nil, env)
      if bindings.is_a?(Array)
        # Evaluate bindings in order using the old environment.
        bindings.each_slice(2) do |name, val|
          raise LyraError.new("Syntax error: Name of binding in let must be a symbol.") unless name.is_a?(Symbol)
          env1.set!(name, eval_ly(val, env1, force_eval, true))
        end
      else
        bindings.each do |b|
          raise LyraError.new("Syntax error: Binding in let must have 2 parts.") unless b.is_a?(List) && b.size == 2
          raise LyraError.new("Syntax error: Name of binding in let must be a symbol.") unless b.car.is_a?(Symbol)
          env1.set!(b.car, eval_ly(b.cdr.car, env, force_eval, true))
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
    when :"def-macro"
      # Same as define, but the 'is_macro' parameter is true.
      # Form: `(def-macro (name arg0 arg1 ...) body...)`
      ev_define(rest(expr), env, true)
    when :module
      ev_module expr
    when :lazy
      if expr.cdr.size != 1
        raise LyraError.new("Wrong number of arguments for lazy. (Expected 1, got #{expr.cdr.size})")
      end
      if force_eval
        eval_ly(expr.cdr.car, env, force_eval)
      else
        LazyObj.new expr.cdr.car, env
      end
    when :"lazy-seq"
      if expr.cdr.size != 2
        raise LyraError.new("Wrong number of arguments for lazy-seq. (Expected 2, got #{expr.cdr.size})")
      end
      LazyList.create eval_ly(expr.cdr.car, env), lambda { eval_ly(expr.cdr.cdr.car, env) }
    when :"try*"
      # Form: (try* <expr> (catch <ex-name> <validator> <body>)
      #       (try* <expr> (catch <ex-name> <body>)
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
          res = eval_ly(body, env, force_eval)
        rescue LyraError => error
          # Error caught
          # Register error in new env
          env1 = Env.new(nil, env)
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
            res = eval_keep_last(clause, env1, force_eval)
          else
            raise error
          end
        end
        res
      else
        raise LyraError.new("No catch-clause in try*", :syntax)
      end
    when :"expand-macro"
      func = eval_ly(expr.cdr.car, env, force_eval, true)
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
    when :alias
      if expr.size != 2
        raise LyraError.new("Wrong number of arguments for alias. (Expected 1, got #{expr.cdr.size})")
      end
      Alias.new(expr.cdr.car)
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

      raise LyraError.new("Runtime error: Expected a function, got #{elem_to_pretty(func)}", :expected_function) unless func.is_a?(LyraFn)

      # If the function is not pure, force evaluation.
      force_eval = true unless func.pure?

      if func.native?
        LYRA_CALL_STACK.push func
        args = eval_list(args, env, force_eval)

        if !force_eval && args.any? { |e| e.is_a?(LazyObj) }
          #r = LazyObj.new cons(func, args), env # FIXME Buggy
          r = func.call(args, env)
        else
          # Call the function with the new arguments
          r = func.call(args, env)
        end

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
          args = eval_list(args, env, true)
          # Tail call
          raise TailCall.new(args)
        else
          LYRA_CALL_STACK.push func

          # Evaluate arguments that will be passed to the call.
          args = eval_list(args, env, force_eval)

          if !force_eval && args.any? { |e| e.is_a?(LazyObj) }
            #r = LazyObj.new cons(func, args), env # FIXME Buggy
            r = func.call(args, env)
          else
            # Call the function with the new arguments
            r = func.call(args, env)
          end
          # Remove from the callstack.
          LYRA_CALL_STACK.pop

          r
        end
      end
    end
  else
    raise LyraError.new("Unknown type. (Object is #{expr})")
  end
end

