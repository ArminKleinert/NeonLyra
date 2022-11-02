
  add_fn_with_env(:"iterate-seq", 3) do |xs, env|
    func, acc, vec = xs.to_a
    vec.each_with_index do |x, i|
      acc = func.call(list(acc, x, i), env)
    end
    acc
  end
  add_fn_with_env(:"iterate-seq-p", 4) do |xs, env|
    pred, func, acc, vec = xs.to_a
    vec.each_with_index do |x, i|
      temp = list(acc, x, i)
      break unless pred.call(temp, env)
      acc = func.call(temp, env)
    end
    acc
  end

  add_fn(:"map-of", 0, -1) { |*xs| xs.each_slice(2).to_a.to_h }
  add_fn(:"map-size", 1) { |m| m.size }
  add_fn(:"map-get", 2) { |m, k| m.is_a?(Hash) ? m[k] : raise("#{m} is not a map.") }
  add_fn(:"map-set", 3) { |m, k, v| m2 = Hash[m]; m2[k] = v; m2 }
  add_fn(:"map-remove", 2) { |m, k| m.select { |k1, _| k != k1 } }
  add_fn(:"map-keys", 1) { |m| m.keys }
  add_fn(:"map-merge", 2) { |m, m2| Hash[m].merge!(m2) }
  add_fn(:"map-has-key?", 2) { |m, k| m.has_key? k }
  add_fn(:"map-has-value?", 2) { |m, v| m.has_value? v }
  add_fn(:"map-entries", 1) { |m| m.to_a }
  add_fn(:"map->vector", 1) { |m| m.to_a }
  add_fn(:"map-eq?", 2) { |m, m1| m == m1 }

  add_fn(:"buildin-set-of", 0, -1) { |*xs| xs.to_set }
  add_fn(:"buildin-set-size", 1) { |s| s.size }
  add_fn(:"buildin-set-add", 2) { |s, e| s.add e }
  add_fn(:"buildin-set-union", 2) { |s0, s1| s0 | s1 }
  add_fn(:"buildin-set-difference", 2) { |s0, s1| s0 - s1 }
  add_fn(:"buildin-set-intersection", 2) { |s0, s1| s0 & s1 }
  add_fn(:"buildin-set-includes?", 2) { |s, e| s.include? e }
  add_fn(:"buildin-set-subset?", 2) { |s0, s1| s0 <= s1 }
  add_fn(:"buildin-set-true-subset?", 2) { |s0, s1| s0 < s1 }
  add_fn(:"buildin-set-superset?", 2) { |s0, s1| s0 >= s1 }
  add_fn(:"buildin-set-true-superset?", 2) { |s0, s1| s0 > s1 }
  add_fn(:"buildin-set->vector", 1) { |s| s.to_a }
  add_fn(:"buildin-set-eq?", 2) { |s, s1| s == s1 }

  def foldr(f, v, xs, env)
    xs.to_a.reverse_each do |e|
      v = f.call(list(e, v), env)
    end
    v
  end

  add_fn_with_env(:"buildin-foldr", 3) do |args, env|
    f = args.car
    v = args.cdr.car
    xs = args.cdr.cdr.car
    foldr(f, v, xs, env)
  end

  add_fn_with_env(:"buildin-foldl", 3) do |args, env|
    f = args.car
    v = args.cdr.car
    xs = args.cdr.cdr.car
    xs.each do |x|
      v = f.call(list(v, x), env)
    end
    v
  end

  add_fn(:"buildin-contains?", 2) { |c, e| c.include? e }

  add_fn(:"buildin-nth", 2) { |c, i| c.is_a?(Enumerable) ? c[i] : nil }

  add_fn(:"buildin-strcat", 2) { |s, e| s.to_s + elem_to_s(e) }

  add_fn(:"buildin-append", 2) do |x, y|
    if x.is_a? String
      x + elem_to_s(y)
    elsif !x.is_a?(Enumerable) || !y.is_a?(Enumerable)
      nil
    elsif x.is_a? List
      x + y
    elsif x.is_a? Array
      x + y.to_a
    else
      x.to_cons_list + y.to_cons_list
    end
  end

  add_fn(:"buildin-print!", 1) { |x| print elem_to_s(x) }
  add_fn(:"readln!", 0) { gets }
  add_fn(:"file-read!", 1) { |name| IO.read name }
  add_fn(:"file-write!", 2) { |name, text| IO.write name, text }
  add_fn(:"file-append!", 2) { |name, text| File.open(name, 'a') { |f| f.write(text) } }

  add_fn(:copy, 1) { |x| x.is_a?(Box) ? x.clone : x }

  add_fn(:memoize, 1) { |fn| MemoizedLyraFn.new fn }

  add_var(:Nothing, nil)

  add_fn_with_env(:"load!", 1) do |xs, env|
    file = xs.car
    prefix = xs.cdr.car
    eval_str(IO.read(file), Env.global_env)
  end

  add_fn_with_env(:"import!", 2) do |xs, env|
    mod_name = xs.car.to_sym
    alias_name = xs.cdr.car

    mod = IMPORTED_MODULES.lazy

    if mod.respond_to?(:filter)
      mod = mod.filter{|e|e.name == mod_name}.to_a.first
    else
      # select is an older version of filter. It forces the creation of an array and does not preserve  the lazyness of the Enumerable.
      mod = mod.select{|e|e.name == mod_name}.first
    end

    if !mod.nil?
      mod.bindings.each do |bind1|
        bind = bind1.to_s.split("/", 2)[-1]

        if alias_name.empty?
          bind = bind.to_sym
        else
          bind = (alias_name + "/" + bind).to_sym
        end

        env.next_module_env.set_no_export! bind, Env.global_env.find(bind1)
        #puts "#{alias_name} #{alias_name.empty?} #{bind1} #{bind}"
      end

      list(mod.name, mod.abstract_name)
    else
      nil
    end
  end

  add_fn(:"read-string", 1) do |s|
    tokens = tokenize(s)
    ast = make_ast(tokens)
    if tokens[0] == "(" && ast.size > 1
      ast
    else
      ast[0]
    end
  end

  add_fn_with_env(:"eval!", 1) { |x, env| eval_ly first(x), env }

  add_fn_with_env(:"measure!", 2) { |args, env|
    median = lambda do |arr|
      arr.sort!
      len = arr.size
      (arr[(len - 1) / 2] + arr[len / 2]) / 2
    end

    runs = args.car
    f = args.cdr.car
    res = Array.new(runs)
    runs.times do |i|
      t0 = Time.now
      f.call(list, env)
      t1 = Time.now
      res[i] = (t1 - t0) * 1000.0
    end
    median.call(res) }

  add_fn(:sqrt, 1) { |n| Math.sqrt(n) }

  add_fn(:ljust, 2) { |x, n| elem_to_s(x).ljust(n) }

  add_fn_with_env(:"apply-to", 2) { |xs, env| first(xs).call(second(xs).force, env) }

  [NOTHING_TYPE, BOOL_TYPE, VECTOR_TYPE, MAP_TYPE, LIST_TYPE, FUNCTION_TYPE,
   INTEGER_TYPE, FLOAT_TYPE, RATIO_TYPE, SET_TYPE, TYPE_NAME_TYPE, STRING_TYPE,
   SYMBOL_TYPE, BOX_TYPE, ERROR_TYPE, CHAR_TYPE, KEYWORD_TYPE,
   DELAY_TYPE].each do |t|
    add_var t.to_sym, t
  end

  add_fn_with_env(:"class", 1) { |x, _| type_of(x.car) }

  add_fn(:"error!", 1, 3) { |msg, info, trace| raise LyraError.new(msg, info, trace) }

  add_fn(:"error-msg", 1) { |e| e.msg }
  add_fn(:"error-info", 1) { |e| e.info }
  add_fn(:"error-trace", 1) { |e| e.trace }

  add_fn(:"exit!", 1) { |s| exit(s) }

  add_fn(:"callstack", 0) { LYRA_CALL_STACK }
