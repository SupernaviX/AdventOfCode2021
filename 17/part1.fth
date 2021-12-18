include ../utils.fth

variable x1
variable x2
variable y1
variable y2

: parse-input ( -- )
  open-input next-line close-input
  15 /string \ skip "target area: x="
  [char] . split parse-number x1 !
  1 /string \ skip "."
  [char] , split parse-number x2 !
  3 /string \ skip " y="
  [char] . split parse-number y1 !
  1 /string \ skip "."
  parse-number y2 !
;

: x-at ( x-init t -- n )
  ?dup =0 if drop 0 exit then
  0 swap 0 do ( x-init xpos )
    over +
    swap dup if 1- then swap
  loop
  nip
;

: is-x-solution? ( t -- ? )
  x2 @ 0 ?do
    i over x-at x1 @ x2 @ 1+ within
      if drop true unloop exit
      then
  loop
  drop false
;

: is-solution? ( y -- ? )
  0 \ ( yspeed y )
  31337 0 do
    dup y1 @ < if
      2drop false unloop exit
    then
    dup y2 @ < if
      i is-x-solution?
        if 2drop true unloop exit
        then
    then
    over + \ add yspeed to y
    swap 1- swap \ subtract 1 from yspeed
  loop
;

: run ( -- )
  parse-input
  y1 @ negate 
  begin dup is-solution? =0
  while 1-
  repeat
  ." Solution y: " dup . cr
  ." max height: " dup 1+ * 2/ . cr
;
run
bye