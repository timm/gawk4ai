"""Keep x columns; swap the goals (names ending in + or -) for one
column: distance to heaven (0 = best). Skips names ending in X.
usage: python3 ydist.py f f    (MOOT optimize csv, 2 passes)"""
import math
import re
from types import SimpleNamespace

from lib import fmt, num, records

FS = re.compile(" *, *")


def main():
    o = SimpleNamespace()
    w, xs, lo, hi = {}, [], {}, {}  # w[c]: heaven, 1=max, 0=min
    for fileno, fnr, line in records(o):
        row = FS.split(line)
        if fnr == 1:
            w.clear()
            xs.clear()
            for c, s in enumerate(row):
                if s.endswith(("+", "-")):
                    w[c] = int(s.endswith("+"))
                elif not s.endswith("X"):
                    xs.append(c)
            if fileno > 1:
                print(",".join([row[c] for c in xs] + ["D2h-"]))
        elif fileno == 1:
            for c in w:
                if row[c] != "?":
                    v = num(row[c])
                    lo[c] = min(lo.get(c, v), v)
                    hi[c] = max(hi.get(c, v), v)
        else:
            d = 0
            for c in w:
                n = (num(row[c]) - lo.get(c, 0)) / (
                    hi.get(c, 0) - lo.get(c, 0) + 1E-32)
                d += (w[c] - n) * (w[c] - n)
            print(",".join([row[c] for c in xs]
                           + [fmt(math.sqrt(d / len(w)))]))


main()
