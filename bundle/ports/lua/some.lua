-- usage: lua some.lua N=100 T=n f   (f is pre-shuffled)
-- keep N labelled rows, then the test rows (> T)
package.path = (arg[0]:match("(.*/)") or "./") .. "?.lua;" .. package.path
local lib = require("lib")
local run = lib.run

local O = {N = 0, T = 0}
run(O, function(line, _, _, nr)
  if nr <= O.N or nr > O.T then print(line) end end)
