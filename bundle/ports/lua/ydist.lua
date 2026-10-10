-- usage: lua ydist.lua f f    (MOOT optimize csv, 2 passes)
-- keep x columns; swap the goals (names ending in + or -) for one
-- column: distance to heaven (0 = best). Skips names ending in X.
package.path = (arg[0]:match("(.*/)") or "./") .. "?.lua;" .. package.path
local lib = require("lib")
local num = lib.num

local w, x, lo, hi = {}, {}, {}, {}     -- w[c]: heaven 1=max, 0=min

local function header(t, nr)
  local out = {}
  for c, s in ipairs(t) do
    if s:find("[+-]$") then w[c] = s:find("%+$") and 1 or 0
    elseif not s:find("X$") then x[c] = true; out[#out + 1] = s end end
  out[#out + 1] = "D2h-"
  if nr > 1 then print(table.concat(out, ",")) end end

local function d2h(t)
  local d, n = 0, 0
  for c, h in pairs(w) do
    local v = h - (num(t[c]) - lo[c]) / (hi[c] - lo[c] + 1E-32)
    d, n = d + v * v, n + 1 end
  return math.sqrt(d / n) end

lib.run({}, function(line, file, fnr, nr)
  local t = lib.split(line, " *, *")
  if fnr == 1 then header(t, nr)
  elseif file == 1 then
    for c in pairs(w) do
      if t[c] ~= "?" then
        local v = num(t[c])
        if not lo[c] or v < lo[c] then lo[c] = v end
        if not hi[c] or v > hi[c] then hi[c] = v end end end
  else
    local out = {}
    for c = 1, #t do if x[c] then out[#out + 1] = t[c] end end
    out[#out + 1] = lib.str(d2h(t))
    print(table.concat(out, ",")) end end)
