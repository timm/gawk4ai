"""y = mean y of the K nearest train rows in the predicted y-bin.
usage: ... | nb.py | python3 knn.py T=n d -
(ALL=1: ignore the bin; S=n: keep only n train rows;
 I=1: only search rows sharing the test row's value in the
      train column with most variance)"""
import math
import re
from collections import Counter, defaultdict
from types import SimpleNamespace

from lib import eq, fmt, num, records

FS = re.compile(" *, *")
DIGITS = re.compile("[0-9]+")


class Knn:
    def __init__(self, o):
        self.o = o
        self.x, self.y, self.bin = {}, {}, {}
        self.n = self.s = self.s2 = 0
        self.col, self.idx = None, defaultdict(list)

    def train(self, r, row):
        y = self.y[r] = num(row[-1])
        self.n += 1
        self.s += y
        self.s2 += y * y
        self.x[r] = row[:-1]

    def bins(self):
        mu = self.s / self.n
        sd = math.sqrt(self.s2 / self.n - mu * mu) + 1E-32
        for r, y in self.y.items():
            z = -1.7 * (y - mu) / sd
            self.bin[r] = str(int(self.o.B / (1 + math.exp(min(z, 700)))))

    def index1(self):
        "Index the train rows by the column with most variance."
        k, m, m2 = Counter(), Counter(), Counter()
        for row in self.x.values():
            for c, v in enumerate(row):
                if DIGITS.fullmatch(v):
                    k[c] += 1
                    m[c] += num(v)
                    m2[c] += num(v) ** 2
        most = 0
        for c in k:
            v = m2[c] / k[c] - (m[c] / k[c]) * (m[c] / k[c])
            if v > most:
                most, self.col = v, c
        for r, row in self.x.items():
            self.idx[row[self.col]].append(r)

    def predict(self, line, test):
        p = (line.split() + [""])[0]
        z = FS.split(test)
        return fmt(self.knn(p, z)) + " " + z[-1]

    def knn(self, p, z):
        o = self.o
        if o.I and len(self.idx[z[self.col]]) >= o.K:
            rows = self.idx[z[self.col]]
        else:
            rows = [r for r in self.y if o.ALL or eq(self.bin[r], p)]
        d = {r: self.near(r, z) for r in rows}
        nearest = sorted(d, key=lambda r: (d[r], r))[:o.K]
        total = 0
        for r in nearest:
            total += self.y[r]
        return total / len(nearest)

    def near(self, r, z):
        d = 0
        for a, b in zip(self.x[r], z):
            d += self.dist(a, b)
        return d

    def dist(self, a, b):
        "Bins are ordered; anything else is 0/1."
        if a == "?" or b == "?":
            return 1
        if DIGITS.fullmatch(a + b):
            return abs(num(a) - num(b)) / (self.o.B - 1)
        return not eq(a, b)


def main():
    o = SimpleNamespace(B=7, K=5, ALL=0, T=0, S=0, I=0)
    knn, test = Knn(o), {}
    for fileno, fnr, line in records(o):
        if fileno == 1:
            if fnr > o.T:
                test[fnr - o.T] = line
            elif not o.S or fnr <= o.S:
                knn.train(fnr, FS.split(line))
            continue
        if fnr == 1:
            knn.bins()
            if o.I:
                knn.index1()
        print(knn.predict(line, test.get(fnr, "")))


main()
