#!/bin/zsh
# A3 round-trip runner: rustfmt --check, then print(parse(f)) == f.
R=/Users/oobi/Documents/mechanism-lang-rust-m0
D=$R/bend2/tests/rust_frontend.bend
O=${TMPDIR:-/tmp}/a3-out
mkdir -p $O
pass=0; fail=0
for f in ${@:-$R/test/rust/parse/*.rs}; do
  b=$(basename $f .rs)
  rustfmt --check --edition 2021 $f >/dev/null 2>&1 || { echo "RUSTFMT-DIRTY $b"; fail=$((fail+1)); continue; }
  ~/.bend/bin/bend $D print "$(cat $f)" > $O/$b.out 2>$O/$b.err
  print -rn -- "$(cat $f)" > $O/$b.want
  print -rn -- "$(cat $O/$b.out)" > $O/$b.got
  if cmp -s $O/$b.want $O/$b.got; then echo "PASS $b"; pass=$((pass+1)); else echo "FAIL $b"; diff $O/$b.want $O/$b.got | head -20; fail=$((fail+1)); fi
done
echo "pass=$pass fail=$fail"
