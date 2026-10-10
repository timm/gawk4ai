import subprocess, sys
import numpy as np
from sklearn.metrics import multilabel_confusion_matrix
from lib import table
d = table(sys.stdin, sep=" ")
got, want = d[0], d[1]
labels = np.unique(want)
print("   n,   a,   b,   c,   d,acc,pre, pf, pd, class", flush=True)
pc = lambda x, y: int(100 * x / y + 0.5) if y else 0
out = []
for x, ((a, c), (b, dd)) in zip(
        labels, multilabel_confusion_matrix(want, got, labels=labels)):
    out.append("%4d,%4d,%4d,%4d,%4d,%3d,%3d,%3d,%3d, %s\n" % (
        b + dd, a, b, c, dd, pc(a + dd, len(d)), pc(dd, c + dd),
        pc(c, a + c), pc(dd, b + dd), x))
subprocess.run(["sort", "-t,", "-k9nr"], input="".join(out), text=True)
