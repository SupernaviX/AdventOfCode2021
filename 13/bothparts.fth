include ../utils.fth

create point-list vec allot
2 cells point-list init-vec

struct
  cell field matrix.data
  cell field matrix.w
  cell field matrix.h
end-struct matrix
: matrix[] ( x y matrix -- addr )
  >r
  r@ matrix.w @ * +
  r> matrix.data @ +
;
: matrix@ ( x y matrix -- val ) matrix[] c@ ;
: matrix-on! ( x y matrix -- ) matrix[] 255 swap c! ;

create old-matrix matrix allot
create new-matrix matrix allot

: matrix>size ( matrix -- u )
  dup matrix.w @ swap matrix.h @ *
;

: init-matrix ( w h -- )
  new-matrix matrix.h !
  new-matrix matrix.w !
  new-matrix matrix>size allocate throw
  new-matrix matrix.data !
  new-matrix matrix.data @ new-matrix matrix>size 0 fill
;

: fill-matrix-from-input ( -- )
  point-list vec>size 0 ?do
    i point-list vec[] 2@ ( x y )
    new-matrix matrix-on!
  loop
;

: parse-dots ( -- )
  begin next-line dup
  while
    [char] , split
    parse-number -rot parse-number
    over new-matrix matrix.w @ max new-matrix matrix.w !
    dup new-matrix matrix.h @ max new-matrix matrix.h !
    point-list append-vec-item 2!
  repeat
  2drop
  new-matrix matrix.w @ 1+ new-matrix matrix.h @ 1+ init-matrix
  fill-matrix-from-input
;

: shift-matrix ( -- )
  new-matrix matrix.data @ old-matrix matrix.data !
  new-matrix matrix.w @ old-matrix matrix.w !
  new-matrix matrix.h @ old-matrix matrix.h !
;

: fold-up ( axis -- )
  old-matrix matrix.w @ old-matrix matrix.h @ 2/ init-matrix
  old-matrix matrix.h @ 0 ?do
    i
    old-matrix matrix.w @ 0 ?do ( axis y )
      2dup over - abs - ( axis yold ynew )
      over i swap old-matrix matrix@
        if i swap new-matrix matrix-on!
        else drop
        then
    loop
    drop
  loop
  drop
;

: fold-left ( axis -- )
  old-matrix matrix.w @ 2/ old-matrix matrix.h @ init-matrix
  old-matrix matrix.w @ 0 ?do
    i
    old-matrix matrix.h @ 0 ?do ( axis x )
      2dup over - abs - ( axis xold xnew )
      over i old-matrix matrix@
        if i new-matrix matrix-on!
        else drop
        then
    loop
    drop
  loop
  drop
;

: fold ( c-addr u -- )
  11 /string \ trim "fold along "
  over c@ >r
  2 /string parse-number
  shift-matrix
  r> case
    [char] y of fold-up endof
    [char] x of fold-left endof
  endcase
  old-matrix matrix.data @ free throw
;

: count-dots ( -- u )
  0
  new-matrix matrix>size 0 do
    new-matrix matrix.data @ i + c@ if 1+ then
  loop
;

: print-dots ( -- )
  new-matrix matrix.h @ 0 ?do
    i
    new-matrix matrix.w @ 0 ?do
      i over new-matrix matrix@
        if [char] # emit
        else [char] . emit
        then
    loop
    drop cr
  loop
;

: run ( -- )
  open-input
  parse-dots
  next-line fold
  ." Part 1: " count-dots . cr
  begin next-line?
  while fold
  repeat
  close-input
  print-dots
;

run
new-matrix matrix.data @ free throw
bye