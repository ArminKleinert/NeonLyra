# NeonLyra

Lyra is a lisp I made for fun and learning. NeonLyra is an improved version.

Current stable version: 0.2.5  
Current version: 0.2.5

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

- Install Ruby (Tested with Ruby 3.0.2 and Truffleruby 21.2.0.1)
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
- List (`car`, `cdr`, `size`)
- Boolean (`#t`, `#f`)
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
- Delay (responds to `unwrap`, `eager` and `unbox`)

## Some friendly infos about the syntax 

- `(...)` is used for function calls.
- `'expr` quotes an expression and is equivalent to `(quote expr)`
- <code>\`expr</code> quotes an expression and is equivalent to `(quasiquote expr)`
- `~expr` is equivalent to `(unquote expr)`
- `~@expr` is equivalent to `(unquote-splicing expr)`
- `[...]` creates a vector.
- `'()` is the empty list. (`()` is also valid, but discouraged)
- `let` is the sequential let expression.
- `plet` is the parallel let expression.
- `<expr>.?` becomes `(unwrap <expr>)`
- `<expr>.!` becomes `(eager <expr>)`
- `@<expr>` becomes `(unbox <expr>)`
- `#t` is literal true
- `#f` is literal false
- `#(...)` shortened form for lambda. Arguments are called `%1`, `%2`, ..., `%15` and are initialized as `Nothing` unless specified. Arguments beyond 15 are in `%&`. The total argument list is `%&&`.
- `\p(...)` is a shortcut for partial functions.
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
- `Box` instead of `Atom`.
- Boxes are not synchronized.
- Creators for user-defined types should start with `make-` instead of `->`.
- Disallows overriding old defs.
- Functions and variables are created using scheme-style `define`. (though `def` and `defn` are available as aliases but discouraged)
- `nil` is called `Nothing` as a reference to Haskell. (`nil` is provided as an alias though)
- No meta-data.
- No method-access using `.` and `..`.
- No access to the host language.
- No mutable arrays.
- No build-in loops.
- Keyword access only works for maps. (Not for user-defined types)
- No primitive (value) types.
- No streams to files or sockets.
- No transients.
- Only Boxes can be copied.
- Still going through a lot of changes.
- Tail recursion. (`recur` is available too and useful for anonymous funnctions)
- The empty list is a singleton and false.
- Type-conversion functions are always marked with `->`. (`->int`, `->string`, etc.)
- Type-conversion functions return `Nothing` if conversion failed.
- There are no type hints.
- User-defined types are not maps.
- `(lambda' (...) ...)` instead of `(fn [...] ...)`. (`fn` is available as an alias, including `fn` with different argument numbers)
- `#f`, `Nothing` and `'()` are all false.
- `module` surrounds a list of expressions instead of being used at the top of a file only.
- `seq` returns `Nothing` for all types that aren't collections.
- modules (`module`) instead of namespaces (`ns`).
- All impure functions must end with the postfix `!` (like `load!`, `readln!`, ...).
- Nested `#(...)` is allowed.
- For `map` with more than 1 collection, you need to use `mapcar`.

The aliases can be imported using `(load! "core/clj.lyra") (import! "clj" "")`. 

## Example

```scm
; sum using normal recursion
(define (sum xs) (if (empty? xs) 0 (+ (first xs) (sum (rest xs)))))

; sum using foldl
(define (sum xs) (foldl + 0 xs))

; sum using a partial function
(define sum (partial foldl + 0))

; sum using a lambda
(define sum (lambda (xs) (foldl + 0 xs)))

; sum using a hash-lambda
(define sum #(foldl + 0 %1))

; sum with optional transformation function
(define sum
  (case-lambda
    ((xs) (foldl + 0 xs))
    ((f xs) (foldl #(+ (f %1) %2) 0 xs))))

; sum with case-lambda and destructuring (pattern-matching is not supported!)
(define sum
  (case-lambda
    (((x & xs)) (if xs (+ x (sum xs)) x))
    ((f xs) (sum (map f xs)))))

; Example macro for a Clojure-like 'when'
(defmacro (when p & body) (list 'if p (cons 'begin body) Nothing))

; Using the shorter quasiquote, unquote and unquote-splicing
(defmacro (when p & body) `(if ~p (begin ~@body) Nothing))

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

```scm
; Registers a new type 'pair'.
; This automatically generates the functions in the current module
;   make-pair x y
;   pair? p
;   unwrap-pair p
;   pair-x p
;   pair-y p
(def-type pair x y)

(let ((p (make-pair 1 2))) ; Creates a new pair
  (pair? p) ; #t
  (pair? 5) ; #f
  (unwrap-pair p) ; [1 2]
  (pair-x p) ; 1
  (pair-y p)) ; 2

; The name 'pair' can still be safely used.
(define (pair x y) (make-pair x y))

; Implementations for the generic functions first, second and eq?
(def-impl ::pair first pair-x)
(def-impl ::pair second pair-y)
(def-impl ::pair eq?
  (lambda (p p1) (and (pair? p1) (eq? (unwrap-pair p) (unwrap-pair p1)))))

; To define a collection, the ->list function must be defined
;   and give predictable output.
;   Defining ->list creates definitions for a bunch of functions.
;   Also, 'collection? returns true for any object which can be 
;   transformed into a list.  However, sequence? has to be defined
;   separately. Only defining ->list is very slow. It is advised
;   to at least define size, first and rest also.
; As for any type you define, it is advisable to also implement eq?.
```

