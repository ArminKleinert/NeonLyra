# Core functions and expressions

```
#     : Number of arguments.
Pure? : Does the function have no sideeffects?
Impl? : Is the function implemented?
Gen?  : Is the function generic?
```

### File: core.rb, evaluate.rb

```
Name                 |  #  |Pure?|Impl?|Gen? | 
---------------------+-----+-----+-----+-----+------------------------------------------------------
define               | >=2 |  x  |  x  |     | Different formats:
                     |     |     |     |     | (define sym val) Sets the value for sym to val in the 
                     |     |     |     |     | module environment. (value-define)
                     |     |     |     |     | (define (sig) & body) Defines a function. (function-define)
def-generic          | 3   |  x  |  x  |     | Defines a generic function. It takes a symbol, function 
                     |     |     |     |     | signature and a fallback function.
def-impl             | 3   |  x  |  x  |     | Defines implementations for generic functions.
def-macro            | >=1 |  x  |  x  |     | Defines a macro. (See readme)
def-type             | >=1 |  x  |  x  |     | Defines a new type. This adds a couple of other functions
                     |     |     |     |     | automatically. (See readme)
lambda               | >=2 |  x  |  x  |     | 
cond                 | >=1 |  x  |  x  |     | 
if                   | 3   |  x  |  x  |     | 
let                  | >=1 |  x  |  x  |     | Sets variables for a scope. References are looked up from
                     |     |     |     |     | the old environment.
let*                 | >=1 |  x  |  x  |     | Sets variables for a scope. Works sequentially.
quote                | 1   |  x  |  x  |     | Return the argument without evaluating it.
recur                | any |  x  |  x  |     | Explicit tail-recursion. Only valid in positions that can
                     |     |     |     |     | trigger implicit tail-recursion.
gensym               | 0   |  x  |  x  |     | 
module               | >=1 |  x  |  x  |     | 
memoize              | 1   |  x  |  x  |     | 
seq                  | 1   |  x  |  x  |     | Returns a equence for all non-empty collections, Nothing
                     |     |     |     |     | otherwise.
                     |     |     |     |     | 
lazy                 | 1   |  x  |  x  |     | 
eager                | 1   |  x  |  x  |     | 
partial              | >=1 |  x  |  x  |     | 
lazy-seq             | 2   |  x  |  x  |     | Creates a lazy sequence. First takes an element, then
                     |     |     |     |     | the generator body:
                     |     |     |     |     |   (define (repeat e) (lazy-seq e (repeat e)))
                     |     |     |     |     | 
nothing              | any |  x  |  x  |     | Swallows any numer of arguments and returns the Nothing.
                     |     |     |     |     | object.
unwrap               | 1   |  x  |  x  |     | 
                     |     |     |     |     | 
box                  | 1   |  x  |  x  |     | Create a box.
unbox                | 1   |  x  |  x  |     | Get the contents of a Box.
set-box!             | 2   |  x  |  x  |     | 
                     |     |     |     |     | 
load!                | 1   |     |  x  |     | Load file. Attention: load! always uses the global
                     |     |     |     |     | environment, not the local one.
read-string          | 1   |  x  |  x  |     | Parses a string into code.
eval!                | 1   |     |  x  |     | Executes an object as code.
                     |     |     |     |     | 
measure!             | 2   |  x  |  x  |     | Takes an integer n and a function f. Executes f n
                     |     |     |     |     | times and returns the median time of the execution in
                     |     |     |     |     | milliseconds.
                     |     |     |     |     | 
=                    | 2   |  x  |  x  |     | 
/=                   | 2   |  x  |  x  |     | 
<                    | 2   |  x  |  x  |     | 
>                    | 2   |  x  |  x  |     | 
<=                   | 2   |  x  |  x  |     | 
>=                   | 2   |  x  |  x  |     | 
                     |     |     |     |     | 
+                    | 2   |  x  |  x  |     | 
-                    | 2   |  x  |  x  |     | 
*                    | 2   |  x  |  x  |     | 
/                    | 2   |  x  |  x  |     | 
rem                  | 2   |  x  |  x  |     | 
                     |     |     |     |     | 
bit-and              | 2   |  x  |  x  |     | 
bit-or               | 2   |  x  |  x  |     | 
bit-xor              | 2   |  x  |  x  |     | 
bit-shl              | 2   |  x  |  x  |     | 
bit-shr              | 2   |  x  |  x  |     | 
                     |     |     |     |     | 
defined?             | 1   |  x  |  x  |     | Checks whether or not a symbol is defined.
nothing?             | 1   |  x  |  x  |     | True for the Nothing object.
null?                | 1   |  x  |  x  |     | True for both Nothing and '().
list?                | 1   |  x  |  x  |     | 
vector?              | 1   |  x  |  x  |     | 
int?                 | 1   |  x  |  x  |     | 
float?               | 1   |  x  |  x  |     | 
string?              | 1   |  x  |  x  |     | 
symbol?              | 1   |  x  |  x  |     | 
char?                | 1   |  x  |  x  |     | 
boolean?             | 1   |  x  |  x  |     | 
map?                 | 1   |  x  |  x  |     | 
set?                 | 1   |  x  |  x  |     | 
                     |     |     |     |     | 
id                   | 1   |  x  |  x  |     | 
id-fn                | 1   |  x  |  x  |     | Creates a function which always returns the object.
hash                 | 1   |  x  |  x  |     | Returns the hash-code for an object
                     |     |     |     |     | (reference for Boxes)
                     |     |     |     |     | 
list-size            | 1   |  x  |  x  |     | 
car                  | 1   |  x  |  x  |     | 
cdr                  | 1   |  x  |  x  |     | 
cons                 | 2   |  x  |  x  |     | 
                     |     |     |     |     | 
vector               | any |  x  |  x  |     | 
vector-size          | 1   |  x  |  x  |     | 
vector-nth           | 2   |  x  |  x  |     | 
vector-add           | 2   |  x  |  x  |     | 
vector-append        | 2   |  x  |  x  |     | 
vector-range         | 3   |  x  |  x  |     | 
vector-includes?     | 2   |  x  |  x  |     | 
vector-eq?           | 2   |  x  |  x  |     | 
                     |     |     |     |     | 
string-size          | 1   |  x  |  x  |     | 
string-nth           | 2   |  x  |  x  |     | 
string-append        | 2   |  x  |  x  |     | 
string-includes?     | 2   |  x  |  x  |     | 
string-eq?           | 2   |  x  |  x  |     | 
                     |     |     |     |     | 
iterate-seq          | 3   |  x  |  x  |     | Iterates a sequence with a function, accumular and the
                     |     |     |     |     | sequence. The function takes 3 arguments: The accumulator,
                     |     |     |     |     | the current element and the current index. Example:
                     |     |     |     |     |   (iterate-seq (lambda (acc e idx) (+ acc e)) 0 sequence)
                     |     |     |     |     | Attention! iterate-seq is optimized for vectors and 
                     |     |     |     |     |   evaluates eagerly!
iterate-seq-p        | 4   |  x  |  x  |     | Similar to iterate-seq, but the first argument is a
                     |     |     |     |     | predicate. When the predicate returns a falsey value, the
                     |     |     |     |     | iteration breaks.
                     |     |     |     |     | Attention! iterate-seq-p is optimized for vectors and 
                     |     |     |     |     |   evaluates eagerly!
                     |     |     |     |     | 
map-of               | any |  x  |  x  |     | 
map-size             | 1   |  x  |  x  |     | 
map-get              | 2   |  x  |  x  |     | 
map-set              | 3   |  x  |  x  |     | 
map-remove           | 2   |  x  |  x  |     | 
map-keys             | 1   |  x  |  x  |     | 
map-merge            | 2   |  x  |  x  |     | 
                     |     |     |     |     | 
set-of               | any |  x  |  x  |     | 
set-size             | 1   |  x  |  x  |     | 
set-add              | 2   |  x  |  x  |     | 
set-union            | 2   |  x  |  x  |     | 
set-difference       | 2   |  x  |  x  |     | 
set-intersection     | 2   |  x  |  x  |     | 
set-includes?        | 2   |  x  |  x  |     | 
set-subset?          | 2   |  x  |  x  |     | 
set-true-subset?     | 2   |  x  |  x  |     | 
set-superset?        | 2   |  x  |  x  |     | 
set-true-superset?   | 2   |  x  |  x  |     | 
                     |     |     |     |     | 
print!               | 1   |     |  x  |     | 
println!             | 1   |     |  x  |     | 
readln!              | 0   |     |  x  |     | 
file-read!           | 1   |     |  x  |     | 
file-write!          | 2   |     |  x  |     | 
file-append!         | 2   |     |  x  |     | 
                     |     |     |     |     | 
is-a?                | 2   |  x  |  x  |     | Checks whether an object is of a certain type.
                     |     |     |     |     | Example: (is-a? x ::integer)
                     |     |     |     |     | 
ljust                | 2   |  x  |  x  |     | Takes a string and a number. The string is then resized to
                     |     |     |     |     | at least n characters by inserting spaces on the right
                     |     |     |     |     | side.
```

