-- usage: ... | lua rank.lua [C=5]   (lines: predicted actual)
-- check the C rows with the best (lowest) predictions; print how
-- the best of them really ranks among all n test rows, as a percent, 100*r/n.
package.path = (arg[0]:match("(.*/)") or "./") .. "?.lua;" .. package.path
local lib = require("lib")

local O = {C = 5}
local p, a = {}, {}
lib.run(O, function(line, _, _, nr)
  local s, t = line:match("(%S*)%s*(%S*)")
  p[nr], a[nr] = lib.num(s), lib.num(t) end)

local b, j = nil, 0                        -- best actual in top C
for _, i in ipairs(lib.byval(p)) do
  if not b or a[i] < b then b = a[i] end
  j = j + 1
  if j == O.C then break end end

local r = 1
for _, v in ipairs(a) do if v < b then r = r + 1 end end
print(string.format("%.1f", 100 * r / #a))
