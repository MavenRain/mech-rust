# mech-rust unit C progress (Rust -> mech importer, RUST-IN)

Scope source: design brief sections 4.2, 5, 6, 8.1, 8.3, 9 and 10 (M1).  M0-PLAN.md has NO unit after B (CF1).  The
scope of C below was the choice of the opening session;  the USER RULED it on 10-04 (Rulings, U1).
Worktree /Users/oobi/Documents/mechanism-lang-rust-m0.  Branch mech-rust/m1 (U2), to be created at 317131b (unit B,
on mech-rust/m0, pushed per B-PROGRESS.md) as the first step of C0;  the tree was clean at the start of C.
W = /Users/oobi/Documents/mech-rust-m0.
NEVER commit or push.  Stage own paths only.  No Co-Authored-By line.  One sub-unit per fresh session.  Read this
file's tail first, then the C-LEARN.md sections named in the sub-unit.  Build mode: wf-builder agents (U4, section
"Build mode").  The rules of M0-PLAN.md "Shared setup and rules" stay in force: never touch
/Users/oobi/Documents/mechanism-lang;  do not run dev/gates.sh;  stop if one Bend run exceeds 20 minutes;  disk floor
30 GiB;  cargocho with at most 2 jobs;  rg/sd;  no `cd X &&` or `VAR=` prefix;  no em-dashes.

## Start state 10-03 (claude6, session a6159075; read-only probes, no worktree change)
CF1  M0-PLAN.md has two units, A and B.  Brief section 10: M0 = RUST-PARSE + mech -> Rust with DIFF-EXEC on
     second-price.  A = 653a27e, B = 317131b.  So M0 is complete and C is the first M1 unit.  M1 (brief 10): both
     directions for structs, enums, functions, `match`, structural recursion, RsOption, RsResult, RsVec, integers per
     Q4, name mangling, the carrier;  all section 9 gates on the seed corpus.
CF2  Worktree: `git status --short` is empty, `git log` head is 317131b.  No fetch was run.  Disk: 40 GiB free.
CF3  Files of A + B (lines): bend2/rust/ ast 149, token 79, lexer 209, parser 1357, fragment 229, print 837, rir 58,
     erase_typed 1878, emit 209, FRONTEND.md 93, EMIT.md 192;  bend2/cli/rust_out.bend;  drivers bend2/tests/
     rust_frontend 108, rust_emit 204, rust_emit_oracle 378;  gates dev/rust-parse-gate.sh, dev/rust-out-diff-exec.sh.
CF4  RIR (rir.bend, read in full).  Ty = TBool | TCon{name,args} | TBox | TRef | TFn{args,ret}.  Ex = XVar | XInt |
     XBool | XCall{func,targs,args} | XCtor{family,ctor,args} | XMatch | XIf | XClosure | XBorrow | XClone | XBox.
     Pat = PCtor{family,ctor,binds}, Bind = BVar | BSkip.  Item = IUse{module} | IEnum{name,generics,copy,variants} |
     IUnit{name,ctor} | IFn{name,generics,params,ret,body}.  Module{source,items}.  Each name is a final Rust name.
     Each `.clone()`, `&` and `Box::new` is an explicit node.  emit.bend lowers RIR to A.SrcFile and A's printer
     prints it (D1 of unit B).
CF5  A's AST (ast.bend) has `Meta` (gap, docs) and `SrcFile` with `inner` (the `//!` lines).  It has no position
     field (rg for pos/line/col finds none).  Positions exist only at token level (fragment pass).
CF6  Golden crate test/rust/emit/crate: Cargo.toml, mech-carrier.mech (160 lines, 26 declarations), src/init.rs 74,
     src/second_price.rs 113, src/nat.rs 55 (fixed text), src/lib.rs 5.  A module file has one `//!` line
     ("Emitted by `mech rust-out` from `<input file>`."), then sorted `use crate::<m>::*;` lines, then the items.
     lib.rs has the `pub mod` lines SORTED by name (rust_out.bend:565), so it does not hold the input order.
     Reserved module names: bin, lib, main, nat (rust_out.bend:71).
CF7  EMIT.md classes of the two M0 inputs: 22 fn, 7 data, 1 bool (MechBool), 23 prop, 2 type, 1 absurd.  MechBool
     (init.mech:8) has no Rust item and is not in the carrier (carried classes: prop, type, absurd).
CF8  Erasure is lossy on the M0 inputs (EMIT.md "Erasure rules"): quantity-0 binders that are not types, Prop
     binders and fields, indices and levels are dropped;  `P a b` becomes `P`.  Example: init.mech:26 MechDecidable
     (0 P : Prop), two constructors with one quantity-0 field each, becomes an enum with two variants and no field.
     So the import of the golden crate is a simply typed program.  It is NOT alpha-equal to init + second-price, and
     the carried proofs name the original types.  RT-MECH holds only on canonical mech (brief 6).  It is not a gate
     of C on the M0 inputs.
CF9  D7, direction mech -> Rust (EMIT.md "Names"): def camelCase -> snake_case;  constructor mechZero -> MechZero;
     family name kept;  a Rust keyword gets `_`;  module = file stem with `-` -> `_`.  The file stem is in the `//!`
     line (second-price.mech), not in the module name (second_price).
CF10 surface/syntax.bend has the types Decl (78), T (36), RecDef (33), Fam (30), FamCtor (27), Branch (23), Motive
     (17), Binder (14) and the text functions `show(term)` (263), `decl_text` (357), `print(decls)` (382) and a
     precedence printer (`at`, 569).  NOT verified: that the text of `print` parses back to the same Decl list.
CF11 `checked_form(rows)` is in surface/elab.bend (API.md:39).  Check entry (B-PROGRESS.md header):
     `Elab.check_in(Global.initial(), Budget.unlimited(), source)`;  `kanon build` joins the files with "\n".
