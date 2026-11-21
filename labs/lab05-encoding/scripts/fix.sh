#!/bin/sh
# Lab 5: convert staff-broken.csv from KZ-1048 (iconv name: RK1048) to UTF-8,
# CRLF -> LF, and add a UTF-8 BOM so Excel recognises UTF-8 on double-click.
# Run from labs/lab05-encoding:  sh scripts/fix.sh
set -e
in=evidence/staff-broken.csv
out=evidence/staff-fixed.csv

iconv -f RK1048 -t UTF-8 "$in" > "$out"                  # 1. encoding
sed -i 's/\r$//' "$out"                                  # 2. CRLF -> LF
printf '\357\273\277' | cat - "$out" > tmp && mv tmp "$out"   # 3. BOM

file "$out"
