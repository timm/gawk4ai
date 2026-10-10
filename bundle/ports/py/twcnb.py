"""TWCNB: Rennie et al. ICML'03, Table 4 (steps 1-8).
Input rows: word counts..., label. Train on rows 1..T."""
import math
from collections import Counter, defaultdict
from types import SimpleNamespace

from lib import num, records


def learn(y, d, df, t, nf):
    s, every, nh, tot = defaultdict(Counter), Counter(), Counter(), 0
    for r, row in d.items():
        size = 0
        for c in row:                                      # step 2
            row[c] *= math.log(t / df[c])
            size += row[c] * row[c]
        for c, v in row.items():                           # step 3
            z = v / math.sqrt(size + 1E-32)
            s[y[r]][c] += z
            every[c] += z
            nh[y[r]] += z
            tot += z
    w = {}
    for h in nh:                                           # steps 4-6
        w[h] = [math.log((every[c] - s[h][c] + 1) / (tot - nh[h] + nf - 1))
                for c in range(nf - 1)]
        z = 0
        for v in w[h]:
            z -= v
        w[h] = [v / z for v in w[h]]
    return w


def classify(w, row):                                      # steps 7,8
    best, out = None, ""
    for h, wh in w.items():
        t = 0
        for x, wc in zip(row[:-1], wh):
            t += math.log(1 + num(x)) * wc
        if not out or t < best:
            best, out = t, h
    return out


def main():
    o = SimpleNamespace(T=0)
    y, d, df, w = {}, {}, Counter(), {}
    for nr, (_, _, line) in enumerate(records(o), 1):
        row = line.split(",")
        if nr <= o.T:                                      # step 1
            y[nr] = row[-1]
            for c, x in enumerate(row[:-1]):
                if num(x) > 0:
                    d.setdefault(nr, {})[c] = math.log(1 + num(x))
                    df[c] += 1
            continue
        if nr == o.T + 1:
            w = learn(y, d, df, o.T, len(row))
        print(classify(w, row), row[-1])


main()
