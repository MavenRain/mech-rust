#!/bin/zsh
# C2 check: the `resolve` mode of the Rust importer on the golden crate, the
# "Done when" of C2 (22 fn and 7 data of CF7, D7 of each mech name gives the
# Rust name back, the order is init, second_price) and a few refusals.
# The last line is C2-RESOLVE-OK or C2-RESOLVE-FAIL.
set -u
ROOT=${ROOT:-$HOME/Documents/mechanism-lang-rust-m0}
BEND=${BEND:-$HOME/.bend/bin/bend}
WORK=$(mktemp -d ${TMPDIR:-/tmp}/c2-resolve.XXXXXX)
trap 'rm -rf $WORK' EXIT
JS=$WORK/rust_import.js
G=$ROOT/test/rust/emit/crate/src
ulimit -s "$(ulimit -Hs)"
if ! $BEND $ROOT/bend2/tests/rust_import.bend -o $JS > $WORK/build.log 2>&1; then
  tail -n 20 $WORK/build.log
  print BUILD-FAIL
  print C2-RESOLVE-FAIL
  exit 1
fi

# resolve <out> <lib.rs> <init.rs> <nat.rs> <second_price.rs>
# The `x` keeps the last newline of each text.
resolve() {
  local l i n s
  l="$(cat $2; print -rn -- x)"; i="$(cat $3; print -rn -- x)"
  n="$(cat $4; print -rn -- x)"; s="$(cat $5; print -rn -- x)"
  node --stack-size=16384 $JS resolve "${l%x}" init "${i%x}" nat "${n%x}" second_price "${s%x}" > $1 2> $WORK/err < /dev/null
}

fail=0
resolve $WORK/out $G/lib.rs $G/init.rs $G/nat.rs $G/second_price.rs
if ! python3 - $WORK/out $G/init.rs $G/second_price.rs <<'EOF'
import re, sys
out = open(sys.argv[1]).read().splitlines()
KW = set("as break const continue crate else enum extern false fn for if impl in let loop match mod move mut pub ref return self Self static struct super trait true type unsafe use where while async await dyn abstract become box do final macro override priv typeof unsized virtual yield try gen".split())
def snake(s):
    return (s[:1].lower() + "".join("_" + c.lower() if c.isupper() else c for c in s[1:])) if s else s
def kw(s):
    return s + "_" if s in KW else s
rows, man, bad = [], [], []
for l in out:
    m = re.fullmatch(r"(\S+) (enum|variant|struct|ctor|fn) (\S+) -> (\S+)", l)
    n = re.fullmatch(r"manifest (\S+) (\S+)", l)
    if m: rows.append(m.groups())
    elif n: man.append(n.groups())
    else: bad.append(l)
if bad: print("unexpected lines:", bad[:3])
def back(k, rust, mech):
    if k in ("fn", "ctor"): return kw(snake(mech))
    if k == "variant": return rust.split("::")[0] + "::" + mech[:1].upper() + mech[1:]
    return mech
nd7 = [r for r in rows if back(r[1], r[2], r[3]) != r[2]]
fns = [r for r in rows if r[1] == "fn"]
data = [r for r in rows if r[1] in ("enum", "struct")]
src = open(sys.argv[2]).read() + open(sys.argv[3]).read()
src_fns = set(re.findall(r"^pub fn (\w+)", src, re.M))
src_data = set(re.findall(r"^pub (?:enum|struct) (\w+)", src, re.M))
same_fns = src_fns == {r[2] for r in rows if r[1] in ("fn", "ctor")}
same_data = src_data == {r[2] for r in data}
mechs = [r[3] for r in rows]
print(f"rows={len(rows)} fn={len(fns)} data={len(data)} variant={sum(r[1]=='variant' for r in rows)} ctor={sum(r[1]=='ctor' for r in rows)} d7-back-bad={len(nd7)} mech-distinct={len(set(mechs))==len(mechs)} src-fns-match={same_fns} src-data-match={same_data}")
print("manifest", " ".join(f"{a}:{b}" for a, b in man))
ok = (not bad and len(fns) == 22 and len(data) == 7 and not nd7 and same_fns and same_data
      and len(set(mechs)) == len(mechs)
      and man == [("init", "init.mech"), ("second_price", "second-price.mech")])
for r in nd7[:3]: print("D7 BAD", r)
sys.exit(0 if ok else 1)
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
  resolve $o $3 $4 $5 $6
  if rg -q -F -- "REFUSED $2" $o; then
    print "MATCH $1 ($(head -n 1 $o))"
  else
    print "FAIL $1: $(head -c 300 $o) $(head -c 300 $WORK/err)"
    fail=1
  fi
}

N=$WORK/n
mkdir -p $N
sd -F -- 'auction_add' 'auction_Add' < $G/second_price.rs > $N/canon.rs
L=$(rg -n 'fn auction_Add' $N/canon.rs | head -n 1 | cut -d: -f1)
neg canon "src/second_price.rs:$L:1: name \`auction_Add\` that is not canonical" $G/lib.rs $G/init.rs $G/nat.rs $N/canon.rs
sd -F -- 'use crate::init::*;' '' < $G/second_price.rs > $N/unknown.rs
neg unknown 'src/second_price.rs:' $G/lib.rs $G/init.rs $G/nat.rs $N/unknown.rs
rg -q -F 'unknown type `MechNat`' $WORK/neg-unknown || { print "FAIL unknown: not unknown type MechNat"; fail=1 }
sd -F -- '`init.mech`.' "\`init.mech\`.

use crate::second_price::*;" < $G/init.rs > $N/cycle.rs
neg cycle 'src/init.rs:3:1: `use crate::second_price::*;` in a module cycle (CD3)' $G/lib.rs $N/cycle.rs $G/nat.rs $G/second_price.rs
sd -F -- 'auction_bit' 'mech_true' < $G/second_price.rs > $N/mech.rs
L=$(rg -n 'fn mech_true' $N/mech.rs | head -n 1 | cut -d: -f1)
neg mech "src/second_price.rs:$L:1: "'mech name collision (CD5): `mech_true` gives `mechTrue`' $G/lib.rs $G/init.rs $G/nat.rs $N/mech.rs
sd -F -- 'auction_add' 'nat_add' < $G/second_price.rs > $N/rust.rs
L=$(rg -n 'fn nat_add' $N/rust.rs | head -n 1 | cut -d: -f1)
neg rust "src/second_price.rs:$L:1: name collision (D7): nat_add" $G/lib.rs $G/init.rs $G/nat.rs $N/rust.rs
{ cat $G/nat.rs; print } > $N/nat.rs
neg nat 'src/nat.rs:1:1: text other than the fixed `nat` module of the emitter (CD7)' $G/lib.rs $G/init.rs $N/nat.rs $G/second_price.rs
sd -F -- '`init.mech`' '`ini.mech`' < $G/init.rs > $N/file.rs
neg file 'src/init.rs:1:1: file `ini.mech` that does not give the module name (CD4)' $G/lib.rs $N/file.rs $G/nat.rs $G/second_price.rs
{ cat $G/lib.rs; print -r -- 'pub mod extra;' } > $N/lib.rs
neg missing 'src/extra.rs:0:0: no text for the module' $N/lib.rs $G/init.rs $G/nat.rs $G/second_price.rs

if (( fail )); then print C2-RESOLVE-FAIL; exit 1; fi
print C2-RESOLVE-OK
