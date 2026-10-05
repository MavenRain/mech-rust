# Unit A progress (hand build, main loop)

Builders: opus wf-builder relaunch died on [reasoning_extraction] (req_011CfeXaQoQ48wmio96cg4fo), HALTED, no sonnet.
Bend: ~/.bend/bin/bend is 2.0.25 (repo pin 2.0.27); shared binary left untouched.

Sub-units (one fresh session each; context cap forces the split):
- A1 token.bend + lexer.bend + driver `lex` mode: WRITTEN (this session). Check: `~/.bend/bin/bend <file> --check-only`.
  Run: `~/.bend/bin/bend bend2/tests/rust_frontend.bend lex "$(cat f.rs)"`. Result of first check/run: see the session report.
- A2 ast.bend + parser.bend (one @unsafe parse(mode, tokens) -> Value, as bend2/surface/parser.bend:197-423).
- A3 print.bend (rustfmt-stable, gaps from Tok.gap) + accepted fixtures (>= 14, rustfmt --check --edition 2021).
- A4 fragment.bend + refused fixtures + EXPECTED.tsv + dev/rust-parse-gate.sh + FRONTEND.md + mutation control + stage + COMMIT-MSG-A.txt.

Design decisions so far: keywords lex as Ident (parser compares names); `>`/`<` lex singly (generics); non-doc comments
(line and block) lex as Comment and are refused everywhere (keeps print(parse(f)) == f); Tok.gap = blank line before token.

A2 relaunch 10-02 (session 415cff98): one opus wf-builder with an inline brief died on [reasoning_extraction] (req_011CfeZefypCupf4b1uCxqCF). HALTED, no sonnet.
A2 design held for the hand build: parser-local token sum (one constructor per keyword and punct, classify Ident once with String.eq; no string-literal patterns);
gap + outer docs + attrs on items, fields, variants, stmts, arms; inner docs on file and inline mod; refusals left to an A4 token pre-pass;
one @unsafe parse(mode, tokens) -> Result<&2, &2, String, Value> as bend2/surface/parser.bend:197-510; Bool.pick picks a Mode, never two parse calls;
no-struct flag for if/match scrutinees; driver `parse` mode prints PARSE-OK plus `<kind> <name>` per top-level item.

A2 hand build 10-02 (session bb8a04d4): A1 re-checked (--check-only clean, lex sample correct, ~30 s/run). Disk 29 GiB under the floor;
diskfree dry run = 0.8 GiB cargo caches only (left alone: other sessions build); bend runs carry `# [skip-disk]`.
Bend 2 probes: `(a, b) = p` in a do block REJECTED; `Pd{+a, r} <- m` REJECTED (annotated form is a syntax error); built-in pair is
Type not Data. So reference style `+a : Parsed<T> <- ...` plus pv/pr accessors. No mutually recursive types (syntax.bend uses
type parameters): AST = one recursive `Node` (expressions + items) with Seg<T>, Stmt<N>, Arm<N>, FieldInit<N>, FieldPat<P> helpers.
Parser token PT{k: K, i: Info{text, loc, gap}}; keyword + punct tables via String.eq; binop sym = token text.
A2 STATUS (session bb8a04d4): bend2/rust/ast.bend + bend2/rust/parser.bend WRITTEN, `bend bend2/rust/parser.bend --check-only` = "All terms check"
(unsafe: parse, file). `File` clashed with Base, renamed A.SrcFile. Entry: Parser.file(src) -> Result<String, A.SrcFile>; A.item_line(n).
Driver `parse` mode ADDED (dispatch now takes +mode +src); driver --check-only clean. Sample (inner doc, use group, attr+doc struct,
enum with tuple/named/unit variants, pub(crate) const, type alias, trait with supertrait, impl with struct literal shorthand + method
calls + if/else + binops, match with struct pattern + guard + or-pattern + macros + closure, inline mod with bounded generic) = PARSE-OK
with all 9 item lines correct. Not yet exercised: failure messages, turbofish, `move` closures, `if let`, `..base`, tuple index fields.
A2 DONE (unstaged). NEXT (fresh session): A3 print.bend + accepted fixtures.

