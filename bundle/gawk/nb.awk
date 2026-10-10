# usage: ... | gawk -f nb.awk   (rows tagged train/test by split.awk)
# naive Bayes: count what the train rows hold, then guess every test row.
BEGIN     { FS=","; M=2; K=1 }     # M,K: the m- and k-estimates
/^train,/ { train(f) }             
/^test,/  { print classify(f), $NF } 

function train(f,   c) {
  rows++; for (c=2; c<=NF; c++) if ($c != "?") f[$NF][c][$c]++ }

function classify(f,   h,t,best,out) {
  for (h in f) if ((t=like(f,h)) > best || !out) { best=t; out=h }
  return out }

function like(f,h,   n,p,out,c) {    # log P(h) + sum log P(x|h)
  n   = f[h][NF][h]
  p   = (n+K)/(rows + K*length(f))
  out = log(p)
  for (c=2; c<NF; c++)
    if ($c != "?") out += log((f[h][c][$c] + M*p)/(n+M))
  return out }
