#!/usr/bin/env python3 -B
# vim: set et sw=2 ts=2 sts=2 :
# weak.py: how weak is the knn@N guesser?  Runs the `make opt` pipeline --
# shuffle, ydist, label N rows, knnr -- and scores its guesses three ways,
# averaged over SEEDS:
#   err%   100*MAE / MAE(always guess the mean of the N labels); 100 = useless
#   rho    Spearman rank correlation, guessed vs actual, over every test row
#   top5%  rank of the truly best row among the C with the best guesses
# N=0 is the no-learner baseline: check C rows at random.
# Writes the table bodies and the two scatter panels that slides 2a, 3 and 4
# pull in.  Needs the MOOT data: cd bundle/gawk && make moot.
# usage: python3 slides/weak.py   (or: make fig)
import os, random, statistics as st, subprocess, time

HERE = os.path.dirname(os.path.abspath(__file__))
GAWK = os.path.dirname(HERE) + "/bundle/gawk"
MOOT = os.path.expanduser(os.environ.get("MOOT", "~/tmp/moot")) + "/optimize"
FIG, TMP = HERE + "/fig", "/tmp/weak-run"
SEEDS, BUDGETS, C, TIE = range(1, 51), (25, 50, 100), 5, .35
INK, PICK, GRID, AXIS, MUTED = "#1559b3", "#cc7000", "#e6e8e9", "#9aa0a6", "#5f6368"
W, H, L, R, T, B = 440, 446, 54, 14, 30, 44  # square plot: y=x sits at 45 deg

FILES = [("SS-A", "config/SS-A.csv"), ("SS-K", "config/SS-K.csv"),
         ("SS-M", "config/SS-M.csv"), ("SS-U", "config/SS-U.csv"),
         ("X264_AllMeasurements", "config/X264_AllMeasurements.csv"),
         ("HSQLDB", "systems/HSQLDB.csv"), ("LLVM", "systems/LLVM.csv"),
         ("pom3d", "process/pom3d.csv"), ("Wine_quality", "misc/Wine_quality.csv"),
         ("Health-ClosedIssues0000", "hpo/Health-ClosedIssues0000.csv")]
PANELS = dict(X264_AllMeasurements="best case", Wine_quality="worst case")

SH = r"""
set -e
cd {gawk}
gawk -f shuffle.awk seed={seed} {src} > {t}/s
T=$(( ($(wc -l < {t}/s) - 1) / 2 ))
gawk -f ydist.awk {t}/s {t}/s > {t}/y
if [ {n} -eq 0 ]; then tail -n +2 {t}/y | gawk -F, 'NR > '$T' {{print $NF}}' > {t}/p
else
  (head -1 {t}/y; tail -n +2 {t}/y | gawk -f some.awk N={n} T=$T) > {t}/m
  gawk -f knnr.awk T={n} {t}/m > {t}/p
  tail -n +2 {t}/m | head -{n} | gawk -F, '{{print $NF}}' > {t}/train
fi
"""

#-- scoring -----------------------------------------------------------------
def run(src, seed, n):  # one pipeline run: guesses, actuals, labelled mean, secs
  t0 = time.perf_counter()
  subprocess.run(["bash", "-c", SH.format(gawk=GAWK, seed=seed, src=src, t=TMP, n=n)],
                 check=True, capture_output=True)
  secs = time.perf_counter() - t0
  f = [l.split() for l in open(TMP + "/p") if l.split()]
  if not n: return [], [float(x[0]) for x in f], 0, secs
  return ([float(x[0]) for x in f], [float(x[1]) for x in f],
          st.mean(float(x) for x in open(TMP + "/train")), secs)

def ranks(v):  # 1..n; ties share their mean rank
  out, o, i = [0.0] * len(v), sorted(range(len(v)), key=lambda i: v[i]), 0
  while i < len(o):
    j = i
    while j + 1 < len(o) and v[o[j + 1]] == v[o[i]]: j += 1
    for k in range(i, j + 1): out[o[k]] = (i + j) / 2 + 1
    i = j + 1
  return out

