# File: core.lyra



## Macros

### Macro `par'` 
```
  par' : [expr]* -> expr
  
  Pure? Yes
  
  Takes a list of expressions and wraps each in a lambda. These functions are then evaluated by the par function.
```
### Macro `par-with-timeout'` 
```
  par-with-timeout' : expr -> [expr]* -> expr
  
  Pure? Yes
  
  Takes a number (timeout) and a list of expressions and wraps each in a lambda. These functions are then evaluated by the par-with-timeout function. Timeouts <= 0 mean an infinite timeout. (Might as well use par')
```
### Macro: `->` 
```
  -> : expr -> [expr]* -> expr
  
  Pure? Yes
  
  As in Clojure.
```
### Macro: `->>` 
```
  ->> : expr -> [expr]* -> expr
  
  Pure? Yes
  
  As in Clojure.
```
### Macro: `and` 
```
  and : expr -> expr -> expr
  
  Pure? Yes
  
  Macro for lazy `and`.
   (and x y) returns y if x is #t or returns #f if x is not true.
```
### Macro: `as->` 
```
  as-> : symbol -> expr -> [expr]* -> expr
  
  Pure? Yes
  
  As in Clojure.
```
### Macro: `begin` 
```
  begin : [expr]* -> expr
  
  Pure? Yes
  
  Perform operations sequencially.
```
### Macro: `case` 
```
  case : expr -> [any, expr]* -> expr
  
  Pure? Yes
```
### Macro: `case-lambda` 
```
  case-lambda : (expr, expr) -> [(expr, expr)]* -> expr
  
  Pure? Yes
  
  case-lambda* without a necessary name. Supports destructuring.
```
### Macro: `case-lambda*` 
```
  case-lambda* : symbol -> (expr, expr) -> [(expr, expr)]* -> expr
  
  Pure? Yes
  
  Create a multi-function:
  (define f (case-lambda* f
    (() "0") ; 0 args
    ((x) "1") ; 1 arg
    ((x y) "2") ; 2 args
    ((w x y z & zs) "4 or more") ; 4+ args
    (default "3"))) ; Varargs going into a list called 'default
  When called, the function decides which function to call by the number of arguments it got.
  (list (f) (f 6) (f 6 7) (f 6 7 8 9) (f 5 4 3)) ; ("0" "1" "2" "4 or more" "3")
```
### Macro: `comment` 
```
  comment : [expr]* -> Nothing
  
  Pure? Yes
  
  Take any number arguments and return Nothing.
```
### Macro: `compute*->` 
```
  compute*-> : expr -> expr -> expr -> [expr]* -> expr
  
  Pure? Yes
  
  Similar to '->> but stops when the value becomes
  Nothing or an exception is thrown.
  if the value becomes nothing, default is returned.
  if an error is thrown, error-default is returned
    (compute*-> 'default 'error 1 inc inc inc)  ; => 4
    (compute*-> 'default 'error 1 (+ 3) inc))   ; => 5
    (compute*-> 'default 'error 1 ->list first) ; => default
    (compute*-> 'default 'error 0 throw! inc)   ; => error
    (compute*-> 'default 'error "r")            ; => "r"
```
### Macro: `compute->` 
```
  compute-> : expr -> [expr]* -> expr
  
  Pure? Yes
  
  Like compute*-> but the special cases all return Nothing.
    (compute-> 1 inc inc inc)  ; => 4
    (compute-> 1 (+ 3) inc))   ; => 5
    (compute-> 1 ->list first) ; => Nothing
    (compute-> 0 throw! inc)   ; => Nothing
    (compute-> "r")            ; => "r"
```
### Macro: `cond` 
```
  cond : [expr]* -> expr
  
  Pure? Yes
  
  `if` with multiple arguments.
  `(cond a b c d else e)` is equivalent to `(if a b (if c d (if else e Nothing)))`.
  `(cond a b c d e)` if equivalent to `(if a b (if c d e))`.
```
### Macro: `condp` 
```
  condp : (any -> any -> bool) -> expr -> [(expr, expr)]* -> expr´
  
  Pure? Yes
  
  (let* ((f0 (lambda (e) (condp <= e  1 0  5 9  11))))
    (f0 0) ; 0
    (f0 1) ; 0
    (f0 3) ; 9
    (f0 6)) ; 11 ; default
```
### Macro: `def-memo` 
```
  def-memo : list|vector -> [expr]* -> (any* -> any)
  
  Pure? Yes
  
  define memoized function.
```
### Macro: `define*` 
```
  define* : [list|vector] -> [expr]* -> expr
  
  Pure? Yes
  
  Extended define.
  Supports destructuring.
  Will support keyword arguments in the future
```
### Macro: `for` 
```
  for : list -> expr -> expr
  
  Pure? Yes
```
### Macro: `lambda` 
```
  lambda : list|vector -> [expr]* -> expr
  
  Pure? Yes
  
  Simplified lambda* which auto-generates a name.
  The rest is the same. Does not require any special functions, only buildins.
```
### Macro: `lambda'` 
```
  lambda' : list -> [expr]* -> expr
  lambda' : symbol -> list -> [expr]* -> expr
  
  Pure? Yes
  
  Supports destructuring.
  
  This lambda will take a list of at least 2 elements a and b and the rest of the list. It adds a to b and prepends the result to the list again.
   ((lambda' ((a b & rest)) (cons (+ a b) rest))
     '(1 2 3 4 5 6)) ; => (3 3 4 5 6)
  Or more generalized:
   (lambda' ((a b & rest)) (add-front rest (+ a b)))
  The destructuring works for any type that supports 'first and 'rest.

```
### Macro: `lazy-seq` 
```
  lazy-seq : expr -> [expr]* -> expr
  
  Pure? Yes
  
  Generates a lazy list.
  This allows for infinite sequences. Lyra does not understand the simpler syntax that languages like Clojure and Scheme have.
  Example: `(define (iterate f start) (lazy-seq start (iterate f (f start))))`
```
### Macro: `let` 
```
  let : list|vector -> [expr]* -> expr
  
  Pure? Yes
```
### Macro: `let1` 
```
  let1 : list|vector -> [expr]* -> expr
  
  Pure? Yes
  
  Simpler let for a single binding.
  (let1 (a 1) a) is equivalent to (let*((a 1)) a)
```
### Macro: `letfn` 
```
  letfn : sequence -> expr* -> expr
  
  Pure? Yes
  
  (letfn ((f1 (a) (* a 2))
          (f2 (& a) (map odd? a)))
     (println! (f1 2)) ; => 4
     (println! (f1 44))) ; => 88
```
### Macro: `loop` 
```
  loop : list|vector -> [expr]* -> expr
  
  Pure? Yes
  
  loop macro similar to clojure. Supports destructuring.
  (loop [(a b) '(1 2) res 0]
    (if (> res 0) res (recur '() (+ a b))))
  ;=> 3
```
### Macro: `loop` 
```
  loop : list|vector -> [expr]* -> expr
  
  Pure? Yes
  
  Simplified loop without destructuring
```
### Macro: `or` 
```
  or : expr -> expr -> expr
  
  Pure? Yes
  
  Macro for lazy `or`.
   (or x y) returns x if x is truthy or y if x is not truthy.
```
### Macro: `plet` 
```
  plet : expr -> [expr]* -> expr
  
  Pure? Yes
  
  Parallel let. Supports destructuring.
  The assignments are done in parallel, if possible.
  The body is still executed in order.
```
### Macro: `quasiquote` 
```
  quasiquote : expr -> expr
  
  Pure? Yes
  
  Quotes an expression. Sub-sxpressions can be unquoted using unquote and unquote-splicing.
```
### Macro: `try` 
```
  try : expr -> [expr]* -> expr
  
  Pure? Yes
  
  Extended try*-catch with finally.
  Can handle multiple catch-clauses.
  (try (error! 'h 'not-that)
    (catch (lambda (e) (eq? 'syntax (error-info e))) e 'error1)
    (catch _ e 'error2)
    (finally (box-set! b 25)))
    ;=> 'error2
```
### Macro: `λ` 
```
  λ : list|vector -> [expr]* -> expr
  
  Pure? Yes
  
  Plain alias for lambda.
```

## Functions

