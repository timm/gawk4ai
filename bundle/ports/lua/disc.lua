-- usage: lua disc.lua [B=7] f f  (pass 1: mean,sd; pass 2: bins)
package.path = (arg[0]:match("(.*/)") or "./") .. "?.lua;" .. package.path
local lib = require("lib")
local run, split = lib.run, lib.split

local O = {B = 7}
local num, n, s, s2 = {}, {}, {}, {}

run(O, function(line, file, fnr)
  local t = split(line, ",")
  if fnr == 1 then                     -- header: Uppercase = numeric
    for c = 1, #t - 1 do num[c] = t[c]:find("^[A-Z]") ~= nil end
    if file > 1 then print(line) end
  elseif file == 1 then
    for c, isnum in pairs(num) do
      if isnum and t[c] ~= "?" then
        local x = tonumber(t[c])
        n[c] = (n[c] or 0) + 1
        s[c] = (s[c] or 0) + x
        s2[c] = (s2[c] or 0) + x * x end end
  else
    for c in pairs(n) do
      if t[c] ~= "?" then
        t[c] = lib.bin(O.B, n[c], s[c], s2[c], tonumber(t[c])) end end
    print(table.concat(t, ",")) end end)
