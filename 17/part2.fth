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

create all-solutions vec allot
cell all-solutions init-vec
: mark-solution ( x y -- )
  65535 and swap 16 lshift or   \ combine x and y into a cell (4 bytes)
  all-solutions append-vec-item !
;

: find-x-solutions ( y t -- )
  x2 @ 1+ 0 ?do
    i over x-at x1 @ x2 @ 1+ within
      if
        over i swap mark-solution
      then
  loop
  2drop
;

: find-solutions ( y -- )
  dup \ track old y for later
  0 \ ( old-y yspeed y )
  31337 0 do
    dup y1 @ < if
      2drop drop unloop exit
    then
    dup y2 @ <= if
      rot dup i find-x-solutions -rot
    then
    over + \ add yspeed to y
    swap 1- swap \ subtract 1 from yspeed
  loop
;

: count-solutions ( -- n )
  all-solutions buf.data @ all-solutions vec>size sort-cells
  1
  all-solutions vec>size 1 do
    i 1- all-solutions vec[] @ i all-solutions vec[] @ <>
      if 1+
      then
  loop
;

: run ( -- )
  parse-input
  y1 @ negate 1+ y1 @ ?do
    i find-solutions
  loop
  ." Solutions: " count-solutions . cr
;
run
bye