#!/bin/zsh
# mech-rust unit D, D2 (carrier merge): runner. No commit, no push.
# Use: zsh d2-carrier.sh [smoke|golden|gates|exec|all]
#   smoke   Builds the two drivers. Emits and imports the seed 05_proofs.
#   golden  Emits the two M0 inputs. Writes the golden carrier again if no
#           other file of the golden crate changed. Imports the golden crate.
#   gates   Runs ROUND-TRIP (dev/rt-mech-gate.sh) and RUST-IN
#           (dev/rust-in-gate.sh). Prints each line that is not a pass.
#   exec    Runs DIFF-EXEC (dev/rust-out-diff-exec.sh). The gate builds the
#           golden crate with cargo. Run this mode with the sandbox off.
#   all     smoke, golden, gates (default).
# D2_WORK and MECH_RUST_ROOT can isolate runner checks from the real gates.
# Outputs stay in $D2_WORK (default $TMPDIR/d2-carrier).
set -u
R=${MECH_RUST_ROOT:-/Users/oobi/Documents/mechanism-lang-rust-m0}
BEND=${BEND:-$HOME/.bend/bin/bend}
O=${D2_WORK:-${TMPDIR:-/tmp}/d2-carrier}
G=$R/test/rust/emit/crate
node=(node --stack-size=16384)
mkdir -p $O
ulimit -s "$(ulimit -Hs)" 2> /dev/null
[[ "$(< $R/bend2/cli/rust_in.bend)" == *crate_merged* ]] || { print "PATCH-MISSING rust_in.bend"; exit 1 }
[[ "$(< $R/bend2/cli/rust_out.bend)" == *key_line* ]] || { print "PATCH-MISSING rust_out.bend"; exit 1 }

built=0
build() {
  local t
  (( built )) && return 0
  for t in rust_emit rust_import; do
    $BEND $R/bend2/tests/$t.bend -o $O/$t.js > $O/build-$t.log 2>&1 || {
      print "FAIL build $t"
      head -n 14 $O/build-$t.log | cut -c1-240
      print "..."
      tail -n 14 $O/build-$t.log | cut -c1-240
      exit 1
    }
  done
  built=1
  print "BUILD-OK"
}

key_count() {
  local lines=(${(f)"$(< $1)"})
  local keyl=(${(M)lines:#-- at *})
  print ${#keyl}
}

smoke() {
  build
  local s=$R/test/rust/seed/05_proofs rc
  rm -rf $O/s5
  mkdir -p $O/s5
  (cd -q $s && $node $O/rust_emit.js crate light.mech $O/s5/e1 > $O/s5/emit.out 2> $O/s5/emit.err < /dev/null)
  rc=$?
  print -r -- "SMOKE emit rc=$rc $(head -c 300 $O/s5/emit.err)"
  (( rc == 0 )) || return $rc
  [[ -f $O/s5/e1/mech-carrier.mech ]] && cat $O/s5/e1/mech-carrier.mech
  $node $O/rust_import.js run $O/s5/e1 $O/s5/i1 > $O/s5/imp.out 2> $O/s5/imp.err < /dev/null
  rc=$?
  print -r -- "SMOKE import rc=$rc $(head -c 400 $O/s5/imp.err)"
  (( rc == 0 )) || return $rc
  [[ -f $O/s5/i1/light.mech ]] || return 1
  cut -c1-140 $O/s5/i1/light.mech
}

golden() {
  build
  local rc d
  rm -rf $O/gold
  mkdir -p $O/gold
  cp $R/prelude/init.mech $R/prelude/mechanism/second-price.mech $O/gold/
  (cd -q $O/gold && $node $O/rust_emit.js crate init.mech second-price.mech plain > plain.out 2> plain.err < /dev/null)
  rc=$?
  print -r -- "GOLDEN emit rc=$rc $(head -c 300 $O/gold/plain.err)"
  (( rc == 0 )) || return $rc
  d="$(diff -rq $G $O/gold/plain 2>&1)"
  print -r -- "GOLDEN diff: $d"
  if [[ $d == "Files $G/mech-carrier.mech and $O/gold/plain/mech-carrier.mech differ" ]]; then
    cp $O/gold/plain/mech-carrier.mech $G/mech-carrier.mech || return 1
    print "GOLDEN carrier written"
  elif [[ -n $d ]]; then
    return 1
  fi
  print "GOLDEN carrier: $(wc -l < $G/mech-carrier.mech) lines, $(key_count $G/mech-carrier.mech) key lines"
  $node $O/rust_import.js run $G $O/gold/imp > $O/gold/imp.out 2> $O/gold/imp.err < /dev/null
  rc=$?
  print -r -- "GOLDEN import rc=$rc $(head -c 700 $O/gold/imp.err)"
  [[ $rc == 65 && "$(head -c 15 $O/gold/imp.err)" == MECH-CHECK-FAIL && ! -e $O/gold/imp && ! -L $O/gold/imp ]]
}

not_pass() {
  local lines=(${(f)"$(< $1)"})
  print -rl -- ${${${lines:#PASS *}:#ok *}:#OK *} | cut -c1-400 | head -n 30
}

gates() {
  local rc failed=0
  zsh $R/dev/rt-mech-gate.sh > $O/rt.log 2>&1
  rc=$?
  print "ROUND-TRIP rc=$rc"
  (( rc == 0 )) || failed=1
  not_pass $O/rt.log
  zsh $R/dev/rust-in-gate.sh > $O/ri.log 2>&1
  rc=$?
  print "RUST-IN rc=$rc"
  (( rc == 0 )) || failed=1
  not_pass $O/ri.log
  return $failed
}

# DIFF-EXEC builds the golden crate with cargo. Run it with the sandbox off.
diffexec() {
  local rc
  zsh $R/dev/rust-out-diff-exec.sh > $O/de.log 2>&1
  rc=$?
  print "DIFF-EXEC rc=$rc"
  not_pass $O/de.log
  return $rc
}

case ${1:-all} in
  exec) diffexec ;;
  smoke) smoke ;;
  golden) golden ;;
  gates) gates ;;
  all) smoke && golden && gates ;;
  *) print "use: zsh d2-carrier.sh [smoke|golden|gates|exec|all]"; exit 64 ;;
esac
