// usage: node tfidf.js [K=64] f f
// (text<TAB>label) -> counts of the K words with most tf*idf
const { opt, lines } = require("./lib")
opt.K = 64
const STOP = new Set(("that this with from have which their these " +
  "been such more were also they than into").split(" "))
const df = new Map(), tf = new Map()
let N = 0, keep = []

for (const [line, nr, fnr] of lines()) {
  const [text, label = ""] = line.split("\t")
  if (fnr === 1) { if (nr > 1) keep = top(); continue }
  if (nr === fnr) { count(text); continue }
  const a = words(text)
  const out = Array.from({ length: opt.K }, (_, j) => a.get(keep[j]) ?? 0)
  console.log([...out, label].join(","))
}

function words(text) {
  const a = new Map()
  for (const w of text.toLowerCase().split(/[^a-z]+/))
    if (w.length > 3 && !STOP.has(w)) a.set(w, (a.get(w) ?? 0) + 1)
  return a
}

function count(text) {
  N++
  for (const [w, k] of words(text)) {
    df.set(w, (df.get(w) ?? 0) + 1)
    tf.set(w, (tf.get(w) ?? 0) + k)
  }
}

function top() {                          // ties: word descending (gawk)
  const score = new Map()
  for (const [w, k] of df) score.set(w, tf.get(w) * Math.log(N / k))
  return [...score].sort((a, b) => b[1] - a[1] || (a[0] < b[0] ? 1 : -1))
    .slice(0, opt.K).map(([w]) => w)
}
