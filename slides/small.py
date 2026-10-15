#!/usr/bin/env python3 -B
# vim: set et sw=2 ts=2 sts=2 cc=75 :
# small.py: how good is `shuf | bins | nb`?  Runs it on every MOOT
# classify file of 128+ rows x 20 shuffles.  The last 25% of each
# shuffle is the test set, so both sides train on the same first 75%.
# LightGBM gets the SAME shuffled rows and the SAME split.
# usage: python3 slides/small.py        (-c: redraw from the cache)
import json, os, statistics as st, subprocess, sys, time, warnings
import numpy as np
warnings.simplefilter("ignore")
sys.path.insert(0, os.path.expanduser("~/gh/gawk4ai/slides"))
from clas import same, acc

HERE = os.path.dirname(os.path.abspath(__file__))
GAWK = os.path.expanduser("~/gh/gawk4ai/bundle/gawk")
MOOT = os.path.expanduser("~/tmp/moot/classify")
FIG  = HERE + "/fig"
TMP  = HERE + "/../../tmp/small"; os.makedirs(TMP, exist_ok=True)
SEEDS, TEST, MINTEST = range(1, 21), .25, 5   # test = the last TEST
MAX  = 10**9 if "-a" in sys.argv else 500   # -a: every scorable file, not
TAG  = "nball" if "-a" in sys.argv else "nb27"  # just the small ones

def scorable(path):                    # a file we can actually classify
  L = [l.strip().split(",") for l in open(path) if l.strip()]
  hdr, rows = L[0], L[1:]
  goal = [c for c, h in enumerate(hdr) if h.rstrip().endswith("!")]
  if not goal: return 0                # nothing marked as the goal
  k = len(set(r[goal[-1]] for r in rows if len(r) > goal[-1]))
  if k > len(rows) / 4: return 0       # near-unique goal: a regression set
  if int(len(rows) * TEST) < MINTEST: return 0   # too few rows to test on
  return len(rows)

FILES = []
for f in sorted(os.listdir(MOOT)):
  if not f.endswith(".csv"): continue
  n = scorable(f"{MOOT}/{f}")
  if n and n < MAX: FILES += [(f[:-4], n)]

def gawk(src, seed):
  t0 = time.perf_counter()
  sh = (f"gawk -f {GAWK}/shuf.awk Seed={seed} {src} > {TMP}/s; "
        f"gawk -f {GAWK}/bins.awk {TMP}/s | "
        f"gawk -f {GAWK}/nb.awk > {TMP}/pairs")
  subprocess.run(["bash","-c",sh], check=True, capture_output=True)
  secs = time.perf_counter() - t0
  n = sum(1 for l in open(TMP+"/s") if l.strip()) - 1
  f = [l.rstrip("\n").split("\t") for l in open(TMP+"/pairs") if l.strip()]
  return [x[0] for x in f], [x[1] for x in f], n, secs

def isnum(vals):                       # sniff by value, not by column name
  seen = False
  for v in vals:
    if v == "?": continue
    try: float(v); seen = True
    except ValueError: return False
  return seen

def lgbm(n):
  import lightgbm as lgb
  t0 = time.perf_counter()
  L = [l.strip().split(",") for l in open(TMP+"/s") if l.strip()]
  hdr, rows = L[0], L[1:]
  ycol = max(c for c, h in enumerate(hdr) if h.endswith("!"))
  xcol = [c for c, h in enumerate(hdr)        # same rule as nb1's head():
          if c != ycol and not h.endswith("X")]   # skip the class, skip X
  x = [[r[c] for c in xcol] for r in rows]    # (shuf's binsX lands here)
  y = [r[ycol] for r in rows]
  cols, cat = [], []
  for c in range(len(x[0])):
    v = [r[c] for r in x]
    if isnum(v):
      cols += [[float(r[c]) if r[c] != "?" else np.nan for r in x]]
    else:
      u = {s:i for i,s in enumerate(sorted(set(v)))}
      cols += [[u[r[c]] for r in x]]; cat += [c]
  f = np.array(cols, dtype=float).T
  ky = {v:i for i,v in enumerate(sorted(set(y)))}
  back = {i:v for v,i in ky.items()}
  T = n - int(n * TEST)          # same split the gawk side used
  m = lgb.LGBMClassifier(verbose=-1, n_estimators=100)
  m.fit(f[:T], [ky[v] for v in y[:T]], categorical_feature=cat or "auto")
  return ([back[int(p)] for p in m.predict(f[T:])], y[T:],
          time.perf_counter() - t0)


