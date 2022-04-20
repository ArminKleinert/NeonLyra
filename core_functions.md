# Core functions and expressions

```
#     : Number of arguments.
Pure? : Does the function have no sideeffects?
Impl? : Is the function implemented?
Gen?  : Is the function generic?
```

### File: core.rb, evaluate.rb

```
Name                 |  #  |Pure?|Gen? | 
---------------------+-----+-----+-----+------------------------------------------------------------
define               | >=2 |  x  |     | Different formats:
                     |     |     |     | (define sym val) Sets the value for sym to val in the 
                     |     |     |     | module environment. (value-define)
                     |     |     |     | (define (sig) & body) Defines a function. (function-define)
def-generic          | 3   |  x  |     | Defines a generic function. It takes a symbol, function 
                     |     |     |     | signature and a fallback function.
def-impl             | 3   |  x  |     | Defines implementations for generic functions.
def-macro            | >=1 |  x  |     | Defines a macro. (See readme)
def-type             | >=1 |  x  |     | Defines a new type. This adds a couple of other functions
                     |     |     |     | automatically. (See readme)
lambda*              | >=3 |  x  |     | Creates a function with a name. The name is bound
                     |     |     |     | inside the function, but not outside of it.
lambda               | >=2 |  x  |     | Creates an anonymous function.
cond                 | >=1 |  x  |     | 
if                   | 3   |  x  |     | 
let                  | >=1 |  x  |     | Sets variables for a scope. References are looked up from
                     |     |     |     | the old environment.
let*                 | >=1 |  x  |     | Sets variables for a scope. Works sequentially.
quote                | 1   |  x  |     | Return the argument without evaluating it.
recur                | any |  x  |     | Explicit tail-recursion. Only valid in positions that can
                     |     |     |     | trigger implicit tail-recursion.
                     |     |     |     | 
try*                 | 2   |  x  |     | Try to execute something and capture a potential error 
                     |     |     |     | in the second form.
catch                | >=2 |  x  |     | Part of try* and only valid inside it. The first argument
                     |     |     |     | is a name for the error, the second is a validation
                     |     |     |     | function and the rest are what happens to the error.
                     |     |     |     | (try* <error> (catch (lambda (x) #t) e 'saved)
                     |     |     |     | (try* <error> (catch (lambda (x) #f) e ..) ; Fails
                     |     |     |     | 
alias                | 1   |  x  |     | Creates an Alias object.
                     |     |     |     | 
gensym               | 0-1 |  x  |     | 
module               | >=1 |  x  |     | 
memoize              | 1   |  x  |     | 
seq                  | 1   |  x  |     | Returns a equence for all non-empty collections, Nothing
                     |     |     |     | otherwise.
                     |     |     |     | 
lazy                 | 1   |  x  |     | 
eager                | 1   |  x  |     | 
partial              | >=1 |  x  |     | 
lazy-seq             | 2   |  x  |     | Creates a lazy sequence. First takes an element, then
                     |     |     |     | the generator body:
                     |     |     |     |   (define (repeat e) (lazy-seq e (repeat e)))
                     |     |     |     | 
nothing              | any |  x  |     | Swallows any numer of arguments and returns the Nothing
                     |     |     |     | object.
unwrap               | 1   |  x  |  x  | Gets the value of a Box, Alias or gets the value-vector of
                     |     |     |     | a user-defined type object.
                     |     |     |     | 
box                  | 1   |  x  |     | Create a box.
unbox                | 1   |  x  |     | Get the contents of a Box.
set-box!             | 2   |  x  |     | 
                     |     |     |     | 
load!                | >=1 |     |     | Load files. Attention: load! always uses the global
                     |     |     |     | environment, not the local one.
                     |     |     |     |   (load! "core/random.lyra" "tests.lyra")
read-string          | 1   |  x  |     | Parses a string into code.
eval!                | 1   |     |     | Executes an object as code.
                     |     |     |     | 
measure!             | 2   |  x  |     | Takes an integer n and a function f. Executes f n
                     |     |     |     | times and returns the median time of the execution in
                     |     |     |     | milliseconds.
                     |     |     |     | 
=                    | 2   |  x  |     | Equality function for atoms. Compares references for
                     |     |     |     | non-atoms.
/=                   | 2   |  x  |     | 
<                    | 2   |  x  |     | Comparison for atoms. Undefined for non-atoms.
>                    | 2   |  x  |     | Comparison for atoms. Undefined for non-atoms.
<=                   | 2   |  x  |     | Comparison for atoms. Undefined for non-atoms.
>=                   | 2   |  x  |     | Comparison for atoms. Undefined for non-atoms.
                     |     |     |     | 
+                    | 2   |  x  |     | Addition for atoms. Nothing for non-atoms.
-                    | 2   |  x  |     | Subtraction for atoms. Nothing for non-atoms.
*                    | 2   |  x  |     | Multiply for atoms. Nothing for non-atoms.
/                    | 2   |  x  |     | Division for atoms. Nothing for non-atoms.
rem                  | 2   |  x  |     | Modulo for atoms. Nothing for non-atoms.
                     |     |     |     | 
bit-and              | 2   |  x  |     | Bitwise-and for ints. Nothing for other types.
bit-or               | 2   |  x  |     | Bitwise-or for ints. Nothing for other types.
bit-xor              | 2   |  x  |     | Bitwise-xor for ints. Nothing for other types.
bit-shl              | 2   |  x  |     | Bitwise-shift-left for ints. Nothing for other types.
bit-shr              | 2   |  x  |     | Bitwise-shift-right for ints. Nothing for other types.
                     |     |     |     | 
defined?             | 1   |  x  |     | Checks whether or not a symbol is defined.
nothing?             | 1   |  x  |     | True for the Nothing object.
null?                | 1   |  x  |     | True for both Nothing and '().
list?                | 1   |  x  |     | 
vector?              | 1   |  x  |     | 
int?                 | 1   |  x  |     | 
float?               | 1   |  x  |     | 
string?              | 1   |  x  |     | 
symbol?              | 1   |  x  |     | 
char?                | 1   |  x  |     | 
boolean?             | 1   |  x  |     | 
map?                 | 1   |  x  |     | 
set?                 | 1   |  x  |     | 
                     |     |     |     | 
id                   | 1   |  x  |     | Returns the argument.
id-fn                | 1   |  x  |     | Creates a function which always returns the object.
hash                 | 1   |  x  |     | Returns the hash-code for an object
                     |     |     |     | (reference for Boxes)
                     |     |     |     | 
list-size            | 1   |  x  |     | 
car                  | 1   |  x  |     | 
cdr                  | 1   |  x  |     | 
cons                 | 2   |  x  |     | 
                     |     |     |     | 
vector               | any |  x  |     | 
vector-size          | 1   |  x  |     | 
vector-nth           | 2   |  x  |     | 
vector-add           | 2   |  x  |     | 
vector-append        | 2   |  x  |     | 
vector-range         | 3   |  x  |     | 
vector-includes?     | 2   |  x  |     | 
vector-eq?           | 2   |  x  |     | 
                     |     |     |     | 
string-size          | 1   |  x  |     | 
string-nth           | 2   |  x  |     | 
string-append        | 2   |  x  |     | 
string-includes?     | 2   |  x  |     | 
string-eq?           | 2   |  x  |     | 
                     |     |     |     | 
iterate-seq          | 3   |  x  |     | Iterates a sequence with a function, accumular and the
                     |     |     |     | sequence. The function takes 3 arguments: The accumulator,
                     |     |     |     | the current element and the current index. Example:
                     |     |     |     |   (iterate-seq (lambda (acc e idx) (+ acc e)) 0 sequence)
                     |     |     |     | Attention! iterate-seq is optimized for vectors and 
                     |     |     |     |   evaluates eagerly!
iterate-seq-p        | 4   |  x  |     | Similar to iterate-seq, but the first argument is a
                     |     |     |     | predicate. When the predicate returns a falsey value, the
                     |     |     |     | iteration breaks.
                     |     |     |     | Attention! iterate-seq-p is optimized for vectors and 
                     |     |     |     |   evaluates eagerly!
                     |     |     |     | 
map-of               | any |  x  |     | 
map-size             | 1   |  x  |     | 
map-get              | 2   |  x  |     | 
map-set              | 3   |  x  |     | 
map-remove           | 2   |  x  |     | 
map-keys             | 1   |  x  |     | 
map-merge            | 2   |  x  |     | 
                     |     |     |     | 
set-of               | any |  x  |     | 
set-size             | 1   |  x  |     | 
set-add              | 2   |  x  |     | 
set-union            | 2   |  x  |     | 
set-difference       | 2   |  x  |     | 
set-intersection     | 2   |  x  |     | 
set-includes?        | 2   |  x  |     | 
set-subset?          | 2   |  x  |     | 
set-true-subset?     | 2   |  x  |     | 
set-superset?        | 2   |  x  |     | 
set-true-superset?   | 2   |  x  |     | 
                     |     |     |     | 
print!               | 1   |     |     | 
println!             | 1   |     |     | 
readln!              | 0   |     |     | 
file-read!           | 1   |     |     | 
file-write!          | 2   |     |     | 
file-append!         | 2   |     |     | 
                     |     |     |     | 
is-a?                | 2   |  x  |     | Checks whether an object is of a certain type.
                     |     |     |     | Example: (is-a? x ::integer)
                     |     |     |     | 
ljust                | 2   |  x  |     | Takes a string and a number. The string is then resized to
                     |     |     |     | at least n characters by inserting spaces on the right
                     |     |     |     | side.
```

