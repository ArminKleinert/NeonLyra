# File: core/aliases.lyra


## Functions

### Function: `∉` 
```
  ∉ : any -> collection -> bool
  
  Pure? Yes
  
  Alias for (comp not included?)
```
### Function: `includes?` 
```
  includes? : collection -> any -> bool
  
  Pure? Yes
  
  Alias for contains?
```
### Function: `require!` 
```
  require! : sequence -> sequence
  
  Pure? No
  
  Alias for load!
```
### Function: `fold` 
```
  fold : (any -> any -> any) -> any -> collection -> any
  
  Pure? Yes
  
  Alias for foldr.
```
### Function: `member?` 
```
  member? : any -> collection -> bool
  
  Pure? Yes
  
  Alias for included?
```
### Function: `⋅` 
```
  ⋅ : (any -> any) -> (any -> any) -> (any -> any)
  
  Pure? Yes
  
  Alias for
```
### Function: `∀` 
```
  ∀ : (any -> bool) -> collection -> bool
  
  Pure? Yes
  
  Alias for all?.
```
### Function: `∃` 
```
  ∃ : (any -> bool) -> collection -> bool
  
  Pure? Yes
  
  Alias for any?.
```
### Function: `∄` 
```
  ∄ : (any -> bool) -> collection -> bool
  
  Pure? Yes
  
  Alias for none?.
```
### Function: `≠` 
```
  ≠ : number -> number -> bool
  
  Pure? Yes
  
  Alias for /=.
```
### Function: `≥` 
```
  ≥ : number -> number -> bool
  
  Pure? Yes
  
  Alias for >=.
```
### Function: `≤` 
```
  ≤ : number -> number -> bool
  
  Pure? Yes
  
  Alias for <=.
```
### Function: `∈` 
```
  ∈ : any -> collection -> bool
  
  Pure? Yes
  
  Alias for included?.
```
### Function: `<=>` 
```
  <=> : any -> any -> bool
  
  Pure? Yes
  
  Alias for compare.
```
### Function: `++` 
```
  ++ : sequence -> sequence -> sequence
  
  Pure? Yes
  
  Alias for append.
```
### Function: `uniq` 
```
  uniq : collection -> collection
  
  Pure? Yes
  
  Alias for unique.
```
# File: core/clj.lyra


## Constants

### Constant: `nil` 
```
  
  
  Pure? Yes
  
  nil : Nothing
  Alias for Nothing.
```

## Macros

### Macro: `when` 
```
  when : expr -> expr* -> expr
  
  Pure? Yes
  
  Works as an if without an else branch. If the predicate does not hold true, Nothing is returned.
```
### Macro: `def` 
```
  def : symbol -> expr -> expr
  
  Pure? Yes
  
  Works as define for variables.
```
### Macro: `defn` 
```
  defn : symbol -> sequence|string|map -> sequence? -> expr* -> expr
  
  Pure? Yes
  
  Works as define for functions. Does not support inlined documentation and meta-data.
  (defn f [a b] ...)                 => (define (f a b) ...)
  (defn f {meta-data} [a b] ...)     => (define (f a b) ...)
  (defn f "documentation" [a b] ...) => (define (f a b) ...)
```
### Macro: `fn` 
```
  fn : (symbol|sequence -> expr*)+ -> expr
  
  Pure? Yes
  
  Defines a function, as lambda does, but can also create named funktions like lambda* or case-lambdas, depending on the form.
  (fn [a b] ...)               => (lambda (a b) ...)
  (fn f [a b] ...)             => (lambda* f (a b) ...)
  (fn ([a] ...) ([a b] ...))   => (case-lambda ((a) ...) ((a b) ...))
  (fn f ([a] ...) ([a b] ...)) => (case-lambda* f ((a) ...) ((a b) ...))
```

## Functions

