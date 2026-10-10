import sys
from lib import cli
o, (f,) = cli(N=100, T=0)
rows = f.readlines()
sys.stdout.writelines(rows[: o["N"]] + rows[o["T"]:])
