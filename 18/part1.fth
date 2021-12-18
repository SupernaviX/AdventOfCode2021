include ../utils.fth

create expr buf allot
32 expr init-buf
: expr[] ( i -- expr ) expr buf[] ;
: push-term ( c -- )
  1 expr reserve-buf-space c!
;
: insert-term ( c i -- )
  1 expr insert-buf-region c!
;

254 constant PAIR_START
255 constant PAIR_END
: is-number? ( char -- ? ) PAIR_START < ;

: replace-pair-with-0 ( start -- )
  dup 1+ 3 expr remove-buf-region
  0 swap expr[] c!
;
: replace-number-with-pair ( number i -- )
  1+ 3 expr insert-buf-region 1-
  PAIR_START over c!
  PAIR_END over 3 + c!
  over 2/ over 1+ c!
  swap 1+ 2/ swap 2 + c!
;

: push-expression' ( c-addr u -- c-addr u )
  over c@ [char] [ = if \ if it's the start of a pair
    PAIR_START push-term \ add a "pair start"
    1 /string \ swallow the "["
    recurse \ add the first element
    1 /string \ swallow the ","
    recurse \ add the second element
    PAIR_END push-term \ add a "pair end"
    1 /string \ swallow the "]"
  else
    0 0 2swap >number 2swap drop \ parse the next number out of the string
    push-term \ and push it into the list
  then
;
: push-expression ( c-addr u -- ) push-expression' 2drop ;

: add-number-before ( number i -- )
  0 swap 1- ?do
    i expr[] c@ dup is-number? if
      + i expr[] c!
      unloop exit
    else drop
    then
  -1 +loop
  drop
;
: add-number-after ( number i -- )
  expr buf>size swap 1+ ?do
    i expr[] c@ dup is-number? if
      + i expr[] c!
      unloop exit
    else drop
    then
  loop
  drop
;

: explode? ( -- kaboom? )
  0 \ depth
  expr buf>size 0 ?do
    i expr[] c@
    case
      PAIR_START of 1+ endof
      PAIR_END of 1- endof
    endcase
    dup 4 > if
      i 1 + dup expr[] c@ swap add-number-before
      i 2 + dup expr[] c@ swap add-number-after
      i replace-pair-with-0
      drop true unloop exit
    then
  loop
  \ if we reach the end, depth is 0 which is false
;

: split? ( -- kasplit? )
  expr buf>size 0 ?do
    i expr[] c@ dup is-number? if
      dup 9 > if
        i replace-number-with-pair
        true unloop exit
      else drop
      then
    else drop
    then
  loop
  false
;

: print-expression ( -- )
  expr buf>size 0 do
    i expr[] c@
    case
      PAIR_START of [char] [ emit space endof
      PAIR_END of [char] ] emit space endof
      dup .
    endcase
  loop cr
;

: reduce-expression ( -- )
  begin
    explode?
    ?dup =0 if split? then
    =0
  until
;

: add-expression ( c-addr u -- )
  PAIR_START 0 insert-term
  push-expression
  PAIR_END push-term
  reduce-expression
;

: compute-magnitude' ( i -- u i' )
  dup expr[] c@ dup is-number? if
    \ magnitude is that number, i' is i + 1
    swap 1+
  else
    drop \ must be PAIR_START
    1+ recurse ( uleft i' )
    recurse ( uleft uright i' )
    rot 3 * rot 2* + ( i' mag )
    swap 1+ \ must be PAIR_END at the end
  then
;
: compute-magnitude ( -- u )
  0 compute-magnitude' drop
;

: parse-input ( -- )
  open-input
  next-line push-expression
  begin next-line?
  while add-expression
  repeat
  close-input
;
: run ( -- )
  parse-input
\  print-expression
  compute-magnitude .
;
run
expr destroy-buf
bye