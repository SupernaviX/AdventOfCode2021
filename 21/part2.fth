include ../utils.fth

: wrap-at ( u max -- u )
  begin 2dup >
  while tuck - swap
  repeat
  drop
;

struct
  buf field p.states
  2 cells field p.wins
  2 cells field p.ongoing
end-struct player

: p.state[i] ( i player -- address ) swap 2* cells swap p.states buf[] ;
: p.state[ps] ( position score player -- address )
  >r 4 lshift or r> p.state[i]
;

: init-player ( start address -- )
  >r
  0 0 r@ p.wins 2!
  1 0 r@ p.ongoing 2!
  512 2* cells r@ p.states init-zeroed-buf
  1 0 rot 0 r> p.state[ps] 2!
;
: destroy-player ( address -- )
  p.states destroy-buf
;

create p1 player allot
create p2 player allot
create scratch player allot
1 scratch init-player

: parse-input ( -- )
  open-input
  \ Input looks like "Player 1 starting position: 4"
  next-line 28 /string parse-number p1 init-player
  next-line 28 /string parse-number p2 init-player
  close-input
;

variable current-player
p1 current-player !
variable other-player
p2 other-player !

: swap-turn ( -- )
  current-player other-player swap-cells
;

\ every round, we can compute:
\   the various states a player can be in, purely by their own rolls
\ so,
\   roll the dice for player 1
\     multiply the states WHERE THEY WIN by the states P2 HAS BEEN IN
\     add that to p1's victory count
\   swap players and repeat

: advance ( position score roll -- position' score' )
  rot + 10 wrap-at ( score position' )
  tuck + ( position' score' )
;

: clear-scratch ( -- )
  512 0 do
    0 0 i scratch p.state[i] 2!
  loop
;

: apply-roll ( roll times -- )
  21 0 do
    11 1 do \ i is position, j is score
      over i j rot advance ( roll times position' score' )
      scratch p.state[ps] ( roll times target )
      over i j current-player @ p.state[ps] 2@ rot d* ( roll times target dmore )
      rot 2+! ( roll times )
    loop
  loop
  2drop
;

: copy-scratch ( -- )
  512 0 do
    i scratch p.state[i] 2@ i current-player @ p.state[i] 2!
  loop
;

: move-player ( -- )
  clear-scratch
  3 1 apply-roll
  4 3 apply-roll
  5 6 apply-roll
  6 7 apply-roll
  7 6 apply-roll
  8 3 apply-roll
  9 1 apply-roll
  copy-scratch
;

: collect-wins ( -- )
  32 21 do
    11 1 do \ i is position, j is score
      i j current-player @ p.state[ps] 2@ \ count the number of ways that we reached this win state
      other-player @ p.ongoing 2@ dd* \ times the number of games that went on long enough to do it
      current-player @ p.wins 2+!
      0 0 i j current-player @ p.state[ps] 2!
    loop
  loop
;

: update-ongoing-game-count ( -- )
  0 0
  21 1 do
    11 1 do
      i j current-player @ p.state[ps] 2@ d+
    loop
  loop
  current-player @ p.ongoing 2!
;

: take-turn ( -- done? )
  clear-scratch
  move-player
  collect-wins
  update-ongoing-game-count
  current-player @ p.ongoing 2@ 0 0 d=
  swap-turn
;
: play-game ;
: run ( -- )
  parse-input
  begin take-turn until
  ." P1 wins: " p1 p.wins 2@ d. cr
  ." P2 wins: " p2 p.wins 2@ d. cr
  ." overall winner: " p1 p.wins 2@ p2 p.wins 2@ dmax d. cr
;
run
p1 destroy-player
p2 destroy-player
scratch destroy-player
bye