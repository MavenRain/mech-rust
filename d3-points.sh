#!/bin/zsh
# D3 runner (open points of the importer).
# Modes: in | rt | parse | gates | exec | all.  The default mode is gates.
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
  all) gates && diffexec ;;
  *) print -u2 -- "usage: d3-points.sh [in|rt|parse|gates|exec|all]"; exit 2 ;;
esac
rc=$?
print -- "D3-RUNNER mode=$mode rc=$rc"
exit $rc
