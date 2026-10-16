# usage: gawk -f tfidf.awk [K=64] f f
# (text<TAB>label) -> counts of the K words with most tf*idf
BEGIN   { FS="\t"; OFS=","; K=64
          STOP = "^(that|this|with|from|have|which|their|these|"
          STOP = STOP "been|such|more|were|also|they|than|into)$" }
FNR==1  { if (NR > 1) top(); next }
NR==FNR { count(); next }
        { print row() }

function words(a,   n,i,w,s) {
  s = $1; sub(/^(train|test|header),/, "", s)  # split.awk's tag is not
  n = split(tolower(s), w, /[^a-z]+/)          # text: do not index it
  for (i=1; i<=n; i++)
    if (length(w[i]) > 3 && w[i] !~ STOP) a[w[i]]++ }

function count(   a,w) {
  N++; words(a); for (w in a) { df[w]++; tf[w] += a[w] } }

function top(   w,j,score) {
  for (w in df) score[w] = tf[w] * log(N/df[w])
  PROCINFO["sorted_in"] = "@val_num_desc"
  for (w in score) if (++j <= K) keep[j] = w
  delete PROCINFO["sorted_in"] }

function row(   a,j,out) {
  words(a); for (j=1; j<=K; j++) out = out (a[keep[j]]+0) OFS
  return out $2 }
