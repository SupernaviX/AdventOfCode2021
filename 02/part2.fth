include ../utils.fth

s" ./input" r/o open-file throw constant input

80 constant inputbuf#
create inputbuf inputbuf# allot

: next-command ( -- c-addr u number -1 | 0 )
  inputbuf inputbuf# input read-line throw
    if inputbuf swap bl split 2swap parse-number?
    else drop false
    then
;

variable hpos
variable depth
variable aim
0 hpos !
0 depth !
0 aim !

: move-forward ( n -- )
  dup hpos +!
  aim @ * depth +!
;
: aim-down ( n -- ) aim +! ;
: aim-up ( n -- ) negate aim +! ;

: run
  begin next-command
  while
    -rot
    2dup s" forward" str=
    if 2drop move-forward
    else
      s" down" str=
      if aim-down
      else aim-up
      then
    then
  repeat
;

run
." hpos: " hpos @ .
." depth: " depth @ .
." solution: " hpos @ depth @ * .
bye