CF12 cli/mech.bend `dispatch` has the cases `import` (107), `diff-parity` (115), `map-inventory` (121), `rust-out`
     (129).  `rust-in` is free.  No M0 gate builds bend2/main.bend, so no gate runs a dispatch case.
CF13 Limits of A and B that touch C (FRONTEND.md + EMIT.md "Known limits"): the only struct form is the unit struct;
     no `let`;  a raw identifier prints without `r#`;  the fragment pass reads tokens only;  the crate write has the
     F29 recursion (stack rule in the DIFF-EXEC gate).
CF14 From B-PROGRESS.md and the memory topic, not verified again: bend is ~/.bend/bin/bend 2.0.25 (pin 2.0.27);  a JS
     build (`bend <driver> -o x.js`, then node) is the fast path for a driver with many runs;  cargo, clippy and
     `git push` need the Bash sandbox off.

## Scope of unit C (RULED 10-04, U1)
`mech rust-in <crate dir> <out dir>` for the Rust fragment that unit B emits (the image of RIR): a Rust crate becomes
one `.mech` file for each module and a manifest in dependency order.  Brief 4.2 steps 3 (resolve), 4 (infer),
6 (lower) and 7 (mech check).  Steps 1, 2 and 5 are unit A.
Target: the golden crate of unit B imports to a program that passes the kernel check (MECH-CHECK), and `rust-out` of
that program gives the golden crate back byte for byte (RT-RUST).
Files: bend2/rust/{lift,resolve,infer,lower}.bend, bend2/rust/IMPORT.md, bend2/cli/rust_in.bend and one dispatch case
in bend2/cli/mech.bend, bend2/tests/rust_import.bend, test/rust/import/, dev/rust-in-gate.sh.
C0 changes files of A and B for the positions (U3): ast.bend, parser.bend, print.bend, emit.bend, FRONTEND.md and
the driver rust_frontend.bend.
A change to a file of A or B needs a rerun of the gate of that unit (RUST-PARSE: dev/rust-parse-gate.sh, last
pass=35;  DIFF-EXEC: dev/rust-out-diff-exec.sh, last 238 values, sandbox off).
Not in C (later M1 units, HYPOTHESIS): growth of the fragment on both sides (struct with private fields and
accessors, `let`, method calls, RsOption/RsResult/RsVec and the Q7 combinators, integers Q4, `vec!` Q9);  the
carrier merge keyed by item path (Q3) and RT-MECH on a canonical seed corpus;  Rust input outside the image of the
emitter (8.1 inference for closures and `let` with no annotation, 8.3 use counts);  the REFUSAL and RUST-CLEAN gates
on the seed corpus.

## Sub-units (as for A and B: each ends with checks clean, a driver mode that shows the result, and a log entry here)
C0 Branch + crib + positions (U2, U3).  Step 1: create the branch mech-rust/m1 at 317131b.  Agent 1: the crib
   W/C-LEARN.md, sections L1-L7 (the list is in the log entry "C OPENED", step 2);  it reads the worktree and writes
   only that file.  Agent 2: positions per CD13.  Files (units A and B): bend2/rust/ast.bend, parser.bend, print.bend,
   emit.bend (position 0:0), bend2/rust/FRONTEND.md (one paragraph), driver bend2/tests/rust_frontend.bend with a
   new mode `pos` (one line for each item: `<line>:<col> <kind> <name>`).  No change to token.bend, lexer.bend or
   fragment.bend unless the parser needs it for the token position (name the change in the log).
   Done when: mode `pos` gives the correct line:col for each item of the first parse fixture (compare with `rg -n`),
   dev/rust-parse-gate.sh gives pass=35 and RUST-PARSE-OK, and dev/rust-out-diff-exec.sh gives DIFF-EXEC-OK (238
   values;  main loop, sandbox off).
C1 Lift.  bend2/rust/lift.bend: A.SrcFile
   -> R.Module, the inverse of each lowering function of emit.bend (`//!` line -> source;  `use crate::m::*;` ->
   IUse;  derive list + enum -> IEnum, copy flag from `Copy` in the derive;  unit struct + constructor fn -> IUnit;
   `pub fn` with `Clone` bounds -> IFn;  types, patterns and expressions node by node).  A shape outside the image is
   a refusal (CD13).  Driver bend2/tests/rust_import.bend, mode `lift`: prints `Em.text(lift(parse(file)))`.
   Done when: the output is byte-equal to the input for init.rs and second_price.rs of the golden crate, and one
   negative file (a `let` statement) gives a refusal line with the line:col of the `let`.
C2 Resolve + names.  bend2/rust/resolve.bend: module list and CD3 order;  item table (enum, variant, unit struct,
   constructor fn, fn);  each name in a body resolves (a local shadows an item;  the `use` lines give the visible
   modules;  the `nat` items per CD7);  CD5 inverse names with the canonical-name and collision checks;  CD4 file
   names.  Driver mode `resolve`: one line for each item, `<module> <kind> <rust name> -> <mech name>`, then the
   manifest order.  Done when: the table has the 22 fn and 7 data of CF7, D7 of each mech name gives the Rust name
   back, and the order is init, second_price.
C3 Infer.  bend2/rust/infer.bend (CD8, CD9): signatures -> mech telescopes;  a typed copy of each body with the type
   arguments of each XCtor and the result type of each XMatch;  the CD9 refusal.  Driver mode `types`: one line for
   each fn with its telescope and the count of annotated nodes.  Done when: all 22 fn lines print with no refusal.
   The full check of the telescopes is the byte comparison of C4.
