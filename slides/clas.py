#!/usr/bin/env python3 -B
# vim: set et sw=2 ts=2 sts=2 cc=75 :
# clas.py: RETIRED as a harness -- small.py replaced it, and the
# `prep | bin | nb` pipeline it drove is gone.  Kept because small.py
# imports same() and acc() from here; running it will fail.
# See slides/small.py for the current experiment.
import json, os, statistics as st, subprocess, sys
import time, warnings
import numpy as np

warnings.simplefilter("ignore")
HERE = os.path.dirname(os.path.abspath(__file__))
GAWK = os.path.dirname(HERE) + "/bundle/gawk"
MOOT = os.path.expanduser(
          os.environ.get("MOOT", "~/tmp/moot")) + "/classify"
FIG, TMP = HERE + "/fig", "/tmp/clas-run"
SEEDS, TIE = range(1, 21), .35
CLIFFS, COHEN = .197, .35    # thresholds from ~/gh/super/start.py
FILES = "diabetes ecoli glass iris ionosphere sonar vehicle segment " \
        "column3C page.blocks".split()

SH = """
set -e
cd {gawk}
gawk -f prep.awk Seed={seed} {src} > {t}/p
T=$(( $(grep -c '^:cells,' {t}/p) / 2 ))
grep '^:cells,' {t}/p | cut -d, -f2- > {t}/rows
grep '^:x,' {t}/p > {t}/x
gawk -f bin.awk {t}/p | gawk -f nb.awk t=$T > {t}/pairs
echo $T > {t}/T
"""


def gawk(src, seed):         # the pipeline: guesses, actuals, seconds
  t0 = time.perf_counter()
  subprocess.run(["bash", "-c",
                  SH.format(gawk=GAWK, seed=seed, src=src, t=TMP)],
                 check=True, capture_output=True)
  secs = time.perf_counter() - t0
  f = [l.rstrip("\n").split("\t")
       for l in open(TMP + "/pairs") if l.strip()]
  return ([x[0] for x in f], [x[1] for x in f],
          int(open(TMP + "/T").read()), secs)


def lgbm(T):                   # same rows, same split, LightGBM defaults
  import lightgbm as lgb
  t0 = time.perf_counter()
  rows = [l.strip().split(",") for l in open(TMP + "/rows") if l.strip()]
  isnum = open(TMP + "/x").read().strip().split(",")[1:]  # prep says so
  x, y = [r[:-1] for r in rows], [r[-1] for r in rows]
  cols, cat = [], []
  for c in range(len(x[0])):
    if isnum[c] == "1":                                    # a number is a
      cols += [[float(r[c]) if r[c] != "?" else np.nan for r in x]]
    else:                                                  # number, not a
      u = {v: i for i, v in enumerate(sorted({r[c] for r in x}))}
      cols += [[u[r[c]] for r in x]]; cat += [c]           # category code
  f = np.array(cols, dtype=float).T
  ky = {v: i for i, v in enumerate(sorted(set(y)))}
  back = {i: v for v, i in ky.items()}
  m = lgb.LGBMClassifier(verbose=-1, n_estimators=100)
  m.fit(f[:T], [ky[v] for v in y[:T]], categorical_feature=cat or "auto")
  got = [back[int(p)] for p in m.predict(f[T:])]
  return got, y[T:], time.perf_counter() - t0


def cliffs(xs, ys):          # true if the effect size is small
  gt = sum(x > y for x in xs for y in ys)
  lt = sum(x < y for x in xs for y in ys)
  return abs(gt - lt) / (len(xs) * len(ys)) <= CLIFFS


def cohen(xs, ys):           # true if means closer than COHEN * pooled sd
  n, m = len(xs), len(ys)
  sp = (((n - 1) * st.stdev(xs)**2 + (m - 1) * st.stdev(ys)**2)
        / (n + m - 2)) ** 0.5
  return abs(st.mean(xs) - st.mean(ys)) <= COHEN * (sp or 1E-32)


def ks(xs, ys):              # kolmogorov-smirnov: "same" at 95%?
  from bisect import bisect_right
  xs, ys = sorted(xs), sorted(ys)
  n, m = len(xs), len(ys)
  cdf = lambda a, v: bisect_right(a, v) / len(a)
  d = max(abs(cdf(xs, v) - cdf(ys, v)) for v in xs + ys)
  return d <= 1.36 * ((n + m) / (n * m)) ** 0.5


def same(xs, ys):            # as ~/gh/super/eval.py has it
  return cliffs(xs, ys) and ks(xs, ys)


