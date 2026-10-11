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

FILES = [("SS-A", "config/SS-A.csv"), ("SS-K", "config/SS-K.csv"),
         ("SS-M", "config/SS-M.csv"), ("SS-U", "config/SS-U.csv"),
         ("X264_AllMeasurements", "config/X264_AllMeasurements.csv"),
         ("HSQLDB", "systems/HSQLDB.csv"), ("LLVM", "systems/LLVM.csv"),
         ("pom3d", "process/pom3d.csv"), ("Wine_quality", "misc/Wine_quality.csv"),
         ("Health-ClosedIssues0000", "hpo/Health-ClosedIssues0000.csv")]

SH = r"""
set -e
cd {gawk}
gawk -f split.awk Seed={seed} N={n} {src} | gawk -f ydist.awk > {t}/y
gawk -F, '/^train,/ {{print $NF}}' {t}/y > {t}/train
if [ {n} -eq 0 ]; then gawk -F, '/^test,/ {{print $NF}}' {t}/y > {t}/p
else gawk -f knnr.awk {t}/y > {t}/p
fi
"""

# split.awk tags rows train/test (N>0 labels just N of them), ydist.awk
# folds the goals into one D2h column, knnr.awk prints "y^ y" per test row.
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

#-- report ------------------------------------------------------------------
def trip(v, fmt, lo=True):  # three numbers, the best one bold: slide 4's shape
  pick = min(v) if lo else max(v)
  return " / ".join(f"<b>{x:{fmt}}</b>" if x == pick else f"{x:{fmt}}" for x in v)

def main():
  for d in (TMP, FIG): os.makedirs(d, exist_ok=True)
  wide = [BUDGETS[0], BUDGETS[-1]]               # slide 4: random / @25 / @100
  keys = [0] + wide
  rank, down = [], [[] for _ in range(6)]   # err, rho, rand, 25, 50, 100
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
      got[n] = [x[2] for x in runs]
      if n == BUDGETS[0]:
        err, rh = st.mean(x[0] for x in runs), st.mean(x[1] for x in runs)
    rnd = []
    for seed in SEEDS:                           # the no-learner baseline
      _, act, _, t = run(src, seed, 0)
      secs[0] += t
      rnd += [pct(act, random.Random(seed).sample(range(len(act)), min(C, len(act))))]

    m = {n: st.mean(got[n]) for n in BUDGETS}
    mr = st.mean(rnd)                                       # no-learner column
    sd = st.pstdev(rnd + [v for n in BUDGETS for v in got[n]])  # "best, or
    cut = min([mr] + list(m.values())) + TIE * sd           #  within 0.35.sd"
    cell = lambda v: (f'<td class="b">{v:.1f}</td>' if v <= cut
                      else f'<td>{v:.1f}</td>')
    print(f"{name:26} {err:7.1f} {rh:7.2f}"
          + "".join(f"{m[n]:8.1f}" for n in BUDGETS) + f"{mr:8.1f}")
    rank += [f'<tr><td>{name}</td><td>{err:.0f}</td><td>{rh:.2f}</td>'
             + cell(mr) + "".join(cell(m[n]) for n in BUDGETS) + '</tr>']
    for i, v in enumerate([err, rh, mr] + [m[n] for n in BUDGETS]): down[i] += [v]

    three = {0: st.mean(rnd), wide[0]: m[wide[0]], wide[1]: m[wide[1]]}
    cut5 = min(three.values()) + TIE * st.pstdev(rnd + got[wide[0]] + got[wide[1]])
    for k, v in three.items(): five[k] += [v]; best[k] += v <= cut5

  d = [st.mean(c) for c in down]
  print(f"{'mean':26} {d[0]:7.1f} {d[1]:7.2f}" + "".join(f"{v:8.1f}" for v in d[2:]))
  rank += [f'<tr class="mean"><td>mean</td><td>{d[0]:.0f}</td>'
           f'<td>{d[1]:.2f}</td>'
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
  for f, body in (("rank-rows", rank), ("few-row", [row])):
    open(f"{FIG}/{f}.html", "w").write("\n".join(body) + "\n")
  print("-> slides/fig/")

main()