### Function: `->char` 
```
  ->char : any -> char
  
  Pure? Yes
  
  Tries to make a char from an element. Returns Nothing on error.
```
### Function: `->float` 
```
  ->float : any -> float
  
  Pure? Yes
  
  Tries to make an element into a float. Returns Nothing on error.
```
### Function: `->int` 
```
  ->int : any -> int
  
  Pure? Yes
  
  Tries to make an element into an int. Requires ->float. Returns Nothing on error.
```
### Function: `->int#char` 
```
  ->int#char : char -> int
  
  Pure? Yes
  
  Implementation for ->int.Gets the utf-8 code of the char.
```
### Function: `->int#float` 
```
  ->int#float : float -> ->int
  
  Pure? Yes
  
  Implementation for ->int. Rounds down.
```
### Function: `->int#int` 
```
  ->int#int : int -> int
  
  Pure? Yes
  
  Implementation for ->int. Does nothing for ints.
```
### Function: `->int#rational` 
```
  ->int#rational : rational -> int
  
  Pure? Yes
  
  Implementation for ->int. Rounds down.
```
### Function: `->keyword` 
```
  ->keyword : any -> keyword
  
  Pure? Yes
  
  Try to make an element into a keyword. Returns Nothing on error.
```
### Function: `->list` 
```
  ->list : any -> list
  
  Pure? Yes
  
  Tries to make a list from an element. Returns Nothing on error.
```
### Function: `->map` 
```
  ->map : any -> map
  
  Pure? Yes
  
  Tries to make a map from an element. The default uses ->list and a native helper. Even the default might fail. Returns Nothing on error.
  If the default is used, the list must have the format `((k v)*)`
```
### Function: `->map#list` 
```
  ->map#list : list -> map
  
  Pure? Yes
  
  Implementation for ->set
```
### Function: `->map#map` 
```
  ->map#map : map -> map
  
  Pure? Yes
  
  Implementation. Since the input is already a map, this returns the element itself.
```
### Function: `->rational` 
```
  ->rational : any -> rational
  
  Pure? Yes
  
  Tries to make an element into a ratonal. Returns Nothing on error.
```
### Function: `->rational#char` 
```
  ->rational#char : char -> rational
  
  Pure? Yes
  
  Implementation for ->rational.
```
### Function: `->rational#float` 
```
  ->rational#float : float -> rational
  
  Pure? Yes
  
  Implementation for ->rational.
```
### Function: `->rational#int` 
```
  ->rational#int : int -> rational
  
  Pure? Yes
  
  Implementation for ->rational.
```
### Function: `->rational#rational` 
```
  ->rational#rational : rational -> rational
  
  Pure? Yes
  
  Implementation for ->rational.
```
### Function: `->set` 
```
  ->set : any -> set
  
  Pure? Yes
  
  Try to make an element into a set. The default uses ->list and a native function. Returns Nothing on error.
```
### Function: `->set#list` 
```
  ->set#list : list -> set
  
  Pure? Yes
  
  Implementation for ->set
```
### Function: `->set#map` 
```
  ->set#map : map -> set
  
  Pure? Yes
  
  Implementation for ->set
```
### Function: `->string` 
```
  ->string : any -> string
  
  Pure? Yes
  
  Tries to make an element into a string. Returns an unreadable string on error.
```
### Function: `->string#list` 
```
  ->string#list : list -> map
  
  Pure? Yes
  
  Implementation for ->string.
```
### Function: `->string#map` 
```
  ->string#map : map -> string
  
  Pure? Yes
  
  Implementation for ->string.
```
### Function: `->symbol` 
```
  ->symbol : any -> symbol
  
  Pure? Yes
  
  Try to make an element into a symbol. Returns Nothing on error.
```
### Function: `->vector` 
```
  ->vector : any -> vector
  
  Pure? Yes
  
  Try to make an element into a vector. The default uses ->list and a native function. Returns Nothing on error.
```
### Function: `->vector#list` 
```
  ->vector#list : list -> vector
  
  Pure? Yes
  
  Implementation for ->vector
```
### Function: `->vector#map` 
```
  ->vector#map : map -> vector
  
  Pure? Yes
  
  Implementation for ->vector
```
### Function: `F` 
```
  F : ([any]* -> bool)
  
  Pure? Yes
  
  Always false
```
### Function: `T` 
```
  T : ([any]* -> bool)
  
  Pure? Yes
  
  Always true
```
### Function: `add` 
```
  add : collection -> any -> collection
  
  Pure? Yes
  
  Add an element y to the end of a collection xs.
```
### Function: `add#map` 
```
  add#map : map -> sequence -> map
  
  Pure? Yes
  
  Implementation for add. The sequence must have a size of 2.
```
### Function: `add-front` 
```
  add-front : collection -> any -> collection
  
  Pure? Yes
  
  Add an element y to the front of a sequence xs.
  Default implementation requires ->list and returns a list.
```
### Function: `add-front#list` 
```
  add-front#list : list -> any -> list
  
  Pure? Yes
  
  Implementation for add-front.
```
### Function: `add-front#map` 
```
  add-front#map : map -> sequence -> map
  
  Pure? Yes
  
  Implementation for add-front. Same as add. The sequence must have a size of 2.
```
### Function: `all?` 
```
  all? : (any -> bool) -> collection -> bool
  
  Pure? Yes
  
  Check whether a predicate is true for all elements in a collection xs.
  Requires empty?, first, rest and drop-while/drop-until to work.
```
### Function: `any?` 
```
  any? : (any -> bool) -> collection -> bool
  
  Pure? Yes
  
  Check whether a predicate is true for at least 1 element in a collection xs.
  Requires empty?, first, rest and drop-while/drop-until to work.
```
### Function: `append` 
```
  append : collection -> collection -> collection
  Append all elements from a sequence ys to collection xs. Requires: ->list.
  
  Pure? Yes
```
### Function: `append#map` 
```
  append#map : map -> collection -> collection
  
  Pure? Yes
  
  Implementation for append.
```
### Function: `apply` 
```
  apply : ([any]* -> any) -> [any]* -> any
  
  Pure? Yes
  
  Apply a function to a variable number of arguments with the last one being expanded using spread.
  (apply list 1 2 3 '(9 7 5)) ;=> (list 1 2 3 9 7 5) ;=> (1 2 3 9 7 5)
```
### Function: `but-last` 
```
  but-last : collection -> list
  
  Pure? Yes
  
  Get all elements, except for the last one from a collection. Requires ->list, first, rest, size.
```
### Function: `cartesian-product` 
```
  cartesian-product : sequence -> sequence -> list
  
  Pure? Yes
```
### Function: `chunk-map` 
```
  chunk-map : int -> (any -> any) -> collection -> list
  
  Pure? Yes
  
  Operates like map, but eagerly calculates each "chunk" once requested.
```
### Function: `collection?` 
```
  collection? : any -> bool
  
  Pure? Yes
  
  Check whether a variable is a collection.
  By default, a variable is a collection if it is a sequence or if it is convertable to a list.
```
### Function: `combinations` 
```
  combinations : [sequence]* -> list
  
  Pure? Yes
  
  Lazily calculates all combinations of any number of lists while preserving order:
  (combinations '(1 2) '(3 4) '(5 6))
  => ((1 3 5) (1 3 6) (1 4 5) (1 4 6) (2 3 5) (2 3 6) (2 4 5) (2 4 6))
```
### Function: `comp` 
```
  comp : (any -> any) -> (any -> any) -> (any -> any)
  
  Pure? Yes
  
  Alias for compose.
```
### Function: `compare` 
```
  compare : any -> any -> bool
  
  Pure? Yes
  
  Compare two variables x and y. Returns 0 if (= x y), -1 if (< x y) or 1 otherwise.
  The default requires = and < to work for x and y.
```
### Function: `complement` 
```
  complement : (any -> bool) -> (any -> bool)
  
  Pure? Yes
  
  Function complement
```
### Function: `compose` 
```
  compose : (any -> any) -> (any -> any) -> (any -> any)
  
  Pure? Yes
  
  Function composition
```
### Function: `compose-any` 
```
  compose-any : (any -> bool) -> (any -> bool) -> (any -> bool)
  
  Pure? Yes
  
  Function composition using and.
  ((compose-or sequence? empty?) x) ;=> (or (sequence? x) (empty? x))
```
### Function: `compose-n` 
```
  compose-n : (any -> any) -> ([any]+ -> any) -> ([any]+ -> any)
  
  Pure? Yes
  
  Function composition, but the function g (which is applied first) takes 2 arguments.
```
### Function: `compose-or` 
```
  compose-or : (any -> bool) -> (any -> bool) -> (any -> bool)
  
  Pure? Yes
  
  Function composition using or.
  ((compose-or sequence? number?) x) ;=> (or (sequence? x) (number? x))
```
### Function: `compose2` 
```
  compose2 : (any -> any) -> (any -> any -> any) -> (any -> any -> any)
  
  Pure? Yes
  
  Function composition, but the function g (which is applied first) takes 2 arguments.
```
### Function: `concat` 
```
  concat : collection -> [collection]* -> list
  
  Pure? Yes
  
  Append any number of sequences to each other.
  Required: append, foldr1
```
### Function: `conj` 
```
  conj : collection -> any+ -> collection
  
  Pure? Yes
  
  Add a number of elements to a collection.
  If the collection is a list, uses cons. Otherwise, uses add.
```
### Function: `const` 
```
  const : any -> ([any]* -> any)
  
  Pure? Yes
  
  Alias for constantly.
```
### Function: `constantly` 
```
  constantly : any -> ([any]* -> any)
  
  Pure? Yes
  
  Returns a function which always returns x.
```
### Function: `contains?` 
```
  contains? : collection -> any -> bool
  
  Pure? Yes
  
  Check whether the collection xs contains the element e.
```
### Function: `contains?#list` 
```
  contains?#list : list -> any -> bool
  
  Pure? Yes
  
  Implementation for contains?.
```
### Function: `contains?#map` 
```
  contains?#map : map -> any -> bool
  
  Pure? Yes
  
  Implementation for contains?.
```
### Function: `count-by` 
```
  count-by : (any -> bool) -> collection -> int
  
  Pure? Yes
  
  Count how many elements in xs satisfy predicate p.
  Required: foldl
```
### Function: `cycle` 
```
  cycle : sequence -> list
  
  Pure? Yes
  
  Create an infinite sequence repeating the elements of xs.
    (take 5 (cycle '(1 2)))) ;=> (1 2 1 2 1)
  Required: empty?, first, rest
```
### Function: `dec` 
```
  dec : number -> number
  
  Pure? Yes
  
  Decrement number by 1 (using -)
```
### Function: `delete-at` 
```
  delete-at : int -> collection -> collection
  
  Pure? Yes
  
  Delete element at index i in a collection xs.
  If xs is a collection, use a linear implementation for lists and return a lazy sequence.
  Otherwise, return Nothing.
```
### Function: `destructure` 
```
  destructure : list -> list
  
  Pure? Yes
  
  (destructure (('(a b) '(1 2)))) ;=> ((sym0 '(1 2)) (a (first sym0)) (sym1 (rest sym0)) (b (first sym1)))
```
### Function: `divmod` 
```
  divmod : any -> any -> list
  
  Pure? Yes
  
  (divmod x y) ;=> (list (/ x y) (rem x y))
```
### Function: `doall!` 
```
  doall! : collection -> list
  
  Pure? No
  
  Evaluate a list
```
### Function: `drop` 
```
  drop : int -> collection -> sequence
  
  Pure? Yes
  
  Drop the first n elements of a collection xs.
  Returns Nothing for atoms.
  Requires: empty?, first, rest
```
### Function: `drop-until` 
```
  drop-until : (any -> bool) -> collection -> sequence
  
  Pure? Yes
  
  Drop the elements of a collection xs until a predicate is true.
  Returns Nothing for atoms.
  Requires: empty?, first, rest
```
### Function: `drop-while` 
```
  drop-while : (any -> bool) -> collection -> sequence
  
  Pure? Yes
  
  Drop the elements of a collection xs until a predicate is false.
  Returns Nothing for atoms.
  Requires: empty?, first, rest
```
### Function: `else` 
```
  
  
  Pure? Yes
  
  else : bool
  Nicer-to-read alias for #t.
```
### Function: `empty?` 
```
  empty? : collection -> bool
  
  Pure? Yes
  
  Check whether a variable is empty, according to the following rules:
    lists are empty if null? is true for them (true for empty list and Nothing).
    collections are empty if their size is 0.
    The special value Nothing is empty.
    Other non-collections are not empty.
```
### Function: `enumerate` 
```
  enumerate : sequence -> sequence
  
  Pure? Yes
  
  Alias for zip-to-index.
  
  (empty? (enumerate '()))
  (empty? (enumerate []))
  (eq? '((0 4) (1 5) (2 6)) (enumerate '(4 5 6)))
  (eq? '((0 4) (1 5) (2 6)) (enumerate [4 5 6]))
```
### Function: `eq?` 
```
  eq? : any -> any -> bool
  
  Pure? Yes
  
  More general equality function. Defaults to = but uses seq-eq? if sequence? is true for both x and y.
```
### Function: `eq?#list` 
```
  eq?#list : list -> sequence -> bool
  
  Pure? Yes
  
  Implementation of eq? for lists.
```
### Function: `eq?#map` 
```
  eq?#map : map -> map -> bool
  
  Pure? Yes
  
  Implementation of eq? for maps.
```
### Function: `eval-seq!` 
```
  eval-seq! : collection -> collection
  
  Pure? No
  
  Forces a sequence to be evaluated. The sequence is then returned as it was.
```
### Function: `even?` 
```
  even? : number -> bool
  
  Pure? Yes
  
  Check whether a number is odd or even. Requires ->int.
```
### Function: `every-pred` 
```
  every-pred : [(any -> bool)]+ -> (any -> bool)
  
  Pure? Yes
  
  Check whether all predicates are true on a given element
```
### Function: `fact-seq` 
```
  fact-seq : () -> list
  
  Pure? Yes
  
  Sequence of the factorial numbers, starting at 0.
  (yes, it says 1, but starts at 0)
```
### Function: `filter` 
```
  filter : (any -> bool) -> collection -> list
  
  Pure? Yes
  
  Lazy filter.
  Required: empty?, first, rest
```
### Function: `filter-indexed` 
```
  filter-indexed : (any -> int -> bool) -> collection -> list
  
  Pure? Yes
  
  Filter lazily with index.
  Required: empty?, first, rest
```
### Function: `find` 
```
  find : any -> collection -> any
  
  Pure? Yes
  
  Find associated key or value for an element. The type of return value depends on the type of the collection.
  index-of for lists and vectors, true or false for sets.
```
### Function: `first` 
```
  first : collection -> any
  
  Pure? Yes
  
  Get the first element of a collection.
  Default requires ->list. If ->list is not available, returns Nothing.
```
### Function: `first#list` 
```
  first#list : list -> any
  
  Pure? Yes
  
  Implementation for first.
```
### Function: `first#map` 
```
  first#map : map -> any
  
  Pure? Yes
  
  Returns the first key in the map.
```
### Function: `flatten` 
```
  flatten : collection -> list
  
  Pure? Yes
  
  Flatten a collection.
  Required: collection?, foldr, append
  Could use some optimization
```
### Function: `flatten1` 
```
  flatten1 : collection -> list
  
  Pure? Yes
  
  Flatten by one level.
  Required: map
  Could use some optimization
```
### Function: `flip` 
```
  flip : function -> function
  
  Pure? Yes
  
  Take a function f, which takes two arguments and returns a new function which takes the arguments reversed.
```
### Function: `fmap` 
```
  fmap : (any -> any) -> (any -> bool) -> collection -> list
  
  Pure? Yes
  
  Filter, then map.
  (fmap f p xs) is equivalent to (filter p (map f xs))
  Required: empty?, first, rest
```
### Function: `foldl` 
```
  foldl : function -> any? -> collection -> any?
  
  Pure? Yes
  
  Generic for foldl.
```
### Function: `foldl#list` 
```
  foldl#list : (any -> any -> any) -> any -> list -> any
  
  Pure? Yes
  
  Implementation for foldl.
```
### Function: `foldl#map` 
```
  foldl#map : (any -> any -> any) -> any -> map -> any
  
  Pure? Yes
  
  Implementation for foldl.
```
### Function: `foldl-indexed` 
```
  foldl-indexed : (any -> any -> int -> any) -> any -> collection -> any
  
  Pure? Yes
  
  foldl with index.
  Requires: empty?, first, rest
```
### Function: `foldl1` 
```
  foldl1 : (any -> any -> any) -> collection -> any
  
  Pure? Yes
  
  (foldl1 + '()) ;=> Nothing
  (foldl1 + '(1)) ;=> 1 (if only 1 element is given, return it.
  (foldl1 + '(1 2 3)) ;=> 6
  Requires: empty?, size, first, rest, foldl
```
### Function: `foldr` 
```
  foldr : function -> any? -> collection -> any?
  
  Pure? Yes
  
  Generics for foldr and foldl.
```
### Function: `foldr#list` 
```
  foldr#list : (any -> any -> any) -> any -> list -> any
  
  Pure? Yes
  
  Implementation for foldr.
```
### Function: `foldr#map` 
```
  foldr#map : (any -> any -> any) -> any -> map -> any
  
  Pure? Yes
  
  Implementation for foldr.
```
### Function: `foldr-indexed` 
```
  foldr-indexed : (any -> any -> int -> any) -> any -> collection -> any
  
  Pure? Yes
  
  foldr with index.
  Requires: empty?, first, rest
```
### Function: `foldr1` 
```
  foldr1 : (any -> any -> any) -> collection -> any
  
  Pure? Yes
  
  Similar to foldr1.
  Requires empty?, size, first, rest
```
### Function: `frequencies` 
```
  frequencies : collection -> map
  
  Pure? Yes
  
  Map of the number of occurances of each item in a collection.
  Required: foldl
```
### Function: `fst` 
```
  fst : any -> any -> any
  
  Pure? Yes
  
  Take 2 arguments, return the first.
```
### Function: `get` 
```
  get : collection -> any -> any
  
  Pure? Yes
  
  Get an element in a collection xs by its key k.
  The default behaviour uses nth, but it has to be overridden for maps and sets.
```
### Function: `get#map` 
```
  get#map : map -> any -> any
  
  Pure? Yes
  
  Special implementation for get for map.
```
### Function: `get-in` 
```
  get-in : collection -> sequence -> any
  
  Pure? Yes
  
  Get an item from xs after calling get on it for each item in ks.
    (get-in [1 [2 [3]]] '(0)) ;=> 1
    (get-in [1 [2 [3]]] '(1 0)) ;=> 2
    (get-in [1 [2 [3]]] '(1 1)) ;=> [3]
    (get-in [1 [2 [3]]] '(1 1 0)) ;=> 3
  Required for xs: get
  Required for ks: empty?, first, rest
```
### Function: `group-by` 
```
  group-by : (any -> any) -> collection -> map
  
  Pure? Yes
```
### Function: `inc` 
```
  inc : number -> number
  
  Pure? Yes
  
  Increment number by 1 (using +)
```
### Function: `included?` 
```
  included? : any -> collection -> bool
  
  Pure? Yes
  
  Check whether value e is in a collection xs. This is the reverse of contains?
```
### Function: `index-of` 
```
  index-of : any -> collection -> int
  
  Pure? Yes
  
  Tries to find the index of the element from the collection xs. Returns -1 if the element could not be found.
```
### Function: `indices-of` 
```
  indices-of : sequence -> any -> list
  
  Pure? Yes
  
  Get the indices of all occuranges of elem in seq.
  Required for seq: foldr-indexed
  Required for elements in seq: eq?
```
### Function: `interleave` 
```
  interleave : collection -> [collection]* -> list
  
  Pure? Yes
```
### Function: `interpose` 
```
  interpose : any -> sequence -> list
  
  Pure? Yes
  
  Takes a separator and a sequence. After each element of the sequence, the separator is inserted, except after the last one.
  (interpose 0 '(1 2 3 4 5)) ;=> (1 0 2 0 3 0 4 0 5)
```
### Function: `into` 
```
  into : () -> list
  into : collection -> collection
  into : collection -> collection -> collection
  into : collection -> (collection -> collection) -> collection -> collection
  
  Pure? Yes
  
  Add items from 'from' to 'to', keeping the type of 'to'. (if add is correctly defined)
    (into) ;=> () ; empty input -> empty list
    (into '(1 2)) ;=> (1 2)
    (into [1 2] '(3 4)) ;=> [1 2 3 4]
    (into [1 2] unique '(3 3 4 3)) ;=> [1 2 3 4]
  The last case works well for partials:
    (let* ((f (partial into [1 2] unique))) ...)
  Required: foldl, add
```
### Function: `iterate` 
```
  iterate : (any -> any) -> any -> list
  
  Pure? Yes
  
  Typical iterate function creating an infinite sequence.
    (take 5 (iterate inc 0) => (0 1 2 3 4)
    (take 3 (iterate list '()) => (() (()) ((())))
```
### Function: `juxt` 
```
  juxt : [(any -> any)]+ -> (any -> any)
  
  Pure? Yes
  
  See https://clojuredocs.org/clojure.core/juxt
  (juxt identity name) is effectively equivalent to (lambda (x) (vector (identity x) (name x)))
```
### Function: `last` 
```
  last : collection -> any
  
  Pure? Yes
  
  Get last element of a collection.
  Default implementation requires ->list, first, rest, size.
```
### Function: `list` 
```
  list : any* -> list
  
  Pure? Yes
  
  Take any number of arguments and return a list of them.
  (list 1 2 3) ;=> (1 2 3)
```
### Function: `list*` 
```
  list* : [any]* -> list
  
  Pure? Yes
  
  repeatedly apply cons to a list.
  (list* 1 2 3 4 '(5 6)) ;=> (1 2 3 4 5 6)
  (list* 1 2 '(3)) is equivalent to (cons 1 (cons 2 '(3)))
```
### Function: `log!` 
```
  log! : any* -> list
  
  Pure? No
  
  As println!, but returns the input as a list.
```
### Function: `log1!` 
```
  log1! : any -> any
  
  Pure? No
  
  As println!, but takes only one argument and returns it after printing.
```
### Function: `map` 
```
  map : (any -> any) -> collection -> list
  
  Pure? Yes
  
  Lazy map requires empty?, first, rest
```
### Function: `map-eager` 
```
  map-eager : (any -> any) -> collection -> list
  
  Pure? Yes
  
  Same as map, but works eagerly, not lazy.
```
### Function: `map-indexed` 
```
  map-indexed : (any -> int -> any) -> collection -> list
  
  Pure? Yes
  
  map with index.
  Requires empty?, first, rest.
```
### Function: `map-invert` 
```
  map-invert : map -> map
  
  Pure? Yes
  
  Makes a map of key-value pairs into a map of value-key pairs.
  This may loose information, so the following might not always hold:
  (eq? m (map-invert (map-invert m)))
  However, this feature is used often enough that including it makes sense.
```
### Function: `map-split` 
```
  map-split : ([any]* -> any) -> collection -> list
  
  Pure? Yes
  
  Takes a sequence of sequences and maps over each sub-sequence.
  (map-split + '((1 2) (3 4) (5 6))) ;=> (3 7 11)
```
### Function: `map-until` 
```
  map-until : (any -> any) -> (any -> bool) -> collection -> list
  
  Pure? Yes
  
  map until a predicate if true. Uses map and take-until.
```
### Function: `map-while` 
```
  map-while : (any -> any) -> (any -> bool) -> collection -> list
  
  Pure? Yes
  
  map while a predicate if true. Uses map and take-whilel.
```
### Function: `mapcar` 
```
  mapcar : ([any]+ -> any) -> [collection]* -> list
  
  Pure? Yes
  
  Take any number of collections and map their first elements until all are empty.
    (mapcar list '(1 2 3) '(4 5 6) '(7 8 9)) ;=> ((1 4 7) (2 5 8) (3 6 9))
    (mapcar + '(1 2 3) '(4 5 6) '(7 8 9)) ;=> (12 15 18)
    (mapcar + '(1 2 3) '(4 5) '(7 8 9)) ;=> (12 15 12)
  Required: any?, empty?, first, rest to work correctly with all inputs.
```
### Function: `mapcat` 
```
  mapcat : (any -> collection) -> collection -> list
  
  Pure? Yes
  
  map and then append (lazy).
```
### Function: `mapcon` 
```
  mapcon : (any -> collection) -> collection -> collection
  
  Pure? Yes
  
  maplist and append (eager).
```
### Function: `mapf` 
```
  mapf : (any -> any) -> (any -> bool) -> collection -> list
  
  Pure? Yes
  
  map, then filter
  (mapf f p xs) is equivalent to (map f (filter p xs))
  Required: empty?, first, rest
```
### Function: `mapl` 
```
  mapl : (any -> any) -> collection -> list
  
  Pure? Yes
  
  Alias for map-eager. The name is supposed to show a similarity to mapv, but the output is a list, not a vector.
```
### Function: `maplist` 
```
  maplist : (collection -> any) -> collection -> list
  
  Pure? Yes
  
  map but use the rest of the list.
  (maplist size '(1 2 3)) ;=> (3 2 1)
    Like (list (size '(1 2 3)) (size '(2 3)) (size '(3)))
  Requires: empty?, rest
```
### Function: `max` 
```
  max : any -> any -> any
  
  Pure? Yes
  
  Get maximum of n m (using < or >)
```
### Function: `min` 
```
  min : any -> any -> any
  
  Pure? Yes
  
  Get minimum of n m (using < or >)
```
### Function: `minimum` 
```
  minimum : collection -> any
  minimum : (any -> any) -> collection -> any
  
  Pure? Yes
  
  Get minimum of the elements in a sequence using min/max.
  Required: foldl1, map
```
### Function: `minimum` 
```
  minimum : collection -> any
  minimum : (any -> any) -> collection -> any
  
  Pure? Yes
  
  Get maximum of the elements in a sequence using min/max.
  Required: foldl1, map
```
### Function: `most?` 
```
  most? : (any -> bool) -> collection -> bool
  
  Pure? Yes
  
  Check whether more than half of the elements of a collection satisfy a predicate p.
  Required: size, count-by
```
### Function: `name` 
```
  name : any -> string
  
  Pure? Yes
  
  Turns symbols and keywords into strings. strings are unchanged. for all other types, the function returns Nothing.
```
### Function: `none?` 
```
  none? : (any -> bool) -> collection -> bool
  
  Pure? Yes
  
  Check whether a predicate is true for no elements in a collection xs.
  Requires empty?, first, rest and drop-while/drop-until to work.
```
### Function: `not-eq?` 
```
  not-eq? : any -> any -> bool
  
  Pure? Yes
  
  Check for non-equality. This is the reverse of eq?.
```
### Function: `nth` 
```
  nth : collection -> int -> any
  
  Pure? Yes
  
  Get element from sequence xs at index i (starts at 0). Requires ->list.
  Returns Nothing if the element cannot be found.
```
### Function: `nth#map` 
```
  nth#map : map -> int -> vector
  
  Pure? Yes
  
  Implementation of nth for maps. This converts the map into a sequence and then returns the pair (key, value).
```
### Function: `number?` 
```
  number? : any -> bool
  
  Pure? Yes
  
  Check whether a variable is a number.
```
### Function: `odd?` 
```
  odd? : number -> bool
  
  Pure? Yes
  
  Check whether a number is odd or even. Requires ->int.
```
### Function: `par` 
```
  par : [(() -> any)]* -> list
  
  Pure? Yes
  
  Run functions in parallel. Returns a list of delay objects
```
### Function: `partition` 
```
  partition : int -> collection -> list
  partition : int -> int -> collection -> list
  partition : int -> int -> collection -> collection -> list
  
  Pure? Yes
  
  Partition function
  Required: size, take, drop
   (partition 3 [1 2 3 4])) ;=> ((1 2 3))
   (partition 3 [1 2 3 4 5 6])) ;=> ((1 2 3) (4 5 6))
   (partition 1 [1 2 3 4 5 6])) ;=> ((1) (2) (3) (4) (5) (6))
   (partition 0 [1 2 3 4 5 6])))) ;=> ()
   (partition 3 2 [1 2 3 4 5])) ;=> ((1 2 3) (3 4 5))
   (partition 3 1 [1 2 3 4 5])) ;=> ((1 2 3) (2 3 4) (3 4 5))
   (partition 3 3 [1 2 3] [1 2 3 4])) ;=> ((1 2 3) (4 1 2))
```
### Function: `partition-all` 
```
  partition-all : int -> collection -> list
  
  Pure? Yes
  
  (partition-all 2 [0 1 2 3 4 5])) ;=> ((0 1) (2 3) (4 5))
  Required: empty?, take, drop
```
### Function: `partition-by` 
```
  partition-by : (any -> any) -> collection -> list
  
  Pure? Yes
```
### Function: `permutations` 
```
  permutations : sequence -> list
  
  Pure? Yes
  
  Calculate all permutations of a collection.
  Requires only ->list to be defined.
```
### Function: `pmap` 
```
  pmap : (any -> any) -> collection -> list
  
  Pure? Yes
  
  Parallel map. Like pmap', but returns values, not delays.
  Please do not use this yet.
  FIXME: The current implementation is hopelessly broken.
```
### Function: `pmap'` 
```
  pmap' : (any -> any) -> collection -> list
  
  Pure? Yes
  
  Parallel map. Returns a (lazy) list of delays.
```
### Function: `prepend` 
```
  prepend : collection -> collection -> collection
  
  Pure? Yes
  
  Reverse append. (append xs to ys).
```
### Function: `print!` 
```
  print! : any* -> Nothing
  
  Pure? No
  
  Printing. Can take any number of arguments (variadic and requires ->string to work correctly.
  (print! 1 2 3) ;=> prints "123"
```
### Function: `printall!` 
```
  printall! : any* -> Nothing
  
  Pure? No
  
  Like println!, but separates the arguments with a space.
  (printall! "abc" "abc" "abc") ;=> prints "abc abc abc\n"
```
### Function: `println!` 
```
  println! : any* -> Nothing
  
  Pure? No
  
  Like print! but appends a linebreak.
  (println! "abc" "abc" "abc") ;=> prints "abcabcabc\n"
```
### Function: `product` 
```
  product : collection -> number
  product : (number -> number) -> collection -> number
  
  Pure? Yes
  
  Calculate the product of the elements of a collection using *.
  Required: foldl, map
```
### Function: `range` 
```
  range : int -> int -> list
  
  Pure? Yes
  
  Lazily create a range of the numbers between from and to (inclusive)
```
### Function: `remove` 
```
  remove : (any -> bool) -> collection -> list
  
  Pure? Yes
  
  Filter with complement of p
```
### Function: `remove-indexed` 
```
  remove-indexed : (any -> int -> bool) -> collection -> list
  
  Pure? Yes
  
  Filter with index with complement of p
```
### Function: `repeat` 
```
  repeat : any -> list
  
  Pure? Yes
  
  Create an infinite sequence of the same element e.
```
### Function: `repeatedly` 
```
  repeatedly : (() -> any) -> list
  
  Pure? Yes
  
  Repeatedly execute f in a lazy sequence.
```
### Function: `replace-subseq` 
```
  replace-subseq : int -> int -> sequence -> sequence
  
  Pure? Yes
  
  Replaces a sub-sequence in a sequence.
    (replace-subseq 0 4 '() '(1 2 3 4)) ;=> ()
    (replace-subseq 1 2 '(3 4) '(1 2 3 4)) ;=> (1 3 4 4)
    (replace-subseq 1 2 '(3 4 5 6) '(1 2 3 4)) ;=> (1 3 4 5 6 6)
  Requires split-at to work correctly.
```
### Function: `rest` 
```
  rest : collection -> collection
  
  Pure? Yes
  
  Get the rest of the elements of a collection.
  Default requires ->list. If ->list is not available, returns Nothing.
```
### Function: `rest#list` 
```
  rest#list : list -> list
  
  Pure? Yes
  
  Implementation for rest.
```
### Function: `rest#map` 
```
  rest#map : map -> sequence
  
  Pure? Yes
  
  Implementation for rest.
```
### Function: `reverse` 
```
  reverse : collection -> collection
  
  Pure? Yes
  
  Reverse a collection.
  The default requires foldl and returns a list.
```
### Function: `reverse#map` 
```
  reverse#map : map -> map
  
  Pure? Yes
  
  Special implementation of reverse for maps.
  Since maps are unordered, they are their own reversals.
```
### Function: `rget` 
```
  rget : any -> collection -> any
  
  Pure? Yes
  
  Reverse of get. Takes the collection first and the key second.
```
### Function: `rnth` 
```
  rnth : int -> collection -> any
  
  Pure? Yes
  
  Reverse of nth. Takes the collection first and the key second.
```
### Function: `scalar?` 
```
  scalar? : any -> bool
  
  Pure? Yes
  
  Short for (and (atom? x) (not (symbol? x))).
```
### Function: `scanl` 
```
  scanl : (any -> any -> any) -> any -> collection -> list
  
  Pure? Yes
  
  scan left. (known as reductions in clojure)
  Return intermediate results of foldl as a list.
  Requires empty?, first, rest
```
### Function: `scanl` 
```
  scanl : (any -> any -> any) -> collection -> list
  
  Pure? Yes
  
  scan left with no accumulator.
  Requires empty?, size, first, rest.
```
### Function: `scanr` 
```
  scanr : (any -> any -> any) -> any -> collection -> list
  
  Pure? Yes
  
  Intermediate results of foldr as a lazy sequence
    (scanr + 5 '(1 2 3 4)) ;=> (15 14 12 9 5)
  Required: empty?, first, rest
```
### Function: `scanr1` 
```
  scanr : (any -> any -> any) -> collection -> list
  
  Pure? Yes
  
  Intermediate results of foldr1 as a lazy sequence
    (scanr1 + '(1 2 3 4 5)) ;=> (15 14 12 9 5)
  Required: empty?, first, rest, size
```
### Function: `second` 
```
  second : collection -> any
  
  Pure? Yes
  
  Get second element of a collection. Default requires first and rest.
  The default is (first (rest xs)).
```
### Function: `seq-eq?` 
```
  seq-eq? : sequence -> sequence -> bool
  
  Pure? Yes
  
  Check whether 2 sequences are equal. They need to support empty?, first and rest
```
### Function: `seq?` 
```
  seq? : any -> bool
  
  Pure? Yes
  
  Alias for sequence?
```
### Function: `sequence?` 
```
  sequence? : any -> bool
  
  Pure? Yes
  
  Check whether a variable is a sequence.
  Needs to be implemented for sequence types or some functions might not work.
```
### Function: `size` 
```
  size : collection -> int
  
  Pure? Yes
  
  Get the size of a collection xs. Default requires ->list.
  Return 0 for types which are not convertable to list.
  The result can become an infinite loop for infinite sequences.
```
### Function: `size#list` 
```
  size#list : list -> int
  
  Pure? Yes
  
  Implementation for size.
```
### Function: `size#map` 
```
  size#map : map -> int
  
  Pure? Yes
  
  Implementation for size.
```
### Function: `slices` 
```
  slices : int -> collection -> list
  
  Pure? Yes
  
  (slices 3 '(1 2 3 4 5 6)) ;=> ((1 2 3) (4 5 6))
  Required: size, take, drop
```
### Function: `snd` 
```
  snd : any -> any -> any
  
  Pure? Yes
  
  Take 2 arguments, return the second.
```
### Function: `split` 
```
  split : int -> collection -> list
  Required: empty?, ->list (for the rest), first, rest
  
  Pure? Yes
  
  Split a sequence into 2 parts: From index 0 to n and the rest.
  (split n xs) is equivalent to (list (take n xs) (drop n xs))
```
### Function: `split` 
```
  split : any -> sequence -> list
  
  Pure? Yes
  
  Split at each occurance of v in xs.
  Requires split-by to work for xs.
  Requires eq? to be defined for v.
```
### Function: `split-by` 
```
  split-by : (any -> bool) -> sequence -> list
  
  Pure? Yes
  
  Split a sequence each time as predicate is true for the current element.
  Always returns a list.
    (split-by (lambda (x) (= x 1)) '(5 1 2 3 1 6)) ;=> ((5) (2 3) (6))
  Required: foldr
```
### Function: `split-if` 
```
  split-if : (any -> bool) -> collection -> list
  
  Pure? Yes
  
  (split-if p xs) is equivalent to (list (take-while p xs) (drop-while p xs))
  Required: empty?, first, rest
```
### Function: `split-unless` 
```
  split-unless : (any -> bool) -> collection -> list
  
  Pure? Yes
  
  (split-unless p xs) is equivalent to (list (take-until p xs) (drop-until p xs))
  Required: empty?, first, rest
```
### Function: `split-with` 
```
  split-with : (any -> bool) -> sequence -> sequence
  
  Pure? Yes
  
  (split-with p xs) is the same as (list (take-while p xs) (drop-while p xs)).
```
### Function: `spread` 
```
  spread : sequence -> sequence
  
  Pure? Yes
  
  Expand the last element of a sequence and returns a list.
  (spread (list 1 2 3 '(9 7 5))) ;=> (1 2 3 9 7 5)
  Requires: split-at, size
```
### Function: `subseq` 
```
  subseq : int -> int -> collection -> list
  
  Pure? Yes
  
  Returns a sub-sequence of a sequence.
  Equivalent to (take length (drop start xs)).
```
### Function: `succ` 
```
  succ : any -> any
  
  Pure? Yes
  
  Calculate successor of a variable.
  For numbers, this defaults to inc.
  chars have their internal value incremented by 1.
  Other variables are their own successors (eg. a function has no successor).
```
### Function: `sum` 
```
  sum : collection -> number
  sum : (number -> number) -> collection -> number
  
  Pure? Yes
  
  Sum up elements of a collection using +.
  Required: foldl, map
```
### Function: `symbol` 
```
  symbol : any -> symbol
  
  Pure? Yes
  
  Alias for ->symbol.
```
### Function: `take` 
```
  take : int -> collection -> list
  
  Pure? Yes
  
  Take the first n elements of a collection xs or the whole collection, if its size is greater than n.
  Returns Nothing for atoms. Otherwise, the output is always a list.
  Requires: empty?, first, rest
```
### Function: `take-nth` 
```
  take-nth : int -> collection -> list
  
  Pure? Yes
  
  Take every nth item.
```
### Function: `take-until` 
```
  take-until : (any -> bool) -> collection -> list
  
  Pure? Yes
  
  Take until a predicate is true.
  Required: empty?, first, rest
```
### Function: `take-while` 
```
  take-while : (any -> bool) -> collection -> list
  
  Pure? Yes
  
  Take while a predicate is true.
  Required: empty?, first, rest
```
### Function: `times` 
```
  times : (any -> any) -> int -> (any -> any)
  
  Pure? Yes
  
  Creates a function which takes one argument and applies f to it n times.
  (let* ((f (times inc 6)))
    (f 9) ;=> 15
    ((times inc 0) 9)) ;=> 9
```
### Function: `tuples` 
```
  tuples : int -> collection -> list
  
  Pure? Yes
  
  (tuples 3 '(1 2 3 4 5)) ;=> ((1 2 3) (2 3 4) (3 4 5))
  Required: size, take, rest
```
### Function: `unique` 
```
  unique : collection -> list
  
  Pure? Yes
  
  Get a sequence with its duplicates removed.
  Required: empty?, first, rest
```
### Function: `unique?` 
```
  unique? : collection -> bool
  
  Pure? Yes
```
### Function: `unwrap` 
```
  unwrap : box -> any
  
  Pure? Yes
  
  unbox a box or unpack a user-defined type. Can be overridden.
```
### Function: `v-zip-with` 
```
  v-zip-with : ([any]* -> any) -> sequence -> list
  
  Pure? Yes
  
  Similar to zip, but takes a sequence of sequences to zip.
  The output is always a list.
  Stops when all sequences are empty.
   (v-zip-with v+ '((1 2 3) (4 5 6) (7 8 9))) ;=> (12 15 18)
   (v-zip-with v+ '((1 2 3) (4) (7 8 9))) ;=> (12 10 12)
   (v-zip-with v+ '((1 2 3) (4 5 6 10) (7 8 9))) ;=> (12 15 18 10)
  Required for xs: map-eager, all?
  Required for inner sequences: first, empty?, rest
```
### Function: `va-all?` 
```
  va-all? : (any -> bool) -> [any]* -> bool
  
  Pure? Yes
```
### Function: `va-any?` 
```
  va-any? : (any -> bool) -> [any]* -> bool
  
  Pure? Yes
```
### Function: `va-none?` 
```
  va-none? : (any -> bool) -> [any]* -> bool
  
  Pure? Yes
```
### Function: `walk-with-path` 
```
  walk-with-path : (any -> list) -> collection -> collection
  
  Pure? Yes
  
  Not even in testing yet!
```
### Function: `xrange` 
```
  xrange : () -> list
  xrange : int -> list
  xrange : int -> int -> list
  xrange : int -> int -> int -> list
  
  Pure? Yes
  
  Extended range function.
  Takes 0 to 3 input numbers.
  Arity | Output
  0     | Infinite sequence starting at 0 and counting up.
  1     | Infinite sequence starting at from.
  2     | Lazy sequence counting from 'from' to 'to'.
  3     | Lazy sequence counting from 'from' to 'to'
        | If stop is a function, it is repeatedly applied to the current value of from until (>= from to).
        | Otherwise, step is repeatedly added to from using +.
```
### Function: `zip` 
```
  zip : sequence -> sequence -> list
  
  Pure? Yes
  
  zip the elements of two collections using list.
    (zip '(1 2 3) '(4 5 6)) ;=> ((1 4) (2 5) (3 6))
  Required for both l0 and l1: empty?, first, rest
```
### Function: `zip-to-index` 
```
  zip-to-index : sequence -> list
  
  Pure? Yes
  
  zip the elements of a collection to their indices.
    (zip-to-index '(9 8 7)) ;=> ((0 9) (1 8) (2 7))
  Requires map-indexedd to work.
```
### Function: `zip-with` 
```
  zip-with : (any -> any -> any) -> sequence -> sequence -> list
  
  Pure? Yes
  
  zip the elements of two collections with a function.
    (zip-with + '(1 2 3) '(4 5 6)) ;=> (5 7 9)
    (zip-with list '(1 2 3) '(4 5 6)) ;=> ((1 4) (2 5) (3 6))
  Required for both l0 and l1: empty?, first, rest
```
# File: buildins.lyra

