#!/bin/zsh
# B1 sample check: build the emit driver to JavaScript, print both samples,
# and compare each emitted item with the golden crate (W/target-crate).
set -u
D=/Users/oobi/Documents/mechanism-lang-rust-m0
W=/Users/oobi/Documents/mech-rust-m0
O=${TMPDIR:-/tmp}/mrb1
mkdir -p $O
if ! ~/.bend/bin/bend $D/bend2/tests/rust_emit.bend -o $O/re.js > $O/build.log 2>&1; then
  print -r -- "B1-SAMPLE-FAIL build"
  head -n 14 $O/build.log
  exit 1
fi
node $O/re.js sample init > $O/init.rs
node $O/re.js sample second > $O/second.rs
fail=0
python3 $W/cmp_sample.py $W/target-crate/src/init.rs $O/init.rs || fail=1
python3 $W/cmp_sample.py $W/target-crate/src/second_price.rs $O/second.rs || fail=1
rustfmt --check --edition 2021 $O/init.rs $O/second.rs > /dev/null 2>&1 || { print -r -- "not rustfmt-clean"; fail=1 }
if (( fail == 0 )); then
  print -r -- "B1-SAMPLE-OK"
else
  print -r -- "B1-SAMPLE-FAIL"
  exit 1
fi
