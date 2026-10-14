# usage: gawk -f shuf.awk [Seed=1 Era=64 N=0] file.csv
# Shuffle the rows, deal them out in eras separated by a blank line, and
# prefix each row with binsX: how many rows are still to come.
BEGIN    { Seed=1          # srand seed, so a run is reproducible
           Era=64          # rows per era; era 1 absorbs the remainder
           N=0 }           # rows to deal out; 0 means "all of them"
BEGIN    { FS="[ \t]*,[ \t]*"   # the raw file may pad its commas
           OFS=","         # but what we emit never does
           hdr=0           # 0 until the header row has gone by
           delete a }      # every row, held so we can shuffle them
empty()  { next }
!hdr++   { srand(Seed); print "binsX" OFS $0; next }
         { a[length(a)+1] = $0 }
END      { deal(a, Era, N) }

function deal(a,era,want,   m,n,nxt,r,i) {  # reaches for no global
  m = length(a)                 # rows we read
  n = want ? want : m           # rows to deal out
  nxt = era + m % era           # era 1 eats the odd rows, so the last
  while (n > 0) { shuffle(a)    # era is always exactly era long
    for(i=1; i<=m && n-- > 0; i++) {
      print n OFS a[i]          # the countdown, then the row
      if (++r == nxt && n) {    # a blank line SEPARATES eras; none
        print ""; nxt += era }}}}   # follows the last one

function shuffle(a,   i,j,t) {
  for(i=length(a); i>1; i--) {
    j=int(rand()*i)+1; t=a[i]; a[i]=a[j]; a[j]=t }}

function empty() {                     # a whole-line comment, or blank
  if ($0 ~ /^[[:space:]]*#/) return 1
  gsub(/^[[:space:]]+|[[:space:]]+$/,"")
  $1=$1
  return $0=="" }
