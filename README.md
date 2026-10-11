# tinyai

AI, written small.

This document reports a wonder, in the old sense of the word. In four hours
of LLM-assisted work, we rebuilt the everyday core of machine learning —
naive Bayes, nearest neighbor, tf-idf, discretization, ranking — in under
400 lines of gawk. Every script fits on one screen. The whole system reads
in an afternoon, and comes close to its industrial cousins at a vanishing
fraction of the cost. The method that produced it is one sentence long:
"good — now write it smaller."

Behind the stunt sits a new perspective on where scripting belongs. The old
view: scripts are for early prototyping, and then the real system replaces
them. The new view: scripting is the beginning *and* the end. Begin with
small scripts, to understand the issue. Move to the middle — many languages,
many tools, as much compute as the question deserves — to explore the
options. Then return, and close with something as simple as usefully
possible. The script at the end is not the prototype. It is the
understanding, written down. And that suggests a standard we will defend
throughout: no result is understood until it can be made simpler, and its
parts ranked from most important to least.

Why does this matter? Because we all do the same things with data, every
day. We classify rows. We find similar examples. We rank options. We score
text. And for each of these tasks, we reach for the same giant stacks:
scikit-learn, pytorch, a hosted LLM. Mostly, this works. But look at the
bill. Those stacks import hundreds of packages and millions of lines that
nobody on your team has read, or ever will. Installs break. Results resist
audit. And now that LLMs write much of our code, the flood is worse: a
one-hour session can generate more code and more dialog than its human can
review. We run, daily, systems we cannot explain.

The core of these everyday tasks is small. Most of what ships around them is
scaffolding, not substance — ceremony, not content. We want the content. If
you refactor until clear — and keep refactoring — naive Bayes is twenty
lines. Nearest neighbor is thirty. Better still, LLMs respond well to that
one simple prompt. Asked for less, they deliver more.

What follows explains the method, the history behind it, ten arguments for
it — and, in fairness, when you should not use it.

## A note on names: awk and gawk

Awk is the language, born at Bell Labs in 1977 and named for its authors:
Aho, Weinberger, and Kernighan. Gawk is the GNU implementation — the one
most widely installed today, and the one this repo uses. Arnold Robbins has
maintained gawk since 1993: three decades of stewardship that kept a 1970s
language alive, portable, and quietly everywhere. Asked about his design
philosophy in a 2024 interview, Robbins offered a borrowed motto that this
repo takes as its own: "Elegance is power cloaked in simplicity." In this
document, "awk" names the language and "gawk" names the tool; the mindset is
the same.

## The gawk mindset

Gawk demands brief scripts. If your ideas are not clear, the gawk will be a
mess. So the rule of gawk is: refactor until clear.

Years of gawk coding teach an "I can build that" mentality. You consume your
own tools. For a while, this author got lost in the canon of optimization and
active learning research. Then came the experiments. The experiments found
many shortcuts that the literature had missed.

The mindset has several parts:

**Constraint is a razor.** Gawk has no libraries and no imports. Every idea
costs its true size, in lines. You cannot hide confusion behind an install
command. If an algorithm does not fit in forty lines, you do not understand
it yet. Gawk makes that visible, fast.

**Representation comes before algorithm.** Gawk gives you strings, numbers,
and hash arrays. Nothing else. So you must hunt for the smallest data
representation first. Once the representation is right, the algorithm often
collapses into a few pattern-action rules. See `bundle/gawk/nb.awk`: the
whole naive Bayes classifier is one nested count table and twenty lines.

**Programs are stream rules.** Pattern-action is the Unix mindset. Data flows
past; code reacts. Tools compose through pipes, not APIs. Each script does
one job, and `make` glues them together. The architecture emerges from the
pipeline, not from a class diagram.

**Pipelines have replaceable parts.** Each stage is a part you can swap. Mix
and match. Is one part too slow? Then replace it — with, say, some
super-optimized C. But do not do that first. Try the simple part first,
measure, and replace only what the measurements condemn. Most parts are never
the bottleneck, so most parts stay simple.

**Rewrite beats maintain.** A thirty-line script is disposable. It is cheaper
to rewrite it than to patch it. This kills any sunk-cost attachment to old
code. The ideas live in your head, not in the codebase.

