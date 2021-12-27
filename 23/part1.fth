include ../utils.fth

struct
  cell field s.cost
  2 4 * field s.rooms
  7 field s.hallways
  aligned
end-struct state

: hallway[] ( i state -- address ) s.hallways + ;
: hallway-bounds ( -- end start ) 7 0 ;
: all-hallway-bounds ( -- end start ) 11 0 ;
: room[] ( i room state -- address ) s.rooms -rot 2* + + ;
: room[]-back ( room state -- address ) 0 -rot room[] ;
: room[]-front ( room state -- address ) 1 -rot room[] ;
: room-bounds ( -- end start ) 4 0 ;

: tile. ( c -- )
  case
    0 of ." ." endof
    1 of ." A" endof
    2 of ." B" endof
    3 of ." C" endof
    4 of ." D" endof
    ( default ) ." ?"
  endcase
;

: state. ( state -- )
  ." #############" cr
\  ." #" hallway-bounds do i over hallway[] c@ hallway-tile. loop ." #" cr
    ." #"
    2 0 do i over hallway[] c@ tile. loop
    6 2 do ." ." i over hallway[] c@ tile. loop
    6 over hallway[] c@ tile.
    ." #" cr
  ." ###" room-bounds do i over room[]-front c@ tile. ." #" loop ." ##" cr
  space space ." #" room-bounds do i over room[]-back c@ tile. ." #" loop cr
  space space ." #########" cr
  drop
;

\ equality ignores count
: state= ( s1 s2 -- ? )
  2dup s.rooms 2@ rot s.rooms 2@ d= -rot
  s.hallways 2@ rot s.hallways 2@ d= and
;
: state-hash ( state -- hash )
  dup s.rooms 2@ hash+
  swap s.hallways 2@ dhash+
;

: is-solution? ( state -- ? )
  hallway-bounds do
    i over hallway[] c@ if
      drop false unloop exit
    then
  loop
  2 0 do
    room-bounds do
      dup j i rot room[] c@ i 1+ <> if
        drop false unloop unloop exit
      then
    loop
  loop
  true
;

create states heap allot
: cost-of ( state -- d ) s.cost @ 0 ;
state ' cost-of states init-heap

create visited hashset allot
' state-hash ' state= state visited init-hashset

: current-state ( -- state ) 0 states vec[] ;
: current-room[]-back ( room -- val ) current-state room[]-back c@ ;
: current-room[]-front ( room -- val ) current-state room[]-front c@ ;
: current-hallway[] ( i -- val ) current-state hallway[] c@ ;

: parse-amphipod ( c -- a )
  case
    [char] A of 1 endof
    [char] B of 2 endof
    [char] C of 3 endof
    [char] D of 4 endof
    ( default ) 0 swap
  endcase
;
: parse-room-amphipods ( c-addr u -- first second third fourth )
  3 /string over c@ parse-amphipod -rot
  2 /string over c@ parse-amphipod -rot
  2 /string over c@ parse-amphipod -rot
  2 /string over c@ parse-amphipod -rot
  2drop
;

: parse-hallway-amphipods ( c-addr u -- a b c d e f g )
  1 /string over c@ parse-amphipod -rot
  1 /string over c@ parse-amphipod -rot
  2 /string over c@ parse-amphipod -rot
  2 /string over c@ parse-amphipod -rot
  2 /string over c@ parse-amphipod -rot
  2 /string over c@ parse-amphipod -rot
  1 /string over c@ parse-amphipod -rot
  2drop
;

: parse-input ( -- )
  open-input
  next-line 2drop \ skip empty top row
\  next-line 2drop \ skip empty hallway
  states push-heap-item-start drop
  next-line parse-hallway-amphipods
  hallway-bounds swap 1- do
    i current-state hallway[] c!
  -1 +loop
  0 1 do
    next-line parse-room-amphipods
    room-bounds swap 1- do
      j i current-state room[] c!
    -1 +loop
  -1 +loop
  0 current-state s.cost !
  states push-heap-item-done
  close-input
;

: hallway-energy ( i -- u ) 1 swap 0 ?do 10 * loop ;
: amphipod-energy ( i -- u ) 1- hallway-energy ;

: outside-room? ( i -- ? )
  dup 2 =
  over 4 = or
  over 6 = or
  swap 8 = or
;
: hallway-index ( i -- i true | false )
  case
    0 of 0 true endof
    1 of 1 true endof
    2 of false endof
    3 of 2 true endof
    4 of false endof
    5 of 3 true endof
    6 of false endof
    7 of 4 true endof
    8 of false endof
    9 of 5 true endof
    10 of 6 true endof
  endcase
;
: room-hallway ( i -- i ) 1+ 2* ;

: inclusive-bounds ( i1 i2 -- end start ) 2dup > if swap then 1+ swap ;

: hallway-has? ( type i -- )
  hallway-index
    if current-hallway[] =
    else =0
    then
;

: hallway-clear? ( i -- ? ) 0 swap hallway-has? ;
: hallways-clear? ( i1 i2 -- )
  inclusive-bounds do
    i hallway-clear? =0 if false unloop exit then
  loop
  true
;

: room-complete? ( room -- ? )
  dup current-room[]-front over 1+ =
  over current-room[]-back rot 1+ = and
