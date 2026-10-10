# usage: gawk -f select.awk T=n [K=5] d d
# keep K cols with least H(class|col); default K = half
BEGIN   { FS=OFS=","; K=0 }       # K=0: keep half
NR==FNR { if (FNR <= T) count(); next }
FNR==1  { rank() }
        { print keep() }

function count(   c) {
  for (c=1; c<NF; c++)
    if ($c != "?") { n[c][$c]++; ny[c][$c][$NF]++ } }

function rank(   c,v,y,p,e,j) {
  for (c in n) for (v in n[c]) for (y in ny[c][v]) {
    p = ny[c][v][y] / n[c][v]; e[c] -= n[c][v]/T * p*log(p) }
  K = K ? K : int((NF-1)/2)
  PROCINFO["sorted_in"] = "@val_num_asc"
  for (c in e) if (++j <= K) use[c]
  delete PROCINFO["sorted_in"] }

function keep(   c,out) {
  for (c=1; c<NF; c++) if (c in use) out = out $c OFS
  return out $NF }