### File: core.lyra

```
Name                 |  #  |Pure?|Gen? | 
---------------------+-----+-----+-----+------------------------------------------------------------
T                    | any |  x  |     | Takes any number of arguments and return #t.
comment              | any |  x  |     | Takes any number of arguments without evaluating them
                     |     |     |     | and returns Nothing.
flip                 | 1   |  x  |     | Takes a function which takes 2 arguments and returns 
                     |     |     |     | a new function which takes the same arguments reversed.
fst                  | 2   |  x  |     | Take 2 arguments and return the first.
snd                  | 2   |  x  |     | Take 2 arguments and return the second.
compare              | 2   |  x  |  x  | Compares 2 variables x and y.
                     |     |     |     |   x < y => -1
                     |     |     |     |   x = y => 0
                     |     |     |     |   x > y => 1
                     |     |     |     | 
list                 | any |  x  |     | Take any number of arguments and return them as a list.
let1                 | 2   |  x  |     | Sets a single variable.
defmacro             | >=1 |  x  |     | Alias for def-macro.
                     |     |     |     | 
size                 | 1   |  x  |  x  | Get the size of a collection. 
first                | 1   |  x  |  x  | Get the first element of a collection.
second               | 1   |  x  |  x  | Get the second element of a collection.
                     |     |     |     | By default: (first (rest xs))
rest                 | 1   |  x  |  x  | Get all but the first element of a collection.
foldl                | 3   |  x  |  x  | Typical foldl.
foldr                | 3   |  x  |  x  | Typical foldr.
last                 | 1   |  x  |     | Get the last element of a collection.
but-last             | 1   |  x  |     | Get all but the last element of a collection.
empty?               | 1   |  x  |     | Check whether a collection is empty. #f by default.
append               | 2   |  x  |  x  | Append 2 collections.
add                  | 2   |  x  |  x  | Add a single element to a collection.
contains?            | 2   |  x  |  x  | 
included?            | 2   |  x  |     | Reverse of contains?.
nth                  | 2   |  x  |  x  | 
seq-eq?              | 2   |  x  |     | Comparison function for lists.
eq?                  | 2   |  x  |  x  | General comparison function. Predefined as = for
                     |     |     |     | non-collections. Same behavior as seq-eq? for collections.
                     |     |     |     | 
->symbol             | 1   |  x  |  x  | 
->int                | 1   |  x  |  x  | 
->float              | 1   |  x  |  x  | 
->string             | 1   |  x  |  x  | 
->bool               | 1   |  x  |  x  | 
->list               | 1   |  x  |  x  | 
->vector             | 1   |  x  |  x  | 
->char               | 1   |  x  |  x  | 
->map                | 1   |  x  |  x  | 
->set                | 1   |  x  |  x  | 
                     |     |     |     | 
collection?          | 1   |  x  |  x  | True for lists, vectors, maps and sets, false for others.
sequence?            | 1   |  x  |  x  | True if the input is a list or vector.
number?              | 1   |  x  |  x  | 
                     |     |     |     | 
symbol               | 1   |  x  |     | Alias for ->symbol.
not                  | 1   |  x  |     | 
and                  | 2   |  x  |     | 
or                   | 2   |  x  |     | 
odd?                 | 1   |  x  |     | 
even?                | 1   |  x  |     | 
                     |     |     |     | 
foldl1               | 2   |  x  |     | 
foldl-indexed        | 3   |  x  |     | 
foldr1               | 2   |  x  |     | 
foldr-indexed        | 3   |  x  |     | 
                     |     |     |     | 
scanl                | 3   |  x  |     | As in Haskell.
scanl1               | 2   |  x  |     | As in Haskell.
scanr                | 3   |  x  |     | As in Haskell.
scanr1               | 2   |  x  |     | As in Haskell.
                     |     |     |     | 
compose              | 2   |  x  |     | Given 2 functions f and g, makes a new function for
                     |     |     |     | (f (g x))
compose2             | 2   |  x  |     | Given 2 functions f and g, makes a new function for
                     |     |     |     | (f (g x y))
compose-and          | 2   |  x  |     | Given 2 functions f and g, makes a new function for
                     |     |     |     | checking (and (f x) (g x))
compose-or           | 2   |  x  |     | Given 2 functions f and g, makes a new function for
                     |     |     |     | checking (or (f x) (g x))
complement           | 1   |  x  |     | Returns given a function p, returns a function which
                     |     |     |     | checks (not (p x)).
                     |     |     |     | 
begin                | any |  x  |     | 
def-memo             | >=1 |  x  |     | A macro which defines a function and memoizes it.
                     |     |     |     | 
spread               | 1   |  x  |     | Takes a list and expands the last element.
                     |     |     |     | (spread '(1 2 (1 2) (7 8))) => (1 2 (1 2) 7 8)
apply                | >=1 |  x  |     | Takes a function and variadic arguments, calls spread on
                     |     |     |     | the arguments and then applies the function.
                     |     |     |     | 
map                  | 2   |  x  |     | Lazy map. Returns a list.
map-eager            | 2   |  x  |     | Eager map. Returns a list.
mapv                 | 2   |  x  |     | Eager map. Returns a vector.
map-indexed          | 2   |  x  |     | 
mapv-indexed         | 2   |  x  |     | 
map-while            | 3   |  x  |     | 
map-until            | 3   |  x  |     | 
maplist              | 2   |  x  |     | map but for the consecutive sublists. 
                     |     |     |     | (maplist size '('a 'b 'c)) => (3 2 1)
mapcar               | >=2 |  x  |     | Variadic map.
mapcon               | 2   |  x  |     | Calls maplist, expects the result to be a sequence of 
                     |     |     |     | lists and appends them.
mapcat               | 2   |  x  |     | Calls map, expects the result to be a sequence of lists
                     |     |     |     | and appends them.
                     |     |     |     | 
juxt                 | >=1 |  x  |     | (juxt f0 f1..) is the same as
                     |     |     |     |    (lambda (x) (list (f0 x) (f1 x) ..))
                     |     |     |     | Eg. ((juxt dec id inc) 1) ;=> (0 1 2)
                     |     |     |     | 
filter               | 2   |  x  |     | Lazy filter. Returns a list.
filterv              | 2   |  x  |     | Eager filter. Returns a vector.
filter-indexed       | 2   |  x  |     | 
remove               | 2   |  x  |     | 
remove-indexed       | 2   |  x  |     |  
                     |     |     |     | 
every-pred           | >=1 |  x  |     | Takes any number of predicate functions and returns a new 
                     |     |     |     | function which checks if all those predicates are true on
                     |     |     |     | a given element.
                     |     |     |     | 
fmap                 | 3   |  x  |     | filter, then map (like (filter p (map f xs)))
mapf                 | 3   |  x  |     | map, then filter (like (map f (filter p xs)))
                     |     |     |     | 
take-drop            | 2   |  x  |     | Creates a list equal to
                     |     |     |     |   (list (take n xs) (drop n xs))
take-drop-while      | 2   |  x  |     | Creates a list equal to
                     |     |     |     |   (list (take-while p xs) (drop-while p xs))
take-drop-until      | 2   |  x  |     | Creates a list equal to
                     |     |     |     |   (list (take-until p xs) (drop-until p xs))
take                 | 2   |  x  |     | 
take-while           | 2   |  x  |     | 
take-until           | 2   |  x  |     | 
drop                 | 2   |  x  |     | 
drop-while           | 2   |  x  |     | 
drop-until           | 2   |  x  |     | 
                     |     |     |     | 
all?                 | 2   |  x  |     | Checks whether a predicate is true for all elements in a 
                     |     |     |     | list.
none?                | 2   |  x  |     | Checks whether a predicate is true for no element in a 
                     |     |     |     | list.
any?                 | 2   |  x  |     | Checks whether a predicate is true for at least 1 element
                     |     |     |     | in a list.
                     |     |     |     | 
zip-with             | 3   |  x  |     | 
zip                  | 2   |  x  |     | (zip l0 l1) is equal to (zip-with list l0 l1)
                     |     |     |     | (zip '(9 8 7) '(1 2 3)) => ((9 1) (8 2) (7 3))
zip-to-index         | 1   |  x  |     | (zip-to-index '(5 4 3)) => ((0 5) (1 4) (2 3))
v-zip-with           | 2   |  x  |     | zip-with but takes a sequence of sequences.
                     |     |     |     | 
split-by             | 2   |  x  |     | 
split                | 2   |  x  |     | Take element and collection, split collection at each
                     |     |     |     | occurance of the element.
                     |     |     |     | 
repeatedly           | 1   |  x  |     | 
repeat               | 1   |  x  |     | Create an infinite sequence of the same element.
iterate              | 2   |  x  |     | Infinite sequence as in Haskell:
                     |     |     |     | iterate f e = e : iterate f (f e)
                     |     |     |     | 
va-all?              | >=1 |  x  |     | Variadic version of all?
va-none?             | >=1 |  x  |     | Variadic version of none?
va-any?              | >=1 |  x  |     | Variadic version of any?
                     |     |     |     | 
concat               | >=1 |  x  |     | Appends collections.
string-concat        | >=1 |  x  |     | Appends strings.
                     |     |     |     | 
v+                   | >=1 |  x  |     | Variadic +
v-                   | >=1 |  x  |     | Variadic - (if only 1 argument is given, it is negated)
v*                   | >=1 |  x  |     | Variadic *
v/                   | >=1 |  x  |     | Variadic /
v%                   | >=1 |  x  |     | Variadic rem
                     |     |     |     | 
divmod               | 2   |  x  |     | (divmod x y) => (list (/ x y) (rem x y))
                     |     |     |     | 
constantly           | 1   |  x  |     | Takes an element x and returns a new function which, for any given input, returns x.
const                | 1   |  x  |     | Alias for constantly
                     |     |     |     | 
reverse              | 1   |  x  |     | Reverse a list.
sum                  | 1   |  x  |     | Sums the elements of a list. (0 if the list is empty)
product              | 1   |  x  |     | Calculate the product of a list. (1 if empty)
                     |     |     |     | 
inc                  | 1   |  x  |     | Increases a number by 1.
dec                  | 1   |  x  |     | Decreases a number by 1.
min                  | 2   |  x  |     | Get minimum of 2 objects.
max                  | 2   |  x  |     | Get maximum of 2 objects.
minimum              | 1   |  x  |     | Get minimum of a list.
maximum              | 1   |  x  |     | Get maximum of a list.
                     |     |     |     | 
range                | 2   |  x  |     | 
indices-of           | 2   |  x  |     | 
                     |     |     |     | 
λ                    | >=2 |  x  |     | A fun macro which transforms into a lambda-form:
                     |     |     |     | (λ x y . (+ x y)) becomes (lambda (x y) (+ x y))
fact-seq             |     |     |     | An infinite list of the factorial numbers.
                     |     |     |     | 
->                   | >=1 |  x  |     | As in Clojure.
->>                  | >=1 |  x  |     | As in Clojure.
as->                 | >=2 |  x  |     | As in Clojure.
                     |     |     |     | 
case                 | >=1 |  x  |     | Similar to switch case.
                     |     |     |     | Syntax: (case e c0 r0 c1 r1 ... cn rn default)
                     |     |     |     | (case 1) ;=> Nothing
                     |     |     |     | (case 1 #f) ;=> #f ; Default
                     |     |     |     | (case 1 1 #t #f) ;=> #t ; Normal matching.
                     |     |     |     | (case 1 '(1) #t #f) ;=> #t ; membership in collections.
                     |     |     |     | (case 1 (partial = 1) #t #f) ;=> #t 
                     |     |     |     | ; Function for matching.
case-lambda          | >=0 |  x  |     | Creates a lambda which can accept different numbers
                     |     |     |     | of arguments.
                     |     |     |     | (let ((l (case-lambda ((x)x) ((x y)y) (xs(car xs)))))
                     |     |     |     |   (list (l 9) (l 0 1) (l 2 3 4))) ;=> (9 1 2)
case-lambda*         | >=1 |  x  |     | case-lambda but takes a name too.
try                  | >=2 |  x  |     | Like try*, but can have multiple expressions in the body, 
                     |     |     |     | multiple catch-clauses and a finally-clause at the end.
condp                | >=3 |  x  |     | As in Clojure.
                     |     |     |     | 
frequencies          | >=3 |  x  |     | As in Clojure.
unique               | 1   |  x  |     | Removes duplicates from a sequence but retains order.
unique?              | 1   |  x  |     | Checks whether a sequence is unique.
tuples               | 2   |  x  |     | (tuples 3 '(1 2 3 4 5)) ;=> ((1 2 3) (2 3 4) (3 4 5))
slices               | 3   |  x  |     | (slices 3 '(1 2 3 4 5 6)) ;=> ((1 2 3) (4 5 6))
loop                 | >=1 |  x  |     | 
defmacro             | >=1 |  x  |     | Alias for def-macro
into                 | 2   |  x  |     | Appends all elements of the second argument to the first,
                     |     |     |     | keeping the type of the first.
partition            | 1-2 |  x  |     | Extended version of both slices and tuples, as in Clojure.
dedupe               | 1   |  x  |     | Returns a lazy sequence removing consecutive duplicates in
                     |     |     |     | coll.
                     |     |     |     |
combinations         | Any |  x  |     | Returns a lazy sequence of ordered combinations of any
                     |     |     |     | number of lists.
                     |     |     |     | (combinations [1 2] [3 4]) ;=> ((1 3) (1 4) (2 3) (2 4))
for                  | 2   |  x  |     | List comprehension. Similar to Clojure.
                     |     |     |     | Also supports :let and :while.
                     |     |  x  |     | (for ((x [1 2]) (y [3 4]) (:let ((z (+ x y))))) [x y z])
                     |     |     |     |   ; => ([1 3 4] [1 4 5] [2 3 5] [2 4 6])
```

