include ../utils.fth

struct
  cell field p.x
  cell field p.y
  cell field p.z
end-struct point
: point. ( point -- )
  ." ("
  dup p.x @ 0 .r
  ." , "
  dup p.y @ 0 .r
  ." , "
  p.z @ 0 .r
  ." ) "
;
: copy-point ( from to -- )
  over p.x @ over p.x !
  over p.y @ over p.y !
  swap p.z @ swap p.z !
;
: point-hash ( p -- d )
  dup p.z @ 65535 and
  over p.y @ 16 lshift or
  swap p.x @ 65535 and
;
: point= ( p1 p2 -- ? )
  point-hash rot point-hash d=
;

: dx ( p1 p2 -- n ) p.x @ swap p.x @ - ;
: |dx| ( p1 p2 -- u ) dx abs ;
: dy ( p1 p2 -- u ) p.y @ swap p.y @ - ;
: |dy| ( p1 p2 -- u ) dy abs ;
: dz ( p1 p2 -- u ) p.z @ swap p.z @ - ;
: |dz| ( p1 p2 -- u ) dz abs ;

: distance ( p1 p2 -- ud )
  2dup |dx| 0
  2over |dy| 0 d+
  2swap |dz| 0 d+
;

32 constant MAX_SCANNER_POINTS
struct
  cell field scanner.size
  cell field scanner.solved
  point field scanner.location
  MAX_SCANNER_POINTS point * field scanner.points
end-struct scanner
: point[] ( i scanner -- address ) scanner.points swap point * + ;

create scanners vec allot
scanner scanners init-vec
: scanner[] ( i -- addr ) scanners vec[] ;

: parse-point ( c-addr u address -- )
  >r
  [char] , split parse-number r@ p.x !
  [char] , split parse-number r@ p.y !
  parse-number r> p.z !
;

: parse-scanner ( -- done? )
  next-line 2drop \ starts with scanner name/number
  scanners append-vec-item >r
  0 r@ scanner.size !
  false r@ scanner.solved !
  0 r@ scanner.location p.x !
  0 r@ scanner.location p.y !
  0 r@ scanner.location p.z !
  begin next-line?
  while ?dup =0
    if r> 2drop false exit
    else
      r@ scanner.size @ r@ point[] parse-point
      1 r@ scanner.size +!
    then
  repeat
  r> drop true
;
: parse-input ( -- )
  open-input
  begin parse-scanner until
  true 0 scanner[] scanner.solved !
  close-input
;

struct
  cell field pair.p1
  cell field pair.p2
  2 cells field pair.hash
end-struct pair
: pair. ( pair -- )
  dup pair.p1 @ point. pair.p2 @ point.
;

: pair-priority ( pair -- ) pair.hash 2@ ;

create leftpairs heap allot
pair ' pair-priority leftpairs init-heap
create rightpairs heap allot
pair ' pair-priority rightpairs init-heap

: sort-pair ( n1 n2 -- nlow nhigh )
  2dup > if swap then
;
: sort-triad ( n1 n2 n3 -- nlow nmid nhigh )
  sort-pair -rot sort-pair rot sort-pair
;

: pair-hash ( p1 p2 -- d )
  2dup |dx| -rot 2dup |dy| -rot |dz| ( dx dy dz )
  sort-triad \ order pieces from lowest to highest
  swap 16 lshift or swap \ combine into one i64
;
: write-pair ( p1 p2 address -- )
  >r 2dup pair-hash ( p1 p2 hash )
  r@ pair.hash 2!
  r@ pair.p2 !
  r> pair.p1 !
;

: collect-pair ( i j scanner heap -- )
  >r r@ push-heap-item-start ( i j scanner address )
  swap >r ( i j address )
  rot r@ point[] rot r> point[] rot ( p1 p2 address )
  write-pair
  r> push-heap-item-done
;

: collect-pairs ( scanner heap -- )
  dup clear-vec
  over scanner.size @ 1 do
    i 0 do
      i j 2over collect-pair
    loop
  loop
  2drop
;

: d-compare ( d1 d2 -- n )
  2over 2over d< >r d> r> swap - 
;
: compare-pairs ( d1 d2 -- n )
  swap pair.hash 2@ rot pair.hash 2@ d-compare
;

struct
  cell field m.s1p1
  cell field m.s1p2
  cell field m.s2p1
  cell field m.s2p2
end-struct match
: m>s1has? ( point m -- ? )
  2dup m.s1p1 @ =
  -rot m.s1p2 @ = or
;
: m>s2has? ( point m -- ? )
  2dup m.s2p1 @ =
  -rot m.s2p2 @ = or
