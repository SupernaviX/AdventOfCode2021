include ../utils.fth

create formula buf allot
1024 formula init-buf

create production-rules 26 26 * aligned allot

\ rules look like "AB"
: rule[] ( c-addr -- address )
  dup c@ [char] A -
  swap 1+ c@ [char] A -
  26 * + production-rules +
;

\ input should look like "CH -> B"
: save-rule ( c-addr u -- )
  7 <> if ." invalid input " 240 throw then
  dup 6 + c@ swap rule[] c!
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

: tick ( -- )
  \ almost double the buffer
  formula buf>size 1- formula reserve-buf-space
  1- formula buf>size 1- formula buf[] ( old-addr new-addr )
  begin 2dup <>
  while \ given pair "AB" from the old string
    over c@ over c! \ copy "B"
    1- swap 1- swap
    over rule[] c@ over c! \ copy the "AB" productino
    1-
  repeat
  2drop
;

: print-formula ( -- )
  0 formula buf[] formula buf>size type cr
;

create counts 26 cells allot
: count-letters ( -- )
  26 0 do
    0 i cells counts + c!
  loop
  formula buf>size 0 ?do
    i formula buf[] c@ [char] A - cells counts +
    dup @ 1+ swap !
  loop
;
: highest-count ( -- u )
  0
  26 0 do
    i cells counts + @ max
  loop
;
: lowest-count ( -- u )
  -1 1 rshift
  26 0 do
    i cells counts + @ ?dup if min then
  loop
;
: score ( -- u )
  count-letters
  highest-count lowest-count -
;

: run ( -- )
  parse-input
  10 0 do tick loop
  score .
;

run
formula destroy-buf
bye