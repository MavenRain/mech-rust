#!/bin/zsh
# D3 runner (open points of the importer).
# Modes: in | rt | parse | gates | py | exec | all.  The default mode is gates.
# The exit code is not 0 when a gate of the mode fails.
# The mode exec runs DIFF-EXEC.  It needs the sandbox off (sccache).
ROOT=/Users/oobi/Documents/mechanism-lang-rust-m0

gate() {
  print -- "== $1"
  ( cd $ROOT && zsh $2 )
  local rc=$?
  print -- "== $1 rc=$rc"
  return $rc
}

rin() { gate RUST-IN dev/rust-in-gate.sh }
rt() { gate ROUND-TRIP dev/rt-mech-gate.sh }
parse() { gate RUST-PARSE dev/rust-parse-gate.sh }
diffexec() { gate DIFF-EXEC dev/rust-out-diff-exec.sh }

pygate() {
  print -- "== $1"
  ( cd $ROOT && python3 $2 )
  local rc=$?
  print -- "== $1 rc=$rc"
  return $rc
}

# The three Python gates of the importer.
py() {
  local rc=0
  pygate RUST-INFER dev/rust-infer-gate.py || rc=1
  pygate RUST-LOWER dev/rust-lower-gate.py || rc=1
  pygate RUST-IN-CLI dev/rust-in-cli-gate.py || rc=1
  return $rc
}

gates() {
  local rc=0
  rin || rc=1
  rt || rc=1
  parse || rc=1
  return $rc
}

mode=${1:-gates}
case $mode in
  in) rin ;;
  rt) rt ;;
  parse) parse ;;
  gates) gates ;;
  exec) diffexec ;;
  py) py ;;
  all) gates && py && diffexec ;;
  *) print -u2 -- "usage: d3-points.sh [in|rt|parse|gates|py|exec|all]"; exit 2 ;;
esac
rc=$?
print -- "D3-RUNNER mode=$mode rc=$rc"
exit $rc
