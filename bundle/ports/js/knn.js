// usage: ...| nb.js | node knn.js T=n d -
// y = mean y of K nearest train rows in the predicted y-bin
// (ALL=1: ignore the bin; S=n: keep only n train rows;
//  I=1: only search rows sharing the test row's bin in the
//       train column with most variance)
const { opt, lines } = require("./lib")
Object.assign(opt, { B: 7, K: 5, ALL: 0, S: 0, I: 0, T: 0 })
const FS = / *, */
const x = {}, y = {}, bin = {}, test = {}, idx = {}
let n = 0, s = 0, s2 = 0, Col

for (const [line, nr, fnr] of lines()) {
  if (nr === fnr && fnr <= opt.T) {
    if (!opt.S || fnr <= opt.S) train(line.split(FS), fnr)
  } else if (nr === fnr) test[fnr - opt.T] = line
  else {
    if (fnr === 1) { bins(); if (opt.I) index1() }
    console.log(predict(line, test[fnr]))
  }
}

function train(z, r) {
  y[r] = +z.at(-1); n++; s += y[r]; s2 += y[r] ** 2
  x[r] = z.slice(0, -1)
}

function bins() {
  const mu = s / n, sd = Math.sqrt(s2 / n - mu ** 2) + 1e-32
  for (const r in y)
    bin[r] = Math.trunc(opt.B / (1 + Math.exp(-1.7 * (y[r] - mu) / sd)))
}

function index1() {                       // Col = most-variance col
  const k = {}, m = {}, m2 = {}
  for (const r in x) x[r].forEach((v, c) => {
    if (!/^[0-9]+$/.test(v)) return
    k[c] = (k[c] ?? 0) + 1
    m[c] = (m[c] ?? 0) + +v
    m2[c] = (m2[c] ?? 0) + v * v
  })
  let most = 0
  for (const c in k) {
    const v = m2[c] / k[c] - (m[c] / k[c]) ** 2
    if (v > most) { most = v; Col = +c }
  }
  for (const r in x) (idx[x[r][Col]] ??= []).push(r)
}

function predict(line, row) {
  const p = line.trim().split(/\s+/)[0], z = row.split(FS)
  return g6(knn(p, z)) + " " + z.at(-1)
}

function knn(p, z) {
  const d = []                            // [row, distance]
  const near = r => x[r].reduce((sum, a, c) => sum + dist(a, z[c]), 0)
  const pool = idx[z[Col]] ?? []
  if (opt.I && pool.length >= opt.K) for (const r of pool) d.push([r, near(r)])
  else for (const r in y)
    if (opt.ALL || bin[r] === +p) d.push([r, near(r)])
  d.sort((a, b) => a[1] - b[1] || a[0] - b[0])  // ties: row order (as gawk)
  const best = d.slice(0, opt.K)
  return best.reduce((sum, [r]) => sum + y[r], 0) / best.length
}

function dist(a, b = "") {                // bins: ordered; else 0/1
  if (a === "?" || b === "?") return 1
  if (/^[0-9]+$/.test(a + b)) return Math.abs(a - b) / (opt.B - 1)
  return a !== b ? 1 : 0
}

function g6(v) {                          // awk's default "%.6g"
  return Number.isInteger(v) ? String(v) : String(+v.toPrecision(6))
}
