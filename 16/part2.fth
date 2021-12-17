include ../utils.fth

create bits vec allot
1 bits init-vec

: parse-input ( -- )
  open-input next-line close-input
  hex
  0 do ( c-addr )
    dup 1 parse-number ( c-addr digit )
    4 0 do
      dup 3 rshift 1 and bits append-vec-item c!
      1 lshift
    loop
    drop 1+
  loop
  drop
  decimal
;

variable >bits
0 >bits !
: read-bits ( n -- u )
  0
  over 0 do
    1 lshift
    i >bits @ + bits vec[] c@ or
  loop
  swap >bits +!
;

variable version-sum
0 version-sum !

defer read-packet

: 4dlshift ( d -- d )
  over 28 rshift
  swap 4 lshift or
  swap 4 lshift swap
;

: read-literal ( -- d )
  0 0
  begin
    4dlshift
    5 read-bits
    dup 4 rshift =0 >r
    15 and rot or swap
    r>
  until
;

: read-operator-packets ( -- packets )
  11 read-bits \ number of packets
  dup >r
  begin ?dup
  while read-packet rot 1-
  repeat
  r>
;

: read-operator-bits ( -- packets )
  15 read-bits \ number of bits
  >bits @ + \ target bit count
  0 swap ( packets target )
  begin >bits @ over <>
  while
    read-packet 2swap
    swap 1+ swap
  repeat
  drop
;

: read-operator ( -- packets )
  1 read-bits
    if read-operator-packets
    else read-operator-bits
    then
;

: p-sum ( packets -- d )
  1- 0 ?do d+ loop
;
: p-product ( packets -- d )
  1- 0 ?do dd* loop
;
: p-min ( packets -- d )
  1- 0 ?do dmin loop
;
: p-max ( packets -- d )
  1- 0 ?do dmax loop
;
: p-> ( packets -- d )
  2 <> if ." Invalid > " 100 throw then
  d> if 1 0 else 0 0 then
;
: p-< ( packets -- d )
  2 <> if ." Invalid < " 100 throw then
  d< if 1 0 else 0 0 then
;
: p-= ( packets -- d )
  2 <> if ." Invalid = " 100 throw then
  d= if 1 0 else 0 0 then
;

: execute-operator ( packets op -- d )
  case
    0 of p-sum endof
    1 of p-product endof
    2 of p-min endof
    3 of p-max endof
    5 of p-> endof
    6 of p-< endof
    7 of p-= endof
  endcase
;

: read-unknown ( -- d )
  3 read-bits version-sum +!
  3 read-bits dup 4 =
    if drop read-literal
    else
      >r
      read-operator
      r> execute-operator
    then
;
' read-unknown is read-packet

: run ( -- )
  parse-input
  read-packet d.
;

run
bits destroy-vec
bye