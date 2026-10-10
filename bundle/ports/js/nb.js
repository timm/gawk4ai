// usage: node nb.js [T=n W=n] f   train rows 1..T, test rows > W
const { opt, lines, inc } = require("./lib")
Object.assign(opt, { m: 2, k: 1, T: 1e32, W: 10 })
const f = {}                              // f[class][col][value] = count
let N = 0

for (const [line, nr] of lines()) {
  const x = line.split(/ *, */)
  if (nr > opt.W) console.log(classify(x), x.at(-1))
  if (nr <= opt.T) train(x)
}

function train(x) {
  N++
  x.forEach((v, c) => { if (v !== "?") inc(f, x.at(-1), c, v) })
}

function classify(x) {
  let best, out
  for (const h in f) {
    const t = like(h, x)
    if (out === undefined || t > best) { best = t; out = h }
  }
  return out
}

function like(h, x) {                     // log P(h) + sum log P(x|h)
  const { m, k } = opt, last = x.length - 1, fh = f[h]
  const n = fh[last]?.[h] ?? 0
  const p = (n + k) / (N + k * Object.keys(f).length)
  let out = Math.log(p)
  for (let c = 0; c < last; c++)
    if (x[c] !== "?") out += Math.log(((fh[c]?.[x[c]] ?? 0) + m*p) / (n+m))
  return out
}
