// usage: node knnr.js T=n [K=5] s    (s: shuffled, header)
// kNN on raw rows: numbers scaled 0..1 by train min/max,
// symbols 0/1, "?" 1. Predict mean y of K nearest. Prints y^ y.
const { opt, lines, num, eq, g6 } = require("./lib")
Object.assign(opt, { K: 5, T: 0 })
const isNumCol = [], lo = [], hi = [], rows = []   // rows: [x, y]

for (const [line, nr] of lines()) {
  const z = line.split(/ *, */), x = z.slice(0, -1)
  if (nr === 1) x.forEach((name, c) => isNumCol[c] = /^[A-Z]/.test(name))
  else if (nr <= opt.T + 1) train(x, z.at(-1))
  else console.log(g6(knn(x)), z.at(-1))
}

function train(x, y) {
  rows.push([x, y])
  x.forEach((v, c) => {
    if (!isNumCol[c] || v === "?") return
    if (lo[c] === undefined || num(v) < lo[c]) lo[c] = num(v)
    if (hi[c] === undefined || num(v) > hi[c]) hi[c] = num(v)
  })
}

function knn(x) {
  const d = rows.map(([r], i) =>         // [row index, distance^2]
    [i, r.reduce((sum, a, c) => sum + gap(c, a, x[c]) ** 2, 0)])
  d.sort((a, b) => a[1] - b[1] || a[0] - b[0])  // ties: row order
  const near = d.slice(0, opt.K)
  return near.reduce((sum, [i]) => sum + num(rows[i][1]), 0) / near.length
}

function gap(c, a, b = "") {
  if (a === "?" || b === "?") return 1
  if (!isNumCol[c]) return eq(a, b) ? 0 : 1
  return (num(a) - num(b)) / (hi[c] - lo[c] + 1e-32)
}