C4 Lower + text + check.  bend2/rust/lower.bend: IEnum -> `mu` family (generics -> quantity-0 type parameters, TBox
   dropped);  IUnit -> family with one constructor;  IFn -> `def` or `def rec` (CD10);  XMatch -> case with one
   branch for each constructor (BSkip -> a binder with no use);  XIf -> case on MechBool;  XBool -> mechTrue or
   mechFalse;  XCall -> application, type arguments first;  XClosure -> `fun`;  XInt and the nat names per CD7;
   MechBool per CD6.  Text per CD11.  Driver mode `lower` prints the `.mech` text of each module.  Mode `check`
   joins the files in manifest order, runs `Elab.check_in`, and prints `MECH-CHECK-OK <n> rows` or the kernel error.
   Then give the text to the driver of unit B (mode `emit`) under $TMPDIR.  Done when: `check` is OK with no
   postulate row, and the init.rs and second_price.rs that come back are byte-equal to the golden files.
C5 CLI.  bend2/cli/rust_in.bend and the dispatch case `rust-in`: `mech rust-in <crate dir> <out dir>`;  read
   src/lib.rs, then src/<m>.rs for each `pub mod` (CD7 for nat);  refuse an out dir that exists (as rust-out);  write
   one `.mech` file for each module and `MANIFEST` (one file name on each line, dependency order);  copy
   `mech-carrier.mech` with no change if the crate has one (no merge in C);  exit codes as rust-out (EMIT.md
   "Command").  Driver mode `run` calls the same `run` as the verb.  Done when: the JS build of the driver writes the
   out dir under $TMPDIR from the golden crate, and `rust-out` on the MANIFEST files gives a crate with Cargo.toml
   and src/ byte-equal to the golden crate.
