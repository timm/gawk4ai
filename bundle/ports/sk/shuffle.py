from lib import cli, table
o, (f,) = cli(seed=1)
d = table(f, header=0, sep=",")
print(d.sample(frac=1, random_state=o["seed"]).to_csv(index=False), end="")
