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

: average-crab ( -- position )
  0
  crabs vec>size 0 ?do
    i crabs vec[] @ +
  loop
  crabs vec>size /
;

: cost-to-travel ( distance -- cost )
  dup 1+ * 2/
;

: distance-needed ( position -- distance )
  0 ( position total )
  crabs vec>size 0 ?do
    over i crabs vec[] @ - abs cost-to-travel +
  loop
;

variable smallest-found
: smallest-distance-needed ( -- distance )
  1 30 lshift smallest-found !
  crabs vec>size 1- crabs vec[] @ 0 ?do
    i distance-needed
    smallest-found @ min smallest-found !
  loop
  smallest-found @
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
." distance needed: " average-crab distance-needed .
crabs destroy-vec
bye