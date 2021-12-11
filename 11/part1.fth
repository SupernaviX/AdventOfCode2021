include ../utils.fth

create gridbuf buf allot
64 gridbuf init-buf

variable grid-w
variable grid-h

: i>xy ( i -- x y ) grid-w @ u/mod ;
: xy>i ( x y -- i ) grid-w @ * + ;
: i@ ( i -- value ) gridbuf buf[] c@ ;
: i! ( value i -- ) gridbuf buf[] c! ;
: xy@ ( x y -- value ) xy>i i@ ;

: print-grid ( -- )
  grid-h @ 0 do
    i
    grid-w @ 0 do
      i over xy@ 0 <# #s #> type
    loop
    drop cr
  loop cr
;

: push-grid-row ( c-addr u -- )
  dup gridbuf reserve-buf-space
  swap 0 do ( c-addr target )
    over c@ [char] 0 - over c!
    1+ swap 1+ swap
  loop
  2drop
;

: parse-input ( -- )
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

: i@grow ( i -- flash? )
  dup i@ 1+ tuck swap i!
  10 =
;

: i@process ( i -- )
  dup i@grow if
    i>xy
    over 0 > if
      dup 0 >
        if over 1- over 1- xy>i recurse then
      over 1- over xy>i recurse
      dup grid-h @ 1- <
        if over 1- over 1+ xy>i recurse then
    then
    dup 0 >
      if 2dup 1- xy>i recurse then
    dup grid-h @ 1- <
      if 2dup 1+ xy>i recurse then
    over grid-w @ 1- < if
      dup 0 >
        if over 1+ over 1- xy>i recurse then
      over 1+ over xy>i recurse
      dup grid-h @ 1- <
        if over 1+ over 1+ xy>i recurse then
    then
    2drop
  else drop
  then
;

variable flashes
0 flashes !
: i@handle-flash ( i -- )
  dup i@ 9 >
    if
      1 flashes +!
      0 swap i!
    else drop
    then
;

: tick ( -- )
  gridbuf buf>size 0 do
    i i@process
  loop
  gridbuf buf>size 0 do
    i i@handle-flash
  loop
;

: run
  parse-input
  100 0 do tick loop
  flashes @ .
;
run
gridbuf destroy-buf
bye