"""Regression tree: split on col<=bin (or col==symbol) that most
reduces squared error; stop below M rows. Prints y^ y.
usage: python3 tree.py T=n [M=8] d   (d: binned, no header)"""
import re
from types import SimpleNamespace

from lib import eq, fmt, num, records

DIGITS = re.compile("[0-9]+")


def goes(a, v):
    "Bins: <=; symbols: ==."
    if DIGITS.fullmatch(a + v):
        return num(a) <= num(v)
    return eq(a, v)


class Tree:
    def __init__(self, o):
        self.o = o
        self.x, self.y = {}, {}
        self.mean, self.col, self.cut = {}, {}, {}

    def train(self, r, row):
        self.y[r] = num(row[-1])
        self.x[r] = row[:-1]

    def grow(self, ids, k, ncols):
        s = 0
        for i in ids:
            s += self.y[i]
        self.mean[k] = s / len(ids)
        if len(ids) < self.o.M:
            return
        best, bc, bv = self.sse(ids), None, None
        for c in range(ncols):
            seen = set()
            for i in ids:
                v = self.x[i][c]
                if v in seen:
                    continue
                seen.add(v)
                e = (self.sse(self.part(ids, c, v, True))
                     + self.sse(self.part(ids, c, v, False)))
                if e < best:
                    best, bc, bv = e, c, v
        if bc is None:
            return
        self.col[k], self.cut[k] = bc, bv
        self.grow(self.part(ids, bc, bv, True), 2 * k, ncols)
        self.grow(self.part(ids, bc, bv, False), 2 * k + 1, ncols)

    def part(self, ids, c, v, want):
        return [i for i in ids if goes(self.x[i][c], v) == want]

    def sse(self, ids):
        if not ids:
            return 0
        s = s2 = 0
        for i in ids:
            s += self.y[i]
            s2 += self.y[i] * self.y[i]
        return s2 - s * s / len(ids)

    def leaf(self, row):
        k = 1
        while k in self.col:
            k = 2 * k + (not goes(row[self.col[k]], self.cut[k]))
        return self.mean[k]


def main():
    o = SimpleNamespace(M=8, T=0)
    tree = Tree(o)
    for nr, (_, _, line) in enumerate(records(o), 1):
        row = line.split(",")
        if nr <= o.T:
            tree.train(nr, row)
            continue
        if nr == o.T + 1:
            tree.grow(list(range(1, o.T + 1)), 1, len(row) - 1)
        print(fmt(tree.leaf(row)), row[-1])


main()
