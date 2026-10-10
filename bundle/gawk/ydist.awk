# usage: gawk -f ydist.awk f f    (MOOT optimize csv, 2 passes)
# keep x columns; swap the goals (names ending in + or -) for one
# column: distance to heaven (0 = best). Skips names ending in X.
BEGIN   { FS=" *, *"; OFS="," }
FNR==1  { header(); next }
NR==FNR { for (c in w) if ($c != "?") minmax(c, $c+0); next }
        { print xs() d2h() }

function header(   c,out) {
  for (c=1; c<=NF; c++)
    if ($c ~ /[+-]$/) w[c] = $c ~ /\+$/    # heaven: 1=max, 0=min
    else if ($c !~ /X$/) { x[c]; out = out $c OFS }
  if (NR > 1) print out "D2h-" }

function minmax(c, v) {
  if (!(c in lo) || v < lo[c]) lo[c] = v
  if (!(c in hi) || v > hi[c]) hi[c] = v }

function xs(   c,out) {
  for (c=1; c<=NF; c++) if (c in x) out = out $c OFS
  return out }

function d2h(   c,d,n) {
  for (c in w) { n++
    d += (w[c] - ($c - lo[c]) / (hi[c] - lo[c] + 1E-32))^2 }
  return sqrt(d / n) }
