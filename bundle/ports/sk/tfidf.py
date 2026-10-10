import numpy as np, pandas as pd
from sklearn.feature_extraction.text import CountVectorizer
from lib import cli
o, (f, _) = cli(K=64)
d = pd.read_csv(f, sep="\t", dtype=str, keep_default_na=False, quoting=3)
cv = CountVectorizer(token_pattern=r"[a-z]{4,}", stop_words="english")
X = cv.fit_transform(d.iloc[:, 0])
df = np.asarray((X > 0).sum(axis=0)).ravel()
score = np.asarray(X.sum(axis=0)).ravel() * np.log(X.shape[0] / df)
top = np.argsort(-score)[: o["K"]]
out = pd.DataFrame(X[:, top].toarray())
out["label"] = d.iloc[:, 1]
print(out.to_csv(index=False, header=False), end="")
