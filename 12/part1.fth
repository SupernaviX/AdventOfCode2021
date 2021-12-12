include ../utils.fth

create namebuf buf allot
32 namebuf init-buf

create namevec vec allot
cell namevec init-vec
: caves# ( -- u ) namevec vec>size ;

: id>name ( id -- c-addr u )
  namevec vec[] @ \ get the buffer index from namevec
  namebuf buf[] count \ and pull the name from namebuf
;

: name>id ( c-addr u -- id )
  namevec vec>size 0 ?do
    2dup i id>name str= if
      2drop i unloop exit
    then
  loop
  \ add the start index of this string in namevec
  namebuf buf>size namevec append-vec-item !
  dup 1+ namebuf reserve-buf-space \ add space for the string in the buf
  2dup c! 1+ \ the buf entry starts with the one-byte character count
  swap move \ and the rest of it is the character count itself
  namevec vec>size 1- \ plus return the new vec index
;
: is-small-cave? ( id -- ? ) id>name drop c@ lowercase? ;

create adjacency-list vec allot
2 cells adjacency-list init-vec

: track-adjacency ( id1 id2 -- )
  adjacency-list append-vec-item 2!
;

create adjacency-matrix buf allot
: bake-adjacency-matrix ( -- )
  caves# dup * adjacency-matrix init-zeroed-buf
  adjacency-list vec>size 0 do
    i adjacency-list vec[] 2@
    2dup caves# * + adjacency-matrix buf[] 255 swap c!
    swap caves# * + adjacency-matrix buf[] 255 swap c!
  loop
;
: are-adjacent? ( id1 id2 -- ? )
  caves# * + adjacency-matrix buf[] c@ <>0
;

: parse-input ( -- )
  s" start" name>id drop \ "start" is always id 0
  s" end" name>id drop \ "end" is always id 1
  open-input
  begin next-line?
  while
    [char] - split
    name>id >r name>id r>
    track-adjacency
  repeat
  close-input
  bake-adjacency-matrix
;

create seen-stack 1024 allot
variable seen-stack#
0 seen-stack# !

: push-seen ( id -- )
  seen-stack seen-stack# @ + c!
  1 seen-stack# +!
;
: drop-seen ( -- )
  -1 seen-stack# +!
;
: have-seen? ( id -- ? )
  seen-stack# @ 0 ?do
    i seen-stack + c@ over =
      if drop true unloop exit
      then
  loop
  drop false
;

variable paths
0 paths !
: visit ( id -- )
  \ if we have marked this as "seen", don't recurse
  dup have-seen? if drop exit then
  \ if this is a smol cave, we have already "seen" it
  dup is-small-cave? if dup push-seen then
  \ if this is adjacent to an exit, this forms a full path
  dup 1 are-adjacent? if 1 paths +! then
  caves# 1- ( id other )
  begin dup 1 > \ loop over all adjacencies _except_ start and end (0 and 1)
  while
    2dup are-adjacent? if dup recurse then
    1-
  repeat drop
  is-small-cave? if drop-seen then
;

: run ( -- )
  parse-input
  0 visit
  ." Paths to end: " paths @ .
;

run
namebuf destroy-buf
namevec destroy-vec
adjacency-list destroy-vec
adjacency-matrix destroy-buf
bye