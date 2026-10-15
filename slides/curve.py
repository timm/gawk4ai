#!/usr/bin/env python3 -B
# vim: set et sw=2 ts=2 sts=2 :
# curve.py: how early does the score settle, and on how few labelled
# papers?  abcd.awk Every=N prints a running macro pd as the guesses
# arrive, and some.awk keeps only the first N training rows, so one
# pipeline gives both axes.  One panel per data set, one line per
# labelling budget, over SEEDS shuffles.  pd, not accuracy: ~1% of these
# papers are a "yes", so accuracy rewards saying "no" to everything.
# Needs the MOOT data: cd bundle/gawk && make moot.
# usage: python3 slides/curve.py   (or: make fig)
import json, os, statistics as st, subprocess, sys
from math import log10
HERE = os.path.dirname(os.path.abspath(__file__))
GAWK = os.path.dirname(HERE) + "/bundle/gawk"
MOOT = os.path.expanduser(os.environ.get("MOOT", "~/tmp/moot"))
RAW  = MOOT + "/text_mining/reading/raw"
FIG, EVERY, SEEDS = f"{HERE}/fig", 10, 10
DATA  = ["Hall", "Kitchenham", "Radjenovic", "Wahono"]
TRAIN = [50, 100, 200, 0]                           # 0 = every labelled row
HUE   = ["#1559b3", "#cc7000", "#8250c4", "#137a46"]      # validated, 4 slots
GRID, AXIS, MUTED, DARK = "#e6e8e9", "#9aa0a6", "#5f6368", "#202124"
W, H = 900, 530                                     # four panels, 2 x 2
L, R, T, B, GX, GY = 46, 64, 50, 42, 78, 60         # margins, then gaps
PW = (W - L - R - GX) / 2
PH = (H - T - B - GY) / 2

def prep(name, seed):                 # shuffle, tag, tf-idf: once per seed
  d = f"{FIG}/../../.curve"
  os.makedirs(d, exist_ok=True)
  t, g = f"{d}/{name}.{seed}.split", f"{d}/{name}.{seed}.tfidf"
  if not os.path.exists(g):
    subprocess.run(f'gawk -f {GAWK}/tsv.awk {RAW}/{name}.csv'
                   f' | gawk -f {GAWK}/split.awk Seed={seed} > {t}'
                   f' && gawk -f {GAWK}/tfidf.awk {t} {t} > {g}', shell=True)
  return g, sum(1 for l in open(t) if l.startswith("train,"))

def once(name, seed, train):          # one shuffle -> {rows seen: macro pd}
  g, T = prep(name, seed)
  n = train or T
  p = subprocess.run(
    f'gawk -f {GAWK}/some.awk N={n} T={T} {g}'
    f' | gawk -f {GAWK}/twcnb.awk T={n} | gawk -f {GAWK}/abcd.awk Every={EVERY}',
    shell=True, capture_output=True, text=True).stdout
  out = {}
  for l in p.splitlines():
    f = l.split()
    if len(f) == 3 and all(x.isdigit() for x in f): out[int(f[0])] = int(f[2])
  return out

def mean(name, train):                # that, averaged over every shuffle
  rs = [once(name, s, train) for s in range(1, SEEDS + 1)]
  return sorted((n, st.mean([r[n] for r in rs if n in r])) for n in rs[0])

def txt(x, y, s, anchor="start", size=11, fill=DARK, weight=""):
  w = f' font-weight="{weight}"' if weight else ""
  return (f'<text x="{x:.1f}" y="{y:.1f}" text-anchor="{anchor}" '
          f'font-size="{size}" fill="{fill}"{w}>{s}</text>')

def panel(o, line, name, col, row):   # one data set, its training budgets
  x = L + col * (PW + GX)
  y = T + row * (PH + GY)
  lo, hi = log10(EVERY), log10(max(n for n, _ in line[TRAIN[0]]))
  px = lambda n: x + (log10(n) - lo) / (hi - lo) * PW
  py = lambda a: y + (100 - a) / 100 * PH                 # 0..100 %
  for a in range(0, 101, 20):
    o += [f'<line x1="{x}" y1="{py(a):.1f}" x2="{x+PW:.1f}" y2="{py(a):.1f}" '
          f'stroke="{GRID}" stroke-width="1"/>']
    if col == 0: o += [txt(x - 7, py(a) + 4, a, "end", 10, MUTED)]
  for n in (10, 30, 100, 300, 1000, 3000):
    if EVERY <= n <= 10 ** hi: o += [txt(px(n), y + PH + 15, n, "middle", 10, MUTED)]
  o += [f'<line x1="{x}" y1="{y+PH:.1f}" x2="{x+PW:.1f}" y2="{y+PH:.1f}" '
        f'stroke="{AXIS}" stroke-width="1"/>',
        txt(x, y - 12, name, size=13, fill=DARK, weight="600"),
        txt(x + PW, y - 12, f"{int(10**hi)} held out", "end", 10, MUTED)]
  for i, t in enumerate(TRAIN):
    v = line[t]
    o += [f'<polyline points="' + " ".join(f"{px(n):.1f},{py(a):.1f}"
          for n, a in v) + f'" fill="none" stroke="{HUE[i]}" '
          f'stroke-width="2" stroke-linejoin="round"/>',
          txt(x + PW + 6, py(v[-1][1]) + 4, t or "all", size=11, fill=HUE[i],
              weight="600")]

def main():
  cache = f"{FIG}/curve.json"                     # -c: redraw, do not rerun
  if "-c" in sys.argv and os.path.exists(cache):
    line = {d: {int(t): v for t, v in ts.items()}
            for d, ts in json.load(open(cache)).items()}
  else:
    line = {d: {t: mean(d, t) for t in TRAIN} for d in DATA}
    json.dump(line, open(cache, "w"))
  o = [f'<svg viewBox="0 0 {W} {H}" width="{W}" height="{H}" '
       f'xmlns="http://www.w3.org/2000/svg" role="img" aria-label="accuracy '
       f'against test rows seen, four data sets, four training budgets">',
       txt(L, 16, "macro pd %, by labelled papers learnt from:", size=11, fill=MUTED)]
  for i, t in enumerate(TRAIN):       # a legend, as well as the end labels
    o += [f'<line x1="{L+250+i*92}" y1="12" x2="{L+272+i*92}" y2="12" '
          f'stroke="{HUE[i]}" stroke-width="2"/>',
          txt(L + 278 + i * 92, 16, t or "all", size=11, fill=HUE[i], weight="600")]
  for j, d in enumerate(DATA): panel(o, line[d], d, j % 2, j // 2)
  o += [txt(W / 2, H - 6, "test rows seen (log)", "middle", 11, MUTED), "</svg>"]
  open(f"{FIG}/curve.svg", "w").write("\n".join(o) + "\n")
  for d in DATA:
    for t in TRAIN:
      v, settle = line[d][t], line[d][t][-1][0]
      for n, a in reversed(v):
        if abs(a - v[-1][1]) > 1: break
        settle = n
      print(f"{d:10} train {t or 'all':>4}   final {v[-1][1]:5.1f}%"
            f"   steady from {settle:5d} of {v[-1][0]}")
  print("-> slides/fig/curve.svg")

main()
