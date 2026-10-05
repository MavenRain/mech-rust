#!/bin/zsh
# C3 check: the `types` mode of the Rust importer on the golden crate, the
# "Done when" of C3 (all 22 fn lines print with no refusal), and one CD9
# refusal (a constructor of a generic family as a match scrutinee).
# The fn names must be the `fn` rows of the `resolve` mode.
# The last line is C3-TYPES-OK or C3-TYPES-FAIL.
set -u
ROOT=${ROOT:-$HOME/Documents/mechanism-lang-rust-m0}
BEND=${BEND:-$HOME/.bend/bin/bend}
WORK=$(mktemp -d ${TMPDIR:-/tmp}/c3-types.XXXXXX)
trap 'rm -rf $WORK' EXIT
JS=$WORK/rust_import.js
G=$ROOT/test/rust/emit/crate/src
ulimit -s "$(ulimit -Hs)"
if ! $BEND $ROOT/bend2/tests/rust_import.bend -o $JS > $WORK/build.log 2>&1; then
  tail -n 20 $WORK/build.log
  print BUILD-FAIL
  print C3-TYPES-FAIL
  exit 1
fi

# run <mode> <out> <lib.rs> <init.rs> <nat.rs> <second_price.rs>
# The `x` keeps the last newline of each text.
run() {
  local l i n s
  l="$(cat $3; print -rn -- x)"; i="$(cat $4; print -rn -- x)"
  n="$(cat $5; print -rn -- x)"; s="$(cat $6; print -rn -- x)"
  node --stack-size=16384 $JS $1 "${l%x}" init "${i%x}" nat "${n%x}" second_price "${s%x}" > $2 2> $WORK/err < /dev/null
}

fail=0
run types $WORK/out $G/lib.rs $G/init.rs $G/nat.rs $G/second_price.rs
run resolve $WORK/res $G/lib.rs $G/init.rs $G/nat.rs $G/second_price.rs
if ! python3 - $WORK/out $WORK/res <<'EOF'
import re, sys
out = open(sys.argv[1]).read().splitlines()
res = open(sys.argv[2]).read().splitlines()
rows, bad = [], []
for l in out:
    m = re.fullmatch(r"(\S+) (\S+) : (.+) annotated (\d+)", l)
    if m: rows.append(m.groups())
    else: bad.append(l)
fns = [tuple(l.split(" ")[i] for i in (0, 4)) for l in res if re.fullmatch(r"\S+ fn \S+ -> \S+", l)]
same = [(r[0], r[1]) for r in rows] == fns
notes = sum(int(r[3]) for r in rows)
print(f"fn-lines={len(rows)} resolve-fn-rows={len(fns)} same-names-in-order={same} annotated-total={notes}")
if bad: print("unexpected lines:", bad[:3])
sys.exit(0 if (not bad and len(rows) == 22 and same) else 1)
EOF
then
  head -n 3 $WORK/out; head -c 400 $WORK/err
  fail=1
  print "FAIL golden crate"
else
  print "MATCH golden crate"
fi

# neg <name> <expected text> <lib.rs> <init.rs> <nat.rs> <second_price.rs>
neg() {
  local o=$WORK/neg-$1
  run types $o $3 $4 $5 $6
  if rg -q -F -- "REFUSED $2" $o; then
    print "MATCH $1 ($(head -n 1 $o))"
  else
    print "FAIL $1: $(head -c 300 $o) $(head -c 300 $WORK/err)"
    fail=1
  fi
}

N=$WORK/n
mkdir -p $N
sd -F -- '    match s {' '    match MechSum::MechInl(s.clone()) {' < $G/init.rs > $N/scrut.rs
L=$(rg -n '^pub fn mech_sum_rec' $N/scrut.rs | head -n 1 | cut -d: -f1)
neg scrut "src/init.rs:$L:1: constructor of a generic family with no expected type (CD9)" $G/lib.rs $N/scrut.rs $G/nat.rs $G/second_price.rs

if ! python3 $ROOT/dev/rust-infer-gate.py --driver $JS; then
  fail=1
fi

if (( fail )); then print C3-TYPES-FAIL; exit 1; fi
print C3-TYPES-OK
