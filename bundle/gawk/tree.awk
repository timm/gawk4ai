# usage: gawk -f tree.awk T=n [M=8] d   (d: binned, no header)
# regression tree: split on col<=bin (or col==symbol) that most
# reduces squared error; stop below M rows. Prints y^ y.
BEGIN   { FS=","; M=8 }
NR <= T { y[NR] = $NF; for (c=1; c<NF; c++) x[NR][c] = $c; next }
NR==T+1 { for (r=1; r<=T; r++) all = all " " r; grow(all, 1) }
        { print leaf(1) " " $NF }

function grow(ids, k,   c,v,n,s,best,bc,bv,id,a,i,e) {
  n = split(ids, id, " "); for (i in id) { s += y[id[i]] }
  mean[k] = s/n; if (n < M) return
  best = sse(ids)
  for (c=1; c<NF; c++) {
    delete a
    for (i in id) {
      v = x[id[i]][c]; if (v in a) continue; a[v]
      e = sse(part(ids, c, v, 1)) + sse(part(ids, c, v, 0))
      if (e < best) { best = e; bc = c; bv = v } } }
  if (!bc) return
  col[k] = bc; cut[k] = bv
  grow(part(ids, bc, bv, 1), 2*k)
  grow(part(ids, bc, bv, 0), 2*k+1) }

function part(ids, c, v, want,   id,i,out) {
  split(ids, id, " ")
  for (i in id)
    if (goes(x[id[i]][c], v) == want) out = out " " id[i]
  return out }

function goes(a, v) {                  # bins: <=; symbols: ==
  return a v ~ /^[0-9]+$/ ? a+0 <= v+0 : a == v }

function sse(ids,   id,i,n,s,s2) {
  n = split(ids, id, " "); if (!n) return 0
  for (i in id) { s += y[id[i]]; s2 += y[id[i]]^2 }
  return s2 - s*s/n }

function leaf(k) {
  while (k in col) k = 2*k + !goes($col[k], cut[k])
  return mean[k] }
