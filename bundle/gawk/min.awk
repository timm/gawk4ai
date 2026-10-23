BEGIN    { Seed=1          # srand seed, so a run is reproducible
           N=0             # rows to deal out; 0 means "all of them"
           Test=.25 }      # the last quarter of them is the test set
BEGIN    { CONVFMT="~.17f"
	   FS="[ \t]*,[ \t]*"   # the raw file may pad its commas
           OFS=","         # but what we emit never does
           delete Names    # every row, held so we can shuffle
           delete Num      # every row, held so we can shuffle
           delete Rows }   # every row, held so we can shuffle
empty()  { next }
!Name    { srand(Seed)
       	   for(_=1;_<=NF;_++_) {
	     Name[_] = $_
	     if ($_~/!$/) Klass=_
	     if ($_~/^[A-Z]/) Num[_]= $_!~/-$/}}

Name     {  Rows[rand()]=$0 }
END      {  think(Rows,Klass) }

function think(Rows,Klass) {
  for(Row in Rows) {
    $0 = Row
    for 
     

         { Rows[length(Rows)+1] = $0 }
END      { deal() }

function empty() {                     # a whole-line comment, or blank
  if ($0 ~ /^[[:space:]]*#/) return 1
  gsub(/^[[:space:]]+|[[:space:]]+$/,"")
  $1=$1
  return $0=="" }
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


