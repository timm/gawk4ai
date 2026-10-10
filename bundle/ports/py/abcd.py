"""Per-class confusion-matrix report from 'predicted actual' lines."""
from collections import Counter
from types import SimpleNamespace

from lib import eq, num, records


def pc(x, y):
    return int(100 * x / y + .5) if y else 0


def report(n, got, want, hit):
    print("   n,   a,   b,   c,   d,acc,pre, pf, pd, class")
    lines = []
    for x in want:
        d = hit[x]
        b = want[x] - d
        c = got[x] - d
        a = n - b - c - d
        lines.append("%4d,%4d,%4d,%4d,%4d,%3d,%3d,%3d,%3d, %s" % (
            want[x], a, b, c, d, pc(a + d, n), pc(d, c + d),
            pc(c, a + c), pc(d, b + d), x))
    lines.sort()  # as `sort -t, -k9nr`: pd descending, then whole line
    lines.sort(key=lambda s: -num(s.split(",")[8]))
    for line in lines:
        print(line)


def main():
    n, got, want, hit = 0, Counter(), Counter(), Counter()
    for _, _, line in records(SimpleNamespace()):
        predicted, actual = (line.split() + ["", ""])[:2]
        n += 1
        got[predicted] += 1
        want[actual] += 1
        hit[predicted] += eq(predicted, actual)
    report(n, got, want, hit)


main()
