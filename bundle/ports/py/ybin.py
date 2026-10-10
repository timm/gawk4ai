"""Replace the class y with its bin (stats from the 1st T rows).
usage: python3 ybin.py T=n d d"""
import math
from types import SimpleNamespace

from lib import num, records


def discretize(x, mu, sd, bins):
    z = -1.7 * (x - mu) / sd
    return int(bins / (1 + math.exp(min(z, 700))))


def main():
    o = SimpleNamespace(B=7, T=0)
    n = s = s2 = 0
    for fileno, fnr, line in records(o):
        row = line.split(",")
        if fileno == 1:
            if fnr <= o.T and row[-1] != "?":
                y = num(row[-1])
                n += 1
                s += y
                s2 += y * y
            continue
        if row[-1] != "?":
            mu = s / n
            sd = math.sqrt(s2 / n - mu * mu) + 1E-32
            row[-1] = str(discretize(num(row[-1]), mu, sd, o.B))
        print(",".join(row))


main()
