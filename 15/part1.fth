include ../utils.fth

variable grid-size

create grid vec allot
cell grid init-vec

create costs vec allot
cell costs init-vec
: costs[] ( i -- address ) costs vec[] ;

create frontier vec allot
cell frontier init-vec
: frontier[] ( i -- address ) frontier vec[] ;
: frontier-cost@ ( i -- address ) frontier[] @ costs[] @ ;

: xy>i ( x y -- i ) grid-size @ * + ;
: i>xy ( i -- x y ) grid-size @ /mod ;

: parse-input ( -- )
  open-input
  begin next-line?
  while
    dup grid-size !
    0 do
      dup c@ [char] 0 - grid append-vec-item !
      0 costs append-vec-item !
      1+
    loop
    drop
  repeat
  close-input
;

: frontier-swap ( child-i parent-i -- )
  dup frontier vec[] @ >r
  over frontier vec[] @ swap frontier vec[] !
  r> swap frontier vec[] !
;
: frontier-swap? ( child-i parent-i -- ? )
  over frontier-cost@ over frontier-cost@ <
    if frontier-swap true
    else 2drop false
    then
;

: frontier-push ( u -- )
  frontier append-vec-item !
  frontier vec>size 1-
  begin ?dup
  while
    dup 1- 2/ \ get parent index
    2dup frontier-swap?
      if nip
      else 2drop exit
      then
  repeat
;

: frontier-min ( i1 i2 -- i )
  \ if i2 is bigger than the frontier, just drop it
  dup frontier vec>size >= if drop exit then
  over frontier-cost@ over frontier-cost@ <=
    if drop else nip then
;

: preserve-heap-order ( i -- )
  dup frontier vec>size >= if drop exit then
  dup dup 2* 1+ frontier-min
  over 2* 2 + frontier-min ( i imin )
  2dup <>
    if tuck frontier-swap recurse
    else 2drop
    then
;

: frontier-pop ( -- u )
  0 frontier vec[] @
  frontier pop-vec-item @ 0 frontier vec[] !
  0 preserve-heap-order
;

: left-neighbor? ( i -- i -1 | 0 )
  i>xy over 0 >
    if swap 1- swap xy>i true
    else 2drop false
    then
;
: right-neighbor? ( i -- i -1 | 0 )
  i>xy over grid-size @ 1- <
    if swap 1+ swap xy>i true
    else 2drop false
    then
;
: up-neighbor? ( i -- i -1 | 0 )
  i>xy dup 0 >
    if 1- xy>i true
    else 2drop false
    then
;
: down-neighbor? ( i -- j -1 | 0 )
  i>xy dup grid-size @ 1- <
    if 1+ xy>i true
    else 2drop false
    then
;
: add-cost? ( from to -- ? )
  dup costs vec[] @
    if 2drop false exit
    then
  swap costs vec[] @
  over grid vec[] @ +
  swap costs vec[] !
  true
;

: solve-for-address ( i -- )
  dup left-neighbor?
    if 2dup add-cost?
      if frontier-push else drop then
    then
  dup right-neighbor?
    if 2dup add-cost?
      if frontier-push else drop then
    then
  dup up-neighbor?
    if 2dup add-cost?
      if frontier-push else drop then
    then
  dup down-neighbor?
    if 2dup add-cost?
      if frontier-push else drop then
    then
  drop
;

: solve ( -- )
  0 frontier-push
  begin frontier vec>size
  while
    frontier-pop solve-for-address
  repeat
;

: run ( -- )
  parse-input
  solve
  grid-size @ 1- grid-size @ 1- xy>i costs vec[] @ .
;

run
grid destroy-vec
costs destroy-vec
frontier destroy-vec
bye