# Contributing

`README.md#house-rules` says how to write the code. This says what a patch
has to pass, and what to do when it does not.

## Before you push

```sh
gawk --lint -f bundle/gawk/yours.awk </dev/null   # must be quiet
awk 'length>75' bundle/gawk/yours.awk             # must print nothing
bundle/gawk/sweep.sh > /tmp/after.txt             # 8 files x 5 seeds
diff /tmp/before.txt /tmp/after.txt
```

`sweep.sh` fingerprints both pipelines: `shuf | bins | nb` on classify data
and `shuf | rank` on optimize data. A change to `dist.awk` shows up in the
second half or nowhere.

Take the `before.txt` fingerprint **before** you edit. An empty diff means
behaviour did not move. If you meant to move it, the diff is the evidence
for what you changed, and belongs in the commit message.

Before believing a refactor, run the slow one: `sweep.sh --all`, every data
file by three seeds. It takes minutes. Three changes in this repo's history
read as obviously equivalent and were not; all three were caught here and
nowhere else.

Two warnings from `--lint` are expected and good:

- **`parameter 'x' shadows global variable`** — the parameter is in scope,
  which is the point. `deal(a, era, want)` reaches for nothing.
- **`statement has no effect`** on a bare `x[c]` — that is how you add to a
  set. Write `x[c] = c` if you want silence; nothing reads the value.

## Anti-patterns

Each of these happened here. The dodge is the fix that was actually made.

| Smell | Dodge |
|---|---|
| Too many globals | Add a function. Its parameter list is the scope you were missing. `shuf.awk` went 8 globals to 5 this way. |
| State used only inside `END` | Bury `END` in a function: `END { deal(a) }`. Its loop indices become locals — and stop being settable from the command line, where `prog.awk r=5 f.csv` could corrupt them. |
| A counter beside an array (`n`, then `a[n]`) | Delete the counter. `length(a)` is O(1) in gawk (~40ns) and cannot drift out of step. |
| Parallel arrays: `Mu[c]`, `Sd[c]`, `M2[c]`, `N[c]` | One keyed array: `num[c]["mu"]`. Four globals become one. |
| A function reaching for a global | Pass it in. Arrays go by reference, so it costs nothing, and the dependency moves into the signature where a reader sees it. |
| A global two functions share as scratch | Make it a local of the caller and pass it. An unsupplied trailing parameter is a fresh local array per call. |
| A global that is written and never read | Delete it. `T`, `R`, `Burn`, `Eras`, `Num` all looked load-bearing. Grep for a reader before believing otherwise. |
| A flag meaning "we are at the end" | Change the data so the structure says it. One blank line *between* train and test needs no flag, no countdown column and no knob: `train()` reads until it sees the blank, then calls `test()`. Three scripts used to carry their own copy of "where does test start"; now only `shuf.awk` decides. |
| Two loops and a `Testing` flag | Two functions and two `getline` loops. `train()` returning `test()` is the state machine. |
| `while (getline)` | `while (getline > 0)`. getline returns 1, 0 **and -1**; `-1` is truthy, so a read error spins forever. The inner parens are optional — gawk parses `getline > 0` as a comparison — but the `> 0` is not. |
| `length(x)` on an untyped local | That call types `x` **scalar**, and the next `x[i]` is fatal. `delete x` at the top of the function types it as an array instead. |
| A loop over all fields that skips most of them | Loop the set instead. `for(c in num)` beat `for(c=1;c<=NF;c++)` by 50% on a file with no numeric columns. |
| Frozen values stored in a global | If one function freezes and uses them, make them locals it passes. Then "nothing frozen is stored" is true by construction. |
| A name one letter from a builtin | Rename. `flush()` is legal; `fflush()` is a builtin and cannot be redefined. |
| Reaching for `$NF` as the class | Find it by header. The class is **not** always last: `mnist_1.csv` has it at column 1. |

## Contracts a stage may rely on

**Headers.** A name ending `!` is a goal; ending `X` means ignore the column;
a leading capital means numeric. Two counterexamples cost real time here, so
test against them: `spambase.csv` has a column literally named `CHAR_FREQ_#`
and a second column ending in `!`; `mnist_1.csv` puts the class first.

**The stream.** `shuf.awk` shuffles and prints the header, then every row,
with **one blank line inside**: training rows before it, the held-out last
`Test` of them after. That line is the whole protocol. `bins.awk` freezes mu
and sd when it reaches it, `nb.awk` stops learning and starts guessing, and
`rank.awk` stops paying for labels. No tag column, no counter, no stage
needs a knob saying where test begins.

**Shared code.** `rank.awk` pulls in `dist.awk` with `@include`. gawk
resolves that against `AWKPATH`, **not** against the directory of the
including file, so `gawk -f rank.awk` works from `bundle/gawk` and fails by
absolute path from anywhere else. Set `AWKPATH` if you call it from a
script; `slides/rank.py` does.

**Padding.** `shuf.awk` rebuilds every record with `OFS=","`, so everything
downstream may use `FS=","` rather than the padded-comma regex.

**Knobs.** Set them as operands, not with `-v`:

```sh
gawk -f bins.awk B=20 f.csv      # works
gawk -v B=20 -f bins.awk f.csv   # silently lost: BEGIN overwrites it
```
