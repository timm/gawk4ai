# usage: gawk -f disc.awk [B=7] f f  (pass 1: mean,sd; pass 2: bins)
BEGIN   { FS=OFS=","; B=7 }
FNR==1  { header(); next }
NR==FNR { stats();  next }
        { print bins() }

function header(   c) {
  for (c=1; c<NF; c++) num[c] = $c ~ /^[A-Z]/
  if (NR > 1) print }

function stats(   c) {
  for (c in num) if (num[c] && $c != "?") {
    n[c]++; s[c] += $c; s2[c] += $c*$c } }

function bins(   c) {
  for (c in n) if ($c != "?") $c = bin(c, $c)
  return $0 }

function bin(c,x,   mu,sd) {
  mu = s[c]/n[c]; sd = sqrt(s2[c]/n[c] - mu^2) + 1E-32
  return int(B / (1 + exp(-1.7 * (x - mu)/sd))) }
