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
: clear-buf ( buf -- )
  0 swap buf.length !
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
: insert-buf-region ( start length buf -- address )
  >r over r> dup buf.length @ rot - >r \ track how many items to move later
  2dup buf.length @ + over grow-buf \ ensure we have enough space
  2dup buf.length +! \ update the buf length
  rot swap buf.data @ + ( length region-start )
  tuck tuck + ( region-start region-start region-end )
  r> move \ move the old region contents, return the new region address
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
: clear-vec ( vec -- ) clear-buf ;
: append-vec-item ( vec -- address )
  dup vec.itemsize @ swap reserve-buf-space
;
: push-vec-item ( vec -- address ) append-vec-item ;
: pop-vec-item ( vec -- address )
  dup buf>size over vec.itemsize @ - over buf[] swap \ get address to return
  dup vec.itemsize @ negate swap buf.length +! \ and shrink it
;
: insert-vec-item ( i vec -- addr )
  tuck vec.itemsize @ * ( vec start )
  over vec.itemsize @ rot ( start length vec )
  vec.buf insert-buf-region
;
: remove-vec-item ( i vec -- )
  tuck vec.itemsize @ * ( vec start )
  over vec.itemsize @ rot ( start length vec )
  vec.buf remove-buf-region
;
: vec>size ( vec -- u )
  dup buf>size swap vec.itemsize @ /
;
: remove-vec-items ( istart count vec -- )
  rot over vec.itemsize @ * ( count vec start )
  -rot swap over vec.itemsize @ * swap ( start length vec )
  vec.buf remove-buf-region
;
: vec[] ( i vec -- address )
  dup vec.itemsize @ rot *
  swap buf[]
;

\ quicksort
variable sortee
variable sortee-len
: sortee[] ( i -- addr ) cells sortee @ + ;
variable comparator
: run-comparator ( c1 c2 -- n ) comparator @ execute ;

: compare-cells ( c1 c2 -- n )
  2dup < -rot > -
;

: swap-cells ( addr1 addr2 -- )
  over @ swap ( addr1 v1 addr2 )
  dup @ -rot ( addr1 v2 v1 addr2 )
  ! swap !
;

\ whatever was written in addr1 will now be in addr2
: swap-addresses ( addr1 addr2 size -- )
  dup 3 and if ." Please only swap cell-aligned addresses :\ " cr 520 throw then
  2/ 2/ 0 ?do
    2dup swap-cells
    cell + swap cell + swap
  loop
  2drop
;

: swap-cells-at-index ( i1 i2 -- )
  sortee[] swap sortee[] swap
  swap-cells
;

: partition-cells ( lo hi -- midpoint )
  2dup + 2/ sortee[] @ >r \ track the partition value
  1+ swap 1- swap
  begin
    1- begin dup sortee[] @ r@ run-comparator 0 > while 1- repeat \ move hi down
    swap
    1+ begin dup sortee[] @ r@ run-comparator 0 < while 1+ repeat \ move lo up
    swap
    2dup >= \ if hi and lo have crossed
      if r> drop nip exit \ return hi
      then
    2dup swap-cells-at-index \ otherwise swap em
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
  ['] compare-cells comparator !
  swap sortee !
  dup sortee-len !
  0 swap 1- quicksort-cells
;

: sort-cells-by ( array cells xt -- )
  comparator !
  swap sortee !
  dup sortee-len !
  0 swap 1- quicksort-cells
;

: 2+! ( d addr -- )
  dup >r
  2@ d+ r> 2!
;

struct
  vec field heap.vec
  cell field heap.priorityfunc
end-struct heap

: heap-swap ( child-i parent-i heap -- )
  >r
  r@ vec[] swap r@ vec[] swap
  r> vec.itemsize @ swap-addresses
;

: heap-priority[]@ ( index heap -- u )
  tuck vec[] swap heap.priorityfunc @ execute
;

: heap-swap? ( child-i parent-i heap )
  >r
  2dup swap r@ heap-priority[]@ rot r@ heap-priority[]@ d<
    if r@ heap-swap true
    else 2drop false
    then
  r> drop
;

: init-heap ( itemsize priority address -- )
  tuck heap.priorityfunc ! init-vec
;
: destroy-heap ( address -- )
  destroy-vec
;
: push-heap-item-start ( heap -- address )
  append-vec-item
;
: push-heap-item-done ( heap -- )
  >r
  r@ vec>size 1-
  begin ?dup
  while
    dup 1- 2/ \ get parent index
    2dup r@ heap-swap?
      if nip
      else 2drop r> drop exit
      then
  repeat
  r> drop
;

: heap-min ( i1 i2 heap -- i )
  >r
  \ if i2 is bigger than the heap size, just drop it
  dup r@ vec>size >= if r> 2drop exit then
  2dup swap r@ heap-priority[]@ rot r@ heap-priority[]@ d<=
    if drop else nip then
  r> drop
;

: preserve-heap-order ( i heap -- )
  >r
  dup r@ vec>size >= if r> 2drop exit then
  dup dup 2* 1+ r@ heap-min
  over 2* 2 + r@ heap-min ( i imin )
  2dup <>
    if tuck r@ heap-swap r> recurse
    else r> drop 2drop
    then
;

: pop-heap ( heap -- address )
  >r
  0 r@ vec>size 1- r@ heap-swap \ swap the lowest and highest item
  r@ vec.itemsize @ negate r@ buf.length +! \ shrink the heap
  0 r@ preserve-heap-order \ ensure everything left is ordered
  r@ vec>size r> vec[] \ return one past the old start, where it is stored
;
: peek-heap ( heap -- address )
  0 swap vec[]
;
