-- usage: lua tfidf.lua [K=64] f f
-- (text<TAB>label) -> counts of the K words with most tf*idf
package.path = (arg[0]:match("(.*/)") or "./") .. "?.lua;" .. package.path
local lib = require("lib")
local run, split = lib.run, lib.split

local O = {K = 64}
local STOP = {}
for w in ([[that this with from have which their these
            been such more were also they than into]]):gmatch("%a+") do
  STOP[w] = true end
local N, df, tf, keep = 0, {}, {}, {}

local function words(text)
  local a = {}
  for w in text:lower():gmatch("[a-z]+") do
    if #w > 3 and not STOP[w] then a[w] = (a[w] or 0) + 1 end end
  return a end

local function top()
  local score, ws = {}, {}
  for w, n in pairs(df) do
    score[w], ws[#ws + 1] = tf[w] * math.log(N / n), w end
  table.sort(ws, function(a, b)     -- ties: gawk compares words, desc
    if score[a] ~= score[b] then return score[a] > score[b] end
    return a > b end)
  for j = 1, math.min(O.K, #ws) do keep[j] = ws[j] end end

run(O, function(line, file, fnr)
  local t = split(line, "\t")
  if fnr == 1 then                    -- skip header
    if file > 1 then top() end
  elseif file == 1 then
    N = N + 1
    for w, k in pairs(words(t[1])) do
      df[w], tf[w] = (df[w] or 0) + 1, (tf[w] or 0) + k end
  else
    local a, out = words(t[1]), {}
    for j = 1, O.K do out[j] = a[keep[j]] or 0 end
    out[#out + 1] = t[2] or ""
    print(table.concat(out, ",")) end end)
