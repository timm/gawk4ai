# usage: ... | gawk -f abcd.awk [Every=0]   (lines: guessed actual)
# per class: n, the cells tn fn fp tp, then acc, precision, pf, recall.
# Every>0 also prints "rows acc pd" as it goes (pd = macro recall,
# the one that still means something when a class is 1% of the data).
BEGIN { FS="\t"; Every=0 }   # classes can hold spaces
NF==2 { n++; got[$1]++; want[$2]++; hit[$1] += $1==$2; ok += $1==$2
        if (Every && n % Every == 0) print n, int(100*ok/n), int(100*pd(want,hit)) }
END   { report(n, got, want, hit) }

function pd(want,hit,   x,k,s) {          # mean recall over the classes
  for (x in want) { k++; s += hit[x]/want[x] }
  return s/k }

function report(n,got,want,hit,   x,tn,fn,fp,tp) {
  print "   n,  tn,  fn,  fp,  tp, acc, pre,  pf,  pd, class"
  for (x in want) {
    tp = hit[x]
    fp = got[x]-tp
    fn = want[x]-tp
    tn = n-fn-fp-tp
    printf "%4d,%4d,%4d,%4d,%4d,%4d,%4d,%4d,%4d, %s\n",
      want[x],tn,fn,fp,tp, pc(tn+tp,n), pc(tp,fp+tp), pc(fp,tn+fp),
      pc(tp,fn+tp), x | "sort -t, -k9nr" } }

function pc(x,y) { return y ? 100*x/y : 0 }
