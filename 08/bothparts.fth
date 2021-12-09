include ../utils.fth



10 2array inputs \ first cell is length, second is segment bitmask
: input-segment# ( i -- u ) inputs @ ;
: input-mask ( i -- u ) inputs cell + @ ;
10 array digit-mappings \ index is digit in input, value is digit in solution
10 array reverse-digit-mappings \ index is digit in solution, value is digit in input

\ convert a string of ABCDEFG into a bitmask for convenient storage
: string-to-mask ( c-addr u -- u mask )
  tuck 0 -rot 0 do ( u mask c-addr )
    dup 1+ -rot \ store next addr for later
    c@ [char] a - \ get an index for the segment
    1 swap lshift \ turn it into a bit
    + swap \ and add it to the mask
  loop
  drop
;

: process-input ( c-addr u address -- )
  >r string-to-mask r> 2!
;

: track-mapping ( input-index solution-index )
  2dup reverse-digit-mappings !
  swap digit-mappings !
;

: clear-old-mappings ( -- )
  10 0 do
    -1 i reverse-digit-mappings !
    -1 i digit-mappings !
  loop
;

: is-unmapped? ( i -- ? )
  digit-mappings @ -1 =
;

: find-by-segment# ( count -- i )
  10 0 do
    i is-unmapped? if
      i input-segment# over = if drop i leave then
    then
  loop
;

: find-by-mask ( mask -- i )
  10 0 do
    i input-mask over = if drop i leave then
  loop
;

: find-by-segment#-and-submask ( count mask -- i )
  10 0 do
    i is-unmapped? if
      over i input-segment# = if  \ find something with the right # of segments
        i input-mask over and over = if \ that is a superset of the mask
          2drop i leave
        then
      then
    then
  loop
;

: find-8 ( -- i ) 7 find-by-segment# ;
: find-1 ( -- i ) 2 find-by-segment# ;
: find-4 ( -- i ) 4 find-by-segment# ;
: find-7 ( -- i ) 3 find-by-segment# ;

: find-3 ( -- i )
  5 7 reverse-digit-mappings @ input-mask
  find-by-segment#-and-submask \ something with 5 segments that's a superset of 7
;

: find-9 ( -- i )
  7 reverse-digit-mappings @ input-mask \ mask for 7
  4 reverse-digit-mappings @ input-mask or \ + mask for 4
  6 swap find-by-segment#-and-submask \ with 6 segments and that submask
;

: find-5 ( -- i )
  9 reverse-digit-mappings @ input-mask \ mask for 9
  1 reverse-digit-mappings @ input-mask invert and \ - mask for 1
  5 swap find-by-segment#-and-submask \ has 5 segments and that submask
;

: find-2 ( -- i ) 5 find-by-segment# ;

: find-6 ( -- i )
  5 reverse-digit-mappings @ input-mask
  6 swap find-by-segment#-and-submask \ has 6 segments and contains 5
;

: find-0 ( -- i ) 6 find-by-segment# ;

: solve-line ( -- )
  clear-old-mappings
  find-8 8 track-mapping
  find-1 1 track-mapping
  find-4 4 track-mapping
  find-7 7 track-mapping
  find-3 3 track-mapping
  find-9 9 track-mapping
  find-5 5 track-mapping
  find-2 2 track-mapping
  find-6 6 track-mapping
  find-0 0 track-mapping
;

: translate-number ( c-addr u -- n )
  string-to-mask nip
  10 0 do
    i input-mask over = if
      i digit-mappings @ nip leave
    then
  loop
;


variable simple-digit-count
0 simple-digit-count !
: is-simple? ( n -- ? )
  dup 1 =
  over 4 = or
  over 7 = or
  swap 8 = or
;

variable sum-of-outputs
0 sum-of-outputs !

: translate-rest ( c-addr u -- )
  bl split 2drop \ throw out bar
  0 -rot
  4 0 do
    bl split translate-number
    dup is-simple?
      if 1 simple-digit-count +!
      then
    >r rot 10 * r> + -rot 
  loop
  2drop sum-of-outputs +!
;

: process-line ( c-addr u -- )
  10 0 do
    bl split i inputs process-input
  loop
  solve-line
  translate-rest
;

: run ( -- )
  open-input
  begin next-line?
  while process-line
  repeat
  close-input
;

run
." Part 1 answer: " simple-digit-count @ . cr
." Part 2 answer: " sum-of-outputs @ . cr
bye