def rho(xs, ys):  # Spearman
  a, b = ranks(xs), ranks(ys)
  ma, mb = st.mean(a), st.mean(b)
  den = (sum((x - ma)**2 for x in a) * sum((y - mb)**2 for y in b))**.5
  return sum((x - ma) * (y - mb) for x, y in zip(a, b)) / den if den else 0

def pct(act, top):  # where the best of TOP really ranks, as a percent
  b = min(act[i] for i in top)
  return 100 * (1 + sum(1 for a in act if a < b)) / len(act)

def score(pred, act, mu):
  mae = st.mean(abs(p - a) for p, a in zip(pred, act))
  top = sorted(range(len(pred)), key=lambda i: (pred[i], i))[:C]
  return (100 * mae / st.mean(abs(mu - a) for a in act),
          rho(pred, act), pct(act, top), top)

#-- figure ------------------------------------------------------------------
def svg(pred, act, top, title, r):
  lo, hi = min(min(pred), min(act)), max(max(pred), max(act))
  pad = (hi - lo) * .06 or .01
  lo, hi, pw, ph = lo - pad, hi + pad, W - L - R, H - T - B
  sx = lambda v: L + (v - lo) / (hi - lo) * pw
  sy = lambda v: T + ph - (v - lo) / (hi - lo) * ph
  def txt(x, y, s, anchor="start", size=11, fill=MUTED, bold=""):
    return (f'<text x="{x:.1f}" y="{y:.1f}" text-anchor="{anchor}" '
            f'font-size="{size}" fill="{fill}" {bold}>{s}</text>')
  def line(x1, y1, x2, y2, c, w=1.0, dash=""):
    return (f'<line x1="{x1:.1f}" y1="{y1:.1f}" x2="{x2:.1f}" y2="{y2:.1f}" '
            f'stroke="{c}" stroke-width="{w}" {dash}/>')
  o = [f'<svg viewBox="0 0 {W} {H}" width="{W}" height="{H}" '
       f'xmlns="http://www.w3.org/2000/svg" role="img" aria-label="{title}: '
       f'guessed versus actual distance to heaven, Spearman rho {r:.2f}">',
       txt(0, 13, title, size=14, fill="#202124", bold='font-weight="700"'),
       txt(W, 13, f"&#961; = {r:.2f} &middot; seed 1", "end", 13)]
  for i in range(5):                                          # recessive grid
    v = lo + (hi - lo) * i / 4
    o += [line(L, sy(v), L + pw, sy(v), GRID),
          txt(L - 8, sy(v) + 4, f"{v:.2f}", "end"),
          txt(sx(v), T + ph + 16, f"{v:.2f}", "middle")]
  o += [line(L, T + ph, L + pw, T + ph, AXIS), line(L, T, L, T + ph, AXIS),
        # y = x: where a perfect guesser would put every point
        line(sx(lo), sy(lo), sx(hi), sy(hi), AXIS, 1.5, 'stroke-dasharray="5 4"'),
        txt(L + pw - 4, T + 12, "perfect", "end")]
  picked = set(top)
  o += [f'<circle cx="{sx(p):.1f}" cy="{sy(a):.1f}" r="2.6" fill="{INK}" '
        f'fill-opacity="0.3"/>' for i, (p, a) in enumerate(zip(pred, act))
        if i not in picked]
  o += [f'<circle cx="{sx(pred[i]):.1f}" cy="{sy(act[i]):.1f}" r="4.5" '
        f'fill="{PICK}" stroke="#fff" stroke-width="2"/>' for i in top]
  o += [txt(L + pw / 2, H - 14, "guessed d2h", "middle", 12),
        f'<text x="14" y="{T+ph/2:.0f}" font-size="12" fill="{MUTED}" '
        f'transform="rotate(-90 14 {T+ph/2:.0f})" text-anchor="middle">'
        f'actual d2h</text>', "</svg>"]
  return "\n".join(o)

#-- report ------------------------------------------------------------------
def trip(v, fmt, lo=True):  # three numbers, the best one bold: slide 4's shape
  pick = min(v) if lo else max(v)
  return " / ".join(f"<b>{x:{fmt}}</b>" if x == pick else f"{x:{fmt}}" for x in v)