### File: core.lyra

```
Name                 |  #  |Pure?|Impl?|Gen? | 
---------------------+-----+-----+-----+-----+------------------------------------------------------
comment              | any |  x  |  x  |     | 
fst                  | 2   |  x  |  x  |     | Take 2 arguments and return the first.
snd                  | 2   |  x  |  x  |     | Take 2 arguments and return the second.
compare              | 2   |  x  |  x  |  x  | Compares 2 variables x and y.
                     |     |     |     |     |   x < y => -1
                     |     |     |     |     |   x = y => 0
                     |     |     |     |     |   x > y => 1
                     |     |     |     |     | 
list                 | any |  x  |  x  |     | Take any number of arguments and return them as a list.
let1                 | 2   |  x  |  x  |     | Sets a single variable.
                     |     |     |     |     | 
size                 | 1   |  x  |  x  |  x  | 
first                | 1   |  x  |  x  |  x  | 
second               | 1   |  x  |  x  |  x  | 
rest                 | 1   |  x  |  x  |  x  | 
foldl                | 3   |  x  |  x  |  x  | 
foldr                | 3   |  x  |  x  |  x  | 
last                 | 1   |  x  |  x  |     | 
but-last             | 1   |  x  |  x  |     | 
empty?               | 1   |  x  |  x  |     | 
append               | 2   |  x  |  x  |  x  | 
contains?            | 2   |  x  |  x  |  x  | 
included?            | 2   |  x  |  x  |     | Reverse of contains?.
nth                  | 2   |  x  |  x  |  x  | 
seq-eq?              | 2   |  x  |  x  |     | Comparison function for lists.
eq?                  | 2   |  x  |  x  |  x  | General comparison function.
                     |     |     |     |     | 
->symbol             | 1   |  x  |  x  |  x  | 
->int                | 1   |  x  |  x  |  x  | 
->float              | 1   |  x  |  x  |  x  | 
->string             | 1   |  x  |  x  |  x  | 
->bool               | 1   |  x  |  x  |  x  | 
->list               | 1   |  x  |  x  |  x  | 
->vector             | 1   |  x  |  x  |  x  | 
->char               | 1   |  x  |  x  |  x  | 
->map                | 1   |  x  |  x  |  x  | 
->set                | 1   |  x  |  x  |  x  | 
                     |     |     |     |     | 
collection?          | 1   |  x  |  x  |  x  | True for lists, vectors, maps and sets, false for others.
sequence?            | 1   |  x  |  x  |  x  | True if the input is a list or vector.
number?              | 1   |  x  |  x  |  x  | 
                     |     |     |     |     | 
symbol               | 1   |  x  |  x  |     | Alias for ->symbol.
not                  | 1   |  x  |  x  |     | 
and                  | 2   |  x  |  x  |     | 
or                   | 2   |  x  |  x  |     | 
odd?                 | 1   |  x  |  x  |     | 
even?                | 1   |  x  |  x  |     | 
                     |     |     |     |     | 
foldl1               | 3   |  x  |  x  |     | 
foldl-indexed        | 3   |  x  |  x  |     | 
foldr1               | 3   |  x  |  x  |     | 
foldr-indexed        | 3   |  x  |  x  |     | 
                     |     |     |     |     | 
compose              | 2   |  x  |  x  |     | Given 2 functions f and g, makes a new function for
                     |     |     |     |     | (f (g x))
compose-and          | 2   |  x  |  x  |     | Given 2 functions f and g, makes a new function for
                     |     |     |     |     | checking (and (f x) (g x))
compose-or           | 2   |  x  |  x  |     | Given 2 functions f and g, makes a new function for
                     |     |     |     |     | checking (or (f x) (g x))
complement           | 1   |  x  |  x  |     | Returns given a function p, returns a function which
                     |     |     |     |     | checks (not (p x)).
                     |     |     |     |     | 
begin                | any |  x  |  x  |     | 
def-memo             | >=1 |  x  |  x  |     | A macro which defines a function and memoizes it.
                     |     |     |     |     | 
spread               | 1   |  x  |  x  |     | Takes a list and expands the last element.
                     |     |     |     |     | (spread '(1 2 (1 2) (7 8))) => (1 2 (1 2) 7 8)
apply                | >=1 |  x  |  x  |     | Takes a function and variadic arguments, calls spread on
                     |     |     |     |     | the arguments and then applies the function.
                     |     |     |     |     | 
map                  | 2   |  x  |  x  |     | Lazy map. Returns a list.
map-eager            | 2   |  x  |  x  |     | Eager map. Returns a list.
mapv                 | 2   |  x  |  x  |     | Eager map. Returns a vector.
map-indexed          | 2   |  x  |  x  |     | 
mapv-indexed         | 2   |  x  |  x  |     | 
map-while            | 3   |  x  |  x  |     | 
map-until            | 3   |  x  |  x  |     | 
maplist              | 2   |  x  |  x  |     | map but for the consecutive sublists. 
                     |     |     |     |     | (maplist size '('a 'b 'c)) => (3 2 1)
mapcar               | >=2 |  x  |  x  |     | Variadic map.
mapcon               | 2   |  x  |  x  |     | Calls maplist, expects the result to be a sequence of 
                     |     |     |     |     | lists and appends them.
mapcat               | 2   |  x  |  x  |     | Calls map, expects the result to be a sequence of lists
                     |     |     |     |     | and appends them.
                     |     |     |     |     | 
filter               | 2   |  x  |  x  |     | Lazy filter. Returns a list.
filterv              | 2   |  x  |  x  |     | Eager filter. Returns a vector.
filter-indexed       | 2   |  x  |  x  |     | 
remove               | 2   |  x  |  x  |     | 
remove-indexed       | 2   |  x  |  x  |     |  
fmap                 | 3   |  x  |  x  |     | filter, then map (like (filter p (map f xs)))
mapf                 | 3   |  x  |  x  |     | map, then filter (like (map f (filter p xs)))
                     |     |     |     |     | 
take-drop            | 2   |  x  |  x  |     | Creates a list equal to
                     |     |     |     |     |   (list (take n xs) (drop n xs))
take-drop-while      | 2   |  x  |  x  |     | Creates a list equal to
                     |     |     |     |     |   (list (take-while p xs) (drop-while p xs))
take-drop-until      | 2   |  x  |  x  |     | Creates a list equal to
                     |     |     |     |     |   (list (take-until p xs) (drop-until p xs))
take                 | 2   |  x  |  x  |     | 
take-while           | 2   |  x  |  x  |     | 
take-until           | 2   |  x  |  x  |     | 
drop                 | 2   |  x  |  x  |     | 
drop-while           | 2   |  x  |  x  |     | 
drop-until           | 2   |  x  |  x  |     | 
                     |     |     |     |     | 
all?                 | 2   |  x  |  x  |     | Checks whether a predicate is true for all elements in a 
                     |     |     |     |     | list.
none?                | 2   |  x  |  x  |     | Checks whether a predicate is true for no element in a 
                     |     |     |     |     | list.
any?                 | 2   |  x  |  x  |     | Checks whether a predicate is true for at least 1 element
                     |     |     |     |     | in a list.
                     |     |     |     |     | 
zip-with             | 3   |  x  |  x  |     | 
zip                  | 2   |  x  |  x  |     | (zip l0 l1) is equal to (zip-with list l0 l1)
                     |     |     |     |     | (zip '(9 8 7) '(1 2 3)) => ((9 1) (8 2) (7 3))
zip-to-index         | 1   |  x  |  x  |     | (zip-to-index '(5 4 3)) => ((0 5) (1 4) (2 3))
v-zip-with           | 2   |  x  |  x  |     | zip-with but takes a sequence of sequences.
                     |     |     |     |     | 
split-by             | 2   |  x  |  x  |     | 
split                | 2   |  x  |  x  |     | Take element and collection, split collection at each
                     |     |     |     |     | occurance of the element.
                     |     |     |     |     | 
repeatedly           | 1   |  x  |  x  |     | 
repeat               | 1   |  x  |  x  |     | Create an infinite sequence of the same element.
iterate              | 2   |  x  |  x  |     | Infinite sequence as in Haskell:
                     |     |     |     |     | iterate f e = e : iterate f (f e)
                     |     |     |     |     | 
va-all?              | >=1 |  x  |  x  |     | Variadic version of all?
va-none?             | >=1 |  x  |  x  |     | Variadic version of none?
va-any?              | >=1 |  x  |  x  |     | Variadic version of any?
                     |     |     |     |     | 
concat               | >=1 |  x  |  x  |     | Appends collections.
string-concat        | >=1 |  x  |  x  |     | Appends strings.
                     |     |     |     |     | 
v+                   | >=1 |  x  |  x  |     | Variadic +
v-                   | >=1 |  x  |  x  |     | Variadic - (if only 1 argument is given, it is negated)
v*                   | >=1 |  x  |  x  |     | Variadic *
v/                   | >=1 |  x  |  x  |     | Variadic /
v%                   | >=1 |  x  |  x  |     | Variadic rem
                     |     |     |     |     | 
divmod               | 2   |  x  |  x  |     | (divmod x y) => (list (/ x y) (rem x y))
                     |     |     |     |     | 
constantly           | 2   |  x  |  x  |     | Fills a list with a given element.
                     |     |     |     |     | (constantly 9 '(1 2 3)) => (9 9 9)
                     |     |     |     |     | 
reverse              | 1   |  x  |  x  |     | Reverse a list.
sum                  | 1   |  x  |  x  |     | Sums the elements of a list. (0 if the list is empty)
product              | 1   |  x  |  x  |     | Calculate the product of a list. (1 if empty)
                     |     |     |     |     | 
inc                  | 1   |  x  |  x  |     | Increases a number by 1.
dec                  | 1   |  x  |  x  |     | Decreases a number by 1.
min                  | 2   |  x  |  x  |     | Get minimum of 2 objects.
max                  | 2   |  x  |  x  |     | Get maximum of 2 objects.
minimum              | 1   |  x  |  x  |     | Get minimum of a list.
maximum              | 1   |  x  |  x  |     | Get maximum of a list.
                     |     |     |     |     | 
range                | 2   |  x  |  x  |     | 
indices-of           | 2   |  x  |  x  |     | 
                     |     |     |     |     | 
λ                    | >=2 |  x  |  x  |     | A fun macro which transforms into a lambda-form:
                     |     |     |     |     | (λ x y . (+ x y)) becomes (lambda (x y) (+ x y))
fact-seq             |     |     |     |     | An infinite list of the factorial numbers.
                     |     |     |     |     | 
->                   | >=1 |  x  |  x  |     | As in Clojure.
->>                  | >=1 |  x  |  x  |     | As in Clojure.
as->                 | >=2 |  x  |  x  |     | As in Clojure.
                     |     |     |     |     | 
case                 | >=1 |  x  |  x  |     | Similar to switch case.
                     |     |     |     |     | Syntax: (case e c0 r0 c1 r1 ... cn rn default)
                     |     |     |     |     | (case 1) ;=> Nothing
                     |     |     |     |     | (case 1 #f) ;=> #f
                     |     |     |     |     | (case 1 1 #t #f) ;=> #t ; Normal matching.
                     |     |     |     |     | (case 1 '(1) #t #f) ;=> #t ; membership in collections is tested too.
                     |     |     |     |     | (case 1 (partial = 1) #t #f) ;=> #t ; Functions for matching.
```

