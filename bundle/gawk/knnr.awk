# usage: gawk -f knnr.awk T=n [K=5] s    (s: shuffled, header)
# kNN on raw rows: numbers scaled 0..1 by train min/max,
# symbols 0/1, "?" 1. Predict mean y of K nearest. Prints y^ y.
BEGIN { FS=" *, *"; K=5 }
NR==1      { for (c=1; c<NF; c++) num[c] = $c ~ /^[A-Z]/; next }
NR <= T+1  { train(); next }
           { print knn() " " $NF }

function train(   c) {
  y[NR] = $NF
  for (c=1; c<NF; c++) {
    x[NR][c] = $c
    if (num[c] && $c != "?") {
      if (!(c in lo) || $c < lo[c]) lo[c] = $c
      if (!(c in hi) || $c > hi[c]) hi[c] = $c } } }

function knn(   r,c,d,j,sum) {
  for (r in y) for (c in x[r]) d[r] += gap(c, x[r][c], $c)^2
  PROCINFO["sorted_in"] = "@val_num_asc"
  for (r in d) { sum += y[r]; if (++j == K) break }
  delete PROCINFO["sorted_in"]
  return sum/j }

function gap(c,a,b) {
  if (a == "?" || b == "?") return 1
  if (!num[c]) return a != b
  return (a - b) / (hi[c] - lo[c] + 1E-32) }
