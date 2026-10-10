-- usage: ...| lua nb.lua | lua knn.lua T=n d -
-- y = mean y of K nearest train rows in the predicted y-bin
-- (ALL=1: ignore the bin; S=n: keep only n train rows;
--  I=1: only search rows sharing the test row's bin in the
--       train column with most variance)
package.path = (arg[0]:match("(.*/)") or "./") .. "?.lua;" .. package.path
local lib = require("lib")
local run, split, str = lib.run, lib.split, lib.str

local O = {B = 7, K = 5, ALL = 0, S = 0, I = 0, T = 0}
local x, y, test, bin, idx = {}, {}, {}, {}, {}
local n, s, s2, col = 0, 0, 0, nil

local function train(t, r)
  local v = tonumber(t[#t]) or 0
  n, s, s2 = n + 1, s + v, s2 + v * v
  y[r], x[r] = v, table.move(t, 1, #t - 1, 1, {}) end

local function bins()
  for r, v in pairs(y) do bin[r] = lib.bin(O.B, n, s, s2, v) end end

local function index1()                         -- most-variance col
  local k, m, m2, most = {}, {}, {}, 0
  for _, row in pairs(x) do
    for c, v in ipairs(row) do
      if v:find("^%d+$") then
        v = tonumber(v)
        k[c], m[c] = (k[c] or 0) + 1, (m[c] or 0) + v
        m2[c] = (m2[c] or 0) + v * v end end end
  for c in pairs(k) do
    local mu = m[c] / k[c]
    if m2[c] / k[c] - mu * mu > most then
      most, col = m2[c] / k[c] - mu * mu, c end end
  if not col then return end
  for r, row in pairs(x) do
    local v = row[col]
    idx[v] = idx[v] or {}
    table.insert(idx[v], r) end end

local function dist(a, b)                 -- bins: ordered; else 0/1
  if a == "?" or b == "?" then return 1 end
  local u, v = tonumber(a), tonumber(b)
  if (a .. b):find("^%d+$") then return math.abs(u - v) / (O.B - 1) end
  if u and v then return u ~= v and 1 or 0 end
  return a ~= b and 1 or 0 end

local function near(r, z)
  local d = 0
  for c, v in ipairs(x[r]) do d = d + dist(v, z[c]) end
  return d end

local function knn(p, z)
  local rows, d = {}, {}
  local same = col and idx[z[col]] or {}
  if O.I ~= 0 and #same >= O.K then
    rows = table.move(same, 1, #same, 1, {})
  else
    for r in pairs(y) do
      if O.ALL ~= 0 or bin[r] == tonumber(p) then rows[#rows + 1] = r end
    end end
  for _, r in ipairs(rows) do d[r] = near(r, z) end
  table.sort(rows, function(a, b)      -- ties: lower row index first
    if d[a] ~= d[b] then return d[a] < d[b] end
    return a < b end)
  local sum, j = 0, 0
  for _, r in ipairs(rows) do
    sum, j = sum + y[r], j + 1
    if j == O.K then break end end
  return sum / j end

run(O, function(line, file, fnr)
  if file == 1 then
    if fnr > O.T then test[fnr - O.T] = line
    elseif O.S == 0 or fnr <= O.S then train(split(line, " *, *"), fnr) end
  else
    if fnr == 1 then
      bins()
      if O.I ~= 0 then index1() end end
    local z = split(test[fnr], " *, *")
    print(str(knn(line:match("%S+"), z)) .. " " .. z[#z]) end end)
