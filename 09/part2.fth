include ../utils.fth

create gridbuf buf allot
64 gridbuf init-buf

variable grid-w
variable grid-h

: i>xy ( i -- x y ) grid-w @ u/mod ;
: xy>i ( x y -- i ) grid-w @ * + ;
: i@ ( i -- value ) gridbuf buf.data @ + c@ ;
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

create basin-sizes vec allot
cell basin-sizes init-vec

create seenbuf buf allot
variable basin-total

: traverse ( i -- )
  dup seenbuf buf[] c@ if drop exit then \ if we have seen it stop
  1 over seenbuf buf[] c! \ note that we've seen it
  1 basin-total +! \ the basin is just that much bigger
  dup i@ >r \ hold onto our own size in the return stack
  i>xy
  over 0 > if
    over 1- over xy>i dup i@ r@ 9 within
      if recurse
      else drop
      then
  then
  over grid-w @ 1- < if
    over 1+ over xy>i dup i@ r@ 9 within
      if recurse
      else drop
      then
  then
  dup 0 > if
    2dup 1- xy>i dup i@ r@ 9 within
      if recurse
      else drop
      then
  then
  dup grid-h @ 1- < if
    2dup 1+ xy>i dup i@ r@ 9 within
      if recurse
      else drop
      then
  then
  2drop r> drop
;

: clear-seen ( -- )
  seenbuf buf.data @ seenbuf buf>size 0 fill
;

: basin-size ( i -- u )
  clear-seen
  0 basin-total !
  traverse
  basin-total @
;

: find-basin-sizes ( -- )
  gridbuf buf>size seenbuf init-zeroed-buf
  gridbuf buf>size 0 ?do
    i is-low-point? if
      i basin-size basin-sizes append-vec-item !
    then
  loop
;

: product-of-three-biggest-basins ( -- )
  basin-sizes buf.data @ basin-sizes vec>size sort-cells
  1
  basin-sizes vec>size dup 3 - do
    i basin-sizes vec[] @ *
  loop
;

: run
  parse-input
  find-basin-sizes
  product-of-three-biggest-basins . cr
;

run
gridbuf destroy-buf
bye