def main():
  for d in (TMP, FIG): os.makedirs(d, exist_ok=True)
  wide = [BUDGETS[0], BUDGETS[-1]]               # slide 4: random / @25 / @100
  keys = [0] + wide
  weak, rank, down = [], [], [[] for _ in range(5)]
  secs = {k: 0. for k in keys}
  five = {k: [] for k in keys}
  best = {k: 0 for k in keys}
  print(f"{'data':26} {'err%':>7} {'rho':>7}"
        + "".join(f"{n:>8}" for n in BUDGETS) + f"{'rand':>8}")
  for name, rel in FILES:
    src, got, err, rh = f"{MOOT}/{rel}", {}, 0, 0
    for n in BUDGETS:
      runs = []
      for seed in SEEDS:
        pred, act, mu, t = run(src, seed, n)
        e, r, t5, top = score(pred, act, mu)
        runs += [(e, r, t5)]
        if n in secs: secs[n] += t
        if n == BUDGETS[0] and seed == 1 and name in PANELS:
          open(f"{FIG}/weak-{name}.svg", "w").write(
            svg(pred, act, top, f"{name} &mdash; {PANELS[name]}", r))
      got[n] = [x[2] for x in runs]
      if n == BUDGETS[0]:
        err, rh = st.mean(x[0] for x in runs), st.mean(x[1] for x in runs)
    rnd = []
    for seed in SEEDS:                           # the no-learner baseline
      _, act, _, t = run(src, seed, 0)
      secs[0] += t
      rnd += [pct(act, random.Random(seed).sample(range(len(act)), min(C, len(act))))]

    m = {n: st.mean(got[n]) for n in BUDGETS}
    sd = st.pstdev([v for n in BUDGETS for v in got[n]])    # "best, or within
    cut = min(m.values()) + TIE * sd                        #  0.35.sd of it"
    print(f"{name:26} {err:7.1f} {rh:7.2f}"
          + "".join(f"{m[n]:8.1f}" for n in BUDGETS) + f"{st.mean(rnd):8.1f}")
    weak += [f'<tr><td>{name}</td><td>{err:.0f}</td>'
             f'<td>{rh:.2f}</td><td>{m[BUDGETS[0]]:.1f}</td></tr>']
    rank += [f'<tr><td>{name}</td>' + "".join(
      f'<td class="b">{m[n]:.1f}</td>' if m[n] <= cut else f'<td>{m[n]:.1f}</td>'
      for n in BUDGETS) + '</tr>']
    for i, v in enumerate([err, rh] + [m[n] for n in BUDGETS]): down[i] += [v]

    three = {0: st.mean(rnd), wide[0]: m[wide[0]], wide[1]: m[wide[1]]}
    cut5 = min(three.values()) + TIE * st.pstdev(rnd + got[wide[0]] + got[wide[1]])
    for k, v in three.items(): five[k] += [v]; best[k] += v <= cut5

  d = [st.mean(c) for c in down]
  print(f"{'mean':26} {d[0]:7.1f} {d[1]:7.2f}" + "".join(f"{v:8.1f}" for v in d[2:]))
  weak += [f'<tr class="mean"><td>mean</td><td>{d[0]:.0f}</td>'
           f'<td>{d[1]:.2f}</td><td>{d[2]:.1f}</td></tr>']
  rank += ['<tr class="mean"><td>mean</td>'
           + "".join(f'<td>{v:.1f}</td>' for v in d[2:]) + '</tr>']
  row = (f'<td>Few labels<small>rank of best of 5, % (lower = better)</small></td>'
         f'<td style="text-align:left" class="cmp">random / knn@{wide[0]} /'
         f' knn@{wide[1]}</td>'
         f'<td class="trip">{trip([st.mean(five[i]) for i in keys], ".1f")}</td>'
         f'<td class="trip">{trip([best[i] for i in keys], "d", lo=False)}</td>'
         f'<td class="trip">{trip([round(secs[i]) for i in keys], "d")}</td>')
  print("slide 4 row: " + " | ".join(
    f"{i or 'rand'}: {st.mean(five[i]):.1f} best={best[i]} {secs[i]:.0f}s"
    for i in keys))
  for f, body in (("weak-rows", weak), ("rank-rows", rank), ("few-row", [row])):
    open(f"{FIG}/{f}.html", "w").write("\n".join(body) + "\n")
  print("-> slides/fig/")

main()
