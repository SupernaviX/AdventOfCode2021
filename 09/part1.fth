include ../utils.fth

create gridbuf buf allot
64 gridbuf init-buf

variable grid-w
variable grid-h

: i>xy ( i -- x y ) grid-w @ u/mod ;
: xy>i ( x y -- i ) grid-w @ * + ;
: i@ ( i -- value ) gridbuf buf[] c@ ;
: xy@ ( x y -- value ) xy>i i@ ;

: push-grid-row ( c-addr u -- )
  dup gridbuf reserve-buf-space
  swap 0 do ( c-addr target )
    over c@ [char] 0 - over c!
    1+ swap 1+ swap
  loop
  2drop
;

: parse-input
  0 grid-h !
  open-input
  begin next-line?
  while
    dup grid-w !
    1 grid-h +!
    push-grid-row
  repeat
  close-input
;

: is-low-point? ( i -- ? )
  10 >r \ storing lowest neighbor in the return stack
  i>xy
  over 0 >
    if over 1- over xy@ r> min >r then
  over grid-w @ 1- <
    if over 1+ over xy@ r> min >r then
  dup 0 >
    if 2dup 1- xy@ r> min >r then
  dup grid-h @ 1- <
    if 2dup 1+ xy@ r> min >r then
  xy@ r> <
;

: risk-level ( i -- u ) i@ 1+ ;

: sum-risk-levels ( -- u )
  0
  gridbuf buf>size 0 ?do
    i is-low-point? if i risk-level + then
  loop
;

: run
  parse-input
  sum-risk-levels .
;

run
gridbuf destroy-buf
bye