**Small code is auditable code.** You can check correctness by reading, not
only by testing. This matters for science. A reviewer can verify the entire
method. No one can verify "see our 50,000-line repo".

## Some history

The small-tool mindset has a birth certificate. In a Bell Labs memo dated
October 11, 1964, Doug McIlroy wrote:

> "We should have some ways of coupling programs like garden hose — screw in
> another segment when it becomes necessary to massage data in another way."

That memo became the Unix pipe. McIlroy later compressed the whole philosophy
into three rules: write programs that do one thing and do it well; write
programs to work together; write programs to handle text streams, because
that is a universal interface.

Twenty years later, the mindset won a famous duel. In 1986, Jon Bentley's
"Programming Pearls" column asked Donald Knuth to demonstrate literate
programming. The task: print the k most common words in a file. Knuth
delivered a masterpiece — some ten pages of beautifully documented Pascal,
built around a custom trie. McIlroy, the invited reviewer, praised the
artistry. Then he did the whole job in six lines:

```sh
tr -cs A-Za-z '\n' | tr A-Z a-z | sort | uniq -c | sort -rn | sed ${1}q
```

The monolith was art. The pipeline was engineering. This repo sides with the
pipeline.

And "AI in gawk" is not new either. In 1996, Ronald Loui reported that his
undergraduate AI class wrote its best, most consistent work in gawk — better
than the work done in C, C++, or LISP. His reasons still hold. AI programming
is exploratory: today's code is rethought and junkheaped tomorrow, so the
language must make rewrites cheap. Gawk, like LISP, offers one uniform data
structure (the associative array) and trivial syntax, so simple blocks
compose into complex approaches. And AI programmers should "want minds, not
insects": maximize the content of the program, not the efficiency of its
execution. Loui's conclusion was blunt: "Listen to people who program, not
to people who want to tell you how to program."

Other veterans agree. Kernighan said the language gives the "most bang for
the buck" of any language: learnable in an hour, with typical programs just
a few lines.
Robbins and Beebe confessed in *Classic Shell Scripting*: "We like it. A
lot." — and noted that when they rewrote a gawk program in C or C++, the
result was usually much longer, and much harder to debug.

## Why small? Ten arguments

### 1. It works

All this code was about four hours of work. Unlike standard LLM sessions, all
the generated code was short and easy to browse. The prompting was
straightforward. The result runs. Small is not a handicap; small is how it
got done at all.

It also measures up. Every tool here was checked against the library a
working analyst would otherwise reach for — same files, same splits, same
scoring. On ten MOOT classification files (twenty shuffles, 50:50
train:test), naive Bayes over discretized numbers averages 79.6% accuracy
against LightGBM's 84.3%; the gawk tool is best or tied on five files of ten,
LightGBM on nine; and the whole gawk experiment finishes in 26 seconds
against 439. On text with rare classes (four files, roughly 1% "yes"), tf-idf
feeding complement naive Bayes averages 81.7% macro recall against a
class-balanced LinearSVC's 65.0, and wins on all four files — though here the
SVM is the quicker experiment, 154 seconds against 285. On optimization under
a label budget (ten files, fifty shuffles), labelling 25 rows and checking
the five best-ranked returns a row in the best 5.8% of the space, where
checking five rows at random returns 16.3%.

Read those numbers honestly. LightGBM is the better classifier, and it is
running at its defaults — defaults built for data far larger than these
files. Ask it to fit 46 training rows and `min_child_samples=20` has it
building a hundred two-leaf stumps, because no deeper split is legal. Tune it
for small data and it pulls further ahead. So the claim is not that gawk
wins. The claim is the exchange rate: a few points of accuracy, against two
orders of magnitude less code to install, read, and trust.

### 2. The straw man (good science)

The methodological precedent here is much older than this work. In his 1995
book *Empirical Methods for Artificial Intelligence*, Cohen argued that
supposedly sophisticated methods should always be benchmarked against
seemingly stupider ones. He called this the "straw man" approach to
scientific verification. We can attest: whenever we have checked a
sophisticated method against a simpler one, there was something useful in the
simpler. More often than not, a year later, we had switched to the simpler
approach.

### 3. Repetition in miniature (also good science)