def acc(got, want):
  return 100 * sum(a == b for a, b in zip(got, want)) / len(want)


def trip(v, fmt, lo=False):   # two numbers, the better one bold
  pick = min(v) if lo else max(v)
  return " / ".join(f"<b>{x:{fmt}}</b>" if x == pick else f"{x:{fmt}}"
                    for x in v)


#-- figure ------------------------------------------------------------------
INK, PICK, GRID = "#1559b3", "#cc7000", "#e6e8e9"
AXIS, MUTED, DARK = "#9aa0a6", "#5f6368", "#202124"
W, RH, L, BAR = 900, 24, 340, 12      # width, row height, label gutter, bar


def bar(x, y, w, h, fill):            # 4px rounded on the data end only
  r = min(4, abs(w))
  if w >= 0:
    d = (f"M{x},{y} h{w-r} a{r},{r} 0 0 1 {r},{r} v{h-2*r} "
         f"a{r},{r} 0 0 1 {-r},{r} h{-(w-r)} z")
  else:
    d = (f"M{x},{y} h{w+r} a{r},{r} 0 0 0 {-r},{r} v{h-2*r} "
         f"a{r},{r} 0 0 0 {r},{r} h{-(w+r)} z")
  return f'<path d="{d}" fill="{fill}"/>'


def txt(x, y, s, anchor="start", size=15, fill=DARK, extra=""):
  return (f'<text x="{x:.0f}" y="{y:.0f}" text-anchor="{anchor}" '
          f'font-size="{size}" fill="{fill}" {extra}>{s}</text>')


def chart(out, d, secs):
  """A diverging bar per file: gawk minus lgbm, sorted. Blue = gawk ahead,
  orange = lgbm ahead. Each row also carries both means, sd in brackets,
  and a dot on the winner -- so identity never rests on colour alone."""
  lo = min(min(r[4] for r in out), 0) - 1
  hi = max(max(r[4] for r in out), 0) + 1
  span, h = W - L - 60, RH * (len(out) + 1) + 70
  sx = lambda v: L + 40 + (v - lo) / (hi - lo) * span
  o = [f'<svg viewBox="0 0 {W} {h}" width="{W}" height="{h}" '
       f'xmlns="http://www.w3.org/2000/svg" role="img" '
       f'aria-label="accuracy of gawk versus LightGBM, by dataset">',
       txt(20, 20, "data", size=13, fill=MUTED),
       txt(215, 20, "gawk", "end", 13, MUTED),
       txt(310, 20, "lgbm", "end", 13, MUTED),
       txt(sx(0), 20, "delta", "middle", 13, MUTED)]
  for i, (name, sd, a, b, gap, win, *_) in enumerate(out):
    y = 40 + i * RH
    o += [txt(20, y + 11, name[:19], size=15),
          txt(215, y + 11, f"{a:.0f} ({sd[0]:.0f})", "end", 15,
              INK if win[0] else MUTED),
          txt(310, y + 11, f"{b:.0f} ({sd[1]:.0f})", "end", 15,
              PICK if win[1] else MUTED)]
    for on, x, hue in ((win[0], 227, INK), (win[1], 322, PICK)):
      if on: o += [f'<circle cx="{x}" cy="{y+6}" r="3.5" fill="{hue}"/>']
    o += [
          bar(sx(0), y, sx(gap) - sx(0), BAR, INK if gap > 0 else PICK),
          txt(sx(gap) + (8 if gap > 0 else -8), y + 11, f"{gap:+.0f}",
              "start" if gap > 0 else "end", 14, MUTED)]
  y = 40 + len(out) * RH
  o += [f'<line x1="{sx(0)}" y1="32" x2="{sx(0)}" y2="{y-4}" '
        f'stroke="{AXIS}" stroke-width="1"/>',
        f'<line x1="20" y1="{y}" x2="{W-20}" y2="{y}" stroke="{GRID}" '
        f'stroke-width="1"/>',
        txt(20, y + 22, "mean", size=15, fill=MUTED),
        txt(215, y + 22, f"{d[0]:.0f}", "end", 15, MUTED),
        txt(310, y + 22, f"{d[1]:.0f}", "end", 15, MUTED),
        txt(sx(0) + 8, y + 22, f"{d[0]-d[1]:+.0f}", size=14, fill=MUTED),
        txt(20, y + 44, "seconds", size=15, fill=MUTED),
        txt(215, y + 44, f"{secs[0]:.0f}", "end", 15, INK),
        txt(310, y + 44, f"{secs[1]:.0f}", "end", 15, MUTED),
        txt(sx(0) + 8, y + 44, f"{secs[1]/secs[0]:.0f}x faster", size=14,
            fill=MUTED),
        "</svg>"]
  open(f"{FIG}/nb-chart.svg", "w").write("\n".join(o) + "\n")


