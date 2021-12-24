include ../utils.fth

struct
  cell field in.on?
  cell field in.x1
  cell field in.x2
  cell field in.y1
  cell field in.y2
  cell field in.z1
  cell field in.z2
end-struct instruction

create instructions vec allot
instruction instructions init-vec
: instruction[] ( i -- address ) instructions vec[] ;
: instructions-bounds ( -- end start ) instructions vec>size 0 ;

: instruction. ( instruction -- )
  dup in.on? @ .
  dup in.x1 @ .
  dup in.x2 @ .
  dup in.y1 @ .
  dup in.y2 @ .
  dup in.z1 @ .
  in.z2 @ .
  cr
;

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
  parse-range r@ in.x2 ! r@ in.x1 !
  [char] , split 2 /string \ y=y1..y2
  parse-range r@ in.y2 ! r@ in.y1 !
  2 /string \ z=z1..z2
  parse-range r@ in.z2 ! r> in.z1 !
;

: parse-input ( -- )
  open-input
  begin next-line?
  while parse-instruction
  repeat
  close-input
;

50 constant GRID_APOTHEM
GRID_APOTHEM 2* 1+ constant GRID_SIDE
GRID_SIDE GRID_SIDE * GRID_SIDE * constant GRID_SIZE

GRID_SIZE allocate throw constant grid
: grid[] ( x y z -- address )
  GRID_APOTHEM + GRID_SIDE dup * *
  swap GRID_APOTHEM + GRID_SIDE * +
  swap GRID_APOTHEM + +
  grid +
;
grid GRID_SIZE 0 fill

: constrained ( i -- i' )
  GRID_APOTHEM 1+ min GRID_APOTHEM negate max
;

: instruction-x-bounds ( i -- end start )
  instruction[] dup in.x2 @ 1+ constrained swap in.x1 @ constrained
;
: instruction-y-bounds ( i -- end start )
  instruction[] dup in.y2 @ 1+ constrained swap in.y1 @ constrained
;
: instruction-z-bounds ( i -- end start )
  instruction[] dup in.z2 @ 1+ constrained swap in.z1 @ constrained
;

: apply-instruction ( i -- )
  dup instruction-z-bounds ?do
    i
    over instruction-y-bounds ?do
      over instruction-x-bounds ?do
        over instruction[] in.on? @
        over i j rot grid[] c!
      loop
    loop
    drop
  loop
  drop
;
: apply-instructions ( -- )
  instructions-bounds do
    i apply-instruction
  loop
;

: print-instructions ( -- )
  instructions-bounds do
    i instruction[] instruction. cr
  loop
;

: count-active-cells ( -- u )
  0
  GRID_SIZE 0 do
    i grid + c@ if 1+ then
  loop
;

: run ( -- )
  parse-input
  \ print-instructions
  apply-instructions
  count-active-cells . cr
;
run
instructions destroy-vec
grid free throw
bye