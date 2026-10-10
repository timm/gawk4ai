import pandas as pd
from sklearn.compose import make_column_transformer
from sklearn.neighbors import KNeighborsRegressor
from sklearn.pipeline import make_pipeline
from sklearn.preprocessing import MinMaxScaler, OneHotEncoder
from lib import cli, table
o, (f,) = cli(T=0, K=5)
d, T = table(f, header=0), o["T"]
X, y = d.iloc[:, :-1], pd.to_numeric(d.iloc[:, -1])
num = [c for c in X.columns if c[0].isupper()]
X[num] = X[num].apply(pd.to_numeric, errors="coerce").fillna(0)
ct = make_column_transformer((MinMaxScaler(), num),
                             remainder=OneHotEncoder(handle_unknown="ignore"))
m = make_pipeline(ct, KNeighborsRegressor(o["K"])).fit(X[:T], y[:T])
for p, a in zip(m.predict(X[T:]), y[T:]):
    print("%.6g %.6g" % (p, a))
