# usage: gawk -f some.awk N=100 T=n f   (f is pre-shuffled)
# keep N labelled rows, then the test rows (> T)
NR <= N || NR > T
