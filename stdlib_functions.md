# File: core/aliases.lyra

## Macros


## Functions

### Function: `++` 
```
  ++ : sequence -> sequence -> sequence
  
  Pure? Yes
  
  Alias for append.
```
### Function: `<=>` 
```
  <=> : any -> any -> bool
  
  Pure? Yes
  
  Alias for compare.
```
### Function: `fold` 
```
  fold : (any -> any -> any) -> any -> collection -> any
  
  Pure? Yes
  
  Alias for foldr.
```
### Function: `includes?` 
```
  includes? : collection -> any -> bool
  
  Pure? Yes
  
  Alias for contains?
```
### Function: `member?` 
```
  member? : any -> collection -> bool
  
  Pure? Yes
  
  Alias for included?
```
### Function: `require!` 
```
  require! : sequence -> sequence
  
  Pure? No
  
  Alias for load!
```
### Function: `uniq` 
```
  uniq : collection -> collection
  
  Pure? Yes
  
  Alias for unique.
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
### Function: `∈` 
```
  ∈ : any -> collection -> bool
  
  Pure? Yes
  
  Alias for included?.
```
### Function: `∉` 
```
  ∉ : any -> collection -> bool
  
  Pure? Yes
  
  Alias for (comp not included?)
```
### Function: `≠` 
```
  ≠ : number -> number -> bool
  
  Pure? Yes
  
  Alias for /=.
```
### Function: `≤` 
```
  ≤ : number -> number -> bool
  
  Pure? Yes
  
  Alias for <=.
```
### Function: `≥` 
```
  ≥ : number -> number -> bool
  
  Pure? Yes
  
  Alias for >=.
```
### Function: `⋅` 
```
  ⋅ : (any -> any) -> (any -> any) -> (any -> any)
  
  Pure? Yes
  
  Alias for
```
# File: core/clj.lyra

## Macros

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
### Macro: `when` 
```
  when : expr -> expr* -> expr
  
  Pure? Yes
  
  Works as an if without an else branch. If the predicate does not hold true, Nothing is returned.
```

## Functions

# File: core/infix.lyra

## Macros


## Functions

# File: core/queue.lyra

## Macros


## Functions

# File: core/random.lyra

## Macros


## Functions

# File: core/sort.lyra

## Macros


## Functions