Attention! It is not adviced to use any function with the prefix "buildin" directly! They may not always act as intended and may be removed at any time in any version.`

## Macros


## Functions

### Function: `*` 
```
  * : any* -> any
  
  Pure? Yes
```
### Function: `+` 
```
  + : any* -> any
  
  Pure? Yes
```
### Function: `-` 
```
  - : any* -> any
  
  Pure? Yes
```
### Function: `/` 
```
  / : any* -> any
  
  Pure? Yes
```
### Function: `/=` 
```
  /= : any* -> bool
  
  Pure? Yes
```
### Function: `<` 
```
  < : any* -> bool
  
  Pure? Yes
```
### Function: `<=` 
```
  <= : any* -> bool
  
  Pure? Yes
```
### Function: `=` 
```
  = : any* -> bool
  
  Pure? Yes
```
### Function: `>` 
```
  > : any* -> bool
  
  Pure? Yes
```
### Function: `>=` 
```
  >= : any* -> bool
  
  Pure? Yes
```
### Function: `abs` 
```
  abs : number -> number
  
  Pure? Yes
```
### Function: `all?` 
```
  all? : (any -> bool) -> collection -> bool
  
  Pure? Yes
```
### Function: `always-false` 
```
  always-false : any* -> bool
  
  Pure? Yes
  
  Always returns #f.
