#!/usr/bin/env python3 -B
# vim: set et sw=2 ts=2 sts=2 cc=75 :
# tinyai.py: the ideas of this deck as one program, not a pipe demo.
# Cells are typed once, at read.  After that everything passes Rows and
# Tbls around: a Row carries its own d2h and guess, a Tbl holds rows and
# knows which columns are x and which are y.  Only the reports make text.
# The eg_ functions at the end are the demos, one per Makefile target.
# usage: ./tinyai.py DEMO [name=value ...]    ./tinyai.py h
import math, os, random, re, sys
from collections import Counter, defaultdict
from collections.abc import Callable, Iterator

#-- types -----------------------------------------------------------
type QTY = int | float            # any number
type ATOM = QTY | str             # one cell; "?" means unknown
type CELLS = list[ATOM]           # one row's worth of cells
type COL = o                      # what one column has seen
type ROW = o                      # cells, plus the d2h and guess we add
type TBL = o                      # rows, and the cols that watch them
type KLASSES = dict[ATOM, TBL]    # one table per class label
type WEIGHTS = dict[ATOM, list[float]]   # twcnb's per-class weights

MOOT = "~/tmp/moot"
UP = re.compile("[A-Z]")
STOP = re.compile("that|this|with|from|have|which|their|these|"
                  "been|such|more|were|also|they|than|into")

class o(dict):  # dicts with dot access; easier than SimpleNamespace
  __getattr__, __setattr__ = dict.__getitem__, dict.__setitem__

the = o()

def atom(s: str) -> ATOM:
  "'22' -> 22, '3.1' -> 3.1; '?' and 'x' stay strings."
  s = s.strip()
  for fn in (int, float):
    try: return fn(s)
    except ValueError: pass
  return s

def csv(file: str, sep: str = ",") -> Iterator[CELLS]:
  "Rows of FILE, typed, one list at a time."
  with open(os.path.expanduser(file)) as f:
    for line in f:
      if line.strip(): yield [atom(s) for s in line.split(sep)]

#-- columns ---------------------------------------------------------
def Col(txt: str = " ", at: int = 0, sym: bool = False) -> COL:
  "An upper case name, or a goal, means a numeric column."
  return o(at=at, txt=txt, n=0, s=0, s2=0, lo=None, hi=None, goal=None,
           has=Counter(),
           num=not sym and (bool(UP.match(txt)) or txt[-1:] in "+-"))

def add(col: COL, v: ATOM) -> ATOM:  # show V to COL; "?" says nothing
  if v == "?": return v
  col.n += 1
  if not col.num: col.has[v] += 1
  else:
    col.lo = v if col.lo is None else min(col.lo, v)
    col.hi = v if col.hi is None else max(col.hi, v)
    col.s += v; col.s2 += v * v
  return v

def span(col: COL) -> float: return col.hi - col.lo + 1E-32
def norm(col: COL, v: QTY) -> float: return (v - col.lo) / span(col)
def mu(col: COL) -> float: return col.s / col.n
def sd(col: COL) -> float:
  return math.sqrt(col.s2 / col.n - mu(col)**2) + 1E-32

def bin(col: COL, v: QTY) -> int:
  "A numeric, squashed onto 0..B by the logistic curve."
  return int(the.B / (1 + math.exp(
    min(-1.7 * (v - mu(col)) / sd(col), 700))))

def gap(col: COL, a: ATOM, b: ATOM) -> QTY:
  "How far apart two values of one column are."
  if a == "?" or b == "?": return 1
  return (a - b) / span(col) if col.num else a != b

#-- rows and tables -------------------------------------------------
def Row(cells: CELLS) -> ROW: return o(cells=cells, d2h=None, guess=None)

def Tbl(names: CELLS, sym: bool = False) -> TBL:
  "Header -> columns. A name ends in +- for a goal, X to be skipped."
  t = o(names=names, sym=sym, rows=[], all=[], x=[], y=[])
  for at, s in enumerate(names):
    c = Col(str(s), at, sym); t.all += [c]
    if c.txt[-1:] in "+-": c.goal = int(c.txt[-1] == "+"); t.y += [c]
    elif c.txt[-1:] != "X": t.x += [c]
  if not t.y: t.y, t.x = [t.all[-1]], t.x[:-1]   # no goals: y is last
  return t

def addRow(t: TBL, row: ROW | CELLS) -> ROW:
  row = row if isinstance(row, dict) else Row(row)
  t.rows += [row]
  for c in t.all: add(c, row.cells[c.at])
  return row

def addRows(t: TBL, src) -> TBL: [addRow(t, r) for r in src]; return t

def clone(t: TBL, src=(), sym: bool = None) -> TBL:
  return addRows(Tbl(t.names, t.sym if sym is None else sym), src)

def read(file: str, sep: str = ",") -> TBL:
  "A file -> a Tbl. Its first line names the columns."
  src = csv(file, sep)
  return addRows(Tbl(next(src)), src)

