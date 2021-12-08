4096 constant inputbuf#
create inputbuf inputbuf# allot

variable input
: open-input ( -- )
  \ relative paths are resolved relative to whatever's running them
  s" ./input" r/o open-file throw input !
;
: close-input ( -- ) input @ close-file throw ;

: next-line? ( -- c-addr u -1 | 0 )
  inputbuf inputbuf# input @ read-line throw
    if inputbuf swap true
    else drop false
    then
;
: next-line
  next-line? =0
    if ." Missing line " 411 throw
    then
;

: parse-number? ( c-addr u -- n ? ) s>number? nip ;
: parse-number ( c-addr u -- n )
  parse-number? =0
    if ." Invalid number " 412 throw
    then
;

: array ( n -- )
  create cells allot 
  does> ( i -- addr ) swap cells +
;
: 2array ( n -- )
  create 2* cells allot
  does> ( i -- addr ) swap 2* cells +
;

struct
  cell field buf.data
  cell field buf.length
  cell field buf.capacity
end-struct buf
: init-buf ( capacity address -- )
  over allocate throw over buf.data !
  0 over buf.length !
  buf.capacity !
;
: init-zeroed-buf ( length address -- )
  2dup init-buf
  2dup buf.length !
  buf.data @ swap 0 fill
;
: destroy-buf ( buf -- )
  buf.data @ free throw
;
: grow-buf ( target-capacity buf -- )
  >r r@ buf.capacity @ ( target-cap current-cap )
  begin 2dup >
  while
    2* \ double the capacity until we reach/exceed the target
    dup r@ buf.data @ swap resize throw r@ buf.data !
  repeat
  r> buf.capacity ! drop
;
: reserve-buf-space ( space buf -- address )
  2dup buf.length @ + over grow-buf
  dup buf.data @ over buf.length @ + -rot \ track return address
  buf.length +!
;
: remove-buf-region ( start length buf -- )
  >r
  r@ buf.data @ rot + ( length dest )
  2dup + swap ( length src dest )
  over r@ buf.data @ r@ buf.length @ + swap - ( length src dest u )
  move
  negate r> buf.length +! \ shrink the length
;
: buf>size ( buf -- u )
  buf.length @
;
: buf[] ( i buf -- address )
  buf.data @ +
;

struct
  buf field vec.buf
  cell field vec.itemsize
end-struct vec
4 constant DEFAULT_VEC_CAPACITY
: init-vec ( itemsize address -- )
  over DEFAULT_VEC_CAPACITY * over init-buf
  vec.itemsize !
;
: destroy-vec ( address -- ) destroy-buf ;
: append-vec-item ( vec -- address )
  dup vec.itemsize @ swap reserve-buf-space
;
: remove-vec-item ( i vec -- )
  tuck vec.itemsize @ * ( vec start )
  over vec.itemsize @ rot ( start length vec )
  vec.buf remove-buf-region
;
: vec>size ( vec -- u )
  dup buf>size swap vec.itemsize @ /
;
: vec[] ( i vec -- address )
  dup vec.itemsize @ rot *
  swap buf[]
;

\ quicksort
variable sortee
variable sortee-len
: sortee[] ( i -- addr ) cells sortee @ + ;

: swap-cells ( i1 i2 -- )
  sortee[] swap sortee[] swap
  over @ swap ( addr1 v1 addr2 )
  dup @ -rot ( addr1 v2 v1 addr2 )
  ! swap !
;

: partition-cells ( lo hi -- midpoint )
  2dup + 2/ sortee[] @ >r \ track the partition value
  1+ swap 1- swap
  begin
    1- begin dup sortee[] @ r@ > while 1- repeat \ move hi down
    swap
    1+ begin dup sortee[] @ r@ < while 1+ repeat \ move lo up
    swap
    2dup >= \ if hi and lo have crossed
      if r> drop nip exit \ return hi
      then
    2dup swap-cells \ otherwise swap em
  again
;

: quicksort-cells ( lo hi -- )
  over <0
  \ over sortee-len @ >= or
  >r 2dup >= r> or
    if 2drop \ only continue if 0 <= lo < hi < len
    else
      2dup partition-cells ( lo hi p )
      tuck 2swap recurse \ sort lo..p
      1+ swap recurse \ sort p+1..hi
    then 
;

: sort-cells ( array cells -- )
  swap sortee !
  dup sortee-len !
  0 swap 1- quicksort-cells
;