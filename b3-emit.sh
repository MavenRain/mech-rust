#!/bin/zsh
# B3 emit check. Builds the emit driver to JavaScript, emits the module of
# init.mech and the module of second-price.mech (in the globals of init.mech),
# and compares each module byte for byte with the golden crate. Each emitted
# module must also be clean for `rustfmt --check`.
# The first argument is the number of diff lines to print (default 14).
# `nobuild` as the second argument uses the last build.
set -u
D=/Users/oobi/Documents/mechanism-lang-rust-m0
W=/Users/oobi/Documents/mech-rust
O=${TMPDIR:-/tmp}/mrb3
mkdir -p $O
if [[ ${2:-} != nobuild ]]; then
  if ! ~/.bend/bin/bend $D/bend2/tests/rust_emit.bend -o $O/re.js > $O/build.log 2>&1; then
    print -r -- "B3-EMIT-FAIL build"
    head -n 14 $O/build.log | cut -c1-220
    exit 1
  fi
fi
cp $D/prelude/init.mech $D/prelude/mechanism/second-price.mech $O/
cd -q $O
node re.js emit init.mech > init.rs 2> init.err
node re.js emit init.mech second-price.mech > second_price.rs 2> second_price.err
rc=0
for m in init second_price; do
  if diff $W/target-crate/src/$m.rs $m.rs > $m.diff; then
    print -r -- "B3-EMIT-OK $m: byte-equal"
    rustfmt --check --edition 2021 $m.rs > $m.fmt 2>&1 || { print -r -- "B3-FMT-FAIL $m"; rc=1 }
  else
    print -r -- "B3-EMIT-FAIL $m: $(wc -l < $m.diff | tr -d ' ') diff lines, $(wc -l < $m.rs | tr -d ' ') lines out"
    head -n 6 $m.err | cut -c1-220
    head -n ${1:-14} $m.diff | cut -c1-220
    rc=1
  fi
done
# Negative fixture: a refused definition gives no module text and exit code 65.
node re.js emit init.mech $D/test/rust/emit/neg_classify.mech > neg.rs 2> neg.err
nrc=$?
if [[ $nrc == 65 && ! -s neg.rs ]] && rg -q -F 'refused negPostulate: a postulate in the runtime' neg.err; then
  print -r -- "B3-NEGATIVE-OK refused line, exit code 65, no module text"
else
  print -r -- "B3-NEGATIVE-FAIL rc=$nrc"
  head -n 6 neg.err | cut -c1-220
  rc=1
fi
exit $rc
