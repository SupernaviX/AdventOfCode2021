s" ./input" r/o open-file throw constant input

80 constant inputbuf#
create inputbuf inputbuf# allot

: parse-number? ( c-addr u -- n ? ) s>number? nip ;
: next-number ( -- n more? )
  inputbuf inputbuf# input read-line throw
    if inputbuf swap parse-number?
    else drop false
    then
;

variable prev
variable total
0 total !
: run
  next-number =0 if throw then prev !
  begin next-number
  while
    dup prev @ > if 1 total +! then
    prev !
  repeat
;

run
." solution: " total @ .
bye
