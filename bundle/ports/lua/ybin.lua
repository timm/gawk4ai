-- usage: lua ybin.lua T=n d d  (y -> bin; 1st T rows)
package.path = (arg[0]:match("(.*/)") or "./") .. "?.lua;" .. package.path
local lib = require("lib")
local run, split = lib.run, lib.split

local O = {B = 7, T = 0}
local n, s, s2 = 0, 0, 0

run(O, function(line, file, fnr)
  local t = split(line, ",")
  local y = tonumber(t[#t])
  if file == 1 then
    if fnr <= O.T and t[#t] ~= "?" then
      n, s, s2 = n + 1, s + y, s2 + y * y end
  else
    if t[#t] ~= "?" then t[#t] = lib.bin(O.B, n, s, s2, y) end
    print(table.concat(t, ",")) end end)
