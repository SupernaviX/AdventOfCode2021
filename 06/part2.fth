include ../utils.fth

9 2array fish-by-timer

: parse-initial-fish ( c-addr u -- )
  9 0 do
    0 0 i fish-by-timer 2!
  loop
  begin
    [char] , split parse-number ( c-addr u num )
    fish-by-timer 1 swap +!
    dup =0
  until
  2drop
;

: process-input
  open-input
  next-line parse-initial-fish
  close-input
;

: tick ( -- )
  0 fish-by-timer 2@ 2>r
  1 fish-by-timer 0 fish-by-timer 16 cells move \ everything above 0 ticks down
  2r@ 8 fish-by-timer 2!  \ for every fish that was at 0, add a new fish
  6 fish-by-timer 2@ 2r> d+ 6 fish-by-timer 2! \ and also move those fish back to 6
;

: print-fish ( -- )
  9 0 do
    i . i fish-by-timer 2@ d. cr
  loop
;

: tick-times ( -- ) 0 do tick loop ;

: sum-fish ( -- n )
  0 0
  9 0 do
    i fish-by-timer 2@ d+
  loop
;

: run
  process-input
  256 tick-times
  print-fish
;

run
." solution: " sum-fish d.
bye