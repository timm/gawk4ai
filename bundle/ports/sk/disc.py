import pandas as pd
from lib import cli, table, bins
o, (f, _) = cli(B=7)
d = table(f, header=0, sep=",")
for c in d.columns[:-1]:
    if c[0].isupper():
        x = pd.to_numeric(d[c], errors="coerce")
        b = bins(x.fillna(0), x.mean(), x.std(ddof=0), o["B"])
        d[c] = b.astype(str).where(x.notna(), "?")
print(d.to_csv(index=False), end="")