#-- figure ------------------------------------------------------------------
INK, PICK, GRID = "#1559b3", "#cc7000", "#e6e8e9"
AXIS, MUTED, DARK = "#9aa0a6", "#5f6368", "#202124"
W, RH, BAR = 900, 12, 7        # width, row height, bar thickness
NX, GX, LX, AX = 252, 338, 432, 478    # rows, gawk, lgbm, axis columns


def bar(x, y, w, h, fill):            # 3px rounded on the data end only
  r = min(3, abs(w))
  d = (f"M{x},{y} h{w-r} a{r},{r} 0 0 1 {r},{r} v{h-2*r} "
       f"a{r},{r} 0 0 1 {-r},{r} h{-(w-r)} z") if w >= 0 else (
      f"M{x},{y} h{w+r} a{r},{r} 0 0 0 {-r},{r} v{h-2*r} "
      f"a{r},{r} 0 0 0 {r},{r} h{-(w+r)} z")
  return f'<path d="{d}" fill="{fill}"/>'


def txt(x, y, s, anchor="start", size=12, fill=DARK):
  return (f'<text x="{x:.0f}" y="{y:.0f}" text-anchor="{anchor}" '
          f'font-size="{size}" fill="{fill}">{s}</text>')


def thin(out, n=50):                  # the ends in full, the middle sampled
  """First 10, last 10, and n-20 evenly spaced from what lies between.
  The chart would not fit 67 rows; the numbers below it still count all."""
  if len(out) <= n: return out
  mid, k = out[10:-10], n - 20
  step = (len(mid) - 1) / (k - 1)
  keep = sorted({round(i * step) for i in range(k)})
  return out[:10] + [mid[i] for i in keep] + out[-10:]

def chart(out, rows, d, secs):
  """One diverging bar per file: gawk minus lgbm, sorted.  Blue = gawk
  ahead, orange = lgbm ahead.  Every row also prints both means with sd
  in brackets and dots the winner, so identity is never colour alone."""
  all_n, out = len(out), thin(out)
  lo = min(min(r[4] for r in out), 0) - 1
  hi = max(max(r[4] for r in out), 0) + 1
  span, h = W - AX - 70, RH * (len(out) + 1) + 54
  sx = lambda v: AX + 30 + (v - lo) / (hi - lo) * span
  o = [f'<svg viewBox="0 0 {W} {h}" width="{W}" height="{h}" '
       f'xmlns="http://www.w3.org/2000/svg" role="img" '
       f'aria-label="accuracy of gawk versus LightGBM, by dataset">',
       txt(20, 16, "data", size=11, fill=MUTED),
       txt(NX, 16, "rows", "end", 11, MUTED),
       txt(GX, 16, "gawk", "end", 11, MUTED),
       txt(LX, 16, "lgbm", "end", 11, MUTED),
       txt(sx(0), 16, "delta", "middle", 11, MUTED)]
  for i, (name, sd, a, b, gap, win) in enumerate(out):
    y = 26 + i * RH
    o += [txt(20, y + 8, name[:26], size=11),
          txt(NX, y + 8, f"{rows[name]}", "end", 11, MUTED),
          txt(GX, y + 8, f"{a:.0f} ({sd[0]:.0f})", "end", 11,
              INK if win[0] else MUTED),
          txt(LX, y + 8, f"{b:.0f} ({sd[1]:.0f})", "end", 11,
              PICK if win[1] else MUTED)]
    for on, x, hue in ((win[0], GX + 7, INK), (win[1], LX + 7, PICK)):
      if on: o += [f'<circle cx="{x}" cy="{y+4}" r="2.5" fill="{hue}"/>']
    o += [bar(sx(0), y, sx(gap) - sx(0), BAR, INK if gap > 0 else PICK),
          txt(sx(gap) + (6 if gap > 0 else -6), y + 8, f"{gap:+.0f}",
              "start" if gap > 0 else "end", 11, MUTED)]
  y = 26 + len(out) * RH
  o += [f'<line x1="{sx(0)}" y1="22" x2="{sx(0)}" y2="{y-3}" '
        f'stroke="{AXIS}" stroke-width="1"/>',
        f'<line x1="20" y1="{y}" x2="{W-20}" y2="{y}" stroke="{GRID}" '
        f'stroke-width="1"/>',
        txt(20, y + 15, f"mean, all {all_n}", size=11, fill=MUTED),
        txt(GX, y + 15, f"{d[0]:.0f}", "end", 11, MUTED),
        txt(LX, y + 15, f"{d[1]:.0f}", "end", 11, MUTED),
        txt(sx(0) + 6, y + 15, f"{d[0]-d[1]:+.0f}", size=11, fill=MUTED),
        txt(20, y + 30, "seconds", size=11, fill=MUTED),
        txt(GX, y + 30, f"{secs[0]:.0f}", "end", 11, INK),
        txt(LX, y + 30, f"{secs[1]:.0f}", "end", 11, MUTED),
        txt(sx(0) + 6, y + 30, f"{secs[1]/secs[0]:.0f}x faster", size=11,
            fill=MUTED),
        "</svg>"]
  open(f"{FIG}/nb-chart.svg", "w").write("\n".join(o) + "\n")


