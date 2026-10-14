# usage: gawk -f prep.awk f | gawk -f bin.awk [Bins=10]
# a :bins per :cells: x num -> percent, by mu,sd, z +-3. Bins divides 100
# Plain=1 drops the : lines: just the header, then the binned rows.
# vim: set et sw=2 ts=2 sts=2 cc=75 :
BEGIN      { FS=OFS=","; Bins=10 }
/^:x,/     { cols(X)  }               # 1 = numeric x, 0 = symbolic x
/^:mu,/    { cols(mu) }               # these three fall through to the
/^:sd,/    { cols(sd) }               # catch-all below, which prints
/^:cells,/ { print                        # the row, then its bins: assign
             $1 = ":bins"                 # the fields and let awk rebuild
             for (c=2; c<=NF; c++) $c = bin(c)
             print; next }
           { print }                  # :names, :y, anything new

function cols(t,   c) { for (c=2; c<=NF; c++) t[c] = $c }

function bin(c) {                  # one cell: its bucket, as a percent
  if (!X[c] || $c == "?") return $c
  return int(Bins * norm(c, $c)) * (100 / Bins) }

function norm(c,v,   z) {          # 0..1; the squash disc and knnr share
  z = sd[c] ? (v - mu[c]) / sd[c] : 0
  return 1 / (1 + exp(-1.7 * max(-3, min(3, z)))) }

function min(x,y) { return x < y ? x : y }
function max(x,y) { return x > y ? x : y }