### File: core/aliases.lyra

```
Name                 |  #  |Pure?|Impl?|Gen? | 
---------------------+-----+-----+-----+-----+------------------------------------------------------
includes?            | 2   |  x  |  x  |     | Alias for contains?.
require!             | 1   |     |  x  |     | Alias for load!
fold                 | 3   |  x  |  x  |     | Alias for foldr.
member?              | 2   |  x  |  x  |     | Alias for included?.
~                    | 1   |  x  |  x  |     | Alias for complement.
⋅                    | 2   |  x  |  x  |     | Alias for compose.
∀                    | 2   |  x  |  x  |     | Alias for all?.
∃                    | 2   |  x  |  x  |     | Alias for any?.
∄                    | 2   |  x  |  x  |     | Alias for none?.
≠                    | 2   |  x  |  x  |     | Alias for /=
≤                    | 2   |  x  |  x  |     | Alias for >=
≥                    | 2   |  x  |  x  |     | Alias for <=
∈                    | 2   |  x  |  x  |     | Alias for included?.
∉                    | 2   |  x  |  x  |     | Alias for the complement of included?.
<=>                  | 2   |  x  |  x  |     | Alias for compare.
```

### File: core/clj.lyra

```
Name                 |  #  |Pure?|Impl?|Gen? | 
---------------------+-----+-----+-----+-----+------------------------------------------------------
when                 | >=1 |  x  |  x  |     | (when p ...) => (if p (begin ...) Nothing)
def                  | 2   |  x  |  x  |     | Alias for value-define.
defn                 | 2   |  x  |  x  |     | Alias for function-define, but parameters are given
                     |     |     |     |     | as a vector.
fn                   | >=1 |  x  |  x  |     | Alias for lambda, but bindings are given as a vector.
do                   | any |  x  |  x  |     | Alias for begin.
slurp!               | 1   |     |  x  |     | Alias for file-read!
spit!                | 2   |     |  x  |     | Alias for file-write!
count                | 1   |  x  |  x  |     | Alias for size.
reduce               | 3   |  x  |  x  |     | Alias for foldl.
```

