// usage: node ybin.js T=n d d  (y -> bin; 1st T rows)
const { opt, lines } = require("./lib")
Object.assign(opt, { B: 7, T: 0 })
let n = 0, s = 0, s2 = 0

for (const [line, nr, fnr] of lines()) {
  const x = line.split(","), y = x.at(-1)
  if (nr === fnr) {
    if (fnr <= opt.T && y !== "?") { n++; s += +y; s2 += y * y }
    continue
  }
  if (y !== "?") x[x.length - 1] = bin(y)
  console.log(x.join(","))
}

function bin(y) {
  const mu = s / n, sd = Math.sqrt(s2 / n - mu ** 2) + 1e-32
  return Math.trunc(opt.B / (1 + Math.exp(-1.7 * (y - mu) / sd)))
}
