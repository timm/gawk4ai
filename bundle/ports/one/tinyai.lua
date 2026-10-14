#!/usr/bin/env lua
-- vim: set et sw=2 ts=2 sts=2 cc=75 :
-- tinyai.lua: the ideas of this deck as one program, not a pipe demo.
-- Cells are typed once, at read.  After that one payload "my" passes
-- through the stages -- prep learns the columns, bin buckets the numeric
-- ones, nb counts -- and each stage leaves behind a closure that applies
-- it to a new row.  Functions stay under six lines; no local inside any
-- of them (the extras after the gap are this function's scratch).
-- Runs on lua 5.1 .. 5.5 and luajit.
-- usage: lua tinyai.lua -h | -all | -nb | --Bins=20 --file=f -nb
local _ENV = setmetatable({}, {__index = _G})
if setfenv then setfenv(1, _ENV) end       -- lua 5.1, luajit
cat, fmt = table.concat, string.format

help = [[
tinyai.lua: naive Bayes, end to end.
  --Bins=10   buckets for numeric x
  --m=2       m-estimate
  --k=1       k-estimate
  --seed=1234 random number seed
  --file=../../../../tmp/moot/classify/diabetes.csv   the data]]

--- atoms and rows ---------------------------------------------------
function atom(s)                   -- string -> number, bool, else string
  s = s:match"^%s*(.-)%s*$"
  return tonumber(s) or s == "true" or (s ~= "false" and s) end

function cells(s,    t)            
  t={};for v in (s..","):gmatch"(.-)," do t[#t+1]=atom(v) end; return t end

function clean(s)  return (s:gsub("#.*", ""):gsub("[ \r]*$", "")) end

function rows(file,    t, s)       -- data rows, with t.names set aside
  t = {}
  for line in io.lines(file) do
    s = clean(line)
    if s ~= "" then t[t.names and #t + 1 or "names"] = cells(s) end end
  return t end

--- tables -----------------------------------------------------------
function inc(t, val, a, ...)       -- t[a][b][c].. += val, tables as needed
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

-- how many keys (# counts only the array part)
function size(t,    n) n=0; for _ in pairs(t) do n=n+1 end; return n end

function sorted(t, fun) table.sort(t, fun); return t end

function keysort(t, fun,    ks, val)   -- keys of t, ascending on fun(k)
  ks, val = {}, {}
  for k, v in pairs(t) do ks[#ks + 1] = k; val[k] = fun and fun(k) or v end
  return sorted(ks, function(a, b) return val[a] < val[b] end) end

function map(t, fun,    u)         -- fun over the values, into a new array
  u = {}
  for _, v in ipairs(t) do u[#u + 1] = fun(v) end
  return u end

function kap(t, fun,    u)         -- fun(k,v) over an array -> new one
  u = {}
  for k, v in ipairs(t) do u[#u + 1] = fun(k, v) end
  return u end

--- chance -----------------------------------------------------------
function rint(n)                   -- pseudo-random 1..n, our own generator
  SEED = (16807 * SEED) % 2147483647
  return 1 + math.floor(n * SEED / 2147483647) end

function shuffle(t, seed,    j)    -- in place, repeatable from seed
  SEED = seed or SEED
  for i = #t, 2, -1 do j = rint(i); t[i], t[j] = t[j], t[i] end
  return t end

function cut(t, n, fold,    train, test)   -- one fold out, the rest in
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

--- prep: what the columns are, and are like -------------------------
function Num(at) return {at = at, n = 0, mu = 0, m2 = 0} end

function add(col, v)               -- welford; m2 holds the rest of the sd
  col.n = col.n + 1
  col.d = v - col.mu
  col.mu = col.mu + col.d / col.n
  col.m2 = col.m2 + col.d * (v - col.mu) end

function sd(col)
  return col.n > 1 and (col.m2 / (col.n - 1)) ^ 0.5 or 0 end

function role(my, c, s)            -- what one name says its column is
  if s:find"X$"     then return end                       -- ignored
  if s:find"[+-]$"  then my.y[c] = s:find"%+$" and 1 or 0 -- 1 = maximize
  elseif s:find"!$" then my.klass = c
  else my.x[c] = s:find"^%u" and 1 or 0 end end           -- 1 = numeric x

function head(my, names)           -- the header says what each column is
  kap(names, function(c, s) return role(my, c, tostring(s)) end) end

function stats(my)                 -- mu and sd, from these rows only
  for c, isnum in pairs(my.x) do
    if isnum == 1 then my.num[c] = Num(c) end end
  for c in pairs(my.y) do my.num[c] = Num(c) end
  for _, t in ipairs(my.rows) do
    for c, col in pairs(my.num) do
      if t[c] ~= "?" then add(col, t[c]) end end end end

function prep(names, rows,    my)  -- names say what, rows say how much
  my = {the = the, names = names, x = {}, y = {}, num = {}, rows = rows}
  head(my, names); stats(my)
  return my end

--- bin: numeric x -> a percent bucket -------------------------------
function z(col, v)                 -- how many sds from the mean, clipped
  return math.max(-3, math.min(3, (v - col.mu) / (sd(col) + 1E-32))) end

function norm(col, v)              -- 0..1, the squash that disc shares
  return 1 / (1 + math.exp(-1.7 * z(col, v))) end

function bin1(my, c, v)            -- one cell: its bucket, as a percent
  if my.x[c] ~= 1 or v == "?" then return v end
  return math.floor(math.floor(my.the.Bins * norm(my.num[c], v))
                    * 100 / my.the.Bins) end

function bin(my)
  my.bin = function(t)
    return kap(t, function(c, v) return bin1(my, c, v) end) end
  my.bins = map(my.rows, my.bin)
  return my end

--- nb: count what the rows hold, then guess -------------------------
function prior(my, h)              -- P(h), the k-estimate
  return (my.H[h] + my.the.k) / (my.n + my.the.k * size(my.H)) end

function post(my, h, c, v, p)      -- P(v|h), the m-estimate
  return ((at(my.F, h, c, v) or 0) + my.the.m * p)
         / (my.H[h] + my.the.m) end

function like(my, h, t,    p)      -- log P(h) + sum log P(x|h)
  p = prior(my, h)
  return math.log(p) + sum(my.x, function(c)
    return t[c] == "?" and 0 or math.log(post(my, h, c, t[c], p)) end) end

function learn(my, t)
  my.n = my.n + 1
  inc(my.H, 1, t[my.klass])
  for c in pairs(my.x) do
    if t[c] ~= "?" then inc(my.F, 1, t[my.klass], c, t[c]) end end end

function nb(my)
  my.F, my.H, my.n = {}, {}, 0
  for _, t in ipairs(my.bins) do learn(my, t) end
  my.guess = function(t)
    return keysort(my.H, function(h) return -like(my, h, t) end)[1] end
  return my end

function right(my, t)              -- did it get this one right?
  return my.guess(my.bin(t)) == t[my.klass] and 1 or 0 end

function score(my, test)           -- how many of these it gets right
  return sum(test, function(i) return right(my, test[i]) end) end

--- the demos --------------------------------------------------------
function test_rows(    t)          -- the csv reader finds names and rows
  t = rows(the.file)
  print(fmt("%d rows, %d cols, y=%s", #t, #t.names, t.names[#t.names])) end

function test_prep(    d)          -- mu and sd, from the training rows
  d = prep(rows(the.file).names, rows(the.file))
  for c, col in pairs(d.num) do
    print(c, fmt("mu %.3f  sd %.3f", col.mu, sd(col))) end end

function test_bins(    d)          -- the first row, raw and binned
  d = bin(prep(rows(the.file).names, rows(the.file)))
  print("raw  " .. cat(map(d.rows[1], tostring), ","))
  print("bins " .. cat(map(d.bins[1], tostring), ",")) end

function test_nb(    all, ok, n)   -- 5 repeats of 5-way cross-validation
  all, ok, n = rows(the.file), 0, 0
  for train, test in xval(all, 5, 5) do
    ok = ok + score(nb(bin(prep(all.names, train))), test)
    n = n + #test end
  print(fmt("%.1f%% of %d", 100 * ok / n, n)) end

--- the command line -------------------------------------------------
function demos(env,    t)          -- every test_ function in this file
  t = {}
  for k in pairs(env) do if k:find"^test_" then t[#t + 1] = k end end
  return sorted(t) end

function run1(env, s,    ok, err)  -- one demo, crash-proof
  io.write(fmt("%-8s ", s:sub(6)))
  ok, err = pcall(env[s])
  if not ok then print("FAIL " .. tostring(err)) end
  return ok end

function usage(env)                -- the help text, then what can be run
  print(help .. "\n\nDemos:")
  for _, d in ipairs(demos(env)) do print("  -" .. d:sub(6)) end end

function main(env,    k, v)        -- -x runs test_x, --k=v sets the
  for _, s in ipairs(arg) do
    k, v = s:match"^%-%-(%w+)=(.*)"
    if     k            then the[k] = atom(v)
    elseif s == "-h"    then usage(env)
    elseif s == "-all"  then
      for _, d in ipairs(demos(env)) do run1(env, d) end
    elseif env["test_" .. s:sub(2)] then
      run1(env, "test_" .. s:sub(2)) end end end

the = {}
for k, v in help:gmatch("%-%-(%w+)=(%S+)") do the[k] = atom(v) end
SEED = the.seed
main(_ENV)
