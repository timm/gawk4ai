"""The bits of the awk runtime the ports need: the command-line loop
(name=value options and files, read left to right), awk's string to
number conversion, awk's == on input fields, and number printing."""
import re
import sys

NUM = re.compile(r"\s*[-+]?(\d+\.?\d*|\.\d+)([eE][-+]?\d+)?")
ASSIGN = re.compile(r"([A-Za-z_]\w*)=(.*)", re.S)


def num(s):
    "awk string -> number: the longest numeric prefix, else 0."
    m = NUM.match(s)
    return float(m.group()) if m else 0.0


def isnum(s):
    "Does s look like a number (an awk 'strnum')?"
    m = NUM.match(s)
    return bool(m) and not s[m.end():].strip()


def eq(a, b):
    "awk == on two input strings: numeric if both look numeric."
    return num(a) == num(b) if isnum(a) and isnum(b) else a == b


def lt(a, b):
    "awk < on two input strings: numeric if both look numeric."
    return num(a) < num(b) if isnum(a) and isnum(b) else a < b


def fmt(x):
    "awk number -> string: integers as %d, else %.6g."
    return str(int(x)) if x == int(x) else "%.6g" % x


def option(s):
    "Value of a name=value argument."
    if not isnum(s):
        return s
    x = num(s)
    return int(x) if x == int(x) else x


def records(opt):
    """Yield (fileno, fnr, line) for every input line. An argument
    name=value sets opt.name for the files that follow; '-' (or no
    file arguments at all) means stdin."""
    args = sys.argv[1:]
    if all(ASSIGN.fullmatch(a) for a in args):
        args.append("-")
    fileno = 0
    for arg in args:
        if m := ASSIGN.fullmatch(arg):
            setattr(opt, m[1], option(m[2]))
            continue
        fileno += 1
        with sys.stdin if arg == "-" else open(arg) as f:
            for fnr, line in enumerate(f, 1):
                yield fileno, fnr, line.rstrip("\n")
