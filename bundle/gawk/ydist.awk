# usage: ... | gawk -f ydist.awk   (one pass, so it buffers)
# goals (+ or - names) -> one column: distance to heaven, 0=best.
# min,max span every row: d2h is the label, not something we learn.
BEGIN      { FS=OFS="," }
/^header,/ { header() }
/^train,/  { minmax(); row[++rows] = $0 }
/^test,/   { minmax(); row[++rows] = $0 }
END        { for (i=1; i<=rows; i++) print xs(row[i]) }

function header(   c,s) {
  for (c=2; c<=NF; c++)
    if ($c ~ /[+-]$/) w[c] = $c ~ /\+$/    # heaven: 1=max, 0=min
    else if ($c !~ /X$/) { x[c]; s = s OFS $c }
  print $1 s OFS "D2h-" }

function minmax(   c,v) {
  for (c in w) if ($c != "?") {
    v = $c + 0
    if (!(c in lo) || v < lo[c]) lo[c] = v
    if (!(c in hi) || v > hi[c]) hi[c] = v } }

function xs(s,   c,o) {
  $0 = s                       # assigning $0 re-splits it into fields
  o = $1                       # the train/test tag rides along
  for (c=2; c<=NF; c++) if (c in x) o = o OFS $c
  return o OFS d2h() }

function d2h(   c,d,n) {
  for (c in w) { n++
    d += (w[c] - ($c - lo[c]) / (hi[c] - lo[c] + 1E-32))^2 }
  return sqrt(d / n) }
