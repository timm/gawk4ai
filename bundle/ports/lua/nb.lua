-- usage: lua nb.lua [T=n W=n] f   train rows 1..T, test rows > W
package.path = (arg[0]:match("(.*/)") or "./") .. "?.lua;" .. package.path
local lib = require("lib")
local run, split = lib.run, lib.split

local O = {m = 2, k = 1, T = 1E32, W = 10}
local f, N, nh = {}, 0, 0      -- f[class][col][value] = count

local function train(t)
  local h = t[#t]
  N = N + 1
  for c, v in ipairs(t) do
    if v ~= "?" then
      if not f[h] then f[h] = {}; nh = nh + 1 end
      f[h][c] = f[h][c] or {}
      f[h][c][v] = (f[h][c][v] or 0) + 1 end end end

local function like(h, t)      -- log P(h) + sum log P(x|h)
  local fh = f[h]
  local n = fh[#t] and fh[#t][h] or 0
  local p = (n + O.k) / (N + O.k * nh)
  local out = math.log(p)
  for c = 1, #t - 1 do
    if t[c] ~= "?" then
      local seen = fh[c] and fh[c][t[c]] or 0
      out = out + math.log((seen + O.m * p) / (n + O.m)) end end
  return out end

local function classify(t)
  local best, out
  for h in pairs(f) do
    local l = like(h, t)
    if not out or l > best then best, out = l, h end end
  return out or "" end

run(O, function(line, _, _, nr)
  local t = split(line, " *, *")
  if nr > O.W then print(classify(t) .. " " .. t[#t]) end
  if nr <= O.T then train(t) end end)
