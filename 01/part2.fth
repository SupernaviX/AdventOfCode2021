s" ./input" r/o open-file throw constant input

80 constant inputbuf#
create inputbuf inputbuf# allot

: next-number ( -- n more? )
  inputbuf inputbuf# input read-line throw
    if inputbuf swap s>number?
    else drop false
    then
;

3 constant window-size
create prevbuffer window-size 1+ cells allot

: window-total ( -- n )
  0
  window-size 0 do
    prevbuffer i cells + @ +
  loop
;
: window-move ( next -- )
  prevbuffer window-size cells + !
  prevbuffer cell + prevbuffer window-size cells move
;

variable total
0 total !

: run
  window-size 0 do
    next-number =0 if throw then
    window-move
  loop
  begin next-number
  while
    window-total swap ( prevtotal number )
    window-move window-total ( prevtotal newtotal )
    < if 1 total +! then
  repeat
;

run
." solution: " total @ .
bye
