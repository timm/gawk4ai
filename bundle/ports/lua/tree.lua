-- usage: lua tree.lua T=n [M=8] d   (d: binned, no header)
-- regression tree: split on col<=bin (or col==symbol) that most
-- reduces squared error; stop below M rows. Prints y^ y.
package.path = (arg[0]:match("(.*/)") or "./") .. "?.lua;" .. package.path
local lib = require("lib")

local O = {M = 8, T = 0}
local x, y, mean, col, cut = {}, {}, {}, {}, {}
local nx                                    -- number of x columns

local function goes(a, v)                  -- bins: <=; symbols: ==
  if (a .. v):find("^%d+$") then return tonumber(a) <= tonumber(v) end
  return lib.eq(a, v) end

local function part(ids, c, v, want)
  local out = {}
  for _, r in ipairs(ids) do
    if goes(x[r][c], v) == want then out[#out + 1] = r end end
  return out end

local function sse(ids)
  local s, s2 = 0, 0
  if #ids == 0 then return 0 end
  for _, r in ipairs(ids) do s, s2 = s + y[r], s2 + y[r] * y[r] end
  return s2 - s * s / #ids end

local function grow(ids, k)
  local s = 0
  for _, r in ipairs(ids) do s = s + y[r] end
  mean[k] = s / #ids
  if #ids < O.M then return end
  local best, bc, bv = sse(ids), nil, nil
  for c = 1, nx do
    local seen = {}
    for _, r in ipairs(ids) do
      local v = x[r][c]
      if not seen[v] then
        seen[v] = true
        local e = sse(part(ids, c, v, true)) + sse(part(ids, c, v, false))
        if e < best then best, bc, bv = e, c, v end end end end
  if not bc then return end
  col[k], cut[k] = bc, bv
  grow(part(ids, bc, bv, true), 2 * k)
  grow(part(ids, bc, bv, false), 2 * k + 1) end

local function leaf(t)
  local k = 1.0                    -- float keys, like gawk's doubles
  while col[k] do
    k = 2 * k + (goes(t[col[k]], cut[k]) and 0 or 1) end
  return mean[k] end

lib.run(O, function(line, _, _, nr)
  local t = lib.split(line, ",")
  if nr <= O.T then
    y[nr], x[nr] = lib.num(t[#t]), table.move(t, 1, #t - 1, 1, {})
    return end
  if nr == O.T + 1 then
    local all = {}
    for r = 1, O.T do all[r] = r end
    nx = #t - 1
    grow(all, 1.0) end
  print(lib.str(leaf(t)) .. " " .. t[#t]) end)
