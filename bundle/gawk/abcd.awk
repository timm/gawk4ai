# usage: ... | gawk -f abcd.awk   (lines: guessed actual)
# per class: n, the cells a b c d, then acc, precision, pf, recall.
BEGIN { FS="\t" }            # classes can hold spaces
NF==2 { n++; got[$1]++; want[$2]++; hit[$1] += $1==$2 }
END   { report(n, got, want, hit) }

function report(n,got,want,hit,   x,a,b,c,d) {
  print "   n,   a,   b,   c,   d, acc, pre,  pf,  pd, class"
  for (x in want) {
    d = hit[x]
    c = got[x]-d
    b = want[x]-d
    a = n-b-c-d
    printf "%4d,%4d,%4d,%4d,%4d,%4d,%4d,%4d,%4d, %s\n",
      want[x],a,b,c,d, pc(a+d,n), pc(d,c+d), pc(c,a+c),
      pc(d,b+d), x | "sort -t, -k9nr" } }

function pc(x,y) { return y ? 100*x/y : 0 }
