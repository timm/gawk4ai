# usage: ... | gawk -f rank.awk [C=5]   (lines: predicted actual)
# of the C best-guessed rows, where the best really ranks: 100*r/n
BEGIN { C=5
        PROCINFO["sorted_in"] = "@val_num_asc" }  # best guesses first
NF==2 { p[++rows] = $1; a[rows] = $2 }
END   { printf "%.1f\n", 100 * rank(best()) / rows }

function best(   i,j,b) {
  for (i in p) {
    if (!j || a[i] < b) b = a[i]
    if (++j == C) break }
  return b }

function rank(b,   i,n) {
  for (i in a) n += a[i] < b
  return n + 1 }
