# Core functions and expressions

```
Name                 |  #  | Pure|Impl?| 
---------------------+-----+-----+------------------------------------------------------------------
define               | >=2 |  x  |  x  | Different formats:
                     |     |     |     | (define sym val) Sets the value for sym to val in the 
                     |     |     |     | module environment. (value-define)
                     |     |     |     | (define (sig) & bodx) Defines a function. (function-define)
                     |     |     |     | (define type genfunc impl) Adds an implementation for the 
                     |     |     |     | generic function genfunc.
def-generic          | 3   |  x  |  x  | Defines a generic function. It takes a symbol, function 
                     |     |     |     | signature and a fallback function.
def                  | 2   |  x  |  x  | Equivalent to value-define.
defn                 | >=1 |  x  |  x  | Equivalent to function-define.
def-macro            | >=1 |  x  |  x  | Defines a macro. (See redme)
def-type             | >=1 |  x  |  x  | Defines a new type. This adds a couple of other functions
                     |     |     |     | automatically. (See redme)
lambda               | >=2 |  x  |  x  | 
fn                   | >=2 |  x  |  x  | Equivalent to lambda but uses vector-literal instead of a
                     |     |     |     | list for parameters.
cond                 | >=1 |  x  |  x  | 
if                   | 3   |  x  |  x  | 
let                  | >=1 |  x  |  x  | Sets variables for a scope. References are looked up from
                     |     |     |     | the old environment.
let*                 | >=1 |  x  |  x  | Sets variables for a scope. Works sequentially.
let1                 | 2   |  x  |  x  | Sets a single variable.
apply                | >=1 |  x  |  x  | 
quote                | 1   |  x  |  x  | 
recur                | any |  x  |  x  | Explicit tail-recursion. Only valid in positions that can
                     |     |     |     | trigger implicit tail-recursion.
gensym               | 0   |  x  |  x  | 
module               | >=1 |  x  |  x  | 
memoize              | 1   |  x  |  x  | 
def-memo             | >=1 |  x  |  x  | A macro which defines a function and memoizes it.
seq                  | 1   |  x  |  x  | Returns a equence for all non-empty collections, Nothing
                     |     |     |     | otherwise.
                     |     |     |     | 
lazy                 | 1   |  x  |  x  | 
eager                | 1   |  x  |  x  | 
partial              | >=1 |  x  |  x  | 
                     |     |     |     | 
nothing              | any |  x  |  x  | Swallows any numer of arguments and returns the Nothing
                     |     |     |     | object.
unwrap               | 1   |  x  |  x  | 
                     |     |     |     | 
box                  | 1   |  x  |  x  | 
unbox                | 1   |  x  |  x  | 
set-box!             | 2   |  x  |  x  | 
                     |     |     |     | 
load!                | 1   |     |  x  | Load file. Attention: load! always uses the global 
                     |     |     |     | environment, not the local one.
require!             | 1   |     |  x  | Alias for load!
read-string          | 1   |  x  |  x  | Parses a string into code.
eval!                | 1   |     |  x  | Executes an object as code.
                     |     |     |     | 
measure!             | 2   |  x  |  x  | 
                     |     |     |     | 
=                    | 2   |  x  |  x  | 
/=                   | 2   |  x  |  x  | 
<                    | 2   |  x  |  x  | 
>                    | 2   |  x  |  x  | 
<=                   | 2   |  x  |  x  | 
>=                   | 2   |  x  |  x  | 
                     |     |     |     | 
+                    | 2   |  x  |  x  | 
v+                   | >=1 |  x  |  x  | Variadic +
-                    | 2   |  x  |  x  | 
*                    | 2   |  x  |  x  | 
/                    | 2   |  x  |  x  | 
rem                  | 2   |  x  |  x  | 
                     |     |     |     | 
inc                  | 1   |  x  |  x  | Increases a number by 1.
dec                  | 1   |  x  |  x  | Decreases a number by 1.
min                  | 2   |  x  |  x  | Get minimum of 2 objects.
max                  | 2   |  x  |  x  | Get maximum of 2 objects.
                     |     |     |     | 
not                  | 1   |  x  |  x  | 
and                  | 2   |  x  |  x  | 
or                   | 2   |  x  |  x  | 
                     |     |     |     | 
bit-and              | 2   |  x  |  x  | 
bit-or               | 2   |  x  |  x  | 
bit-xor              | 2   |  x  |  x  | 
bit-shl              | 2   |  x  |  x  | 
bit-shr              | 2   |  x  |  x  | 
                     |     |     |     | 
defined?             | 1   |  x  |  x  | Checks whether or not a symbol is defined.
nothing?             | 1   |  x  |  x  | True for the Nothing object
null?                | 1   |  x  |  x  | True for both Nothing and '()
collection?          | 1   |  x  |  x  | True for lists, vectors, maps and sets, false for others.
sequence?            | 1   |  x  |  x  | True if the input is a list or vector.
list?                | 1   |  x  |  x  | 
vector?              | 1   |  x  |  x  | 
int?                 | 1   |  x  |  x  | 
float?               | 1   |  x  |  x  | 
string?              | 1   |  x  |  x  | 
symbol?              | 1   |  x  |  x  | 
char?                | 1   |  x  |  x  | 
boolean?             | 1   |  x  |  x  | 
map?                 | 1   |  x  |  x  | 
set?                 | 1   |  x  |  x  | 
empty?               | 1   |  x  |  x  | 
                     |     |     |     | 
compose              | 2   |  x  |  x  | Given 2 functions f and g, makes a new function for
                     |     |     |     | (f (g x))
compose-and          | 2   |  x  |  x  | Given 2 functions f and g, makes a new function for
                     |     |     |     | checking (and (f x) (g x))
compose-or           | 2   |  x  |  x  | Given 2 functions f and g, makes a new function for
                     |     |     |     | checking (or (f x) (g x))
complement           | 1   |  x  |  x  | Returns given a function p, returns a function which
                     |     |     |     | checks (not (p x))
                     |     |     |     | 
id                   | 1   |  x  |  x  | 
id-fn                | 1   |  x  |  x  | Creates a function which always returns the object.
hash                 | 1   |  x  |  x  | Returns the hash-code for an object
                     |     |     |     | (reference for Boxes)
eq?                  | 2   |  x  |  x  | 
                     |     |     |     | 
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
list                 | any |  x  |  x  | 
list-size            | 1   |  x  |  x  | 
car                  | 1   |  x  |  x  | 
cdr                  | 1   |  x  |  x  | 
cons                 | 2   |  x  |  x  | 
                     |     |     |     | 
vector               | any |  x  |  x  | 
vector-size          | 1   |  x  |  x  | 
vector-nth           | 2   |  x  |  x  | 
vector-add           | 2   |  x  |  x  | 
vector-append        | 2   |  x  |  x  | 
                     |     |     |     | 
iterate-seq          | 3   |  x  |  x  | Iterates a sequence with a function, accumular and the
                     |     |     |     | sequence. The function takes 3 arguments: The accumulator,
                     |     |     |     | the current element and the current element. Example:
                     |     |     |     |   (iterate-seq (lambda (acc e idx) (+ acc e)) 0 sequence)
iterate-seq-p        | 4   |  x  |  x  | Similar to iterate-seq, but the first argument is a
                     |     |     |     | predicate. When the predicate returns a falsey value, the
                     |     |     |     | iteration breaks.
                     |     |     |     | 
map-of               | any |  x  |  x  | 
map-size             | 1   |  x  |  x  | 
map-get              | 2   |  x  |  x  | 
map-set              | 3   |  x  |  x  | 
map-remove           | 2   |  x  |  x  | 
map-keys             | 1   |  x  |  x  | 
map-merge            | 2   |  x  |  x  | 
                     |     |     |     | 
set-of               | any |  x  |  x  | 
set-size             | 1   |  x  |  x  | 
set-add              | 2   |  x  |  x  | 
set-union            | 2   |  x  |  x  | 
set-difference       | 2   |  x  |  x  | 
set-intersection     | 2   |  x  |  x  | 
set-includes?        | 2   |  x  |  x  | 
set-subset?          | 2   |  x  |  x  | 
set-true-subset?     | 2   |  x  |  x  | 
set-superset?        | 2   |  x  |  x  | 
set-true-superset?   | 2   |  x  |  x  | 
                     |     |     |     | 
begin                | any |  x  |  x  | 
comment              | any |  x  |  x  | 
                     |     |     |     | 
size                 | 1   |  x  |  x  | 
count                | 1   |  x  |  x  | Alias for size.
indices-of           | 2   |  x  |  x  | 
contains?            | 2   |  x  |  x  | 
first                | 1   |  x  |  x  | 
rest                 | 1   |  x  |  x  | 
last                 | 1   |  x  |  x  | 
but-last             | 1   |  x  |  x  | 
append               | 2   |  x  |  x  | 
concat               | >=1 |  x  |  x  | Appends collections.
nth                  | 2   |  x  |  x  | 
split                | 2   |  x  |     | Take spliterator and collection, split collection at each
                     |     |     |     | occurance of the spliterator.
split-by             | 2   |  x  |     | 
                     |     |     |     | 
map                  | 2   |  x  |  x  | 
map-indexed          | 2   |  x  |  x  | 
fmap                 | 3   |  x  |  x  | filter, then map
mapf                 | 3   |  x  |  x  | map, then filter 
mapcat               | 2   |  x  |     | 
map-while            | 3   |  x  |     | 
map-until            | 3   |  x  |     | 
                     |     |     |     | 
filter               | 2   |  x  |  x  | 
filter-indexed       | 2   |  x  |     | 
remove               | 2   |  x  |  x  | 
remove-indexed       | 2   |  x  |     |  
                     |     |     |     | 
foldl                | 3   |  x  |  x  | 
foldl1               | 3   |  x  |  x  | 
foldl-indexed        | 3   |  x  |  x  | 
foldr                | 3   |  x  |  x  | 
foldr1               | 3   |  x  |  x  | 
foldr-indexed        | 3   |  x  |  x  | 
reduce               | 3   |  x  |  x  | Alias for foldl.
                     |     |     |     | 
repeat               | 1   |  x  |     | 
repeatedly           | 1   |  x  |     | 
take                 | 2   |  x  |  x  | 
take-while           | 2   |  x  |  x  | 
take-until           | 2   |  x  |  x  | 
drop                 | 2   |  x  |  x  | 
drop-while           | 2   |  x  |  x  | 
drop-until           | 2   |  x  |  x  | 
take-drop            | 2   |  x  |  x  | Creates a list equal to
                     |     |     |     |   (list (take n xs) (drop n xs))
take-drop-while      | 2   |  x  |  x  | Creates a list equal to
                     |     |     |     |   (list (take-while p xs) (drop-while p xs))
take-drop-until      | 2   |  x  |  x  | Creates a list equal to
                     |     |     |     |   (list (take-until p xs) (drop-until p xs))
                     |     |     |     | 
zip-with             | 3   |  x  |  x  | 
zip                  | 2   |  x  |  x  | (zip l0 l1) is equal to (zip-with list l0 l1)
                     |     |     |     | 
all?                 | 2   |  x  |  x  | Checks whether a predicate is true for all elements in a 
                     |     |     |     | list.
none?                | 2   |  x  |  x  | Checks whether a predicate is true for no element in a 
                     |     |     |     | list.
any?                 | 2   |  x  |  x  | Checks whether a predicate is true for at least 1 element
                     |     |     |     | in a list.
va-all?              | >=1 |  x  |  x  | Variadic version of all?
va-none?             | >=1 |  x  |  x  | Variadic version of none?
va-any?              | >=1 |  x  |  x  | Variadic version of any?
                     |     |     |     | 
reverse              | 1   |  x  |  x  | Reverse a list
sum                  | 1   |  x  |  x  | Sums the elements of a list.
minimum              | 1   |  x  |  x  | Get minimum of a list.
maximum              | 1   |  x  |  x  | Get maximum of a list.
                     |     |     |     | 
bubblesort           | 1   |  x  |  x  | Sort a list using bubblesort.
                     |     |     |     | 
print!               | 1   |     |  x  | 
println!             | 1   |     |  x  | 
readln!              | 0   |     |  x  | 
file-read!           | 1   |     |  x  | 
file-write!          | 2   |     |  x  | 
file-append!         | 2   |     |  x  | 
slurp!               | 1   |     |  x  | Alias for file-read!
spit!                | 2   |     |  x  | Alias for file-write!
                     |     |     |     | 
type-name            | 1   |  x  |  x  | Returns the name of the type of a variable.
                     |     |     |     | 
ljust                | 2   |  x  |  x  | Takes a string and a number. The string is then resized to
                     |     |     |     | at least n characters by inserting spaces on the right
                     |     |     |     | side.
```

```
Name                 | 
---------------------+----------------------------------------------------------------------------
#t                   | Boolean true
#f                   | Boolean false
else                 | alias for #t
Nothing              | The non-object
```