def shuffle(t: TBL) -> TBL:
  "In place: reordering rows changes no column stat."
  random.shuffle(t.rows); return t

def halve(t: TBL) -> tuple[TBL, list[ROW]]:
  "The deck's split: train on half, test on the rest."
  n = len(t.rows) // 2
  return clone(t, t.rows[:n]), t.rows[n:]

#-- distance --------------------------------------------------------
def dist(vs, n: int) -> float: return math.sqrt(sum(v * v for v in vs) / n)

def xdist(t: TBL, r1: ROW, r2: ROW) -> float:
  return dist([gap(c, r1.cells[c.at], r2.cells[c.at]) for c in t.x],
              len(t.x))

def ydist(t: TBL, row: ROW) -> float:
  "Distance to heaven (0 = best); cached on the row."
  if row.d2h is None:
    row.d2h = dist([c.goal - norm(c, row.cells[c.at]) for c in t.y],
                   len(t.y))
  return row.d2h

def pick(options, f: Callable, lo=False) -> ATOM:
  "The best option: arg max of F, or arg min when LO."
  best, out = None, None
  for h in options:
    v = f(h)
    if out is None or (v < best if lo else v > best): best, out = v, h
  return out

#-- pre-processors --------------------------------------------------
def disc(t: TBL) -> TBL:  # every numeric x column -> B bins
  out = clone(t, [])
  for row in t.rows:
    cells = row.cells[:]
    for c in t.x:
      if c.num and c.n and cells[c.at] != "?":
        cells[c.at] = bin(c, cells[c.at])
    addRow(out, Row(cells))
  return out

def tfidf(t: TBL) -> TBL:
  "(text, klass) rows -> counts of the K best tf*idf words."
  df, tf = Counter(), Counter()
  def words(s):
    a = Counter()
    for w in re.split("[^a-z]+", str(s).lower()):
      if len(w) > 3 and not STOP.fullmatch(w): a[w] += 1
    return a
  bag = [words(r.cells[0]) for r in t.rows]
  for a in bag:
    for w, v in a.items(): df[w] += 1; tf[w] += v
  sc = {w: tf[w] * math.log(len(bag) / df[w]) for w in df}
  keep = (sorted(sc, key=lambda w: (sc[w], w), reverse=True)
          + [""] * the.K)[:the.K]
  out = Tbl(keep + ["klass"])
  for a, r in zip(bag, t.rows):
    addRow(out, Row([a[w] for w in keep] + [r.cells[-1]]))
  return out

#-- learners --------------------------------------------------------
def byKlass(t: TBL) -> KLASSES:
  "One Tbl per klass. nb counts values, so these are all symbolic."
  klasses = {}
  for row in t.rows:
    addRow(klasses.setdefault(row.cells[-1], clone(t, sym=True)), row)
  return klasses

def nb(t: TBL, klasses: KLASSES, row: ROW) -> ATOM:
  "The most likely klass for ROW, given one table per klass."
  def like(k):                       # log P(k) + sum log P(x|k)
    nk = len(klasses[k].rows)
    n = sum(len(u.rows) for u in klasses.values())
    p = (nk + the.k) / (n + the.k * len(klasses))
    return math.log(p) + sum(
      math.log((klasses[k].all[c.at].has[row.cells[c.at]] + the.m * p)
               / (nk + the.m))
      for c in t.x if row.cells[c.at] != "?")
  return pick(klasses, like)

def knn(t: TBL, row: ROW) -> list[ROW]:  # the K rows nearest ROW
  return sorted(t.rows, key=lambda r: xdist(t, r, row))[:the.K]

def knnr(t: TBL, row: ROW, y: Callable = None) -> float:
  "... and their mean y."
  y, near = y or (lambda r: r.cells[-1]), knn(t, row)
  return sum(y(r) for r in near) / len(near)

def twcnb(t: TBL) -> WEIGHTS:  # Rennie et al. ICML'03, Table 4 (steps 1-6)
  d, df, w = {}, Counter(), {}
  for i, row in enumerate(t.rows):                       # step 1
    for c, v in enumerate(row.cells[:-1]):
      if v > 0: d.setdefault(i, {})[c] = math.log(1 + v); df[c] += 1
  nf = len(t.all)
  s, every, nh, tot = defaultdict(Counter), Counter(), Counter(), 0
  for i, bag in d.items():
    size = 0
    for c in bag:                                        # step 2
      bag[c] *= math.log(len(t.rows) / df[c]); size += bag[c]**2
    for c, v in bag.items():                             # step 3
      z = v / math.sqrt(size + 1E-32)
      y = t.rows[i].cells[-1]
      s[y][c] += z; every[c] += z; nh[y] += z; tot += z
  for h in nh:                                           # steps 4-6
    w[h] = [math.log((every[c] - s[h][c] + 1) / (tot - nh[h] + nf - 1))
            for c in range(nf - 1)]
    z = -sum(w[h])
    w[h] = [v / z for v in w[h]]
  return w

