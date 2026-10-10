// TWCNB: Rennie et al. ICML'03, Table 4 (steps 1-8)
// input rows: word counts..., label
const { opt, lines } = require("./lib")
opt.T = 0
const y = {}, d = {}, df = {}, w = {}

for (const [line, nr] of lines()) {
  const x = line.split(",")
  if (nr <= opt.T) { keep(x, nr); continue }
  if (nr === opt.T + 1) learn(x.length)
  console.log(classify(x), x.at(-1))
}

function keep(x, r) {                                    // step 1
  y[r] = x.at(-1); d[r] = {}
  for (let c = 0; c < x.length - 1; c++)
    if (x[c] > 0) { d[r][c] = Math.log(1 + +x[c]); df[c] = (df[c] ?? 0) + 1 }
}

function learn(nf) {
  const s = {}, all = {}, nh = {}
  let tot = 0
  for (const r in d) {
    const h = y[r], dr = d[r]
    let len = 0
    for (const c in dr) len += (dr[c] *= Math.log(opt.T / df[c])) ** 2 // 2
    for (const c in dr) {                                 // step 3
      const z = dr[c] / Math.sqrt(len + 1e-32)
      s[h] ??= {}
      s[h][c] = (s[h][c] ?? 0) + z
      all[c] = (all[c] ?? 0) + z
      nh[h] = (nh[h] ?? 0) + z
      tot += z
    }
  }
  for (const h in nh) {                                   // steps 4-6
    const wh = []
    for (let c = 0; c < nf - 1; c++)
      wh[c] = Math.log(((all[c] ?? 0) - (s[h][c] ?? 0) + 1) /
                       (tot - nh[h] + nf - 1))
    const z = -wh.reduce((a, b) => a + b, 0)
    w[h] = wh.map(v => v / z)
  }
}

function classify(x) {                                    // steps 7,8
  let best, out
  for (const h in w) {
    let t = 0
    for (let c = 0; c < x.length - 1; c++)
      t += Math.log(1 + +x[c]) * w[h][c]
    if (out === undefined || t < best) { best = t; out = h }
  }
  return out
}