### Function: `nthrest` 
```
  nthrest : sequence -> int -> sequence
  
  Pure? Yes
  
  Drops the first i elements from a sequence.
```
### Function: `nthnext` 
```
  nthnext : sequence -> int -> sequence
  
  Pure? Yes
  
  Drops the first i elements from a sequence. Returns Nothing if the size was less than i.
```
### Function: `next` 
```
  next : sequence -> sequence
  
  Pure? Yes
  
  Drops the first element from a sequence. Returns Nothing if the size was less than 1.
```
### Function: `fnext` 
```
  fnext : sequence -> any
  
  Pure? Yes
  
  Same as (first (next xs)).
```
### Function: `ffirst` 
```
  ffirst : sequence -> any
  
  Pure? Yes
  
  Same as (first (first xs)).
```
### Function: `nnext` 
```
  nnext : sequence -> sequence
  
  Pure? Yes
  
  Same as (next (next xs)).
```
### Function: `nfirst` 
```
  nfirst : sequence -> sequence
  
  Pure? Yes
  
  Same as (next (first xs)).
```
### Function: `reduce` 
```
  reduce : (any -> any -> any) -> any -> sequence -> any
  reduce : (any -> any -> any) -> sequence -> any
  
  Pure? Yes
  
  Same as foldl if 3 arguments are given or foldl1 if there are 2 arguments.
```
### Function: `reductions` 
```
  reductions : (any -> any -> any) -> any -> collection -> list
  reductions : (any -> any -> any) -> collection -> list
  
  Pure? Yes
  
  Same as scanl if 3 arguments are given or scanl1 if there are 2 arguments.
```
### Function: `some` 
```
  some : (any -> bool) -> sequence -> any
  
  Pure? Yes
  
  Checks whether any element in xs matches the predicate p. If so, the element is returned. Otherwise, returns Nothing.
```
### Function: `some?` 
```
  some? : any -> bool
  
  Pure? Yes
  
  Same as (not (nothing? x)).
```
### Function: `some-fn` 
```
  some-fn : (any* -> any) -> (any* -> any)* -> (any -> any)
  
  Pure? Yes
  
  Takes any number (> 0) of (any* -> any) functions. If any of them
  return a truthy value for a given argument, returns the matching value.
```
### Function: `keep` 
```
  keep : (any -> any) -> collection -> sequence
  
  Pure? Yes
```
### Function: `do` 
```
  do : [expr]* -> expr
  
  Pure? Yes
  
  Alias for begin.
```
### Function: `slurp!` 
```
  slurp! : string -> string
  
  Pure? No
  
  Alias for file-read!.
```
### Function: `spit!` 
```
  spit! : string -> string -> int
  
  Pure? No
  
  Alias for file-write!.
```
### Function: `count` 
```
  count : collection -> int
  
  Pure? Yes
  
  Alias for size.
```
### Function: `str` 
```
  str : string -> string* -> string
  
  Pure? Yes
  
  Alias for string-concat.
```
### Function: `vec` 
```
  vec : collection -> vector
  
  Pure? Yes
  
  Alias for ->vector.
```
### Function: `not-any?.` 
```
  not-any? : (any -> bool) -> collection -> bool
  
  Pure? Yes
  
  Alias for none?
```
### Function: `every?` 
```
  every? : (any -> bool) -> collection -> bool
  
  Pure? Yes
  
  Alias for all?.
```
# File: core/infix.lyra

# File: core/queue.lyra


## Functions

### Function: `deque` 
```
  deque : any* -> deque
  
  Pure? Yes
  
  Takes any number of arguments any returns a deque of them.
```
### Function: `queue` 
```
  queue : any* -> queue
  
  Pure? Yes
  
  Takes any number of arguments any returns a queue of them.
```
### Function: `queue?` 
```
  queue? : any -> bool
  
  Pure? Yes
  
  Checks whether a variable is a queue.
```
### Function: `enqueue` 
```
  enqueue : queue -> any -> queue
  
  Pure? Yes
```
### Function: `dequeue` 
```
  dequeue : queue -> queue
  
  Pure? Yes
  
  Returns the queue with the first element removed.
```
### Function: `enqueue-all` 
```
  dequeue : queue -> collection -> queue
  
  Pure? Yes
  
  Enqueues all elements of a collection.
```
### Function: `peek` 
```
  peek : sequence -> any
  
  Pure? Yes
  
  Get the first element from a sequence. If the sequence is a vector,
  it gets the last element instead.
```
### Function: `pop` 
```
  pop : sequence -> any
  
  Pure? Yes
  
  Removes the first element from a sequence.
  If the sequence is a vector, it removes the last element instead.
```
### Function: `push` 
```
  push : sequence -> any -> sequence
  
  Pure? Yes
  
  Appends an element to a sequence If the sequence is a list, the
  element is prepended instead.
```
### Function: `deque-eq?` 
```
  deque-eq? : deque -> deque -> bool
  
  Pure? Yes
  
  Checks whether 2 deques are equal.
```
### Function: `first#deque` 
```
  first#deque : deque -> any
  
  Pure? Yes
  
  Implementation for first.
```
### Function: `rest#deque` 
```
  rest#deque : deque -> deque
  
  Pure? Yes
  
  Implementation for rest.
```
### Function: `add#deque` 
```
  add#deque : deque -> any -> deque
  
  Pure? Yes
  
  Implementation for add. Alias for enqueue.
```
### Function: `append#deque` 
```
  append#deque : deque -> collection -> deque
  
  Pure? Yes
  
  Implementation for append. Alias for enqueue-all.
```
### Function: `prepend#deque` 
```
  prepend#deque : deque -> any -> deque
  
  Pure? Yes
  
  Implementation for prepend.
```
### Function: `add-front#deque` 
```
  add-front#deque : deque -> any -> deque
  
  Pure? Yes
  
  Implementation for add-front.
```
### Function: `->deque` 
```
  ->deque : collection -> deque
  
  Pure? Yes
  
  Turns a collection into a deque.
```
### Function: `->queue` 
```
  ->queue : collection -> queue
  
  Pure? Yes
  
  Turns a collection into a queue.
```
### Function: `sequence?#deque` 
```
  sequence?#deque : any -> bool
  
  Pure? Yes
  
  Returns #t.
```
### Function: `->list#deque` 
```
  ->list#deque : deque -> list
  
  Pure? Yes
  
  Turns the deque into a list.
```
### Function: `->vector#deque` 
```
  ->vector#deque : deque -> vector
  
  Pure? Yes
  
  Turns the deque into a vector.
```
### Function: `->vector#deque` 
```
  ->vector#deque : deque -> int
  
  Pure? Yes
  
  Returns the size of the deque.
```
### Function: `reverse#deque` 
```
  reverse#deque : deque -> deque
  
  Pure? Yes
  
  Reverses a deque.
```
### Function: `eq?#deque` 
```
  eq?#deque : deque -> deque -> deque
  
  Pure? Yes
  
  Alias for deque-eq?.
```
### Function: `->string#deque` 
```
  ->string#deque : deque -> string
  
  Pure? Yes
  
  String representation of a deque.
```
# File: core/random.lyra