;

: can-leave-room? ( hallway room -- ? )
  dup current-room[]-front =0 if
    \ can't leave a room, there's nobody to leave
    2drop false exit
  then
  dup room-complete? if
    \ cannae leave the room, it's done
    2drop false exit
  then
  room-hallway hallways-clear?
;
: can-enter-room? ( hallway room -- ? )
  dup current-room[]-front if
    \ cannae enter the room, someone else is in front
    2drop false exit
  then
  2dup 1+ swap hallway-has? =0 if
    \ cannae enter the room, we aren't the right type
    2drop false exit
  then
  over swap ( hallway hallway room )
  room-hallway inclusive-bounds do
    i over <> i hallway-clear? =0 and if
      drop unloop false exit
    then
  loop
  drop true
;
: can-go-straight-to-own-room? ( startroom -- ? )
  dup current-room[]-front =0 if
    \ cannae leave the room, there's nobody to leave
    drop false exit
  then
  dup current-room[]-front 1- ( startroom endroom )
  2dup = if
    \ this is my room, it was made for me
    2drop false exit
  then
  dup current-room[]-front if
    \ can't dash over now because someone is waiting to leave the end room
    2drop false exit
  then
  room-hallway swap room-hallway hallways-clear?
;

: hallway-room-distance ( hallway room -- u ) room-hallway - abs 1+ ;
: room-room-distance ( room room -- u ) room-hallway swap hallway-room-distance 1+ ;

: try-scooch-out ( room state -- )
  2dup room[]-back c@ >r
  over 1+ r@ = r@ =0 or if
    \ don't scooch out if we belong here, or if we are empty
    2drop r> drop exit
  then
  2dup room[]-back 0 swap c!
  tuck room[]-front r@ swap c!
  r> amphipod-energy swap s.cost +!
;

: try-scooch-in ( room state -- )
  2dup room[]-back c@ if
    \ don't scooch in if something else is already here
    2drop exit
  then
  2dup room[]-front c@ >r
  2dup room[]-front 0 swap c!
  tuck room[]-back r@ swap c!
  r> amphipod-energy swap s.cost +!
;

: leave-room ( hallway room state -- )
  -rot 2dup hallway-room-distance >r rot \ store distance multiplier for later
  2dup room[]-front c@ >r           \ store moving type for later
  2dup room[]-front 0 swap c!
  rot hallway-index drop over hallway[] r@ swap c! ( room state )
  r> amphipod-energy r> * over s.cost +!
  try-scooch-out \ make the fella behind us in the room move to the front
;

: enter-room ( hallway room state -- )
  -rot 2dup hallway-room-distance >r rot \ store distance multiplier for later
  rot hallway-index drop over hallway[] dup c@ >r \ store moving type for later
  0 swap c! ( room state )
  2dup room[]-front r@ swap c!
  r> amphipod-energy r> * over s.cost +!
  try-scooch-in \ if we can, squeeze in there
;

: go-straight-to-own-room ( room state -- )
  2dup room[]-front c@ 1- -rot ( toroom fromroom state )
  -rot 2dup room-room-distance >r rot \ store distance multiplier for later
  2dup room[]-front c@ >r             \ store moving type for later
  2dup room[]-front 0 swap c! \ leave the room
  swap over try-scooch-out ( toroom state )
  2dup room[]-front r@ swap c!
  r> amphipod-energy r> * over s.cost +!
  try-scooch-in
;

: validate-state ( state -- )
  0
  room-bounds do
    over i swap room[]-front c@ +
    over i swap room[]-back c@ +
  loop
  hallway-bounds do
    over i swap hallway[] c@ +
  loop
  20 <> if
    ." WEE WOO " cr
    current-state state.
    over state.
    100 throw
  then
  drop
;

: create-successor-start ( -- address )
  states push-heap-item-start
  current-state over state move
;
: create-successor-done ( address -- )
  drop \ validate-state
  states push-heap-item-done
;

variable max-state
-1 max-state !
: generate-successors ( -- )
  current-state visited add-hashset-item =0 if
    exit
  then
\  current-state s.cost @ max-state @ > if
\    ." Max cost so far: " current-state s.cost @ . cr
\    current-state s.cost @ max-state !
\    current-state state.
\  then
  room-bounds do
    i can-go-straight-to-own-room? if
      create-successor-start
      i over go-straight-to-own-room
      create-successor-done
      unloop exit
    then
  loop
  all-hallway-bounds do
    i outside-room? =0 if
      room-bounds do
        j i can-enter-room? if
          create-successor-start
          dup j i rot enter-room
          create-successor-done
          unloop unloop exit
        then
        j i can-leave-room? if
          create-successor-start
          dup j i rot leave-room
          create-successor-done
        then
      loop
    then
  loop
;

: solve-puzzle ( -- )
  begin current-state is-solution? =0
  while
    generate-successors
    states pop-heap drop
    states vec>size =0 if
      ." oh shit " cr
      69 throw
    then
  repeat
;

: run ( -- )
  parse-input
  solve-puzzle
  current-state is-solution? if
    current-state s.cost @ . cr
  else ." SHIT " cr
  then
;
run
states destroy-heap
bye