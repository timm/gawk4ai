# usage: gawk -f shuf.awk [Seed=1 N=0 Test=.25] file.csv
# Shuffle the rows, then print them with ONE blank line inside: before it
# the training rows, after it the last Test of them, held out for testing.
BEGIN    { Seed=1          # srand seed, so a run is reproducible
           N=0             # rows to deal out; 0 means "all of them"
           Test=.25 }      # the last quarter of them is the test set
BEGIN    { FS="[ \t]*,[ \t]*"   # the raw file may pad its commas
           OFS=","         # but what we emit never does
           Hdr=0           # 0 until the header row has gone by
           delete Rows }   # every row, held so we can shuffle
empty()  { next }
!Hdr++   { srand(Seed); print; next }
         { Rows[length(Rows)+1] = $0 }
END      { deal() }

function deal(   m,n,i,out,cut) {
  m = length(Rows)            # rows we read
  n = N ? N : m               # rows to deal out
  cut = n - int(n * Test)     # ...of which this many are for training
  while (n > 0) { shuffle()   # reshuffle for each extra pass
    for(i=1; i<=m && n-- > 0; i++) {
      if (out++ == cut) print ""    # training over: the one blank line
      print Rows[i] } } }

function shuffle(   i,j,t) {
  for(i=length(Rows); i>1; i--) {
    j=int(rand()*i)+1; t=Rows[i]; Rows[i]=Rows[j]; Rows[j]=t }}

function empty() {                     # a whole-line comment, or blank
  if ($0 ~ /^[[:space:]]*#/) return 1
  gsub(/^[[:space:]]+|[[:space:]]+$/,"")
  $1=$1
  return $0=="" }
