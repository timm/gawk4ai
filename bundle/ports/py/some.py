"""Keep N labelled rows, then the test rows (> T). f is pre-shuffled.
usage: python3 some.py N=100 T=n f"""
from types import SimpleNamespace

from lib import records

o = SimpleNamespace(N=0, T=0)
for nr, (_, _, line) in enumerate(records(o), 1):
    if nr <= o.N or nr > o.T:
        print(line)
