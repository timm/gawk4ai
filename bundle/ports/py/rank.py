"""Check the C rows with the best (lowest) predictions; print how
the best of them really ranks among all n test rows, as s=r/n.
usage: ... | python3 rank.py [C=5]   (lines: predicted actual)"""
from types import SimpleNamespace

from lib import fmt, lt, num, records


def main():
    o = SimpleNamespace(C=5)
    p, a = [], []
    for _, _, line in records(o):
        f = line.split() + ["", ""]
        p.append(f[0])
        a.append(f[1])
    top = sorted(range(len(p)), key=lambda i: (num(p[i]), i))[:o.C]
    b = a[top[0]]
    for i in top:
        if lt(a[i], b):
            b = a[i]
    n = 1
    for x in a:
        n += lt(x, b)
    print(fmt(n / len(a)))


main()