;
create matches vec allot
match matches init-vec
: match[] ( i -- address ) matches vec[] ;

create points vec allot
cell points init-vec

: track-match ( d1 d2 -- )
  matches push-vec-item
  over pair.p2 @ over m.s2p2 !
  swap pair.p1 @ over m.s2p1 !
  over pair.p2 @ over m.s1p2 !
  swap pair.p1 @ swap m.s1p1 !
;

: find-matching-pairs ( -- )
  matches clear-vec
  begin leftpairs vec>size >0 rightpairs vec>size >0 and
  while
    leftpairs peek-heap rightpairs peek-heap
    2dup compare-pairs
    ?dup =0 if
      track-match
      leftpairs pop-heap drop
      rightpairs pop-heap drop
    else
      <0 if
        leftpairs pop-heap drop
      else
        rightpairs pop-heap drop
      then
      2drop
    then
  repeat
  leftpairs clear-vec
  rightpairs clear-vec
;

: try-add-point ( p1 -- )
  points vec>size 0 ?do
    i points vec[] @ over = if
      drop unloop exit
    then
  loop
  points push-vec-item !
;

: find-matched-points ( -- )
  points clear-vec
  matches vec>size 0 ?do
    i matches vec[] m.s1p1 @ try-add-point
    i matches vec[] m.s1p2 @ try-add-point
  loop
;

create matrix 16 cells allot
: matrix[] ( x y -- address ) 2* 2* + cells matrix + ;
: matrix@ ( x y -- value ) matrix[] @ ;
: matrix! ( i x y -- ) matrix[] ! ;
: matrix. ( -- )
  4 0 do
    4 0 do
      i j matrix@ 2 .r space
    loop cr
  loop
;

: reset-matrix ( -- )
  4 0 do
    4 0 do
      0 i j matrix!
    loop
  loop
;

: transform-point ( point -- )
  >r
  0 0 matrix@ r@ p.x @ *
  1 0 matrix@ r@ p.y @ * +
  2 0 matrix@ r@ p.z @ * +
  3 0 matrix@ + ( x )
  0 1 matrix@ r@ p.x @ *
  1 1 matrix@ r@ p.y @ * +
  2 1 matrix@ r@ p.z @ * +
  3 1 matrix@ + ( x y )
  0 2 matrix@ r@ p.x @ *
  1 2 matrix@ r@ p.y @ * +
  2 2 matrix@ r@ p.z @ * +
  3 2 matrix@ + ( x y z )
  r@ p.z !
  r@ p.y !
  r> p.x !
;

: compute-x-orientation ( s1p1 s1p2 s2p1 s2p2 -- )
  dx >r
  2dup dx r@ =        if  1 0 0 matrix! then
  2dup dx negate r@ = if -1 0 0 matrix! then
  2dup dy r@ =        if  1 0 1 matrix! then
  2dup dy negate r@ = if -1 0 1 matrix! then
  2dup dz r@ =        if  1 0 2 matrix! then
  2dup dz negate r@ = if -1 0 2 matrix! then
  2drop r> drop
;
: compute-y-orientation ( s1p1 s1p2 s2p1 s2p2 -- )
  dy >r
  2dup dx r@ =        if  1 1 0 matrix! then
  2dup dx negate r@ = if -1 1 0 matrix! then
  2dup dy r@ =        if  1 1 1 matrix! then
  2dup dy negate r@ = if -1 1 1 matrix! then
  2dup dz r@ =        if  1 1 2 matrix! then
  2dup dz negate r@ = if -1 1 2 matrix! then
  2drop r> drop
;
: compute-z-orientation ( s1p1 s1p2 s2p1 s2p2 -- )
  dz >r
  2dup dx r@ =        if  1 2 0 matrix! then
  2dup dx negate r@ = if -1 2 0 matrix! then
  2dup dy r@ =        if  1 2 1 matrix! then
  2dup dy negate r@ = if -1 2 1 matrix! then
  2dup dz r@ =        if  1 2 2 matrix! then
  2dup dz negate r@ = if -1 2 2 matrix! then
  2drop r> drop
;

create transformed point allot
: compute-translation ( s1p1 s2p1 -- )
  \ copy s2p1 sos it can be transformed without breaking anything
  transformed copy-point
  transformed transform-point
  dup p.x @ transformed p.x @ - 3 0 matrix!
  dup p.y @ transformed p.y @ - 3 1 matrix!
  p.z @ transformed p.z @ - 3 2 matrix!
;

: compute-matrix-from ( s1p1 s1p2 s2p1 s2p2 -- )
  reset-matrix
  2over 2over compute-x-orientation
  2over 2over compute-y-orientation
  2over 2over compute-z-orientation
  drop nip compute-translation
