# mech-rust M0 unit B progress (mech -> Rust emitter, DIFF-EXEC)

Scope source: M0-PLAN.md "Unit B".  Worktree /Users/oobi/Documents/mechanism-lang-rust-m0, branch mech-rust/m0,
HEAD 653a27e (unit A, pushed), tree clean at the start of B.  W = /Users/oobi/Documents/mech-rust.
NEVER commit or push.  Stage own paths only.  No Co-Authored-By line.  Hand build in the main loop (opus builders died
3 of 3 on unit A).  One sub-unit per fresh session.  Read this file's tail first, then the B-LEARN.md sections named
in the sub-unit.

## Start state 10-03 (session claude7 18ecf380)
- Disk 39 GiB free (floor 30).  `bend` is not on PATH (A used ~/.bend/bin/bend 2.0.25, pin says 2.0.27).  node,
  rustfmt, cargo, cargocho are on PATH.  No `_bend2/`, `_build/`, `build/` in the worktree (no CLI build exists).
- CLI path: bend2/main.bend -> cli/mech.bend `dispatch` (own verbs: import, diff-parity, map-inventory; the rest goes to
  cli/kanon.bend `dispatch_args`).  A new verb goes in cli/mech.bend `dispatch` as `case "rust-out":` before the fallthrough.
- Check entry: `Elab.check_in(Global.initial(), Budget.unlimited(), source)` -> `C.Pair<Global.T, Rows>`,
  Rows = `List<&2, C.Pair<String, Global.Entry>>` (kanon.bend:47-59).  `kanon build` joins files with "\n" (read_files).
- The repo's own runtime at the CLI is `run --host kernel`: Eval of the export, accepted only if the value is an integer
  literal (host.bend:220-240).  DIFF-EXEC needs constructor values too, so B5 needs its own oracle driver on top of Eval.
- Kernel reference crib: W/B-LEARN.md (written by a read-only agent in this session; sections S1-S11).

## Input classification (read from the two .mech files; HYPOTHESIS until B2 prints the same table)
init.mech
- Rust enums: MechNat (recursive field boxed), MechEmpty (no variants), MechSum<A, B>, MechDecidable (param `0 P : Prop`
  dropped; both fields are quantity 0, so two unit variants).  MechBool -> `bool`.  MechUnit -> single-constructor struct.
- Carrier (Prop): MechFalse, MechTrue, MechEq, mechRefl, mechSymm, mechTrans, mechCongr, MechProofEq, mechProofRefl, mechProofJ.
- Carrier (type-valued defs, rule D3): MechPi, MechSigma.
- Runtime fns: mechBoolRec, mechEmptyElim, mechSumRec, mechNatRec (rec, fn-typed binder), mechDecidableBool, mechJ,
  mechTransport (both are the identity after erasure; the `0 P : ... -> Type 0` binder becomes a generic).
- Special: mechFalseElim (empty elimination of a Prop scrutinee into data; rule D4).
second-price.mech
- Rust enums: AuctionChoice, AuctionOrder (index params and Prop fields dropped: two unit variants).
- Carrier: AuctionLe (rec, Prop-valued), auctionLeZero, auctionLeSucc, auctionWinnerPaysThreshold, auctionLoserPaysZero,
  AuctionUtilityGe, auctionDominatesAnyChoice, auctionIncentiveCompatible, auctionIndividualRational, auctionNoDeficit,
  auctionTruthfulA/B/C.
- Runtime fns (15): auctionCompare (rec), auctionChoice, auctionAllocate, auctionPayment, auctionMax, auctionPriorityB,
  auctionChoiceA/B/C, auctionPaymentA/B/C, auctionAdd (rec), auctionToNative (kernel Nat, literals 0 and 1, natAdd,
  a closure and a type-level lambda passed to mechNatRec), auctionBit (Nat literals).
- Kernel Nat is in the runtime closure, so `src/nat.rs` is needed (Q5).  Prims used: natAdd only.

