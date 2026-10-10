// usage: node shuffle.js [seed=1] f    (header stays first)
const { opt, lines } = require("./lib")
opt.seed = 1
const rows = []
let rand

for (const [line, nr] of lines()) {
  if (nr === 1) { rand = mulberry32(opt.seed); console.log(line) }
  else rows.push(line)
}
for (let i = rows.length - 1; i > 0; i--) {     // Fisher-Yates
  const j = Math.floor(rand() * (i + 1));
  [rows[i], rows[j]] = [rows[j], rows[i]]
}
for (const row of rows) console.log(row)

function mulberry32(a) {                        // small seeded PRNG
  return () => {
    a = (a + 0x6D2B79F5) | 0
    let t = Math.imul(a ^ (a >>> 15), 1 | a)
    t = (t + Math.imul(t ^ (t >>> 7), 61 | t)) ^ t
    return ((t ^ (t >>> 14)) >>> 0) / 4294967296
  }
}