C6 Gate + close.  dev/rust-in-gate.sh (CD12): LIFT lines (one for each module file), MECH-CHECK, RT-RUST lines (one
   for each crate file, the carrier excluded), refusal fixtures test/rust/import/refuse/* + EXPECTED.tsv (at least:
   `let`, a struct with fields, a method call other than `.clone()`, a name that is not canonical, a changed nat.rs,
   mutual recursion, a module cycle, a constructor with no expected type).  Mutation controls in $TMPDIR copies, each
   must be RED: swap two constructors in one imported `.mech` file (RT-RUST);  make the recursive call of
   auction_compare `auction_compare(tie_wins, bid, price)` in a copy of second_price.rs (MECH-CHECK, RED with the
   totality error).  Only if the cost is small: DIFF-EXEC of unit B on the imported program (it needs the input list
   of dev/rust-out-diff-exec.sh as a parameter, a file of B).  Goldens test/rust/import/expected/*.mech.
   bend2/rust/IMPORT.md.  Stage own paths.  W/COMMIT-MSG-C.txt (no Co-Authored-By).

## Design defaults (HYPOTHESES; each is confirmed or changed in the sub-unit that names it)
CD1  Pipeline: tokens -> fragment pass -> A.SrcFile (unit A) -> `lift` to R.Module -> resolve -> infer -> lower to
     Syntax.Decl -> text -> kernel check.  The importer accepts exactly the image of emit.bend.  Reason: RIR is small
     (11 expression nodes), and the law `emit(lift(f)) == f` has a check for each file.  (C1)
CD2  REPLACED by CD13 (U3 RULED 10-04: positions in A's AST).
CD3  Module order: topological order of the `use crate::<m>::*;` edges, ties by byte order of the module name
     (CF6: lib.rs is sorted).  A cycle is refused in C (brief 5 merges a cycle into one file;  later unit).  (C2)
CD4  Output file name: the file in the `//!` line if the line has the form of the emitter, else `<module>.mech`.
     RT-RUST needs it: the emitter writes the input file name into the `//!` line (CF6, CF9).  (C2)
CD5  Names: the inverse of D7 (snake_case -> camelCase def;  UpperCamel variant -> constructor with a lower-case
     first letter;  remove the keyword `_`).  A Rust name is canonical if D7 of its inverse gives the name back.  Any
     other name is refused.  The mech names get a collision check too.  (C2)
CD6  `bool`: if the crate uses `bool`, the importer writes
     `mu MechBool : Type 0 with | mechFalse : MechBool | mechTrue : MechBool` at the top of the first file in
     manifest order.  On the way back it has the class `bool` and makes no Rust item, so RT-RUST holds.  Alternative:
     a support file of the M1 prelude (later unit).  (C4)
CD7  `nat` module: src/nat.rs is not parsed.  It must be byte-equal to the fixed text of the emitter, else the crate
     is refused.  `Nat`, `nat_small(<n>)` and `nat_add` map to the kernel `Nat`, the literal and `natAdd`.  (C2, C4)
CD8  Quantities from RIR types (inverse of EMIT.md "Ownership"): TRef{T} -> many;  owned T in the Copy set -> many;
     owned T outside the Copy set -> 1;  TFn -> a function type at quantity many;  a generic -> `(0 T : Type 0)` in
     declaration order.  `lower` drops XBorrow, XClone, XBox, TBox and TRef;  the emitter makes them again.  C has no
     use count: the kernel quantity check refuses a wrong use (a MECH-CHECK failure with the kernel text).  (C3)
CD9  Inference is checking-mode first: a fn body against the return type, call arguments against the parameter types
     after the turbofish substitution, match arms against the expected type, a closure against its TFn.  Synthesis
     only for XVar and XCall.  Results: the type arguments of each XCtor of a generic family, and the result type of
     each XMatch (for a motive, if the surface needs one, L5).  An XCtor of a generic family in a synthesis position
     is refused ("no expected type").  (C3)
CD10 Recursion: an IFn that calls itself becomes `def rec`.  The kernel totality check is the refusal for recursion
     that is not structural (brief 5).  Mutual recursion is refused in C.  (C4)
CD11 Text: `Syntax.print`, if C1 shows `parse(print(d)) == d` on the declaration shapes of CD1 (CF10);  else a small
     printer in lower.bend.  (C1 learn, C4)
CD12 Gate RUST-IN: one PASS/FAIL line for each check, then `RUST-IN-OK` or `RUST-IN-FAIL`;  JS build of the driver;
     all outputs under $TMPDIR.  (C6)
CD13 Positions (U3;  CORRECTED in C0 from the crib, L2): `A.Pos{line, col}`, one-based, printed as the fragment pass
     prints it (`A.show_pos`).  Where: the field `pos` of `Meta`.  It is the first token of the construct AFTER its
     outer docs and attributes (so an item with a derive line has the position of `pub`, not of `#`).  L2 shows that
     only items, fields, variants, statements (SLet, SExpr) and arms have a `Meta`;  the 17 expression constructors
     of Node, the types and the patterns have none.  So an expression, type or pattern has no position of its own:
     a refusal for one of these takes the position of the nearest statement, arm or item.  A field on each Node
     constructor was not chosen (26 constructors, each match in parser.bend and print.bend names all fields).
     emit.bend gives the position 0:0 (`A.no_pos()`).  The printer does not read positions, so the print law has
     no change.  RIR gets no positions (it is the IR of unit B;  the 1878 lines of erase_typed.bend build it).  So
     a refusal of lift is `<file>:<line>:<col>: <construct>`, and a refusal of resolve, infer or lower has the
     position of its ITEM (a table from lift: item name -> Pos, from `A.item_pos`) and the construct name.  (C0, C1)

## Build mode (U4 RULED 10-04: wf-builder agents)
- One wf-builder agent for each sub-unit (C0 has two), one at a time: the sub-units share the driver file.  Fable
  xhigh.  If the agent dies: one relaunch on opus xhigh with the marker, then HALT and ask the USER (tier rule
  10-03).  Never sonnet.
- The prompt holds, inline: the sub-unit text, the CF and CD items that it names, the names of the C-LEARN.md
  sections to read, the file list, the done-when checks, and the text "(7 findings max, 56 agents max)".
- Agent rules: change only the listed files;  never commit, push or stage;  ONE runner script W/c<N>-<name>.sh for
  all checks (the Bash cwd of an agent resets between calls);  no `cd X &&` or `VAR=` prefix;  rg/sd;  read a large
  file by span, not whole.  Report: files changed, the last lines of the runner output, open points.
- The main loop does not trust the report.  After the notice it reads `git status`, runs the runner script again,
  and then writes the log entry.  A gate that needs cargo (DIFF-EXEC) runs in the main loop with the sandbox off.
- History: on unit A, three opus wf-builder agents died on the `[reasoning_extraction]` safeguard before any file
  change.  If that occurs again after the one relaunch, a hand build in the main loop needs a USER ruling.

## Rulings (RULED by the USER 2026-10-04)
U1 Scope of C: the importer on the M0 fragment, as above.
U2 Branch: a new branch mech-rust/m1 off 317131b, in the same worktree.  Not created yet (C0 step 1).
U3 Refusal location in the import passes: positions in A's AST (CD13;  a change to files of A and B, so C0 runs
   RUST-PARSE and DIFF-EXEC again).
U4 Build mode: wf-builder agents (the USER wrote "wd-builder";  read as wf-builder).  Section "Build mode".

## Log

### 2026-10-03 C OPENED (claude6, session a6159075): split written, no worktree change, nothing staged

STATE: this file only.  The worktree has no change (HEAD 317131b, clean).  No Bend run, no build, no agent.
Sources read: M0-PLAN.md (all), B-PROGRESS.md (header + B5 part 4), brief sections 4-10 and 12, EMIT.md (Classes to
Refusals, Known limits), FRONTEND.md (Known limits), rir.bend (all), heads of the golden crate.  All other items are
rg extracts (CF5, CF6, CF10-CF12).  W/C-LEARN.md does not exist yet.

NEXT at that time (SUPERSEDED by the entry of 10-04 below;  the L1-L7 list of step 2 is still the crib content):
1. Take the USER rulings U1-U4 if there are any.  With no ruling the defaults hold.
2. Write W/C-LEARN.md (a read-only agent or rg span extracts;  no whole-file read of parser.bend, print.bend or
   erase_typed.bend in the main loop):
   L1 emit.bend: each lowering def and the A node that it makes (the table that `lift` inverts).
   L2 ast.bend: the constructors of Node, Pat, Ty, Sig, Body, UseTree, Meta that L1 names.
   L3 syntax.bend:7-88: the constructors of Decl, T, Fam, FamCtor, RecDef, Branch, Motive, Binder.
   L4 Is `Syntax.print` parse-stable, or is it the precedence printer (`at`)?  Evidence: surface/VALIDATION.md,
      bend2/tests/surface_*.bend.
   L5 Surface text, with examples from init.mech and second-price.mech: a constructor of a family with parameters
      (are the parameters explicit arguments?), `case` with and without a motive, the default quantity of a binder
      and of a constructor field with no mark, `def rec`.
   L6 Where unit B keeps the nat.rs text, the Copy set and the D7 functions (erase_typed.bend, rust_out.bend), for
      reuse by the importer.
   L7 How rust_emit.bend and rust_frontend.bend take arguments and read files, and the JS build + node commands of
      the two gate scripts.
3. Build C1 per the sub-unit text.  Checks: `bend` check of each new file;  mode `lift` on the two golden modules.
4. Add the log entry here.  Update the memory topic project-mech-rust-transpiler.md.

### 2026-10-04 Rulings U1-U4 (claude6, session a6159075): recorded, no worktree change

RULED by the USER: U1 the importer as written;  U2 branch mech-rust/m1;  U3 positions in A's AST;  U4 wf-builder
agents.  Changes in this file: header, scope title, new sub-unit C0, C1 without the crib, CD2 replaced by CD13, new
section "Build mode", section "Rulings".  The branch does not exist yet: this session makes no worktree change.
CD13 is a HYPOTHESIS until the crib section L2 shows the constructors of A.Node.

NEXT (fresh session, C0):
1. Create the branch: `git -C /Users/oobi/Documents/mechanism-lang-rust-m0 switch -c mech-rust/m1` (HEAD stays
   317131b, tree clean;  no push).
2. Agent 1 (wf-builder): W/C-LEARN.md, sections L1-L7 (list in the entry "C OPENED" above, step 2).  L2 must also
   answer: which A.Node constructors have a `meta` field, and how the parser gets the position of a token.
3. Check the crib on disk (seven section headers).  Correct CD13 in this file if L2 changes it.
4. Agent 2 (wf-builder): positions per C0 and CD13.  After the notice: `git status`, the runner script again, mode
   `pos`, dev/rust-parse-gate.sh (pass=35), dev/rust-out-diff-exec.sh (238 values, main loop, sandbox off).
5. Add the log entry here.  Update the memory topic project-mech-rust-transpiler.md.  C1 is the next session.

### 2026-10-04 C0 DONE BY HAND (claude6, session 35625480): branch, crib (partial), positions;  STAGED, not committed

STATE: branch mech-rust/m1 at 317131b (local, NOT pushed).  6 files staged (83 insertions, 10 deletions), index
tree 7fce362a.  Not committed.  W has the new files C-LEARN.md and c0-pos.sh.
Build mode: both wf-builder launches for the crib died on `[reasoning_extraction]` before any file change: fable
req_011CfgtLBG8LZvzTBBqbviod, then the one opus relaunch with `[builder-tier-explicit]`
req_011CfgtPXSA1tLWTYaw6MWAW.  HALT per the tier rule.  The USER RULED a hand build in the main loop for THIS
session (question in the session, answer "Hand build, this session").  U4 stays the rule for the next sub-units.

Crib W/C-LEARN.md (seven headers): L1, L2 and L7 complete, L6 partial, L3, L4 and L5 OPEN.  The session did the
positions before the rest of the crib (L1 and L2 are the inputs of the positions) and then came to its context
limit.  C1 starts with the open crib sections.

Positions (CD13 CORRECTED above: `pos` in `Meta`, first token after the outer docs and attributes):
- ast.bend: type `Pos`;  `Meta` has the new last field `pos`;  defs no_pos, show_pos, meta_pos, item_pos.
- parser.bend: def head_pos;  the last MMeta arm sets `pos`.  No change to token.bend, lexer.bend, fragment.bend.
- print.bend: the two `Meta` matches name the new field and do not read it.
- emit.bend: m0, gap and the `Meta` of IUse give `A.no_pos()` (0:0).
- FRONTEND.md: the mode list and one paragraph.  rust_frontend.bend: mode `pos` (pos_lines, pos_report, MPos).

Checks (all in the main loop):
- Baseline before the change: RUST-PARSE pass=35 fail=0, RUST-PARSE-OK.
- `zsh W/c0-pos.sh`: C0-POS-OK.  Each of the 15 accepted fixtures gives the `rg -n` lines.  01_struct.rs: 5:1 Point
  (doc line 3, derive line 4), 10:1 Unit, 12:1 Meters, 14:1 Pair, 17:1 Wrapper (derive line 16).
- RUST-PARSE after the change: pass=35 fail=0, RUST-PARSE-OK.
- DIFF-EXEC after the change (sandbox off): DIFF-EXEC-OK 238 values;  247 PASS lines, 0 FAIL;  the mutation control
  is RED (88 values differ).
- `git diff --cached --check` is clean.  Disk: 32 GiB free at the end (floor 30).

Open points:
- An expression, type or pattern has no position (CD13).  `item_pos` gives 0:0 for an expression node.
- Mode `pos` prints top-level items only.  Nested items (mod, impl, trait) have a position in their `Meta`.
- c0-pos.sh takes column 1 for each top-level item (true for rustfmt-clean fixtures).
- test/rust/parse has 15 accepted fixtures (01..15);  the gate floor is 14.
- COMMITTED + PUSHED on USER ask (same session, after the hand-off text): commit acfdfd6 on mech-rust/m1 (signed
  off, no Co-Authored-By, tree 7fce362a), pushed to origin/mech-rust/m1 (new branch, tracking set).  The worktree
  is clean.  The C1 session starts at HEAD acfdfd6.

NEXT (fresh session, C1):
1. Read this file's tail, CD13, and C-LEARN.md L1 and L2.
2. Complete the crib: L3, L4, L5 and the open part of L6 (one wf-builder first;  if it dies, the tier rule).
3. Build C1 (lift) per the sub-unit text.  Add the log entry.  Update the memory topic.

### 2026-10-04 C1 session 1 (claude6, session 20fd1392): crib written by hand, C1 lift NOT built

STATE: the worktree has no change (HEAD acfdfd6, `git status --short` empty after the two dead agents).  Nothing
staged.  W has the new files c1-print-probe.bend and c1-crib.sh;  C-LEARN.md has L3, L4, L5 and L6 written.
Build mode: both wf-builder launches for the crib died on `[reasoning_extraction]` before any file change: fable
req_011Cfhn7tigrpdzay84UxWa5, then the one opus relaunch with `[builder-tier-explicit]`
req_011CfhnBKYmSMpWQeYPXY12p.  Hand build in the main loop (ruled in the session prompt for this session).
The crib reads took the main loop to its context limit (165k hand-off), so C1 has no file yet.

Crib results that touch a design default:
- CD11 CONFIRMED on the two M0 inputs: `zsh W/c1-crib.sh` gave C1-CRIB-OK (init.mech 26 declarations,
  second-price.mech 30;  for each: print(parse(T1)) == T1 and Same.declarations(parse(src), parse(T1)) = SAME).
  So lower.bend prints with `Syntax.print`.  The first run was held by the disk floor (28 GiB free);  the run
  passed when the disk was at 30 GiB again.
- CD9 / C4: each `case` of the two inputs has a motive (`as <self> in <Family> return <type>`), so lower always
  prints the motive.  A constructor term takes the fields only, no family parameter argument (L5 a, b).
- CD7: the nat module has FOUR names: Nat, nat_small, nat_add, nat_decimal (rust_out.bend:73).  CD7 names three.
- CD8: the Copy set is each enum with `Copy` in the derive list and each unit struct (copy_names,
  erase_typed.bend:815).
- C1 fact: the parser of unit A accepts `let` (8 parse fixtures have one), so the negative file of C1 reaches lift
  and the refusal position is the `pos` of the SLet meta.

Checks: W/c1-crib.sh C1-CRIB-OK (the probe copy in bend2/tests/ is removed at exit;  `git status --short` empty
after the run).  The worktree has no change, so RUST-PARSE and DIFF-EXEC have no new input and were NOT run.
The "Done when" checks of C1 were NOT run (no lift.bend).

Open points:
- Disk: 28 GiB free in the middle of the session, 30 GiB at the end (floor 30).  The cause is not this session
  (it wrote less than 30 KB).  The disk is at the floor, so the hook can hold the next gate run.  The `diskfree`
  dry run found 0K to reclaim (the only target/ dirs are HOT, 3.9G in total), so `diskfree --apply` gives no
  room.  The USER decides where the room comes from.
- The crib has points with the label NOT read or HYPOTHESIS (L3 prim_name, L5 e natAdd, L6 copy flag and the
  `-` -> `_` step of the module name).  They are inputs of C2 to C4, not of C1.

NEXT (fresh session, C1):
1. Disk above the 30 GiB floor, with room for the cargo build of DIFF-EXEC.  The crib is complete.
2. Build C1 (lift) per the sub-unit text BY HAND in the main loop from the start of the session.  USER RULED
   2026-10-04 (end of C1 session 1):  no wf-builder launch for C1.  Inputs: C-LEARN.md L1, L2, L7;  bend2/rust/rir.bend (58 lines);  bend2/rust/emit.bend (209 lines).
3. RUST-PARSE (pass=35), DIFF-EXEC (238 values, sandbox off), the C1 "Done when" checks, the log entry, the memory
   topic.  Stage own paths only.

### 2026-10-04 C1 session 2 (claude7, session f0c52f8f): C1 lift built by hand, all checks GREEN

State: worktree mechanism-lang-rust-m0, branch mech-rust/m1, HEAD acfdfd6.  Two new files, STAGED, NOT
committed:
- bend2/rust/lift.bend (704 lines): `lift(f: A.SrcFile) -> Result<&2, &2, Refusal, R.Module>` and `show(r)`
  (`<line>:<col>: <construct>`; the caller adds `<file>:`).
- bend2/tests/rust_import.bend (55 lines): the driver, mode `lift`.  Output: `Em.text(m)`, or one line
  `REFUSED <line>:<col>: <construct>`, or `PARSE-FAIL <msg>`.
Runner (not in the repo): W/c1-lift.sh.

Design:
- Expressions: `kind` (not recursive) puts the head of one node in a tag `K`.  `walk` is the one recursive
  walker; it takes a list of jobs `Job{at, k}`.  Types use the same plan (`ty_kind` + `tks`).  No mutual
  recursion.
- Refusal position (CD13): items, variants, fields, arms and statements give the pos of their meta.  An
  expression, type or pattern gives the pos of its nearest statement, arm or item.  The `let` refusal comes from
  `tail_job`: the first statement of a block that is not the one tail expression.
- Derive lists: lift compares with `Em.derive(True{})` and `Em.derive(False{})`, so lift and emit use one list.
- Unit struct: the next item must be its constructor fn `pub fn c() -> Name { Name }`.  Else: refusal.
- NOT checked: the `gap` flag (blank lines).  Layout is the job of the printer.
- `//!` line: the emitter form gives the source file name.  Another form gives "" (C2 sets `<module>.mech`,
  CD4).
- The driver does not run the fragment pass of A (Fr.refusals).  It runs Parser.file only.
- Trap: `exs` is a keyword of Bend 2 (build error "expected : a name (got the keyword 'exs')").  The walker
  name is `walk`.

Checks (all GREEN):
- W/c1-lift.sh: `MATCH init.rs`, `MATCH second_price.rs`, `MATCH neg_let.rs: REFUSED 4:5: \`let\` statement`,
  `C1-LIFT-OK`.  The line:col of the negative file comes from `rg -n --column` on the `let`.
- dev/rust-parse-gate.sh: `pass=35 fail=0`, `RUST-PARSE-OK` (sandbox on).
- dev/rust-out-diff-exec.sh: `DIFF-EXEC-OK 238 values` (sandbox off).
- Disk: 39 GiB free at the end (floor 30).

Open points:
- lib.rs and nat.rs of the golden crate and the refuse fixtures of A (test/rust/refuse/) were NOT run through
  lift.  The "Done when" of C1 does not name them.
- With the sandbox off, $TMPDIR is a different dir.  Read the output of a background gate from its task output
  file, not from a log under $TMPDIR.

NEXT (fresh session, C2): build C2 per its sub-unit text.  Stage own paths only.  Never commit or push.

Update (same session, on USER ask): COMMITTED f710abb (`git commit -s`, no Co-Authored-By) and PUSHED to
origin mech-rust/m1 (acfdfd6..f710abb).  The worktree is clean.

### 2026-10-04 C2 session 1 (claude7, hand build in the main loop; the close by a wf-closer agent because of the step-budget hook)

State: bend2/rust/resolve.bend NEW, 774 lines. bend2/tests/rust_import.bend gets mode `resolve` (80 lines now). Runner W/c2-resolve.sh NEW. Both repo paths STAGED, NOT committed, HEAD f710abb.

Design:
- resolve.bend imports ../cli/rust_out.bend as Ro (a rust -> cli import) for mod_ok, mod_name, reserved, nat_names, nat_rs, sorted, variant_tys and code_is. Thus the two directions use one set of D7 module rules and one nat.rs text. The D7 item names come from erase_typed (Et.fn_name, Et.upper_first, Et.keywords).
- lib.rs: each item must be `pub mod <name>;` with a plain meta. A module name must be a D7 module name; bin, lib and main are refused; a duplicate is refused.
- nat (CD7): the text must be byte-equal to Ro.nat_rs(). It is not parsed. Its visible items are Nat, nat_small and nat_add; nat_decimal does not resolve.
- Item table rows: enum (kept), variant (`Enum::Variant` -> lower first letter), struct (kept), ctor and fn (snake_case -> camelCase, a keyword `_` is removed). Canonical check (CD5): D7 of the mech name must give the Rust name back, else refused.
- Collisions: Rust item names across all modules plus the nat names (D7); mech names across all rows plus MechBool, mechFalse, mechTrue, Nat, natAdd (CD5).
- Names in bodies: one @unsafe job walker over types, bodies and arms. Scope = own module + the `use`d modules + the nat items when `use crate::nat::*;` is present. A local (param, closure param, pattern binder) shadows an item. An unknown type, name, function or constructor is refused at the item position.
- CD3 order: Kahn's algorithm, ties in byte order (Ro.sorted), nat edges excluded. A cycle is refused at the `use` position.
- CD4: the file comes from the emitter `//!` line, else `<module>.mech`. The stem must give the module name back.
- A refusal is shown as `src/<module>.rs:<line>:<col>: <what>`.
- Driver: `rust_import.bend resolve <lib.rs text> (<module> <text>)*`; output rows then `manifest <module> <file>` lines.
Bend 2 lessons (candidates for C-LEARN): a match cannot scrutinize a computed value (give it its own def); there is no `!` operator (use Bool.pick); a multi-scrutinee match of a Maybe and a struct param was refused ("a match on a parameter or field"), so match one param and get the field with a def; `+x = a <> b` cannot infer its type (use a def); a def that an inferred `+x = f()` let calls must come before it; IO.args gives List<String> (&1), not List<&2, String>; zsh `"$(f)"` removes the trailing newline again, so keep the `x` trick in a variable.
Checks: c2-resolve.sh: rows=40 fn=22 data=7 variant=10 ctor=1 d7-back-bad=0 mech-distinct=True src-fns-match=True src-data-match=True; manifest init:init.mech second_price:second-price.mech; MATCH golden crate, canon, unknown, cycle, mech, rust, nat, file, missing; C2-RESOLVE-OK. Parse gate: pass=35 fail=0 RUST-PARSE-OK. DIFF-EXEC: DIFF-EXEC-OK 238 values (sandbox off). c1-lift.sh: C1-LIFT-OK. Disk: 37 GiB.
Open points: unused or unsorted `use` lines are not refused (RT-RUST in C6 catches them). Mech keyword names are left to the kernel parse in C4. A missing module text is refused at 0:0, because there is no file.
NEXT: C3, fresh session. Read this entry and the C3 section.
Then 3731b20 was COMMITTED (signed off, no Co-Authored-By) and PUSHED to origin/mech-rust/m1 on USER ask (2026-10-04, f710abb..3731b20).

### 2026-10-04 C3 HALTED (claude7, session 1d9d2531): both wf-builder launches died before any file change

State: HEAD 3731b20, the worktree and W have no change (`git status --short` empty in both after the two agents).
Build mode U4: one wf-builder for C3 with a self-contained brief (the C3 sub-unit text, CD8, CD9, CD6, CD7, the
C-LEARN spans L1, L3, L5, L6, the Bend 2 traps of C1 and C2, the runner W/c3-types.sh with a CD9 negative case).
- Launch 1 (fable xhigh): stopped on the Fable usage limit (HTTP 429), req_011Cfi2bivypz7xTKRjZtpvY.
- Launch 2 (the one opus xhigh relaunch with `[builder-tier-explicit]`): died on `[reasoning_extraction]`,
  req_011Cfi2fXcCzJFChTTA79zyE.
HALT per the tier rule. The main loop did not start a hand build: the step-budget hook stopped it at 12 steps with
the context at about 96k, and a hand build needs a USER ruling (as for C1 and C2).
Design notes for the next session (from the brief, HYPOTHESES): output line `<module> <mech fn name> : <telescope>
annotated <n>`; the telescope is a Syntax.T printed with Syntax.show (so C4 reuses the value); types compare modulo
TRef and TBox; the function table has each IFn, each IUnit constructor fn and the nat fns; the refusal reuses
Rs.Bad and Rs.show at the item position; negative case: `match MechSum::MechInl(a.clone())` as a scrutinee.
NEXT: USER ruling (hand build in a fresh session, or a builder launch later), then C3 per its sub-unit text.

### 2026-10-04 C3 session 1, hand build (claude7, session 1d9d2531; USER RULED "Hand build here, now"): DRAFT, does not build yet

State: HEAD 3731b20. bend2/rust/infer.bend NEW (draft, about 480 lines) and mode `types` in
bend2/tests/rust_import.bend (defs `typed`, `inferred`, tag MTypes). Both STAGED, NOT committed. No runner yet.
Check: `bend bend2/tests/rust_import.bend` stops at infer.bend:297, `expected '=' observed ')'`: the lambda form
`(fun js => ...)` is wrong for Bend 2. Find the lambda form in a file that builds (rg for `Maybe.map` or
`Result.bind` callers), and check the signatures of Maybe.map, Result.map and Result.bind that the draft guesses
(`(&2, &2, A, B, x, f)` and `(&2, &2, &2, E, A, B, x, f)`). More build errors can follow.
Trap: `bend bend2/rust/infer.bend` alone fails ("one namespace per file": resolve imports ../cli/rust_out.bend).
Check through the driver only.
Design of the draft (CD8, CD9):
- Notes, not a typed tree: `Typed{module, rust, mech, pos, tele, notes}`. A note is NCtor{targs} for each XCtor and
  NMatch{ret} for each XMatch, in pre-order (node, then children left to right, the scrutinee before the arms). C4
  walks the body in the same order. Reason: a typed copy of the tree needs a second walker (no mutual recursion).
- One @unsafe walker `walk(env, Result<String, St{jobs, notes}>)` with a non-recursive `step`. Jobs: JChk{locals,
  e, want} and JArm{locals, fam, args, arm, want}. `synth` (XVar, XCall, wrappers; a non-generic XCtor becomes a
  JChk) gives Syn{ty, jobs}. Types compare after `strip` (TRef, TBox removed).
- Tables over ALL modules (resolve already checked the scope): sigs = each IFn, each IUnit ctor fn, nat_small
  (u32 -> Nat) and nat_add (&Nat, &Nat -> Nat); fams = each IEnum; copies = IEnum with copy plus IUnit.
- Telescope: `(0 G : Type 0)` for each generic, then `(<q> <camel(unkw(param))> : <mty>)`, then the return type.
  q: TRef, TFn, TBool, Copy names -> many; other owned -> 1. mty: TBool -> MechBool, TCon -> application, TFn ->
  arrows with binder `_`. Printed with Syntax.show.
- Refusal: Rs.Bad at the fn item position, texts "type mismatch (CD9)", "argument count (CD9)", "constructor of a
  generic family with no expected type (CD9)" and others.
NEXT (fresh session): fix the build of the driver, write W/c3-types.sh (frame of c2-resolve.sh: 22 lines, names =
the RkFn rows, no REFUSED; negative `match MechSum::MechInl(a.clone())` in a copy of init.rs gives the CD9 refusal
at the `pub fn` line), rerun c1-lift.sh and c2-resolve.sh, then the log entry. Stage own paths.

### 2026-10-04 C3 session 2, hand build (claude7, session 11b0b9ed): C3 DONE, all checks GREEN

State: HEAD 3731b20. bend2/rust/infer.bend NEW and mode `types` in bend2/tests/rust_import.bend. Both STAGED, NOT
committed. Runner W/c3-types.sh NEW. The design of the draft (session 1 entry) did not change.
Build fixes to the draft (Bend 2 traps, candidates for C-LEARN):
- A lambda is `x => body`, not `fun x => ...`. Signatures: Maybe.map(a, A, B, f, m), Result.map(a, b, E, A, B, f, r),
  Result.bind(a, b, E, A, B, r, f). The file uses small named defs instead (cons_job, syn_of, ctor_ok, keep_item,
  keep_done, append_typed, append_done), as the other files of the importer do.
- No forward references, thus no mutual recursion: strip/strips, teq/teqs, subst/substs and mty/mtys/arrows are now
  one @unsafe def over a list of types each (strips, teqs, substs, mtys). A TFn{args, ret} goes in as the list
  `ret <> args`; `one` and `fn_of` give the result back.
- A match on a computed value or on a consumed binder: give it its own def (ctor_fields, typed_of, env_sigs, one_m).
- Termination check: the list argument first (apps(xs, h)).
- A binder with two uses needs `+` (both branches of Bool.pick are eager): item_copies(p, +cs).
- base.bend has no Nat.eq: same_len is structural.
- SType takes a Bignum.T: Syntax.SType{Bignum.zero()}, with import ../kernel/bignum.bend.
- One build of the driver to JS takes about 17 s.
Output: Syntax.show marks the quantities ("0 ", "1 ", no mark for many). No binder of the golden crate has
quantity 1: the generic params are `&A` (TRef, many), as in prelude/init.mech
`mechBoolRec : (0 A : Type 0) -> A -> A -> MechBool -> A`.
Checks (all GREEN):
- c3-types.sh: fn-lines=22 resolve-fn-rows=22 same-names-in-order=True annotated-total=21; MATCH golden crate;
  MATCH scrut (REFUSED src/init.rs:43:1: constructor of a generic family with no expected type (CD9)); C3-TYPES-OK.
- c1-lift.sh: C1-LIFT-OK.  c2-resolve.sh: rows=40 fn=22 data=7, C2-RESOLVE-OK.  Disk: 38 GiB.
- Not run: dev/rust-parse-gate.sh and dev/rust-out-diff-exec.sh (no file of A or B changed).
Open points: each XCtor gets an NCtor note (an empty list for a family with no generics), so C4 takes one note for
each XCtor and each XMatch, in pre-order. Only the byte comparison of C4 checks the telescopes in full. XInt checks
against u32 only (the emitter image is nat_small(<n>)). Only one CD9 negative here; C6 has the fixture list.
NEXT: C4, fresh session. Read this entry and the C4 section.
### 2026-10-04 C3 staged review (Codex): four MEDIUM findings fixed

Reviewed the complete staged diffs in mechanism-lang-rust-m0 and W, including the driver, inference pass,
c3-types.sh and this progress log. No CI or check weakening. The four reproduced findings were:
- Pattern field counts: Foo::Bar(y, _) or Foo::Bar against Bar(bool) incorrectly succeeded. Check binder arity.
- Match coverage: missing, duplicate or empty arms against an inhabited family incorrectly succeeded. Consume
  each variant exactly once; preserve empty-family elimination and allow constructor order changes.
- Type arity: Foo without its declared generic, Foo<bool> without generics, A<bool>, and malformed enum fields
  or unused call type arguments incorrectly succeeded. Validate signatures, fields and call types in scope.
- Local callbacks: f::<bool>(x) incorrectly succeeded although f has no generic telescope. Refuse local type args
  both when checking a call and when synthesizing a match scrutinee.
Changes: inference validates these cases with item-position refusals. dev/rust-infer-gate.py adds 32 cases;
W/c3-types.sh invokes it using the same compiled driver as its original checks.
Validation: the original staged driver fails all 14 new negative cases. The fixed driver passes all 32 cases,
all 22 golden function rows, and byte comparisons of golden types, resolve and lift output against the staged
baseline. Existing CD9, argument and closure refusals are preserved. Driver compilation and shell syntax pass.
The bare global-function-value probe is outside the current emitter image and remains refused.
No remaining review blockers. Fixes staged for user review; NEXT remains C4.
