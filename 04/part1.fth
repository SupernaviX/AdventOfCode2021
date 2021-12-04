include ../utils.fth

create numbers buf allot
50 numbers init-buf

: parse-numbers ( c-addr u -- )
  begin [char] , split dup
  while
    parse-number
    1 numbers reserve-buf-space c!
  repeat
  2drop 2drop
;

255 constant marked \ 0xFF means a number has been marked
struct
  25 field board.numbers
  5 field board.row-free#
  5 field board.col-free#
  aligned
end-struct board

create boards vec allot
board boards init-vec

: parse-board-row ( row-address -- )
  >r next-line ( c-addr u )
  begin dup
  while
    bl remove-start \ trim leading spaces
    bl split parse-number r@ c! \ store the number
    r> 1+ >r \ move the target forward
  repeat
  2drop r> drop
;

: parse-board ( address -- )
  5 0 do
    dup board.numbers i 5 * + parse-board-row
    5 over board.row-free# i + c!
    5 over board.col-free# i + c!
  loop
  drop
;

: process-input ( -- )
  open-input
  next-line parse-numbers
  begin next-line?
  while
    2drop \ this was an empty line
    boards append-vec-item parse-board
  repeat
  close-input
;

: find-number-on-board ( number board -- index | -1 )
  >r 24 ( number index )
  begin dup -1 >
  while 2dup r@ board.numbers + c@ <>
  while 1-
  repeat then
  nip r> drop
;
: decrement ( a-addr -- value )
  dup c@ 1-
  tuck swap c!
;

: fill-index-on-board ( index board -- won? )
  2dup board.numbers + marked swap c! \ mark it
  >r 5 /mod ( col-index row-index )
  r@ board.row-free# + decrement =0 swap
  r> board.col-free# + decrement =0 or
;
: mark-number-on-board ( number board -- won? )
  >r
  r@ find-number-on-board
  dup -1 =
    if r> 2drop 0
    else r> fill-index-on-board
    then
;

: mark-number ( number -- winner-index | -1 )
  boards vec>size 1- ( number board-index )
  begin dup -1 >
  while
    2dup boards vec[] mark-number-on-board =0
  while 1-
  repeat then
  nip
;

variable winning-board
variable winning-number
: find-solution ( -- index )
  numbers buf>size 0 do
    i numbers buf[] c@ mark-number
    dup -1 <> if
      winning-board !
      i numbers buf[] c@ winning-number !
      leave
    else drop
    then
  loop
;

: board-score ( board -- score )
  0 ( board score )
  25 0 do
    over board.numbers i + c@ \ number of that space
    dup marked = if drop 0 then \ or 0 if it has been marked
    +
  loop
  nip
;

: run
  process-input
  find-solution
;
run
." winning board: " winning-board @ .
." winning number: " winning-number @ .
." solution: " winning-board @ boards vec[] board-score winning-number @ * .
numbers destroy-buf
boards destroy-vec
bye