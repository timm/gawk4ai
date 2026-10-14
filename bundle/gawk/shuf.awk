BEGIN    { FS="[ \t]*,[ \t]*"; OFS=","; Seed=1; Era=64 }
empty()  { next }
!hdr++   { srand(Seed); print; next }
         { a[++n] = $0 }
END      { N = N ? N : n
           nxt = Era + n % Era          # era 1 eats the odd rows, so the
           while (N > 0) { shuffle()    # last era is always Era long
             for(i=1; i<=n && N-- > 0; i++) {
               print a[i]
               if (++r == nxt) { print ""; nxt += Era } } }
           if (r != nxt - Era) print "" }

function shuffle(   i,j,t) {
  for(i=n; i>1; i--) { j=int(rand()*i)+1; t=a[i]; a[i]=a[j]; a[j]=t } }

function empty() {
  sub(/#.*/,""); gsub(/^[[:space:]]+|[[:space:]]+$/,""); $1=$1; return $0=="" }
