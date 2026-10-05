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
