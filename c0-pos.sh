#!/bin/zsh
# C0 positions check (unit C, sub-unit C0). One JavaScript build of the
# frontend driver, then mode `pos` on each accepted parse fixture.
# Expected lines come from `rg -n` on the fixture: each top-level item starts
# in column 1, so the position is `<line>:1`. Output: one MATCH or DIFF line
# for each fixture, then C0-POS-OK or C0-POS-FAIL. The first fixture is printed.
set -u
ROOT=/Users/oobi/Documents/mechanism-lang-rust-m0
BEND=${BEND:-$HOME/.bend/bin/bend}
WORK=$(mktemp -d ${TMPDIR:-/tmp}/c0-pos.XXXXXX)
trap 'rm -rf $WORK' EXIT
JS=$WORK/rust_frontend.js

if ! $BEND $ROOT/bend2/tests/rust_frontend.bend -o $JS > $WORK/build.log 2>&1; then
  print -r -- "BUILD-FAIL"
  head -40 $WORK/build.log | cut -c1-220
  print -r -- "C0-POS-FAIL"
  exit 1
fi

# want <file>: `<line>:1 <kind> <name>` (`use` and `impl` have no name).
want() {
  {
    rg -n -o -r '$3 $4' '^(pub(\([a-z]+\))? )?(fn|struct|enum|mod|trait|const|type) (\w+)' $1
    rg -n -o -r '$3' '^(pub(\([a-z]+\))? )?(use|impl)\b' $1
  } | sd '^(\d+):' '$1:1 ' | sort -n -t: -k1,1
}

rc=0
first=1
for f in $ROOT/test/rust/parse/*.rs; do
  src="$(cat $f; print -rn -- x)"
  node $JS pos "${src%x}" > $WORK/got 2> $WORK/err < /dev/null
  want $f > $WORK/want
  if (( first )); then
    print -r -- "--- pos ${f:t}"
    cat $WORK/got
    first=0
  fi
  if cmp -s $WORK/want $WORK/got; then
    print -r -- "MATCH ${f:t} $(wc -l < $WORK/got | tr -d ' ') items"
  else
    print -r -- "DIFF ${f:t}"
    diff $WORK/want $WORK/got | head -8
    rc=1
  fi
done

if (( rc == 0 )); then
  print -r -- "C0-POS-OK"
else
  print -r -- "C0-POS-FAIL"
fi
exit $rc
