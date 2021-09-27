require_relative 'types.rb'
require_relative 'reader.rb'
require_relative 'core.rb'

# nil is not a valid pair but will be used as a separator between
# local LYRA_ENV and global LYRA_ENV.
unless Object.const_defined?(:LYRA_ENV)
  LYRA_ENV = LyraEnv.new(nil)
  $lyra_call_stack = EmptyList.instance # Call stack starts as empty list.
  setup_core_functions
end

# Parses and evaluates a string as Lyra-source code.
def evalstr(s, env = LYRA_ENV)
  ast = make_ast(tokenize(s))
  eval_keep_last(ast, env)
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
def pairs(cons0, cons1, expect_vargs = false, res = [])
  if cons0.empty?
    res
  elsif cons1.empty?
    res << List.create(first(cons0), list)
    pairs(cons0.cdr, list, expect_vargs, res)
  elsif expect_vargs && cons0.cdr.empty? && cons1.cdr.empty?
    res << List.create(cons0.car, List.create(cons1.car, list))
    res
  elsif cons0.cdr.empty? && !(cons1.cdr.empty?)
    res << List.create(first(cons0), cons1)
    res
  else
    res << List.create(first(cons0), first(cons1))
    pairs(cons0.cdr, cons1.cdr, expect_vargs, res)
  end
end

# Search environment for symbol
def associated(x, env)
  env.find(x)
end

# Append two lists. Complexity depends on the first list.
# TODO Potential candidate for optimization?
def append(c0, c1)
  if c0.empty?
    c1
  else
    List.create(first(c0), append(c0.cdr, c1))
  end
end

def reverse(list)
  acc = list
  until list.empty?
    acc = List.create(first(list), acc)
    list = rest(list)
  end
  acc
end

# Takes a List (list of expressions), calls eval_ly on each element
# and return a new list.
# TODO Potential candidate for optimization?
def eval_list(expr_list, env)
  l = list
  until expr_list.empty?
    l = List.create(eval_ly(first(expr_list),env,true),l)
    expr_list= rest(expr_list)
  end
  l
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
  LYRA_ENV.add(name, res)

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

    if definition_env.__id__ == LYRA_ENV.__id__
      env1 = LyraEnv.new(LYRA_ENV).add_pairs(arg_pairs)
    else
      env1 = LyraEnvPair.new(definition_env, environment).add_pairs(arg_pairs)
    end

    # Execute all commands in the body and return the last
    # value.
    eval_keep_last(body_expr, env1)
  end
end

# Evaluation function
def eval_ly(expr, env, is_in_call_params = false)
  if expr.nil? || (expr.is_a?(List) && expr.empty?)
    list # nil evaluates to nil
  elsif expr.is_a?(Symbol)
    associated(expr, env) # Get associated value from env
  elsif atom?(expr) || expr.is_a?(LyraFn)
    expr
  elsif expr.is_a? Array
    if expr.all? { |x| !x.is_a?(Symbol) && atom?(x) }
      expr
    else
      arr.map { |x| eval_ly x, env, true }
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
      raise "if needs 3 arguments." if list_len(expr) < 4 # includes the 'if
      pres = eval_ly(second(expr), env)
      #uts "In if: " + pres.to_s
      if pres != false && pres != nil && !pres.is_a?(EmptyList)
        # The predicate was true
        eval_ly(third(expr), env)
      else
        # The predicate was not true
        eval_ly(fourth(expr), env)
      end
    when :cond
      clauses = rest(expr)
      result = nil
      until clauses.empty?
        predicate = eval_ly(first(first(clauses)), env)
        if predicate
          result = eval_ly(second(first(clauses)), env)
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
      raise "let* bindings must be a list." unless second(expr).is_a?(List)

      bindings = second(expr)
      body = rest(rest(expr))
      env1 = LyraEnv.new(env)

      bindings.each do |b|
        env1.add(b.car, eval_ly(b.cdr.car, env1))
      end

      # Execute the body.
      eval_keep_last(body, env1)
    when :"let1"
      raise "let1 needs at least 1 argument." if expr.cdr.empty?
      raise "let1 bindings must be a list." unless second(expr).is_a?(List)

      # `expr` has the following form:
      # (let1 (name value) body...)
      # The binding (name-value pair) is evaluated and added to the
      # environment. Then the body is executed and the result of the
      # last expression returned.
      # If the body is empty, returns nil.
      name = first(second(expr))
      val = eval_ly(second(second(expr)), env) # Evaluate the value.
      env1 = LyraEnv.new env
      env1.add(name, val)
      eval_keep_last(rest(rest(expr)), env1) # Evaluate the body.
    when :let
      raise "let needs at least 1 argument." if expr.cdr.empty?
      raise "let bindings must be a list." unless second(expr).is_a?(List)

      # 'expr' has the following form:
      # (let ((sym0 val0) (sym1 val1) ...) body...)
      # The bindings (sym-val pairs) are evaluated, added to the environment
      # and then the body is evaluated. The last returned value is returned.

      bindings = second(expr)
      body = rest(rest(expr))
      env1 = LyraEnv.new(env)

      # Evaluate bindings in order using the old environment.
      bindings.each do |b|
        env1.add(b.car, eval_ly(b.cdr.car, env))
      end

      # Execute the body.
      eval_keep_last(body, env1)
    when :quote
      # Quotes a single expression so that it is not evaluated when
      # passed.
      if rest(expr).empty? || !(rest(rest(expr)).empty?)
        raise "quote takes exactly 1 argument"
      end
      second(expr)
    when :"def-macro"
      # Same as define, but the 'ismacro' parameter is true.
      # Form: `(def-macro (name arg0 arg1 ...) body...)`
      ev_define(rest(expr), env, true)
    when :apply
      fn = second(expr)
      args = rest(rest(expr))
      args1 = nil
      until args.cdr.empty?
        args1 = List.create(eval_ly(args.car, env, true), args1)
        args = args.cdr
      end
      last_arg = args.car
      last_arg = eval_ly(list(:"->list", last_arg), env)
      args = eval_list(last_arg, env)
      args1 = append(reverse(args1), args)
      expr = List.create(fn, args1)
      eval_ly(expr, env)
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

      # The arguments which will be passed to the function.
      args = rest(expr)

      # If `expr` had the form `((...) ...)`, then the result of the
      # inner list must be executed too.
      func = eval_ly(func, env) if func.is_a?(List)

      if func.native?
        $lyra_call_stack = List.create(func, $lyra_call_stack)
        args = eval_list(args, env)
        r = func.call(args)
        $lyra_call_stack = $lyra_call_stack.cdr
        r
      elsif func.ismacro
        # The macro is first called and the resulting expression
        # is then executed.
        r1 = func.call(args, env)
        eval_ly(r1, env)
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
        if !is_in_call_params && (!$lyra_call_stack.empty?) && (func == $lyra_call_stack.car)
          # Evaluate arguments that will be passed to the call.
          args = eval_list(args, env)
          # Tail call
          raise TailCall.new(args)
        else
          $lyra_call_stack = List.create(func, $lyra_call_stack)

          # Evaluate arguments that will be passed to the call.
          args = eval_list(args, env)

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

