# usage: ... | gawk -f bins.awk | gawk -f nb.awk [M=2 K=1]
# Cells arrive already discrete, so this is pure counting.  One blank
# line splits the stream: learn before it, guess after it.
BEGIN    { M=2             # m-estimate: prior weight for a rare cell
           K=1 }           # k-estimate: prior weight for a rare class
BEGIN    { FS="," }        # cells arrive already binned by bins.awk
FNR==1   { train() }       # not BEGIN: knobs land after BEGIN has run

function head(x,   c,klass) {            # x: the columns to learn from
  for(c=1; c<=NF; c++)
    if ($c ~ /X$/) continue              # ends X: a column to ignore
    else if ($c ~ /!$/) klass = c        # ends !: the class column
    else x[c]
  return klass }

function train(   c,x,klass,seen,f) {    # seen[class]: rows of a class
  klass = head(x)                        # f[class][c][val]: cell counts
  while (getline > 0) {
    if ($0 == "") return test(x, klass, seen, f)
    seen[$klass]++
    for(c in x) if ($c != "?") f[$klass][c][$c]++ } }

function test(x,klass,seen,f) {          # guess all that follow
  while (getline > 0) print guess(x, seen, f) "\t" $klass }

function guess(x,seen,f,   h,rows,v,best,out) {
  for(h in seen) rows += seen[h]         # the training rows, now all in
  for(h in seen) { v = like(x, seen, f, h, rows)
                   if (!out || v > best) { best = v; out = h } }
  return out }

function like(x,seen,f,h,rows,   c,p,out) {   # k-estimate for the class,
  p = (seen[h] + K) / (rows + K*length(seen))   # m-estimate per cell
  for(c in x) if ($c != "?")
    out += log((f[h][c][$c] + M*p) / (seen[h] + M))
  return out + log(p) }
