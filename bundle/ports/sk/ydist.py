import numpy as np
from lib import cli, table
o, (f, _) = cli()
d = table(f, header=0)
goals = [c for c in d.columns if c[-1] in "+-"]
xs = [c for c in d.columns if c not in goals and c[-1] != "X"]
y = d[goals].astype(float)
y = (y - y.min()) / (y.max() - y.min() + 1e-32)
heaven = np.array([c[-1] == "+" for c in goals], float)
d = d[xs].assign(**{"D2h-": np.sqrt(((heaven - y) ** 2).mean(axis=1))})
print(d.to_csv(index=False), end="")
