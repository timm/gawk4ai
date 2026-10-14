-- bin.lua: numeric x cells become a percent bucket; the rest ride along.
-- my.bins is the training rows, binned; my.bin(row) bins any new row.
-- vim: set et sw=2 ts=2 sts=2 cc=75 :
local _ENV = setmetatable({}, {__index = require"prep"})
if setfenv then setfenv(1, _ENV) end   -- lua 5.1, luajit

help = [[
bin.lua: numeric x -> percent of Bins, by mu and sd, z clipped to +-3.
  --Bins=10   how many buckets]]

function norm(col, v,    z)        -- 0..1, the squash knnr shares
  z = (v - col.mu) / (sd(col) + 1E-32)
  return 1 / (1 + math.exp(-1.7 * math.max(-3, math.min(3, z)))) end

function bin1(my, c, v)            -- one cell: its bucket, as a percent
  if my.x[c] ~= 1 or v == "?" then return v end
  return math.floor(math.floor(my.the.Bins * norm(my.num[c], v))
                    * 100 / my.the.Bins) end

function bin(my)
  my.the = the(help, my.the)
  my.bin = function(t) return kap(t, function(c, v) return bin1(my, c, v) end) end
  my.bins = map(my.rows, my.bin)
  return my end

return _ENV
