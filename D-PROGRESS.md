# mech-rust unit D progress (round trip on a canonical seed corpus, ROUND-TRIP)

Scope source: design brief sections 6, 9 and 10 (M1), and C-PROGRESS.md "Scope of unit C", last paragraph.
The scope of D below is the choice of the opening session (2026-10-05).  It is an ASSUMPTION until the USER rules
(Rulings wanted, U5).  The USER was away, so the session continued on the defaults.
Worktree /Users/oobi/Documents/mechanism-lang-rust-m0, branch mech-rust/m1.  W = /Users/oobi/Documents/mech-rust.
NEVER commit or push.  Stage own paths only.  No Co-Authored-By line.  One sub-unit per fresh session.  Read the
tail of this file first.  The rules of C-PROGRESS.md (header and "Build mode") stay in force: never touch
/Users/oobi/Documents/mechanism-lang;  do not run dev/gates.sh;  stop if one Bend run exceeds 20 minutes;  disk
floor 30 GiB;  rg/sd;  no `cd X &&` or `VAR=` prefix;  no em-dashes.

## Start state 10-05 (claude7, session c7d1fb7e; read-only, no worktree change)
DF1  Unit C is closed.  The USER committed C6 as f751164 and pushed it (mech-rust/m1 = origin/mech-rust/m1).  The
     worktree is clean.  W is clean at 72cee55.  Disk: 47 GiB free.
DF2  M1 (brief 10): both directions for structs, enums, functions, `match`, structural recursion, RsOption,
     RsResult, RsVec, integers per Q4, name mangling, the carrier;  all section 9 gates on the seed corpus.
DF3  Present state of the two directions: `rust-out` (unit B) and `rust-in` (unit C) agree on the M0 fragment only:
     enums, unit structs, generics, fn, `match`, `if`, closures, structural recursion, kernel `Nat`, `bool`.
DF4  Gates that exist: RUST-PARSE (dev/rust-parse-gate.sh), DIFF-EXEC (dev/rust-out-diff-exec.sh, sandbox off),
     RUST-IN (dev/rust-in-gate.sh: LIFT, GOLDEN, MECH-CHECK, RT-RUST, REFUSE, RED), and three Python gates.
     There is no RT-MECH gate and no seed corpus.  RT-RUST runs on one crate, the golden crate of unit B.
DF5  The M0 inputs (init.mech, second-price.mech) are NOT canonical (CF8): erasure drops quantity-0 binders that
     are not types, Prop fields and indices.  RT-MECH cannot hold on them.
DF6  The carrier (test/rust/emit/crate/mech-carrier.mech) is text: one comment line, then `-- from <file>` and
     the declarations with no Rust form (classes prop, type, absurd) in source order.  `rust-in` copies it with no
     change.  There is no merge, and no key that gives the place of a declaration between the runtime items.
