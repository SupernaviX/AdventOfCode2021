include ../utils.fth

9 array fish-by-timer

: parse-initial-fish ( c-addr u -- )
  9 0 do
    0 i fish-by-timer !
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
  0 fish-by-timer @ >r
  1 fish-by-timer 0 fish-by-timer 8 cells move \ everything above 0 ticks down
  r@ 8 fish-by-timer !  \ for every fish that was at 0, add a new fish
  r> 6 fish-by-timer +! \ and also move those fish back to 6
;

: print-fish ( -- )
  9 0 do
    i . i fish-by-timer @ . cr
  loop
;

: tick-times ( -- ) 0 do tick loop ;

: sum-fish ( -- n )
  0
  9 0 do
    i fish-by-timer @ +
  loop
;

: run
  process-input
  80 tick-times
;

run
." solution: " sum-fish .
bye