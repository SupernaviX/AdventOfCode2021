include ../utils.fth

create formula buf allot
1024 formula init-buf

create production-rules 26 26 * aligned allot

: rule[] ( c1 c2 -- address )
  26 * + production-rules +
;
: rule[A] ( u1 u2 -- address )
  [char] A - swap
  [char] A - swap
  rule[]
;

\ input should look like "CH -> B"
: save-rule ( c-addr u -- )
  7 <> if ." invalid input " 240 throw then
  dup 6 + c@ swap dup c@ swap 1+ c@ rule[A] c!
;

: parse-input ( -- )
  open-input
  next-line
  dup formula reserve-buf-space
  swap move

  next-line 2drop \ blank line

  \ parse da rulez
  begin next-line?
  while save-rule
  repeat
  close-input
;

26 26 * 26 * 2* cells constant SCRATCH_SIZE
SCRATCH_SIZE allocate throw constant curr-counts
SCRATCH_SIZE allocate throw constant prev-counts

: curr-count[] ( u1 u2 u -- address )
  26 * + 26 * +
  2* cells curr-counts +
;
: prev-count[] ( ui u1 u -- address )
  26 * + 26 * +
  2* cells prev-counts +
;

: curr-count[A] ( c1 c2 c -- address )
  >r >r [char] A -
  r> [char] A -
  r> [char] A -
  curr-count[]
;

: clear-counts ( -- )
  curr-counts SCRATCH_SIZE 0 fill
;
: init-counts ( -- )
  clear-counts
  26 0 do
    i
    26 0 do
      dup i rule[] c@ if
        \ For the initial pass, count the rightmost character of any valid pair
        dup i i curr-count[] 1 0 rot 2!
      then
    loop
    drop
  loop
;

: add-counts ( prev-u1 prev-u2 curr-u1 curr-u2 -- )
  26 0 do
    2over i prev-count[] 2@
    2over i curr-count[] 2+!
  loop
  2drop 2drop
;

\ Given the total char counts from step i,
\ replace them with the total char counts frmo step i+1
: step-counts ( -- )
  curr-counts prev-counts SCRATCH_SIZE move
  clear-counts
  26 0 do
    i
    26 0 do
      dup i rule[] c@ ?dup if
        [char] A -  ( u1 u )
        2dup over i add-counts  ( u1 u )
        over i tuck add-counts ( u1 )
      then
    loop
    drop
  loop
;

create counts 26 2* cells allot
: count[] ( u -- addr )
  2* cells counts +
;
: count[A] ( c -- addr )
  [char] A - count[]
;
: count-1+! ( c -- )
  count[A] 1 0 rot 2+!
;

: add-char-pair-to-count ( c1 c2 -- )
  [char] A - swap [char] A - swap ( u1 u2 )
  26 0 do
    2dup i curr-count[] 2@ i count[] 2+!
  loop
  2drop
;

: print-formula ( -- )
  0 formula buf[] formula buf>size type cr
;

: highest-count ( -- d )
  0 0
  26 0 do
    i 2* cells counts + 2@ dmax
  loop
;
: lowest-count ( -- d )
  -1 -1 1 rshift
  26 0 do
    i 2* cells counts + 2@
    2dup 0 0 d<>
      if dmin
      else 2drop
      then
  loop
;

: score ( -- d )
  highest-count lowest-count d-
;

: run ( -- )
  parse-input
  init-counts
  40 0 do step-counts loop
  0 formula buf[] c@ count-1+! \ count the leftmost char once
  formula buf>size 1- 0 ?do
    i formula buf[] c@
    i 1+ formula buf[] c@
    add-char-pair-to-count
  loop
  score d.
;

run
formula destroy-buf
curr-counts free throw
prev-counts free throw
bye