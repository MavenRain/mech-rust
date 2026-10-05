#!/usr/bin/env python3
"""Regression checks for the D1 workflow using freshly compiled JS drivers."""

import argparse
import os
from pathlib import Path
import subprocess
import sys
import tempfile


def compiler(path, drivers, behavior):
    path.write_text(
        f"#!{sys.executable}\n"
        "from pathlib import Path\nimport sys\n"
        f"drivers = Path({str(drivers)!r})\n"
        "source, flag, output = sys.argv[1:]\nassert flag == '-o'\n"
        "name = 'rust_import.js' if source.endswith('rust_import.bend') else 'rust_emit.js'\n"
        + (
            "sys.exit(23)\n"
            if behavior == "build-fail"
            else "Path(output).write_text('process.exit(0);')\n"
            if behavior == "no-manifest"
            else "text = (drivers / name).read_text()\n"
            + (
                "if name == 'rust_import.js':\n"
                "    text = \"const r = require('node:child_process').spawnSync(process.execPath, ['--stack-size=16384', \" + repr(str(drivers / name)) + \", ...process.argv.slice(2)], {stdio: 'inherit'}); process.exit(['seed-check', 'rt-mech'].includes(process.argv[2]) ? 1 : (r.status ?? 1));\"\n"
                if behavior == "mode-fail"
                else ""
            )
            + "Path(output).write_text(text)\n"
        )
    )
    path.chmod(0o700)


def run_case(root, drivers, temporary, name, behavior, script, expected_code, markers):
    case = temporary / name
    case.mkdir()
    fake_bend = case / "bend"
    compiler(fake_bend, drivers, behavior)
    work = case / "work"
    work.mkdir()
    for driver in ("rust_import.js", "rust_emit.js"):
        (work / driver).write_text("process.exit(0);\n")
    environment = dict(os.environ, BEND=str(fake_bend), RT_WORK=str(work), D1_WORK=str(work))
    result = subprocess.run(
        ["zsh", str(script)], cwd=root, env=environment, stdin=subprocess.DEVNULL,
        capture_output=True, text=True, timeout=180,
    )
    output = result.stdout + result.stderr
    if result.returncode != expected_code or any(marker not in output for marker in markers):
        raise AssertionError(f"{name}: exit={result.returncode}\n{output}")
    if behavior == "normal" and output.count("PASS ") != 24:
        raise AssertionError(f"{name}: expected all 24 probe steps\n{output}")
    print(f"PASS {name}")


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--root", type=Path, default=Path(__file__).resolve().parent.parent / "mechanism-lang-rust-m0")
    parser.add_argument("--drivers", type=Path, required=True, help="directory with freshly compiled rust_import.js and rust_emit.js")
    parser.add_argument("--probe", type=Path, default=Path(__file__).resolve().parent / "d1-seed.sh")
    args = parser.parse_args()
    root, drivers, probe = args.root.resolve(), args.drivers.resolve(), args.probe.resolve()
    for driver in ("rust_import.js", "rust_emit.js"):
        if not (drivers / driver).is_file():
            parser.error(f"missing driver: {drivers / driver}")
    with tempfile.TemporaryDirectory(prefix="d1-workflow-") as directory:
        temporary = Path(directory)
        run_case(root, drivers, temporary, "rebuild-stale-drivers", "normal", probe, 0, ["D1-PROBE-OK"])
        run_case(root, drivers, temporary, "reject-checker-exit-error", "mode-fail", root / "dev/rt-mech-gate.sh", 1, ["FAIL SEED-CHECK", "FAIL RT-MECH", "ROUND-TRIP-FAIL"])
        run_case(root, drivers, temporary, "reject-cached-build-error", "build-fail", probe, 1, ["FAIL build rust_import"])
        run_case(root, drivers, temporary, "reject-missing-manifest", "no-manifest", probe, 1, ["FAIL MANIFEST", "D1-PROBE-FAIL"])
    print("D1-WORKFLOW-OK")


if __name__ == "__main__":
    main()
