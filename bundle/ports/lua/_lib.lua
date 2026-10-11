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
