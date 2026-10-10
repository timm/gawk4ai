"""(text<TAB>label) -> counts of the K words with most tf*idf.
usage: python3 tfidf.py [K=64] f f"""
import math
import re
from collections import Counter
from types import SimpleNamespace

from lib import records

STOP = re.compile("that|this|with|from|have|which|their|these|"
                  "been|such|more|were|also|they|than|into")


def words(text):
    a = Counter()
    for w in re.split("[^a-z]+", text.lower()):
        if len(w) > 3 and not STOP.fullmatch(w):
            a[w] += 1
    return a


def top(n, df, tf, k):
    "The k words with most tf*idf (padded with '' if too few)."
    score = {w: tf[w] * math.log(n / df[w]) for w in df}
    best = sorted(score, key=lambda w: (score[w], w), reverse=True)
    return (best + [""] * k)[:k]


def main():
    o = SimpleNamespace(K=64)
    n, df, tf, keep = 0, Counter(), Counter(), []
    for fileno, fnr, line in records(o):
        if fnr == 1:
            if fileno > 1:
                keep = top(n, df, tf, o.K)
            continue
        text, label = (line.split("\t") + [""])[:2]
        a = words(text)
        if fileno == 1:
            n += 1
            for w in a:
                df[w] += 1
                tf[w] += a[w]
        else:
            print(",".join([str(a[w]) for w in keep] + [label]))


main()
