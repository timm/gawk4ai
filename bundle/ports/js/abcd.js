// usage: ... | node abcd.js   (input lines: predicted actual)
const { lines, inc } = require("./lib")
const got = {}, want = {}, hit = {}
let n = 0

for (const [line] of lines()) {
  const [p = "", a = ""] = line.trim().split(/\s+/)
  n++; inc(got, p); inc(want, a)
  hit[p] = (hit[p] ?? 0) + (p === a)
}
report()

function report() {
  const pad = (v, w) => String(v).padStart(w)
  const out = Object.keys(want).map(x => {
    const d = hit[x] ?? 0, b = want[x] - d, c = (got[x] ?? 0) - d
    const a = n - b - c - d
    const pd = pc(d, b + d)
    const cells = [want[x], a, b, c, d].map(v => pad(v, 4)).concat(
      [pc(a + d, n), pc(d, c + d), pc(c, a + c), pd].map(v => pad(v, 3)))
    return { pd, line: cells.join(",") + ", " + x }
  })
  out.sort((u, v) => v.pd - u.pd || (u.line < v.line ? -1 : 1))
  console.log("   n,   a,   b,   c,   d,acc,pre, pf, pd, class")
  for (const o of out) console.log(o.line)
}

function pc(x, y) { return y ? Math.trunc(100 * x / y + .5) : 0 }
