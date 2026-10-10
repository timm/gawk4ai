# usage: gawk -f kmknn.awk T=n [S=256 C=8 K=5] s  (s: shuffled, header)
# k-means (incremental: x += (v-x)/n) on S rows, then put every
# train row in its nearest centroid; kNN only inside the test
# row's cluster. Numbers scaled by train min/max. Prints y^ y.
BEGIN      { FS=" *, *"; S=256; C=8; K=5 }
NR==1      { for (c=1; c<NF; c++) num[c] = $c ~ /^[A-Z]/; next }
NR <= T+1  { train(); next }
NR == T+2  { kmeans() }
           { split($0, z, FS); print knn(z) " " $NF }

function train(   c) {
  y[NR] = $NF
  for (c=1; c<NF; c++) {
    x[NR][c] = $c
    if (num[c] && $c != "?") {
      if (!(c in lo) || $c < lo[c]) lo[c] = $c
      if (!(c in hi) || $c > hi[c]) hi[c] = $c } } }

function kmeans(   r,i,c,k) {
  for (i=1; i<=C; i++) for (c in x[i+1]) mu[i][c] = x[i+1][c]
  for (r=2; r <= S+1 && r <= T+1; r++) {
    k = near(x[r]); n[k]++
    for (c in x[r]) if (num[c] && x[r][c] != "?" && mu[k][c] != "?")
      mu[k][c] += (x[r][c] - mu[k][c]) / (n[k] + 1) }
  for (r in y) cl[near(x[r])][r] }

function near(v,   i,d,best,out) {
  for (i in mu) if ((d = dist(v, mu[i])) < best || !out) {
    best = d; out = i }
  return out }

function knn(z,   r,d,j,sum) {
  for (r in cl[near(z)]) d[r] = dist(x[r], z)
  PROCINFO["sorted_in"] = "@val_num_asc"
  for (r in d) { sum += y[r]; if (++j == K) break }
  delete PROCINFO["sorted_in"]
  return sum/j }

function dist(a,b,   c,d) {
  for (c in a) d += gap(c, a[c], b[c])^2
  return d }

function gap(c,a,b) {
  if (a == "?" || b == "?") return 1
  if (!num[c]) return a != b
  return (a - b) / (hi[c] - lo[c] + 1E-32) }
