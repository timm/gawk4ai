-- _lib.lua: the bits every port needs -- options, csv input, cell types.
-- vim: set et sw=2 ts=2 sts=2 cc=75 :
-- usage: local l = require("_lib")   then l.cli, l.csv, l.coerce
local l = {}

function l.coerce(s)           -- string to number, bool, else string
  s = s:match"^%s*(.-)%s*$"
  return tonumber(s) or s == "true" or (s ~= "false" and s) end

function l.csv(file, fun,    nr,t,s)  -- fun(row, nr), cells coerced
  nr = 0
  for line in io.lines(file) do
    s = line:gsub("#.*", ""):match"^%s*(.-)%s*$"
    if s ~= "" then
      t, nr = {}, nr + 1              -- (.-), so empty cells survive
      for cell in (s .. ","):gmatch"(.-)," do
        t[#t + 1] = l.coerce(cell) end
      fun(t, nr) end end end

function l.key(a, ...)         -- one flat key of any arity; cells hold
  if select("#", ...) == 0 then return tostring(a) end   -- no "\0"
  return tostring(a) .. "\0" .. l.key(...) end

function l.argmax(t, fun,    best,out,v)  -- key of t scoring best on fun
  for k in pairs(t) do
    v = fun(k)
    if not out or v > best then best, out = v, k end end
  return out end

function l.learn(the, fit)     -- rows <=T go to fit; rows >W come back
  return coroutine.wrap(function()
    l.csv(the.file, function(t, nr)
      if nr > the.W then coroutine.yield(t) end
      if nr <= the.T then fit(t) end end) end) end

function l.inc(t, a, ...)      -- inc(t,a,b,c) is t[a][b][c] += 1,
  if select("#", ...) == 0 then      -- making the tables on the way down
    t[a] = (t[a] or 0) + 1
  else
    t[a] = t[a] or {}
    l.inc(t[a], ...) end
  return t end

function l.cli(the, args,    k,v)  -- "k=v" sets the; else the file
  for _, s in ipairs(args) do
    k, v = s:match"^(%w+)=(.*)"
    if k then the[k] = l.coerce(v) else the.file = s end end
  return the end

return l
