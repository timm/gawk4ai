from sklearn.feature_selection import SelectKBest, mutual_info_classif
from sklearn.preprocessing import OrdinalEncoder
from lib import cli, table
o, (f, _) = cli(T=0, K=0)
d = table(f, sep=",")
X, y = OrdinalEncoder().fit_transform(d.iloc[:, :-1]), d.iloc[:, -1]
k = o["K"] or X.shape[1] // 2
mi = lambda X, y: mutual_info_classif(X, y, discrete_features=True)
s = SelectKBest(mi, k=k).fit(X[: o["T"]], y[: o["T"]])
d = d.iloc[:, list(s.get_support(indices=True)) + [-1]]
print(d.to_csv(index=False, header=False), end="")
