include ../utils.fth

12 constant digits

variable items
: count-items ( -- n )
  0 items !
  open-input
  begin next-line?
  while 1 items +! 2drop
  repeat
  close-input
;
count-items

items @ array ratings
items @ array is-candidate?

: populate-ratings ( -- )
  open-input
  items @ 0 do
    next-line
    binary parse-number decimal i ratings !
  loop
  close-input
;
: reset-ratings ( -- )
  items @ 0 do
    -1 i is-candidate? !
  loop
;

: nth-digit ( cell i -- 0 | 1 )
  digits 1- swap - rshift 1 and \ digit 0 in a 3-digit number -> shift by 2
;

variable 0s
variable 1s
: find-most-common-digit ( digit -- 0 | 1 )
  0 0s ! 0 1s !
  items @ 0 do
    i is-candidate? @ if
      i ratings @ over nth-digit
        if 1 1s +!
        else 1 0s +!
        then
    then
  loop
  drop
  0s @ 1s @ <=
    if 1 \ on a tie, 1 is most common
    else 0
    then
;

variable matches
: eliminate-the-unviable ( desired-value digit -- wegood? )
  0 matches !
  items @ 0 do
    i is-candidate? @ if
      2dup i ratings @ swap nth-digit =
        if 1 matches +!
        else 0 i is-candidate? !
        then
    then
  loop
  2drop
  matches @ 1 =
;

: whatever-is-left ( -- rating )
  items @ 0 do
    i is-candidate? @ if
      i ratings @ leave
    then
  loop
;

: bitflip ( 1 or 0 -- 0 or 1 )
  if 0 else 1 then
;

variable o2
variable co2
: run ( -- )
  populate-ratings
  reset-ratings
  digits 0 do
    i find-most-common-digit
    i eliminate-the-unviable
    if
      whatever-is-left o2 !
      leave
    then
  loop
  reset-ratings
  digits 0 do
    i find-most-common-digit bitflip
    i eliminate-the-unviable
    if
      whatever-is-left co2 !
      leave
    then
  loop
;

run
." o2: " o2 @ .
." co2: " co2 @ .
." solution: " o2 @ co2 @ * .
bye