### File: core/aliases.lyra

```
Name                 |  #  |Pure?|Gen? | 
---------------------+-----+-----+-----+------------------------------------------------------------
includes?            | 2   |  x  |     | Alias for contains?.
require!             | 1   |     |     | Alias for load!
fold                 | 3   |  x  |     | Alias for foldr.
member?              | 2   |  x  |     | Alias for included?.
~                    | 1   |  x  |     | Alias for complement.
⋅                    | 2   |  x  |     | Alias for compose.
∀                    | 2   |  x  |     | Alias for all?.
∃                    | 2   |  x  |     | Alias for any?.
∄                    | 2   |  x  |     | Alias for none?.
≠                    | 2   |  x  |     | Alias for /=.
≤                    | 2   |  x  |     | Alias for >=.
≥                    | 2   |  x  |     | Alias for <=.
∈                    | 2   |  x  |     | Alias for included?.
∉                    | 2   |  x  |     | Alias for the complement of included?.
<=>                  | 2   |  x  |  x  | Alias for compare.
++                   | 2   |  x  |  x  | Alias for append.
```

### File: core/clj.lyra

```
Name                 |  #  |Pure?|Gen? | 
---------------------+-----+-----+-----+------------------------------------------------------------
when                 | >=1 |  x  |     | (when p ...) => (if p (begin ...) Nothing)
def                  | 2   |  x  |     | Alias for value-define.
defn                 | 2   |  x  |     | Alias for value-define with the value being a fn.
fn                   | >=1 |  x  |     | Alias for lambda, lambda*, case-lambda or case-lambda*,
                     |     |     |     | depending on the exact syntax. For more info, see 
                     |     |     |     | https://clojuredocs.org/clojure.core/fn
do                   | any |  x  |     | Alias for begin.
slurp!               | 1   |     |     | Alias for file-read!.
spit!                | 2   |     |     | Alias for file-write!.
count                | 1   |  x  |     | Alias for size.
reduce               | 2-3 |  x  |     | Alias for foldl and foldl1.
reductions           | 2-3 |  x  |     | Alias for scanl and scanl1.
nthrest              | 2   |  x  |     | Alias for drop but the arguments are reversed.
nthnext              | 2   |  x  |     | Like nthrest but returns Nothing if the rest is empty.
next                 | 1   |  x  |     | Like rest but returns Nothing if the rest is empty.
ffirst               | 1   |  x  |     | Same as (first (first ..))
fnext                | 1   |  x  |     | Same as (first (next ..))
nnext                | 1   |  x  |     | Same as (next (next ..))
nfirst               | 1   |  x  |     | Same as (next (first ..))
enumerate            | 1   |  x  |     | Alias for zip-to-index.
conj                 | 2   |  x  |  x  | Alias for add.
```

