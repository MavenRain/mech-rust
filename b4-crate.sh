#!/bin/zsh
# B4 crate check. Stage `emit`: builds the driver to JavaScript, writes the
# crate of init.mech + second-price.mech in a new run directory, compares the
# Rust files byte for byte with the golden crate, and does the refusal checks.
# Stage `cargo`: `cargocho build` + clippy in the crate of the last `emit` run
# (sccache needs the Bash sandbox off). No first argument = the two stages.
# `nobuild` as the second argument uses the last driver build.
# The third argument is the number of build log lines to print (default 12).
set -u
D=/Users/oobi/Documents/mechanism-lang-rust-m0
W=/Users/oobi/Documents/mech-rust-m0
O=${TMPDIR:-/tmp}/mrb4
mode=${1:-all}
mkdir -p $O
rc=0
ok() { print -r -- "B4-OK $1" }
bad() { print -r -- "B4-FAIL $1"; rc=1 }
if [[ $mode != cargo ]]; then
  if [[ ${2:-} != nobuild ]]; then
    if ! ~/.bend/bin/bend $D/bend2/tests/rust_emit.bend -o $O/re.js > $O/build.log 2>&1; then
      print -r -- "B4-FAIL driver build"
      head -n ${3:-12} $O/build.log | cut -c1-200
      exit 1
    fi
  fi
  R=$(mktemp -d $O/run.XXXXXX)
  print -r -- $R > $W/.b4-last
  mkdir $R/dup
  cp $D/prelude/init.mech $D/prelude/mechanism/second-price.mech $R/
  cp $D/prelude/init.mech $R/dup/
  cp $D/prelude/init.mech $R/X1.mech
  cd -q $R
  node $O/re.js crate init.mech second-price.mech out > crate.out 2> crate.err
  crc=$?
  if [[ $crc != 0 ]]; then
    print -r -- "B4-FAIL crate write rc=$crc"
    head -n 8 crate.err | cut -c1-200
    exit 1
  fi
  for f in Cargo.toml src/lib.rs src/init.rs src/second_price.rs src/nat.rs; do
    if diff $W/target-crate/$f out/$f > ${f:t}.diff 2>&1; then
      ok "$f: byte-equal"
    else
      bad "$f: $(wc -l < ${f:t}.diff | tr -d ' ') diff lines"
      head -n 8 ${f:t}.diff | cut -c1-200
    fi
  done
  print -r -- "B4-FILES $(fd -t f . out | sort | tr '\n' ' ')"
  if rustfmt --check --edition 2021 out/src/lib.rs > fmt.log 2>&1; then ok "rustfmt --check"; else bad "rustfmt --check"; fi
  print -r -- "B4-CARRIER $(rg -c '^-- from ' out/mech-carrier.mech) files, $(rg -c '^[a-z]' out/mech-carrier.mech) heads, $(wc -l < out/mech-carrier.mech | tr -d ' ') lines"
  node $O/re.js crate init.mech second-price.mech out > again.out 2> again.err
  x=$?
  if [[ $x == 1 ]] && rg -q -F 'mech: output already exists: out' again.err; then ok "existing output refused, exit code 1"; else bad "existing output rc=$x"; fi
  node $O/re.js crate init.mech $D/test/rust/emit/neg_classify.mech neg > neg.out 2> neg.err
  x=$?
  if [[ $x == 65 && ! -e neg ]] && rg -q -F 'refused negPostulate: a postulate in the runtime' neg.err; then ok "refused definition: exit code 65, no crate"; else bad "refused definition rc=$x"; head -n 4 neg.err | cut -c1-200; fi
  node $O/re.js crate init.mech dup/init.mech col > col.out 2> col.err
  x=$?
  if [[ $x == 65 && ! -e col ]] && rg -q -F 'refused: module name collision (D7): init' col.err; then ok "module name collision: exit code 65, no crate"; else bad "module name collision rc=$x"; head -n 4 col.err | cut -c1-200; fi
  node $O/re.js crate X1.mech stem > stem.out 2> stem.err
  x=$?
  if [[ $x == 65 && ! -e stem ]] && rg -q -F 'refused X1.mech: the file stem must be' stem.err; then ok "bad file stem: exit code 65, no crate"; else bad "bad file stem rc=$x"; head -n 4 stem.err | cut -c1-200; fi
  node $O/re.js crate only > one.out 2> one.err
  x=$?
  if [[ $x == 64 ]] && rg -q -F 'usage: mech rust-out' one.err; then ok "no input file: usage, exit code 64"; else bad "usage rc=$x"; fi
  left=$(fd -I -t d -d 1 'tmp-' . | wc -l | tr -d ' ')
  if [[ $left == 0 ]]; then ok "no temporary directory left"; else bad "$left temporary directories left"; fi
fi
if [[ $mode != emit ]]; then
  # $TMPDIR is not the same with the sandbox off: the run directory comes from a fixed file.
  R=$(< $W/.b4-last)
  cargocho build -- --manifest-path $R/out/Cargo.toml --target-dir ${R:h}/target -j 2 > $R/cbuild.log 2>&1
  x=$?
  if [[ $x == 0 ]]; then ok "cargocho build: $(tail -n 1 $R/cbuild.log | cut -c1-120)"; else bad "cargocho build rc=$x"; head -n 8 $R/cbuild.log | cut -c1-200; fi
  cargocho clippy --warn -- --manifest-path $R/out/Cargo.toml --target-dir ${R:h}/target -j 2 -- -D warnings > $R/clippy.log 2>&1 # [skip-gateledger] the crate is a new temporary directory outside each git tree
  x=$?
  if [[ $x == 0 ]]; then ok "cargocho clippy -D warnings: $(tail -n 1 $R/clippy.log | cut -c1-120)"; else bad "cargocho clippy rc=$x"; head -n 8 $R/clippy.log | cut -c1-200; fi
fi
exit $rc
