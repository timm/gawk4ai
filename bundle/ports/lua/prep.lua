-- prep.lua: rows in, one payload out: what the columns are, and are like.
-- names: UPPER=num, +-=goal, !=class, X=skip. Stats come from these rows
-- only, so a cross-validation fold never learns from its own test rows.
-- vim: set et sw=2 ts=2 sts=2 cc=75 :
local _ENV = setmetatable({}, {__index = require"_lib"})
if setfenv then setfenv(1, _ENV) end   -- lua 5.1, luajit

help = [[
prep.lua: csv rows in, one payload out.
  --seed=1234   random number seed]]

function Num(at, txt) return {at = at, txt = txt, n = 0, mu = 0, m2 = 0} end

function add(col, v)               -- welford; m2 holds the rest of the sd
  col.n = col.n + 1
  col.d = v - col.mu
  col.mu = col.mu + col.d / col.n
  col.m2 = col.m2 + col.d * (v - col.mu) end

function sd(col)
  return col.n > 1 and (col.m2 / (col.n - 1)) ^ 0.5 or 0 end

function role(my, c, s)            -- what one name says its column is
  if s:find"X$"    then return end                      -- ignored
  if s:find"[+-]$" then my.y[c] = s:find"%+$" and 1 or 0 -- 1 = maximize
  elseif s:find"!$" then my.klass = c
  else my.x[c] = s:find"^%u" and 1 or 0 end end          -- 1 = numeric x

function head(my, names)           -- the header says what each column is
  for c, s in ipairs(names) do role(my, c, tostring(s)) end
  return my end

function stats(my)                 -- mu and sd, from these rows only
  for c, isnum in pairs(my.x) do if isnum == 1 then my.num[c] = Num(c) end end
  for c in pairs(my.y) do my.num[c] = Num(c) end
  for _, t in ipairs(my.rows) do
    for c, col in pairs(my.num) do
      if t[c] ~= "?" then add(col, t[c]) end end end end

function prep(names, rows,    my)  -- names say what, rows say how much
  my = {the = the(help), names = names, x = {}, y = {}, num = {}, rows = rows}
  head(my, names)
  stats(my)
  return my end

return _ENV
