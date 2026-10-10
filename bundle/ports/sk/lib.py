import sys, io, warnings
import numpy as np, pandas as pd
warnings.filterwarnings("ignore")


def cli(**defaults):
    "awk-style args: name=value options, then files ('-' = stdin)"
    opts, files = dict(defaults), []
    for a in sys.argv[1:]:
        if "=" in a and not a.startswith("/"):
            k, v = a.split("=", 1)
            opts[k] = type(defaults.get(k, ""))(v) if k in defaults else v
        else:
            files.append(sys.stdin if a == "-" else open(a))
    return opts, files or [sys.stdin]


def table(f, header=None, sep=r" *, *"):
    return pd.read_csv(f, sep=sep, header=header, dtype=str,
                       engine="python", keep_default_na=False)


def bins(x, mu, sd, B=7):
    return (B / (1 + np.exp(-1.7 * (x - mu) / (sd + 1e-32)))).astype(int)
