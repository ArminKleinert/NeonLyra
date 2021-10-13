# NeonLyra

Lyra is a lisp I make for fun and learning. NeonLyra is an improved version.

Current version: 0.0.7

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
- Set  

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

; sum using foldl
(define (sum xs) (foldl + 0 xs))

; sum using a partial function
(define sum (partial + 0))

; Example macro for a Clojure-like 'when'
(def-macro (when p & body) (list 'if p (cons 'begin body) Nothing))

; Becomes (if #t (begin (println! 5) 66) Nothing)
; This expression is then evaluated, prints 5 and returns 66
(when #t (println! 5) 66)

; Becomes (if #f (begin (println! 5) 66) Nothing)
; This expression just returns Nothing
(when #f (println! 5) 66)

; Generic function which gets the firsst element of an object called xs.
; If no implementation is provided for the type of xs, the id function
; is used as a fallback.
; Below that are implementation of this function for the list, vector and
; string types.
; (first (list 11 12 13))   => 11
; (first (vector 21 22 23)) => 21
; (first "abc")             => "a"
; (first 123)               => 123 (No implementation found, so id is used.
(def-generic xs (first xs) id)
(define ::list first car)
(define ::vector first (lambda (v) (vector-get v 0)))
(define ::string first (lambda (s) (first (chars s))))
```

## Example of a user-defined type

```
; Registers a new type 'pair'.
; This automatically generates the functions in the current module
;   make-pair x y
;   pair? p
;   unwrap-pair p
;   pair-x p
;   pair-y p
(def-type pair x y)

(let1 (p (make-pair 1 2)) ; Creates a new pair
  (pair? p) ; #t
  (pair? 5) ; #f
  (unwrap-pair p) ; [1 2]
  (pair-x p) ; 1
  (pair-y p)) ; 1

; The name 'pair' can still be safely used.
(define (pair x y) (make-pair x y))

; Implementations for the generic functions first and second
(define ::pair first pair-x)
(define ::pair second pair-y)
```

## Changelog

- 0.0.1  
  - The thing works but lacks functionality.  
- 0.0.2  
  - Macros, types, more functions, modules, @ prefix  
- 0.0.3  
  - measure, memoize, def-memo, fixed lookup bug in lambdas  
- 0.0.4  
  - Loading of other source-files, more functions, aggressive optimizer (currently turned off)  
- 0.0.5  
  - and, or, complement, composition, take and drop (and their variants)  
  - fixed a bug with nil  
  - renamed List to ConsList and NonEmptyList to List  
- 0.0.6  
  - User-defined types  
  - Generic fuctions  
  - Some other bug fixes.  
- 0.0.7  
  - Many new functions.  
  - Various bug fixes.  
  - All important functions have tests.  


