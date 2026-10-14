BEGIN    { FS="[ \t]*,[ \t]*"; M=2; K=1; Bins=10; T=1E32 }
FNR==1   { for(c=1;c<=NF;c++) head(c,$c); next }
/^$/     { if (b) era(); next }                  # blank line = era over
         { R++
           if (b && R == T+1) era()              # stop learning: flush
           if (Eras && R > t) print classify() "\t" $NF
           if (R <= T) { welford(); buf[++b] = $0 } }

function head(c,s) {
  if (s ~ /X$/) return
  if (s !~ /[!X]$/) X[c]
  if (s ~ /^[A-Z]/) Num[c] }

function welford(   c,d) {                   # per row, as the row arrives
  for(c in Num) if ($c != "?") {
    N[c]++; d = $c - Mu[c]; Mu[c] += d/N[c]; M2[c] += d*($c - Mu[c]) } }

function era(   c,i,n,f) {                   # freeze sd, learn the backlog
  for(c in Num) Sd[c] = N[c] < 2 ? 0 : sqrt(M2[c]/(N[c]-1))
  for(i=1; i<=b; i++) {
    n = split(buf[i], f)
    Rows++; H[f[n]]++
    for(c in X) if (f[c] != "?") F[f[n]][c][disc(c,f[c])]++ }
  delete buf; b=0; Eras++ }

function disc(c,v) {
  return (c in Num) ? int(Bins * cdf(v, Mu[c], Sd[c])) : v }

function cdf(v,mu,s,   z) {
  z = (v - mu)/(s + 1E-32); z = z>3 ? 3 : (z<-3 ? -3 : z)
  return 1/(1 + exp(-1.7*z)) }

function classify(   c,h,v,best,out) {
  for(c in X) B[c] = disc(c,$c)
  for(h in H) { v = like(h); if (!out || v > best) { best = v; out = h } }
  return out }

function like(h,   c,p,out) {
  p = (H[h] + K) / (Rows + K*length(H))
  for(c in X) if ($c != "?") out += log((F[h][c][B[c]] + M*p) / (H[h] + M))
  return out + log(p) }
