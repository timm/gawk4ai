#!/usr/bin/env python3 -B
# vim: set et sw=2 ts=2 sts=2 cc=75 :
# clas.py: RETIRED as a harness -- small.py replaced it, and the
# `prep | bin | nb` pipeline it drove is gone.  What is left is the
# pair of tests small.py imports: are two sets of runs the same, and
# how often did a guess match.  Thresholds from ~/gh/super/start.py.
from bisect import bisect_right

CLIFFS = .197

def cliffs(xs, ys):          # true if the effect size is small
  gt = sum(x > y for x in xs for y in ys)
  lt = sum(x < y for x in xs for y in ys)
  return abs(gt - lt) / (len(xs) * len(ys)) <= CLIFFS

def ks(xs, ys):              # kolmogorov-smirnov: "same" at 95%?
  xs, ys = sorted(xs), sorted(ys)
  n, m = len(xs), len(ys)
  cdf = lambda a, v: bisect_right(a, v) / len(a)
  d = max(abs(cdf(xs, v) - cdf(ys, v)) for v in xs + ys)
  return d <= 1.36 * ((n + m) / (n * m)) ** 0.5

def same(xs, ys):            # as ~/gh/super/eval.py has it
  return cliffs(xs, ys) and ks(xs, ys)

def acc(got, want):
  return 100 * sum(a == b for a, b in zip(got, want)) / len(want)
