"""kNN on raw rows: numbers scaled 0..1 by train min/max, symbols
0/1, "?" 1. Predict mean y of K nearest. Prints y^ y.
usage: python3 knnr.py T=n [K=5] s    (s: shuffled, header)"""
import re
from types import SimpleNamespace

from lib import eq, fmt, lt, num, records

FS = re.compile(" *, *")
UPPER = re.compile("[A-Z]")


class Knnr:
    def __init__(self, o, names):
        self.o = o
        self.isnum = [bool(UPPER.match(s)) for s in names[:-1]]
        self.x, self.y, self.lo, self.hi = {}, {}, {}, {}

    def train(self, r, row):
        self.y[r] = row[-1]
        self.x[r] = row[:-1]
        for c, v in enumerate(self.x[r]):
            if self.numeric(c) and v != "?":
                if c not in self.lo or lt(v, self.lo[c]):
                    self.lo[c] = v
                if c not in self.hi or lt(self.hi[c], v):
                    self.hi[c] = v

    def numeric(self, c):
        return c < len(self.isnum) and self.isnum[c]

    def predict(self, z):
        d = {}
        for r, row in self.x.items():
            d[r] = 0
            for c, a in enumerate(row):
                g = self.gap(c, a, z[c] if c < len(z) else "")
                d[r] += g * g
        nearest = sorted(d, key=lambda r: (d[r], r))[:self.o.K]
        total = 0
        for r in nearest:
            total += num(self.y[r])
        return total / len(nearest)

    def gap(self, c, a, b):
        if a == "?" or b == "?":
            return 1
        if not self.numeric(c):
            return not eq(a, b)
        lo, hi = num(self.lo.get(c, "")), num(self.hi.get(c, ""))
        return (num(a) - num(b)) / (hi - lo + 1E-32)


def main():
    o = SimpleNamespace(K=5, T=0)
    knn = None
    for nr, (_, _, line) in enumerate(records(o), 1):
        row = FS.split(line)
        if nr == 1:
            knn = Knnr(o, row)
        elif nr <= o.T + 1:
            knn.train(nr, row)
        else:
            print(fmt(knn.predict(row)), row[-1])


main()
