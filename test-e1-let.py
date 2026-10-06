#!/usr/bin/env python3
"""Check E1 runner failure handling with an isolated emitter and prelude."""

import os
from pathlib import Path
import subprocess
import tempfile
import unittest


RUNNER = Path(__file__).with_name("e1-let.sh")
ROOT_ASSIGNMENT = "ROOT=/Users/oobi/Documents/mechanism-lang-rust-m0"
CURRENT = "pub fn probe() -> bool {\n    let value = true;\n    value\n}\n"
STALE = CURRENT.replace("true", "false")


class EmitPreludeTests(unittest.TestCase):
    def setUp(self):
        directory = tempfile.TemporaryDirectory(prefix="e1-runner-test-")
        self.addCleanup(directory.cleanup)
        self.root = Path(directory.name)
        self.output = self.root / "e1"
        self.output.mkdir()
        self.prelude = self.root / "prelude" / "init.mech"
        self.prelude.parent.mkdir()
        self.fixture = self.root / "test" / "rust" / "emit" / "let_probe.mech"
        self.fixture.parent.mkdir(parents=True)
        self.fixture.write_text("-- isolated runner fixture\n")
        # This cached driver reads the copied prelude, as the real emitter does.
        (self.output / "re.js").write_text(
            'process.stdout.write(require("node:fs").readFileSync("init.mech", "utf8"));\n'
        )
        (self.output / "init.mech").write_text(STALE)
        source = RUNNER.read_text()
        self.assertEqual(source.count(ROOT_ASSIGNMENT), 1)
        self.runner = self.root / "e1-let.sh"
        self.runner.write_text(source.replace(ROOT_ASSIGNMENT, f"ROOT={self.root}"))

    def emit(self):
        return subprocess.run(
            ["zsh", str(self.runner), "emit", "nobuild"],
            env={**os.environ, "TMPDIR": str(self.root)},
            capture_output=True,
            text=True,
            timeout=30,
        )

    def test_copies_current_prelude(self):
        self.prelude.write_text(CURRENT)
        result = self.emit()
        self.assertEqual(result.returncode, 0, result.stdout + result.stderr)
        self.assertIn("E1-EMIT-OK", result.stdout)
        self.assertEqual((self.output / "let_probe.rs").read_text(), CURRENT)

    def test_failed_copy_cannot_pass_using_stale_prelude(self):
        result = self.emit()
        self.assertNotEqual(result.returncode, 0, result.stdout + result.stderr)
        self.assertNotIn("E1-EMIT-OK", result.stdout)
        self.assertFalse((self.output / "let_probe.rs").exists())


if __name__ == "__main__":
    unittest.main()
