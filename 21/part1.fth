include ../utils.fth

: wrap-at ( u max -- u )
  begin 2dup >
  while tuck - swap
  repeat
  drop
;
struct
  cell field p.pos
  cell field p.score
end-struct player
: init-player ( position address -- )
  0 over p.score !
  p.pos !
;
: move-player ( spaces player -- )
  tuck p.pos @ + 10 wrap-at swap ( pos player )
  2dup p.score +! p.pos !
;
: player-won? ( player -- ? ) p.score @ 1000 >= ;

create p1 player allot
create p2 player allot

: parse-input ( -- )
  open-input
  \ Input looks like "Player 1 starting position: 4"
  next-line 28 /string parse-number p1 init-player
  next-line 28 /string parse-number p2 init-player
  close-input
;

variable diestate
1 diestate !
variable rollcount
0 rollcount !
: roll ( -- u )
  1 rollcount +!
  diestate @
  dup 1+ 100 wrap-at diestate !
;

: take-turn ( player -- win? )
  roll roll + roll + \ get the total number of spaces to move
  over move-player
  player-won?
;

: play-game ( -- )
  begin p1 take-turn =0
  while p2 take-turn =0
  while repeat then
;

: compute-answer ( -- u )
  p1 p.score @ p2 p.score @ min rollcount @ *
;

: run ( -- )
  parse-input
  play-game
  compute-answer . cr
;
run
bye