```
### Function: `always-true` 
```
  always-true : any* -> bool
  
  Pure? Yes
  
  Always returns #t.
```
### Function: `any?` 
```
  any? : (any -> bool) -> collection -> bool
  
  Pure? Yes
```
### Function: `apply-to` 
```
  apply-to : function -> list -> any
  
  Pure? Yes
```
### Function: `atom?` 
```
  atom? : any -> bool
  
  Pure? Yes
  
  Returns #t for symbols, bools, strings and numbers.
  Returns #f for anything else.
```
### Function: `bit-and` 
```
  bit-and : int -> int -> int
  
  Pure? Yes
```
### Function: `bit-or` 
```
  bit-or : int -> int -> int
  
  Pure? Yes
```
### Function: `bit-shl` 
```
  bit-shl : int -> int -> int
  
  Pure? Yes
```
### Function: `bit-shr` 
```
  bit-shr : int -> int -> int
  
  Pure? Yes
```
### Function: `bit-xor` 
```
  bit-xor : int -> int -> int
  
  Pure? Yes
```
### Function: `boolean?` 
```
  boolean? : any -> bool
  
  Pure? Yes
```
### Function: `box` 
```
  box : any -> box
  
  Pure? Yes
  
  Wraps the argument into a box.
```
### Function: `box-set!` 
```
  box-set! : box -> any -> box
  
  Pure? No
  
  Changes the value of a box.
