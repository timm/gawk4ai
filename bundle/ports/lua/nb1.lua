-- usage: lua nb1.lua [m=2 k=1 T=n W=n] f   train rows 1..T, test rows > W
-- vim: set et sw=2 ts=2 sts=2 cc=75 :
package.path = (arg[0]:match("(.*/)") or "./") .. "?.lua;" .. package.path
local l = require("_lib")

local the = l.cli({m = 2, k = 1, T = 1E32, W = 10}, arg)
local F, H, N, NH = {}, {}, 0, 0  -- F[class,col,value], H[class]: counts
local key, train, like, classify
local log = math.log

function key(h, c, v)          -- one flat key; "\0" cannot occur in a cell
  return string.format("%s\0%s\0%s", h, c, v) end

function train(t,    h)
  h = t[#t]
  N = N + 1
  if not H[h] then NH = NH + 1 end
  l.inc(H, h)
  for c = 1, #t - 1 do
    if t[c] ~= "?" then l.inc(F, key(h, c, t[c])) end end end

function like(h, t,    p,out,seen)      -- log P(h) + sum log P(x|h)
  p = (H[h] + the.k) / (N + the.k * NH)
  out = log(p)
  for c = 1, #t - 1 do
    if t[c] ~= "?" then
      seen = F[key(h, c, t[c])] or 0
      out = out + log((seen + the.m * p) / (H[h] + the.m)) end end
  return out end

function classify(t,    best,out,v)
  for h in pairs(H) do
    v = like(h, t)
    if not out or v > best then best, out = v, h end end
  return out or "" end

l.csv(the.file, function(t, nr)
  if nr > the.W then
    print(tostring(classify(t)) .. " " .. tostring(t[#t])) end
  if nr <= the.T then train(t) end end)
