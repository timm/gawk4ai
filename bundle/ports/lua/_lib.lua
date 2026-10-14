-- _lib.lua: what gawk gives for free -- rows, counts, sorts, sums.
-- usage: local _ENV = setmetatable({}, {__index=require"_lib"})
-- vim: set et sw=2 ts=2 sts=2 cc=75 :
local _ENV = setmetatable({}, {__index = _G})
if setfenv then setfenv(1, _ENV) end   -- lua 5.1, luajit
cat, fmt = table.concat, string.format

function atom(s)                   -- string -> number, bool, else string
  s = s:match"^%s*(.-)%s*$"
  return tonumber(s) or s == "true" or (s ~= "false" and s) end

function cells(s,    t)            -- one csv line -> one row of atoms
  t = {}
  for v in (s .. ","):gmatch"(.-)," do t[#t + 1] = atom(v) end
  return t end

function clean(s)                  -- drop comments, trailing blanks, dos \r
  return (s:gsub("#.*", ""):gsub("[ \r]*$", "")) end

function rows(file,    t, s)       -- data rows, with t.names set aside
  t = {}
  for line in io.lines(file) do
    s = clean(line)
    if s ~= "" then t[t.names and #t + 1 or "names"] = cells(s) end end
  return t end

function inc(t, val, a, ...)       -- t[a][b][c]..+= val, tables as needed
  if select("#", ...) == 0 then t[a] = (t[a] or 0) + val else
    t[a] = t[a] or {}
    inc(t[a], val, ...) end
  return t end

function at(t, a, ...)             -- t[a][b][c].., nil if any is missing
  if t == nil then return nil end
  if select("#", ...) == 0 then return t[a] end
  return at(t[a], ...) end

function sum(t, fun,    n)         -- sum fun(k) over keys of t, or values
  n = 0
  for k, v in pairs(t) do n = n + (fun and fun(k) or v) end
  return n end

function size(t,    n)             -- how many keys (# only counts arrays)
  n = 0
  for _ in pairs(t) do n = n + 1 end
  return n end

function sorted(t, fun) table.sort(t, fun); return t end

function keysort(t, fun,    ks, val)   -- keys of t, ascending on fun(k)
  ks, val = {}, {}
  for k, v in pairs(t) do ks[#ks + 1] = k; val[k] = fun and fun(k) or v end
  return sorted(ks, function(a, b) return val[a] < val[b] end) end

function first(t, k,    u)         -- the first k items
  u = {}
  for i = 1, math.min(k, #t) do u[i] = t[i] end
  return u end

function mid(t) return sum(t) / #t end

function kap(t, fun,    u)         -- fun(k,v) over an array, into a new one
  u = {}
  for k, v in ipairs(t) do u[#u + 1] = fun(k, v) end
  return u end

function map(t, fun,    u)         -- fun over the values, into a new array
  u = {}
  for _, v in ipairs(t) do u[#u + 1] = fun(v) end
  return u end

SEED = 1234
function rint(n)                   -- pseudo-random 1..n, our own generator
  SEED = (16807 * SEED) % 2147483647
  return 1 + math.floor(n * SEED / 2147483647) end

function shuffle(t, seed,    j)    -- in place, repeatable from seed
  SEED = seed or SEED
  for i = #t, 2, -1 do j = rint(i); t[i], t[j] = t[j], t[i] end
  return t end

function cut(t, n, fold,    train, test)   -- rows of one fold, and the rest
  train, test = {}, {}
  for i, row in ipairs(t) do
    if (i - 1) % n + 1 == fold then test[#test + 1] = row
    else train[#train + 1] = row end end
  return train, test end

function xval(t, m, n,    r, fold)     -- m repeats of n-way, train & test
  r, fold = 0, 0
  return function()
    fold = fold % n + 1
    if fold == 1 then r = r + 1; shuffle(t, r) end
    if r > m then return end
    return cut(t, n, fold) end end

function demos(env,    t)          -- every test_ function in a module
  t = {}
  for k in pairs(env) do if k:find"^test_" then t[#t + 1] = k end end
  return sorted(t) end

function run1(env, s,    ok, err)  -- one demo, crash-proof
  io.write(fmt("%-12s ", s:sub(6)))
  ok, err = pcall(env[s])
  print(ok and "PASS" or ("FAIL " .. tostring(err)))
  return ok end

function run(env, the, doc,    k, v)   -- -x runs test_x, --k=v sets the
  for _, s in ipairs(arg) do
    k, v = s:match"^%-%-(%w+)=(.*)"
    if     k            then the[k] = atom(v)
    elseif s == "-h"    then usage(env, doc)
    elseif s == "-all"  then for _, d in ipairs(demos(env)) do run1(env, d) end
    elseif env["test_" .. s:sub(2)] then run1(env, "test_" .. s:sub(2)) end end end

function usage(env, doc)           -- the help text, then what can be run
  print(doc .. "\n\nDemos:")
  for _, d in ipairs(demos(env)) do print("  -" .. d:sub(6)) end end

function the(help, t)              -- the help text holds the defaults
  t = t or {}
  for k, v in help:gmatch("%-%-(%w+)=(%S+)") do t[k] = t[k] or atom(v) end
  for _, s in ipairs(arg or {}) do
    for k, v in s:gmatch("(%w+)=(%S+)") do t[k] = atom(v) end end
  return t end

return _ENV
