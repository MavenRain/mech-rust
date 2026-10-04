#!/bin/zsh
# B2 classify check. Builds the emit driver to JavaScript and makes the
# classify table of init.mech + second-price.mech. Each `fn` line must be
# equal to the signature of the same function in the golden crate.
# A signature that rustfmt puts on more than one line is put back on one line.
# `table` as the first argument prints the full table.
set -u
D=/Users/oobi/Documents/mechanism-lang-rust-m0
W=/Users/oobi/Documents/mech-rust-m0
O=${TMPDIR:-/tmp}/mrb2
mkdir -p $O
if ! ~/.bend/bin/bend $D/bend2/tests/rust_emit.bend -o $O/re.js > $O/build.log 2>&1; then
  print -r -- "B2-CLASSIFY-FAIL build"
  head -n 12 $O/build.log | cut -c1-200
  exit 1
fi
node $O/re.js classify $D/prelude/init.mech $D/prelude/mechanism/second-price.mech > $O/table.txt 2> $O/run.log
if [[ ${1:-} == table ]]; then cat $O/table.txt; head -n 5 $O/run.log | cut -c1-200; fi
rg -o 'pub fn .*' $O/table.txt | sort > $O/got.txt
{ symx $W/target-crate/src/init.rs; symx $W/target-crate/src/second_price.rs } | rg -o 'pub fn .*' | rg -v 'fn mech_unit\(' | sd -F '( ' '(' | sd -F ', )' ')' | sort > $O/want.txt
if diff $O/want.txt $O/got.txt > $O/diff.txt; then
  print -r -- "B2-CLASSIFY-OK fn signatures: $(wc -l < $O/got.txt | tr -d ' ') equal"
else
  print -r -- "B2-CLASSIFY-FAIL signatures"
  cat $O/diff.txt
  exit 1
fi
# Negative fixture: one refused definition and one name collision.
node $O/re.js classify $D/prelude/init.mech $D/test/rust/emit/neg_classify.mech > $O/neg.txt 2>> $O/run.log
if rg -q -F 'refused negPostulate: a postulate in the runtime' $O/neg.txt && rg -q -F 'refused: name collision (D7): neg_twin' $O/neg.txt; then
  print -r -- "B2-NEGATIVE-OK refused line + collision line"
else
  print -r -- "B2-NEGATIVE-FAIL"
  tail -n 6 $O/neg.txt | cut -c1-200
  exit 1
fi
