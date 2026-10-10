"""Shuffle rows; the header stays first.
usage: python3 shuffle.py [seed=1] f"""
import random
from types import SimpleNamespace

from lib import records


def main():
    o = SimpleNamespace(seed=1)
    rows = []
    for nr, (_, _, line) in enumerate(records(o), 1):
        if nr == 1:
            random.seed(o.seed)
            print(line)
        else:
            rows.append(line)
    random.shuffle(rows)
    for line in rows:
        print(line)


main()
