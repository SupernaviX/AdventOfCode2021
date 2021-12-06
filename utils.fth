512 constant inputbuf#
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