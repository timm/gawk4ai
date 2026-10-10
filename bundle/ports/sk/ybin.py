import pandas as pd
from lib import cli, table, bins
o, (f, _) = cli(T=0, B=7)
d = table(f, sep=",")
y = pd.to_numeric(d.iloc[:, -1])
yt = y[: o["T"]]
d[d.columns[-1]] = bins(y, yt.mean(), yt.std(ddof=0), o["B"])
print(d.to_csv(index=False, header=False), end="")