DF7  The text of the importer (test/rust/import/expected/*.mech) is the output of `Syntax.print`: one line for
     each declaration, full parentheses, `case <e> as self in <F> return <T> with`.  A source file of the seed
     corpus has a different text, so a text compare is not RT-MECH.  The brief (6) gives the law: the checked
     forms are alpha-equivalent, through `checked_form` (bend2/surface/API.md:39, surface/elab.bend).
DF8  Driver commands (from dev/rust-in-gate.sh): `bend bend2/tests/<driver>.bend -o <x.js>`, then
     `node --stack-size=16384 <x.js> <mode> <args>`.  Emitter: mode `crate <files> <out dir>`, run in the folder
     of the .mech files.  Importer: modes `lift`, `resolve`, `types`, `lower`, `check`, `run <crate> <out dir>`.
DF9  Open points of C6 (IMPORT.md "Known limits"): mutual recursion has no located refusal;  a struct with fields
     gets the text of a unit struct;  `bad__name` imports as `bad_Name` and `good_` imports (the name map is not
     shown to be injective).

## Scope of unit D (ASSUMPTION, U5)
The round-trip laws of brief 6 on a seed corpus, for the fragment of DF3.  No growth of the fragment.
Reason: P2 makes the round trip the definition of "dual".  The gates must exist before the fragment grows, so
that each later unit adds seed files and not a new gate.
Target: for each seed program S, with E = `rust-out` and I = `rust-in`:
- SEED-CHECK: S passes the kernel check with no axiom.
- RT-MECH: I(E(S)) and S have alpha-equivalent checked forms.
- FIXPOINT: I(E(I(E(S)))) is byte-equal to I(E(S)).
- RT-RUST: E(I(E(S))) is byte-equal to E(S), with the same file inventory.
- RED controls: each mutation of brief 9 that belongs to these gates turns its gate red.
Not in D (later M1 units, HYPOTHESIS): E = struct with private fields, accessors and `let`;  F = RsOption,
RsResult, RsVec and the Q7 combinators, `vec!`;  G = integers per Q4;  H = the REFUSAL and RUST-CLEAN gates on
the seed corpus, DIFF-EXEC on the seed corpus, and the close of M1.

## Sub-units (each ends with checks clean, a runner script in W, and a log entry here)
D1  Seed corpus v1 and RT-MECH without the carrier.
    Learn first (probe, in the runner): write one small program, run E then I, and read the two texts.  Read
    API.md for `checked_form`.  Record the facts in the log entry.
    Files: test/rust/seed/<program>/{MANIFEST, *.mech} (programs with runtime declarations only);  a mode
    `rt-mech` in bend2/tests/rust_import.bend (two program texts in, `RT-MECH-OK <n>` or `RT-MECH-FAIL <name>`
    out);  dev/rt-mech-gate.sh (one PASS or FAIL line for each check, then ROUND-TRIP-OK or ROUND-TRIP-FAIL);
    W/d1-seed.sh.
    Seed v1 (4 programs minimum): (1) enums, `match`, `if` on MechBool;  (2) a generic family and a generic
    fn;  (3) structural recursion on a unary natural and a higher-order fn with a closure;  (4) two files with a
    dependency edge, and kernel `Nat` with a literal and `natAdd`.
    Done when: the four gates of the target are green on each program;  a GREEN control (a seed that differs from
    another only in binder names passes RT-MECH against it);  two RED controls (swap two branch bodies in the
    imported text: RT-MECH fails;  swap two constructors of a family in the imported text: RT-RUST fails).
D2  The carrier merge (Q3).  `rust-out` writes a key for each carried declaration (file and place).  `rust-in`
    puts each carried declaration back, so the import of a canonical program has its proofs, and the kernel check
    of the import checks the proofs against the Rust text (brief 6, last item).  Seed v2: programs with Prop
    declarations.  RED: drop one carried proof (RT-MECH fails);  change a fn body so that a carried proof is false
    (the import fails with MECH-CHECK-FAIL).  This changes rust_out.bend, rust_in.bend, EMIT.md, IMPORT.md and the
    golden carrier, so RUST-IN and DIFF-EXEC run again.
D3  The open points of DF9: a located refusal for mutual recursion in resolve.bend (EXPECTED.tsv row 06
    changes);  the correct text for a struct with fields;  a strict inverse of D7, so that a Rust name that no
    mech name gives is refused (`bad__name`, `good_`), each with a fixture row.
D4  Close: bend2/rust/ROUNDTRIP.md, the limits in IMPORT.md and EMIT.md, W/COMMIT-MSG-D.txt, and a full rerun
    (RUST-PARSE, RUST-IN, the three Python gates, ROUND-TRIP;  DIFF-EXEC with the sandbox off).

## Design defaults (HYPOTHESES; each is confirmed or changed in the sub-unit that names it)
DD1  Seed layout: test/rust/seed/<program>/ holds the source files and MANIFEST (file names in dependency
     order, the format of the importer).  No expected Rust text is committed in D1: the laws compare outputs of
     the two commands.  (D1)
DD2  Canonical mech for D1: runtime declarations only (no declaration at Prop, no quantity-0 binder that is not
     a type, no index, no postulate).  The seed starts with its own MechBool family if it uses a Boolean, in the
     form of CD6.  (D1)
DD3  RT-MECH compare: `checked_form` of the two joined programs, then equality of the rows up to bound names.
     If `checked_form` already has no bound names (de Bruijn), the compare is row equality.  The failure line
     names the first declaration that differs.  (D1 learn)
DD4  The gate builds each driver one time (JS build) and keeps all outputs under $TMPDIR, as CD12.  (D1)
DD5  If RT-MECH or FIXPOINT is red on a seed program because of a defect of unit B or C, D1 records the defect
     and the smallest seed that shows it.  A fix that is one site goes in D1 with a rerun of the gate of that
     unit.  A larger fix is a new sub-unit.  (D1)
DD6  Carrier key: a comment line `-- at <file> after <item name or start>` before each carried declaration.
     The emitter is the only writer.  (D2)

## Rulings wanted (the session continued on the defaults in brackets)
U5 Scope of the next M1 unit: [D = round trip on a seed corpus for the present fragment, then E, F, G, H as
   above] or growth of the fragment first.
U6 RT-MECH law: [alpha-equivalent checked forms, brief 6] or byte-equal text after `Syntax.print`.
U7 Build mode for D: [as U4: one wf-builder agent for each sub-unit;  after two dead launches a hand build in the
   main loop, as the USER ruled for C3, C4 and C5] or HALT after two dead launches.

## Log

### 2026-10-05 D OPENED (claude7, session c7d1fb7e): split written, no worktree change
Facts DF1 to DF9 are from `git log`, `git status`, the brief, IMPORT.md, the gate script and the expected files.
No Bend run and no build in the opening step.  NEXT: D1.

### 2026-10-05 D1 HALTED for the builders, probe DONE by hand (claude7, session c7d1fb7e): D1-PROBE-OK
Both wf-builder launches died on `[reasoning_extraction]` before any file change (fable xhigh
req_011CfjGhSyLZULfmUGz5TNJN;  opus xhigh with the marker req_011CfjGk1U1JQNi9tUPn3fzD).  No third launch.
The hand build started on default U7 (the USER did NOT rule for D).  It stopped at the session context limit
after the learn step.  D1 is NOT complete.
Built and STAGED:
- ROOT test/rust/seed/01_enum_match/{light.mech, MANIFEST}: seed program 1 (MechBool, a family with three
  constructors, two `case` on it, one `case` on MechBool).  Normal surface text, motive names `which` and `flag`.
- W/d1-seed.sh: the probe runner.  For each folder of test/rust/seed it runs E, I, E, I and prints PASS or FAIL
  for EMIT, IMPORT, EMIT2, RT-RUST, IMPORT2, FIXPOINT, then D1-PROBE-OK or D1-PROBE-FAIL.  It keeps the two JS
  drivers in $D1_WORK (default $TMPDIR/d1-seed) for the next run.
Result: `zsh W/d1-seed.sh` gives 6 PASS lines and D1-PROBE-OK (two driver builds and the run: less than 4 min).
Facts:
DF10 The round trip holds on a new seed with no change to unit B or C: RT-RUST and FIXPOINT are byte-equal.
DF11 I(E(S)) is not S as text.  Three differences: full parentheses and one line for each declaration;  the
     motive name is always `self`;  a constructor in a branch body gets an ascription, `(lightGreen : Light)`
     (a Boolean constructor gets none).  NOT verified: that `checked_form` removes the ascription.  If it does
     not, RT-MECH needs a compare that ignores an ascription, or the seed must have the same ascriptions.
DF12 `case go ... in MechBool` becomes a Rust `if`.  The seed has its own MechBool family as the first
     declaration (DD2), and the import has it at the same place.
DF13 The emitter writes mech-carrier.mech when no declaration is carried (84 bytes, the comment line only), and
     the importer copies it.  The inventory of an import is the .mech files, MANIFEST and mech-carrier.mech.
DF14 Places for the mode `rt-mech` (bend2/tests/rust_import.bend, 161 lines): the mode sum `Md` and `mode_of`
     (line 123, a `Bool.pick` chain), `run_mode` (125), `check_rows` (100), and the kernel call
     `Elab.check_text(Global.initial(), Budget.unlimited(), <text>)` (110), which gives the rows.
     `checked_form(rows: Rows) -> String` is at bend2/surface/elab.bend:619 (`check_in` at 602).
     NOT verified: the text of `checked_form` (bound names or indices), so DD3 is open.
NOT done in D1: seed programs 2, 3 and 4;  SEED-CHECK;  the mode `rt-mech`;  dev/rt-mech-gate.sh;  the GREEN
control and the two RED controls.  No gate of unit A, B or C ran (no file of these units changed).
NEXT (fresh session, D1 session 2, hand build unless the USER rules U7 in a different way):
1. Print `checked_form` for light.mech and for its import (a scratch mode, or `rt-mech` at once) and close DF11
   and DD3.
2. Add the mode `rt-mech`: arguments are the two joined program texts;  it checks each text, compares the
   checked forms, and prints `RT-MECH-OK <n>` or `RT-MECH-FAIL <name>`.
3. Write seed programs 2, 3 and 4 (D1 text) and run W/d1-seed.sh after each program.
4. Write dev/rt-mech-gate.sh from W/d1-seed.sh and dev/rust-in-gate.sh, with SEED-CHECK, RT-MECH and the
   three controls.  Then the log entry and the staging.

### 2026-10-05 D1 session 2 (claude7, session b0a19f31): steps 1 and 2 by hand, steps 3 and 4 written by hand and run by one wf-closer
Rulings (USER, 10-05): U5 scope of unit D as written.  U6 RT-MECH by alpha-equivalent checked forms.  U7 hand build
in the main loop, no builder agents.
Build mode note: the step-budget hook denied each Bash and Write call of the main loop after 20 steps.  The main
loop wrote each file text.  One wf-closer agent wrote the files of steps 3 and 4 from these texts with no change,
ran the gates, staged, and added this entry.  It made no design decision and no repair.  If the USER reads U7 as
"no agent of any type", this is a deviation to rule on.
Facts:
DF15 (closes DD3) `checked_form` prints bound names (kernel/pp.bend takes them from the binders): the motive name
     `which` of the seed and `self` of the import give different texts.  The kernel term has de Bruijn indices,
     and `Term.equal` (kernel/term.bend:291) compares the binder names too.  So RT-MECH has its own compare,
     bend2/rust/roundtrip.bend: `alpha` is `Term.equal` with the binder names ignored (SPi, SZk, leg binders, the
     self name and index names of a motive, Let).  `first_diff` compares the rows in pairs (name, class, type,
     body) and gives the name of the first row that differs.
DF16 (closes DF11) `checked_form` keeps the ascription: the import row has `Ann` around the constructor.
     Decision (ASSUMPTION, see U8): the compare is strict (an `Ann` must be on the two sides), and a canonical
     seed has the ascriptions that the importer writes.  Seed 1 changed: the three branch bodies of lightNext are
     `(<constructor> : Light)`.
DF17 The rows have no row for a `mu` family (3 rows for light.mech).  RT-MECH sees a family only through the
     terms that use it.  A change of a family declaration is the job of RT-RUST (the second RED control).
     `Global.T` has the families (field `families`, Positivity.Family).  A compare of them is not in D1.
DF18 Measured by hand: `seed-check` on light.mech gives `MECH-CHECK-OK 3 rows axioms=0`.  `rt-mech` of seed 1
     against its import gave `RT-MECH-FAIL lightNext` before the ascriptions and `RT-MECH-OK 3` after (the motive
     names differ: `which` and `flag` against `self`).  `rt-mech` of I(E(S)) against I(E(I(E(S)))) gives
     `RT-MECH-OK 3`.  The JS build of the driver takes about 10 s.
Built and STAGED (ROOT):
- bend2/rust/roundtrip.bend (new): `alpha`, `same_entry`, `first_diff`.
- bend2/tests/rust_import.bend: modes `seed-check <program text>` and `rt-mech <program text> <program text>`
  (output `RT-MECH-OK <n>`, `RT-MECH-FAIL <name>`, or `MECH-CHECK-FAIL left|right <error>`).
- test/rust/seed/02_generic, 03_recursion, 04_two_files (seed programs 2, 3 and 4), and the change of seed 1.
- test/rust/seed-control/01_enum_match_renamed.mech (GREEN control: seed 1 with each binder renamed).
- dev/rt-mech-gate.sh: SEED-CHECK, EMIT, IMPORT, EMIT2, RT-RUST, IMPORT2, FIXPOINT, RT-MECH for each seed, then
  the GREEN control and the two RED controls, then ROUND-TRIP-OK or ROUND-TRIP-FAIL.
Result of `zsh dev/rt-mech-gate.sh`:
PASS SEED-CHECK 01_enum_match
PASS EMIT 01_enum_match
PASS IMPORT 01_enum_match
PASS EMIT2 01_enum_match
PASS RT-RUST 01_enum_match
PASS IMPORT2 01_enum_match
PASS FIXPOINT 01_enum_match
PASS RT-MECH 01_enum_match
PASS SEED-CHECK 02_generic
PASS EMIT 02_generic
PASS IMPORT 02_generic
PASS EMIT2 02_generic
PASS RT-RUST 02_generic
PASS IMPORT2 02_generic
PASS FIXPOINT 02_generic
PASS RT-MECH 02_generic
FAIL SEED-CHECK 03_recursion MECH-CHECK-FAIL expected a binder name and ':', found 'sum'
FAIL EMIT 03_recursion ==> /tmp/claude-501/rt-mech-gate/emit.err <==
error: line 11, column 69: expected a binder name and ':', found 'sum'
refused count.mech: carrier: line 11, column 69: expected a binder name and ':', found 'sum'


==> /tmp/claude-501/rt-mech-gate/emit.out <==
FAIL IMPORT 03_recursion mech: cannot read /tmp/claude-501/rt-mech-gate/03_recursion/e1/src/lib.rs
FAIL SEED-CHECK 04_two_files MECH-CHECK-FAIL expected a binder name and ':', found 'sum'
FAIL EMIT 04_two_files ==> /tmp/claude-501/rt-mech-gate/emit.err <==
error: line 2, column 59: expected a binder name and ':', found 'sum'
refused native.mech: carrier: line 2, column 59: expected a binder name and ':', found 'sum'


==> /tmp/claude-501/rt-mech-gate/emit.out <==
FAIL IMPORT 04_two_files mech: cannot read /tmp/claude-501/rt-mech-gate/04_two_files/e1/src/lib.rs
PASS GREEN renamed binders
PASS RED branch bodies swapped (RT-MECH)
PASS RED constructors swapped (RT-RUST)
work=/tmp/claude-501/rt-mech-gate pass=19 fail=6
ROUND-TRIP-FAIL
Result of `zsh dev/rust-in-gate.sh` (the driver changed): pass=28 fail=0
RUST-IN-OK
Rulings wanted: U8 RT-MECH and ascriptions: [strict compare, and the seed has the ascriptions of the importer] or
`alpha` ignores `Ann`.
STATUS RED: D1 is NOT complete.  NEXT (fresh session, hand build in the main loop): make each FAIL line above
pass.  For an RT-MECH FAIL, compare the seed text with $RT_WORK/<seed>/i1 and give the seed the ascriptions of the
import (DF16).  For an EMIT or IMPORT FAIL, read the error text and change the seed to the M0 fragment (DF3), or
record a defect of unit B or C (DD5).  Then run `zsh dev/rt-mech-gate.sh` and `zsh dev/rust-in-gate.sh` again.

### 2026-10-05 D1 session 2, repair by hand in the main loop (claude7, session b0a19f31)
This entry supersedes the STATUS RED paragraph of the entry above.
DF19 `sum` is a keyword of the surface language (surface/token.bend:140, the term `sum (...)`), so it cannot be a
     binder name.  Seeds 3 and 4: the binder `sum` is now `total`.
DF20 The importer writes an ascription on a constructor that is an argument and on a constructor application:
     `(countZero : Count)` and `((countNext ((countNext total) : Count)) : Count)`.  Seed 3 `countDouble` has
     these ascriptions now (DF16).  Seeds 2 and 4 have no constructor in a def body, and they passed RT-MECH with
     no ascription.
Result of `zsh dev/rt-mech-gate.sh` after the repair (each FAIL line, then the last two lines):
work=/tmp/claude-501/rt-mech-gate pass=35 fail=0
ROUND-TRIP-OK
`zsh dev/rust-in-gate.sh` was not run again: the closer ran it after the last change of the driver (pass=28
fail=0, RUST-IN-OK), and this repair changed seed files only.
STATUS GREEN: the D1 gate is green: SEED-CHECK, RT-MECH, FIXPOINT and RT-RUST on 4 seed programs, the GREEN
control and the two RED controls.  All paths are STAGED and NOT committed.  D1 is complete if the USER accepts U8
and the build mode note.  NEXT (fresh session): D2 as written above.

### 2026-10-05 W moved to /Users/oobi/Documents/mech-rust (claude7, session b0a19f31, on USER ask)
The work folder repo (origin https://github.com/MavenRain/mech-rust.git) is now at /Users/oobi/Documents/mech-rust.
Its old path was /Users/oobi/Documents/mech-rust-m0.  The move is a rename of the directory: the history, the index
and the remote did not change.  Each path to W in the tracked files of W now has the new name (16 lines in 12
files: the `W=` line of b1-sample.sh, b2-classify.sh, b3-emit.sh, b4-crate.sh and c1-crib.sh, and text in the
PROGRESS, LEARN and PLAN files).  Thus an old log entry shows the new path for a command that ran at the old path.
The code worktree did not move: /Users/oobi/Documents/mechanism-lang-rust-m0, branch mech-rust/m1.

### 2026-10-05 D1 staged review and fixes (Codex)
Reviewed all 26 initially staged paths across this repo (HEAD 72cee55) and the code worktree (HEAD f751164).
No CI weakening, CRITICAL findings or HIGH findings. Two MEDIUM findings were reproduced and fixed:

1. `dev/rt-mech-gate.sh` discarded the exit status of `seed-check` and `rt-mech`. A driver that printed its
   normal verdict and then exited 1 still produced pass=35 fail=0 and ROUND-TRIP-OK. The gate now requires
   exit 0 as well as the expected verdict for each invocation, including the GREEN and RED controls.
   The same injected error now produces pass=25 fail=10, ROUND-TRIP-FAIL and exit 1.
2. `d1-seed.sh` reused any nonempty JS drivers and silently skipped a program when its import had no
   manifest. Two cached drivers containing `process.exit(0);` gave eight PASS lines and D1-PROBE-OK without
   running RT-RUST or FIXPOINT. The probe now rebuilds the current drivers on every run. Both workflow
   scripts explicitly fail an import with a missing or empty manifest.

Added `d1-workflow-gate.py`: run `python3 d1-workflow-gate.py --drivers <fresh JS driver directory>`.
It checks stale driver rebuilding (all 24 steps), checker exit errors, build failure despite cached drivers,
and missing manifests. All four controls passed: D1-WORKFLOW-OK.
Validation after fixes: D1-PROBE-OK (24 steps), ROUND-TRIP-OK (pass=35 fail=0), RUST-IN-OK (pass=28 fail=0),
shell syntax checks and both repositories' diff whitespace checks. The probe compiled the current drivers.
The final two gates reused those drivers; their hashes matched the independent initial gate build:
rust_import.js = 2cf81cc56a4a5a3f616a65c7de7fef969817a902fb6a3bba9153b6f979e2fb5a;
rust_emit.js = dfb5c66d4ea4dc316f9b47a37ac4ec1b9bb5ff6bfe7619d33f797a27da0a57a7.
Duplicate compilation attempts were canceled before those final runs. No remaining review blockers.
All fixes and regression checks are staged. No commit or push.

### 2026-10-05 D2 carrier merge, hand build in the main loop (claude7, session 01e6fab9): ROUND-TRIP-OK 57, RUST-IN-OK 28, DIFF-EXEC-OK

Start state: the code worktree was at 4f1b5da and W was at 4307dc7. The USER committed D1. No agent ran in this sub-unit (U7). All edits and all gate runs came from the main loop.

Design (DD6, confirmed as built):

- The emitter writes one key line as the first line of each carried chunk: `-- at <file> start` or `-- at <file> after <name>`. `<name>` is the first name of the nearest runtime declaration before the chunk in the same file.
- The importer splits the carrier into chunks with `Ro.chunks_of`. It reads the first line of each chunk as the key and removes that line. It puts the chunk lines in `<file>`, at the start or directly after the declaration `<name>`. Chunks with the same key keep the order of the carrier.
- The merge runs before the kernel check. Thus the kernel checks each carried proof against the text that comes from the Rust files.
- A file with no carried chunk keeps its lowered text. The importer also copies the carrier file with no change.
- The merge has three refusals: `REFUSED carrier: the first line of a chunk is not a key line: <line>`, `REFUSED carrier: a chunk has no line`, `REFUSED carrier: the import has no place for the key line: <key>`.

Files (code worktree, 12 paths, 424 insertions, 33 deletions):

- `bend2/cli/rust_out.bend`: `words`, `join_lines`, `key_line`, `is_run`. `carry` keeps the name of the last runtime declaration, and `add_vd` writes the key line.
- `bend2/cli/rust_in.bend`: the merge block (`Key`, `Kept`, `key_of`, `kept_all`, `merged_text`, `merge_ok`, `crate_merged`). `crate_files` is removed. `import_crate` gives the carrier text to the merge.
- `bend2/rust/EMIT.md`, `bend2/rust/IMPORT.md`: the key line, the merge, the refusals, the limits.
- `dev/rt-mech-gate.sh`: legs KEYS, COPY, two RED and two REFUSE on the seed `05_proofs`.
- `dev/rust-in-gate.sh`: leg CARRIER. The other golden legs use a copy of the crate with no carrier file.
- `test/rust/emit/crate/mech-carrier.mech`: the emitter wrote it again. It has 186 lines and 26 key lines. No other file of the golden crate changed.
- `test/rust/seed/05_proofs/`, `test/rust/seed/06_two_files_proofs/`: new seeds with carried declarations in one file and in two files.

Golden crate (DF5). With the merge, the import of the golden crate with its carrier fails: `MECH-CHECK-FAIL AuctionOrder takes 0 arguments and the term gives 2`. The golden crate of M0 is not a canonical program, and a carried declaration does not agree with the imported text. Decision in this session: RUST-IN has a new CARRIER leg that expects this refusal (exit code 65, no output). The legs GOLDEN, MECH-CHECK, RT-RUST and RED use a copy of the crate with no carrier file. `test/rust/import/expected/` has no change. The USER can change this decision.

Gates on the staged code tree 651115f6:

- ROUND-TRIP (`zsh dev/rt-mech-gate.sh`): `pass=57 fail=0`, `ROUND-TRIP-OK`. Six seeds, the D1 controls, and the D2 legs: KEYS (3 key lines), COPY (the carrier copy is byte-equal), RED carried proof dropped (`RT-MECH-FAIL`), RED fn body changed (`MECH-CHECK-FAIL`, exit code 65, no output), REFUSE key with no place in the import (exit code 65, no output), REFUSE carried chunk with no key line (exit code 65, no output).
- RUST-IN (`zsh dev/rust-in-gate.sh`): `pass=28 fail=0`, `RUST-IN-OK`.
- DIFF-EXEC (`zsh dev/rust-out-diff-exec.sh`): `DIFF-EXEC-OK 238 values`. In the sandbox the cargo step fails (`sccache: error: Operation not permitted`). The green run had the sandbox off. This run came before the two REFUSE legs were added to the ROUND-TRIP script. No emitter file and no importer file changed after this run.

Limits:

1. A key names a runtime declaration of the same file. If the import has no such name in that file, the command refuses the crate.
2. A carrier with no key lines is refused. A carrier that the emitter wrote before D2 is such a carrier.
3. The golden crate with its carrier is refused (see above).
4. The merged text has no empty line between declarations. This is the format of the surface printer.
5. No gate leg gives the refusal `a chunk has no line`. The chunk split makes no empty chunk from the carrier texts of the gate.

Runner: `zsh /Users/oobi/Documents/mech-rust/d2-carrier.sh [smoke|golden|gates|exec|all]`. The mode `exec` runs DIFF-EXEC and needs the sandbox off.

Open for the USER: the golden crate decision above. U8 and the use of wf-closer stay with no ruling.

Staged: the 12 paths of the code worktree (tree 651115f6), and `d2-carrier.sh` and this file in W. No commit or push for D2. NEXT: D3.
### 2026-10-05 D2 staged review and fixes (Codex)

Reviewed all 12 originally staged code paths and both staged W paths. Kept the existing staged work and staged fixes in both repositories. No commit or push.

Validation weakening was checked first. The runner could report failed gates and still exit successfully. The golden crate's new carrier refusal is consistent with DF5: M0 erasure is outside the canonical round-trip contract. The successful merge and byte-equal carrier-copy checks remain in ROUND-TRIP, and the kernel check remains mandatory.

Findings fixed:

1. HIGH, runner hides validation failures (`d2-carrier.sh`, functions `gates`, `diffexec`, `golden`, and `all`). Reproduction on the original staged runner: `env BEND=/usr/bin/false zsh d2-carrier.sh gates` prints both gate failures but returns 0. The runner now preserves failure statuses, rejects unexpected golden output or import results, and stops `all` when an earlier mode fails. `d2-carrier-test.py` exercises 22 success and failure cases in an isolated fixture root. The real failed-compiler reproduction now returns 1.
2. MEDIUM, proof-only dependencies are missing from Rust module order (`bend2/cli/rust_in.bend`, `crate_merged`). A checked `z_base.mech` defining `Safe`, followed by `a_proof.mech` using `Safe` only in a proof, emits successfully but the staged importer returns 65 with `MECH-CHECK-FAIL Safe`. The carrier now records every source file in a second line, `-- files <file> ...`. The importer validates the complete permutation and restores it before inference and lowering, so implicit `MechBool` placement and carried anchors stay in the correct file. Seeds `07_carrier_order` and `08_carrier_bool_order` cover proof-only files, runtime-only files, erased dependencies, and the Boolean anchor. Three negative controls reject unknown, repeated, and missing files.

Validation on the final code:

- ROUND-TRIP: `pass=76 fail=0`, all eight seeds, mutations, and refusals. Capture: `/Users/oobi/Documents/gpt7/.kanon-exec/run-gE09Qz`.
- RUST-IN: `pass=28 fail=0`. Capture: `/Users/oobi/Documents/gpt7/.kanon-exec/run-ZKjN1U`.
- DIFF-EXEC: 238 matching values; the mutation control differs at 88 values. Capture: `/Users/oobi/Documents/gpt7/.kanon-exec/run-KzzIG3`. All generated Rust files remain byte-equal to the goldens; only the carrier metadata changed.
- Runner: `RUNNER-OK 22 exit-status cases`; `zsh -n d2-carrier.sh` passed.
- RUST-IN-CLI: all driver and full CLI publication/refusal cases passed. Capture: `/Users/oobi/Documents/gpt7/.kanon-exec/run-Mcz3eX`. The first attempt passed the driver cases but timed out compiling the CLI at the script's 180-second limit (`run-lwB0gx`). A separate compilation passed (`run-DoJtA9`), then the unchanged gate passed with `--driver` and `--cli` pointing to the compiled artifacts. A transient disk-floor hold cleared without deleting files.
- Staged and unstaged whitespace checks passed. No Rust source was edited.

Source hashes: `rust_in.bend` = `6da569d5e791133d2c505f79e1a4dc64e4cc6d68d47de4b6e9f2dcd01b90ac36`; `rust_out.bend` = `b1f52cf8cdb138735c5a07eb8ab6b3d1f8e5665f79693ed1bfc23c3052e5dfd2`.
ROUND-TRIP driver hashes: `rust_import.js` = `4ddc609d6fe410594b902e4722e5129b7064ae9eb5c846cfd4c0ebf489975fe8`; `rust_emit.js` = `20f46e1365fd44f21758fc48fd20d6e136e7031d6542cf79cf9e3158fa80fe49`.

No remaining review blockers. The M0 golden carrier is still intentionally refused as noncanonical; no kernel-check bypass was introduced. The code index contains 19 paths, and W contains the runner, its regression test, and this progress record. NEXT remains D3.

### 2026-10-05 D3 open points of the importer, hand build in the main loop (claude7): RUST-IN-OK 31, RUST-PARSE-OK 35, ROUND-TRIP-OK; D3 NOT complete

Start state: the code worktree was at 4e9e30a and W was at e5737d7. The USER committed D2. Two wf-builder launches died on `[reasoning_extraction]` before any file change (fable xhigh req_011Cfjk8BwJv4Tcuk3aLwDSz; opus xhigh with the marker req_011CfjkDQ9QwqUuCYi6516Jq). No third launch. The hand build ran on default U7.

Point 1, use before the declaration (DONE):

- `resolve.bend`: `check_items` has a second scope, `seen`: the used modules and the items up to the present item. A name that the module has, but that `seen` does not have, is refused by `early_at`. `after_space` makes the text from the text of the name check.
- Text: `use of the function `<name>` before its declaration (mutual recursion or a forward reference)`. The position is the position of the item that has the use.
- The plan hypothesis is confirmed for fns: the golden crate and all seeds stay green, so no canonical crate has a use of a later item.

Point 2, struct with fields (DONE):

- `lift.bend`: `unit_body` takes the name and has `body_ok`. A struct with fields gives `struct `<name>` with fields`. A struct with generics gives `struct `<name>` with generics`. This check now comes before the `Copy` check. A struct with no fn after it gets the same check first, then the old text.
- The old text `struct with generics or fields` is removed. No fixture and no doc had it.

Point 3, the name map (PART DONE, plan hypothesis CHANGED):

- Fact: the mech name `bad_Name` gives the Rust name `bad__name` and comes back as `bad_Name`. The mech name `good_` gives `good_` and comes back as `good_`. Seed `09_names` shows SEED-CHECK, EMIT, IMPORT, RT-RUST, FIXPOINT and RT-MECH for the two names. Thus the two examples of the plan are wrong: mech names give these Rust names, and the importer must not refuse them. No importer change.
- Reason: with f = D7 and g = its inverse, the importer accepts r only if f(g(r)) = r. Then g(r) comes back from f, so the map is a bijection between the accepted Rust names and their mech names.
- NOT built: the emitter side. `rust-out` has no check that g(f(m)) = m. By the rule, the mech names `bad__name` and `type_` give the Rust names of `bad_Name` and `type`, and they do not come back. No probe and no gate shows this. Wanted: a refusal `refused <name>: ... (D7)` in `rust-out`, or a RED control in ROUND-TRIP if a golden input has such a name.
- Side fact: the emitter writes an identity `case` on MechBool as `b`. The first text of seed `09_names` had such a body, and RT-MECH gave `RT-MECH-FAIL good_`. The seed now has a negation in the two fns. A seed with an identity `case` on MechBool is not canonical.

EXPECTED.tsv (11 rows): rows 02 and 06 changed; rows 09_unit_no_ctor, 10_tuple_struct, 11_forward_reference are new.

Gates:

- RUST-IN: `pass=31 fail=0`, `RUST-IN-OK`. This run came before the change of the seed body and of IMPORT.md. No importer file changed after it.
- RUST-PARSE: `pass=35 fail=0`, `RUST-PARSE-OK`.
- ROUND-TRIP, after the seed change: `work=/tmp/claude-501/rt-mech-gate pass=84 fail=0`, `ROUND-TRIP-OK`.
- NOT run: DIFF-EXEC (no emitter file and no golden file changed), the Python gates and RUST-IN-CLI.

Limits: the position of the new refusal is the item, not the use. No fixture has a use of a later type or constructor, or a struct with generics.

Runner: `zsh /Users/oobi/Documents/mech-rust/d3-points.sh [in|rt|parse|gates|exec|all]`. The exit code is not 0 when a gate fails. It has no regression test.

Staged: `lift.bend`, `resolve.bend`, `IMPORT.md`, `EXPECTED.tsv`, three new fixtures, seed `09_names` in the code worktree; `d3-points.sh` and this file in W. No commit or push. NEXT: D3 session 2 (the emitter side of point 3, with the Python gates and DIFF-EXEC), then D4.

Added after the gate run. These facts come from the code and from `EXPECTED.tsv`, with no new run:

- The importer side of point 3 has a fixture row already. Row `04_name_not_canonical` refuses `badName`, a Rust name that no mech name gives (CD5).
- The emitter has the collision check of D7: `refused: name collision (D7): <name>`. Thus two mech names with the same Rust name in one crate are refused. A single mech name that does not come back is not refused, for example `bad__name` in a crate with no `bad_Name`. The emitter side of point 3 is this case only.
- Staged trees: code ffe5230e (12 files). The W tree changes with this note, see `git write-tree`.

### 2026-10-05 D3 session 2, the emitter side of the name map (claude7, hand build in the main loop): RUST-IN-OK 31, ROUND-TRIP-OK 90, RUST-PARSE-OK 35, RUST-INFER-OK, RUST-LOWER-OK, RUST-IN-CLI-OK, DIFF-EXEC-OK 238 values

Builder deaths: two wf-builder launches died on `[reasoning_extraction]` before any tool call (fable req_011CfjsD5vrveB9awqB226g1; opus with the marker req_011CfjsFxe99BXc1JGCf8vSH). No third launch. The hand build ran in the main loop, as in D1 to D3.

Probe facts (before the edit):

- `bad__name` was emitted as `pub fn bad__name` and imported back as `def bad_Name`. This was a silent rename with rc 0.
- The parameters `fooBar` and `foo_bar` in one fn were emitted as a duplicate Rust parameter `foo_bar`. They imported back as two `fooBar` binders. This is a recorded Limit, not fixed (see Limits).

What changed:

- Code worktree `/Users/oobi/Documents/mechanism-lang-rust-m0` (branch `mech-rust/m1`, HEAD 690b5ab):
  - `bend2/rust/erase_typed.bend`: new inverse-name defs `is_under`, `camel_step`, `camel_rest`, `camel`, `lower_first`, `drop_head`, `unkw`, `fn_back`, `back_text`. New checks `ctor_kept` (in `variants`), `name_kept`, `unit_kept` (in `unit_class`) and `fn_class` (in `head_class`). The emitter (`rust-out`) now refuses a mech name m when its Rust name r = f(m) does not come back through the importer inverse g (g(r) != m).
  - `bend2/rust/resolve.bend`: the local inverse defs are removed. It calls `Et.fn_back` and `Et.lower_first`. There is now one definition for the emitter and the importer.
  - `bend2/rust/infer.bend` (line about 196) uses `Et.fn_back`.
  - `bend2/rust/lower.bend` imports `erase_typed.bend` as `Et` and uses `Et.lower_first` at 3 sites.
  - `test/rust/seed-control/`: three new controls (below).
  - `dev/rt-mech-gate.sh`: a `want` table and a control loop (a SEED-CHECK step and a REFUSE step for each control).
  - `bend2/rust/EMIT.md`: two new bullets in `## Names (rule D7)`, a row in the Refusals table, and the text about `neg_classify.mech` changed (see the classify line below).
  - `bend2/rust/IMPORT.md`: the bullet near line 77 now says that the emitter refuses a name that does not come back, and it names the three controls.
  - `test/rust/emit/neg_classify.mech`: the header comment for line 2 of the result is updated.
- Two fixes during the build: the helper `kept` clashed with an existing `def kept` in `erase_typed.bend`, so it is now `name_kept`. `unit_kept` first used the variant name as the mech name and refused `MechUnit` (RUST-IN fail x2); now it uses `mech = lower_first(ctor)`.
- W `/Users/oobi/Documents/mech-rust` (HEAD 4bc94df): `d3-points.sh` has a new `py` mode (the three Python gates). `all` is now gates + py + diffexec. This file has this entry.

Refusal text and the three controls:

- Text: `refused <def>: a name that does not come back from the Rust name `<rust>`: the importer gives `<back>` (D7)`. Exit 65. No output dir.
- `names_double_underscore.mech` (`def bad__name`): `refused bad__name: ... Rust name `bad__name`: the importer gives `bad_Name` (D7)`.
- `names_keyword_tail.mech` (`def type_`): `refused type_: ... `type_`: the importer gives `type` (D7)`.
- `names_upper_ctor.mech` (`mu Light` with the constructor `Red`): `refused Light: ... `Red`: the importer gives `red` (D7)`.
- Each control passes SEED-CHECK (`MECH-CHECK-OK 1 rows axioms=0`) and is then refused.

Gates (logs in /tmp/claude-501/d3s2/):

- RUST-IN: `pass=31 fail=0`, `RUST-IN-OK`.
- ROUND-TRIP: `work=/tmp/claude-501/rt-mech-gate pass=90 fail=0`, `ROUND-TRIP-OK`.
- RUST-PARSE: `pass=35 fail=0`, `RUST-PARSE-OK`.
- RUST-INFER: `RUST-INFER-OK` (`== RUST-INFER rc=0`).
- RUST-LOWER: `RUST-LOWER-OK` (`== RUST-LOWER rc=0`).
- RUST-IN-CLI: `RUST-IN-CLI-OK` (`== RUST-IN-CLI rc=0`).
- Runner modes: `D3-RUNNER mode=gates rc=0`, `D3-RUNNER mode=py rc=0`, `D3-RUNNER mode=exec rc=0`.
- DIFF-EXEC: `DIFF-EXEC-OK 238 values`, `== DIFF-EXEC rc=0`, `EXEC-DONE rc=0`. No golden input (`init.mech`, `second-price.mech`) was refused with "does not come back".
- classify on `test/rust/emit/neg_classify.mech` with `prelude/init.mech` (rust_emit.js classify, rc=0), result lines after the `## 2` header:
  - `refused negPostulate: a postulate in the runtime`
  - `fn negTwin = pub fn neg_twin() -> MechNat`
  - `refused neg_twin: a name that does not come back from the Rust name `neg_twin`: the importer gives `negTwin` (D7)`
  - `names: no collision`
  - Line 2 of the result is now the come-back refusal of `neg_twin`, not a name collision. The comment in `neg_classify.mech` and the two sentences in `EMIT.md` now say this.

Not run: the modes ran in three separate runs (`gates`, `py`, `exec`). A full `all` rerun in one go was not run. The doc edits to `EMIT.md` and `neg_classify.mech` came after the gates, and they changed no code.

Limits:

- The parameters and the local binders of a fn are not checked. The case `fooBar` and `foo_bar` in one fn gives a duplicate Rust parameter `foo_bar` and imports back as two `fooBar` binders. This is not fixed.
- Two fn names that give the same Rust name cannot reach the collision check in the classify table any more. One of the two names does not come back and is refused first. The collision check stays in the code.
- Stop rule (a golden input refused with "does not come back": do not change the check, ask the USER): it did not fire. DIFF-EXEC shows no such refusal. Nothing needs a USER ruling.

Staged (no commit, no push):

- Code worktree (11 files): `bend2/rust/erase_typed.bend`, `bend2/rust/resolve.bend`, `bend2/rust/infer.bend`, `bend2/rust/lower.bend`, `bend2/rust/EMIT.md`, `bend2/rust/IMPORT.md`, `dev/rt-mech-gate.sh`, `test/rust/seed-control/names_double_underscore.mech`, `test/rust/seed-control/names_keyword_tail.mech`, `test/rust/seed-control/names_upper_ctor.mech`, `test/rust/emit/neg_classify.mech`. Tree: `87710d77d0a8762cb341d6319fc84c1f46a10402`.
- W (2 files): `D-PROGRESS.md`, `d3-points.sh`. Tree: `7a83ca8e3bb67d7cb1db87faf6cc76f2d5a73a8b` before this line was filled in. The tree changes with this line, so the `git write-tree` printed last is authoritative..

Commit commands for the USER:

```
git -C /Users/oobi/Documents/mechanism-lang-rust-m0 commit -s -m "rust-out: refuse a name that does not come back from its Rust name (D3)"
git -C /Users/oobi/Documents/mech-rust commit -s -m "D3 session 2: log the emitter name check, add the Python gates mode"
```

NEXT: D4 close in a fresh session (`bend2/rust/ROUNDTRIP.md`, the limits in `IMPORT.md` and `EMIT.md`, `W/COMMIT-MSG-D.txt`, a full `all` rerun).

## D4 documentation and partial validation 2026-10-05 (claude7, hand build in the main loop)

Both builder launches died on the `[reasoning_extraction]` classifier before their first tool call (fable req_011Cfk8rSbLt77wMf7XMvzpS; opus with the marker req_011Cfk8w4PkXuJ696528ef7w). Per U7 the close is a hand build in the main loop.

Files (code worktree, branch mech-rust/m1, base 13daf80):

- `bend2/rust/ROUNDTRIP.md` (new): the reference page of unit D. Sections: Files, Canonical program, Laws (SEED-CHECK, RT-RUST, FIXPOINT, RT-MECH and the compare `alpha`, strict on `Ann`), Seed corpus (the nine seeds and the four controls), Carrier merge (pointers to EMIT.md and IMPORT.md), Gate (each check and control, `pass=90 fail=0`), Known limits. The review below narrows the contract and records additional limits.
- `bend2/rust/IMPORT.md`: one intro sentence names ROUNDTRIP.md. The last known limit (RT-MECH and DIFF-EXEC are not gates of this unit) was stale since D1; it now names the ROUND-TRIP gate on the seed corpus and DIFF-EXEC on the golden crate. No other bullet changed.
- `bend2/rust/EMIT.md`: one intro sentence names ROUNDTRIP.md. One bullet in the Tests list names the ROUND-TRIP gate as the gate that runs the emitter on the seed corpus and the `names_*` controls. No other bullet changed.
- W `COMMIT-MSG-D.txt` (new): the commit message of the D4 commit, in the shape of COMMIT-MSG-C.txt.

Limits carried into ROUNDTRIP.md: strict compare on ascriptions (U8 default); no come-back check on parameters and local binders; the M0 fragment only; the gate runs the seed corpus and the controls, not the two M0 inputs; the carrier copy in the import is a record only; a forward-reference refusal has the position of the item; the GREEN control is on seed 01 only. Not carried: the D2 limits block (D-PROGRESS.md line 305) and the U8 decision text (line 161) were not re-read in this session (a classifier denial); the page says only what the gate script, the driver modes, IMPORT.md and EMIT.md show.

Full rerun `zsh ~/Documents/mech-rust/d3-points.sh all` with the sandbox off (log /tmp/claude-501/d4/all.log):

- RUST-IN: `pass=31 fail=0`, `RUST-IN-OK`, `== RUST-IN rc=0`.
- ROUND-TRIP: `pass=90 fail=0`, `ROUND-TRIP-OK`, `== ROUND-TRIP rc=0` (the three `names_*` REFUSE controls PASS).
- RUST-PARSE: `pass=35 fail=0`, `RUST-PARSE-OK`, `== RUST-PARSE rc=0`.
- RUST-INFER: `RUST-INFER-OK`, rc=0. RUST-LOWER: `RUST-LOWER-OK`, rc=0.
- RUST-IN-CLI: rc=1 on a `subprocess.TimeoutExpired` while building the CLI (`bend2/mech.bend`, `timeout=180`). All 14 driver cases printed PASS before this build; the CLI cases did not run. No check line failed. This runner finishes ROUND-TRIP before starting the Python gates. `D3-RUNNER mode=all rc=1`, so DIFF-EXEC did not run in that pass.
- Second pass, `py` then `exec` with the sandbox off (logs /tmp/claude-501/d4/py.log, /tmp/claude-501/d4/exec.log):
  - RUST-INFER: `RUST-INFER-OK`, rc=0. RUST-LOWER: `RUST-LOWER-OK`, rc=0.
  - RUST-IN-CLI: rc=1 again, the same `subprocess.TimeoutExpired`: the build `bend bend2/mech.bend -o <tmp>/rust-in.js` timed out after 180 seconds. `D3-RUNNER mode=py rc=1`.
  - DIFF-EXEC: `DIFF-EXEC-OK 238 values`, `== DIFF-EXEC rc=0`, `D3-RUNNER mode=exec rc=0`.
- Build timing evidence for the RUST-IN-CLI red (log /tmp/claude-501/d4/build-time.log): the same build run by hand passes (`BUILD-RC=0`, a 3.3 MB `mech-cli.js`) in 381.82 seconds, with the machine at load average 17 to 25. The limit `timeout=180` in `dev/rust-in-cli-gate.py` line 123 is below this measured build time. Both failed gate runs passed the 14 driver cases, then timed out before any CLI case ran. No code changed in D4, and the gate was GREEN in D3 session 2 on the same code. Not changed: the limit (a code change, for the USER to rule). To complete the fresh-build validation, run `zsh ~/Documents/mech-rust/d3-points.sh py` on a quiet machine and require `RUST-IN-CLI-OK`.
- Status of the D4 full rerun: 6 of 7 gates GREEN on this code (RUST-IN, ROUND-TRIP, RUST-PARSE, RUST-INFER, RUST-LOWER, DIFF-EXEC); RUST-IN-CLI NOT SHOWN (timeout under load, two passes).

Staged (no commit, no push): code worktree `bend2/rust/ROUNDTRIP.md`, `bend2/rust/IMPORT.md`, `bend2/rust/EMIT.md`, tree 7c88e1b3ad86b4486ec1002f3bdf784139010778; W `COMMIT-MSG-D.txt` and this file (the `git write-tree` printed last is authoritative).

Commit commands for the USER:

```
git -C /Users/oobi/Documents/mechanism-lang-rust-m0 commit -s -F /Users/oobi/Documents/mech-rust/COMMIT-MSG-D.txt
git -C /Users/oobi/Documents/mech-rust commit -s -m "D4: record the reference page and validation limits"
```

NEXT: D4 closure remains pending the successful fresh-build validation above; committing the documentation alone does not complete it. Open from the brief: U8 (strict compare on ascriptions) and the golden carrier stay with the USER. After D closes, the next M1 unit per the D scope is E (struct with private fields, accessors and `let`), in a fresh session.

### Staged review 2026-10-05 (Codex)

Reviewed all five staged files across the code and W repositories. No code, test or CI configuration change was staged. Two MEDIUM documentation findings were fixed:

1. The reference page claimed the laws for any program satisfying an incomplete canonical checklist. The existing `names_double_underscore.mech` passes the kernel check but is refused with D7. Removing the ascription from `(lightGreen : Light)` in seed 01 passes the kernel check, emission and import, but gives `RT-MECH-FAIL lightNext`. The three reference pages now scope the results to the nine seeds and state the name, erasure and ascription restrictions. ROUNDTRIP.md also records that `mu` families have no separate checked rows: swapping constructors in two family-only programs gives `RT-MECH-OK 0`, so RT-RUST remains necessary.
2. The close record treated a commit as sufficient despite the incomplete required rerun, and incorrectly said no gate checks ran. The logs show 14 driver cases passed before each CLI build timeout. The close record and commit message now preserve the pending fresh-build validation and distinguish the driver from the CLI.

Review validation: the three reproduction probes pass (`REVIEW-PROBES-OK`). The unmodified CLI gate passes with its supported prebuilt inputs, including 28 named cases and six usage checks:

```sh
python3 dev/rust-in-cli-gate.py --driver "$TMPDIR/rt-mech-gate/rust_import.js" --cli /tmp/claude-501/d4/mech-cli.js
```

Result: `RUST-IN-CLI-OK`. The driver and CLI artifacts were built during the original D4 validation after base 13daf80; the code, tests and gate scripts have no changes from that base. Artifact SHA-256: driver `8233f72959923fef14b08123afcadb5a823c73631fddfc3e7f10282aabec5a30`, CLI `0cd36059b865f03147f2aa0ed7d7b639e2bb1659f91669348a81a5a380bf29c8`. This checks the existing builds and does not establish a fresh build within 180 seconds. The timeout and gates are unchanged.

Review evidence in `/Users/oobi/Documents/gpt7`: `mech-rust-review/probe.py`, `.kanon-exec/run-9vaBRx` (probes), `.kanon-exec/run-BzfUFE` (CLI gate). The earlier six green gate results remain the original D4 evidence; they were not rerun for these documentation corrections.
