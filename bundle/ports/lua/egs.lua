-- egs.lua: the demos. lua egs.lua -h | -all | -nb | --Bins=20 -nb
-- vim: set et sw=2 ts=2 sts=2 cc=75 :
local _ENV = setmetatable({}, {__index = require"nb"})
if setfenv then setfenv(1, _ENV) end   -- lua 5.1, luajit

help = [[
egs.lua: naive Bayes, end to end.
  --Bins=10   buckets for numeric x
  --m=2       m-estimate
  --k=1       k-estimate
  --file=/Users/timm/tmp/moot/classify/diabetes.csv   the data]]

my = the(help)

function test_rows(    t)          -- the csv reader finds names and rows
  t = rows(my.file)
  print(#t, #t.names, t.names[#t.names]) end

function test_prep(    d)          -- mu and sd, from the training rows
  d = prep(rows(my.file).names, rows(my.file))
  for c, col in pairs(d.num) do print(c, fmt("%.3f %.3f", col.mu, sd(col))) end end

function test_bins(    d)          -- the first row, raw and binned
  d = bin(prep(rows(my.file).names, rows(my.file)))
  print(cat(map(d.rows[1], tostring), ","))
  print(cat(map(d.bins[1], tostring), ",")) end

function test_nb(    all, ok, n)   -- 5 repeats of 5-way cross-validation
  all, ok, n = rows(my.file), 0, 0
  for train, test in xval(all, 5, 5) do
    ok = ok + score(nb(bin(prep(all.names, train))), test)
    n = n + #test end
  print(fmt("%.1f%% of %d", 100 * ok / n, n)) end

run(_ENV, my, help)
