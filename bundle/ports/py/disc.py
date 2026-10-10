"""Discretize numeric columns (names start upper case) into B bins.
usage: python3 disc.py [B=7] f f   (pass 1: mean,sd; pass 2: bins)"""
import math
import re
from collections import Counter
from types import SimpleNamespace

from lib import num, records


def discretize(x, mu, sd, bins):
    z = -1.7 * (x - mu) / sd
    return int(bins / (1 + math.exp(min(z, 700))))


def main():
    o = SimpleNamespace(B=7)
    cols, n, s, s2 = [], Counter(), Counter(), Counter()
    for fileno, fnr, line in records(o):
        row = line.split(",")
        if fnr == 1:
            cols = [c for c, name in enumerate(row[:-1])
                    if re.match("[A-Z]", name)]
            if fileno > 1:
                print(line)
        elif fileno == 1:
            for c in cols:
                if row[c] != "?":
                    x = num(row[c])
                    n[c] += 1
                    s[c] += x
                    s2[c] += x * x
        else:
            for c in n:
                if row[c] != "?":
                    mu = s[c] / n[c]
                    sd = math.sqrt(s2[c] / n[c] - mu * mu) + 1E-32
                    row[c] = str(discretize(num(row[c]), mu, sd, o.B))
            print(",".join(row))


main()
