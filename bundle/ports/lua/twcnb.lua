-- TWCNB: Rennie et al. ICML'03, Table 4 (steps 1-8)
-- input rows: word counts..., label
package.path = (arg[0]:match("(.*/)") or "./") .. "?.lua;" .. package.path
local lib = require("lib")
local run, split = lib.run, lib.split

local O = {T = 0}
local y, d, df, w = {}, {}, {}, {}

local function keep(t, r)                                -- step 1
  y[r] = t[#t]
  for c = 1, #t - 1 do
    local v = tonumber(t[c]) or 0
    if v > 0 then
      d[r] = d[r] or {}
      d[r][c], df[c] = math.log(1 + v), (df[c] or 0) + 1 end end end

local function learn(nf)
  local s, all, nh, tot = {}, {}, {}, 0
  for r, row in pairs(d) do
    local h, len = y[r], 0
    for c, v in pairs(row) do                            -- step 2
      row[c] = v * math.log(O.T / df[c])
      len = len + row[c] * row[c] end
    s[h] = s[h] or {}
    for c, v in pairs(row) do                            -- step 3
      local z = v / math.sqrt(len + 1E-32)
      s[h][c], all[c] = (s[h][c] or 0) + z, (all[c] or 0) + z
      nh[h], tot = (nh[h] or 0) + z, tot + z end end
  for h, n in pairs(nh) do                               -- steps 4-6
    local z = 0
    w[h] = {}
    for c = 1, nf - 1 do
      w[h][c] = math.log(((all[c] or 0) - (s[h][c] or 0) + 1)
                         / (tot - n + nf - 1))
      z = z - w[h][c] end
    for c = 1, nf - 1 do w[h][c] = w[h][c] / z end end end

local function classify(t)                               -- steps 7,8
  local best, out
  for h, wh in pairs(w) do
    local sum = 0
    for c = 1, #t - 1 do
      sum = sum + math.log(1 + (tonumber(t[c]) or 0)) * wh[c] end
    if not out or sum < best then best, out = sum, h end end
  return out or "" end

run(O, function(line, _, _, nr)
  local t = split(line, ",")
  if nr <= O.T then keep(t, nr); return end
  if nr == O.T + 1 then learn(#t) end
  print(classify(t) .. " " .. t[#t]) end)
