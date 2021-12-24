include ../utils.fth

struct
  cell field r.x1
  cell field r.x2
  cell field r.y1
  cell field r.y2
  cell field r.z1
  cell field r.z2
end-struct region

: copy-region ( from to -- ) region move ;
: region-size ( region -- d )
  >r
  r@ r.x2 @ r@ r.x1 @ - 1+ 0
  r@ r.y2 @ r@ r.y1 @ - 1+ d*
  r@ r.z2 @ r> r.z1 @ - 1+ d*
;

struct
  region field in.region
  cell field in.on?
end-struct instruction

create instructions vec allot
instruction instructions init-vec
: instruction[] ( i -- address ) instructions vec[] ;
: instructions-bounds ( -- end start ) instructions vec>size 0 ;

\ parse "123..456" into 123 and 456
: parse-range ( c-addr u -- start end )
  [char] . split parse-number -rot
  1 /string \ skip .
  parse-number
;

: parse-instruction ( c-addr u -- )
  instructions push-vec-item >r
  bl split s" on" str= r@ in.on? !
  [char] , split 2 /string \ x=x1..x2
  parse-range r@ r.x2 ! r@ r.x1 !
  [char] , split 2 /string \ y=y1..y2
  parse-range r@ r.y2 ! r@ r.y1 !
  2 /string \ z=z1..z2
  parse-range r@ r.z2 ! r> r.z1 !
;

: parse-input ( -- )
  open-input
  begin next-line?
  while parse-instruction
  repeat
  close-input
;

create regions vec allot
region regions init-vec
: region[] ( i -- address ) regions vec[] ;
: regions-bounds ( -- end start ) regions vec>size 0 ;

variable current-instruction
: instruction-on? ( -- ? ) current-instruction @ in.on? @ ;
: instruction-x1 ( -- n ) current-instruction @ r.x1 @ ;
: instruction-x2 ( -- n ) current-instruction @ r.x2 @ ;
: instruction-y1 ( -- n ) current-instruction @ r.y1 @ ;
: instruction-y2 ( -- n ) current-instruction @ r.y2 @ ;
: instruction-z1 ( -- n ) current-instruction @ r.z1 @ ;
: instruction-z2 ( -- n ) current-instruction @ r.z2 @ ;

variable current-region
: region-x1 ( -- n ) current-region @ r.x1 @ ;
: region-x2 ( -- n ) current-region @ r.x2 @ ;
: region-y1 ( -- n ) current-region @ r.y1 @ ;
: region-y2 ( -- n ) current-region @ r.y2 @ ;
: region-z1 ( -- n ) current-region @ r.z1 @ ;
: region-z2 ( -- n ) current-region @ r.z2 @ ;

: region. ( region -- )
  dup r.x1 @ 0 .r ." .."
  dup r.x2 @ 0 .r ." , "
  dup r.y1 @ 0 .r ." .."
  dup r.y2 @ 0 .r ." , "
  dup r.z1 @ 0 .r ." .."
  r.z2 @ 0 .r
;

: instruction. ( instruction -- )
  dup in.on? @ if ." on " else ." off " then region.
;

: within-inc ( x low high -- ? ) 1+ within ;

: segments-overlap? ( a1 a2 b1 b2 -- ? )
  -rot >= -rot <= and
;

: instruction-overlaps-region ( -- ? )
  instruction-x1 instruction-x2 region-x1 region-x2 segments-overlap?
  instruction-y1 instruction-y2 region-y1 region-y2 segments-overlap? and
  instruction-z1 instruction-z2 region-z1 region-z2 segments-overlap? and
;

: copy-current-region ( -- address )
  regions push-vec-item
  current-region @ over copy-region
;
: try-split-x1 ( -- )
  region-x1 instruction-x1 < if
    \ create a new region from the non-overlapping bit
    copy-current-region
    instruction-x1 1- swap r.x2 !
    \ shrink the overlapping region
    instruction-x1 current-region @ r.x1 !
  then
;
: try-split-x2 ( -- )
  region-x2 instruction-x2 > if
    \ create a new region from the non-overlapping bit
    copy-current-region
    instruction-x2 1+ swap r.x1 !
    \ shrink the overlapping region
    instruction-x2 current-region @ r.x2 !
  then
;
: try-split-y1 ( -- )
\  region-y2 instruction-y1 instruction-y2 within-inc
  region-y1 instruction-y1 < if
    \ create a new region from the non-overlapping bit
    copy-current-region
    instruction-y1 1- swap r.y2 !
    \ shrink the overlapping region
    instruction-y1 current-region @ r.y1 !
  then
;
: try-split-y2 ( -- )
  region-y2 instruction-y2 > if
    \ create a new region from the non-overlapping bit
    copy-current-region
    instruction-y2 1+ swap r.y1 !
    \ shrink the overlapping region
    instruction-y2 current-region @ r.y2 !
  then
;
: try-split-z1 ( -- )
  region-z1 instruction-z1 < if
    \ create a new region from the non-overlapping bit
    copy-current-region
    instruction-z1 1- swap r.z2 !
    \ shrink the overlapping region
    instruction-z1 current-region @ r.z1 !
  then
;
: try-split-z2 ( -- )
  region-z2 instruction-z2 > if
    \ create a new region from the non-overlapping bit
    copy-current-region
    instruction-z2 1+ swap r.z1 !
    \ shrink the overlapping region
    instruction-z2 current-region @ r.z2 !
  then
;

: try-split-region ( -- )
  try-split-x1
  try-split-x2
  try-split-y1
  try-split-y2
  try-split-z1
  try-split-z2
;

: process-region ( region -- )
  current-region !
  instruction-overlaps-region if
    \ create new little regions for the parts that don't overlap
    \ we will not include the original region in our new set
    try-split-region
  else
    \ this region is entirely separate from the new one
    \ therefore we just need to preserve it
    current-region @ regions push-vec-item copy-region
  then
;

: process-instruction ( instruction -- )
  current-instruction !
  regions vec>size >r \ store how many regions there are before this iteration
  regions-bounds ?do
    i region[] process-region
  loop
  instruction-on? if
    current-instruction @ regions push-vec-item copy-region
  then
  0 r> regions remove-vec-items
;

: count-active-cells ( -- d )
  0 0
  regions-bounds ?do
    i region[] region-size d+
  loop
;

: regions. ( -- )
  regions-bounds ?do
    i region[] region. cr
  loop
;

: process-instructions ( -- )
  instructions-bounds ?do
    ." Applying instruction " i 1+ . ." of " instructions vec>size . cr
    i instruction[] process-instruction
  loop
;

: run ( -- )
  parse-input
  process-instructions
\  regions.
  count-active-cells d.
;
run
bye