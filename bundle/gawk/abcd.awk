# usage: ... | gawk -f abcd.awk   (lines: guessed actual)
# per class: n, the cells tn fn fp tp, then acc, precision, pf, recall.
BEGIN { FS="\t" }            # classes can hold spaces
NF==2 { n++; got[$1]++; want[$2]++; hit[$1] += $1==$2 }
END   { report(n, got, want, hit) }

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
