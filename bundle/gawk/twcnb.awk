# TWCNB: Rennie et al. ICML'03, Table 4 (steps 1-8)
# input rows: word counts..., label
BEGIN   { FS="," }
NR <= T { keep(); next }
NR==T+1 { learn() }
        { print classify() "\t" $NF }

function keep(   c) {                                   # step 1
  y[NR] = $NF
  for (c=1; c<NF; c++)
    if ($c > 0) { d[NR][c] = log(1+$c); df[c]++ } }

function learn(   r,c,len,h,z,tot,nh,s,all) {
  for (r in d) { len = 0
    for (c in d[r]) len += (d[r][c] *= log(T/df[c]))^2  # step 2
    for (c in d[r]) { z = d[r][c] / sqrt(len + 1E-32)    # step 3
      s[y[r]][c] += z; all[c] += z; nh[y[r]] += z; tot += z } }
  for (h in nh) { z = 0                              # steps 4-6
    for (c=1; c<NF; c++)
      z -= w[h][c] = log((all[c]-s[h][c]+1) / (tot-nh[h]+NF-1))
    for (c=1; c<NF; c++) w[h][c] /= z } }

function classify(   h,c,t,best,out) {               # steps 7,8
  for (h in w) { t = 0
    for (c=1; c<NF; c++) t += log(1+$c) * w[h][c]
    if (t < best || !out) { best=t; out=h } }
  return out }
