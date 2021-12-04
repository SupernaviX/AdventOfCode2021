: parse-number? ( c-addr u -- n ? ) s>number? nip ;
: parse-number ( c-addr u -- n )
  parse-number? =0
    if ." Invalid number " 412 throw
    then
;

: array ( n -- )
  create cells allot 
  does> ( i -- addr ) swap cells +
;
