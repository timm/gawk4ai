#!/usr/bin/env python3 -B
# vim: set et sw=2 ts=2 sts=2 cc=75 :
# loc.py: count the tools the deck teaches, in every language, and write
# the table body that slide6.html includes.  Lines = non-blank, non-
# comment; a python docstring is that language's usage comment, so it
# does not count either.  Counting the files means nothing goes stale.
# usage: python3 slides/loc.py   (or: make fig)
import os, re

HERE = os.path.dirname(os.path.abspath(__file__))
ROOT = os.path.dirname(HERE)
PORTS = f"{ROOT}/bundle/ports"

TOOLS = "abcd nb shuffle disc some knnr ydist rank tfidf twcnb".split()
LANGS = [("gawk", f"{ROOT}/bundle/gawk", "{}.awk", None),
         ("lua", f"{PORTS}/lua", "{}.lua", "lib.lua"),
         ("js", f"{PORTS}/js", "{}.js", "lib.js"),
         ("python", f"{PORTS}/py", "{}.py", "lib.py"),
         ("rust", f"{PORTS}/rust/src", "bin/{}.rs", "lib.rs"),
         ("python+sklearn", f"{PORTS}/sk", "{}.py", "lib.py")]
COMMENT = re.compile(r"^\s*(#|//|--|$)")
MARK = re.compile('"""' + "|'''")

def loc(path):  # non-blank, non-comment lines; None if there is no file
  if not os.path.exists(path): return None
  n, doc = 0, False
  for line in open(path):
    marks = len(MARK.findall(line))
    if doc:                              # inside a multi-line docstring
      doc = marks % 2 == 0
      continue
    if marks and MARK.match(line.strip()):
      doc = marks % 2 == 1               # a docstring opens here
      continue
    if not COMMENT.match(line): n += 1
  return n

def cell(v): return f'<td>{"&mdash;" if v is None else v}</td>'

def main():
  n = {lang: {} for lang, *_ in LANGS}
  for lang, d, pat, lib in LANGS:
    for t in TOOLS: n[lang][t] = loc(f"{d}/{pat.format(t)}")
    n[lang]["lib"] = loc(f"{d}/{lib}") if lib else None
  out = [f"<tr><td>{t}</td>" + "".join(cell(n[l][t]) for l, *_ in LANGS)
         + "</tr>" for t in TOOLS]
  out += ['<tr class="lib"><td>shared lib</td>'
          + "".join(cell(n[l]["lib"]) for l, *_ in LANGS) + "</tr>"]
  tot = {l: sum(v or 0 for v in n[l].values()) for l, *_ in LANGS}
  out += ['<tr class="tot"><td>total</td>'
          + "".join(cell(tot[l]) for l, *_ in LANGS) + "</tr>",
          '<tr class="rel"><td>&times; gawk</td>'
          + "".join(f'<td>{tot[l] / tot["gawk"]:.1f}</td>'
                    for l, *_ in LANGS) + "</tr>"]
  with open(f"{HERE}/fig/loc-rows.html", "w") as f:
    f.write("\n".join(out) + "\n")
  print(f"{'tool':10}" + "".join(f"{l:>16}" for l, *_ in LANGS))
  for t in TOOLS + ["lib"]:
    print(f"{t:10}" + "".join(f"{str(n[l][t]):>16}" for l, *_ in LANGS))
  print(f"{'total':10}" + "".join(f"{tot[l]:>16}" for l, *_ in LANGS))
  print("-> slides/fig/loc-rows.html")

main()
