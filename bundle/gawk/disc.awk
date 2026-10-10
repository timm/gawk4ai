# usage: ... | gawk -f disc.awk [B=7]   (one pass, so it buffers)
# numeric cols (upper case names) -> B bins, from train rows only.
# Emits mu,sd rows too: with B, they say what any bin means.
BEGIN      { FS=OFS=","; B=7 }
/^header,/ { header(); print }
/^train,/  { stats(); row[++rows] = $0 }
/^test,/   { row[++rows] = $0 }
END        { musd(); meta()
             for (i=1; i<=rows; i++) print bins(row[i]) }

function header(   c) {
  nf = NF
  for (c=2; c<NF; c++) if ($c ~ /^[A-Z]/) num[c] }

function stats(   c) {
  for (c in num) if ($c != "?") {
    n[c]++; s[c] += $c; s2[c] += $c*$c } }

function musd(   c) {            # one mean and sd per column, once
  for (c in n) {
    mu[c] = s[c]/n[c]
    sd[c] = sqrt(s2[c]/n[c] - mu[c]^2) + 1E-32 } }

function meta(   c) {            # what a bin means, in the stream
  printf "mu"  ; for (c=2; c<=nf; c++) printf ",%s", c in mu ? mu[c] : ""
  printf "\nsd"; for (c=2; c<=nf; c++) printf ",%s", c in sd ? sd[c] : ""
  print "" }

function bins(s,   c) {
  $0 = s                       # assigning $0 re-splits it into fields
  for (c in n) if ($c != "?") $c = bin(c, $c)
  return $0 }

function bin(c,x) { return int(B / (1 + exp(-1.7 * (x - mu[c])/sd[c]))) }
