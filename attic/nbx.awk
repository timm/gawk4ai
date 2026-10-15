# usage: ... | gawk -f xval.awk | gawk -f nbx.awk [M=2 K=1]
# naive Bayes that learns :train, guesses :test, and forgets on a blank
# line. All its state is one array, so forgetting is one delete.
# vim: set et sw=2 ts=2 sts=2 cc=75 :
BEGIN      { FS=" *, *"; M=2; K=1 }   # spaces are fine
/^$/       { delete my; next }                 # fold over: forget it all
/^:x,/     { delete X; for(c=2;c<=NF;c++) if ($c != "") X[c] }
/^:train,/ { learn() }
/^:test,/  { hit += classify()==$NF; tot++ }
END        { printf "%.1f%% of %d\n", 100*hit/tot, tot }

function learn(   c) {
  if (!(("H",$NF) in my)) my["k"]++            # one more class to smooth
  my["n"]++; my["H",$NF]++
  for(c in X) if ($c != "?") my["F",$NF,c,$c]++ }

function classify(   h,p,v,best,out) {
  for(h in my) if (h ~ /^H/) { split(h,p,SUBSEP)
    if ((v=like(p[2])) > best || !out) { best=v; out=p[2] } }
  return out }

function like(h,   c,p,out) {
  p = (my["H",h] + K) / (my["n"] + K*my["k"])
  out = log(p)
  for(c in X) if ($c != "?")
    out += log((my["F",h,c,$c] + M*p) / (my["H",h] + M))
  return out }
