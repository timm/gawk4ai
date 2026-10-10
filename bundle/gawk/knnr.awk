# usage: ... | gawk -f knnr.awk [K=5]   (rows tagged by split.awk)
# kNN: nums squashed 0..1 by the logistic, as disc bins them;
# syms 0/1; "?" is 1. Prints y^ y.
BEGIN      { FS=","; K=5
             PROCINFO["sorted_in"] = "@val_num_asc" }  # nearest first
/^header,/ { for (c=2; c<NF; c++) if ($c ~ /^[A-Z]/) num[c] }
/^train,/  { train() }
/^test,/   { print knn() " " $NF }

function train(   c) {
  y[++rows] = $NF
  for (c=2; c<NF; c++) {
    x[rows][c] = $c
    if (c in num && $c != "?") {
      n[c]++; s[c] += $c; s2[c] += $c*$c } } }

function norm(c,v,   mu,sd) {    # 0..1, the same squash disc bins with
  mu = s[c]/n[c]
  sd = sqrt(s2[c]/n[c] - mu^2) + 1E-32
  return 1/(1 + exp(-1.7 * (v - mu)/sd)) }

function knn(   r,c,d,j,sum) {
  for (r in y) for (c in x[r]) d[r] += gap(c, x[r][c], $c)^2
  for (r in d) { sum += y[r]; if (++j == K) break }
  return sum/j }

function gap(c,a,b) {
  if (a == "?" || b == "?") return 1
  if (!(c in num)) return a != b
  return norm(c,a) - norm(c,b) }
