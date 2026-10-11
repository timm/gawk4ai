# usage: ... | gawk -f bin.awk | gawk -f nb.awk [t=10 T=1E32 M=2 K=1]
# naive Bayes on discretized rows: guess rows past t, learn rows up to T.
# vim: set et sw=2 ts=2 sts=2 cc=75 :
BEGIN     { FS=","; M=2; K=1; t=10; T=1E32 }   # M,K: m- and k-estimates
/^:x,/    { for (c=2; c<=NF; c++) if ($c != "") X[c] }
/^:bins,/ { if (++nr > t)  print classify() "\t" $NF  # guess before learn
            if (nr <= T)   train() }

function train(   c) {             # H[class], F[class,col,value]: counts
  n++; H[$NF]++
  for (c in X) if ($c != "?") F[$NF,c,$c]++ }

function classify(   h,v,best,out) {
  for (h in H) if ((v = like(h)) > best || !out) { best = v; out = h }
  return out }

function like(h,   c,p,out) {      # log P(h) + sum log P(x|h)
  p   = (H[h] + K) / (n + K * length(H))
  out = log(p)
  for (c in X) if ($c != "?") out += log((F[h,c,$c] + M*p) / (H[h] + M))
  return out }