A3 hand build 10-03 (session claude7 41c08321): bend2/rust/print.bend WRITTEN, `--check-only` = "All terms check" (unsafe: pp, file).
Shape: width helpers (slen, flen, one_line, le, sub, room, fit, capped) + leaves (vis, lit, attrs, meta, ovf) + chain decomposition
(Link = LMeth/LField with `?` counts) + ONE @unsafe `pp(j: Job)`; JPick/JSel keep the costly alternative lazy as data. A flat
rendering carries "\n" when it cannot stay on one line (blocks with stmts, match, items, a part past a rustfmt width).
Bend 2 facts learned: termination check reads args left to right ("each passed unchanged until one shrinks"), so list walkers take the
list FIRST (last_from(xs, x)); nested constructor patterns and `case other:` work; Bool.pick is eager.
rustfmt rule learned: in an enum, one multi-line variant (docs or attrs count) next to a one-line variant puts EVERY struct variant
vertical (`mixed` + JVFlags give width 0); two multi-line variants do not.
Driver: `print` mode added; dispatch now `run_mode(mode_of(mode), src)` (eager Bool.pick ran lex + parse + print every call:
~3 min/run, now ~1 min/run).
Fixtures: test/rust/parse/01_struct .. 14_gaps (structs, enums, fns + vertical sig, impl + struct literals + ..base, traits,
match, if/else-if/if-let/one-line if-else, chains + closure-block overflow, use/mod, const/type/impl Fn/tuples, vertical call
args, ?/vec!/Box::new, turbofish + move, blank lines + field/variant docs and attrs). All 14 `rustfmt --check --edition 2021`
clean; round trip 14/14 PASS via scratch runner W/a3-run.sh (args = fixture paths, default all; compares with trailing
newlines stripped because `"$(cat f)"` drops them: the A4 gate must compare exactly, e.g. src via a file arg or append "\n").
Fixtures avoid refused constructs (no lifetimes, no `mod x;` since rustfmt needs x.rs, no `.unwrap()`); a Bash hook blocks
`let x = e?; Ok(..x..)` tails in written Rust, so fixtures use `.map` there.
Known printer gaps (for FRONTEND.md, A4): raw idents print without `r#` (AST drops it); binary expressions break only after the last
operator, no rustfmt binop layout; an over-wide match arm body is not wrapped in a block; long `if` conditions and fn generics/where
never break; long use trees never wrap; tuple-struct fields and generics are always one line; exact trailing-newline law untested.
A3 DONE (unstaged, untracked). NEXT (fresh session): A4 fragment.bend + refused fixtures + EXPECTED.tsv + dev/rust-parse-gate.sh
+ FRONTEND.md + mutation control + stage + COMMIT-MSG-A.txt.

A4 hand build 10-03 (session claude7 cd027d34): WRITTEN, NOT VERIFIED, all unstaged and untracked. Context cap hit before the gate finished.
WRITTEN:
- bend2/rust/fragment.bend: token pre-pass, `refusals(tokens)` = all refusals in source order. Walk state: prev token ends an
  expression (indexing), impl-header flag (`for` permitted from `impl` to the next `{` or `;`), use flag (`as` permitted from `use` to `;`).
  Multi-token cases first (`&mut`, `.await`, `.name(` / `.name::`, `name!`), each consumes its tokens. Rule table: FRONTEND.md.
- parser.bend: `from_tokens(raw)` split out of `file` (lex once). Driver: `check` mode = lex, fragment, parse, print; a refused
  source prints `REFUSED <line>:<col> <construct>` per refusal. Driver `--check-only` = "All terms check" (first try).
- test/rust/refuse/04_ref_mut .. 20_comment (17 files) + EXPECTED.tsv (20 rows: name TAB line:col TAB construct, no header).
- dev/rust-parse-gate.sh (zsh, executable): ONE `bend <driver> -o <bin>` build in a mktemp dir, then `check` per fixture; exact
  `cmp` (sentinel `x` keeps trailing newlines); rustfmt --check on accepted AND refused; floors 14/20; rows == files, names unique.
- bend2/rust/FRONTEND.md (files, pipeline, law, refusal table, gate, known limits).
BLOCKED (USER): Write of refuse/01_loop.rs, 02_while.rs, 03_for.rs DENIED by the no-imperative-loop hook. Bypass is session env
CLAUDE_ALLOW_LOOP_KEYWORDS=1 (USER only); not worked around. EXPECTED.tsv already has their rows (all `2:5`). Contents:
  01_loop.rs:  `pub fn spin() -> u32 {` / `    loop {}` / `}`
  02_while.rs: `pub fn wait(ready: bool) -> u32 {` / `    while ready {}` / `    0` / `}`
  03_for.rs:   `pub fn total(xs: Vec<u32>) -> u32 {` / `    for x in xs {}` / `    0` / `}`
