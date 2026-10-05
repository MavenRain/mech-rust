#!/usr/bin/env python3
"""Check runner exit statuses using isolated compiler and gate fixtures."""

import os
from pathlib import Path
import subprocess
import sys
import tempfile


RUNNER = Path(sys.argv[1]) if len(sys.argv) > 1 else Path(__file__).with_name("d2-carrier.sh")
DRIVER = r"""
const fs = require('fs');
const path = require('path');
const fail = process.env.RUNNER_TEST_FAIL;
const out = process.argv.at(-1);
const golden = process.argv.includes('init.mech');
if (path.basename(process.argv[1]) === 'rust_emit.js') {
  if (fail === 'emit' || (golden && fail === 'gold-emit')) process.exit(7);
  fs.mkdirSync(out, {recursive: true});
  if (golden) {
    fs.cpSync(path.join(process.env.MECH_RUST_ROOT, 'test/rust/emit/crate'), out, {recursive: true});
    if (fail === 'gold-diff') fs.writeFileSync(path.join(out, 'unexpected'), 'changed');
  } else {
    fs.writeFileSync(path.join(out, 'mech-carrier.mech'), '-- fixture\n');
  }
} else if (process.argv[3] === path.join(process.env.MECH_RUST_ROOT, 'test/rust/emit/crate')) {
  if (fail === 'gold-accept') {
    fs.mkdirSync(out, {recursive: true});
  } else {
    console.error(fail === 'gold-error' ? 'unexpected failure' : 'MECH-CHECK-FAIL fixture');
    process.exit(fail === 'gold-error' ? 1 : 65);
  }
} else {
  if (fail === 'import') process.exit(9);
  fs.mkdirSync(out, {recursive: true});
  fs.writeFileSync(path.join(out, 'light.mech'), 'fixture\n');
}
"""


with tempfile.TemporaryDirectory(prefix="d2-runner-test-") as temporary:
    root = Path(temporary) / "repo"
    for relative in ("bend2/cli", "bend2/tests", "dev", "prelude/mechanism", "test/rust/seed/05_proofs", "test/rust/emit/crate"):
        (root / relative).mkdir(parents=True)
    (root / "bend2/cli/rust_in.bend").write_text("crate_merged\n")
    (root / "bend2/cli/rust_out.bend").write_text("key_line\n")
    for relative in ("prelude/init.mech", "prelude/mechanism/second-price.mech", "test/rust/seed/05_proofs/light.mech"):
        (root / relative).write_text("fixture\n")
    (root / "test/rust/emit/crate/mech-carrier.mech").write_text("-- fixture\n")
    (root / "driver.js").write_text(DRIVER)
    compiler = root / "bend"
    compiler.write_text('#!/bin/zsh\n[[ $RUNNER_TEST_FAIL == build ]] && exit 3\ncp "$MECH_RUST_ROOT/driver.js" "$3"\n')
    compiler.chmod(0o755)
    for name, failure in (("rt-mech-gate.sh", "rt"), ("rust-in-gate.sh", "ri"), ("rust-out-diff-exec.sh", "exec")):
        (root / "dev" / name).write_text(f'#!/bin/zsh\n[[ $RUNNER_TEST_FAIL == {failure} ]] && exit 4\nexit 0\n')

    cases = [(mode, "", True) for mode in ("smoke", "golden", "gates", "exec", "all")]
    cases += [("gates", failure, False) for failure in ("rt", "ri")]
    cases += [("exec", "exec", False)]
    cases += [(mode, failure, False) for mode in ("smoke", "all") for failure in ("build", "emit", "import")]
    cases += [(mode, failure, False) for mode in ("golden", "all") for failure in ("gold-emit", "gold-diff", "gold-accept", "gold-error")]
    for index, (mode, failure, succeeds) in enumerate(cases):
        env = dict(os.environ, MECH_RUST_ROOT=str(root), BEND=str(compiler), D2_WORK=str(Path(temporary) / str(index)), RUNNER_TEST_FAIL=failure)
        result = subprocess.run(["zsh", str(RUNNER.resolve()), mode], env=env, capture_output=True, text=True, timeout=30)
        assert (result.returncode == 0) == succeeds, f"{mode}/{failure}: rc={result.returncode}\n{result.stdout}\n{result.stderr}"
    print(f"RUNNER-OK {len(cases)} exit-status cases")
