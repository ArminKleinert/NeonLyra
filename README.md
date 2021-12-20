# NeonLyra

Lyra is a lisp I make for fun and learning. NeonLyra is an improved version.

Current version: 0.1.2

Inspired by Scheme, Clojure, Haskell, Ruby and the text on my coffee cup.

## Goals and priorities:

- Having fun

## Features:

- Different numeric types: Integer and Float  
- Macros  
- Tail recursion  
- Lazy evaluation  
- Ease of use for Clojurians.  

## Usage:

- Install Ruby (Tested with Ruby 3.0.2, jruby 9.1.17.0 and Truffleruby 21.2.0.1)  
- Clone the repo or download it as a zip  
- Run `ruby lyra.rb` to load `core.lyra` and start the repl.  
- Run `ruby lyra.rb tests.lyra` to ensure that everything works as intended.  
- Run `ruby lyra.rb <your source files>` to run your own source files.  

## Differences to original Lyra:

- No `set-car!` or `set-cdr!` and no mutating functions for vectors.  
- No shying away from using more native functions.  
- Lists (except lazy lists) have a size. To count the elements, they do not have to be iterated.  
- User-defined types use native functions.  
- A module system.  

## Types:

- Symbol  
- Basic numbers: Integer, Float, Rational  
- String  
- List (car, cdr, size)  
- Boolean (#t, #f)  
- Char
- Nothing (Returned on failed type conversions or similar situations)  
- Function  
- Vector  
- Map  
- Lazy  
- Box (The only mutable type)  
- Set  
- Error  
- Keyword  

## Some friendly infos about the syntax 

- `(...)` is used for function calls.  
- `'expr` quotes an expression and is equivalent to `(quote expr)`  
- `[...]` creates a vector. It is not fully the same as `(vector ...)`, but gives the same value.  
- `'()` is the empty list. (`()` is also valid, but discouraged)  
- `let` is the parallel let expression.  
- `let*` is the sequential let expression.  
- `<expr>.?` becomes `(unwrap <expr>)`  
- `<expr>.!` becomes `(eager <expr>)`  
- `@<expr>` becomes `(unbox <expr>)`  
- `#(...)` is an alternative syntax for anonymous functions  
- `#t` is literal true  
- `#f` is literal false  
- `#{...}` is a literal set.  
- `{...}` is a literal map.  
- `:<word>` is a keyword literal. (eg. `:a`)  
- Numbers can start with the prefixes `0x` or `0b` for hexadecimal or binary literals.
- Function with names that end in `!` are considered impure. Impure calls eagerly evaluate their parameters. They will also not be optimized away. You can mark any function as pure by not putting a `!` at the end of the name.  

## Differences to Clojure:

Clojure influences Lyra a lot. Still, every language has things I love and things I hate.  
Lyra is by design much less powerful than Clojure because it tries to be as functionally pure as it can. This forbids access to the host language as well as streams to files and sockets.  
Please keep in mind that most of this might change in the future, since Lyra is partially still in planning. Most of these differences are build into the design of the language though.  
Here are some differences to Clojure I could think of:  

- Lyra is a hobby project and not a serious attempt at making something great.  
- Bad performance. :(  
- The boolean literals are `#t` and `#f` (but are aliased as `true` and `false`)
- Box instead of `Atom`.  
- Boxes are not synchronized.  
- Creators for user-defined types should start with `make-` instead of `->`.  
- Disallows overriding old defs.  
- Functions and variables are created using scheme-style `define`. (though `def` and `defn` are available as aliases but discouraged)  
- `nil` is called `Nothing` in reference to Haskell. (`nil` is provided as an alias though)  
- No meta-data.  
- No method-access using `.` and `..`.  
- No `letfn` (yet).  
- No access to the host language.  
- No arrays.  
- No build-in loops.  
- Keyword access only works for maps. (Not for user-defined types)  
- No primitive (value) types.  
- No streams to files or sockets.  
- No transients.  
- Math ops are not variadic. Use `v+`, `v-`, ... if necessary. Same goes for `=`, `<`, ...  
- Only Boxes can be copied.  
- Still going through a lot of changes.  
- Tail recursion. (`recur` is available too)  
- The empty list is a singleton and false.  
- Type-conversion functions are always marked with `->`.  
- Type-conversion functions return `Nothing` if conversion failed.  
- There are no type hints.  
- User-defined types are not maps.  
- `(lambda (...) ...)` instead of `(fn [...] ...)`. (fn is available as an alias)  
- `#f`, `Nothing` and `'()` are all false.  
- `module` surrounds a list of expressions instead of being used at the top of a file only.  
- `seq` returns `Nothing` for all types that aren't collections.  
- modules (`module`) instead of namespaces (`ns`).  
- All impure functions must end with the postfix `!` (like `load!`, `readln!`, ...).  
- Nested `#(...)` is allowed (though discouraged)  
- Names cannot end with `'`  

The aliases can be imported using `(load! "core/clj.lyra")`. 

## Example

```
; sum using normal recursion
(define (sum xs) (if (empty? xs) 0 (+ (first xs) (sum (rest xs)))))

; sum using foldl
(define (sum xs) (foldl + 0 xs))

; sum using a partial function
(define sum (partial foldl + 0))

; sum using a lambda
(define sum (lambda (xs) (foldl + 0 xs)))

; Example macro for a Clojure-like 'when'
(def-macro (when p & body) (list 'if p (cons 'begin body) Nothing))

; Becomes (if #t (begin (println! 5) 66) Nothing)
; This expression is then evaluated, prints 5 and returns 66
(when #t (println! 5) 66)

; Becomes (if #f (begin (println! 5) 66) Nothing)
; This expression just returns Nothing
(when #f (println! 5) 66)

; Generic function which gets the first element of an object called xs.
; If no implementation is provided for the type of xs, the id function
; is used as a fallback.
; Below that are implementation of this function for the list, vector and
; string types.
; (first (list 11 12 13))   => 11
; (first (vector 21 22 23)) => 21
; (first "abc")             => "a"
; (first 123)               => 123 (No implementation found, so id is used.
(def-generic xs (first xs) id)
(def-impl ::list first car)
(def-impl ::vector first (lambda (v) (vector-nth v 0)))
(def-impl ::string first (lambda (s) (string-nth s 0)))

; Infinite sequence of numbers counting up.
(define (foo i) (lazy-seq i (foo (+ i 1))))
(take 6 (filter odd? (map inc (foo 0)))) ; => (1 3 5 7 9 11)

; Infix fun
(load! "infix.lyra")
(§ 1 + 2 * 3 = 7) ; => #t

; Error handling
; Error types raised by the standard library:
;   'arity, 'reimplementation, 'syntax, 'runtime, 'invalid-call, 'parse-error
; Attention: Using error! and try* is heavily discouraged!
(try*
  (error! "error here" 'syntax)
  (catch (lambda (x) (eq? (error-info x) 'syntax)) e 'saved))
(try*
  (error! "error here" 'syntax)
  (catch (lambda (x) (eq? (error-info x) 'not-syntax)) e 'saved)) ; Fails
(try*
  (error! "error here" 'syntax)
  (catch _ e 'saved))
; Extended try-catch with optional finally-clause
(try
  ...
  (catch v0 e ...)
  (catch v1 e ...)
  (finally ...))
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
  (pair-y p)) ; 2

; The name 'pair' can still be safely used.
(define (pair x y) (make-pair x y))

; Implementations for the generic functions first and second
(def-impl ::pair first pair-x)
(def-impl ::pair second pair-y)
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
  - Generic functions  
  - Some other bug fixes.  
- 0.0.7  
  - Many new functions.  
  - Various bug fixes.  
  - All important functions have tests.  
- 0.0.8  
  - All important functions are generic now.  
- 0.0.9  
  - Massive performance improvement (very welcome after 0.0.8).  
  - Some useless but fun macros:  
    - Fun lambdas like `(any? (λ x . x) '(#f #f #t))`  
  - More tests  
  - Better implementation for some functions  
  - Fixed foldr1  
  - Beta features (Might be removed in the next version):  
    - Function arguments are now also bound to the variables `%0` to `%15` (or less if the function call receives less arguments).  
      So `(lambda (x y) (+ x y))` and `(lambda (x y) (+ %0 %1))` are equivalent.  
    - New `#(...)` syntax for anonymous functions.  
      - The function is variadic and its arguments are bound to the variables `%0` to `%15`. Such a function must not receive more than that number of arguments.  
      - `#(+ %0 %1)` becomes `(lambda (& \x00) (+ %0 %1))`  
- 0.1.0  
  - Performance improvement  
  - Lazy and infinite sequences  
  - Safer macro inlining  
  - Optimized list concatenation  
- 0.1.1  
  - Support for random numbers  
  - Added `->`, `->>` and `as->` from Clojure  
  - Infix operations in `infix.lyra`  
  - Simpler export from modules.  
- 0.1.2  
  - Simple Repl  
  - Fixed bugs with lazy evaluation.  
  - Generic implementation definition is now done via. `def-impl`  
  - Simplified cond and load! format  
  - lambda*, case, condp, case-lambda expressions  
  - Ignore `_` arguments  
  - rational type  
- 0.1.3  
  - Error handling via. try*-catch (Usage is heavily discouraged!)  
  - char type and char literals (including utf-8 characters)  
  - Keyword type  
  - Literals for keywords, sets and maps.  
  - `loop` macro  

