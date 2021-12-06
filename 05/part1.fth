include ../utils.fth

struct
  cell field line.x1
  cell field line.y1
  cell field line.x2
  cell field line.y2
  cell field line.dx
  cell field line.dy
end-struct line
create lines vec allot
line lines init-vec

: gcd ( a b -- gcd )
  ?dup =0 if abs exit then
  tuck mod recurse
;

: compute-delta ( line -- )
  >r
  r@ line.x2 @ r@ line.x1 @ - \ total difference in x
  r@ line.y2 @ r@ line.y1 @ - \ total difference in y
  2dup gcd tuck
  / r@ line.dy !
  / r> line.dx !
;

: extract-number ( c-addr u -- c-addr u n )
  0 0 2swap >number 2swap drop
;

: parse-coords ( c-addr u -- )
  lines append-vec-item >r
  extract-number r@ line.x1 !
  1 /string \ ignore ","
  extract-number r@ line.y1 !
  4 /string \ ignore " -> "
  extract-number r@ line.x2 !
  1 /string \ ignore ","
  parse-number r@ line.y2 !
  r> compute-delta
;

: process-input ( -- )
  open-input
  begin next-line?
  while parse-coords
  repeat
  close-input
;

create points buf allot
variable x-max
variable y-max

: init-points ( -- )
  lines vec>size 0 do
    i lines vec[]
    dup line.x1 @ over line.x2 @ max x-max @ max x-max !
    dup line.y1 @ swap line.y2 @ max y-max @ max y-max !
  loop
  x-max @ 1+ y-max @ 1+ * points init-zeroed-buf
;

: point-addr ( x y -- address )
  x-max @ 1+ * + points buf.data @ +
;

: fill-in-point ( x y -- )
  point-addr dup c@ 1+ swap c!
;

: increment ( x y dx dy -- x' y' )
  rot + -rot + swap
;

: horizontal-or-vertical? ( line -- ? )
  dup line.dx @ =0
  swap line.dy @ =0 or
;

: fill-in-line ( line -- )
  >r
  r@ line.x2 @ r@ line.y2 @
  r@ line.x1 @ r@ line.y1 @
  2dup fill-in-point
  begin 2over 2over d<>
  while
    r@ line.dx @ r@ line.dy @ increment
    2dup fill-in-point
  repeat
  2drop 2drop
  r> drop
;

: fill-in-lines ( -- )
  lines vec>size 0 do
    i lines vec[] dup horizontal-or-vertical?
      if fill-in-line
      else drop
      then
  loop
;

: score-points ( -- n )
  0
  points buf>size 0 do
    i points buf[] c@ 1 >
      if 1+
      then
  loop
;

: run
  process-input
  init-points
  fill-in-lines
;

run
." score: " score-points .
lines destroy-vec
points destroy-buf
bye