# usage: gawk -f pick.awk N=100 T=n [F=0.5 seed=1] d
# label N rows from rows 1..T, skipping near-duplicates (tabu):
# a random candidate closer than k = F*sd(distances) to any pick
# goes on the no[] list. If stuck, halve k and clear no[].
# Prints the N picks, then the test rows (> T). Never reads y.
BEGIN { FS=OFS=","; N=100; F=0.5; B=7; seed=1 }
      { row[NR] = $0 }
END   { srand(seed); pick(); report() }

function pick(   k,r,s,ok,n,tries) {
  k = F * spread()
  while (n < N) {
    if (++tries > 4*T) { k /= 2; tries = 0; delete no }
    r = int(rand()*T) + 1
    if ((r in got) || (r in no)) continue
    ok = 1
    for (s in got) if (dist(r, s) < k) { ok = 0; break }
    if (ok) got[r] = ++n; else no[r] = 1 } }

function spread(   i,d,s,s2) {       # sd of 64 random distances
  for (i=1; i<=64; i++) {
    d = dist(int(rand()*T)+1, int(rand()*T)+1)
    s += d; s2 += d*d }
  return sqrt(s2/64 - (s/64)^2) }

function dist(i,j,   a,b,c,d,n) {    # mean distance per column
  n = split(row[i], a); split(row[j], b)
  for (c=1; c<n; c++) d += gap(a[c], b[c])
  return d / (n-1) }

function gap(x,y) {
  if (x == "?" || y == "?") return 1
  if (x y ~ /^[0-9]+$/) return (x > y ? x-y : y-x)/(B-1)
  return x != y }

function report(   r) {
  for (r in got) print row[r]
  for (r=T+1; r<=NR; r++) print row[r] }