NOT VERIFIED: the first gate run (background task bvyd3u0fw, started 02:15) passed the check phase and was still in the native
build (no binary) after 6+ min at hand-off. Unknown: native build time and whether it works at all, whether IO.print adds a
trailing newline (the gate compare is exact), the hand-counted EXPECTED positions, rustfmt-clean state of the refused fixtures.
Until 01-03 exist the gate is RED by design (3 rows with no file).
GATE RUN 1 RESULT (task bvyd3u0fw, native build DID finish, exit 0 through `head`): 0 PASS. All 14 accepted FAIL
"print(parse(f)) differs from f"; refused rows also not PASS (output past line 41 not read, context cap). A uniform failure
means one systematic cause, NOT 14 printer bugs (A3 round trip was 14/14): first suspects = IO.print adds a trailing newline,
or the native binary gets argv differently from `bend <file> args` (mode/src shifted, so "unknown mode" or usage text).
Diagnose with ONE run: build the binary by hand, run `check` on 01_struct.rs, and compare bytes (`cmp -l`, `od -c` tail).
Build time: not measured (between 6 and ~10 min).
NEXT (fresh session): (0) diagnose the uniform FAIL above first. (1) USER creates 01-03 or sets the env var. (2) Run dev/rust-parse-gate.sh in the background, fix FAILs;
if the native build is too slow or fails, change the gate to interpreter runs (~1 min per fixture, 34 fixtures). (3) Mutation
control in a $TMPDIR copy (bend2/rust, bend2/tests/rust_frontend.bend, test/rust, dev/rust-parse-gate.sh), each must end
RUST-PARSE-FAIL: (a) fragment.bend `Entry{"dyn", CDyn{}}` -> `Entry{"dyn", CKw{}}`, expect FAIL refuse/15_dyn.rs;
(b) print.bend:136 `"pub "` -> `"pub  "`, expect FAIL on parse/* fixtures. (4) Stage bend2/rust, bend2/tests/rust_frontend.bend,
test/rust, dev/rust-parse-gate.sh; write W/COMMIT-MSG-A.txt (no Co-Authored-By). NEVER commit or push.

A4 close 10-03 (session claude7 67afaf39): steps 0, 2, 3, 4 DONE; step 1 still with the USER.
STEP 0 (uniform FAIL): cause = IO.print appends "\n" (interpreter AND native output = file + one "\n", 355 vs 354 bytes on
01_struct.rs). Native argv is the same as the interpreter (that suspect is refuted). Fix: driver `main` uses IO.write (exact
bytes, probe confirmed). Driver --check-only clean. All 31 fixtures `rustfmt --check --edition 2021` clean.
NATIVE BUILD: old (IO.print) driver built in 1191 s on a loaded box, run = 1 s. The IO.write driver FAILED to build natively
3 of 3 (669 s, ~490 s, ~490 s; bend exit non-zero, log has only the check lines; cause NOT isolated; a tiny IO.write program
builds natively without a problem). JS build of the same driver = 48 s, `node rf.js check` = 1 s, exact match.
GATE CHANGED: dev/rust-parse-gate.sh builds `rust_frontend.js` and runs it with `${NODE:-node}` (fails early without node);
FRONTEND.md updated (node on PATH, no native build). New dependency: node (USER can rule for interpreter runs instead).
STEP 2 gate (45 s, W/gate-run2.log): pass=31 fail=5, RUST-PARSE-FAIL. All 5 FAILs come from the missing 01-03 files (3 rows
with no file, refused-count 17 < 20, expected-rows 20 vs 17). 14 accepted + 17 refused PASS with exact compare.
Loop rows probed with the source as an argument (no .rs file written): REFUSED 2:5 loop / 2:5 while / 2:5 for = EXPECTED.tsv.
STEP 3 mutation controls ($TMPDIR copies, W/mut-a.log, W/mut-b.log, W/a4-summary.txt): (a) dyn -> CKw: adds FAIL
refuse/15_dyn.rs (pass=30 fail=6). (b) `"pub "` -> `"pub  "`: adds FAIL on parse/01,02,03,04,05,09,10,12,14 (pass=22 fail=14).
Both judged on their specific FAIL lines, because the verdict line is RED in the baseline too until 01-03 exist.
STEP 4: STAGED bend2/rust, bend2/tests/rust_frontend.bend, test/rust, dev/rust-parse-gate.sh; W/COMMIT-MSG-A.txt written
(it describes the state WITH the 3 loop fixtures: 20 refused, 34 fixtures). NEVER commit or push.
NEXT (USER): create refuse/01_loop.rs, 02_while.rs, 03_for.rs (contents above; the Write hook denied them again), run
`zsh dev/rust-parse-gate.sh` (expect pass=34 fail=0, RUST-PARSE-OK), `git add test/rust/refuse`, then
`git commit -s -F ~/Documents/mech-rust/COMMIT-MSG-A.txt`. After that: unit B (M0-PLAN.md).
10-03 later (same session): USER said "Go ahead and commit and push" and ruled "create them, then commit" (printf through the
shell). The Bash companion loop guard DENIED the printf writes too (bypass = session env CLAUDE_ALLOW_LOOP_KEYWORDS=1 only).
Not worked around. NOTHING committed or pushed; 41 files still staged (tree 81e9cec7). USER has commit + push authorization
on record for this unit once the gate prints RUST-PARSE-OK: push = `git push -u origin mech-rust/m0`.
UNIT A DONE 10-03: USER ran the block (loop fixtures 01-03 created, gate, commit, push). HEAD 653a27e on mech-rust/m0 =
origin/mech-rust/m0, tree clean. The gate output of that run was not seen by the agent (the `&&` chain commits only on exit 0).
NEXT: unit B (M0-PLAN.md): bend2/rust/{rir,erase_typed,emit}.bend + bend2/cli rust-out verb + test/rust/emit +
dev/rust-out-diff-exec.sh (DIFF-EXEC). Fresh session, hand build in sub-units as for A. Use a JS build for any gate that runs one
driver many times. Open from A: cause of the native build failure of the IO.write driver; printer gaps listed in FRONTEND.md.
