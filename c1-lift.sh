#!/bin/zsh
# C1 "Done when" check: build bend2/tests/rust_import.bend once, lift init.rs
# and second_price.rs of the golden crate (the output must be byte-equal to
# the input), then lift one negative file with a `let` statement (the output
# must be one refusal line with the line:col of the `let`).
# Last line: C1-LIFT-OK or C1-LIFT-FAIL.
set -u
ROOT=${ROOT:-$HOME/Documents/mechanism-lang-rust-m0}
BEND=${BEND:-$HOME/.bend/bin/bend}
WORK=$(mktemp -d ${TMPDIR:-/tmp}/c1-lift.XXXXXX)
trap 'rm -rf $WORK' EXIT
JS=$WORK/rust_import.js
ulimit -s "$(ulimit -Hs)"
fail=0

if ! $BEND $ROOT/bend2/tests/rust_import.bend -o $JS > $WORK/build.log 2>&1; then
  print -r -- "BUILD-FAIL"
  head -n 40 $WORK/build.log
  print -r -- "C1-LIFT-FAIL"
  exit 1
fi

# lift <in> <out>: the text goes in as one argument; the `x` sentinel keeps
# the final newline.
lift() {
  local src
  src="$(cat $1; print -rn -- x)"
  node --stack-size=16384 $JS lift "${src%x}" > $2 2> $WORK/err < /dev/null
}

for f in init second_price; do
  in=$ROOT/test/rust/emit/crate/src/$f.rs
  lift $in $WORK/$f.got
  if cmp -s $in $WORK/$f.got; then
    print -r -- "MATCH $f.rs"
  else
    print -r -- "DIFF $f.rs"
    diff $in $WORK/$f.got | head -n 20
    head -n 5 $WORK/err
    fail=1
  fi
done

neg=$WORK/neg_let.rs
cat > $neg <<'EOF'
//! Emitted by `mech rust-out` from `neg.mech`.

pub fn f() -> bool {
    let x = true;
    x
}
EOF
at=$(rg -n --column -o 'let' $neg | head -n 1 | cut -d: -f1,2)
want="REFUSED $at: \`let\` statement"
lift $neg $WORK/neg.got
got=$(head -n 1 $WORK/neg.got)
lines=$(wc -l < $WORK/neg.got | tr -d ' ')
if [[ "$got" == "$want" && "$lines" == 1 ]]; then
  print -r -- "MATCH neg_let.rs: $got"
else
  print -r -- "DIFF neg_let.rs: want '$want', got '$got' ($lines lines)"
  head -n 5 $WORK/err
  fail=1
fi

if (( fail == 0 )); then
  print -r -- "C1-LIFT-OK"
else
  print -r -- "C1-LIFT-FAIL"
  exit 1
fi
