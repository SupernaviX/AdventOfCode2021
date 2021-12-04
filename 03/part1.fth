include ../utils.fth

12 constant digits
digits array 1s-seen

variable items
0 items !

: count-1s ( c-addr u -- )
  0 do
    dup c@ [char] 1 =
      if 1 i 1s-seen +!
      then
    1+
  loop
  drop
;

: process-input ( -- )
  open-input
  begin next-line
  while
    1 items +!
    count-1s
  repeat
  close-input
;

variable gamma
variable epsilon
0 gamma !
0 epsilon !

: push-1 ( -- )
  gamma @ 2* 1+ gamma !
  epsilon @ 2* epsilon !
;

: push-0 ( -- )
  gamma @ 2* gamma !
  epsilon @ 2* 1+ epsilon !
;

: compute-gamma-and-epsilon ( -- )
  digits 0 do
    i 1s-seen @ items @ 1 rshift >
      if push-1
      else push-0
      then
  loop
;

: run
  process-input
  compute-gamma-and-epsilon
;
run
." gamma: " gamma @ .
." epsilon: " epsilon @ .
." solution: " gamma @ epsilon @ * .
bye