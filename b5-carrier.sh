#!/bin/zsh
# Carrier check of mech-rust M0 unit B (sub-unit B5).
#
# The script compares the golden carrier (test/rust/emit/crate/mech-carrier.mech) with the classify table of
# prelude/init.mech + prelude/mechanism/second-price.mech and with the text of the two inputs:
#   1. the head names of the carrier = the names of the `prop`, `type` and `absurd` lines (same set, same count);
#   2. no head name of the carrier has a `fn`, `data` or `bool` line, and the table has no `refused` line;
#   3. each `-- from <file>` line names an input, in input order;
#   4. below each `-- from` line, the non-blank lines are lines of that input in the same order (verbatim), and
#      the head names are the non-runtime head names of that input in source order.
# A head is a line with a lower-case letter in column 1 (rule D2). Its name is the first word after the keyword
# that is not `rec`.
#
# Use: zsh b5-carrier.sh [<re.js>]. With no argument the script builds bend2/tests/rust_emit.bend to JavaScript
# (about 48 s). Output: `B5-CARRIER-OK ...` (exit code 0) or `B5-CARRIER-FAIL` and the reasons (exit code 1).
set -u
ulimit -s "$(ulimit -Hs)"
root=$HOME/Documents/mechanism-lang-rust-m0
bend=${BEND:-$HOME/.bend/bin/bend}
node=(${NODE:-node} --stack-size=16384)
O=${TMPDIR:-/tmp}/mrb5
mkdir -p $O
stop() { print -r -- "B5-CARRIER-FAIL $1"; [[ -n ${2:-} ]] && head -n 12 $2 | cut -c1-200; exit 1 }
js=${1:-$O/re.js}
js=${js:A}
if (( $# == 0 )); then
  $bend $root/bend2/tests/rust_emit.bend -o $js > $O/build.log 2>&1 || stop "driver build" $O/build.log
fi
cp $root/prelude/init.mech $root/prelude/mechanism/second-price.mech $O/
cd -q $O
$node $js classify init.mech second-price.mech > table.txt 2> table.err || stop "classify" table.err
python3 - table.txt $root/test/rust/emit/crate/mech-carrier.mech init.mech second-price.mech <<'EOF'
import re
import sys

table = open(sys.argv[1]).read().splitlines()
carrier = open(sys.argv[2]).read().splitlines()
inputs = sys.argv[3:]


def rows(kinds):
    return [w[1].rstrip(":") for w in (line.split() for line in table) if len(w) > 1 and w[0] in kinds]


def head_name(line):
    found = [re.match(r"[A-Za-z_][A-Za-z0-9_']*", w) for w in line.split()[1:] if w != "rec"]
    return found[0].group(0) if found and found[0] else ""


def heads(lines):
    return [head_name(line) for line in lines if re.match(r"[a-z]", line)]


def in_order(part, whole):
    rest = iter(whole)
    return all(any(x == y for y in rest) for x in part)


want = rows({"prop", "type", "absurd"})
runtime = set(rows({"fn", "data", "bool"}))
got = heads(carrier)
marks = [i for i, line in enumerate(carrier) if line.startswith("-- from ")]
sections = [(carrier[i][8:], carrier[i + 1 : j]) for i, j in zip(marks, marks[1:] + [len(carrier)])]
names = [name for name, _ in sections]
sources = {name: open(name).read().splitlines() for name in inputs}
problems = (
    (
        [f"names differ: table only {sorted(set(want) - set(got))}, carrier only {sorted(set(got) - set(want))}"]
        if set(want) != set(got)
        else []
    )
    + ([f"count: table {len(want)}, carrier {len(got)}"] if len(want) != len(got) else [])
    + [f"runtime name in the carrier: {n}" for n in got if n in runtime]
    + [f"table: {line}" for line in table if line.startswith("refused")]
    + ([f"from lines: {names}"] if names != inputs else [])
    + [
        f"{n}: the lines are not verbatim lines of the source in source order"
        for n, body in sections
        if not in_order([line for line in body if line.strip()], sources.get(n, []))
    ]
    + [
        f"{n}: the head names are not the non-runtime heads of the source in source order"
        for n, body in sections
        if heads(body) != [h for h in heads(sources.get(n, [])) if h in set(want)]
    ]
)
if problems:
    print("B5-CARRIER-FAIL")
    print("\n".join(p[:400] for p in problems))
    print("table:   " + " ".join(want)[:900])
    print("carrier: " + " ".join(got)[:900])
    sys.exit(1)
counts = ", ".join(f"{k} {len(rows({k}))}" for k in ("prop", "type", "absurd"))
order = "equal to the table order" if got == want else "source order (the table order is different)"
print(
    f"B5-CARRIER-OK {len(got)} heads ({counts}) from {len(sections)} files, verbatim, {order}; "
    f"{len(runtime)} runtime names, none in the carrier"
)
EOF
