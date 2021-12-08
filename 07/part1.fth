include ../utils.fth

create crabs vec allot
cell crabs init-vec

: parse-input ( -- )
  open-input
  next-line
  begin dup
  while
    [char] , split parse-number
    crabs append-vec-item !
  repeat
  2drop
  close-input
;

: sort-crabs ( -- )
  crabs buf.data @ crabs vec>size sort-cells
;

: median-crab ( -- position )
  crabs vec>size 2/ crabs vec[] @
;

: distance-needed ( position -- distance )
  0 ( position total )
  crabs vec>size 0 ?do
    over i crabs vec[] @ - abs +
  loop
;

: print-crabs ( -- )
  crabs vec>size 0 ?do
    i crabs vec[] @ .
  loop cr
;

: run ( -- )
  parse-input
  sort-crabs
;

run
." smallest distance needed: "  median-crab distance-needed .
crabs destroy-vec
bye