# usage: ... | gawk -f rank.awk [C=5]   (lines: predicted actual)
# check the C rows with the best (lowest) predictions; print how
# the best of them really ranks among all n test rows, as s=r/n.
BEGIN { C=5 }
      { p[NR] = $1; a[NR] = $2 }
END   { print rank(best()) / NR }

function best(   i,j,b) {
  PROCINFO["sorted_in"] = "@val_num_asc"
  for (i in p) {
    if (!j || a[i] < b) b = a[i]
    if (++j == C) break }
  delete PROCINFO["sorted_in"]
  return b }

function rank(b,   i,n) {
  for (i in a) n += a[i] < b
  return n + 1 }
