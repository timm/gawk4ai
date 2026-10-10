-- usage: lua shuffle.lua [seed=1] f    (header stays first)
package.path = (arg[0]:match("(.*/)") or "./") .. "?.lua;" .. package.path
local lib = require("lib")
local run = lib.run

local O, rows = {seed = 1}, {}
run(O, function(line, _, _, nr)
  if nr == 1 then print(line) else rows[#rows + 1] = line end end)
math.randomseed(O.seed)
for i = #rows, 2, -1 do
  local j = math.random(i)
  rows[i], rows[j] = rows[j], rows[i] end
for _, row in ipairs(rows) do print(row) end
