// usage: ... | node rank.js [C=5]   (lines: predicted actual)
// check the C rows with the best (lowest) predictions; print how
// the best of them really ranks among all n test rows, as a percent, 100*r/n.
const { opt, lines, num, g6 } = require("./lib")
Object.assign(opt, { C: 5 })
const rows = []                           // [index, predicted, actual]

for (const [line] of lines()) {
  const [p, a] = line.trim().split(/\s+/)
  rows.push([rows.length, num(p), num(a)])
}
const checked = rows.toSorted((x, y) => x[1] - y[1] || x[0] - y[0])
  .slice(0, opt.C)
const best = Math.min(...checked.map(r => r[2]))
const rank = rows.filter(r => r[2] < best).length + 1
console.log((100 * rank / rows.length).toFixed(1))
