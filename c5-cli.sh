#!/bin/zsh
# C5 check: the `rust-in` verb of the Rust importer, the "Done when" of C5:
# a. Build the importer driver, unit B and the mech CLI to JS.
# b. Mode `run` on the golden crate writes init.mech, second-price.mech,
#    MANIFEST and a copy of mech-carrier.mech, and no other file.
# c. RT-RUST: unit B `crate` on the MANIFEST files gives Cargo.toml and src/
#    byte-equal to the golden crate (mech-carrier.mech is reported only).
# d. An output directory that exists: exit 1, no change.
# e. Bad arguments and a crate with no src/lib.rs: exit 64.
# f. A refused crate (a `let` in init.rs): exit 65, a REFUSED line with the
#    position of the `let`, no output directory.
# g. A crate with no mech-carrier.mech: no carrier in the output.
# h. The verb `mech rust-in` gives the same files as mode `run`.
# i. C4 (with C1 to C3), the lowering gate and the inference gate stay green.
# The last line is C5-CLI-OK or C5-CLI-FAIL.
set -u -o pipefail
ROOT=${ROOT:-$HOME/Documents/mechanism-lang-rust-m0}
BEND=${BEND:-$HOME/.bend/bin/bend}
HERE=${0:A:h}
WORK=$(mktemp -d ${TMPDIR:-/tmp}/c5-cli.XXXXXX)
trap 'rm -rf $WORK' EXIT
JS=$WORK/rust_import.js
RE=$WORK/rust_emit.js
CLI=$WORK/mech.js
G=$ROOT/test/rust/emit/crate
ulimit -s "$(ulimit -Hs)"
fail=0

ok() { print "MATCH $1" }
bad() { print "FAIL $1"; fail=1 }

# a. build <source> <out js>
build() {
  if ! $BEND $1 -o $2 > $WORK/build.log 2>&1; then
    tail -n 20 $WORK/build.log
    print "BUILD-FAIL $1"
    print C5-CLI-FAIL
    exit 1
  fi
}
build $ROOT/bend2/tests/rust_import.bend $JS
build $ROOT/bend2/tests/rust_emit.bend $RE
build $ROOT/bend2/mech.bend $CLI
ok "build (driver, unit B, mech CLI)"