```
### Function: `box?` 
```
  box? : any -> bool
  
  Pure? Yes
```
### Function: `buildin->bool` 
```
  buildin->bool : any -> bool
  
  Pure? Yes
  
  Turns a variable into a bool. Returns Nothing if this is not possible.
```
### Function: `buildin->char` 
```
  buildin->char : any -> char
  
  Pure? Yes
  
  Turns a variable into a char. Returns Nothing if this is not possible.
```
### Function: `buildin->float` 
```
  buildin->float : any -> float
  
  Pure? Yes
  
  Turns a variable into a float. Returns Nothing if this is not possible.
```
### Function: `buildin->int` 
```
  buildin->int : any -> int
  
  Pure? Yes
  
  Turns a variable into an int. Returns Nothing if this is not possible.
```
### Function: `buildin->keyword` 
```
  buildin->keyword : any -> keyword
  
  Pure? Yes
  
  Turns a variable into a keyword. Returns Nothing if this is not possible.
```
### Function: `buildin->list` 
```
  buildin->list : any -> list
  
  Pure? Yes
  
  Turns a variable into a list. Returns Nothing if this is not possible.
```
### Function: `buildin->map` 
```
  buildin->map : any -> map
  
  Pure? Yes
  
  Turns a variable into a map. Returns Nothing if this is not possible.
