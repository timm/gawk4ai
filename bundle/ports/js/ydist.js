// usage: node ydist.js f f    (MOOT optimize csv, 2 passes)
// keep x columns; swap the goals (names ending in + or -) for one
// column: distance to heaven (0 = best). Skips names ending in X.
const { lines, num, g6 } = require("./lib")
const w = {}, keep = new Set(), lo = {}, hi = {}

for (const [line, nr, fnr] of lines()) {
  const z = line.split(/ *, */)
  if (fnr === 1) header(z, nr > 1)
  else if (nr === fnr) {
    for (const c in w) if (z[c] !== "?") minmax(c, num(z[c]))
  } else console.log(z.filter((_, c) => keep.has(c)).join(",") +
                     "," + g6(d2h(z)))
}

function header(z, show) {
  z.forEach((name, c) => {
    if (/[+-]$/.test(name)) w[c] = /\+$/.test(name) ? 1 : 0  // heaven
    else if (!/X$/.test(name)) keep.add(c)
  })
  if (show) console.log([...z.filter((_, c) => keep.has(c)), "D2h-"]
    .join(","))
}

function minmax(c, v) {
  if (!(c in lo) || v < lo[c]) lo[c] = v
  if (!(c in hi) || v > hi[c]) hi[c] = v
}

function d2h(z) {
  let d = 0, n = 0
  for (const c in w) {
    const t = w[c] - (num(z[c]) - lo[c]) / (hi[c] - lo[c] + 1e-32)
    d += t * t; n++
  }
  return Math.sqrt(d / n)
}