To repeat a result with a simpler apparatus is not mere engineering. It is
good science. A reproduction that strips a method to its essentials tests
which parts were load-bearing and which were ritual. Each script here is such
a reproduction. When twenty lines recover the published result, the other ten
thousand lines of the reference implementation are shown to be scaffolding —
and the idea itself stands clearer.

### 4. Code does not transfer; principles do (the Cartwright argument)

The philosopher Nancy Cartwright, examining evidence-based reasoning, issued
a famous warning: what worked *there* may not work *here*. The pathway from
there to here is never verbatim reuse. It is abstraction — strip the prior
work down to its essential features — followed by adaptation of those
features to the new domain. On this view, we never really reuse code. At
best, we reuse the principles behind the code. And that puts a demand on the
code itself: it must *demonstrate* its principles, visibly, so that others
can lift them out and carry them elsewhere. Twenty transparent lines
demonstrate a principle. A framework buries it.

(For those who doubt this view: note that software engineering keeps
relearning it. The field is so diverse an enterprise that solutions from
over there routinely need extensive adaptation before they work over here —
a lesson documented at length in the literature on local versus global
models.)

### 5. Better prompting

This exercise taught us something about prompting. Our usual experience of
LLM-assisted coding is one of being overwhelmed: by the volume of dialog
about the work, and by the volume of code that is the work. Here we ran the
session differently. When something did not make sense, we said "please
clarify", and a shorter, clearer script came back. Once something ran, the
next prompt was "good — now write it smaller". Iterated, that one instruction
changed the output entirely. The code stayed small enough to read in full.
That kept the human genuinely in the loop. That, in turn, made every later
prompt better informed. Brevity is not just a property of the product. It is
a discipline that improves the process.

### 6. Teaching the next generation

Watch a modern AI coding assistant at work. You will see it lean, constantly,
on small Unix tools. A prompt becomes a pipeline of grep, sed, sort, gawk, and
make. The most capable programmers on the planet — human or otherwise — have
converged on the same conclusion: the power lies in a flexible kit of small
tools, composed in endlessly varied ways. If that is how software is now
built, then students need worked examples of the style. They need
explainable, inspectable demonstrations of how AI itself can be assembled
from a handful of small scripts. This repo offers such examples.

(An aside, for those who think coding is over: read Bainbridge's "Ironies of
Automation" (1983) and reflect. For four decades we have known that when
humans merely supervise automation, they still need the skills to monitor it
and to step in when it fails. Supervision demands *more* expertise, not less.
The automation handles the easy cases and hands humans only the hard ones.
The central educational challenge in computer science right now is how to
give students those skills. Small, fully readable tools are one answer. A
student who has built naive Bayes in twenty lines can supervise a system
that uses one.)

More humility here, from classroom experience. When data structures get
complicated, this author tests ideas in Lua or Python, not gawk. And when
students receive these tools, they usually prefer the Python ports to the
ggawk originals. No matter. A useful teaching strategy: hand students the
working gawk, then ask them to port it to their young language of choice.
The port forces a line-by-line understanding that no lecture achieves.
Years later, students come back and say they have forgotten everything
else they were ever told — but darn, that little gawk tool is useful.

### 7. The attack surface

Every dependency is an attack vector. A modern data-science stack imports
hundreds of packages. Strangers maintain each one. Each one is a possible
channel for a supply-chain attack; see the 2024 xz-utils backdoor
(CVE-2024-3094). A few hundred lines of dependency-free code can be audited
completely, in an afternoon. A transitive dependency tree of millions of
lines cannot. For safety-critical or reproducible work, the auditable
artifact is the trustworthy one.

Measure the tree you are trusting. On the machine that ran these
experiments, the installed numpy, scipy, scikit-learn and LightGBM ship
995,456 non-blank lines of Python, Cython and C between them — and that count
omits LightGBM's own engine, which arrives as a 4.7 MB compiled library whose
source (39,468 lines, plus 126,599 more vendored from other projects) is not
in the wheel at all. The eleven scripts in `bundle/gawk` come to 223 lines,
170 of them code, and depend on nothing but gawk.

### 8. The Richard Hipp argument (usability)

