import numpy as np, pandas as pd
from sklearn.neighbors import KNeighborsRegressor
from lib import cli, table, bins
o, (f, g) = cli(T=0, K=5, B=7, ALL=0)
d, T = table(f), o["T"]
X = d.iloc[:, :-1].apply(pd.to_numeric, errors="coerce") / (o["B"] - 1)
X, y = X.fillna(9), pd.to_numeric(d.iloc[:, -1])
yb = bins(y[:T], y[:T].mean(), y[:T].std(ddof=0), o["B"])
p = g.read().split("\n")  # predicted bins (ignored if ALL)
for i, row in enumerate(range(T, len(d))):
    m = np.ones(T, bool) if o["ALL"] else yb == int(p[i].split()[0])
    k = KNeighborsRegressor(min(o["K"], m.sum()), metric="manhattan")
    k.fit(X[:T][m], y[:T][m])
    print("%.6g %.6g" % (k.predict(X.iloc[[row]])[0], y[row]))
