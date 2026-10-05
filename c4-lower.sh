#!/bin/zsh
# C4 check: the `lower` and `check` modes of the Rust importer on the golden
# crate, the "Done when" of C4:
# 1. `lower` prints init.mech and second-price.mech with no refusal.
# 2. `check` passes the kernel check with no axiom.
# 3. Unit B writes the lowered files back to src/init.rs and
#    src/second_price.rs byte for byte (RT-RUST); lib.rs, nat.rs,
#    Cargo.toml and mech-carrier.mech are reported only.
# 4. RED control: a recursive call that is not structural fails the check.
# 5. C1, C2 and C3 stay green.
# The last line is C4-LOWER-OK or C4-LOWER-FAIL.
set -u -o pipefail
ROOT=${ROOT:-$HOME/Documents/mechanism-lang-rust-m0}
BEND=${BEND:-$HOME/.bend/bin/bend}
HERE=${0:A:h}
WORK=$(mktemp -d ${TMPDIR:-/tmp}/c4-lower.XXXXXX)
trap 'rm -rf $WORK' EXIT
JS=$WORK/rust_import.js
RE=$WORK/rust_emit.js
G=$ROOT/test/rust/emit/crate
ulimit -s "$(ulimit -Hs)"

# build <driver> <out js>
build() {
  if ! $BEND $ROOT/bend2/tests/$1.bend -o $2 > $WORK/build.log 2>&1; then
    tail -n 20 $WORK/build.log
    print "BUILD-FAIL $1"
    print C4-LOWER-FAIL
    exit 1
  fi
}
build rust_import $JS
build rust_emit $RE

# run <mode> <out> <lib.rs> <init.rs> <nat.rs> <second_price.rs>
# The `x` keeps the last newline of each text.
run() {
  local l i n s
  l="$(cat $3; print -rn -- x)"; i="$(cat $4; print -rn -- x)"
  n="$(cat $5; print -rn -- x)"; s="$(cat $6; print -rn -- x)"
  node --stack-size=16384 $JS $1 "${l%x}" init "${i%x}" nat "${n%x}" second_price "${s%x}" > $2 2> $WORK/err < /dev/null
}

fail=0
S=$G/src
M=$WORK/m
mkdir -p $M

# 1. `lower`: split the output at the `-- file <name>` lines.
run lower $WORK/low $S/lib.rs $S/init.rs $S/nat.rs $S/second_price.rs
lower_rc=$?
if (( lower_rc == 0 )) && python3 - $WORK/low $M <<'EOF'
import os, sys
text = open(sys.argv[1]).read()
names, parts, bad = [], {}, []
for l in text.splitlines(keepends=True):
    if l.startswith("-- file "):
        names.append(l[8:].strip()); parts[names[-1]] = ""
    elif names: parts[names[-1]] += l
    else: bad.append(l)
for n in names: open(os.path.join(sys.argv[2], n), "w").write(parts[n])
print(f"files={names} lines={[parts[n].count(chr(10)) for n in names]}")
if bad: print("unexpected lines:", bad[:3])
sys.exit(0 if (not bad and names == ["init.mech", "second-price.mech"]) else 1)
EOF
then
  print "MATCH lower"
else
  head -n 3 $WORK/low; head -c 400 $WORK/err
  fail=1
  print "FAIL lower"
fi

# 2. `check`: the kernel check of the files joined in manifest order.
if run check $WORK/chk $S/lib.rs $S/init.rs $S/nat.rs $S/second_price.rs \
  && rg -q '^MECH-CHECK-OK [0-9]+ rows axioms=0$' $WORK/chk; then
  print "MATCH check ($(head -n 1 $WORK/chk))"
else
  print "FAIL check: $(head -c 400 $WORK/chk) $(head -c 400 $WORK/err)"
  fail=1
fi

# 3. RT-RUST: unit B reads the files by name, so it runs in their folder.
if (cd -q $M && node --stack-size=16384 $RE crate init.mech second-price.mech plain > $WORK/crate.out 2> $WORK/crate.err); then
  for f in src/init.rs src/second_price.rs; do
    if cmp -s $G/$f $M/plain/$f; then
      print "MATCH rt-rust $f"
    else
      print "FAIL rt-rust $f"
      diff $G/$f $M/plain/$f | head -n 12
      fail=1
    fi
  done
  for f in src/lib.rs src/nat.rs Cargo.toml mech-carrier.mech; do
    if cmp -s $G/$f $M/plain/$f; then print "SAME $f"; else print "DIFFERS $f (reported only)"; fi
  done
else
  print "FAIL unit B crate: $(head -c 400 $WORK/crate.err)"
  fail=1
fi

# 4. RED control: auction_compare calls itself on the full arguments.
N=$WORK/n
mkdir -p $N
sd -F -- 'auction_compare(tie_wins, previous, other)' 'auction_compare(tie_wins, bid, price)' < $S/second_price.rs > $N/second_price.rs
if cmp -s $S/second_price.rs $N/second_price.rs; then
  print "FAIL red control: the edit did not apply"
  fail=1
else
  if run check $WORK/red $S/lib.rs $S/init.rs $S/nat.rs $N/second_price.rs \
    && rg -q '^MECH-CHECK-FAIL recursive definition auctionCompare failed the structural termination guard$' $WORK/red; then
    print "MATCH red control ($(head -n 1 $WORK/red))"
  else
    print "FAIL red control: $(head -c 400 $WORK/red) $(head -c 400 $WORK/err)"
    fail=1
  fi
fi

# 5. The checks of C1, C2 and C3.
for u in c1-lift:C1-LIFT-OK c2-resolve:C2-RESOLVE-OK c3-types:C3-TYPES-OK; do
  s=${u%%:*}
  want=${u#*:}
  if got=$(zsh $HERE/$s.sh 2>&1 | tail -n 1) && [[ $got == $want ]]; then
    print "MATCH $s ($got)"
  else
    print "FAIL $s: $got"
    fail=1
  fi
done

if (( fail )); then print C4-LOWER-FAIL; exit 1; fi
print C4-LOWER-OK
