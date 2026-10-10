#!/bin/bash
# usage: ./run_tests.sh AWK_OR_PORT_RUNNER outdir
# RUN is a command prefix: e.g. "gawk -f awk/" or "lua lua/" or "node js/" ...
# each tool is invoked as:  $RUN<name><ext> args...
R="$1"; X="$2"; O="$3"; mkdir -p "$O"; d=data
T=$(( ($(wc -l < $d/diabetes_shuf.csv) - 1) / 2 ))
${R}nb$X $d/soybean_noheader.csv | ${R}abcd$X                                        > $O/01_base.txt
${R}disc$X $d/diabetes_shuf.csv $d/diabetes_shuf.csv                                > $O/02_disc.csv
tail -n +2 $O/02_disc.csv | ${R}nb$X T=$T W=$T                                      > $O/03_nbdisc.txt
tail -n +2 $O/02_disc.csv | ${R}some$X N=100 T=$T | ${R}nb$X T=100 W=100             > $O/04_scarce.txt
tail -n +2 $O/02_disc.csv > $O/d.csv; ${R}select$X T=$T $O/d.csv $O/d.csv           > $O/05_select.csv
${R}nb$X T=$T W=$T $O/05_select.csv                                                 > $O/06_nbselect.txt
T=$(( ($(wc -l < $d/autompg_shuf.csv) - 1) / 2 ))
${R}disc$X $d/autompg_shuf.csv $d/autompg_shuf.csv | tail -n +2                      > $O/r.csv
${R}knn$X T=$T ALL=1 $O/r.csv <(tail -n +$((T+1)) $O/r.csv)                          > $O/07_knn.txt
${R}ybin$X T=$T $O/r.csv $O/r.csv                                                   > $O/08_ybin.csv
${R}nb$X T=$T W=$T $O/08_ybin.csv | ${R}knn$X T=$T $O/r.csv -                        > $O/09_nbknn.txt
T=$(( ($(wc -l < $d/kitchenham_shuf.tsv) - 1) / 2 ))
${R}tfidf$X $d/kitchenham_shuf.tsv $d/kitchenham_shuf.tsv                           > $O/10_tfidf.csv
${R}twcnb$X T=$T $O/10_tfidf.csv | ${R}abcd$X                                        > $O/11_twcnb.txt
${R}shuffle$X seed=1 $d/diabetes.csv | sort | md5sum                                > $O/12_shuffle_sorted_md5.txt
head -1 $d/diabetes.csv | md5sum                                                   >> $O/12_shuffle_sorted_md5.txt
${R}shuffle$X seed=1 $d/diabetes.csv | head -1 | md5sum                             >> $O/12_shuffle_sorted_md5.txt
