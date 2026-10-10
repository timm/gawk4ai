-- usage: lua abcd.lua < "predicted actual" lines
package.path = (arg[0]:match("(.*/)") or "./") .. "?.lua;" .. package.path
local lib = require("lib")
local run = lib.run

local function eq(a, b)    -- awk: numeric compare if both look numeric
  local x, y = tonumber(a), tonumber(b)
  if x and y then return x == y end
  return a == b end

local function pc(x, y) return y ~= 0 and math.floor(100*x/y + .5) or 0 end

local n, got, want, hit = 0, {}, {}, {}
run({}, function(line)
  local a, b = line:match("^%s*(%S*)%s*(%S*)")
  n = n + 1
  got[a] = (got[a] or 0) + 1
  want[b] = (want[b] or 0) + 1
  hit[a] = (hit[a] or 0) + (eq(a, b) and 1 or 0) end)

print("   n,   a,   b,   c,   d,acc,pre, pf, pd, class")
io.stdout:flush()
local sort = io.popen("sort -t, -k9nr", "w")
for x, w in pairs(want) do
  local d = hit[x] or 0
  local b, c = w - d, (got[x] or 0) - d
  local a = n - b - c - d
  sort:write(string.format("%4d,%4d,%4d,%4d,%4d,%3d,%3d,%3d,%3d, %s\n",
    w, a, b, c, d, pc(a + d, n), pc(d, c + d), pc(c, a + c), pc(d, b + d), x))
end
sort:close()
