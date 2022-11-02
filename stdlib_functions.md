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

