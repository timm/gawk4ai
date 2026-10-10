-- shared helpers for the gawk ports
local M = {}

-- awk-style args: name=value sets O[name]; else a file ("-" = stdin).
-- fn(line, file, fnr, nr) sees every line; file = 1,2,.. (input order)
function M.run(O, fn)
  local nr, file = 0, 0
  local function each(lines)
    local fnr = 0
    file = file + 1
    for line in lines do
      nr, fnr = nr + 1, fnr + 1
      fn(line, file, fnr, nr) end end
  for _, a in ipairs(arg) do
    local k, v = a:match("^([%a_][%w_]*)=(.*)$")
    if k then O[k] = tonumber(v) or v
    elseif a == "-" then each(io.lines())
    else each(io.lines(a)) end end
  if file == 0 then each(io.lines()) end end

function M.split(s, sep)    -- sep is a Lua pattern
  local t, i = {}, 1
  while true do
    local j, k = s:find(sep, i)
    if not j then t[#t + 1] = s:sub(i); return t end
    t[#t + 1] = s:sub(i, j - 1); i = k + 1 end end

-- awk-ish sigmoid bin of x, given count, sum, sum of squares
function M.bin(B, n, s, s2, x)
  local mu = s / n
  local sd = math.sqrt(s2 / n - mu * mu) + 1E-32
  return math.floor(B / (1 + math.exp(-1.7 * (x - mu) / sd))) end

-- awk number to string: integers as integers, else %.6g
function M.str(v)
  local i = math.tointeger(v)
  return i and tostring(i) or string.format("%.6g", v) end

-- awk string to number ("?" and junk become 0)
function M.num(s) return tonumber(s) or 0 end

-- awk == on fields: numeric if both look numeric, else string
function M.eq(a, b)
  local u, v = tonumber(a), tonumber(b)
  if u and v then return u == v end
  return a == b end

-- keys of t sorted by value t[k], ties by ascending key
-- (gawk's PROCINFO["sorted_in"] = "@val_num_asc")
function M.byval(t)
  local ks = {}
  for k in pairs(t) do ks[#ks + 1] = k end
  table.sort(ks, function(a, b)
    if t[a] ~= t[b] then return t[a] < t[b] end
    return a < b end)
  return ks end

return M
