-- usage: lua knnr.lua T=n [K=5] s    (s: shuffled, header)
-- kNN on raw rows: numbers scaled 0..1 by train min/max,
-- symbols 0/1, "?" 1. Predict mean y of K nearest. Prints y^ y.
package.path = (arg[0]:match("(.*/)") or "./") .. "?.lua;" .. package.path
local lib = require("lib")
local num, str = lib.num, lib.str

local O = {K = 5, T = 0}
local isnum, x, y, lo, hi = {}, {}, {}, {}, {}

local function train(t, r)
  y[r], x[r] = num(t[#t]), table.move(t, 1, #t - 1, 1, {})
  for c = 1, #t - 1 do
    local v = t[c]
    if isnum[c] and v ~= "?" then
      v = num(v)
      if not lo[c] or v < lo[c] then lo[c] = v end
      if not hi[c] or v > hi[c] then hi[c] = v end end end end

local function gap(c, a, b)
  if a == "?" or b == "?" then return 1 end
  if not isnum[c] then return lib.eq(a, b) and 0 or 1 end
  return (num(a) - num(b)) / (hi[c] - lo[c] + 1E-32) end

local function knn(t)
  local d, sum, j = {}, 0, 0
  for r, row in pairs(x) do
    d[r] = 0
    for c, v in ipairs(row) do
      local g = gap(c, v, t[c])
      d[r] = d[r] + g * g end end
  for _, r in ipairs(lib.byval(d)) do
    sum, j = sum + y[r], j + 1
    if j == O.K then break end end
  return sum / j end

lib.run(O, function(line, _, _, nr)
  local t = lib.split(line, " *, *")
  if nr == 1 then
    for c = 1, #t - 1 do isnum[c] = t[c]:find("^%u") ~= nil end
  elseif nr <= O.T + 1 then train(t, nr)
  else print(str(knn(t)) .. " " .. t[#t]) end end)
