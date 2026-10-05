#!/bin/zsh
# C1 crib probe (unit C, crib section L4): is `Syntax.print` parse-stable on
# the two M0 inputs? One JavaScript build of W/c1-print-probe.bend (copied to
# bend2/tests/ for the import paths, removed at exit). For each input:
# T1 = print(parse(src)), T2 = print(parse(T1)), text fixpoint T1 == T2, and
# the Decl equality of parse(src) and parse(T1) (Same.declarations).
# Output: one PROBE line for each input, then C1-CRIB-OK or C1-CRIB-FAIL.
set -u
ROOT=/Users/oobi/Documents/mechanism-lang-rust-m0
W=/Users/oobi/Documents/mech-rust
BEND=${BEND:-$HOME/.bend/bin/bend}
WORK=$(mktemp -d ${TMPDIR:-/tmp}/c1-crib.XXXXXX)
COPY=$ROOT/bend2/tests/zz_c1_print_probe.bend
trap 'rm -rf $WORK; rm -f $COPY' EXIT
JS=$WORK/x.js

cp $W/c1-print-probe.bend $COPY
if ! $BEND $COPY -o $JS > $WORK/build.log 2>&1; then
  print -r -- "BUILD-FAIL"
  head -30 $WORK/build.log | cut -c1-200
  print -r -- "C1-CRIB-FAIL"
  exit 1
fi

# Stack rule of dev/rust-out-diff-exec.sh (:20, :23).
ulimit -s "$(ulimit -Hs)"
run() { node --stack-size=16384 $JS "$@" < /dev/null; }

rc=0
for f in $ROOT/prelude/init.mech $ROOT/prelude/mechanism/second-price.mech; do
  src="$(cat $f; print -rn -- x)"
  run t1 "${src%x}" > $WORK/t1 2> $WORK/err
  t1="$(cat $WORK/t1; print -rn -- x)"
  run t1 "${t1%x}" > $WORK/t2 2>> $WORK/err
  same="$(run same "${src%x}" 2>> $WORK/err | head -1 | cut -c1-160)"
  decls=$(rg -c '^(def|mu|axiom|poly|specialize)\b' $WORK/t1)
  fix=NO
  if [[ -s $WORK/t1 ]] && cmp -s $WORK/t1 $WORK/t2; then fix=YES; fi
  print -r -- "PROBE ${f:t} decls=${decls:-0} t1_bytes=$(wc -c < $WORK/t1 | tr -d ' ') fixpoint=$fix decl_equal=$same"
  if [[ $fix != YES || $same != SAME ]]; then
    rc=1
    head -3 $WORK/t1 | cut -c1-200
    diff $WORK/t1 $WORK/t2 | head -6 | cut -c1-200
    head -3 $WORK/err | cut -c1-200
  fi
done

if (( rc == 0 )); then
  print -r -- "C1-CRIB-OK"
else
  print -r -- "C1-CRIB-FAIL"
fi
exit $rc
