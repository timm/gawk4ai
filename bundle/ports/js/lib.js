// awk-style input. Args run left to right: NAME=value sets opt.NAME,
// anything else is a file ("-" = stdin); no files means stdin.
const fs = require("fs")

const opt = {}

function* lines() {                       // yields [line, NR, FNR]
  const args = process.argv.slice(2)
  if (args.every(a => /^[A-Za-z_]\w*=/.test(a))) args.push("-")
  let nr = 0
  for (const a of args) {
    const m = a.match(/^([A-Za-z_]\w*)=(.*)$/)
    if (m) { opt[m[1]] = isNaN(m[2]) ? m[2] : +m[2]; continue }
    const all = fs.readFileSync(a === "-" ? 0 : a, "utf8").split("\n")
    if (all.at(-1) === "") all.pop()
    let fnr = 0
    for (const line of all) yield [line, ++nr, ++fnr]
  }
}

function inc(o, ...keys) {                // o[k1]...[kn]++
  const last = keys.pop()
  for (const k of keys) o = o[k] ??= {}
  return o[last] = (o[last] ?? 0) + 1
}

const NUM = /^\s*[-+]?(\d+\.?\d*|\.\d+)([eE][-+]?\d+)?/

const isNum = s => typeof s === "number" || NUM.test(s) &&
  s.replace(NUM, "").trim() === ""        // awk "strnum": looks numeric

const num = s => {                        // awk's s+0: leading number
  if (typeof s === "number") return s
  const m = String(s).match(NUM)
  return m ? parseFloat(m[0]) : 0
}

const eq = (a, b) =>                      // awk ==, strnum aware
  isNum(a) && isNum(b) ? num(a) === num(b) : String(a) === String(b)

function g6(v) {                          // awk's print: "%.6g"
  if (Number.isInteger(v) && Math.abs(v) < 2 ** 63) return String(v)
  if (!isFinite(v)) return isNaN(v) ? "nan" : v > 0 ? "inf" : "-inf"
  const sign = v < 0 ? "-" : ""
  let [m, e] = Math.abs(v).toExponential(5).split("e")
  const [m30, e30] = Math.abs(v).toExponential(30).split("e")
  const d30 = m30.replace(".", "")        // C rounds exact ties to even
  if (/^50*$/.test(d30.slice(6)) && d30[5] % 2 === 0) [m, e] = [m30, e30]
  const d = m.replace(".", "").slice(0, 6)
  e = +e
  if (e < -4 || e >= 6) {
    const man = (d[0] + "." + d.slice(1)).replace(/\.?0+$/, "")
    return sign + man + "e" + (e < 0 ? "-" : "+") +
      String(Math.abs(e)).padStart(2, "0")
  }
  const int = e >= 0 ? d.slice(0, e + 1) : "0"
  const frac = (e >= 0 ? d.slice(e + 1) : "0".repeat(-e - 1) + d)
    .replace(/0+$/, "")
  return sign + int + (frac ? "." + frac : "")
}

module.exports = { opt, lines, inc, isNum, num, eq, g6 }
