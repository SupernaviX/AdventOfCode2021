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

: read-literal ( -- u )
  0
  begin
    4 lshift
    5 read-bits
    dup 15 and rot or
    swap 4 rshift =0
  until
;

: read-operator-packets ( -- )
  11 read-bits \ number of packets
  begin ?dup
  while read-packet 1-
  repeat
;

: read-operator-bits ( -- )
  15 read-bits \ number of bits
  >bits @ + \ target bit count
  begin >bits @ over <>
  while read-packet
  repeat
  drop
;

: read-operator ( -- )
  1 read-bits
    if read-operator-packets
    else read-operator-bits
    then
;

: read-unknown ( -- )
  3 read-bits version-sum +!
  3 read-bits 4 =
    if read-literal drop
    else read-operator
    then
;
' read-unknown is read-packet

: run ( -- )
  parse-input
  read-packet
  version-sum @ .
;

run
bits destroy-vec
bye