Hipp wrote SQLite. He avoids dependencies and builds his own tools: his own
version control, his own editor, his own test harness. His claim: tools built
by their own users fit their users. Our experience agrees. When analysts
consume their own tools, friction is felt at once and removed quickly.
Features that nobody needs are never written. Before you import a solution,
first ask how much of the problem survives contact with fifty lines of your
own code.

### 9. Energy

The computational cost of modern AI is measured in megawatts, and the cost is
paid on every run, forever. A method that fits in kilobytes and runs in
milliseconds on one core is not just cheaper. At scale, it is the
environmentally responsible baseline. Before you reach for a billion
parameters, check what a few hundred lines can do.

### 10. Fun

It is fun. To find the smaller version of a thing is one of programming's
oldest pleasures. It is the instinct behind Ken Thompson's remark that one of
his most productive days was throwing away a thousand lines of code.
Small-tool programming turns deletion into progress, and progress into play.

## Refactoring to simplicity

One more framing, and maybe the best one. This is not a war on complexity.
Complexity has a job. The job is to find the simplicity on the far side.

So: burn down your CPUs. Run the largest, most intricate analysis you can
afford. But when you are done, deliver two things, not one. First, the
state-of-the-art result. Second, the tiny baseline that gets nearly the same
answer for a tiny fraction of the resources. The big run buys the knowledge;
the small run proves you have it.

Declare it as a standard: we do not understand a result until we know how to
make it simpler — until we can rank its parts from most important to least,
and say out loud which ones were doing the work. A method you cannot shrink
is a method you do not yet understand. Simplicity is not where analysis
starts. It is where understanding arrives.

## When not to do this

Some humility is in order. Tiny tools are not always the answer.

First, the obvious objection: no, we will not code artificial general
intelligence in gawk. But we do not want to. What we want to do — what
almost all working analysts want to do — is a thousand tasks smaller than
AGI: classify this, rank that, find the rows like these. For that thousand,
small tools serve. Let AGI keep its data centers; we will keep our one-liners.

Do not do this when the task is genuinely hard perception: vision, speech,
open-ended language generation. Twenty lines of gawk will not beat a
transformer at reading an X-ray. Use the big model; keep the tiny tool as the
baseline that proves the big model earns its cost.

Do not do this when the data is huge and the deadline is real. Gawk is a
single-core text engine. When measurements show a stage is the bottleneck,
replace that stage with optimized code — that is the pipeline working as
designed, not a defeat.

Do not do this when the data is deeply nested. Gawk offers strings, numbers,
and hash arrays, and nothing else. For flat tables and streams, that is a
feature. For richly nested records, object graphs, or recursive documents,
it is a fight you will lose. Use a language with real data structures.

Do not do this for deep numerics. Decades of hard-won engineering live inside
LAPACK and friends. Rewriting SVD in gawk teaches you SVD; it does not improve
on LAPACK.

Do not do this alone against a regulated or contractual stack. If the
customer requires a supported, certified library, use it.

In short: tiny tools are for baselines, teaching, auditing, prototyping, and
for all the everyday tasks where the core really is small. That covers more
ground than most people think — but not all of it.

## References

- M.D. McIlroy, Bell Labs internal memo, October 11, 1964. Reproduced in
  P. Salus, *A Quarter Century of UNIX*, Addison-Wesley, 1994.
- J. Bentley, D. Knuth, M.D. McIlroy, "Programming Pearls: A Literate
  Program," *CACM* 29(6):471–483, June 1986.
- R.P. Loui, "Why GAWK for AI?," *ACM SIGPLAN Notices* 31(8):8–9, 1996.
- A. Robbins, N. Beebe, *Classic Shell Scripting*, O'Reilly, 2005.
- awk.info advocacy pages (archived):
  https://web.archive.org/web/20110721185328/http://awk.info/?advocacy
- R. Farrow, "Interview with Arnold Robbins," USENIX *;login:*, June 27, 2024.
  https://www.usenix.org/publications/loginonline/interview-arnold-robbins
- G. Socher, "AWK one-liner collection," tuxgraphics.org.
  http://tuxgraphics.org/~guido/scripts/awk-one-liner.html
- N. Cartwright, J. Hardie, *Evidence-Based Policy: A Practical Guide to
  Doing It Better*, Oxford University Press, 2012.
