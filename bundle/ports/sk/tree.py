from sklearn.preprocessing import OrdinalEncoder
from sklearn.tree import DecisionTreeRegressor
from lib import cli, table
o, (f,) = cli(T=0, M=8)
d, T = table(f, sep=","), o["T"]
X = OrdinalEncoder().fit_transform(d.iloc[:, :-1])
y = d.iloc[:, -1].astype(float)
m = DecisionTreeRegressor(min_samples_split=o["M"]).fit(X[:T], y[:T])
for p, a in zip(m.predict(X[T:]), y[T:]):
    print("%.6g %.6g" % (p, a))