### File: core/random.lyra

```
Name                 |  #  |Pure?|Impl?|Gen? | 
---------------------+-----+-----+-----+-----+------------------------------------------------------
random               | 1   |  x  |  x  |     | Takes a seed and generates a random number based on
                     |     |     |     |     | it. (64 bits)
random!              | 0   |     |  x  |     | Generates a random number and sets an invisible 
                     |     |     |     |     | global seed. (64 bits)
xorshift64s          | 1   |  x  |  x  |     | Take a seed and call xorshift64* on it. (64 bits)
xorshift64           | 1   |  x  |  x  |     | Take a seed and call xorshift64 om it. (64 bits)
xorshift32           | 1   |  x  |  x  |     | Take a seed and call xorshift32 on it. (32 bits)
lfsr                 | 1   |  x  |  x  |     | Take a seed and call a simple lfsr on it. (32 bits)
xorshift64s-seq      | 1   |  x  |  x  |     | Using a seed, generate an infinite sequence using 
                     |     |     |     |     | xorshift64s.
xorshift64-seq       | 1   |  x  |  x  |     | Using a seed, generate an infinite sequence using 
                     |     |     |     |     | xorshift64.
xorshift32-seq       | 1   |  x  |  x  |     | Using a seed, generate an infinite sequence using 
                     |     |     |     |     | xorshift32.
lfsr-seq             | 1   |  x  |  x  |     | Using a seed, generate an infinite sequence using 
                     |     |     |     |     | lfsr (32 bits).
random-nums          | 1   |  x  |  x  |     | Using a seed, generate an infinite sequence of 
                     |     |     |     |     | random numbers.
with-bounds          | 3   |  x  |  x  |     | Take a sequence of numbers, a minimum and a maximum. 
                     |     |     |     |     | Then every number in the sequence is lazily adjusted
                     |     |     |     |     | to be betweeen the minimum and maximum.
shuffle              | 2   |  x  |  x  |     | Takes a sequence and a seed. Random numbers are 
                     |     |     |     |     | generated based on the seed and used to shuffle the
                     |     |     |     |     | sequence.
```

