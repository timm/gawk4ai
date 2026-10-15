#!/usr/bin/env python3 -B
# vim: set et sw=2 ts=2 sts=2 :
# rank.py: how close can a shortlist get?  Team A labels K rows once;
# team B reuses that work and labels only C more to pick a winner.  We
# report where that winner really sits among the held-out rows (0 = the
# very best), against the baseline of team B working alone: label C at
# random, keep the best.  Writes the table body slide 3 pulls in.
# Needs the MOOT data: cd bundle/gawk && make moot.
# usage: python3 slides/rank.py   (or: make fig)
import os, statistics as st, subprocess
HERE = os.path.dirname(os.path.abspath(__file__))
GAWK = os.path.dirname(HERE) + "/bundle/gawk"
MOOT = os.path.expanduser(os.environ.get("MOOT", "~/tmp/moot")) + "/optimize"
FIG, K, C, SEEDS = f"{HERE}/fig", 32, 5, 20
DATA = """misc/auto93 process/nasa93dem process/coc1000 process/pom3a
  process/pom3d process/xomo_flight config/SS-A config/SS-D config/SS-K
  config/SS-M config/Apache_AllMeasurements config/HSMGP_num
  config/SQL_AllMeasurements systems/7z systems/BDBC systems/HSQLDB
  rl/A2C_CartPole sales_data/socks misc/Wine_quality test/dataset120""".split()

def run(src, seed, knobs):            # one shuffle, one score
  sh = subprocess.run(["gawk", "-f", f"{GAWK}/shuf.awk", f"Seed={seed}", src],
                      capture_output=True, text=True).stdout
  r = subprocess.run(["gawk", "-f", f"{GAWK}/rank.awk"] + knobs,
                     input=sh, capture_output=True, text=True,
                     env={**os.environ, "AWKPATH": GAWK})   # finds dist.awk
  return int(r.stdout.strip())

def qs(v):                            # median, and the quartiles around it
  v = sorted(v)
  q = lambda p: v[min(len(v) - 1, int(len(v) * p))]
  return q(.5), q(.25), q(.75)

def main():
  body, out = [], []
  for f in DATA:
    src = f"{MOOT}/{f}.csv"
    n = sum(1 for _ in open(src)) - 1
    mod = [run(src, s, [f"K={K}", f"C={C}"]) for s in range(1, SEEDS + 1)]
    rnd = [run(src, s, [f"Rnd={C}", f"Seed={s}"]) for s in range(1, SEEDS + 1)]
    out += [(os.path.basename(f), n, *qs(mod), st.median(rnd))]
  out.sort(key=lambda r: r[2])
  for name, n, med, lo, hi, rnd in out:
    body += [f"<tr><td>{name}</td><td>{n}</td>"
             f'<td class="b">{med:.0f}</td><td>{lo:.0f}&ndash;{hi:.0f}</td>'
             f"<td>{rnd:.0f}</td></tr>"]
  med = [st.median([r[i] for r in out]) for i in (2, 5)]
  body += [f'<tr class="mean"><td>median, all {len(out)}</td><td></td>'
           f'<td class="b">{med[0]:.0f}</td><td></td><td>{med[1]:.0f}</td></tr>']
  open(f"{FIG}/rank-rows.html", "w").write("\n".join(body) + "\n")
  print(f"{'data':26}{'rows':>7}{'med':>5}{'q25':>5}{'q75':>5}{'rnd'+str(C):>6}")
  for name, n, m, lo, hi, rnd in out:
    print(f"{name:26}{n:7d}{m:5.0f}{lo:5.0f}{hi:5.0f}{rnd:6.0f}")
  print(f"{'median, all '+str(len(out)):26}{'':7}{med[0]:5.0f}{'':10}{med[1]:6.0f}")
  print("-> slides/fig/rank-rows.html")

main()
