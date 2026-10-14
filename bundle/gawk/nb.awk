# usage: ... | gawk -f shuf.awk | gawk -f bins.awk | gawk -f nb.awk
# Cells arrive already discrete, so this is pure counting.  main() owns the
# read loop, so the model is local to it -- and so only ONE input stream is
# handled: a second file's header would arrive as data.
BEGIN    { M=2             # m-estimate: prior weight for a rare cell
           K=1 }           # k-estimate: prior weight for a rare class
BEGIN    { FS=","          # cells arrive already binned by bins.awk
           klass=0         # which column holds the class
           delete x }      # "c in x": column c is an independent col
FNR==1   { for(_=1; _<=NF; _++) head(_,$_); main() }

function head(c,s) {
  if (s ~ /X$/) return                     # ends X: binsX lands here too
  else if (s ~ /!$/) klass = c             # ends !: the class column
  else x[c] }

function main(   buf,rows,n,f) {        # the model lives and dies here
  while ((getline) > 0)
    if (NF) keep(buf,n,f,rows)           # a row: score it, then stash it
    else  { rows = learn(buf,n,f,rows)   # blank line: the era is over
            delete buf } }

function learn(buf,n,f,rows,   i,c) {   # drain the era; return the new
  for(i in buf) {                       # row count, since awk passes
    $0 = buf[i]                         # scalars by value
    rows++
    n[$klass]++
    for(c in x) if ($c != "?") f[$klass][c][$c]++ }
  return rows }

function keep(buf,n,f,rows) {           # score this row, then hold it
  if (rows) print classify(n,f,rows) "\t" $klass
  buf[NR] = $0 }                        # NR: unique, and no length()

function classify(n,f,rows,   h,v,best,out) {
  for(h in n) { v = like(h,n,f,rows)
                if (!out || v > best) { best = v; out = h } }
  return out }

function like(h,n,f,rows,   c,p,out) {     # k-estimate for the class,
  p = (n[h] + K) / (rows + K*length(n))    # m-estimate for each cell
  for(c in x) if ($c != "?")
    out += log((f[h][c][$c] + M*p) / (n[h] + M))
  return out + log(p) }
