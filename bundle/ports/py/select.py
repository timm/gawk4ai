"""Keep the K columns with least H(class|col); default K = half.
usage: python3 select.py T=n [K=5] d d"""
import math
from collections import Counter, defaultdict
from types import SimpleNamespace

from lib import records


def rank(n, ny, o, nf):
    "Columns sorted by conditional entropy; return the best K."
    e = Counter()
    for c in n:
        for v in n[c]:
            for k in ny[c][v].values():
                p = k / n[c][v]
                e[c] -= n[c][v] / o.T * p * math.log(p)
    k = o.K or (nf - 1) // 2
    return set(sorted(e, key=lambda c: (e[c], c))[:k])


def main():
    o = SimpleNamespace(K=0, T=0)  # K=0: keep half
    n = defaultdict(Counter)                        # n[col][value]
    ny = defaultdict(lambda: defaultdict(Counter))  # ny[col][value][y]
    use = set()
    for fileno, fnr, line in records(o):
        row = line.split(",")
        if fileno == 1:
            if fnr <= o.T:
                for c, x in enumerate(row[:-1]):
                    if x != "?":
                        n[c][x] += 1
                        ny[c][x][row[-1]] += 1
            continue
        if fnr == 1:
            use = rank(n, ny, o, len(row))
        kept = [x for c, x in enumerate(row[:-1]) if c in use]
        print(",".join(kept + [row[-1]]))


main()