### File: core/sort.lyra

```
Name                 |  #  |Pure?|Impl?|Gen? | 
---------------------+-----+-----+-----+-----+------------------------------------------------------
sort                 | 1   |  x  |  x  |     | Sort a list.
sort-compare         | 2   |  x  |  x  |     | Like sort, but uses a comparator (see compare).
bubblesort           | 1   |  x  |  x  |     | Sort a list using bubblesort.
mergesort            | 1   |  x  |  x  |     | Sort a list using mergesort.
mergesort-compare    | 2   |  x  |  x  |     | Like mergesort, but the first parameter is a 
                     |     |     |     |     | comparator.
```

### File: core/infix.lyra

```
Name                 |  #  |Pure?|Impl?|Gen? | 
---------------------+-----+-----+-----+-----+------------------------------------------------------
infix->prefix        | >=2 |  x  |  x  |     | Convert an infix expression into prefix notation and
                     |     |     |     |     | call it as lyra code.
                     |     |     |     |     | The first parameter is a map with 4 entries: 
                     |     |     |     |     | 'associativity-of Take a symbol and return either 
                     |     |     |     |     | 'left or 'right.
                     |     |     |     |     | 'precedence-of Take a symbol and return the fitting 
                     |     |     |     |     | precedence.
                     |     |     |     |     | 'unary-op? Take a symbol and return true if it is a 
                     |     |     |     |     | unary operator.
                     |     |     |     |     | 'bin-op? Take a symbol and return true if it is a 
                     |     |     |     |     | binary operator.
infix->lyra          | >=1 |  x  |  x  |     | Take an infix expression, convert it to lyra code and 
                     |     |     |     |     | execute. Uses the aliases defined in aliases.lyra
§                    | >=1 |  x  |  x  |     | Alias for infix->lyra
show-infix-as-prefix | >=2 |  x  |  x  |     | Similar to infix->prefix but does not execute the 
                     |     |     |     |     | code.
```

## Variables

```
Name        | File              | 
------------+-------------------+-------------------------------------------------------------------
#t          | core.rb           | Boolean true
#f          | core.rb           | Boolean false
else        | core.lyra         | alias for #t (for use in cond expressions)
Nothing     | core.rb           | The non-object
::nothing   | core.rb           | Type name for the Nothing object.
::bool      | core.rb           | Type name for #t and #f.
::vector    | core.rb           | Type name for vectors.
::map       | core.rb           | Type name for maps.
::list      | core.rb           | Type name for lists.
::function  | core.rb           | Type name for functions.
::integer   | core.rb           | Type name for integers.
::float     | core.rb           | Type name for floats.
::set       | core.rb           | Type name for sets.
::typename  | core.rb           | Type name for typename objects.
::string    | core.rb           | Type name for strings.
::symbol    | core.rb           | Type name for symbols.
::box       | core.rb           | Type name for boxes.
true        | core/clj.lyra     | #t
false       | core/clj.lyra     | #f
nil         | core/clj.lyra     | Nothing
```
