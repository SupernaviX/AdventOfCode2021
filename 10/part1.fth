include ../utils.fth

variable line
variable line#

: next-char? ( -- c -1 | 0 0 )
  line# @
    if
      line @ c@ -1
      1 line +! -1 line# +!
    else 0 0
    then
;

: expect-char ( actual expected score -- score | 0 )
  -rot <> and
;

: handle-char ( c -- score )
  case
    [char] ) of [char] ( 3 expect-char endof
    [char] ] of [char] [ 57 expect-char endof
    [char] } of [char] { 1197 expect-char endof
    [char] > of [char] < 25137 expect-char endof
    0 over \ by default, leave the char on the stack but return 0
  endcase
;

: score-line ( * -- * score ) \ warning this HEAVILY messes up the stack
  begin next-char?
  while
    handle-char
    ?dup =0
  while repeat then
;

: begin-stack-antics ( -- * )
  0 \ add one extra value to the stack so that we never underflow it
;
: end-stack-antics ( * -- )
  begin ?dup
  while drop
  repeat
;
: solve-line ( c-addr u -- score )
  line# ! line !
  begin-stack-antics
  score-line >r \ track the score in the return stack because...
  end-stack-antics \ we are doing Stack Nonsense
  r> \ return the score  
;

: run ( -- u )
  open-input
  0
  begin next-line?
  while solve-line +
  repeat
  close-input
;

run .
bye