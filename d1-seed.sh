#!/bin/zsh
# D1 probe (unit D, mech-rust): each seed program goes through rust-out (E)
# and rust-in (I) two times.  One PASS or FAIL line for each step.
#   RT-RUST   E(I(E(S))) is equal to E(S), file for file.
#   FIXPOINT  I(E(I(E(S)))) is equal to I(E(S)), file for file.
# RT-MECH is not here: it needs the mode `rt-mech` of the importer driver.
# The current drivers are built once per run and kept in $D1_WORK.
set -u
ROOT=/Users/oobi/Documents/mechanism-lang-rust-m0
BEND=${BEND:-$HOME/.bend/bin/bend}
SEED=$ROOT/test/rust/seed
WORK=${D1_WORK:-$TMPDIR/d1-seed}
mkdir -p $WORK
JS=$WORK/rust_import.js
RE=$WORK/rust_emit.js
ulimit -s "$(ulimit -Hs)" 2> /dev/null
$BEND $ROOT/bend2/tests/rust_import.bend -o $JS > $WORK/build-i.log 2>&1 || { print "FAIL build rust_import"; tail -n 5 $WORK/build-i.log; exit 1 }
$BEND $ROOT/bend2/tests/rust_emit.bend -o $RE > $WORK/build-e.log 2>&1 || { print "FAIL build rust_emit"; tail -n 5 $WORK/build-e.log; exit 1 }

fail=0
step() {
  if [[ $1 == 0 ]]; then
    print -r -- "PASS $2"
  else
    print -r -- "FAIL $2 ${3:-}"
    fail=1
  fi
}
emit() {
  local dir=$1 out=$2
  shift 2
  (cd -q $dir && node --stack-size=16384 $RE crate "$@" $out > $WORK/emit.out 2> $WORK/emit.err < /dev/null)
}
imp() {
  node --stack-size=16384 $JS run $1 $2 > $WORK/imp.out 2> $WORK/imp.err < /dev/null
}

for p in $SEED/*(/); do
  n=${p:t}
  files=(${(f)"$(< $p/MANIFEST)"})
  rm -rf $WORK/$n
  mkdir -p $WORK/$n
  emit $p $WORK/$n/e1 $files
  step $? "EMIT $n" "$(head -c 300 $WORK/emit.err $WORK/emit.out)"
  imp $WORK/$n/e1 $WORK/$n/i1
  step $? "IMPORT $n" "$(head -c 300 $WORK/imp.err)"
  if [[ ! -s $WORK/$n/i1/MANIFEST ]]; then
    step 1 "MANIFEST $n" "import produced no nonempty manifest"
    continue
  fi
  f2=(${(f)"$(< $WORK/$n/i1/MANIFEST)"})
  emit $WORK/$n/i1 $WORK/$n/e2 $f2
  step $? "EMIT2 $n" "$(head -c 300 $WORK/emit.err)"
  diff -r $WORK/$n/e1 $WORK/$n/e2 > $WORK/$n/rt-rust.diff 2>&1
  step $? "RT-RUST $n" "$(head -n 6 $WORK/$n/rt-rust.diff)"
  imp $WORK/$n/e2 $WORK/$n/i2
  step $? "IMPORT2 $n" "$(head -c 300 $WORK/imp.err)"
  diff -r $WORK/$n/i1 $WORK/$n/i2 > $WORK/$n/fix.diff 2>&1
  step $? "FIXPOINT $n" "$(head -n 6 $WORK/$n/fix.diff)"
done
print -r -- "work=$WORK"
if (( fail == 0 )); then
  print D1-PROBE-OK
  exit 0
fi
print D1-PROBE-FAIL
exit 1