### File: core/random.lyra

```
Name                 |  #  |Pure?|Gen? | 
---------------------+-----+-----+-----+------------------------------------------------------------
random               | 1   |  x  |     | Takes a seed and generates a random number based on
                     |     |     |     | it. (64 bits)
random!              | 0   |     |     | Generates a random number and sets an invisible 
                     |     |     |     | global seed. (64 bits)
xorshift64s          | 1   |  x  |     | Take a seed and call xorshift64* on it. (64 bits)
xorshift64           | 1   |  x  |     | Take a seed and call xorshift64 om it. (64 bits)
xorshift32           | 1   |  x  |     | Take a seed and call xorshift32 on it. (32 bits)
lfsr                 | 1   |  x  |     | Take a seed and call a simple lfsr on it. (32 bits)
xorshift64s-seq      | 1   |  x  |     | Using a seed, generate an infinite sequence using 
                     |     |     |     | xorshift64s.
xorshift64-seq       | 1   |  x  |     | Using a seed, generate an infinite sequence using 
                     |     |     |     | xorshift64.
xorshift32-seq       | 1   |  x  |     | Using a seed, generate an infinite sequence using 
                     |     |     |     | xorshift32.
lfsr-seq             | 1   |  x  |     | Using a seed, generate an infinite sequence using 
                     |     |     |     | lfsr (32 bits).
random-nums          | 1   |  x  |     | Using a seed, generate an infinite sequence of 
                     |     |     |     | random numbers.
with-bounds          | 3   |  x  |     | Take a sequence of numbers, a minimum and a maximum. 
                     |     |     |     | Then every number in the sequence is lazily adjusted
                     |     |     |     | to be betweeen the minimum and maximum.
shuffle              | 2   |  x  |     | Takes a sequence and a seed. Random numbers are 
                     |     |     |     | generated based on the seed and used to shuffle the
                     |     |     |     | sequence.
```

