# Core functions and expressions

```
Name                 |  #  | Pure|Impl?| 
---------------------+-----+-----+----------------------------------------------------------------
define               | >=2 |  x  |  x  | 
def                  | 2   |  x  |  x  | Equivalent to value-define.
defn                 | >=1 |  x  |     | Equivalent to function-define.
def-macro            | >=1 |  x  |  x  | 
def-type             | >=1 |  x  |  x  | 
lambda               | >=2 |  x  |  x  | 
fn                   | >=2 |  x  |     | Equivalent to lambda but uses vector-literal instead of a list for parameters.
cond                 | >=1 |  x  |  x  | 
if                   | 3   |  x  |  x  | 
let                  | >=1 |  x  |  x  | Sets variables for a scope. Works sequentially.
let*                 | >=1 |  x  |  x  | Sets a single variable.
apply                | >=1 |  x  |  x  | 
quote                | 1   |  x  |  x  | 
recur                | any |  x  |     | Explicit tail-recursion. Only valid in positions that can trigger implicit tail-recursion.
gensym               | 0   |  x  |  x  | 
module               | >=1 |  x  |  x  | 
memoize              | 1   |  x  |     | 
seq                  | 1   |  x  |  x  | Returns a equence for all non-empty collections, Nothing otherwise.
                     |     |     |     | 
lazy                 | 1   |  x  |  x  | 
eager                | 1   |  x  |  x  | 
partial              | >=1 |  x  |  x  | 
                     |     |     |     | 
nothing              | any |  x  |  x  | Swallows any numer of arguments and returns the Nothing object.
unwrap               | 1   |  x  |  x  | 
                     |     |     |     | 
box                  | 1   |  x  |  x  | 
unbox                | 1   |  x  |  x  | 
set-box!             | 2   |  x  |  x  | 
                     |     |     |     | 
load!                | 1   |     |     | Load file (Can be implemented as (eval (read-string (slurp! file))))
require!             | 1   |     |     | Alias for load!
read-string          | 1   |  x  |     | Parses a string into code.
eval                 | 1   |  x  |     | Executes an object as code.
                     |     |     |     | 
measure!             | 2   |     |     | 
                     |     |     |     | 
=                    | 2   |  x  |  x  | 
<                    | 2   |  x  |  x  | 
>                    | 2   |  x  |  x  | 
<=                   | 2   |  x  |  x  | 
>=                   | 2   |  x  |  x  | 
                     |     |     |     | 
+                    | 2   |  x  |  x  | 
-                    | 2   |  x  |  x  | 
*                    | 2   |  x  |  x  | 
/                    | 2   |  x  |  x  | 
rem                  | 2   |  x  |  x  | 
                     |     |     |     | 
and                  | 2   |  x  |  x  | 
or                   | 2   |  x  |  x  | 
                     |     |     |     | 
bit-and              | 2   |  x  |  x  | 
bit-or               | 2   |  x  |  x  | 
bit-xor              | 2   |  x  |  x  | 
bit-shl              | 2   |  x  |  x  | 
bit-shr              | 2   |  x  |  x  | 
                     |     |     |     | 
nothing?             | 1   |  x  |  x  | True for the Nothing object
null?                | 1   |  x  |  x  | True for both Nothing and '()
collection?          | 1   |  x  |     | True for lists, vectors, maps and sets, false for others.
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
id                   | 1   |  x  |  x  | 
id-fn                | 1   |  x  |  x  | Creates a function which always returns the object.
hash                 | 1   |  x  |  x  | Returns the hash-code for an object (reference for Boxes)
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
vector-iterate       | 4   |  x  |  x  | 
                     |     |     |     | 
map-of               | any |  x  |  x  | 
map-size             | 1   |  x  |  x  | 
map-get              | 2   |  x  |  x  | 
map-set              | 3   |  x  |  x  | 
map-remove           | 2   |  x  |  x  | 
map-keys             | 1   |  x  |  x  | 
map-merge            | 2   |  x  |  x  | 
                     |     |     |     | 
set-of               | any |  x  |     | 
set-size             | 1   |  x  |     | 
set-add              | 2   |  x  |     | 
set-remove           | 2   |  x  |     | 
set-merge            | 2   |  x  |     | 
set-difference       | 2   |  x  |     | 
set-merge            | 2   |  x  |     | 
                     |     |     |     | 
begin                | any |  x  |     | 
comment              | any |  x  |     | 
                     |     |     |     | 
size                 | 1   |  x  |  x  | 
count                | 1   |  x  |  x  | Alias for size.
indices-of           | 2   |  x  |     | 
contains?            | 2   |  x  |     | 
includes?            | 2   |  x  |     | Alias for contains?.
first                | 1   |  x  |  x  | 
rest                 | 1   |  x  |  x  | 
last                 | 1   |  x  |  x  | 
but-last             | 1   |  x  |  x  | 
append               | 2   |  x  |     | 
concat               | >=1 |  x  |     | Appends collections.
nth                  | 2   |  x  |  x  | 
split                | 2   |  x  |     | Take spliterator and collection, split collection at each occurance of the spliterator.
split-by             | 2   |  x  |     | 
                     |     |     |     | 
map                  | 2   |  x  |     | 
map-indexed          | 2   |  x  |     | 
fmap                 | 3   |  x  |     | filter, then map
mapf                 | 3   |  x  |     | map, then filter 
mapcat               | 2   |  x  |     | 
map-while            | 3   |  x  |     | 
map-until            | 3   |  x  |     | 
                     |     |     |     | 
filter               | 2   |  x  |     | 
filter-indexed       | 2   |  x  |     | 
remove               | 2   |  x  |     | 
remove-indexed       | 2   |  x  |     |  
                     |     |     |     | 
foldl                | 3   |  x  |  x  | 
foldl1               | 3   |  x  |     | 
foldl-indexed        | 3   |  x  |     | 
foldr                | 3   |  x  |     | 
foldr1               | 3   |  x  |     | 
foldr-indexed        | 3   |  x  |     | 
reduce               | 3   |  x  |     | Alias for foldl.
                     |     |     |     | 
repeat               | 1   |  x  |     | 
repeatedly           | 1   |  x  |     | 
take                 | 2   |  x  |     | 
take-while           | 2   |  x  |     | 
take-until           | 2   |  x  |     | 
drop                 | 2   |  x  |     | 
drop-while           | 2   |  x  |     | 
drop-until           | 2   |  x  |     | 
                     |     |     |     | 
                     |     |     |     | 
print!               | 1   |     |     | 
println!             | 1   |     |  x  | 
readln!              | 0   |     |     | 
file-read!           | 1   |     |     | 
file-write!          | 2   |     |     | 
file-append!         | 2   |     |     | 
slurp!               | 1   |     |     | Alias for file-read!
spit!                | 2   |     |     | Alias for file-write!
```