- T. Menzies, A. Butcher, D. Cok, et al., "Local versus Global Lessons for
  Defect Prediction and Effort Estimation," *IEEE TSE* 39(6):822-834, 2013.
- P.R. Cohen, *Empirical Methods for Artificial Intelligence*, MIT Press, 1995.
- L. Bainbridge, "Ironies of Automation," *Automatica* 19(6):775–779, 1983.
- CVE-2024-3094, the xz-utils supply-chain backdoor, 2024.
- R. Schwartz, J. Dodge, N.A. Smith, O. Etzioni, "Green AI," *CACM* 63(12), 2020.
- E. Strubell, A. Ganesh, A. McCallum, "Energy and Policy Considerations for
  Deep Learning in NLP," ACL 2019.
- K. Thompson (attributed), "One of my most productive days was throwing away
  1,000 lines of code."
- D.R. Hipp on self-built tools: The Changelog, episode 201, 2016.

## Usage

```sh
make help     # show all rules
make slides   # slides/*.html -> slide*.png
make fig      # rerun experiments (needs MOOT data)
```

## Appendix A: gawk in thirty minutes

A gawk program is a list of rules. Each rule is `pattern { action }`. Gawk
reads input one line at a time. For each line, it runs every action whose
pattern matches. That is the whole model.

**Fields.** Each line splits into fields on `FS` (set it with `-F,` or in a
`BEGIN` block). `$1` is the first field, `$NF` the last, `NF` the count,
`NR` the line number, `$0` the whole line.

**Patterns.** `BEGIN` runs before input; `END` after. `/regexp/` matches the
line; `$1 ~ /x/` matches one field; `NR > 1` skips a header; `/a/,/b/` is a
range. No pattern means "every line".

**Arrays.** One data structure: the associative array. `n[$1]++` counts.
`for (k in n)` iterates. Arrays of arrays nest: `f[h][c][v]++`. That one
idiom is most of machine learning.

**Functions.** Extra parameters are locals — list them after the real
arguments, behind extra spaces.

Now read a real program. Here is the heart of `bundle/gawk/nb.awk`, a
complete naive Bayes trainer:

```awk
/^train,/ { train(f) }

function train(f,   c) {
  rows++; for (c=2; c<=NF; c++) if ($c != "?") f[$NF][c][$c]++ }
```

One rule, one function, one nested count table. Classification is just
reading those counts back with Bayes' rule — fifteen more lines. You now
know enough to read every script in this repo.

## Appendix B: one-liners (the next thirty minutes)

A survey, mostly after Guido Socher's classic collection (tuxgraphics.org).
Teach these after the thirty-minute intro; together they make a one-hour
class.

Start with the coolest gawk program of all time. It is one character long:

```sh
gawk '1' f                                   # print every line
```

The pattern is `1`. One is always true. A true pattern with no action runs
the default action, which is print. The whole language is in that joke:
patterns fire, actions follow, and the defaults do the boring parts for you.

Now the working set:

```sh
gawk -F, '{print $2}' f.csv                  # cut a column
gawk -F, '$1 ~ /x/ {print $2}' f.csv         # column, from matching rows only
gawk '/start/,/stop/' f                      # print a section of a file
gawk '/re/ {print; exit}' f                  # first match only
gawk '/re/ {last=$0} END {print last}' f     # last match only
gawk '/re/ {i=3} i-- > 0' f                  # match plus next 2 lines (grep -A 2)
gawk '{s += $1} END {print s/NR}' f          # mean of column one
gawk '{s += $NF} END {print s}' f            # sum the last column
gawk '{n[$1]++} END {for (k in n) print n[k], k}' f   # group and count
gawk 'BEGIN {srand()} {n[rand()]=$0} END {for (k in n) print n[k]}' f  # shuffle
```

And the coolest of them all — the self-locating field. When output formats
drift, do not count columns; find the label and take the field after it:

```sh
ip route get 1.1.1.1 | gawk '{for (i=1; i<=NF; i++) if ($i=="src") print $(i+1)}'
```

Six of these eight lines are, recognizably, the seeds of the scripts in
`bundle/gawk/`: group-and-count grows into naive Bayes; mean-of-column grows
into discretization; the section printer grows into a data loader. One-liners
are not toys. They are larvae.