## Sub-units (as for A: each ends with checks clean, a driver mode that shows the result, and a log entry here)
B1 RIR + text emission.  Files: bend2/rust/rir.bend (items: enum, struct + ctor fn + accessors, fn, mod, use; types:
   path with generics, `&T`, `Box<T>`, `impl Fn(..) -> T`, bool; exprs: var, path, call with turbofish, ctor, match,
   if/else, closure, borrow, clone, Box::new, literal; patterns), bend2/rust/emit.bend (RIR -> text), driver
   bend2/tests/rust_emit.bend mode `sample` (a hand-built RIR for MechNat, AuctionChoice, auctionPayment, auctionAdd).
   DECISION D1 first (text emitter or A's ast.bend + print.bend).  Done when: sample text is `rustfmt --check
   --edition 2021` clean and builds with `clippy -D warnings` in a $TMPDIR crate.
B2 Typed erasure, declarations.  Files: bend2/rust/erase_typed.bend part 1.  Classify every row (runtime fn, runtime
   family, Prop, type-valued, refused with reason), families -> RIR enum or struct, Pi telescopes -> fn signatures
   (generics, quantities, Copy set), name mangling with collision refusal.  Driver mode `classify` prints one line per
   declaration.  Done when: the table above is reproduced for init + second-price (or the table is corrected here).
B3 Typed erasure, terms.  erase_typed.bend part 2: lambda, application (drop quantity-0 and Prop arguments, turbofish
   from erased type arguments), constructor, case -> match (MechBool -> if/else), let, literal, natAdd, closures,
   ownership modes (D5), plus the emitted `src/nat.rs` text.  Refusals: zk/fhc/mpc shapes, postulates in the runtime
   closure, poly universes, value-dependent types outside the dropped-index rule.  Driver mode `emit` prints the
   modules.  Done when: both modules are rustfmt-clean and clippy-clean in a $TMPDIR crate.
B4 CLI + crate.  `mech rust-out <.mech files in order...> <out crate dir>` (new bend2/cli/rust_out.bend + one dispatch
   case), refuse an existing output dir, Cargo.toml (edition 2021, MIT OR Apache-2.0, no deps), src/lib.rs, one module
   per input file, mech-carrier.mech (D2), collision refusal for module names.  Done when: the driver (JS build)
   writes the crate under $TMPDIR and `cargocho build` + clippy pass there.
B5 Gate + close.  Oracle driver mode `values` (Eval + a constructor-tree printer in Rust `{:?}` form), probe generation
   (D6), generated `src/bin/diff_exec.rs`, dev/rust-out-diff-exec.sh (one PASS/FAIL per value, DIFF-EXEC-OK/FAIL, JS
   build of the driver, crate built outside the tracked tree), mutation control (swap two match arms in a $TMPDIR
   copy, must be RED), test/rust/emit goldens, bend2/rust/EMIT.md, stage, W/COMMIT-MSG-B.txt.

## Design defaults (HYPOTHESES; each is confirmed or changed in the sub-unit that names it)
D1 (B1) Emission path.  M0-PLAN permits plain text.  rustfmt-clean output needs width-aware layout (100 columns), and
   unit A already has it in print.bend for its fixtures.  Default: RIR lowers to A's ast.bend and prints through
   print.bend if B-LEARN S10 shows that the needed constructs are covered; else a plain text emitter with one fixed
   layout that rustfmt does not change (short lines only, checked by the gate).
D2 (B4) Carrier "verbatim": the kernel rows have no source text.  Default: split each input file into top-level chunks
   at column-1 declaration keywords (leading comment lines stay with the next chunk), map chunk i to parsed
   declaration i, refuse on a count mismatch, and copy the chunks whose names are all non-runtime, in source order,
   under a `-- from <file>` line.  A chunk with both runtime and non-runtime names is refused.
D3 (B2) A def whose type ends in a universe (`... -> Prop`, `... -> Type n`) is type-level: it goes to the carrier, and a
   runtime signature that mentions it is refused (value-dependent type).
D4 (B2) mechFalseElim has no Rust body after Prop erasure (empty match on an erased scrutinee).  Default: classify as
   "absurd", send it to the carrier, refuse any runtime def that calls it.  Alternative: keep empty Prop families as
   empty Rust enums and keep that one binder.  USER can rule; the default needs no ruling for second-price.
D5 (B3) Ownership (Q6): Copy set = bool, fieldless enums, unit structs (derive Clone, Copy, Debug, PartialEq, Eq).
   Quantity many and not Copy -> `&T` parameter; quantity 1 -> by value.  A variable of mode `&T` used where an owned
   value is needed gets `.clone()` (generics get a `Clone` bound); match on `&T` binds references; a compound argument
   for a `&T` parameter is emitted as `&expr`.  fn-typed binders -> `&impl Fn(..) -> T`.  A `0 P : .. -> Type` binder is a
   generic and `P a b` is `P` (indices dropped).  Erased type arguments are always passed by turbofish.
D6 (B5) Probes are closed mech terms.  The same probe goes two ways: kernel Eval -> printed value (oracle), and typed
   erasure -> one `println!("{:?}", ..)` line in diff_exec.rs.  Generated inputs: MechNat in {0, 1, 2}, both booleans,
   every constructor of fieldless families, all combinations per first-order runtime fn.  Higher-order and generic fns
   (mechBoolRec, mechSumRec, mechNatRec, mechJ, mechTransport, mechDecidableBool, auctionToNative) get hand-written
   probes in test/rust/emit/probes.mech.  mechEmptyElim has no closed input (noted in EMIT.md, no probe).
D7 Names: defs camelCase -> snake_case fns, constructors -> UpperCamel variants, Rust keywords get a trailing `_`;
   file stem `-` -> `_` for the module name.  The map is checked for collisions per crate and a collision is a refusal,
   which keeps it injective on every accepted input.
D8 Gate speed: build the driver once to JS (`bend <driver> -o x.js`, about 48 s for A) and run with node; native
   builds of IO.write drivers failed 3 of 3 in unit A (cause open).

## Log
10-03 (claude7 18ecf380): unit B opened.  Read M0-PLAN.md, A-PROGRESS.md tail, both .mech inputs, cli/mech.bend,
cli/kanon.bend, main.bend, kernel/global.bend, kernel/shape.bend, kernel/term.bend:1-150.  Split and defaults written
above.  B-LEARN.md agent launched (read-only).  No repo file changed yet.

10-03 same session, TARGET CRATE: W/target-crate (Cargo.toml, src/{lib,init,second_price,nat}.rs) = the hand-written
Rust that the emitter must produce for init + second-price (all 7 + 15 runtime fns, 6 families, nat module).  It is the
golden for B1 (sample) and B3.  `rustfmt --edition 2021` ran in place, exit 0.  rustfmt changed only two sites: the
`mech_sum_rec` signature (over 100 columns -> one parameter per line) and the `mech_nat_rec::<Nat>(..)` call in
`auction_to_native` (one argument per line).  So fn signatures and call arguments need width-aware breaking: this
supports D1 = lower to A's ast.bend and print with print.bend (confirm with B-LEARN S10).
CLIPPY NOT RUN: `cargocho clippy` died on `sccache: error: Operation not permitted` (the Bash sandbox blocks the sccache
server).  Rerun with the sandbox off:  cargocho clippy --warn -- --manifest-path W/target-crate/Cargo.toml
--target-dir "$TMPDIR/mech-out-target" -j 2 -- -D warnings   (the gateledger hook wants `gateledger run --` or the
`[skip-gateledger]` tag; the crate is scratch, so the tag is correct).  Until it is green, the rules below are hypotheses.
Emitter rules found while writing the target (they extend D5):
R1 A generic is kept only if it occurs in the erased signature; a dropped generic takes no turbofish argument
   (mechJ keeps P only, mechTransport keeps B only).  All kept generics get `: Clone`.
R2 A binder that is unused after erasure is `_` in a pattern and `_name` as a fn or closure parameter (else
   `unused_variables` fails `-D warnings`; see `MechNat::MechSucc(_)` in auction_compare).
R3 A match where every arm rebuilds its own pattern is replaced by the scrutinee (clippy::needless_match; the inner
   match of auctionCompare becomes the recursive call).
R4 `if c { true } else { false }` -> `c`, the reverse -> `!c` (clippy::needless_bool).  A match with bool-literal arms keeps
   explicit patterns (match_like_matches_macro fires only with a wildcard last arm).
R5 Never `.clone()` a Copy value (clippy::clone_on_copy).  Pattern variables under a `&T` scrutinee are references; they
   go to `&T` parameters as is (deref coercion covers `&Box<T>`).
R6 A one-branch case on an erased Prop scrutinee is the branch body (mechJ).  Zero branches = D4.
R7 Cross-module names: one `use crate::<module>::*;` line per used module, sorted by module name.
R8 Nat: `nat_small(u32)`, `nat_add(&Nat, &Nat)`, manual `Debug` that prints decimal (its `fmt` signature is the only
   `&mut` and lifetime in emitted code).  Literals above u32 are refused at M0.
R9 Value format for DIFF-EXEC = Rust `{:?}` of derived Debug (`MechSucc(MechZero)`, `true`, `AuctionWin`, decimal Nat).
R10 OPEN for the USER (not hit by the M0 inputs): an enum with 3 or more variants that share a prefix trips
   clippy::enum_variant_names; choices are an `#[allow]` on the enum or a prefix strip.
Hooks met: main-loop Read cap 150 lines; rg definition sweeps over .rs are denied (use `symx <file> <name>`);
gateledger guard on cargocho clippy.  The session base prefix is about 100k tokens, so this session hit the 155k
watchdog after 12 steps.  A sub-unit session must go straight to its files.
NEXT (fresh session): (1) check that W/B-LEARN.md exists and read S10 + S11 only; (2) run the clippy command above
with the sandbox off and fix the target crate and rules R1-R9 from what it reports; (3) rule D1; (4) build B1
(rir.bend, emit.bend, driver mode `sample`) so that the sample text equals the matching parts of W/target-crate.
No file in the worktree changed in this session (git status clean at 653a27e).

10-03 same session, B-LEARN RESULT: the wf-mechanical agent (ad5097572b735dc88) did NOT write B-LEARN.md.  A per-agent
step budget hook stopped its reads after 26 tool calls, and its heredoc writes were refused (that agent type has no
Write tool).  Its report held S1-S6 and parts of S8 and S9.  The main loop wrote W/B-LEARN.md from that report (the
agent's cites, not checked again: each line is a hypothesis).  The "Start state" line above that says "sections
S1-S11" is wrong: S7, S10, S11 and parts of S3, S4, S5, S8, S9 were missing.
A second agent (wf-closer, it has the Edit tool) was launched to add S10, S11, S9, S8, S7 and three open points.
Its result is NOT confirmed here.  Check with:  rg -n '^## S' W/B-LEARN.md   A section that is not there must be
read directly (file windows: B-LEARN.md, "REMAINING READS").
Crib facts that change the sub-units:
F1 (B2) `mu` families are probably not Rows (GUESS in S3).  Families come from `Global.T.families` (newest first), so
   the source position of a family relative to the defs is not in Rows.  B2 must take it from the parsed declarations
   (`Parser.program` gives `List<Syntax.Decl>` in source order) or from one check per file.
F2 (B4) One module per input file: check file i with `Elab.check_in(globals of the files before i, ..)`.  The new Rows
   and the new head part of `families` are the declarations of file i.  `kanon build` joins all files first; B4 must not.
F3 (B3) A case branch carries the binder quantities of the PATTERN (default many), not those of the constructor
   declaration.  Erased fields (quantity 0 or Prop-typed) must come from `Family.ctors[..].args` by position.
   `In{..}` keeps every field, the quantity-0 ones too, and does not keep the family parameters.
F4 (B3) An application is `Out{SPi{q,x,dom},APt{q,arg},head}`: the quantity and the quoted domain are on the node, so
   a quantity-0 argument is dropped with no type inference.  A Prop-typed argument of quantity many needs the sort of
   `dom` (`Check.infer_univ` in a context, then `Level.always_zero`).
F5 (B3) A type `F p1 .. pn` is `Lan{SMu{F, indices}, Sec{SColl n, [Leg{[],p}..]}}`; a function type is
   `Ran{SPi{q,x,A},B}`; a lambda is one `Sec{SPi{q,x,A},[Leg{[(q,x)],body}]}` per binder; Var 0 = innermost binder.
F6 (B5) Oracle: `Eval.eval(globals, [], term)` then `Eval.whnf`.  A constructor value is `VIn{SMu{F,idx}, VACtor{c},
   args}`.  GUESS: whnf forces the head only, so the value printer must force each kept argument in turn, and must
   drop the erased fields with the F3 rule so that its text equals the Rust `{:?}` text.
NEXT step (1) is now: `rg -n '^## S' W/B-LEARN.md`, then read S10 + S11 (or the files, if the sections are not there).

10-03 same session, CRIB COMPLETE + D1 SETTLED + CLIPPY GREEN (this entry replaces NEXT steps 1-3 above):
- B-LEARN.md is 284 lines; headers checked on disk: S1-S6, S8 + S9 (part), VERBATIM DEFINITIONS, then S10 (line 127),
  S11 (192), S9 rest (225), OPEN POINTS CLOSED (244), S8 rest (258), S7 (273).  The second agent wrote these; its
  GUESS marks are in the text.  Read S10 + S11 before B1.
- Agent answers (agent cites, not checked again): a `mu` adds one family record, no Row, no Global entry per
  constructor (check.bend:247, :335; elab.bend:548-551), so F1 is confirmed.  `Ctor.args` has no family params
  (check.bend:296).  No `apply` def in eval.bend: use `out_value` / `out_point` (eval.bend:211).  `quote(globals, size,
  value)` eval.bend:567.  `whnf` forces the head only (eval.bend:386-390), so F6 is confirmed.  `Pp.term` prints a
  constructor as `(In shape addr [..])`, so the B5 oracle needs its own value printer.  `publish` refuses an existing
  directory ("output already exists: ...").  No `die` def was found under bend2 (cli/mech.bend calls `IO.die`: check
  where it comes from before B4).  `rust_frontend` is not in dev/bend2/test-manifest.json.  Printer entry point:
  `def file(f: A.SrcFile) -> String` (print.bend:830).
- EXPERIMENT (main loop): `~/.bend/bin/bend bend2/tests/rust_frontend.bend -o $TMPDIR/mrb/rf.js` (exit 0), then
  `node rf.js print "<source text>"` on the W/target-crate files, output compared with the file:
    second_price.rs  print SAME, check SAME (the fragment pass accepts the whole module)
    init.rs          print DIFF at ONE site: `match e {}` comes back as `match e {` newline `    }`; all else is equal
    nat.rs           print DIFF (whole file; not in A's fragment: const, impl block, `&mut`, macros)
  The tree stayed clean after the JS build.  bend reports 2.0.25 installed, 2.0.34 available (pin 2.0.27).
- D1 = lower RIR to A's `A.SrcFile` and print with `Pr.file`.  A's printer already makes the two rustfmt line breaks of
  the golden (fn parameter list, call arguments), derive attributes, `//!`, unit struct, bounds, `&impl Fn`, turbofish,
  closures.  Two exceptions: (1) the empty match: print.bend:615-616 and 719-720 need a no-arms case that prints
  `match e {}`.  This is a unit A file; after the change run dev/rust-parse-gate.sh again (RUST-PARSE-OK) and add one
  parse fixture.  (2) `src/nat.rs` and the frame of `src/bin/diff_exec.rs` are fixed text, not AST.
- CLIPPY: `cargocho clippy --warn -- --manifest-path W/target-crate/Cargo.toml --target-dir "$TMPDIR/mech-out-target"
  -j 2 -- -D warnings` with the Bash sandbox off = "OK clippy: 0 errors, 0 warnings", exit 0.  So W/target-crate is a
  rustfmt-clean and clippy-clean golden, and rules R1-R9 are enough for these two inputs.  Inside the sandbox sccache
  fails ("Operation not permitted"): each clippy or cargo build of an emitted crate needs the sandbox off.
NEXT (fresh session) B1: (1) read B-LEARN S10 + S11; (2) fix the empty match in print.bend, add the fixture, rerun
the RUST-PARSE gate; (3) write rir.bend (erased program IR with the D5 modes) and emit.bend (RIR -> A.SrcFile ->
`Pr.file`); (4) driver bend2/tests/rust_emit.bend mode `sample` with hand-built RIR for MechNat, MechEmpty +
mech_empty_elim, mech_sum_rec, AuctionChoice, auction_payment, auction_add, auction_to_native; (5) done when the
sample text is byte-equal to the same items in W/target-crate (JS build + node, as in the experiment above).

10-03 B1 (session claude7 46065b82, hand build in the main loop; nothing committed):
- Step 1 done (S10 + S11 read).  Step 2 done: bend2/rust/print.bend has two new cases ahead of the general EMatch cases
  (`JFl{A.EMatch{s, Nil{}}}` and `JBrk{A.EMatch{s, Nil{}}, ind, avail}`, both print `match e {}`); new fixture
  test/rust/parse/15_empty_match.rs (tail position and arm body); dev/rust-parse-gate.sh = pass=35 fail=0,
  RUST-PARSE-OK (15 accepted + 20 refused).  MIN_ACCEPTED stays 14 (the gate and FRONTEND.md:77 agree); the USER can
  raise both to 15.
- Bend 2 facts found (2.0.25): a def must be defined before its use ("expected : a defined name"), with or without
  `@unsafe`, so there is NO mutual recursion between defs.  `+x` on a binder = the binder has more than one use
  (HYPOTHESIS from print.bend; a binder without `+` has one use at most).  Function-typed parameter: `next: A -> B`;
  lambda: `x => expr`; type arguments are explicit at the call (`task_next(A, B, r, next)`).
  CONFIRMED by the checker: a second use of a binder without `+` = "x (consumed more than once)".  `exs` is a keyword
  ("expected : a name (got the keyword 'exs')").  The checker reports ONE error for each run.
- Step 3 + 4 files WRITTEN: bend2/rust/rir.bend, bend2/rust/emit.bend, bend2/tests/rust_emit.bend (`sample init`,
  `sample second`).  RIR: the mode of a binder is its type (`TRef` = borrow), clone / borrow / Box::new are explicit
  nodes.  emit.bend: self-recursive list walkers `tys` and `nodes` (a single value goes in as a list of one), arms
  through `arm_pats` + `arm_bodies` + `zip_arms`; struct items are the unit struct only (`IUnit`), which is the only
  struct shape in the golden (a single-constructor family with fields can be a one-variant enum until B2 rules it).
  An `if` that is an arm body always goes in a block (correct for the golden; a short if/else, 50 columns or less,
  stays on the arm line in rustfmt: OPEN for B3).
- ONE command for step 5:  zsh W/b1-sample.sh   (JS build, both samples, W/cmp_sample.py = each emitted item must be
  an item of the golden file, in order; then rustfmt --check).  It prints B1-SAMPLE-OK or B1-SAMPLE-FAIL.
- RESULT of step 5 = B1 DONE: `zsh W/b1-sample.sh` printed SAMPLE-EQUAL for init (8 items: `//!` line, MechNat,
  MechUnit, mech_unit, MechEmpty, MechSum, mech_empty_elim, mech_sum_rec) and for second (6 items: `//!` line, the two
  `use` lines, AuctionChoice, auction_payment, auction_add, auction_to_native), then B1-SAMPLE-OK (rustfmt --check
  clean).  Fixes on the way: `exs` -> `nodes`, `+x` in sum_arm.  The RUST-PARSE gate ran after the last print.bend
  change.  NOT RUN: clippy on the sample (the sample is not a full crate; its items are byte-equal to items of the
  clippy-green W/target-crate).
- Worktree state (653a27e, nothing staged, nothing committed): M bend2/rust/print.bend; new bend2/rust/rir.bend,
  bend2/rust/emit.bend, bend2/tests/rust_emit.bend, test/rust/parse/15_empty_match.rs.  W files: b1-sample.sh,
  cmp_sample.py.  This session ended at about 157k tokens of context (base prefix about 100k).
NEXT (fresh session) B2: read this entry and F1-F5 above, then B-LEARN S3, S4, S6 and S7 only.  Write
bend2/rust/erase_typed.bend part 1 (classify each row and family; families -> `R.IEnum` / `R.IUnit`; Pi telescopes
-> `R.IFn` signatures with rules R1 + R2 + D5; names by D7 with a collision refusal) and driver mode `classify` in
bend2/tests/rust_emit.bend.  Write each walker as a self-recursive list walker (no mutual recursion) and put `+` on
each binder with two or more uses.  Done when the classify table equals "Input classification" above.

### 2026-10-03 B2 result (claude6, session da918174): DONE, nothing staged, nothing committed

Files:
- NEW `bend2/rust/erase_typed.bend` (part 1: classes, family erasure, signature erasure, names, collision check).
- CHANGED `bend2/tests/rust_emit.bend`: mode `classify <file.mech> [<file.mech>]` (file 2 is checked in the globals of file 1; the Copy list and the item names carry over).
- NEW `W/b2-classify.sh`: JS build, classify table, then a diff of each `fn` line against the `symx` signatures of the golden crate. Argument `table` prints the table.

Check: `zsh ~/Documents/mech-rust/b2-classify.sh` gives `B2-CLASSIFY-OK fn signatures: 22 equal`. `b1-sample.sh` still gives `B1-SAMPLE-OK` (the driver dispatch changed).

The table equals "Input classification" on each line:
- init.mech: MechNat `enum { MechZero, MechSucc(Box<MechNat>) }`, MechBool `bool`, MechUnit `struct` + `fn mech_unit`, MechEmpty `copy enum {}`, MechSum `enum<A, B>`, MechDecidable `copy enum { MechIsFalse, MechIsTrue }`; 10 `prop`; 2 `type` (MechPi, MechSigma); 7 `fn`; mechFalseElim `absurd`.
- second-price.mech: AuctionChoice and AuctionOrder `copy enum` with two unit variants; 13 `prop`; 15 `fn`.
- Last line: `names: no collision`.

Table line forms: `fn <mech name> = pub fn <signature>`, `data <name> = [copy ]enum ..` or `struct <name>; fn <ctor>`, `bool <name>`, `prop <name>`, `type <name>`, `absurd <name>`, `refused <name>: <why>`. Constructors get no line.

Decisions:
- D9: the sort test is syntactic (family level, universe at the end of a telescope, kind of the bound variable). A shape outside these rules is refused with a reason. `Check.infer_univ` is not used; B3 can add it if a body needs it.
- D10: `MechBool` is `bool` by name (prelude contract).
- D11: a parameter name comes from the lambda binder of the body (`peel_name`); the Pi binder name is the fallback. A generic name comes from the Pi binder.
- D12: R2 (`_name` on a binder with no use) is NOT in part 1. No parameter of a golden signature is without a use. B3 does R2 with the erased use counts.
- H1 (holds on the two inputs): the constructor argument context has the family parameters only (last parameter = Var 0), not the indices.

Bend 2 facts (each one cost a 48 s build):
- F7: `Kind` is a keyword. The type is `Knd`.
- F8: a match scrutinee must be a parameter or a pattern field. A computed value needs its own def. So a walker with a computed step is: one recursive walker + one non-recursive step def that gets the computed value and the tail (or the accumulator).
- F9: nested matches on parameters must follow the parameter order. A match on an earlier parameter inside a match on a later one fails ("consumed binder").
- F10: a let of a constructor term has no inferable type. Give the term to a helper def.
- F11: the termination check reads the arguments left to right: each one unchanged until one shrinks. A walker with a changing accumulator before the shrinking argument needs `@unsafe`.

API that B3 can use: `name_class(env, name) -> Class` (`CFn{name, generics, params, ret}`, `CData{item}`, `CBool`, `CProp`, `CType`, `CAbsurd`, `CNo{why}`, `CSkip`), `ers(env, ctx, [ty])` (type erasure, `Knd` context, innermost binder first), `mode`, `tele` + `Acc` (Pi telescope and body lambdas in step), `classify_source(env, names, source) -> St`.

NOT tested: a `refused` line, the collision line with a real collision, `classify` with one file, the phantom generic refusal. There is no negative fixture.

Worktree: branch mech-rust/m0, HEAD 653a27e, nothing staged. Modified: `bend2/rust/print.bend`. Untracked: `bend2/rust/emit.bend`, `bend2/rust/rir.bend`, `bend2/rust/erase_typed.bend`, `bend2/tests/rust_emit.bend`, the B1 parse fixture `test/rust/parse/15_empty_match`.

NEXT (fresh session) B3: read this entry, F1-F11 and the B3 line of the sub-unit list. First add a small negative fixture (one refused def, one name collision) and make `b2-classify.sh` check it. Then write part 2 of `bend2/rust/erase_typed.bend` as the sub-unit list says: start from `tele` (the body below the lambdas is `peel_body` applied one time per binder) and from the `Class` values. Do R2 there. Keep F8, F9 and F11 in mind before the first build.

### 2026-10-03 B3 part a (claude6, session edb02900): negative fixture DONE; part 2 DESIGNED, NOT WRITTEN

Files:
- NEW `test/rust/emit/neg_classify.mech` (one `axiom` with a runtime type; `negTwin` + `neg_twin`, which both give `neg_twin`).
- CHANGED `W/b2-classify.sh`: after the signature check it classifies init.mech + the fixture and needs the two lines `refused negPostulate: a postulate in the runtime` and `refused: name collision (D7): neg_twin`.

Check: `zsh ~/Documents/mech-rust/b2-classify.sh` gives `B2-CLASSIFY-OK fn signatures: 22 equal` and `B2-NEGATIVE-OK refused line + collision line`. Still NOT tested: `classify` with one file, the phantom generic refusal.

Why part 2 is not written: the reads for part 2 brought the context to 132k (base about 100k, hard gate 165k). Part 2 is about 450 lines and each build error costs 48 s and one turn. NO part 2 code is in the tree. `erase_typed.bend` is unchanged.

Facts read in this session (do not read these again):
- F12 `Term.T` (term.bend:27-40): `Var{index}`, `Univ{level}`, `Lan{shape, body}`, `Ran{shape, body}`, `In{shape, addr, args}`, `Elim{data}`, `Sec{shape, legs}`, `Out{shape, addr, head}`, `Let{name, ty, value, body}`, `Ann{body, ty}`, `Global{name}`, `Lit{value}`, `Auto{}`. `Addr`: `APt{quantity, arg}`, `ALeg{index}`, `ACtor{name}`. `Leg{binders: List<&2, C.Pair<Quantity.T, String>>, body}`. `ElimData{shape, scrut, scrut_q, motive: Maybe<&2, Motive<A>>, branches: List<&2, C.Pair<Addr<A>, Leg<A>>>}`.
- F13 `Pos.Ctor{name, args, res_idx, full_arity, self_rec}`; `Pos.find_ctor(ctors, +name) -> Maybe<&2, Ctor>` (positivity.bend:27). `Global.Entry` = `Def{DefEntry{ty, body, reducible, rec_arg, partial}}`, `Axiom{ty}`, `Prim{ty, prim}`; `Global.entry_ty(e)`; `Global.find(name, globals)`; `Global.find_family(name, globals)`.
- F14 `Literal.LInt{value: Bignum.T}`. Bignum has `of_u32`, `le`, `equal`, `compare`; no decimal printer in its first 206 lines. pp.bend:32 `literal(lit: Literal.T) -> String` gives the text (check its output form). u32 bound: `Bignum.le(n, Bignum.of_u32(4294967295))`.
- F15 String patterns are `SNil{}` and `SCon{c, rest}`.
- F16 Sources: the MechBool constructors are `mechFalse`, `mechTrue`. The inner case of auctionCompare (second-price.mech:42-45) builds each constructor again with a new proof: this is the R3 input. auctionToNative is `mechNatRec (fun (value : MechNat) => Nat) 0 (fun (value : MechNat) (previous : Nat) => natAdd 1 previous) n`, so `_value` comes from R2. mechTransport gives mechJ the type argument `fun (0 right : A) (0 proof : ..) => B right`.
- F17 Emitter entry: `Em.text(R.Module{source, items})`; `R.IUse{module}`. Driver: add a tag to `Md`, a case in `mode_of` and in `run_md` (rust_emit.bend:93-147).

Design of part 2 (HYPOTHESES until the build; append below `classify2`, a def must come before its use):
- P1 Context = two lists in step, innermost binder first: `ks: List<&2, Knd>` (as part 1) and `vs: List<&2, Maybe<&2, R.Param>>` (`Some` = a runtime variable with its Rust name and type; a `TRef` type = a borrow; `None` = erased, generic or Prop).
- P2 `Want` = `WOwn{}` | `WRef{}`. Only a variable answers to the want: (TRef variable, WOwn) -> `XClone`; (owned variable, WRef) -> `XBorrow`; else as is. Refuse (`TRef{TBox{..}}` variable, WOwn) at M0 (a boxed field by value needs a deref node). Each compound expression is built owned, then `XBorrow` if WRef. The arms of a match or an if are WOwn (an arm is a temporary scope, so `&f()` in an arm does not live).
- P3 No mutual recursion + F8, so ONE `@unsafe` job-list walker. `Job{ks, vs, want, term}`; `Rx` = `XOk{ex}` | `XNo{why}`; `plan_of(env, job) -> Plan{jobs, build}` reads the top node or the application spine only and does not call the walker; `exs(+env, jobs)`: `case Con{+job, rest}:` then `+plan = plan_of(env, job)` and `build(build_of(plan), exs(env, jobs_of(plan))) <> exs(env, rest)`. `Build` = `BLeaf{rx}` | `BSame{}` | `BCall{func, targs, want}` | `BCtor{family, ctor, boxes, want}` | `BMatch{pats, want}` (results: scrutinee, then one per arm) | `BIf{true_first, want}` | `BClosure{params, want}`.
- P4 Application: a spine walker over `Out{SPi{q, x, dom}, APt{q, arg}, head}` gives the head and the arguments in order.
  - Head `Global{"natAdd"}`: `BCall{"nat_add", [], want}`, two WRef jobs. Each other prim: refuse.
  - Head `Global` with class `CFn`: walk the type telescope of the callee (`Global.entry_ty`) in step with the arguments, with the test of `tele`: `binder_er(q, end_of(dom), one_er(ers(env, tctx, [dom])))`. `BGen`: a turbofish type if the binder name is in `CFn.generics` (R1); erase the type argument by a peel of its lambdas (push `kind_of(end_of(dom), x)`), then `ers` (`fun value => Nat` -> `Nat`; `fun right proof => B right` -> `B`). `BDrop`: skip. `BParam{t}`: one job, want from `mode(copies, q, t)` (`TRef` -> WRef). The mode MUST come from the callee telescope: the Out node has the instantiated domain (`A := AuctionChoice` gives an owned mode against a `&A` parameter). Argument count not equal to the telescope length: refuse (partial application). `CAbsurd`: refuse (D4). `CNo{why}`: refuse with `why`.
  - Head `Var` of type `TRef{TFn{args, ret}}`: the drop test is `binder_er` on the (q, dom) of the Out node; the wants come from the `TFn` args in order.
  - A lambda as an argument: `BClosure`. Merge the nested lambdas, one `Param` for each kept binder with type `mode(copies, q, erased dom)`, body WOwn, R2 gives `_name`.
  - A `Global` function with no argument in argument position: refuse at M0.
- P5 Constructor `In{SMu{F, idx}, ACtor{c}, fields}`: MechBool -> `XBool` (true for `mechTrue`). Class `CData{IUnit{name, ctor}}` -> `XCall{ctor, [], []}`. `IEnum` -> keep mask from the `Family.ctors` args with the rule of `fields` (ctx = `param_kinds(params, [])`, then each arg pushes its kind); kept fields are WOwn jobs; `XBox` where the variant field type is `TBox`; variant name `upper_first(c)`.
- P6 Case `Elim{ElimData{SMu{F, idx}, scrut, q, motive, branches}}`. Prop family: one branch -> `BSame` on the branch body with the binders pushed as `None` (R6); zero branches -> refuse (D4). MechBool -> `BIf`. Else `BMatch`: scrutinee want = WOwn if F is in `copies`, else WRef (a compound scrutinee of a non-Copy family becomes `&expr`); field names from the branch `Leg` binders; kept test from the `Family.ctors` args by position (F3); kept field type `TRef{boxed(F, t)}`. R2: `BSkip` when the erased arm body has no use of the name (write `uses(name, ex)` on `R.Ex`). R3: when each arm has no bind and its body is the `XCtor` of its own pattern, the result is the scrutinee. R4: `if c { true } else { false }` -> `c`; the `!c` form needs a new RIR node (OPEN).
- P7 Let: RIR has no let node. Add `XLet` to rir.bend + emit.bend, or refuse at M0 with a reason. No M0 input has a let.
- P8 Literal -> `XCall{"nat_small", [], [XInt{text}]}`; above u32 -> refuse.
- P9 Def: walk the type telescope and the body lambdas as `tele` does and build `ks` + `vs` in step; body job WOwn; R2 on fn parameters; item = `IFn` from the `CFn` + the body. Module = the `CData` items and the fns in declaration order. `IUse`: file 2 gets the module of file 1, and `nat` when a signature mentions `Nat` (limit: a use of Nat inside a body only is not seen). Module names are B4 (D7).
- P10 `src/nat.rs` is fixed text = the 55 lines of W/target-crate/src/nat.rs (not read in this session).
- OPEN from the design: a Copy field under a borrow pattern needs a deref node (`.clone()` trips clippy::clone_on_copy); the B1 note on a short if/else in an arm.

Worktree: branch mech-rust/m0, HEAD 653a27e, nothing staged. Modified: `bend2/rust/print.bend`. Untracked: `bend2/rust/emit.bend`, `bend2/rust/rir.bend`, `bend2/rust/erase_typed.bend`, `bend2/tests/rust_emit.bend`, `test/rust/parse/15_empty_match.rs`, `test/rust/emit/neg_classify.mech`.

NEXT (fresh session) B3 part 2: read ONLY this entry, then `bend2/rust/rir.bend` (58 lines) and the windows 331-400, 436-536, 586-594 of `bend2/rust/erase_typed.bend`, then W/target-crate/src/nat.rs. Do not read the kernel again (F12-F16 have the shapes). Write part 2 by P1-P10 in one edit, then driver mode `emit <file.mech> [<file.mech>]` and `W/b3-emit.sh` (JS build, emit each module, byte diff against W/target-crate/src/{init,second_price}.rs, `rustfmt --check --edition 2021`). Byte-equal modules are clippy-clean (the golden is clippy-green); run clippy in a $TMPDIR crate only if a module is not byte-equal. Keep F8, F9, F11 and "one error for each build" in mind: read the whole edit against F7-F11 before the first build.

### 2026-10-03 B3 part 2 (claude6, session 946aef5c)

STATE: B3 part 2 DONE, NOT STAGED, NOT COMMITTED. `zsh W/b3-emit.sh` is GREEN: the two emitted modules are byte-equal with the golden crate (init.rs 74 lines, second_price.rs 113 lines), `rustfmt --check` is clean, the negative fixture is OK. The B1 and B2 checks are GREEN after the driver change.

Files (all in the worktree, nothing staged, nothing committed):
- `bend2/rust/erase_typed.bend`: part 2 is below `classify2` (3 new imports: literal, bignum, pp). Types `Want`, `Rx`, `Job`, `Build`, `Plan`, `Sarg`, `Spine`, `Cargs`, `Lam`, `Scope`, `Br`, `Fctx`, `It`, `Es`. Entries `emit1(name, source)` and `emit2(first_name, first_source, name, source)`, each gives `Result<&2, &2, String, R.Module>` (`Fail` = the refusal lines).
- `bend2/tests/rust_emit.bend`: mode `emit <file.mech> [<file.mech>]` (`MEmit`, `emit_out`, `emit1_io`, `emit2_io`, `emit_io`). A refusal exits with code 65.
- `W/b3-emit.sh [<diff lines>] [nobuild]`: JS build to `$TMPDIR/mrb3/re.js`, emit of the two modules from bare file names (the `//!` line and the `use` line come from the file name), byte diff with `W/target-crate/src/{init,second_price}.rs`, `rustfmt --check --edition 2021` for a byte-equal module. Prints `B3-EMIT-OK <module>: byte-equal` or `B3-EMIT-FAIL`.

Design as written (differences from P1-P10):
- P3: `exs(+env, jobs)` is the only body walker. `plan_term` reads one node. `built(oks(results), build)` makes the expression.
- P4: `spine` gives `Spine{head, args}`; `call_args` walks the callee telescope in step with the arguments. `natAdd` is the only prim. A `Global` with no argument is a call with no argument (not a refusal).
- P6: `scoped` pushes one context entry for each branch binder; the kept test is `ctor_tys` (same walk as `fields`). If the branch has more binders than constructor arguments (an induction hypothesis), each extra binder is erased (`None`).
- P9: `nat_use` puts `use crate::nat::*` after the `IUse` of file 1 when a fn signature mentions `Nat`.
- NOT done: the `!c` form of R4 (no RIR node), a deref for a Copy field below a borrow pattern, D7 module names (B4).

Checks (all run in this session, 2 builds for part 2):
- `zsh W/b3-emit.sh`: `B3-EMIT-OK init: byte-equal`, `B3-EMIT-OK second_price: byte-equal`, no `B3-FMT-FAIL`, `B3-NEGATIVE-OK refused line, exit code 65, no module text`.
- `zsh W/b1-sample.sh`: `B1-SAMPLE-OK`. `zsh W/b2-classify.sh`: `B2-CLASSIFY-OK fn signatures: 22 equal`, `B2-NEGATIVE-OK refused line + collision line`.
- Build 1 failed on a keyword (F18). Build 2: `All terms check`. No type error in the 910 lines of part 2.

New facts:
- F18: `exs` is a keyword of Bend 2 (as `Kind`, F7). The walker has the name `run_jobs`.
- F19: a zsh script with `set -u` must use `cd -q`. A plain `cd` runs the chpwd hook `_telcoin_shared_target`, and the hook reads a parameter that is not set.
- F20: `IO.die(Unit, 65, why)` writes `why` to stderr. stdout stays empty.
- F21: the constructor arguments of `In` and the branch binders of `Elim` align with `Pos.Ctor.args` by position (the byte-equal modules are the evidence).

NOT tested:
- Refusal paths other than the postulate: a call of an absurd function (D4), a case with no branch, a partial application, a let, a literal above u32, a string literal, a boxed field by value, an erased variable in a runtime position.
- `BIf` with the false branch first. A case where a branch has more binders than constructor arguments.
- clippy and `cargo build` on the emitted text (not necessary: the text is byte-equal with the golden crate, and the golden crate is clippy-green).
- The emit mode has no name-collision check (D7). Only the classify mode has it.
- `uses` counts a shadowed name as a use (safe direction: no `_` prefix, no skip).

Worktree state: `mechanism-lang-rust-m0`, branch mech-rust/m0, nothing staged. Modified: `bend2/rust/print.bend`. Untracked: `bend2/rust/{emit,rir,erase_typed}.bend` (erase_typed.bend has 1809 lines), `bend2/tests/rust_emit.bend`, `test/rust/emit/`, `test/rust/parse/15_empty_match.rs`. In W: `b3-emit.sh` is new.

NEXT: sub-unit B4 as the header of this file and M0-PLAN.md define it. Open inputs for B4 from B3: D7 (module names, a collision check in the emit mode), the `!c` form of R4, the deref node. Use a fresh session. Read only these windows of this file: lines 1-19 (header), 50-80 (the B4 definition at line 55, D2 at line 69), 145-175 (F2 at line 147, the note at line 172), and this entry (from line 309). Do not read the kernel again.

### 2026-10-03 B4 (claude6, session 4c806958)

STATE: B4 code DONE, NOT STAGED. Emit stage GREEN. Cargo stage GREEN (sandbox off): `B4-OK cargocho build: OK build: 0 errors, 0 warnings`, `B4-OK cargocho clippy -D warnings: OK clippy: 0 errors, 0 warnings`. The B4 done-rule holds. The pointer to the last run directory is `W/.b4-last` ($TMPDIR is not the same with the sandbox off).

Files (worktree mechanism-lang-rust-m0, all UNSTAGED):
- NEW `bend2/cli/rust_out.bend`: `run(args)`. The last argument is the output directory, the arguments before it are
  the `.mech` files in order (one or more, else usage, exit code 64).
- `bend2/cli/mech.bend`: import, `case "rust-out": RustOut.run(args)` before the Kanon case, one usage line.
- `bend2/tests/rust_emit.bend`: mode `crate <file.mech>... <out dir>` calls the same `run` (import `Ro`).
- NEW `W/b4-crate.sh`: stage `emit` (driver build, crate write, diffs, refusal checks), stage `cargo`.

Design as written:
- Output check first: `Files.exists(normalize_target(out))` gives `mech: output already exists: <out>`, exit code 1,
  before a file is read.
- F2: fold on the files with `Acc{env, mods, carrier, bad}`; file i uses `Et.emit_source(env, text)` and the `Es.env`
  result goes to file i+1. A file after a refused file is not read.
- D7: module name = stem (text after the last `/`, `.mech` removed), `-` to `_`, then `Et.rust_name`. The stem must be
  a lower-case letter, then `[a-z0-9_-]*`. Reserved module names: `bin`, `lib`, `main`, `nat`. Lines:
  `refused: module name collision (D7): <n>` and `refused: name collision (D7): <n>` (item names of all modules plus
  `Nat`, `nat_small`, `nat_add`, `nat_decimal`). Each refusal gives exit code 65 and no crate.
- R7: `use crate::<m>::*;` only for a module before this one that has an item name in the names that this module
  mentions (types, called functions, families), plus `nat`; sorted by byte.
- `src/nat.rs` text is in `rust_out.bend` (`nat_rs`), byte-equal with W/target-crate; written only if a module uses it.
- D2 carrier: lines of the text; a chunk starts at a column-1 lower-case letter; the `--` lines directly before it go
  with it; chunk i = declaration i of `Parser.program`; count mismatch, a chunk without ` <first name>`, or a
  declaration with runtime and non-runtime names = refusal. Non-runtime = `CProp`, `CType`, `CAbsurd`.
  Text: one header line, then `-- from <file>` + blank line + chunks for each file with carried chunks.
- Write: temp directory by fs op 1 next to the target, root files, `src` by a second op 1 + rename, then one rename
  to the target. A write failure leaves `<out>.tmp-*` (known limit).

Checks (`zsh W/b4-crate.sh emit`): byte-equal with W/target-crate: Cargo.toml, src/lib.rs, src/init.rs,
src/second_price.rs, src/nat.rs. `rustfmt --check` OK. `B4-CARRIER 2 files, 26 heads, 160 lines`. Refusals OK:
existing output (exit code 1), neg_classify.mech (65, no crate), module name collision (65), bad file stem `X1.mech`
(65), no input file (usage, 64). No temporary directory left.

New facts:
- F22: a recursion that is not a tail call over the characters of a file text gives
  `bend: memory fault (machine stack overflow?)`, exit code 1, in the JS build. Use an accumulator and a tail call
  (`lines_go`), keep chunks as lists of lines, and keep the left operand of `++` short.
- F23: the gateledger hook denies a runner script that has `cargocho clippy`. For a crate outside each git tree, put
  `[skip-gateledger]` on the script line and on the Bash command.
- F24: `effects/fs.js` has no mkdir operation. A nested directory = op 1 (mkdtemp) + op 2 (rename).

NOT tested: `bend2/main.bend` was not built, so the real `mech rust-out` dispatch case is not run (the driver uses the
same `run`). The carrier names are not compared with the classify table, and the carrier is not checked by `mech`.
b1/b2/b3 scripts were not run again (`erase_typed.bend` and `emit.bend` have no change; the driver has one new mode).
Known limit: a local closure with the name of a function of an earlier module counts as a use of that module.
Open from B3, no change: the `!c` form of R4, the deref node.

NEXT: B5 (read its definition in the 50-80 window). First: `zsh W/b4-crate.sh` (the two stages; the cargo stage
needs the Bash sandbox off), then the carrier check against the classify table. NEVER commit or push.

### 2026-10-03 B5 part 1 (claude6, session 77201407)

STATE: B5 PARTIAL, NOT STAGED. B4 confirmed GREEN first (`zsh W/b4-crate.sh` emit stage in the sandbox, then
`zsh W/b4-crate.sh cargo` with the sandbox off; the Bash command needs the `[skip-gateledger]` tag too).
The driver build is RED (F25 below), so no B5 check ran yet. The session stopped at the 150k context mark.

Files written (worktree, all UNSTAGED, none of them built green yet):
- NEW `bend2/tests/rust_emit_oracle.bend` (import name `Or` in the driver): `values`, `probes`, `bin`, each takes
  `List<String>` = the `.mech` files in order; the probes are the declared names of the LAST file.
  - `values`: one line `<name> = <text>` for each probe (`<name> ! <why>` on an evaluation error, exit code 0).
    Printer: `VLit{LInt}` = decimal; `VIn{SMu{fam,_}, VACtor{c}, args}`: class by `Et.family_or_skip`,
    `CBool` = `true`/`false` (`mechTrue`), `IUnit` = the family name, `IEnum` = `Et.upper_first(c)` + the kept fields
    in `(.., ..)`; kept = `Some` in `Et.ctor_tys(env, Global.find_family(fam, globals), c)` by position (F3/F6).
  - `probes` (D6): for each declared name with class `CFn`, no generic, closed result (`MechBool`, `Nat`, or a family
    with no parameter and no index) and inputs for each parameter (`TBool`: 2, `MechNat`: 0/1/2, a fieldless family
    with no parameter: each constructor; `TRef` is transparent): one line
    `def probe<UpperFn><labels> : <ret> := <fn> <args>`, all combinations, left parameter slowest.
    auctionCompare (dependent result) and auctionChoice (erased parameters) get no generated probe by this rule.
    Known limit: a first-order function with an erased binder that this rule does not see gives probes that do not
    check; then the gate stops at "kernel values".
  - `bin`: text of `src/bin/diff_exec.rs` (`use mech_out::<Et.stem(last file)>::*;`, one `println!("{:?}", f());`
    for each probe, `Et.fn_name`).
- `bend2/tests/rust_emit.bend`: import `Or`, modes `values | probes | bin` (`oracle_of`, three `Md` cases, usage).
- NEW `test/rust/emit/probes.mech`: 20 hand-written probes (unit struct, MechSum values, MechDecidable value with an
  erased field, mechBoolRec, mechSumRec, mechNatRec, mechDecidableBool, mechJ, mechTransport, auctionCompare,
  auctionChoice, auctionToNative 3). NOT checked by the kernel yet; the syntax is a guess from the two inputs.
- NEW `dev/rust-out-diff-exec.sh` (zsh, executable): driver build, 2-file crate vs goldens `test/rust/emit/crate/*`,
  `probes` vs `test/rust/emit/generated-probes.mech`, `values` vs `test/rust/emit/values.txt`, 3-file crate
  (third module `probes` = generated + hand-written) + `src/bin/diff_exec.rs`, plain `cargo build -j 2` in
  `$TMPDIR/mech-diff-exec`, one PASS/FAIL for each value, mutation control (python3 swaps the two `AuctionChoice::`
  arm patterns in a copy of `src/second_price.rs`, must give 1 or more different values), DIFF-EXEC-OK/FAIL.
  First argument `emit` stops before cargo and prints the run directory. Not run past the driver build.

New facts:
- F25: Bend 2.0.25 has no forward reference (`expected : a defined name`): a def can call only itself and the defs
  above it. So mutual recursion is not available; erase_typed uses job data (`Plan`/`Job`) for this reason.
- F26: `match` takes only a parameter or a pattern field (`a match cannot scrutinize a computed value: give it its
  own def`).
- F27: main-loop hooks in this session: Read cap 150 lines for each call, a context watchdog from 98k, hard stop near
  165k. The fixed prefix of the session is about 70k, so B5 needs two or more sessions.

NOT done (all of the B5 list after the first build): goldens (`test/rust/emit/crate/{Cargo.toml,mech-carrier.mech,
src/*.rs}`, `generated-probes.mech`, `values.txt`: copy them from the `emit` run directory after a manual check),
`bend2/rust/EMIT.md`, the carrier check against the classify table, stage, `W/COMMIT-MSG-B.txt`. The order of the
`VIn` fields against `Ctor.args` is not confirmed (each M0 constructor has 0 or 1 kept field).

NEXT (fresh session; do not read the kernel, B-LEARN.md or the oracle file in full):
1. WRITTEN in session 77201407 (second part), NOT BUILT: the printer is now `Item`, `kept`, `more_items`,
   `field_items`, `ctor_items`, `whnf_items`, `items_of`, `render`, `shown`, `eval_show` (lines 22-110); a scan
   of the old file found no other forward reference. Start with the build (step 2) and fix what the compiler
   reports. A missing field now gives a short value (the gate then shows FAIL for it), not an error line.
   The plan was: fix F25 in `rust_emit_oracle.bend`: (a) move `shown` above `eval_show`; (b) replace the mutual group
   `show` / `show_whnf` / `show_class` / `show_kept` / `show_field` by one self-recursive def over a work list.
   Sketch: `type Item = IVal{v: V.T} | IText{s: String}`; non-recursive `expand(env, whnf result) ->
   Result<.., List<&2, Item>>` (literal = `[IText]`; constructor = `IText` name, then for 1 or more kept fields
   `IText "("`, `IVal` fields with `IText ", "` between them, `IText ")"`); `render(env, todo, out)` pops one
   item, appends `IText` to `out`, and for `IVal` pushes `expand(..)` in front of `todo` (own list append def;
   the whnf call goes through a helper def above `render` because of F26).
2. `zsh dev/rust-out-diff-exec.sh emit` in the sandbox until the build and the `values` step pass (golden FAIL
   lines are expected until step 3). Read `values.txt` in the run directory: no ` ! ` line, values as expected.
3. Make the goldens, then the full gate with the sandbox off (sccache). If a hook denies plain `cargo build` in the
   script, keep `cargo` in the script and ask the USER; do not put a private CLI in a repo script.
4. EMIT.md, carrier check, stage own paths, `W/COMMIT-MSG-B.txt` (no Co-Authored-By). NEVER commit or push.

### 2026-10-03 B5 part 2 (claude6, session 4ba6ffda)

STATE: B5 PARTIAL, NOT STAGED. Driver build GREEN. Emit stage GREEN (8 golden PASS). Cargo stage RED (F30).

Done:
- `bend2/tests/rust_emit_oracle.bend`: new `keep_one(t, a, tail)`; `kept` calls `keep_one(t, a, kept(rest, more))`
  (F26 again: a match on a pattern field is refused when a different match is between the binder and its use).
  `render` is `@unsafe def` (F28).
- `dev/rust-out-diff-exec.sh`: `ulimit -s "$(ulimit -Hs)"` after `set -u`, `node=(${NODE:-node} --stack-size=16384)`,
  each driver call is `$node $O/re.js ...` (F29). The header comment names NODE and dev/BEND2-BASELINE.json.
- Goldens written from an `emit` run after a manual check: `test/rust/emit/crate/{Cargo.toml,mech-carrier.mech,
  src/{lib,init,nat,second_price}.rs}`, `generated-probes.mech` (218 probes of 13 functions), `values.txt` (238
  values, no ` ! ` line). The 20 hand-written probes of `probes.mech` check in the kernel. Kernel text of a `MechNat`
  is `MechSucc(MechSucc(MechZero))`, of a `Nat` is decimal, of a `MechBool` is `true` / `false`.
- The full gate ran with the sandbox off. No hook denied the plain `cargo build` of the script.

New facts:
- F28: Bend 2.0.25 has a termination guard (`expected : a decreasing self-call`). The repo idiom for a loop that is
  not structural is `@unsafe def` (emit.bend, erase_typed.bend, rust_out.bend have it).
- F29: with the default node stack the 3-file crate write gives `memory fault` between 60 and 120 probe lines
  (`probes.rs` is 56 KB for 238 probes). It passes with the repo baseline (hard `ulimit -s` + `--stack-size=16384`).
  OPEN: a recursion of the crate path that is not a tail call grows with the module size (F22 class). Not found.
- F30: cargo RED on the probe crate, 2 errors, one cause (read-only diagnosis agent, lines verified by the agent):
  E0631 at `src/probes.rs:1686` and `:1694` (probeSumRecInl / Inr): `&|_b: bool| MechNat::MechZero` goes to
  `right: &impl Fn(&B) -> C` with `B = bool`. Cause in `erase_typed.bend`: `lams` (1257-1263) / `slot_of`
  (1240-1243) take the binder mode from the lambda's own domain (`mode(copies, q, t)`, `TBool` stays by value).
  The declared parameter type of the callee reaches the lambda only as a `Want`: `arg_step` (1166-1167) has the
  declared `TFn{[&B], C}`, `want_of` (982-987) makes it `WRef` and drops the argument list; `plan_term` (1417-1418)
  calls `lam_plan(want, lams(..))`. The 2-file crate has one closure (`second_price.rs:103`, ref/ref), so B4 is GREEN.
  Fix plan F1: a `Want` variant with the declared argument list (`wanted` 942 and `ref_use` 956 treat it as
  `WRef`), `plan_term` gives the list to `lams`, binder i takes the reference mode of declared argument i.
  Expected: no change of the goldens.
- F31: the step-budget hook denies Bash AND Edit after 20 tool steps in one user turn. An agent hand-back does not
  reset the count; only a USER message does. Batch the calls; put a multi-step inspection in ONE runner script.
  An rg sweep anchored on `fn` over `.rs` is denied: use `symx`.
- F32: with the sandbox off, TMPDIR is `/private/var/folders/d4/.../T`, so the cargo run directory is
  `$TMPDIR/mech-diff-exec/run.*` there, not below `/tmp/claude-501`.

NEXT (main loop, hand build):
1. Fix F30 (plan F1), rebuild the driver, `zsh dev/rust-out-diff-exec.sh` (sandbox off) until DIFF-EXEC-OK. If
   `init.rs` or `second_price.rs` change: refresh the goldens and rerun B4 (`zsh W/b4-crate.sh cargo`,
   `[skip-gateledger]`).
2. EMIT.md (with the F29 stack rule and the D6 probe limits), carrier check, stage own paths,
   `W/COMMIT-MSG-B.txt` (no Co-Authored-By). NEVER commit or push.

### 2026-10-03 B5 part 3 (claude6, session 4ba6ffda, same session as part 2)

STATE: B5 gate GREEN, NOT STAGED. `zsh dev/rust-out-diff-exec.sh` with the sandbox off: 8 golden PASS, 238 value
PASS, `PASS mutation control is RED: 88 values differ`, `DIFF-EXEC-OK 238 values`, exit code 0.
The session stopped at the 150k context mark. EMIT.md, the carrier check, staging and the commit message are OPEN.

Done:
- F30 fixed in `bend2/rust/erase_typed.bend` (plan F1, first build green):
  - `Want` has `WFn{args: List<&2, R.Ty>}`; `wanted` and `ref_use` treat it as `WRef`.
  - new `fn_want`; `want_of` gives `WFn{args}` for `TRef{TFn{args, ret}}`.
  - new `borrowed`, `as_decl`, `decl_ty`, `decl_slot`, `decl_tail`, `decl_rest` above `lams`; `lams` has `+decl`
    (the declared argument types that remain; an erased binder takes none).
  - the old `lam_plan` is `lam_done`; new `lam_plan(env, ks, vs, want, t)` matches on `want` (`WFn{args}` gives
    `lams(.., args, t)` and `BClosure{params, WRef{}}`); `plan_term` calls it.
- The probe closure is now `&|_b: &bool| MechNat::MechZero`. The goldens did not change (8 golden PASS with the
  new driver), so B4 (`W/b4-crate.sh`) was NOT rerun.

For EMIT.md (limits, not checked by a probe):
- Only the borrow direction is adapted (declared `&T`, Copy binder). A `&bool` binder that the body uses by value
  gives `b.clone()` (`ref_use`); no probe has this case (`_b` is not used).
- F29 stack rule for the JS build. D6 probe rule limits (dependent result, erased parameters: hand-written probes).

NEXT (fresh session; the gate is green, do not change the emitter):
1. `bend2/rust/EMIT.md`.
2. Carrier check against the classify table.
3. Stage own paths (compare with the B1..B4 entries first): M `bend2/cli/mech.bend`, M `bend2/rust/print.bend`,
   `bend2/cli/rust_out.bend`, `bend2/rust/{emit,erase_typed,rir}.bend`, `bend2/tests/{rust_emit,rust_emit_oracle}.bend`,
   `dev/rust-out-diff-exec.sh`, `test/rust/emit/`, `test/rust/parse/15_empty_match.rs`.
4. `W/COMMIT-MSG-B.txt` (no Co-Authored-By). NEVER commit or push.
Open, not a blocker: the F29 recursion. The MEMORY.md line of this project still says "driver build RED".

### 2026-10-03 B5 part 4 (claude6, session b53338b8): B5 CLOSED, unit B STAGED, NOT COMMITTED

STATE: NEXT steps 1-4 of part 3 are DONE. 21 files staged (19 A + 2 M) on HEAD 653a27e, tree a4d0db7d, nothing
unstaged, `git diff --cached --check` clean. The emitter has no change in this session.

Done:
- NEW `bend2/rust/EMIT.md` (files, command + exit codes, classes, erasure rules, names D7, carrier, refusal reasons
  from the strings of `erase_typed.bend`, driver modes, fixtures + gate + stack rule F29, known limits).
- NEW `W/b5-carrier.sh [<re.js>]` (own driver build, `classify` of the two inputs, python3 compare). Result (sandbox):
  `B5-CARRIER-OK 26 heads (prop 23, type 2, absurd 1) from 2 files, verbatim, equal to the table order; 30 runtime
  names, none in the carrier`.
- `dev/rust-parse-gate.sh` (sandbox): `pass=35 fail=0`, `RUST-PARSE-OK` (the print.bend change + fixture 15).
- NEW `W/COMMIT-MSG-B.txt` (no Co-Authored-By).

NOT run in this session: the full DIFF-EXEC gate (cargo, sandbox off). Its last run is part 3 (GREEN, 238 values).
USER command: `git -C ~/Documents/mechanism-lang-rust-m0 commit -s -F ~/Documents/mech-rust/COMMIT-MSG-B.txt`
Open, not blockers (all in EMIT.md "Known limits"): the F29 recursion; `bend2/main.bend` is not built, so the real
dispatch case is not run; the gate does not run `neg_classify.mech`. NEVER commit or push.

UPDATE 2026-10-03 (same session): the USER said "Go ahead and commit and push". COMMITTED as 317131b (tree a4d0db7d,
`-s`, Signed-off-by only) and PUSHED to origin `mech-rust/m0` (push with the sandbox off: in the sandbox git cannot
read `/etc/ssl/cert.pem`). The remote reported `[new branch]`, so the branch was not on the remote before this push;
653a27e (unit A) went up with it. Local = remote after the push. Unit B is CLOSED.
