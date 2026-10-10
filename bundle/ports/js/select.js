// usage: node select.js T=n [K=5] d d
// keep K cols with least H(class|col); default K = half
const { opt, lines, inc } = require("./lib")
Object.assign(opt, { K: 0, T: 0 })        // K=0: keep half
const n = {}, ny = {}                     // n[c][v], ny[c][v][y]
let use

for (const [line, nr, fnr] of lines()) {
  const x = line.split(",")
  if (nr === fnr) { if (fnr <= opt.T) count(x); continue }
  if (fnr === 1) use = rank(x.length)
  const last = x.length - 1
  console.log(x.filter((v, c) => use.has(c) || c === last).join(","))
}

function count(x) {
  for (let c = 0; c < x.length - 1; c++)
    if (x[c] !== "?") { inc(n, c, x[c]); inc(ny, c, x[c], x.at(-1)) }
}

function rank(nf) {
  const e = {}
  for (const c in n) {
    e[c] = 0
    for (const v in n[c]) for (const y in ny[c][v]) {
      const p = ny[c][v][y] / n[c][v]
      e[c] -= n[c][v] / opt.T * p * Math.log(p)
    }
  }
  const K = opt.K || Math.trunc((nf - 1) / 2)
  const cols = Object.keys(e).sort((a, b) => e[a] - e[b] || a - b)
  return new Set(cols.slice(0, K).map(Number))
}
