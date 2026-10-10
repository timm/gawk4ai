# usage: gawk -f nb.awk [T=n W=n] f   train rows 1..T, test rows > W
BEGIN { FS=" *, *"; m=2; k=1; T=1E32; W=10 }
NR > W  { print classify(), $NF }
NR <= T { train() }

function train(   c) {
  N++; for (c=1; c<=NF; c++) if ($c != "?") f[$NF][c][$c]++ }

function classify(   h,t,best,out) {
  for (h in f) if ((t=like(h)) > best || !out) { best=t; out=h }
  return out }

function like(h,   n,p,out,c) {    # log P(h) + sum log P(x|h)
  n = f[h][NF][h]; p = (n+k)/(N + k*length(f)); out = log(p)
  for (c=1; c<NF; c++)
    if ($c != "?") out += log((f[h][c][$c] + m*p)/(n+m))
  return out }
