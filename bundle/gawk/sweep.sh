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
G="gawk -f"

if [ "${1:-}" = "--all" ]; then
  files=$(ls "$C"/*.csv); seeds="1 2 3"
else
  files=$(ls "$C"/soybean.csv "$C"/diabetes.csv "$C"/arrhythmia.csv \
             "$C"/page.blocks.csv "$C"/glass.csv); seeds="1 2 3 4 5"
fi

for f in $files; do
  b=$(basename "$f" .csv)
  for s in $seeds; do
    $G shuf.awk Seed="$s" "$f" > /tmp/sweep.$$ 
    printf "%-22s %s shuf %s\n" "$b" "$s" "$(md5 -q /tmp/sweep.$$)"
    printf "%-22s %s nb1  %s\n" "$b" "$s" \
      "$($G nb1.awk /tmp/sweep.$$ | md5 -q)"
    printf "%-22s %s bins %s\n" "$b" "$s" \
      "$($G bins.awk /tmp/sweep.$$ | $G nb.awk | md5 -q)"
  done
done
rm -f /tmp/sweep.$$
