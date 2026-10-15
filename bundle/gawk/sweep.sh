#!/usr/bin/env bash
# sweep.sh: fingerprint what the pipelines print, so a refactor can be
# checked by diff instead of by reading.
#
#   ./sweep.sh > before.txt     # fingerprint the code as it stands
#   ...edit...
#   ./sweep.sh > after.txt
#   diff before.txt after.txt   # empty = behaviour did not move
#
# usage: sweep.sh [--all]   quick = 5 files x 5 seeds (seconds)
#                           --all = every file x 3 seeds (minutes)
set -eu
cd "$(dirname "$0")"
C=${MOOT:-$HOME/tmp/moot}/classify
O=${MOOT:-$HOME/tmp/moot}/optimize
G="gawk -f"
sum() { command -v md5sum > /dev/null && md5sum "$1" | cut -d" " -f1 \
                                      || md5 -q "$1"; }

if [ "${1:-}" = "--all" ]; then
  files=$(ls "$C"/*.csv); opt=$(ls "$O"/*/*.csv); seeds="1 2 3"
else
  files=$(ls "$C"/soybean.csv "$C"/diabetes.csv "$C"/arrhythmia.csv \
             "$C"/page.blocks.csv "$C"/glass.csv)
  opt=$(ls "$O"/misc/auto93.csv "$O"/config/SS-D.csv "$O"/process/nasa93dem.csv)
  seeds="1 2 3 4 5"
fi

for f in $files; do
  b=$(basename "$f" .csv)
  for s in $seeds; do
    $G shuf.awk Seed="$s" "$f" > /tmp/sweep.$$ 
    printf "%-22s %s shuf %s\n" "$b" "$s" "$(sum /tmp/sweep.$$)"
    $G bins.awk /tmp/sweep.$$ | $G nb.awk > /tmp/sweep2.$$
    test -s /tmp/sweep2.$$ || echo "EMPTY OUTPUT: $b seed $s" >&2
    printf "%-22s %s nb   %s\n" "$b" "$s" "$(sum /tmp/sweep2.$$)"
  done
done

for f in $opt; do                      # the other pipeline: shuf | rank
  b=$(basename "$f" .csv)
  for s in $seeds; do
    printf "%-22s %s rank %s\n" "$b" "$s" \
      "$($G shuf.awk Seed="$s" "$f" | $G rank.awk K=32 C=5)"
  done
done
rm -f /tmp/sweep.$$ /tmp/sweep2.$$
