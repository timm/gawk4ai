# usage: gawk -f prep.awk [Seed=1] f  (UPPER=num, +-=goal, !=class, X=skip)
# one pass: shuffle, learn columns, print the : settings, then the : cells
# vim: set et sw=2 ts=2 sts=2 cc=75 :
BEGIN { FS=" *, *"; OFS=","; Seed=1; CONVFMT="%.17g" }
      { sub(/#.*/, ""); gsub(/^ +|[ \r]+$/, "") }   # dos \r dies here
!/./  { next }                         # blank, or comment-only
      { $1 = $1 }                      # one clean form for all
!cols { srand(Seed); names(); next }   # seed once, before any rand()
      { a[rand()] = $0
        for (c=1; c<=NF; c++) if ($c != "?") {
          cnt[c]++                                  # what is not missing
          if (X[c] || (c in Y)) welford(c, $c) } }  # nums: x and goals

END   { for (c in n) sd[c] = _sd(c)
        print ":names" OFS head
        dump(":x", X); dump(":y", Y); dump(":n", cnt)
        dump(":mu", mu); dump(":sd", sd)
        print ":rows" OFS length(a); print ":seed" OFS Seed
        for (i in a) print ":cells" OFS a[i] }

function names(   c) {                            # header defines it all
  head = $0; cols = NF
  for (c=1; c<=NF; c++)
    if ($c !~ /X$/) {                             # else: ignored
      if ($c ~ /[+-]$/) Y[c] = $c ~ /\+$/      # 1 = maximize
      else if ($c !~ /!$/) X[c] = ($c ~ /^[A-Z]/) }}  # 1 = numeric x

function welford(c,v,   d) {        # running n and mu; m2 holds the rest
  n[c]++
  d = v - mu[c]
  mu[c] += d / n[c]
  m2[c] += d * (v - mu[c]) }

function _sd(c) { return n[c] > 1 ? sqrt(m2[c] / (n[c] - 1)) : 0 }

function dump(tag,t,   c,s) {       # one tagged settings line
  s=tag; for (c=1;c<=cols;c++) s = s OFS (c in t ? t[c] : ""); print s }