def main():
  os.makedirs(TMP, exist_ok=True); os.makedirs(FIG, exist_ok=True)
  raw, secs = {}, [0.0, 0.0]
  for name in FILES:
    runs = [[], []]
    for seed in SEEDS:
      got, want, T, s1 = gawk(f"{MOOT}/{name}.csv", seed)
      g2, w2, s2 = lgbm(T)
      runs[0] += [acc(got, want)]; runs[1] += [acc(g2, w2)]
      secs[0] += s1; secs[1] += s2
    raw[name] = runs
    print(f"{name:14}{st.mean(runs[0]):7.1f}{st.mean(runs[1]):7.1f}",
          flush=True)
  json.dump({"raw": raw, "secs": secs}, open(f"{FIG}/nb-runs.json", "w"))
  report(raw, secs)


def report(raw, secs):       # all the tables, from the cached runs
  out, down, best = [], [[], []], [0, 0]
  for name, runs in raw.items():
    a, b = st.mean(runs[0]), st.mean(runs[1])
    tie = same(runs[0], runs[1])
    win = [a >= b or tie, b >= a or tie]          # best, plus any tie
    for i in (0, 1):
      down[i] += [(a, b)[i]]; best[i] += win[i]
    out += [(name, (st.stdev(runs[0]), st.stdev(runs[1])), a, b, a - b, win,
             ks(runs[0], runs[1]), cliffs(runs[0], runs[1]),
             cohen(runs[0], runs[1]))]
  out.sort(key=lambda r: -r[4])
  d = [st.mean(c) for c in down]
  cell = lambda v, s, w: (f'<td class="b">{v:.0f} ({s:.0f})</td>' if w
                          else f"<td>{v:.0f} ({s:.0f})</td>")
  body = [f"<tr><td>{n}</td>" + cell(a, sd[0], w[0]) + cell(b, sd[1], w[1])
          + f"<td>{gap:+.0f}</td></tr>"
          for n, sd, a, b, gap, w, _, _, _ in out]
  body += ['<tr class="mean"><td>mean</td>'
           + "".join(f"<td>{v:.0f}</td>" for v in d)
           + f"<td>{d[0]-d[1]:+.0f}</td></tr>",
           '<tr class="mean"><td>seconds</td>'
           + "".join(f'<td class="b">{v:.0f}</td>' if v <= min(secs)
                     else f"<td>{v:.0f}</td>" for v in secs)
           + "<td></td></tr>"]
  open(f"{FIG}/nb-rows.html", "w").write("\n".join(body) + "\n")
  row = ('<td>Numeric Xs<small>accuracy</small></td>'
         '<td style="text-align:left" class="cmp">prep|bin|nb / lgbm</td>'
         f'<td class="trip">{trip(d, ".0f")}</td>'
         f'<td class="trip">{trip(best, "d")}</td>'
         f'<td class="trip">{trip(secs, ".0f", lo=True)}</td>')
  open(f"{FIG}/nb5-row.html", "w").write(row + "\n")
  chart(out, d, secs)
  print(f"\n{'data':13}{'gawk':>9}{'lgbm':>10}{'delta':>8}")
  for n, sd, a, b, gap, w, k, cl, ch in out:
    print(f"{n:13}  {' *'[w[0]]}{a:3.0f} ({sd[0]:.0f})"
          f"  {' *'[w[1]]}{b:3.0f} ({sd[1]:.0f}){gap:+8.0f}")
  print(f"{'mean':13}   {d[0]:3.0f}       {d[1]:3.0f}    {d[0]-d[1]:+8.0f}")
  print(f"{'seconds':13}   {secs[0]:3.0f}       {secs[1]:3.0f}")
  print(f"\nwins (best or tied): gawk {best[0]}, lgbm {best[1]}")
  print("-> slides/fig/ nb-rows.html nb5-row.html nb-chart.svg")


if __name__ == "__main__":
  if os.path.exists(f"{FIG}/nb-runs.json") and "-c" in sys.argv:
    j = json.load(open(f"{FIG}/nb-runs.json"))   # -c: redraw, do not rerun
    report(j["raw"], j["secs"])
  else:
    main()
