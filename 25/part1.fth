include ../utils.fth

create grid buf allot
90 grid init-buf

0 constant NONE
1 constant EAST
2 constant SOUTH
4 constant MOVING

variable >grid-width
variable >grid-height
: grid-width ( -- u ) >grid-width @ ;
: grid-height ( -- u ) >grid-height @ ;
: grid-bounds ( -- end start ) grid-width grid-height * 0 ;

: i>xy ( i -- x y ) grid-width /mod ;
: xy>i ( x y -- i ) grid-width * + ;

: grid[i] ( i -- address ) grid buf[] ;
: grid[xy] ( x y -- address ) xy>i grid[i] ;

: grid. ( -- )
  grid-height 0 do
    grid-width 0 do
      i j grid[xy] c@ case
        NONE of ." ." endof
        EAST of ." >" endof
        SOUTH of ." v" endof
        ( default ) ." ?"
      endcase
    loop
    cr
  loop
;

: parse-input ( -- )
  open-input
  0 >grid-height !
  begin next-line?
  while
    dup >grid-width !
    1 >grid-height +!
    0 do
      dup c@ case
        [char] . of NONE endof
        [char] > of EAST endof
        [char] v of SOUTH endof
      endcase 1 grid reserve-buf-space c!
      1+
    loop
    drop
  repeat
  close-input
;

: east-of ( i -- i ) i>xy swap 1+ grid-width mod swap xy>i ;
: south-of ( i -- i ) i>xy 1+ grid-height mod xy>i ;

: apply-movement ( -- )
  grid-bounds do
    i grid[i] c@ MOVING and if
      i grid[i] c@ MOVING invert and case
        EAST of EAST i east-of grid[i] c! endof
        SOUTH of SOUTH i south-of grid[i] c! endof
      endcase
      NONE i grid[i] c!
    then
  loop
;
: step ( -- done? )
  true
  \ move east
  grid-bounds do
    i grid[i] c@ EAST = if
      i east-of grid[i] c@ NONE = if
        EAST MOVING or i grid[i] c! \ set a "moving" flag
        drop false
      then
    then
  loop
  apply-movement
  \ move south
  grid-bounds do
    i grid[i] c@ SOUTH = if
      i south-of grid[i] c@ NONE = if
        SOUTH MOVING or i grid[i] c! \ set a "moving" flag
        drop false
      then
    then
  loop
  apply-movement
;

: solve ( -- u )
  0
  begin
    1+
    step
  until
;

: run ( -- )
  parse-input
  solve .
;
run
grid destroy-buf
bye