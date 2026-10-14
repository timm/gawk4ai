BEGIN    { M=2             # m-estimate: prior weight for a rare cell
           K=1             # k-estimate: prior weight for a rare class
           B=10 }          # a numeric column becomes this many bins

BEGIN    { FS=","          # shuf already trimmed the padded commas
           _rows=0         # how many rows have been learned so far
           _klass=0                        # which column we classify on
           delete _x       # "c in _x": column c is an independent col
           delete _y       # "c in _y": column c is a goal column
           delete _n       # _n[c]: n,m1,m2 live; mu,sd frozen per era
           delete _h       # _h[class]: rows seen of each class
           delete _f       # _f[class][c][val]: times that cell was seen
           delete _buf }   # the era being read, held until it closes
FNR==1   { for(_=1; _<=NF; _++) head(_,$_); next }
/^$/     { if (length(_buf)) newEra(); next }   # blank line = era over
         { if (_rows) print classify() "\t" $_klass  # era 1 only learns
           for(_=1; _<=NF; _++) welford(_,$_)       # _ : the loop var for
           _buf[length(_buf)+1] = $0 }     # rules, never below one

#-- knows the model state -------------------------------------------------
function newEra() { sds(); learn(); zap() }

function head(c,s) {
  if (s ~ /X$/) return                     # ends X: ignore this column
  if (s ~ /!$/) { _y[c]; _klass = c }      # ends !: a goal column,
  else { _x[c]                             # not always the last one
         if (s ~ /^[A-Z]/) _n[c]["m1"] = 0 } }  # _n[c] exists <=> numeric

function welford(c,v,   d) {               # per column, as rows arrive
  if (!(c in _n) || v == "?") return
  _n[c]["n"]++; d = v - _n[c]["m1"]
  _n[c]["m1"] += d/_n[c]["n"]
  _n[c]["m2"] += d*(v - _n[c]["m1"]) }

function sds(   c) {                       # m1,m2,n are live; mu,sd are
  for(c in _n) { _n[c]["mu"] = _n[c]["m1"]    # frozen here, and for the
    _n[c]["sd"] = _n[c]["n"] < 2 ? 0 : sqrt(_n[c]["m2"]/(_n[c]["n"]-1)) } }

function learn(   c,i) {                   # drain the backlog into H,F.
  for(i=1; i<=length(_buf); i++) {         # $0= re-splits on FS; the one
    $0 = _buf[i]                           # caller nexts, so no restore
    _rows++
    _h[$_klass]++
    for(c in _x) if ($c != "?") _f[$_klass][c][disc(c,$c)]++ } }

function zap() { delete _buf }

function disc(c,v) {                       # symbolic falls through;
  return (c in _n) ? int(B * cdf(v, _n[c]["mu"], _n[c]["sd"])) : v }

function classify(   c,h,v,best,out,b) {   # b: this row's bins, built
  for(c in _x) b[c] = disc(c,$c)           # once, read once per class
  for(h in _h) { v = like(h,b)
                if (!out || v > best) { best = v; out = h } }
  return out }

function like(h,b,   c,p,out) {            # k-estimate for the class,
  p = (_h[h] + K) / (_rows + K*length(_h))   # m-estimate for each cell
  for(c in _x) if ($c != "?")
    out += log((_f[h][c][b[c]] + M*p) / (_h[h] + M))
  return out + log(p) }

#-- no model state: args + BEGIN constants --------------------------------
function cdf(v,mu,s,   z) {
  z = (v - mu)/(s + 1E-32); z = z>3 ? 3 : (z<-3 ? -3 : z)
  return 1/(1 + exp(-1.7*z)) }

