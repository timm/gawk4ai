# usage: ... | gawk -f shuf.awk | gawk -f bins.awk [B=10]
# Numeric cells -> bin number.  mu,sd come from the rows BEFORE the
# blank line, so held-out rows never touch the stats that bin them.
BEGIN    { B=10 }          # a numeric column becomes this many bins
BEGIN    { FS=","          # shuf already trimmed the padded commas
           OFS="," }       # and rebuilt every record with this
FNR==1   { print; train() }  # not BEGIN: knobs land after BEGIN runs

function head(num,   c) {                # numeric: leading capital,
  for(c=1; c<=NF; c++)                   # not the class, not an X col
    if ($c !~ /[!X+-]$/ && $c ~ /^[A-Z]/) num[c]["mu"] = 0 }

function train(   c,num,buffer) {        # num[c]: n,mu,m2 then sd
  delete buffer                          # types it: length() of an
  head(num)                              # untyped local makes it scalar
  while (getline > 0) {
    if ($0 == "") { freeze(num); dump(num, buffer); print ""
                    return test(num) }
    buffer[length(buffer)+1] = $0
    for(c in num) welford(num, c, $c) } }

function test(num) {                     # bin all that follow
  while (getline > 0) { bin(num); print } }

function welford(num,c,v,   d) {         # fold one cell into the stats
  if (v == "?") return
  num[c]["n"]++; 
  d             = v - num[c]["mu"]
  num[c]["mu"] += d/num[c]["n"]
  num[c]["m2"] += d*(v - num[c]["mu"]) }

function freeze(num,   c,n) {            # training sd, kept beside mu
  for(c in num) { n = num[c]["n"]
    num[c]["sd"] = n < 2 ? 0 : sqrt(num[c]["m2"]/(n-1)) } }

function bin(num,   c) {                 # this row, numerics binned
  for(c in num) if ($c != "?")
    $c = int(B * cdf($c, num[c]["mu"], num[c]["sd"])) }

function dump(num,buffer,   i) {         # the backlog, now binnable
  for(i=1; i<=length(buffer); i++) { $0 = buffer[i]; bin(num); print } }

function cdf(v,mu,s,   z) {
  z = (v - mu)/(s + 1E-32); z = z>3 ? 3 : (z<-3 ? -3 : z)
  return 1/(1 + exp(-1.7*z)) }
