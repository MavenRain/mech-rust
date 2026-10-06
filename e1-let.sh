#!/bin/zsh
# E1 runner (`let`, both directions).
# Modes: learn | emit | in | rt | parse | py | all.  The default mode is learn.
# The exit code is not 0 when a gate of the mode fails.
# Drivers are built once to $TMPDIR/e1;  `nobuild` as the second argument uses the last build.
# DIFF-EXEC is not here:  run `zsh ~/Documents/mech-rust/d3-points.sh exec` with the sandbox off.
set -u
ROOT=/Users/oobi/Documents/mechanism-lang-rust-m0
W=/Users/oobi/Documents/mech-rust
O=${TMPDIR:-/tmp}/e1
mkdir -p $O

# The sites of E1 (learn L1-L4 and the edit sites).  Read-only.
learn() {
  print -- "== L1 RIR expressions (no block, no let today)"
  rg -n "^type Ex|^  X[A-Z][A-Za-z]*\{" $ROOT/bend2/rust/rir.bend
  print -- "== L2 emitter: tail, nodes, fn_item"
  rg -n "^def tail|^def nodes|^def ex\(|^def fn_item" $ROOT/bend2/rust/emit.bend
  print -- "== L2 importer: let refusal, tail_job"
  rg -n "SLet|^def tail_job|^def stmt_refusal" $ROOT/bend2/rust/lift.bend
  print -- "== L2 importer: lowering and inference entries"
  rg -n "^def children|^def lows|^def fun_of|^def step_jobs" $ROOT/bend2/rust/lower.bend
  rg -n "^type Job|^type Syn|^type St|^def step|^def syn" $ROOT/bend2/rust/infer.bend
  print -- "== L3 checked_form prints Pp.term per def"
  rg -n "^def checked_form|^def entry_text|Pp.term" $ROOT/bend2/surface/elab.bend | head -n 6
  print -- "== L4 let binder quantity (elab) and the kernel sites"
  rg -n "SLet|Check.define" $ROOT/bend2/surface/elab_term.bend | head -n 6
  rg -n "Term.Let\{" $ROOT/bend2/kernel/check_engine.bend
  print -- "== emitter let refusal and the value context"
  rg -n "a let \(M0\)|^def plan_term|^def bind_some|^def slot_at" $ROOT/bend2/rust/erase_typed.bend
}

# Emit: build the emit driver, emit the let fixture in the globals of init.mech, rustfmt --check.
emit() {
  if [[ ${1:-} != nobuild ]]; then
    if ! ~/.bend/bin/bend $ROOT/bend2/tests/rust_emit.bend -o $O/re.js > $O/build.log 2>&1; then
      print -r -- "E1-EMIT-FAIL build"
      head -n 14 $O/build.log | cut -c1-220
      return 1
    fi
  fi
  local fx=$ROOT/test/rust/emit/let_probe.mech
  if [[ ! -f $fx ]]; then
    print -r -- "E1-EMIT-SKIP no fixture $fx"
    return 1
  fi
  if ! cp $ROOT/prelude/init.mech $O/; then
    print -r -- "E1-EMIT-FAIL prelude copy"
    return 1
  fi
  ( cd -q $O && node re.js emit init.mech $fx > let_probe.rs 2> let_probe.err )
  local rc=$?
  if [[ $rc != 0 ]]; then
    print -r -- "E1-EMIT-FAIL rc=$rc"
    head -n 6 $O/let_probe.err | cut -c1-220
    return 1
  fi
  if rustfmt --check --edition 2021 $O/let_probe.rs > $O/let_probe.fmt 2>&1; then
    print -r -- "E1-EMIT-OK $(wc -l < $O/let_probe.rs | tr -d ' ') lines, rustfmt clean"
    rg -n "let " $O/let_probe.rs | head -n 12
  else
    print -r -- "E1-FMT-FAIL"
    head -n 12 $O/let_probe.fmt | cut -c1-220
    return 1
  fi
}

gate() {
  print -- "== $1"
  ( cd -q $ROOT && zsh $2 )
  local rc=$?
  print -- "== $1 rc=$rc"
  return $rc
}

pygate() {
  print -- "== $1"
  ( cd -q $ROOT && python3 $2 )
  local rc=$?
  print -- "== $1 rc=$rc"
  return $rc
}

rin() { gate RUST-IN dev/rust-in-gate.sh }
rt() { gate ROUND-TRIP dev/rt-mech-gate.sh }
parse() { gate RUST-PARSE dev/rust-parse-gate.sh }

py() {
  local rc=0
  pygate RUST-INFER dev/rust-infer-gate.py || rc=1
  pygate RUST-LOWER dev/rust-lower-gate.py || rc=1
  pygate RUST-IN-CLI dev/rust-in-cli-gate.py || rc=1
  return $rc
}

all() {
  local rc=0
  emit ${1:-} || rc=1
  parse || rc=1
  rin || rc=1
  rt || rc=1
  py || rc=1
  return $rc
}

mode=${1:-learn}
case $mode in
  learn) learn ;;
  emit) emit ${2:-} ;;
  in) rin ;;
  rt) rt ;;
  parse) parse ;;
  py) py ;;
  all) all ${2:-} ;;
  *) print -u2 -- "usage: e1-let.sh [learn|emit|in|rt|parse|py|all] [nobuild]"; exit 2 ;;
esac
rc=$?
print -- "E1-RUNNER mode=$mode rc=$rc"
exit $rc