```
### Function: `buildin->pretty-string` 
```
  buildin->pretty-string : any -> string
  
  Pure? Yes
  
  Turns a variable into a string. Returns Nothing if this is not possible.
```
### Function: `buildin->rational` 
```
  buildin->rational : any -> rational
  
  Pure? Yes
  
  Turns a variable into a rational. Returns Nothing if this is not possible.
```
### Function: `buildin->set` 
```
  buildin->set : any -> set
  
  Pure? Yes
  
  Turns a variable into a set. Returns Nothing if this is not possible.
```
### Function: `buildin->string` 
```
  buildin->string : any -> string
  
  Pure? Yes
  
  Turns a variable into a string. Returns Nothing if this is not possible.
```
### Function: `buildin->symbol` 
```
  buildin->symbol : any -> symbol
  
  Pure? Yes
  
  Turns a variable into a symbol. Returns Nothing if this is not possible.
```
### Function: `buildin->vector` 
```
  buildin->vector : any -> vector
  
  Pure? Yes
  
  Turns a variable into a vector. Returns Nothing if this is not possible.
```
### Function: `buildin-append` 
```
  buildin-append : collection -> collection -> collection
  
  Pure? Yes
```
### Function: `buildin-contains?` 
```
  buildin-contains? : collection -> any -> bool
  
  Pure? Yes
```
### Function: `buildin-foldl` 
```
  buildin-foldl : (any -> any -> any) -> any -> sequence -> any
  
  Pure? Yes
```
### Function: `buildin-foldr` 
```
  buildin-foldr : (any -> any -> any) -> any -> sequence -> any
  
  Pure? Yes
```
### Function: `buildin-nth` 
```
  buildin-nth : collection -> int -> any
  
  Pure? Yes
```
### Function: `buildin-print!` 
```
  buildin-print! : string -> Nothing
  
  Pure? No
```
### Function: `buildin-set->vector` 
```
  buildin-set->vector : set -> vector
  
  Pure? Yes
```
### Function: `buildin-set-add` 
```
  buildin-set-add : set ->  -> set
  
  Pure? Yes
```
### Function: `buildin-set-difference` 
```
  buildin-set-difference : set -> set -> set
  
  Pure? Yes
```
### Function: `buildin-set-eq?` 
```
  buildin-set-eq? : set -> set -> bool
  
  Pure? Yes
```
### Function: `buildin-set-includes?` 
```
  buildin-set-includes? : set -> set -> set
  
  Pure? Yes
```
### Function: `buildin-set-intersection` 
```
  buildin-set-intersection : set -> set -> set
  
  Pure? Yes
```
### Function: `buildin-set-of` 
```
  buildin-set-of : any* -> set
  
  Pure? Yes
```
### Function: `buildin-set-size` 
```
  buildin-set-size : set -> int
  
  Pure? Yes
```
### Function: `buildin-set-subset?` 
```
  buildin-set-subset? : set -> set -> set
  
  Pure? Yes
```
### Function: `buildin-set-superset?` 
```
  buildin-set-superset? : set -> set -> set
  
  Pure? Yes
```
### Function: `buildin-set-true-subset?` 
```
  buildin-set-true-subset? : set -> set -> set
  
  Pure? Yes
```
### Function: `buildin-set-true-superset?` 
```
  buildin-set-true-superset? : set -> set -> set
  
  Pure? Yes
```
### Function: `buildin-set-union` 
```
  buildin-set-union : set -> set -> set
  
  Pure? Yes
```
### Function: `buildin-set?` 
```
  buildin-set? : any -> bool
  
  Pure? Yes
```
### Function: `buildin-strcat` 
```
  buildin-strcat : string -> string -> string
  
  Pure? Yes
```
### Function: `buildin-string-add` 
```
  buildin-string-add : string -> any -> string
  
  Pure? Yes
```
### Function: `buildin-string-append` 
```
  buildin-string-append : string -> string -> string
  
  Pure? Yes
```
### Function: `buildin-string-chars` 
```
  buildin-string-chars : string -> sequence
  
  Pure? Yes
```
### Function: `buildin-string-eq?` 
```
  buildin-string-eq? : string -> string -> string
  
  Pure? Yes
```
### Function: `buildin-string-includes?` 
```
  buildin-string-includes? : string -> string -> string
  
  Pure? Yes
```
### Function: `buildin-string-nth` 
```
  buildin-string-nth : string -> int -> any
  
  Pure? Yes
```
### Function: `buildin-string-range` 
```
  buildin-string-range : string -> int -> int -> string
  
  Pure? Yes
```
### Function: `buildin-string-size` 
```
  buildin-string-size : string -> int
  
  Pure? Yes
```
### Function: `buildin-string-split-at` 
```
  buildin-string-split-at : string -> int -> sequence
  
  Pure? Yes
```
### Function: `buildin-string?` 
```
  buildin-string? : any -> bool
  
  Pure? Yes
```
### Function: `buildin-take` 
```
  buildin-take : list -> int -> list
  
  Pure? Yes
```
### Function: `buildin-unwrap` 
```
  buildin-unwrap : unwrappable -> any
  
  Pure? Yes
  
  Unraps the argument.
```
### Function: `buildin-vector` 
```
  buildin-vector : any* -> vector
  
  Pure? Yes
```
### Function: `buildin-vector-add` 
```
  buildin-vector-add : vector -> any -> vector
  
  Pure? Yes
```
### Function: `buildin-vector-append` 
```
  buildin-vector-append : vector -> vector -> vector
  
  Pure? Yes
```
### Function: `buildin-vector-eq?` 
```
  buildin-vector-eq? : vector -> vector -> vector
  
  Pure? Yes
```
### Function: `buildin-vector-includes?` 
```
  buildin-vector-includes? : vector -> vector -> vector
  
  Pure? Yes