;

: in-s1? ( point -- ? )
  matches vec>size 0 ?do
    i matches vec[] m.s1p1 @ over point= if
      drop true unloop exit
    then
    i matches vec[] m.s1p2 @ over point= if
      drop true unloop exit
    then
  loop
  drop false
;

: find-matched-s2-points ( -- )
  points clear-vec
  matches vec>size 0 ?do
    i matches vec[] m.s2p1 @ try-add-point
    i matches vec[] m.s2p2 @ try-add-point
  loop
;
create testpoint point allot
: validate-matrix ( -- )
  find-matched-s2-points
  points vec>size
  begin ?dup ( i )
  while
    1-
    dup points vec[] @ testpoint copy-point
    testpoint transform-point
    testpoint in-s1? =0 if
      points pop-vec-item drop
    then
  repeat
\  ." matched points left: " points vec>size . cr
  points vec>size 12 >=
;

: compute-matrix-i ( i -- valid? )
  \ start with the s1p1 from the ith match we found  
  dup match[] m.s1p1 @
  \ find another match which also includes this s1p1
  matches vec>size 0 ?do
    over i <> if
      dup i match[] m>s1has? if
        i match[] leave
      then
    then
  loop rot >r ( s1p1 match2 )
  \ whichever s2 from the ith match is in this next match, must match s1p1
  r@ match[] m.s2p1 @ swap m>s2has?
    if r@ match[] m.s2p1 @
    else r@ match[] m.s2p2 @
    then ( s1p1 s2p1 )
  r@ match[] m.s1p2 @ swap ( s1p1 s1p2 s2p1 )
  \ whichever point does NOT match s1p1 must match s1p2
  dup r@ match[] m.s2p1 @ =
    if r@ match[] m.s2p2 @
    else r@ match[] m.s2p1 @
    then ( s1p1 s1p2 s2p1 s2p2 )
  compute-matrix-from
  validate-matrix
  r> drop
;
: compute-matrix ( -- )
  matches vec>size 0 ?do
    i compute-matrix-i if
      unloop exit
    then
  loop
  ." cannot match 12 points from any starting pair... " 69 throw
;

\ assuming that the transformation matrix is already defined
: normalize-scanner ( scanner -- )
  dup scanner.size @ 0 do
    i over point[] transform-point
  loop
  dup scanner.location transform-point
  true swap scanner.solved !
;

: are-neighbors? ( s1 s2 -- ? )
  rightpairs collect-pairs
  leftpairs collect-pairs
  find-matching-pairs
  find-matched-points
  points vec>size 12 >=
;

: scanner-to-index ( scanner -- index )
  scanners buf.data @ - scanners vec.itemsize @ /
;

: try-align ( s1 s2 -- aligned? )
  2dup = if 2drop false exit then
  dup scanner.solved @ if 2drop false exit then
  dup >r
  \ ." comparing " over scanner-to-index . ." and " dup scanner-to-index . cr
  are-neighbors? if
    compute-matrix
    r> normalize-scanner
    true
  else r> drop false
  then
;

create frontier vec allot
cell frontier init-vec

: align-all ( -- )
  0 scanner[] frontier push-vec-item !
  begin frontier vec>size
  while
    frontier pop-vec-item @
    scanners vec>size 0 ?do
      dup i scanner[] try-align if
        i scanner[] frontier push-vec-item !
      then
    loop
    drop
  repeat
;

create allpoints heap allot
point ' point-hash allpoints init-heap
variable pointcount
: count-points ( -- u )
  scanners vec>size 0 ?do
    i scanner[] scanner.size @ 0 ?do
      i j scanner[] point[] \ get da point?
      allpoints push-heap-item-start
      copy-point \ copy it in
      allpoints push-heap-item-done
    loop
  loop
  1 pointcount !
  allpoints pop-heap point-hash ( prevhash )
  begin allpoints vec>size
  while
    allpoints peek-heap point-hash
    2over 2over d<> if
      1 pointcount +!
    then
    allpoints pop-heap drop
    2swap 2drop
  repeat
  2drop
  pointcount @
;

: find-max-distance ( -- d )
  0 0
  scanners vec>size 0 do
    scanners vec>size 0 do
      i scanner[] scanner.location
      j scanner[] scanner.location
      distance
      dmax
    loop
  loop
;

: run ( -- )
  parse-input
  align-all
  ." Points: " count-points . cr
  ." Max distance: " find-max-distance d. cr
;

run
scanners destroy-vec
leftpairs destroy-heap
rightpairs destroy-heap
matches destroy-vec
points destroy-vec
frontier destroy-vec
allpoints destroy-heap
bye