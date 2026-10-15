# usage: @include "dist.awk"   (rank.awk pulls this in)
# The parts with no state: column conventions, distances, spans.  Every
# function here takes what it needs and touches no global, so they read
# the same wherever they are called from.

function head(x,w,   c) {                # x[c]: 1 numeric, 0 symbolic
  for(c=1; c<=NF; c++)                   # w[c]: 1 to max it, 0 to min
    if ($c ~ /[+-]$/) w[c] = $c ~ /\+$/
    else if ($c !~ /X$/) x[c] = $c ~ /^[A-Z]/ }

function near(x,lo,hi,xs,b,   i,d,best,out) {      # the closest label
  for(i in xs) { 
    d = distx(x, lo, hi, xs[i], b)
    if (!out || d < best) { best = d; out = i } }
  return out }

function distx(x,lo,hi,a,b,   c,d,n) {   # two rows, by what we know
  for(c in x) { n++; d += gap(x[c], lo[c], hi[c], a[c], b[c])^2 }
  return sqrt(d/n) }

function gap(num,lo,hi,a,b,   v) {       # one cell pair, 0..1, no more
  if (a == "?" || b == "?") return 1
  if (!num) return a != b
  v = (a - b) / (hi - lo + 1E-32)
  return v < -1 || v > 1 ? 1 : (v < 0 ? -v : v) }

function disty(w,lo,hi,a,   c,d,n,v) {   # 0 = every goal at its heaven
  for(c in w) { n++
    v = a[c] == "?" ? 1 - w[c] : (a[c] - lo[c]) / (hi[c] - lo[c] + 1E-32)
    d += (w[c] - v)^2 }
  return sqrt(d/n) }

function cells(cols,out,   c) { for(c in cols) out[c] = $c }   # this row

function grow(cols,a,lo,hi,   c,v) {     # widen lo,hi to hold these cells
  for(c in cols) if (a[c] != "?") { v = a[c] + 0
    if (!(c in lo) || v < lo[c]) lo[c] = v
    if (!(c in hi) || v > hi[c]) hi[c] = v } }
