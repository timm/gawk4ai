#!/bin/bash
# usage: ./run_tests2.sh RUNNER EXT OUTDIR   (tests for knnr, tree, ydist, rank)
R="$1"; X="$2"; O="$3"; mkdir -p "$O"; d=data
${R}ydist$X $d/ssk_shuf.csv $d/ssk_shuf.csv                                      > $O/21_ydist.csv
T=$(( ($(wc -l < $d/autompg_raw_shuf.csv) - 1) / 2 ))
${R}knnr$X T=$T $d/autompg_raw_shuf.csv                                          > $O/22_knnr.txt
gawk -f awk/disc.awk $d/autompg_raw_shuf.csv $d/autompg_raw_shuf.csv | tail -n +2 > $O/a.csv
${R}tree$X T=$T $O/a.csv                                                         > $O/23_tree.txt
${R}tree$X T=$T M=16 $O/a.csv                                                    > $O/24_tree16.txt
${R}rank$X $O/22_knnr.txt                                                        > $O/25_rank.txt
${R}rank$X C=20 $O/23_tree.txt                                                   > $O/26_rank20.txt
T=$(( ($(wc -l < $O/21_ydist.csv) - 1) / 2 ))
(head -1 $O/21_ydist.csv; tail -n +2 $O/21_ydist.csv | ${R}some$X N=25 T=$T) | \
  ${R}knnr$X T=25 | ${R}rank$X                                                   > $O/27_pipeline.txt
