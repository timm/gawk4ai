from sklearn.feature_extraction.text import TfidfTransformer
from sklearn.naive_bayes import ComplementNB
from sklearn.pipeline import make_pipeline
from lib import cli, table
o, (f,) = cli(T=0)
d, T = table(f, sep=","), o["T"]
X, y = d.iloc[:, :-1].astype(float), d.iloc[:, -1]
m = make_pipeline(TfidfTransformer(sublinear_tf=True), ComplementNB(norm=True))
m.fit(X[:T], y[:T])
for p, a in zip(m.predict(X[T:]), y[T:]):
    print(p, a)