### File: core/sort.lyra

```
Name                 |  #  |Pure?|Gen? | 
---------------------+-----+-----+-----+------------------------------------------------------------
sort                 | 1   |  x  |     | Sort a list.
sort-compare         | 2   |  x  |     | Like sort, but uses a comparator (see compare).
bubblesort           | 1   |  x  |     | Sort a list using bubblesort.
mergesort            | 1   |  x  |     | Sort a list using mergesort.
mergesort-compare    | 2   |  x  |     | Like mergesort, but the first parameter is a 
                     |     |     |     | comparator.
```

### File: core/infix.lyra

```
Name                 |  #  |Pure?|Gen? | 
---------------------+-----+-----+-----+------------------------------------------------------------
infix->prefix        | >=2 |  x  |     | Convert an infix expression into prefix notation and
                     |     |     |     | call it as lyra code.
                     |     |     |     | The first parameter is a map with 4 entries: 
                     |     |     |     | 'associativity-of Take a symbol and return either 
                     |     |     |     | 'left or 'right.
                     |     |     |     | 'precedence-of Take a symbol and return the fitting 
                     |     |     |     | precedence.
                     |     |     |     | 'unary-op? Take a symbol and return true if it is a 
                     |     |     |     | unary operator.
                     |     |     |     | 'bin-op? Take a symbol and return true if it is a 
                     |     |     |     | binary operator.
infix->lyra          | >=1 |  x  |     | Take an infix expression, convert it to lyra code and 
                     |     |     |     | execute. Uses the aliases defined in aliases.lyra
§                    | >=1 |  x  |     | Alias for infix->lyra
show-infix-as-prefix | >=2 |  x  |     | Similar to infix->prefix but does not execute the 
                     |     |     |     | code.
```

