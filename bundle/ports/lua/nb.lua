-- nb.lua: naive Bayes. my.bins trains it; my.guess(row) classifies one.
-- vim: set et sw=2 ts=2 sts=2 cc=75 :
local _ENV = setmetatable({}, {__index = require"bin"})
if setfenv then setfenv(1, _ENV) end   -- lua 5.1, luajit

help = [[
nb.lua: naive Bayes on binned rows. usage: lua nb.lua [k=1 m=2] f
  --m=2   m-estimate
  --k=1   k-estimate
  --file=/dev/null   the data]]

function prior(my, h)              -- P(h), the k-estimate
  return (my.H[h] + my.the.k) / (my.n + my.the.k * size(my.H)) end

function post(my, h, c, v, p)      -- P(v|h), the m-estimate
  return ((at(my.F, h, c, v) or 0) + my.the.m * p) / (my.H[h] + my.the.m) end

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
  my.the, my.F, my.H, my.n = the(help, my.the), {}, {}, 0
  for _, t in ipairs(my.bins) do learn(my, t) end
  my.guess = function(t)
    return keysort(my.H, function(h) return -like(my, h, t) end)[1] end
  return my end

function score(my, test,    ok)    -- how many of these it gets right
  ok = 0
  for _, t in ipairs(test) do
    if my.guess(my.bin(t)) == t[my.klass] then ok = ok + 1 end end
  return ok end

function main(    all, ok, n)      -- 5 repeats of 5-way cross-validation
  all, ok, n = rows(the(help).file), 0, 0
  for train, test in xval(all, 5, 5) do
    ok = ok + score(nb(bin(prep(all.names, train))), test)
    n = n + #test end
  print(fmt("%5.1f%% of %d  %s", 100 * ok / n, n, the(help).file)) end

if arg and arg[0] and arg[0]:find"nb%.lua$" then main() end

return _ENV