def twcnbGuess(w: WEIGHTS, row: ROW) -> ATOM:            # steps 7,8
  return pick(w, lambda h: sum(math.log(1 + v) * wc
                               for v, wc in zip(row.cells[:-1], w[h])),
              lo=True)

#-- reports ---------------------------------------------------------
def abcd(pairs: list[tuple]) -> str:
  "[(guess, want)] -> the per-class table, as text."
  n, got, want, hit = 0, Counter(), Counter(), Counter()
  for p, a in pairs:
    n += 1; got[p] += 1; want[a] += 1; hit[p] += p == a
  pc = lambda u, v: 100 * u / v if v else 0
  body = []
  for k in want:
    d = hit[k]; b = want[k] - d; c = got[k] - d; a = n - b - c - d
    body += ["%4d,%4d,%4d,%4d,%4d,%5.1f,%5.1f,%5.1f,%5.1f, %s" % (
      want[k], a, b, c, d, pc(a + d, n), pc(d, c + d), pc(c, a + c),
      pc(d, b + d), k)]
  body.sort()
  body.sort(key=lambda s: -float(s.split(",")[8]))
  return "\n".join(
    ["   n,   a,   b,   c,   d,  acc,  pre,   pf,   pd, class"] + body)

def rank(t: TBL, rows: list[ROW]) -> float:
  "Check the C best-guessed rows: where does the best of them rank?"
  top = sorted(rows, key=lambda r: r.guess)[:the.C]
  b = min(ydist(t, r) for r in top)
  return 100 * (1 + sum(ydist(t, r) < b for r in rows)) / len(rows)

#-- demos -----------------------------------------------------------
def eg_nb():
  "m=2 k=1 W=10         0. incremental naive Bayes, on soybean"
  t = read(f"{MOOT}/classify/soybean.csv")
  klasses, out = {}, []
  for n, row in enumerate(t.rows, 1):  # classify each row, then learn it
    if n > the.W: out += [(nb(t, klasses, row), row.cells[-1])]
    addRow(klasses.setdefault(row.cells[-1], clone(t, sym=True)), row)
  print(abcd(out))

def eg_disc():
  "B=7 m=2 k=1 seed=1   1. numeric x: discretize, then naive Bayes"
  train, test = halve(disc(shuffle(read(f"{MOOT}/classify/diabetes.csv"))))
  klasses = byKlass(train)
  print(abcd([(nb(train, klasses, r), r.cells[-1]) for r in test]))

def eg_opt():
  "N=25 K=5 C=5 seed=1  2. good configs: label N, kNN guesses, check C"
  t = shuffle(read(f"{MOOT}/optimize/config/SS-K.csv"))
  train, test = clone(t, t.rows[:the.N]), t.rows[len(t.rows) // 2:]
  for row in test: row.guess = knnr(train, row, lambda r: ydist(t, r))
  print(f"rank {rank(t, test):.1f}%")

def eg_twcnb():
  "K=64 seed=1          3. rare classes: tf-idf + TWCNB on text"
  raw = read(f"{MOOT}/text_mining/reading/raw/Kitchenham.csv")
  text = Tbl(["text", "klass"])
  for r in raw.rows:
    addRow(text, Row([f"{r.cells[1]} {r.cells[2]}", r.cells[-1]]))
  train, test = halve(shuffle(tfidf(text)))
  w = twcnb(train)
  print(abcd([(twcnbGuess(w, r), r.cells[-1]) for r in test]))

def setup(f: Callable) -> None:
  "A demo's defaults are the name=value pairs in its usage line."
  the.update(dict(m=2, k=1, B=7, K=5, C=5, N=25, W=10, seed=1))
  the.update({k: atom(v)
              for k, v in re.findall(r"(\w+)=(\S+)", f.__doc__ or "")})
  random.seed(the.seed)       # seeded once, here, not inside shuffle

def eg_all():
  "                     run every demo"
  for k, f in list(globals().items()):
    if k[:3] == "eg_" and k not in ("eg_all", "eg_h"):
      print(f"\n# {k[3:]}"); setup(f); f()

def eg_h():
  "                     this help"
  print("usage: ./tinyai.py DEMO [name=value ...]\n")
  for k, f in globals().items():
    if k[:3] == "eg_": print(f"  {k[3:]:<8}{f.__doc__}")

if __name__ == "__main__":
  _av = sys.argv[1:]
  _f = globals().get("eg_" + _av[0]) if _av else None
  setup(_f or eg_h)
  for _a in _av[1:]:
    if _m := re.fullmatch(r"(\w+)=(.*)", _a): the[_m[1]] = atom(_m[2])
  (_f or eg_h)()