def trip(v, fmt, lo=False):           # two numbers, the better one bold
  pick = min(v) if lo else max(v)
  return " / ".join(f"<b>{x:{fmt}}</b>" if x == pick else f"{x:{fmt}}"
                    for x in v)


def report(raw, secs, rows):
  out, best = [], [0, 0]
  for name, r in raw.items():
    a, b = st.mean(r[0]), st.mean(r[1])
    tie = same(r[0], r[1])
    win = [a >= b or tie, b >= a or tie]
    for i in (0, 1): best[i] += win[i]
    out += [(name, (st.stdev(r[0]), st.stdev(r[1])), a, b, a - b, win)]
  out.sort(key=lambda r: -r[4])
  d = [st.mean([r[2] for r in out]), st.mean([r[3] for r in out])]
  cell = lambda v, s, w: (f'<td class="b">{v:.0f} ({s:.0f})</td>' if w
                          else f"<td>{v:.0f} ({s:.0f})</td>")
  body = [f"<tr><td>{n}</td><td>{rows[n]}</td>" + cell(a, sd[0], w[0])
          + cell(b, sd[1], w[1]) + f"<td>{gap:+.0f}</td></tr>"
          for n, sd, a, b, gap, w in out]
  body += [f'<tr class="mean"><td>mean, all {len(out)}</td><td></td>'
           + "".join(f"<td>{v:.0f}</td>" for v in d)
           + f"<td>{d[0]-d[1]:+.0f}</td></tr>",
           '<tr class="mean"><td>seconds</td><td></td>'
           + "".join(f'<td class="b">{v:.0f}</td>' if v <= min(secs)
                     else f"<td>{v:.0f}</td>" for v in secs)
           + "<td></td></tr>"]
  open(f"{FIG}/nb-rows.html", "w").write("\n".join(body) + "\n")
  row = (f'<td>Accuracy<small>{len(out)} files</small></td>'
         '<td style="text-align:left" class="cmp">shuf|bins|nb / lgbm</td>'
         f'<td class="trip">{trip(d, ".0f")}</td>'
         f'<td class="trip">{trip(best, "d")}</td>'
         f'<td class="trip">{trip(secs, ".0f", lo=True)}</td>')
  open(f"{FIG}/nb5-row.html", "w").write(row + "\n")
  chart(out, rows, d, secs)
  print(f"\n{'data':28}{'rows':>6}{'gawk':>9}{'lgbm':>10}{'delta':>8}")
  for n, sd, a, b, gap, w in out:
    print(f"{n:28}{rows[n]:6d}  {' *'[w[0]]}{a:3.0f} ({sd[0]:.0f})"
          f"  {' *'[w[1]]}{b:3.0f} ({sd[1]:.0f}){gap:+8.0f}")
  print(f"{'mean, all '+str(len(out)):28}{'':6}   {d[0]:3.0f}"
        f"       {d[1]:3.0f}    {d[0]-d[1]:+8.0f}")
  print(f"{'seconds':28}{'':6}   {secs[0]:3.0f}       {secs[1]:3.0f}")
  print(f"\nwins (best or tied): gawk {best[0]}, lgbm {best[1]}")
  print("-> slides/fig/ nb-rows.html nb5-row.html nb-chart.svg")


def main():
  raw, secs, rows = {}, [0.0, 0.0], {}
  for name, N in FILES:
    runs = [[], []]
    for seed in SEEDS:
      got, want, n, s1 = gawk(f"{MOOT}/{name}.csv", seed)
      g2, w2, s2 = lgbm(n)
      assert len(want) == len(w2) == int(n * TEST)
      runs[0] += [acc(got, want)]; runs[1] += [acc(g2, w2)]
      secs[0] += s1; secs[1] += s2
    raw[name] = runs; rows[name] = N
    print(name, "done", flush=True)
  json.dump({"raw": raw, "secs": secs, "rows": rows},
            open(f"{FIG}/{TAG}.json", "w"))
  report(raw, secs, rows)


if __name__ == "__main__":
  if os.path.exists(f"{FIG}/{TAG}.json") and "-c" in sys.argv:
    j = json.load(open(f"{FIG}/{TAG}.json"))     # -c: redraw, do not rerun
    report(j["raw"], j["secs"], j["rows"])
  else:
    main()
