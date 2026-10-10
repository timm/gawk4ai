{ n++; got[$1]++; want[$2]++; hit[$1] += $1==$2 }
END { report(n, got, want, hit) }

function report(n,got,want,hit,   x,a,b,c,d) {
  print "   n,   a,   b,   c,   d,acc,pre, pf, pd, class"
  for (x in want) {
    d = hit[x]; b = want[x]-d; c = got[x]-d; a = n-b-c-d
    printf "%4d,%4d,%4d,%4d,%4d,%3d,%3d,%3d,%3d, %s\n",
      want[x],a,b,c,d, pc(a+d,n), pc(d,c+d), pc(c,a+c),
      pc(d,b+d), x | "sort -t, -k9nr" } }

function pc(x,y) { return y ? int(100*x/y + .5) : 0 }
