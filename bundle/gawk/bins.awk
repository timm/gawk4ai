# usage: ... | gawk -f shuf.awk | gawk -f bins.awk [B=10]
# Numeric cells -> bin number, using mu,sd frozen at the end of each era.
# Holds one era so era 1 is binned against real stats, not against nothing.
BEGIN    { B=10 }          # a numeric column becomes this many bins
BEGIN    { FS=","          # shuf already trimmed the padded commas
           OFS=","         # and rebuilt every record with this
           delete num      # num[c]: live n,m1,m2 per numeric col
           delete buf }    # the era read so far, until it closes
FNR==1   { for(_=1; _<=NF; _++) head(_,$_,num); print; next }
/^$/     { dump(buf,num); print ""; next }  # dump ate $0, so print ""
         { buf[length(buf)+1] = $0
           for(_ in num) welford(_,$_,num) }
END      { dump(buf,num) }

function head(c,s,num) {                 # numeric: leading capital,
  if (s !~ /[!X]$/ && s ~ /^[A-Z]/) 
    num[c]["m1"] = 0 }

function welford(c,v,num,   d) {         # fold one cell into the stats
  if (v == "?") return
  num[c]["n"]++; d = v - num[c]["m1"]
  num[c]["m1"] += d/num[c]["n"]
  num[c]["m2"] += d*(v - num[c]["m1"]) }

function update_sd(num,mu,sd,   c) {       # frozen only for one dump
  for(c in num) { mu[c] = num[c]["m1"]
    sd[c] = num[c]["n"] < 2 ? 0 : sqrt(num[c]["m2"]/(num[c]["n"]-1)) } }

function dump(buf,num,   i,c,mu,sd) {        # emit the held era, binned
  update_sd(num,mu,sd)
  for(i=1; i<=length(buf); i++) { 
    $0 = buf[i]
    for(c in num) if ($c != "?") 
      $c = int(B* cdf($c, mu[c], sd[c]))
    print }
  delete buf }

function cdf(v,mu,s,   z) {
  z = (v - mu)/(s + 1E-32); z = z>3 ? 3 : (z<-3 ? -3 : z)
  return 1/(1 + exp(-1.7*z)) }
