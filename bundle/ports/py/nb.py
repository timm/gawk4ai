"""Incremental naive Bayes: train on rows 1..T, classify rows > W.
usage: python3 nb.py [T=n W=n] f"""
import math
import re
from collections import Counter, defaultdict
from types import SimpleNamespace

from lib import records

FS = re.compile(" *, *")


def like(f, n_rows, h, row, o):
    "log P(h) + sum log P(x|h)"
    n = f[h][len(row) - 1][h]
    p = (n + o.k) / (n_rows + o.k * len(f))
    out = math.log(p)
    for c, x in enumerate(row[:-1]):
        if x != "?":
            out += math.log((f[h][c][x] + o.m * p) / (n + o.m))
    return out


def classify(f, n_rows, row, o):
    best, out = None, ""
    for h in f:
        t = like(f, n_rows, h, row, o)
        if not out or t > best:
            best, out = t, h
    return out


def main():
    o = SimpleNamespace(m=2, k=1, T=1E32, W=10)
    f = defaultdict(lambda: defaultdict(Counter))  # f[class][col][value]
    n_rows = 0
    for nr, (_, _, line) in enumerate(records(o), 1):
        row = FS.split(line)
        if nr > o.W:
            print(classify(f, n_rows, row, o), row[-1])
        if nr <= o.T:
            n_rows += 1
            for c, x in enumerate(row):
                if x != "?":
                    f[row[-1]][c][x] += 1


main()
