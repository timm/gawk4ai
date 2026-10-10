import numpy as np
from lib import cli
o, (f,) = cli(C=5)
p, a = np.loadtxt(f, ndmin=2).T
best = a[np.argsort(p, kind="stable")[: o["C"]]].min()
print("%.1f" % (100 * ((a < best).sum() + 1) / len(a)))