### File: core/queue.lyra

```
Name                 |  #  |Pure?|Gen? | 
---------------------+-----+-----+-----+------------------------------------------------------------
queue                | >=0 |  x  |     | Create a new queue.
deque                | >=0 |  x  |     | Create a new deque.
queue?               | 1   |  x  |     | 
deque?               | 1   |  x  |     | 
                     |     |     |     | 
enqueue              | 2   |  x  |     | 
enqueue-all          | 2   |  x  |     | 
dequeue              | 1   |  x  |     | 
                     |     |     |     | 
peek                 | 1   |  x  |     | Take the last element of a vector or the first for other 
                     |     |     |     | collection types.
pop                  | 1   |  x  |     | Remove the last element of a vector or the first for other 
                     |     |     |     | collection types.
push                 | 1   |  x  |     | Add an element to the end of a collection or the front of
                     |     |     |     | a list.
                     |     |     |     | 
->queue              | 1   |  x  |     | Convert a sequence to a queue.
->deque              | 1   |  x  |     | Convert a sequence to a deque.

Other definitions:
  first, rest, add, append, prepend, add-front, last, sequence?, ->list, ->vector, size, reverse, eq?
```

## Variables

```
Name        | File              | 
------------+-------------------+-------------------------------------------------------------------
#t          | core.rb           | Boolean true
#f          | core.rb           | Boolean false
true        | core.rb           | #t
false       | core.rb           | #f
else        | core.lyra         | Alias for #t (for use in cond expressions)
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
nil         | core/clj.lyra     | Nothing
*current-function* | evaluate.rb| Holds the name of the current function.
*ARGS*      | lyra.rb           | Holds the arguments that were passed to the program.
```
