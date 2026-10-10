// usage: node tree.js T=n [M=8] d   (d: binned, no header)
// regression tree: split on col<=bin (or col==symbol) that most
// reduces squared error; stop below M rows. Prints y^ y.
const { opt, lines, num, eq, g6 } = require("./lib")
Object.assign(opt, { M: 8, T: 0 })
const xs = [], ys = [], col = {}, cut = {}, mean = {}
let ncols

for (const [line, nr] of lines()) {
  const z = line.split(","), x = z.slice(0, -1)
  if (nr <= opt.T) { xs[nr] = x; ys[nr] = num(z.at(-1)); continue }
  if (nr === opt.T + 1) {
    ncols = x.length
    grow(Array.from({ length: opt.T }, (_, i) => i + 1), 1)
  }
  console.log(g6(leaf(x)), z.at(-1))
}

function grow(ids, k) {
  mean[k] = ids.reduce((s, i) => s + ys[i], 0) / ids.length
  if (ids.length < opt.M) return
  let best = sse(ids), bc, bv
  for (let c = 0; c < ncols; c++) {
    const seen = new Set()
    for (const i of ids) {
      const v = xs[i][c]
      if (seen.has(v)) continue
      seen.add(v)
      const e = sse(part(ids, c, v, true)) + sse(part(ids, c, v, false))
      if (e < best) { best = e; bc = c; bv = v }
    }
  }
  if (bc === undefined) return
  col[k] = bc; cut[k] = bv
  grow(part(ids, bc, bv, true), 2 * k)
  grow(part(ids, bc, bv, false), 2 * k + 1)
}

function part(ids, c, v, want) {
  return ids.filter(i => goes(xs[i][c], v) === want)
}

function goes(a, v) {                     // bins: <=; symbols: ==
  return /^[0-9]+$/.test(a + v) ? +a <= +v : eq(a, v)
}

function sse(ids) {
  if (!ids.length) return 0
  let s = 0, s2 = 0
  for (const i of ids) { s += ys[i]; s2 += ys[i] * ys[i] }
  return s2 - s * s / ids.length
}

function leaf(x) {
  let k = 1
  while (k in col) k = 2 * k + (goes(x[col[k]], cut[k]) ? 0 : 1)
  return mean[k]
}