## Functions

### Function: `splitmix64` 
```
  splitmix64 : int -> int
  
  Pure? Yes
```
### Function: `xorshift64s` 
```
  xorshift64s : int -> int
  
  Pure? Yes
  
  xorshift64* algorithm.
```
### Function: `init-seed` 
```
  init-seed : any -> int
  
  Pure? Yes
  
  Given an object, init-seed takes a hashcode of that object and puts out a number. This number can be used safely as the seed of a random number generator.
```
### Function: `random` 
```
  random : int -> int
  
  Pure? Yes
  
  Alias for splitmix64.
```
### Function: `xorshift64` 
```
  xorshift64 : int -> int
  
  Pure? Yes
  
  xorshift64 algorithm.
```
### Function: `xorshift32` 
```
  xorshift32 : int -> int
  
  Pure? Yes
  
  xorshift32 algorithm.
```
### Function: `lfsr32` 
```
  lfsr32 : int -> int
  
  Pure? Yes
  
  lfsr32 algorithm.
```
### Function: `lfsr` 
```
  lfsr : int -> int
  
  Pure? Yes
  
  lfsr32 algorithm.
```
### Function: `random-seq` 
```
  random-seq : (int -> int) -> int -> sequence
  
  Pure? Yes
  
  Returns a sequence of random numbers from a function and a starting seed.
```
### Function: `xorshift64s-seq` 
```
  xorshift64s-seq : int -> sequence
  
  Pure? Yes
  
  Returns a sequence of random numbers generated by repeated application of
  the xorshift64s algorithm.
```
### Function: `xorshift64-seq` 
```
  xorshift64-seq : int -> sequence
  
  Pure? Yes
  
  Returns a sequence of random numbers generated by repeated application of
  the xorshift64 algorithm.
```
### Function: `xorshift32-seq` 
```
  xorshift32-seq : int -> sequence
  
  Pure? Yes
  
  Returns a sequence of random numbers generated by repeated application of
  the xorshift32 algorithm.
```
### Function: `lfsr32-seq` 
```
  lfsr32-seq : int -> sequence
  
  Pure? Yes
  
  Returns a sequence of random numbers generated by repeated application of
  the lfsr32 algorithm.
```
### Function: `splitmix64-seq` 
```
  splitmix64-seq : int -> sequence
  
  Pure? Yes
  
  Returns a sequence of random numbers generated by repeated application of
  the splitmix64 algorithm.
```
### Function: `random-nums` 
```
  random-nums : int -> sequence
  
  Pure? Yes
  
  Returns a sequence of random numbers generated by repeated application of
  a random algorithm (currently xorshift64s.
```
### Function: `with-bounds` 
```
  with-bounds : sequence -> int -> int -> sequence
  
  Pure? Yes
  
  Limits every number in a sequence to be in between two numbers.
```
### Function: `shuffle` 
```
  shuffle : sequence -> int -> sequence
  
  Pure? Yes
  
  Shuffles a sequence using the sort/sort-compare and random-nums algorithms.
```
# File: core/sort.lyra


## Functions

### Function: `bubblesort` 
```
  bubblesort : collection -> list.
  
  Pure? Yes
  
  Sorts a collection
```
### Function: `mergesort` 
```
  mergesort : collection -> list.
  
  Pure? Yes
  
  Sorts a collection.
```
### Function: `mergesort-with-comparator` 
```
  mergesort-with-comparator : (any -> any -> int) -> collection -> list.
  
  Pure? Yes
  
  Sorts a collection with an algorithm that compares 2 variables.
  The algorithm returns -1, 0 or 1.
```
### Function: `mergesort-compare` 
```
  mergesort-compare : (any -> any -> int) -> collection -> list.
  
  Pure? Yes
  
  Alias for mergesort-with-comparator.
```
### Function: `sort-compare` 
```
  sort-compare : (any -> any -> int) -> collection -> list.
  
  Pure? Yes
  
  Sorts a collection with an algorithm that compares 2 variables.
  The algorithm returns -1, 0 or 1.
```
### Function: `sort` 
```
  sort : collection -> list.
  
  Pure? Yes
  
  Sorts a collection.
```