```
### Function: `buildin-vector-nth` 
```
  buildin-vector-nth : vector -> int -> any
  
  Pure? Yes
```
### Function: `buildin-vector-range` 
```
  buildin-vector-range : vector -> int -> int -> vector
  
  Pure? Yes
  
  Return sub-vector of a vector from the start-index to the end-index (exclusive).
```
### Function: `buildin-vector-size` 
```
  buildin-vector-size : vector -> int
  
  Pure? Yes
```
### Function: `buildin-vector?` 
```
  buildin-vector? : any -> bool
  
  Pure? Yes
```
### Function: `callstack` 
```
  
  
  Pure? Yes
  
  callstack : sequence
```
### Function: `car` 
```
  car : list -> any
  
  Pure? Yes
```
### Function: `cdr` 
```
  cdr : list -> list
  
  Pure? Yes
```
### Function: `char?` 
```
  char? : any -> bool
  
  Pure? Yes
```
### Function: `class` 
```
  class : any -> symbol
  
  Pure? Yes
```
### Function: `cons` 
```
  cons : any -> list -> list
  
  Pure? Yes
```
### Function: `copy` 
```
  copy : any -> any
  
  Pure? Yes
  
  Only copies boxes. For all other types, it returns its input.
```
### Function: `defined?` 
```
  defined? : any -> bool
  
  Pure? Yes
  
  Checks whether a symbol is defined.
```
### Function: `delay` 
```
  delay : function -> delay
  
  Pure? Yes
```
### Function: `delay-timeout` 
```
  delay-timeout : function -> int -> delay
  
  Pure? Yes
```
### Function: `denominator` 
```
  denominator : rational -> int|#
  
  Pure? Yes
```
### Function: `eager` 
```
  eager : any -> any
  
  Pure? Yes
  
  Eagerly evaluates a variable (delay, lazy list, etc.).
```
### Function: `eq?` 
```
  eq? : any -> any -> bool
  
  Pure? Yes
```
### Function: `error!` 
```
  error! : string -> error
  error! : string -> any -> error
  error! : string -> any -> sequence -> error
  
  Pure? No
```
### Function: `error-info` 
```
  error-info : error -> any
  
  Pure? Yes
```
### Function: `error-msg` 
```
  error-msg : error -> string
  
  Pure? Yes
```
### Function: `error-trace` 
```
  error-trace : error -> sequence
  
  Pure? Yes
```
### Function: `eval!` 
```
  eval! : expr -> any
  
  Pure? No
```
### Function: `evaluated` 
```
  evaluated : any -> bool
  
  Pure? Yes
  
  Checks whether a variable has been evaluated.
```
### Function: `exit!` 
```
  exit! : int -> Nothing
  
  Pure? No
```
### Function: `file-append!` 
```
  file-append! : string -> string -> string
  
  Pure? No
```
### Function: `file-read!` 
```
  file-read! : string -> string
  
  Pure? No
```
### Function: `file-write!` 
```
  file-write! : string -> string -> string
  
  Pure? No
```
### Function: `float?` 
```
  float? : any -> bool
  
  Pure? Yes
```
### Function: `function?` 
```
  function? : any -> bool
  
  Pure? Yes