## Info about the files:
- `core.rb` Contains the buildin functions.  
- `docs.rb` Utility file which generates the documentation for all `.lyra` files.  
- `env.rb` Contains the Environment class, which holds all variables for the current and global scope.  
- `evaluate.rb` The actual Lisp interpreter.  
- `lyra.rb` The main file that needs to be fed to the ruby interpreter.  
- `reader.rb` Reads text and turns it into lisp datastructures. (EDN style)  
- `types.rb` Contains the basic types for Lyra. (Lists, Vectors, ...)  
- `core.lyra` The standard library included in every Lyra file.  
- `benchmark.lyra` Benchmarking functions for testing the performance of the newest version.  
- `buildins.lyra` Documentation for the buildin functions from `core.rb`.  
- `set.lyra`, `string.lyra`, `vector.lyra` contain overrides for the generic functions provided in `core.lyra`  
- `tests.lyra` Test cases for most functions, implemented in Lyra.  
- `core/aliases.lyra` and `core/clj.lyra` contain aliases for other functions.  
- `core/random.lyra` contains implementations for some RNG algorithms.  
- `core/sort.lyra` Sorting algorithms.  


## Changelog

- 0.0.1
  - The thing works but lacks functionality.
- 0.0.2
  - Macros, types, more functions, modules, `@` prefix
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
  - Fixed `foldr1`
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
  - Error handling via. `try*-catch` (Usage is heavily discouraged!)
  - char type and char literals (including utf-8 characters)
  - Keyword type
  - Literals for keywords, sets and maps.
  - `loop` macro
  - Better `case-lambda`
  - Alias type
  - queue type (in `core/queue.lyra`)
  - Removed `#()` and `%`
- 0.1.4
  - To define a collection type, only `->list` has to be defined.
  - Names can now end with `'`
  - `true` and `false` are now boolean literals too.
  - `for` macro for list comprehension.
- 0.1.5
  - `#()` and `%n` are back
  - Bugfix in `->rational` for truffleruby
  - Various bugfixes  
  - Reduced set of core functions
  - `\p(...)` as shortcut for partial functions
- 0.1.6
  - Removed "lazy AST spreading"
  - Performance boost
  - Added `quasiquote` and `unquote-splicing`
  - Fixed bug in lazy sequences
  - Removed alias type.
- 0.1.7
  - Added destructuring for function parameters
  - `let` is now a destructuring let and `plet` is the new parallel let
  - `let`, `plet`, `for` and `loop` now all have forms for using Clojure-like vector bindings.
  - Variadic arithmetic
  - Some bugfixes
  - Better module system (though much more work is needed)
  - Simple multithreading + `delay` type
  - Better documentation
- 0.1.8
  - Simpler module system.
  - Any function or variable with a name which does not start with a '%' is public automatically.
  - More functions and macros.
  - Better documentation, again.
- 0.1.9
  - Using more destructuring.
  - Using more quasiquoting and unquoting.
  - Added `interpose`, `printall!`
  - Fixed `partition`
- 0.2.0
  - Better list concatenation algorithm.
  - Threaded `map` function `pmap` (which is currently broken on truffleruby).
  - Now using `splitmix64` as the default RNG algorithm.
- 0.2.1
  - Removed `LazyObj` because it was not used anymore.
  - `cdr coded list`s (lists backed by arrays).
- 0.2.2
  - Added typechecking for the ruby source with rbs.
  - Fixed a bug where `cons` locked if the tail was an inifinite sequence.
- 0.2.3
  - Fixed a bug where the `reline` history would not load.
  - Fixed a bug where `#f` and `Nothing` were interpreted as the empty list in `quasiquote`.
  - Old `lazyseq` with 2 arguments was renamed to `lazy-seq'`. `lazy-seq` is now very similar to `lazy-seq` from clojure.

## Next goals

- Better `macroexpand`.
- Support `:as` in destructuring.
- Support keyword-arguments in `define*` (if that is easy to do).
- Find and fix the worst performance bottlenecks.
- Better error messages.
- Get NeonLyra working on Truffleruby again.

## Known bugs

- Sets and maps only work for atomic types.

## Dancing

I discovered that the shortcuts for some functions can be used in destructuring functions. It can be abused in joke-code, but otherwise has no practical use.

```scm
((lambda' \p(@~a `and)
  (unbox and unquote a partial quasiquote))
 "■)" '(println! ("(⌐" "■ ")) '("ノ♪" "ヾ"))
; ヾ(⌐■ ■)ノ♪
```
After parsing, the code becomes this:
```scm
((lambda' ((partial (unbox (unquote a)) (quasiquote and)))
  (unbox and unquote a partial quasiquote))
 "■)" '(println! ("(⌐" "■ ")) '("ノ♪" "ヾ"))
```
