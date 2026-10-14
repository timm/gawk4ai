# Contributing

`README.md#house-rules` says how to write the code. This says what a patch
has to pass, and what to do when it does not.

## Before you push

```sh
gawk --lint -f bundle/gawk/yours.awk </dev/null   # must be quiet
awk 'length>75' bundle/gawk/yours.awk             # must print nothing
bundle/gawk/sweep.sh > /tmp/after.txt             # 5 files x 5 seeds
diff /tmp/before.txt /tmp/after.txt
```

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
| Parallel arrays: `Mu[c]`, `Sd[c]`, `M2[c]`, `N[c]` | One keyed array: `num[c]["m1"]`. Four globals become one. |
| A function reaching for a global | Pass it in. Arrays go by reference, so it costs nothing, and the dependency moves into the signature where a reader sees it. |
| A global two functions share as scratch | Make it a local of the caller and pass it. An unsupplied trailing parameter is a fresh local array per call. |
| A global that is written and never read | Delete it. `T`, `R`, `Burn`, `Eras`, `Num` all looked load-bearing. Grep for a reader before believing otherwise. |
| A flag meaning "we are at the end" | Change the data so the structure says it. A blank line that *separates* eras instead of *terminating* them leaves the last era unclosed, so it is never learned — no flag, no countdown, no knob. |
| A loop over all fields that skips most of them | Loop the set instead. `for(c in num)` beat `for(c=1;c<=NF;c++)` by 50% on a file with no numeric columns. |
| Frozen values stored in a global | If one function freezes and uses them, make them locals it passes. Then "nothing frozen is stored" is true by construction. |
| A name one letter from a builtin | Rename. `flush()` is legal; `fflush()` is a builtin and cannot be redefined. |
| Reaching for `$NF` as the class | Find it by header. The class is **not** always last: `mnist_1.csv` has it at column 1. |

## Contracts a stage may rely on

**Headers.** A name ending `!` is a goal; ending `X` means ignore the column;
a leading capital means numeric. Two counterexamples cost real time here, so
test against them: `spambase.csv` has a column literally named `CHAR_FREQ_#`
and a second column ending in `!`; `mnist_1.csv` puts the class first.

**The stream.** `shuf.awk` shuffles, deals rows out in eras separated by a
blank line, and prefixes each row with `binsX`: how many rows are still to
come, counting down to 0. Era 1 absorbs the remainder, so the last era is
always exactly `Era` rows.

**Padding.** `shuf.awk` rebuilds every record with `OFS=","`, so everything
downstream may use `FS=","` rather than the padded-comma regex.

**Knobs.** Set them as operands, not with `-v`:

```sh
gawk -f nb1.awk B=20 f.csv      # works
gawk -v B=20 -f nb1.awk f.csv   # silently lost: BEGIN overwrites it
```
