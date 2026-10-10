import numpy as np
from sklearn.naive_bayes import CategoricalNB
from sklearn.preprocessing import OrdinalEncoder
from lib import cli, table
o, (f,) = cli(T=10**32, W=10)
d = table(f)
X = OrdinalEncoder().fit_transform(d.iloc[:, :-1]).astype(int)
y = d.iloc[:, -1].to_numpy()
nb = CategoricalNB(min_categories=X.max(axis=0) + 1)
classes = np.unique(y)
for i in range(len(y)):
    if i >= o["W"]:
        print(nb.predict(X[i : i + 1])[0], y[i])
    if i < o["T"]:
        nb.partial_fit(X[i : i + 1], y[i : i + 1], classes=classes)