# rin <js> <args>: the exit code goes to $rc, stdout to $WORK/o, stderr to $WORK/e.
rc=0
rin() {
  local js=$1
  shift
  node --stack-size=16384 $js "$@" > $WORK/o 2> $WORK/e < /dev/null
  rc=$?
}
# The file names of a folder, sorted by byte order, on one line.
names() { print -rl -- $1/*(DN:t) | LC_ALL=C sort | paste -sd' ' - }
# One line for each file of a folder: its hash and its relative path.
snap() { (cd -q $1 && find . -type f -exec shasum {} + | LC_ALL=C sort) }

# b. Mode `run` on the golden crate.
O=$WORK/out
rin $JS run $G $O
if (( rc != 0 )); then
  bad "run golden: exit $rc: $(head -c 400 $WORK/e) $(head -c 200 $WORK/o)"
else
  got=$(names $O)
  want="MANIFEST init.mech mech-carrier.mech second-price.mech"
  if [[ $got == $want ]]; then ok "run files ($got)"; else bad "run files: got '$got' want '$want'"; fi
  if [[ "$(cat $O/MANIFEST; print -rn -- x)" == $'init.mech\nsecond-price.mech\nx' ]]; then
    ok "MANIFEST order"
  else
    bad "MANIFEST: $(head -c 200 $O/MANIFEST)"
  fi
  if cmp -s $G/mech-carrier.mech $O/mech-carrier.mech; then ok "carrier copy"; else bad "carrier copy differs"; fi
fi

# c. RT-RUST: unit B reads the files by name, so it runs in their folder.
if [[ -f $O/MANIFEST ]]; then
  mf=(${(f)"$(cat $O/MANIFEST)"})
  if (cd -q $O && node --stack-size=16384 $RE crate $mf $WORK/rt > $WORK/rt.out 2> $WORK/rt.err); then
    if cmp -s $G/Cargo.toml $WORK/rt/Cargo.toml; then ok "rt-rust Cargo.toml"; else bad "rt-rust Cargo.toml"; fi
    if diff -r $G/src $WORK/rt/src > $WORK/rt.diff; then
      ok "rt-rust src/ ($(names $G/src))"
    else
      bad "rt-rust src/"
      head -n 12 $WORK/rt.diff
    fi
    if cmp -s $G/mech-carrier.mech $WORK/rt/mech-carrier.mech; then
      print "SAME mech-carrier.mech"
    else
      print "DIFFERS mech-carrier.mech (reported only)"
    fi
  else
    bad "unit B crate: $(head -c 400 $WORK/rt.err)"
  fi
else
  bad "rt-rust: no MANIFEST"
fi

# d. An output directory that exists.
before=$(snap $O)
rin $JS run $G $O
if (( rc == 1 )) && rg -q 'output already exists' $WORK/e && [[ $(snap $O) == $before ]]; then
  ok "existing out dir (exit 1, no change)"
else
  bad "existing out dir: exit $rc: $(head -c 300 $WORK/e)"
fi

# e. Usage and a crate with no src/lib.rs.
rin $JS run $G
if (( rc == 64 )); then ok "one argument (exit 64)"; else bad "one argument: exit $rc"; fi
rin $JS run $WORK/none $WORK/out-none
if (( rc == 64 )) && [[ ! -e $WORK/out-none && ! -L $WORK/out-none ]]; then
  ok "no lib.rs (exit 64: $(head -n 1 $WORK/e))"
else
  bad "no lib.rs: exit $rc: $(head -c 300 $WORK/e)"
fi

# f. A refused crate: a `let` statement at the start of the first fn body.
B=$WORK/bad
cp -R $G $B
pos=$(python3 - $B/src/init.rs <<'EOF'
import sys
p = sys.argv[1]
lines = open(p).read().split("\n")
i = next(k for k, l in enumerate(lines) if l.startswith("pub fn"))
j = next(k for k in range(i, len(lines)) if lines[k].endswith("{"))
lines.insert(j + 1, "    let unused = mech_unit();")
open(p, "w").write("\n".join(lines))
print(f"{j + 2}:5")
EOF
)
rin $JS run $B $WORK/out-bad
if (( rc == 65 )) && rg -q "REFUSED src/init.rs:$pos:" $WORK/e && [[ ! -e $WORK/out-bad && ! -L $WORK/out-bad ]]; then
  ok "refused crate (exit 65, $(rg -o "src/init.rs:$pos:[^\n]*" $WORK/e | head -n 1))"
else
  bad "refused crate: want src/init.rs:$pos, exit $rc: $(head -c 300 $WORK/e)"
fi

# g. A crate with no mech-carrier.mech.
N=$WORK/nocar
cp -R $G $N
rm $N/mech-carrier.mech
rin $JS run $N $WORK/out-nocar
got=$(names $WORK/out-nocar)
if (( rc == 0 )) && [[ $got == "MANIFEST init.mech second-price.mech" ]]; then
  ok "no carrier ($got)"
else
  bad "no carrier: exit $rc, files '$got': $(head -c 300 $WORK/e)"
fi

# h. The verb of the mech CLI, and its usage text.
rin $CLI rust-in $G $WORK/out-cli
if (( rc == 0 )) && [[ $(snap $WORK/out-cli) == $(snap $O) ]]; then
  ok "mech rust-in = mode run"
else
  bad "mech rust-in: exit $rc: $(head -c 300 $WORK/e)"
fi
rin $CLI
if (( rc == 64 )) && rg -q 'mech rust-in CRATE_DIR OUT_DIR' $WORK/e; then ok "mech usage lists rust-in"; else bad "mech usage: exit $rc"; fi

# i. The checks of C4 (it runs C1 to C3) and the two regression gates.
if got=$(zsh $HERE/c4-lower.sh 2>&1 | tail -n 1) && [[ $got == C4-LOWER-OK ]]; then ok "c4-lower ($got)"; else bad "c4-lower: $got"; fi
if got=$(python3 $ROOT/dev/rust-lower-gate.py --driver $JS --emitter $RE 2>&1 | tail -n 1) && [[ $got == RUST-LOWER-OK* ]]; then ok "rust-lower-gate ($got)"; else bad "rust-lower-gate: $got"; fi
if got=$(python3 $ROOT/dev/rust-infer-gate.py --driver $JS 2>&1 | tail -n 1) && [[ $got == RUST-INFER-OK* ]]; then ok "rust-infer-gate ($got)"; else bad "rust-infer-gate: $got"; fi

if (( fail )); then print C5-CLI-FAIL; exit 1; fi
print C5-CLI-OK
