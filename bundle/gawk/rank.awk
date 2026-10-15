# usage: gawk -f shuf.awk [Test=.25] f.csv | gawk -f rank.awk [K=25 C=5]
# (run it from this directory, or point AWKPATH here: dist.awk is @included)
# Many goals, few labels.  Label the first K training rows and score
# them; a held-out row is then worth what its nearest label is worth.
# Label the C that look best, keep the best of those, and print where
# it really lands: 0 = we found the very best held-out row.
BEGIN    { K=25            # rows we label up front, to learn from
           C=5             # rows we label at the end, to choose from
           Rnd=0           # >0: skip the model, label this many at random
           Seed=1 }        # ...and this seeds that coin, nothing else
BEGIN    { FS="," }        # shuf already trimmed the padded commas
@include "dist.awk"        # the stateless half: see that file

FNR==1   { srand(Seed); train() }   # not BEGIN: knobs land after it

function train(   i,n,x,w,lo,hi,ylo,yhi,now,xs,ys,ly) {
  head(x, w)                             # lo,hi: the x span.  x is free,
  while (getline > 0) {                # so every training row widens it
    if ($0 == "") {                      # ylo,yhi: the y we paid to see
      for(i in ys) ly[i] = disty(w, ylo, yhi, ys[i])
      return test(x, w, lo, hi, ylo, yhi, xs, ly) }
    cells(x, now); grow(x, now, lo, hi)
    if (++n <= K) { cells(x, xs[n]); cells(w, ys[n])
                    grow(w, ys[n], ylo, yhi) } } }

function test(x,w,lo,hi,ylo,yhi,xs,ly,   m,now,ts,guess,tlo,thi) {
  while (getline > 0) {                # guessing knows the train span
    cells(x, now)                        # and nothing else, so an x cell
    guess[++m] = ly[near(x, lo, hi, xs, now)]      # can fall outside it
    cells(w, ts[m])                      # -- which is why gap() caps
    grow(w, ts[m], tlo, thi) }           # held back until guessing ends
  grow(tlo, tlo, ylo, yhi)               # a span folds into another as
  grow(thi, thi, ylo, yhi)               # its own two rows: lo, then hi
  return report(w, ylo, yhi, ts, guess) }

function report(w,ylo,yhi,ts,guess,   j,t,ay,pick) {
  for(j in ts) ay[j] = disty(w, ylo, yhi, ts[j])
  pick = Rnd ? coin(ay) : chose(guess, ay)
  for(j in ts) t += ay[j] < ay[pick]     # how many were really better
  print int(100 * t / length(ts)) }

function coin(ay,   i,j,n,out) {          # the no-model baseline: pay
  n = length(ay)                          # for Rnd rows, keep the best
  for(i=1; i<=Rnd && i<=n; i++) { j = int(rand()*n)+1
    if (!out || ay[j] < ay[out]) out = j }
  return out }

function chose(guess,ay,   i,j,out) {     # the C we label last
  PROCINFO["sorted_in"] = "@val_num_asc"  # ...so walk best-looking first
  for(j in guess) { 
    if (++i > C) break    # only loop that wants an order,
    if (!out || ay[j] < ay[out]) out = j} # so put it back before we leave
  PROCINFO["sorted_in"] = ""
  return out }                            # the best of what we paid for
