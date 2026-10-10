-- usage: lua select.lua T=n [K=5] d d
-- keep K cols with least H(class|col); default K = half
package.path = (arg[0]:match("(.*/)") or "./") .. "?.lua;" .. package.path
local lib = require("lib")
local run, split = lib.run, lib.split

local O = {K = 0, T = 0}
local ny, use = {}, {}       -- ny[col][value][class] = count

local function count(t)
  local y = t[#t]
  for c = 1, #t - 1 do
    local v = t[c]
    if v ~= "?" then
      ny[c] = ny[c] or {}
      ny[c][v] = ny[c][v] or {}
      ny[c][v][y] = (ny[c][v][y] or 0) + 1 end end end

local function rank(nf)
  local e, cols = {}, {}
  for c, vs in pairs(ny) do
    e[c], cols[#cols + 1] = 0, c
    for _, ys in pairs(vs) do
      local n = 0
      for _, k in pairs(ys) do n = n + k end
      for _, k in pairs(ys) do
        local p = k / n
        e[c] = e[c] - n / O.T * p * math.log(p) end end end
  table.sort(cols, function(a, b)   -- ties: lower column first
    if e[a] ~= e[b] then return e[a] < e[b] end
    return a < b end)
  local K = O.K ~= 0 and O.K or (nf - 1) // 2
  for j = 1, math.min(K, #cols) do use[cols[j]] = true end end

run(O, function(line, file, fnr)
  local t = split(line, ",")
  if file == 1 then
    if fnr <= O.T then count(t) end
  else
    if fnr == 1 then rank(#t) end
    local out = {}
    for c = 1, #t - 1 do if use[c] then out[#out + 1] = t[c] end end
    out[#out + 1] = t[#t]
    print(table.concat(out, ",")) end end)
