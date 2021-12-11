include ../utils.fth

variable line
variable line#

: next-char? ( -- c -1 | -1 0 )
  line# @
    if
      line @ c@ -1
      1 line +! -1 line# +!
    else -1 0
    then
;

: bad-char? ( c -- ? )
  case
    [char] ) of [char] ( <> endof
    [char] ] of [char] [ <> endof
    [char] } of [char] { <> endof
    [char] > of [char] < <> endof
    0 over \ by default, leave the char on the stack but return 0
  endcase
;

: is-valid-prefix? ( * -- * -1 ) \ warning this HEAVILY messes up the stack
  begin next-char?
  while bad-char? =0 dup
  while drop
  repeat then
;

variable ogdepth
: begin-stack-antics ( -- * )
  0 \ add a 0 to the stack so that we never underflow it
;
: end-stack-antics ( * -- )
  begin ?dup
  while drop
  repeat
;

: score-missing-char ( c -- u )
  case
    [char] ( of 1 endof
    [char] [ of 2 endof
    [char] { of 3 endof
    [char] < of 4 endof
  endcase
;
: score-missing-chars ( * -- d )
  0 0 2>r
  begin ?dup
  while score-missing-char 2r> 5 d* rot 0 d+ 2>r
  repeat
  2r>
;

: solve-line ( c-addr u -- dscore )
  line# ! line !
  begin-stack-antics
  is-valid-prefix?
    if score-missing-chars
    else end-stack-antics 0 0
    then
;

create scores vec allot
2 cells scores init-vec
: scores@ ( i -- d ) scores vec[] 2@ ;

: find-lowest-index ( -- i )
  0 scores vec>size ( lowest current )
  begin ?dup
  while
    1-
    2dup scores@ rot scores@ d<
      if nip dup
      then
  repeat
;
: find-highest-index ( -- i )
  0 scores vec>size ( lowest current )
  begin ?dup
  while
    1-
    2dup scores@ rot scores@ d>
      if nip dup
      then
  repeat
;
: find-median-score ( -- d )
  begin scores vec>size 1 >
  while
    find-highest-index scores remove-vec-item
    find-lowest-index scores remove-vec-item
  repeat
  0 scores@
;

: run ( -- u )
  open-input
  begin next-line?
  while
    solve-line
    2dup 0 0 d<>
      if scores append-vec-item 2!
      else 2drop
      then
  repeat
  close-input
  find-median-score
;

run d.
bye