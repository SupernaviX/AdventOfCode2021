include ../utils.fth

struct
  cell field s.cond
  cell field s.plus
  cell field s.drop?
end-struct step

create steps vec allot
step steps init-vec
: step[] ( i -- step ) steps vec[] ;
: step-bounds ( -- end start ) 14 0 ;

: parse-step ( address -- )
  next-line 2drop \ "inp w"
  next-line 2drop \ "mul x 0"
  next-line 2drop \ "add x z"
  next-line 2drop \ "mod x 26"
  next-line       \ either "div z 1" or "div z 26"
    s" div z 26" str= over s.drop? !
  next-line       \ "add x <cond>"
    6 /string parse-number over s.cond !
  next-line 2drop \ "eql x w"
  next-line 2drop \ "eql x 0"
  next-line 2drop \ "mul y 0"
  next-line 2drop \ "add y 25"
  next-line 2drop \ "mul y x"
  next-line 2drop \ "add y 1"
  next-line 2drop \ "mul z y"
  next-line 2drop \ "mul y 0"
  next-line 2drop \ "add y w"
  next-line       \ "add y <plus>"
    6 /string parse-number swap s.plus !
  next-line 2drop \ "mul y x"
  next-line 2drop \ "add z y"
;

: parse-input ( -- )
  open-input
  step-bounds do
    steps push-vec-item parse-step
  loop
  close-input
;

struct
  cell field o.term
  cell field o.const
end-struct output

create outputs vec allot
output outputs init-vec

struct
  cell field c.term1
  cell field c.term2
  cell field c.delta
end-struct constraint
: constraint. ( constraint -- )
  dup c.term1 @ [char] A + emit space
  ." = "
  dup c.term2 @ [char] A + emit space
  c.delta @ ?dup if
    dup <0
      if ." - " abs .
      else ." + " .
      then
  then
;

create constraints vec allot
constraint constraints init-vec
: constraint[] ( i -- constraint ) constraints vec[] ;
: constraint-bounds ( -- end start ) constraints vec>size 0 ;

: compute-constraints ( -- )
  step-bounds do
    i step[] s.cond @ >0 if
      \ unconditionally push a digit
      outputs push-vec-item
      i over o.term ! \ for the current step
      i step[] s.plus @ swap o.const ! \ with the step's constant
    else
      \ we MUST drop this digit, add a constraint saying so
      outputs pop-vec-item
      constraints push-vec-item
      i over c.term1 !
      over o.term @ over c.term2 !
      i step[] s.cond @ rot o.const @ + swap c.delta !
    then
  loop
;

create solution 14 allot
: max-valid-number ( -- c-addr u )
  constraint-bounds do
    i constraint[] c.delta @ dup >0
      if 9 9 rot -
      else 9 + 9
      then
    [char] 0 + i constraint[] c.term2 @ solution + c!
    [char] 0 + i constraint[] c.term1 @ solution + c!
  loop
  solution 14
;

: min-valid-number ( -- c-addr u )
  constraint-bounds do
    i constraint[] c.delta @ dup >0
      if 1 + 1
      else 1 1 rot -
      then
    [char] 0 + i constraint[] c.term2 @ solution + c!
    [char] 0 + i constraint[] c.term1 @ solution + c!
  loop
  solution 14  
;
: run ( -- )
  parse-input
  compute-constraints
  ." Max valid number: " max-valid-number type cr
  ." Min valid number: " min-valid-number type cr
;
run
steps destroy-vec
constraints destroy-vec
bye