```
### Function: `gensym` 
```
  gensym : symbol -> symbol
  
  Pure? Yes
  
  Builds a unique symbol.
  (gensym 'lambda) => some unique symbol including lambda.
  (gensym 'lambda) => a different unique symbol including lambda.
```
### Function: `hash` 
```
  hash : any -> int
  
  Pure? Yes
```
### Function: `id` 
```
  id : any -> any
  
  Pure? Yes
  
  Returns its input.
```
### Function: `import!` 
```
  import! : string -> string ->
  
  Pure? No
```
### Function: `int?` 
```
  int? : any -> bool
  
  Pure? Yes
```
### Function: `iterate-seq` 
```
  iterate-seq : (any -> any -> int) -> any -> sequence -> any
  
  Pure? Yes
  
  Takes a function, an accumulator and a sequence. The function is applied
  to the accumulator, the current element and the current index for every
  element in the sequence.
  This function only works for buildin lists and buildin vectors. Usage is
  generally not adviced.
   (iterate-seq (lambda (acc x i) (+ acc i))
                0 '(a b c d e)) ;=> 10
```
### Function: `iterate-seq-p` 
```
  iterate-seq-p : (any -> any -> int -> bool) -> (any -> any) -> any -> sequence -> any
  
  Pure? Yes
  
  Takes a function, an accumulator and a sequence. The function is applied
  to the accumulator, the current element and the current index for every
  element in the sequence.
  This is done as long as the predicate function p holds true.
  This function only works for buildin lists and buildin vectors. Usage is
  generally not adviced.
   (iterate-seq-p (lambda (acc x i) (< i 3))
                  (lambda (acc x i) (+ acc i))
                  0 '(a b c d e)) ;=> 3
```
### Function: `keyword-name` 
```
  keyword-name : keyword -> symbol
  
  Pure? Yes
```
### Function: `keyword?` 
```
  keyword? : any -> bool
  
  Pure? Yes
```
### Function: `lazy?` 
```
  lazy? : any -> bool
  
  Pure? Yes
```
### Function: `list-concat` 
```
  list-concat : list -> list -> list
  
  Pure? Yes
```
### Function: `list-size` 
```
  list-size : list -> int
  
  Pure? Yes
```
### Function: `list?` 
```
  list? : any -> bool
  
  Pure? Yes
```
### Function: `ljust` 
```
  ljust : string -> int -> string
  
  Pure? Yes
```
### Function: `load!` 
```
  
  
  Pure? No
  
  load! : string ->
```
### Function: `map->vector` 
```
  map->vector : map -> vector
  
  Pure? Yes
```
### Function: `map-entries` 
```
  map-entries : map -> sequence
  
  Pure? Yes
```
### Function: `map-eq?` 
```
  map-eq? : map -> map -> bool
  
  Pure? Yes
```
### Function: `map-get` 
```
  map-get : map -> any -> any
  
  Pure? Yes
```
### Function: `map-has-key?` 
```
  map-has-key? : map -> any -> bool
  
  Pure? Yes
```
### Function: `map-has-value?` 
```
  map-has-value? : map -> any -> bool
  
  Pure? Yes
```
### Function: `map-keys` 
```
  map-keys : map -> collection
  
  Pure? Yes
```
### Function: `map-merge` 
```
  map-merge : map -> map -> map
  
  Pure? Yes
```
### Function: `map-of` 
```
  map-of : any* -> map
  
  Pure? Yes
```
### Function: `map-remove` 
```
  map-remove : map -> any -> map
  
  Pure? Yes
```
### Function: `map-set` 
```
  map-set : map -> any -> any -> map
  
  Pure? Yes
```
### Function: `map-size` 
```
  map-size : map -> int
  
  Pure? Yes
```
### Function: `map?` 
```
  map? : any -> bool
  
  Pure? Yes
```
### Function: `measure!` 
```
  measure! : int -> (any) -> int
  
  Pure? No
```
### Function: `memoize` 
```
  memoize : function -> function
  
  Pure? Yes
```
### Function: `nil?` 
```
  nil? : any -> bool
  
  Pure? Yes
  
  #t for Nothing. #f for anything else.
```
### Function: `none?` 
```
  none? : (any -> bool) -> collection -> bool
  
  Pure? Yes
```
### Function: `not` 
```
  not : any -> bool
  
  Pure? Yes
  
  Returns #f for a truthy value and #t for a falsey value.
```
### Function: `nothing` 
```
  nothing : any* -> Nothing
  
  Pure? Yes
  
  Takes any number of arguments and returns Nothing.
```
### Function: `nothing?` 
```
  nothing? : any -> bool
  
  Pure? Yes
  
  #t for Nothing. #f for anything else.
```
### Function: `null?` 
```
  null? : any -> bool
  
  Pure? Yes
  
  #t for Nothing and the empty list. #f for anything else.
```
### Function: `numerator` 
```
  numerator : rational -> int
  
  Pure? Yes
```
### Function: `partial` 
```
  partial : function -> any* -> function
  
  Pure? Yes
  
  Creates a partial function.
```
### Function: `rational?` 
```
  rational? : any -> bool
  
  Pure? Yes
```
### Function: `read-string` 
```
  read-string : string -> expr
  
  Pure? Yes
```
### Function: `readln!` 
```
  readln! : string -> Nothing
  
  Pure? No
```
### Function: `ref=` 
```
  ref= : any* -> bool
  
  Pure? Yes
```
### Function: `rem` 
```
  rem : any* -> any
  
  Pure? Yes
```
### Function: `seq` 
```
  seq : any -> list
  
  Pure? Yes
  
  Turns a variable into a list. If the variable is not a collecttion or if the variable is empty, it returns Nothing instead.
```
### Function: `sqrt` 
```
  sqrt : number -> number
  
  Pure? Yes
```
### Function: `symbol?` 
```
  symbol? : any -> bool
  
  Pure? Yes
```
### Function: `unbox` 
```
  unbox : box -> any
  
  Pure? Yes
  
  Unraps the argument.
```
# File: set.lyra



## Macros


## Functions

### Function: `->map#set` 
```
  ->map#set : set -> map
  
  Pure? Yes
```
### Function: `->set#set` 
```
  ->set#set : set -> set
  
  Pure? Yes
```
### Function: `->string#set` 
```
  ->string#set : set -> string
  
  Pure? Yes
```
### Function: `->vector#set` 
```
  ->vector#set : set -> vector
  
  Pure? Yes
```
### Function: `add#set` 
```
  add#set : set -> any -> set
  
  Pure? Yes
```
### Function: `add-front#set` 
```
  add-front#set : set -> any -> set
  
  Pure? Yes
```
### Function: `append#set` 
```
  append#set : set -> collection -> set
  
  Pure? Yes
```
### Function: `collection?#set` 
```
  collection?#set : set -> bool
  
  Pure? Yes
```
### Function: `contains?#set` 
```
  contains?#set : set -> any -> bool
  
  Pure? Yes
```
### Function: `eq?#set` 
```
  eq?#set : set -> set -> bool
  
  Pure? Yes
```
### Function: `find#set` 
```
  find#set : set -> any -> bool
  
  Pure? Yes
```
### Function: `first#set` 
```
  first#set : set -> set
  
  Pure? Yes
```
### Function: `foldl#set` 
```
  foldl#set : (any -> any -> any) -> any -> set -> any
  
  Pure? Yes
```
### Function: `foldr#set` 
```
  foldl#set : (any -> any -> any) -> any -> set -> any
  
  Pure? Yes
```
### Function: `get#set` 
```
  get#set : set -> any -> bool
  
  Pure? Yes
```
### Function: `list->set` 
```
  list->set : sequence -> set
  
  Pure? Yes
  
  Turns a list (or any sequence for that matter) into a set.
  Notice that `(->list (list->set xs))` is does not necessarily return the elements in the same order!
```
### Function: `nth#set` 
```
  nth#set : set -> int -> any
  
  Pure? Yes
```
### Function: `rest#set` 
```
  rest#set : set -> set
  
  Pure? Yes
```
### Function: `reverse#set` 
```
  reverse#set : set -> set
  
  Pure? Yes
```
### Function: `set->vector` 
```
  set->vector : set -> vector
  
  Pure? Yes
  
  Turns a set into a vector. There is no guarantees made about the order of elements.
```
### Function: `set-add` 
```
  set-add : set -> any -> set
  
  Pure? Yes
```
### Function: `set-difference` 
```
  set-difference : set -> set -> set
  
  Pure? Yes
```
### Function: `set-eq?` 
```
  set-eq? : set -> set -> bool
  
  Pure? Yes
```
### Function: `set-includes?` 
```
  set-includes? : set -> set -> set
  
  Pure? Yes
```
### Function: `set-intersection` 
```
  set-intersection : set -> set -> set
  
  Pure? Yes
```
### Function: `set-of` 
```
  set-of : any* -> set
  
  Pure? Yes
```
### Function: `set-size` 
```
  set-size : set -> int
  
  Pure? Yes
```
### Function: `set-subset?` 
```
  set-subset? : set -> set -> set
  
  Pure? Yes
```
### Function: `set-superset?` 
```
  set-superset? : set -> set -> set
  
  Pure? Yes
```
### Function: `set-true-subset?` 
```
  set-true-subset? : set -> set -> set
  
  Pure? Yes
```
### Function: `set-true-superset?` 
```
  set-true-superset? : set -> set -> set
  
  Pure? Yes
```
### Function: `set-union` 
```
  set-union : set -> set -> set
  
  Pure? Yes
```
### Function: `set?` 
```
  set? : any -> bool
  
  Pure? Yes
```
### Function: `size#set` 
```
  size#set : set -> int
  
  Pure? Yes
```
# File: string.lyra



## Macros


## Functions

### Function: `->float#string` 
```
  ->float#string : string -> float
  
  Pure? Yes
```
### Function: `->int#string` 
```
  ->int#string : string -> int
  
  Pure? Yes
```
### Function: `->list#string` 
```
  ->list#string : string -> list
  
  Pure? Yes
  
  Turns a string into a list of characters.
```
### Function: `->map#string` 
```
  
  
  Pure? Yes
  
  ->map#string :
```
### Function: `->set#string` 
```
  
  
  Pure? Yes
  
  ->set#string :
```
### Function: `->vector#string` 
```
  ->vector#string : string -> vector
  
  Pure? Yes
  
  Turns a string into a vector of characters.
```
### Function: `>rational#string` 
```
  >rational#string : string -> rational
  
  Pure? Yes
```
### Function: `add#string` 
```
  add#string : string -> any -> string
  
  Pure? Yes
```
### Function: `add-front#string` 
```
  add-front#string : string -> any -> string
  
  Pure? Yes
```
### Function: `append#string` 
```
  
  
  Pure? Yes
  
  append#string :
```
### Function: `contains?#string` 
```
  
  
  Pure? Yes
  
  contains?#string :
```
### Function: `eq?#string` 
```
  eq?#string : string -> string -> bool
  
  Pure? Yes
```
### Function: `first#string` 
```
  
  
  Pure? Yes
  
  first#string :
```
### Function: `foldl#string` 
```
  foldl#string : (any -> character -> any) -> any -> string -> any
  
  Pure? Yes
```
### Function: `foldr#string` 
```
  foldr#string : (character -> any -> any) -> any -> string -> any
  
  Pure? Yes
```
### Function: `nth#string` 
```
  
  
  Pure? Yes
  
  nth#string :
```
### Function: `prepend#string` 
```
  prepend#string : string -> any -> string
  
  Pure? Yes
  
  Special implementation for prepend for strings.
```
### Function: `rest#string` 
```
  
  
  Pure? Yes
  
  rest#string :
```
### Function: `reverse#string` 
```
  reverse#string : string -> string
  
  Pure? Yes
```
### Function: `sequence?#string` 
```
  sequence?#string : string -> bool
  
  Pure? Yes
  
  Strings are sequences, so this always returns #t.
```
### Function: `size#string` 
```
  
  
  Pure? Yes
  
  size#string :
```
### Function: `strcat` 
```
  strcat : string -> any -> string
  
  Pure? Yes
  
  Similar to string-add, but uses buildin ->string for the second argument.
```
### Function: `string-add` 
```
  string-add : string -> any -> string
  
  Pure? Yes
```
### Function: `string-append` 
```
  string-append : string -> string -> string
  
  Pure? Yes
```
### Function: `string-chars` 
```
  string-chars : string -> list
  
  Pure? Yes
```
### Function: `string-concat` 
```
  string-concat : list -> string
  Required for elements of xs: ->string
  
  Pure? Yes
  
  Similar to concat, but turns each element into a string.
  Required for xs: foldr1, map-eager
```
### Function: `string-eq?` 
```
  string-eq? : string -> string -> bool
  
  Pure? Yes
  
  String equality check.
```
### Function: `string-includes?` 
```
  string-includes? : string -> string -> bool
  
  Pure? Yes
```
### Function: `string-nth` 
```
  string-nth : string -> int -> char
  
  Pure? Yes
```
### Function: `string-range` 
```
  string-range : int -> int -> string -> string
  
  Pure? Yes
  
  Returns a substring `(string-range 2 5 text)` returns the third through 5th character.
  `(string-range 2 4 "abcde") ;=> "cd"`
```
### Function: `string-reverse` 
```
  string-reverse : string -> string
  
  Pure? Yes
```
### Function: `string-size` 
```
  string-size : string -> int
  
  Pure? Yes
```
### Function: `string-split-at` 
```
  string-split-at : string -> string -> list
  
  Pure? Yes
```
### Function: `string?` 
```
  string? : any -> bool
  
  Pure? Yes
```
### Function: `succ#string` 
```
  succ#string : string -> string
  
  Pure? Yes
```
# File: vector.lyra



## Macros


## Functions

### Function: `->map#vector` 
```
  ->map#vector : vector -> map
  
  Pure? Yes
```
### Function: `->set#vector` 
```
  ->set#vector : vector -> set
  
  Pure? Yes
```
### Function: `->string#vector` 
```
  ->string#vector : vector -> string
  
  Pure? Yes
```
### Function: `->vector#vector` 
```
  ->vector#vector : vector -> vector
  
  Pure? Yes
```
### Function: `add#vector` 
```
  
  
  Pure? Yes
  
  add#vector : vector ->
```
### Function: `append#vector` 
```
  append#vector : vector -> collection -> vector
  
  Pure? Yes
```
### Function: `collection?#vector` 
```
  collection?#vector : vector -> bool
  
  Pure? Yes
  
  Always true.
```
### Function: `contains?#vector` 
```
  contains?#vector : vector -> any -> bool
  
  Pure? Yes
```
### Function: `eq?#vector` 
```
  
  
  Pure? Yes
  
  eq?#vector : vector ->
```
### Function: `filterv` 
```
  filterv : (any -> bool) -> collection -> vector
  
  Pure? Yes
  
  Eagerly filter and return vector.
  Required: foldl
```
### Function: `first#vector` 
```
  first#vector : vector -> any
  
  Pure? Yes
```
### Function: `foldl#vector` 
```
  foldl#vector : (any -> any -> any) -> any -> vector -> any
  
  Pure? Yes
```
### Function: `foldr#vector` 
```
  foldr#vector : (any -> any -> any) -> any -> vector -> any
  
  Pure? Yes
```
### Function: `list->vector` 
```
  list->vector : sequence -> vector
  
  Pure? Yes
```
### Function: `mapv` 
```
  mapv : (any -> any) -> collection -> vector
  
  Pure? Yes
  
  eager map which returns a vector. Relies on foldl and vector-add.
```
### Function: `mapv-indexed` 
```
  mapv-indexed : (any -> int -> any) -> collection -> vector
  
  Pure? Yes
  
  eager mapv with index. Requires: foldl-indexed.
```
### Function: `nth#vector` 
```
  nth#vector : vector -> int -> any
  
  Pure? Yes
```
### Function: `rest#vector` 
```
  rest#vector : vector -> vector
  
  Pure? Yes
```
### Function: `sequence?#vector` 
```
  sequence?#vector : vector -> bool
  
  Pure? Yes
  
  Always true.
```
### Function: `size#vector` 
```
  size#vector : vector -> int
  
  Pure? Yes
```
### Function: `vector` 
```
  vector : any* -> vector
  
  Pure? Yes
```
### Function: `vector-add` 
```
  vector-add : vector -> any -> vector
  
  Pure? Yes
```
### Function: `vector-append` 
```
  vector-append : vector -> vector -> vector
  
  Pure? Yes
```
### Function: `vector-eq?` 
```
  vector-eq? : vector -> vector -> bool
  
  Pure? Yes
```
### Function: `vector-includes?` 
```
  vector-includes? : vector -> any -> bool
  
  Pure? Yes
```
### Function: `vector-nth` 
```
  vector-nth : vector -> int -> any
  
  Pure? Yes
```
### Function: `vector-range` 
```
  vector-range : int -> int -> vector -> vector
  
  Pure? Yes
  
  Same as `range` from the core module, but for vectors.
```
### Function: `vector-size` 
```
  vector-size : vector -> int
  
  Pure? Yes
```
### Function: `vector?` 
```
  vector? : any -> bool
  
  Pure? Yes
```
