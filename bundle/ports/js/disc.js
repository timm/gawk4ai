// usage: node disc.js [B=7] f f  (pass 1: mean,sd; pass 2: bins)
const { opt, lines } = require("./lib")
opt.B = 7
const num = {}, n = {}, s = {}, s2 = {}

for (const [line, nr, fnr] of lines()) {
  const x = line.split(",")
  if (fnr === 1) header(x, line, nr)
  else if (nr === fnr) stats(x)
  else console.log(bins(x).join(","))
}

function header(x, line, nr) {
  for (let c = 0; c < x.length - 1; c++) num[c] = /^[A-Z]/.test(x[c])
  if (nr > 1) console.log(line)
}

function stats(x) {
  for (const c in num) if (num[c] && x[c] !== "?") {
    n[c] = (n[c] ?? 0) + 1
    s[c] = (s[c] ?? 0) + +x[c]
    s2[c] = (s2[c] ?? 0) + x[c] * x[c]
  }
}

function bins(x) {
  for (const c in n) if (x[c] !== "?") x[c] = bin(c, x[c])
  return x
}

function bin(c, x) {
  const mu = s[c] / n[c], sd = Math.sqrt(s2[c] / n[c] - mu ** 2) + 1e-32
  return Math.trunc(opt.B / (1 + Math.exp(-1.7 * (x - mu) / sd)))
}
