include ../utils.fth

create algorithm 512 allot

struct
  buf field g.buf
  cell field g.size
  cell field g.default
end-struct grid
: init-grid ( size address -- )
  2dup g.size !
  0 over g.default !
  swap dup * swap g.buf init-zeroed-buf
;
: destroy-grid ( address -- )
  g.buf destroy-buf
;
: grow-grid ( address -- ) \ add 2 rows and 2 columns on either side
  dup g.size @ dup 4 + ( grid oldsize newsize )
  rot 2dup g.size ! ( oldsize newsize grid )
  swap dup * rot dup * - swap reserve-buf-space drop
;
: update-grid-default ( address -- )
  dup g.default @ \ get current deafult
  511 and algorithm + c@ <>0 \ get new default
  swap g.default !
;
: grid-apothem ( grid -- apothem )
  g.size @ 2/
;
: grid-bounds ( grid -- end start ) grid-apothem dup 1+ swap negate ;
: grid[] ( x y grid -- address )
  >r
  r@ grid-apothem + r@ g.size @ *
  swap r@ grid-apothem + +
  r> g.buf buf[]
;
: grid[]@ ( x y grid -- ? )
  >r
  over r@ grid-bounds swap within
  over r@ grid-bounds swap within and if
    r> grid[] c@ <>0
  else
    2drop r> g.default @
  then
;
: grid[]! ( value x y grid -- ) grid[] c! ;

: grid. ( grid -- )
  ." default value: " dup g.default @ . cr
  dup grid-bounds do
    dup grid-bounds do
      dup i j rot grid[]@ if ." #" else ." ." then
    loop
    cr
  loop
  drop
;

create prevgrid grid allot
create currgrid grid allot
: init-grids ( size -- )
  2/ 2* 1+ \ make sure size is odd
  dup currgrid init-grid \ initialize the current grid
  2 - prevgrid init-grid \ as well as a smoler one
;
: swap-grids ( -- ) currgrid prevgrid grid swap-addresses ;
: update-grid-defaults ( -- )
  currgrid update-grid-default
  prevgrid update-grid-default
\  currgrid g.default @ =0 currgrid g.default !
\  prevgrid g.default @ =0 prevgrid g.default !
;

: parse-algorithm ( -- )
  next-line algorithm swap 0 do
    over c@ [char] # = over c!
    1+ swap 1+ swap
  loop
  2drop
;

variable initial-grid-size

: parse-grid ( -- )
  next-line
  dup initial-grid-size !
  init-grids
  initial-grid-size @ 0 do ( c-addr )
    dup c@ [char] # =
    i initial-grid-size @ 2/ - initial-grid-size @ 2/ negate currgrid grid[]!
    1+
  loop drop
  initial-grid-size @ 2/ negate 1+
  begin next-line?
  while
    0 do ( y c-addr )
      2dup c@ [char] # =
      i initial-grid-size @ 2/ - rot currgrid grid[]!
      1+
    loop drop
    1+
  repeat drop
\  currgrid grid-bounds 1+ do
\    next-line drop
\    currgrid grid-bounds do
\      dup c@ [char] # =
\      i j currgrid grid[]!
\      1+
\    loop
\    drop
\  loop
;

: cell-next-value ( x y -- ? )
  over 1- over 1- prevgrid grid[]@ if 1 else 0 then -rot
  over    over 1- prevgrid grid[]@ if 1 else 0 then -rot
  over 1+ over 1- prevgrid grid[]@ if 1 else 0 then -rot
  over 1- over    prevgrid grid[]@ if 1 else 0 then -rot
  over    over    prevgrid grid[]@ if 1 else 0 then -rot
  over 1+ over    prevgrid grid[]@ if 1 else 0 then -rot
  over 1- over 1+ prevgrid grid[]@ if 1 else 0 then -rot
  over    over 1+ prevgrid grid[]@ if 1 else 0 then -rot
  swap 1+ swap 1+ prevgrid grid[]@ if 1 else 0 then
  \ the stack has 9 bits of address on it, assemble that into a number
  0
  9 0 do
    swap i lshift or
  loop
  algorithm + c@ <>0
;
: update-cell ( x y -- )
  2dup cell-next-value
  -rot currgrid grid[]!
;

: grid-step ( -- )
  swap-grids
  currgrid grow-grid
  currgrid grid-bounds do
    currgrid grid-bounds do
      i j update-cell
    loop
  loop
  update-grid-defaults
;

: parse-input ( -- )
  open-input
  parse-algorithm
  next-line 2drop \ ignore empty line
  parse-grid
  close-input
;

: count-on ( -- u )
  0
  currgrid grid-bounds do
    currgrid grid-bounds do
      i j currgrid grid[]@ if 1+ then
    loop
  loop
;

: run ( -- )
  parse-input
  2 0 do
    ." Step " i 1+ . cr
    grid-step
  loop
  ." Cells after 2 steps: " count-on . cr
  50 2 do
    ." Step " i 1+ . cr
    grid-step
  loop
  ." Cells after 50 steps: " count-on . cr
;
run
currgrid destroy-grid
bye