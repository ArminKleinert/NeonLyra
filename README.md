# NeonLyra

Lyra is a lisp I make for fun and learning. NeonLyra is an improved version.

Current version: 0.0.4

Inspired by Scheme, Clojure, Haskell, Ruby and the text on my coffee cub.

## Goals and priorities:

- Having fun

## Features:

- Different numeric types: Integer and Float  
- Macros  
- Tail recursion  
- Lazy evaluation (not implemented)  
- Ease of use for Clojurians.

## Differences to original Lyra:

- No `set-car!` or `set-cdr!` and no mutating functions for vectors.  
- No shying away from using more native functions.  
- Lists have a size. To count the elements, it does not have to be iterated.  
- User-defined types use native functions.  
- A module system.  

## Types:

- Symbol  
- Basic numbers: Integer, Float  
- String  
- List (car, cdr, size)  
- Boolean (#t, #f)  
- Nothing (Returned on failed type conversions or similar situations)  
- Function  
- Vector  
- Map  
- Lazy  
- Box (The only mutable type)  
- Set (Not implemented)  

## Some friendly infos about the syntax 

- `(...)` is used for function calls.  
- `'expr` quotes an expression and is equivalent to (quote expr)  
- `[...]` creates a vector. It is not fully the same as `(vector ...)`, but gives the same value.  
- `'()` is the empty list. (Not just `()`)  
- `let` is the sequential let expression.  
- `let1` defines a single variable.  
- `<expr>.?` becomes (unwrap <expr>)  
- `<expr>.!` becomes (eager <expr>)  
- `@<expr>` becomes (unbox <expr>)  
- `#t` is literal true  
- `#f` is literal false  
- Numbers can start with the prefixes `0x` or `0b` for hexadecimal or binary literals.

## Differences to Clojure:

Clojure influences Lyra a lot. Still, every language has things I love and things I hate.  
Lyra is by design much less powerful than Clojure because it tries to be as functionally pure as it can. This forbids access to the host language as well as streams to files and sockets.  
Please keep in mind that most of this might change in the future, since Lyra is partially still in planning. Most of these differences are build into the design of the language though. 
Here are some differences to Clojure I could think of:  

- Lyra is a hobby project and not a serious attempt at making something great.  
- Bad performance. :(  
- Box instead of `Atom`.  
- Boxes are not synchronized.  
- Creators for user-defined types should start with `make-` instead of `->`.  
- Disallows overriding old defs.  
- Functions and variables are created using scheme-style `define`. (though `def` and `defn` are available as aliases but discouraged)  
- `nil` is called `Nothing` in reference to Haskell.  
- No meta-data.  
- No method-access using `.` and `..`.  
- No `Keyword` type (Maybe in the future).  
- No `letfn` (All `let` variants can do this, just like in Clojure).  
- No access to the host language.  
- No arrays.  
- No build-in loops.  
- No keyword access for maps. (I really want it though)  
- No literals for `Map`.  
- No literals for `Set`.  
- No primitive (value) types.  
- No streams to files or sockets.  
- No transients.  
- Only Boxes can be copied.  
- Still going through a lot of changes.  
- Tail recursion. (`recur` will be available too)  
- The empty list is a singleton and false.  
- Type-conversion functions are always marked with `->`.  
- Type-conversion functions return `Nothing` if conversion failed.  
- Type hints can only be used in function arguments.  
- There are no type hints.  
- User-defined types are not maps.  
- `(lambda (...) ...)` instead of `(fn [...] ...)`. (fn is available as an alias)  
- `#f`, `Nothing` and `'()` are all false  
- `false` is an alias for `#f`.  
- `module` surrounds a list of expressions instead of being used at the top of a file only.  
- `seq` returns `Nothing` for all types that aren't collections.  
- modules (`module`) instead of namespaces (`ns`).  
- `true` is an alias for `#t`.  
- All impure functions end with the postfix `!` (like `load!`, `readln!`, ...).  

## Example

```
; sum using normal recursion
(define (sum xs) (if (empty? xs) 0 (+ (first xs) (sum (rest xs)))))

; sum using tail-recursion and default value (not implemented yet)
(define (sum xs (res 0)) (if (empty? xs) res (sum (rest xs) (+ (first xs) res))))

; sum using foldl
(define (sum xs) (foldl + 0 xs))

; sum using a partial function
(define sum (partial + 0))
```

## Changelog

- 0.0.1 The thing works but lacks functionality.  
- 0.0.2 Macros, types, more functions, modules, @ prefix  
- 0.0.3 measure, memoize, def-memo, fixed lookup bug in lambdas  
- 0.0.4 Loading of other source-files, more functions, aggressive optimizer (currently turned off)  
