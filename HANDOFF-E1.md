# E1 hand-off (session 2, 2026-10-06): facts gathered, NO file changed in either worktree

The sub-budget hook stopped this builder at 18 tool calls (deny on Bash) before the first edit.  Code worktree
ROOT = /Users/oobi/Documents/mechanism-lang-rust-m0 is clean at 9f1fc14.  W = /Users/oobi/Documents/mech-rust has
only this file new at capture time.  The next builder verifies HEAD and the index in both worktrees, then checks
the relevant declarations and E-PROGRESS.md requirements before editing.  These notes and line numbers are a
checkpoint, not a substitute for current sources or validation.  Budget target for the next launch: ~40 tool
calls;  put related probes into ONE
runner script under $TMPDIR and call it once;  edit with the Edit tool (one call per file, several edits per
file are separate calls, so prefer Write for new files and ONE Edit per existing region).

## Facts beyond E-PROGRESS.md L1-L5 (read this instead of the sources)

### F1 The lifter lifts to the SAME RIR (rir.bend `R.Ex`)
lift.bend `walk(xs: List<Job>) -> Result<Refusal, List<R.Ex>>` (:438) builds `R.XVar`, `R.XCall`, `R.XIf` ...
from the kinds `K` (:262-274: KVar, KInt, KBool, KCall, KCtor, KMatch, KIf{cond, yes: stmts, no: stmts},
KClosure, KBorrow, KClone, KBox, KBad{what}).  `kind(n: A.Node) -> K` (:297-352) has `case A.EBlock{stmts}:
KBad{"block"}` (:339).  `Job{at: A.Pos, k: K}` (:355).  `tail_job(pos, stmts)` (:375-385) accepts
`Con{A.SExpr{meta, e, semi}, Nil{}}` with `plain(meta)` and `semi == False`, else `Fail{stmt_refusal(s)}`;
`stmt_refusal` (:365-372) has `case A.SLet{meta, p, t, init}: Refusal{A.meta_pos(meta), "`let` statement"}`.
`fn_body(pos, b)` (:585-591) = `tail_job(pos, stmts)`.  `arm_job` (:395-402) opens an `A.EBlock` in an arm only
for an `if` (`if_only`, "block in a match arm").  `KIf` arms call `tail_job(at, yes)` and `tail_job(at, no)`
(:~487-492) then `walk([cond job, yj, nj])` and `if_of`.  Each walk arm is a `do Result<&2, &2, Refusal,
List<&2, R.Ex>>:` block with `ys <- walk([Job{at, kind(inner)}])`, `more <- walk(rest)`, `return X <> more`.
So every consumer of `R.Ex` needs an `XLet` arm: emit.bend `nodes` (:126-153, @unsafe, no other arm),
lift.bend (producer only), resolve.bend `JEx{gens, locals, ex}` walker (:449 XIf, :451 XClosure),
infer.bend `JChk{ls, ex, want}` (:609 XIf, :611 XClosure), lower.bend `lows` (:300-303, `Job{ls, ex, w}`,
`children(e, ls, ex, w)` :225) and two more walkers at :328-330 and :358-360 (names collection, read them),
and bend2/tests/rust_emit.bend:82 builds an R.Ex by hand (no change needed unless a match there is exhaustive).
NOT read yet: resolve.bend :395-470, infer.bend around :560-640 (`JChk` and how a want type reaches a binder),
lower.bend :200-370 (`children`, `lows`, `fun_of`, `param_binders(cps, copies, ns)`, `In.mty`), and lift
`cparams` (:201-212, whether an untyped closure param is refused: the infer gate has only "typed closure").

### F2 RIR change (decision): `XLet{name: String, ty: Maybe<&2, Ty>, value: Ex, body: Ex}`
Reason: the lifter must represent `let y = x;` (no annotation) and the LIFT check of dev/rust-in-gate.sh prints
the lift back byte for byte, so the type must stay optional in the RIR.  The emitter always builds `Some{ty}`.
Infer fills `None` with the type of the initializer (ED3/U13) or refuses ``let `<x>` with no type (E1)``.
If the task owner insists on `ty: Ty`, the alternative is a sentinel and is worse.  Record the choice in the
E1 log entry as a change of the L1 plan.

### F3 Emitter plan (erase_typed.bend), exact sites
- `plan_term` :1556-1577, replace :1574-1575 (`case Term.Let{name, ty, value, body}: no_plan("a let (M0)")`)
  with `let_plan(env, ks, vs, want, name, ty, value, body)`.
- Type lowering to reuse: `one_er(ers(env, ks, [ty]))` gives `Er` = `EData{t: R.Ty}` | `EProp{}` | `ENo{why}`
  (`ers` :392, `one_er` :248, `Er` :180).  Binder kinds: `kind_of(end_of(ty), name)` (:199-215) gives
  `KGen{name}`/`KProp{}`/`KVal{}`;  the fn-parameter path uses `binder_er(q, end_of(dom), one_er(ers(..)))`
  (:430) then `slot_of(copies, q, x, bd)` (:1335) = `Some{R.Param{fn_name(name), mode(copies, q, t)}}`.
  `mode(copies, QMany, TCon not Copy)` = `TRef{t}` (:343), so "mirror the fn parameter" and "owned Param"
  disagree for a non-Copy type.  DECISION taken here: owned `R.Param{rn, t}` exactly as the task says;
  `var_use` (:1050) then gives `x` for WOwn (a move) and `&x` for WRef.  This does not make repeated owned
  uses safe: a non-Copy `x` in `Pair::Both(x, x)` is moved twice (rustc E0382).  Before accepting such a let,
  preserve ownership with supported borrowing or cloning, or give a located refusal.  Also check a borrow
  after a move and captures by reusable closures.  Do not report successful emission of Rust that fails
  ownership checking.  Simply recording `TRef` in the slot is insufficient while the actual binding is owned.
  Record the supported cases and refusal in EMIT.md and cover non-Copy uses in a compile regression.
  Function-typed lets (`EData{R.TFn{..}}`): refuse
  ``a let of a function type (E1)`` (no `impl Fn` let in Rust).  `EProp{}` type: plan the body only with
  `KProp{} <> ks`, `None{} <> vs` (erased binder, like a proof parameter).  `ENo{why}`: `no_plan(why)`.
  `EndType`/`EndProp` ends of `ty` (a type-valued or Prop-valued let): refuse ``a let of a type (E1)``.
- Collision check (ED2/L5): `rn = fn_name(name)` (:78).  Refuse when `rn` equals the name of any `Some` slot
  of `vs` (write `has_slot(vs, rn)` over `List<Maybe<R.Param>>`) or any fn name of the module.  Module fn
  names: `Env{globals: Global.T, copies}` (:186);  the source is bend2/kernel/global.bend.
  `Global.Globals` has an `entries: List<C.Pair<String, Global.Entry>>` field; `Global.names` does not exist.
  Enumerate the runtime value items that can be referenced and compare `rn` with `fn_name(global)`.
  Do not substitute an exact lookup of the original let name: global `fooBar` and local `foo_bar` both
  emit as `foo_bar`, while `name_class(env, "foo_bar")` cannot find global `fooBar`.  The resulting
  `let foo_bar: bool = false; foo_bar()` fails with rustc E0618.  If the complete collision check is
  unavailable, refuse the translation.  Check both outer slots and referenced globals before emitting.
  Text: ``no_plan("the let binder `" ++ rn ++ "` collides with `" ++ other ++ "`
  after the name map (E1)")``.
- Jobs: `Plan{[Job{ks, vs, WOwn{}, value}, Job{KVal{} <> ks, Some{R.Param{rn, t}} <> vs, want, body}],
  BLet{rn, t}}`.  Add `BLet{name: String, ty: R.Ty}` to `type Build` (:1002-1009) and the arm in `built`
  (:1765-1784): `case BLet{name, ty}: let_rx(name, ty, xs)` with `let_rx` matching
  `Con{v, Con{b, rest}}` -> `XOk{R.XLet{name, Some{ty}, v, b}}`, other -> `XNo{"internal: a let without two
  parts"}` (style of `if_rx` :1733).  Helper style: `Bool.pick(T, cond, a, b)`, `String.eq`, `has(list,
  name)` exists (:348).

### F4 Emitter plan (emit.bend)
- `nodes` :126-153 add `case Con{R.XLet{name, t, value, body}, rest}: A.EBlock{let_stmts(name, t, value,
  body)} <> nodes(rest)` where `let_stmts` = `A.SLet{m0(), name_pat(name), let_ty(t), Some{one(nodes([value]))}}
  <> tail(one(nodes([body])))` and `let_ty(None) = None`, `let_ty(Some{t}) = Some{ty(t)}`.
- `tail(e)` :104-105: flatten `case A.EBlock{stmts}: stmts`, `case other: [A.SExpr{m0(), other, False{}}]`.
  Then the fn body `Some{tail(body)}` (:186) and `XIf` branches (:145, `tail(one(nodes([yes])))`) flatten a
  let in tail position into statements, and a let in a non-tail position stays `A.EBlock`.  CHECK: `arm_body`
  (:108) wraps only `EIf`;  a block arm body `Foo::Bar => { let x: T = v; x }` is what rustfmt keeps, fine.
  Also check print.bend prints `SLet` with `Some{ty}` as `let x: T = v;` (the parser round-trips
  test/rust/parse fixtures with lets, so it should).  The importer inverse of the flattened tail (F5) must
  not re-open a non-tail `EBlock` except through `KLet`: `kind(A.EBlock{stmts})` stays "block" unless the
  block starts with `SLet` (then it is the non-tail let);  decide: lift `A.EBlock{Con{A.SLet..}, ..}` in any
  expression position to `KLet`, keep "block" for other blocks.
- `name_pat(name)` :56 = `A.PPath{path1(name)}` is the identifier pattern (confirm the parser gives the same
  for `let y = x;` by lifting 01_let: `pat` in lift.bend :228 accepts `PPath` of one segment as a name).

### F5 Importer plan (lift.bend)
- Add `KLet{name: String, ty: Maybe<&2, A.Ty>, init: A.Node, rest: List<&2, A.Stmt<A.Node>>}` to `K`.
- `tail_job`: new first arm `case Con{A.SLet{meta, A.PPath{Con{A.Seg{name, Nil{}}, Nil{}}}, t, Some{init}},
  Con{s, more}}: do .. ok <- plain(meta) .. Done{Job{A.meta_pos(meta), KLet{name, t, init, Con{s, more}}}}`;
  keep located refusals: `SLet` with `init: None` -> "`let` without an initializer";  `SLet` with another
  pattern -> "`let` with a pattern";  `let mut` -> find how the parser marks `mut` (ast.bend `Pat` has no
  PIdent, so `mut x` may parse as `PPath` with a flag or a different ctor: read ast.bend :50-56 and the
  parser `MLetTy` :927 FIRST;  if `mut` is not representable, the parser refuses it and the REFUSE row shows
  the parser's text);  trailing `SLet` with `Nil{}` tail -> "`let` with no tail expression".
- `walk` arm: `case Con{Job{+at, KLet{name, t, init, rest_stmts}}, rest}: do ..: rt : Maybe<R.Ty> <-
  (match t: None -> Done{None}, Some{a} -> map Some over ty(at, a));  vs <- walk([Job{at, kind(init)}]);
  bj : Job <- tail_job(at, rest_stmts);  bs <- walk([bj]);  more <- walk(rest);  return R.XLet{name, rt,
  one(vs), one(bs)} <> more`.  `ty(pos, t)` :182 lowers one A.Ty.
- `kind`: `case A.EBlock{Con{A.SLet{..}, ..}}` -> the let kind (non-tail position), other blocks stay "block".
- Printing back (LIFT identity) goes through emit.bend `nodes` + print.bend, nothing else to add.

### F6 Importer plan (resolve, infer, lower): NOT designed in detail (sources not read)
Read resolve.bend :395-470 (`JEx{gens, locals, ex}`: push `name` to `locals` for the body job, check the
initializer in the outer locals), infer.bend :560-640 (`JChk{ls, ex, want}`: the value is checked against
`Some{t}` or synthesized when `None`;  the body is checked against `want` with the binder's type pushed onto
`ls`;  the "annotated N" count in the `types` rows probably counts filled types: a filled let type may need to
count as 1, then the python POSITIVES row for the let case says `("good", 1)`), lower.bend :200-370
(`children` adds the two sub-jobs, `lows` builds `Syntax.SLet{name, ty, value, body}` through the same
`In.mty(copies, w)` type lowering that `if_t` uses;  the binder enters `ns` for the body like `param_binders`
does for a closure).  The refusal format of infer: `REFUSED src/demo.rs:<line>:1: <text>` (python gate regex,
position is the fn item).  Let text: ``let `<x>` with no type (E1)`` when infer has no type for the
initializer (which initializer has none?  a closure with untyped params or a generic constructor with no
expected type, CD9 text;  if none exists in the fragment, the REFUSE crate for it is dropped and the fact is
recorded, per the plan step 4).

### F7 Fixtures and gates
- Emit fixture ROOT/test/rust/emit/let_probe.mech: closed runtime defs in the globals of prelude/init.mech
  (the runner copies init.mech next to it and runs `node re.js emit init.mech let_probe.mech`);  mech syntax
  `let x : T := v in b`.  Suggested: `def letTwice : (a : MechBool) -> MechBool := fun (a : MechBool) => let x
  : MechBool := a in let y : MechBool := x in y` and a non-tail let, e.g. `mechNot (let z : MechBool := a in
  z)` or a case scrutinee that is a let (check which prelude fns exist with `rg -n "^def " ROOT/prelude/
  init.mech | head`).  Expected Rust: `let x: bool = a;` lines (the runner greps `let `).
- Classify rows: ROOT/test/rust/emit/neg_classify.mech (8 lines: header comments "Line N of the result: ..."
  then `axiom negPostulate : MechNat`, `def negTwin ..`, `def neg_twin ..`).  Append two defs: `def negLetParam
  : (fooBar : MechBool) -> MechBool := fun (fooBar : MechBool) => let foo_bar : MechBool := mechTrue in
  fooBar` (refused: the let binder `foo_bar` collides with `foo_bar`) and `def negLetShadow : (a : MechBool)
  -> MechBool := fun (a : MechBool) => let x : MechBool := a in let x : MechBool := mechFalse in x` (collides
  with `x`).  Find the gate that checks this file's expected lines: `rg -n "neg_classify" ROOT/dev
  ROOT/bend2/tests` (likely bend2/tests/rust_emit.bend or dev/rust-out-diff-exec.sh;  not found yet).
  Add a global-name collision case too: `def fooBar : MechBool := mechTrue` and
  `def negLetGlobal : MechBool := let foo_bar : MechBool := mechFalse in fooBar`.  It must be refused or
  preserve the global reference.  For ownership, use a non-Copy family with a kept field and a pair
  constructor: bind one value to `x`, then construct a pair from `x` twice.  Require compilable Rust with
  preserved values or a located refusal, never successful emission followed by rustc E0382.  Include the
  supported single-use and Copy cases as positive regressions.
  Note: the kernel elaborator may itself refuse `let x .. in let x ..`?  No: shadowing is legal in mech
  (de Bruijn);  the emitter refuses it.
- REFUSE crates (ROOT/test/rust/import/refuse/<name>/src/{lib.rs,foo.rs}, lib.rs = `pub mod foo;`), rows in
  EXPECTED.tsv `name<TAB>65<TAB>REFUSED src/foo.rs:L:C: <text>`;  MIN_REFUSED=8 in rust-in-gate.sh;  every
  directory needs a row.  Remove the `01_let` row and directory (it becomes a positive case) and add
  `12_let_mut` (`pub fn good(x: bool) -> bool { let mut y = x; y }`) and `13_let_no_type` (an initializer
  infer cannot type, see F6).  The positive import of 01_let: there is no positive import fixture directory;
  add it to the python tables instead: rust-infer-gate.py POSITIVES `("let with annotation", "pub fn good(x:
  bool) -> bool { let y: bool = x; y }", [("good", 0)])` and `("let without annotation", "pub fn good(x: bool)
  -> bool { let y = x; y }", [("good", 1)])` (the annotated count depends on F6), rust-lower-gate.py CONTEXTS
  `("let in tail", ...)`, `("let in argument", "pub fn id(x: bool) -> bool { x } pub fn good(b: bool) -> bool
  { id({ let y: bool = b; y }) }")`, and SEMANTICS `("let value", "pub fn result() -> bool { let x: bool =
  true; let y: bool = x; y }", "true")` plus `("let shadows nothing", "pub fn first(x: bool) -> bool { let y:
  bool = false; x } pub fn result() -> bool { first(true) }", "true")`.  rust-in-cli-gate.py: the case
  `("parse refusal", "foo", "pub fn bad() { let x = true; }", None, 65)` stays 65 (trailing let, no tail, no
  return type);  nothing else there.  The infer gate asserts `len(actual) != 22` golden fns: unchanged.
- Seed ROOT/test/rust/seed/10_let/{MANIFEST = `light.mech`, light.mech}: copy 01_enum_match/light.mech and
  add `def lightTwice : (l : Light) -> Light := fun (l : Light) => let n : Light := lightNext l in lightNext n`
  (single use of a non-Copy?  Light is an enum with no fields, so it derives Copy: emit.bend `derive(copy)`;
  a Copy binder may be used twice: `lightPick (lightGo n) n n`).  RT-MECH compares checked rows, so the let
  must survive import+emit twice (FIXPOINT) with the same text.  Add the let-specific RED control required
  by E-PROGRESS.md: mutate the imported `lightTwice` initializer so it computes a different result, assert
  that the mutation changed the source, and require `RT-MECH-FAIL lightTwice`.  Keep the existing controls.
- ROUNDTRIP.md line 102 (plan step 6) mentions the seed list;  EMIT.md (198 lines) and IMPORT.md (84 lines):
  add a `let` section each (ASD-STE100, no em-dashes).

### F8 Gate commands (all in `zsh /Users/oobi/Documents/mech-rust/e1-let.sh all`)
emit: builds ROOT/bend2/tests/rust_emit.bend to $TMPDIR/e1/re.js, runs `node re.js emit init.mech
let_probe.mech`, then `rustfmt --check --edition 2021`.  parse: dev/rust-parse-gate.sh (RUST-PARSE pass=35).
in: dev/rust-in-gate.sh (RUST-IN pass=31;  builds rust_import and rust_emit drivers itself).  rt:
dev/rt-mech-gate.sh (ROUND-TRIP pass=90;  loops over test/rust/seed/*).  py: the three python gates (each
builds its own driver unless `--driver`;  about 3 min each).  Baselines at 9f1fc14: EF2 of E-PROGRESS.md.

## NEXT (exact order for the relaunched builder)
1. ONE Bash runner script that prints: lift.bend :201-212;  resolve.bend :395-470;  infer.bend :540-640 and
   its `^type |^def ` outline;  lower.bend :200-370;  ast.bend :50-56 and :88-93;  parser.bend :905-935
   (`let mut`);  `rg -n "neg_classify" ROOT/dev ROOT/bend2/tests`;  `rg -n "^def " ROOT/prelude/init.mech |
   head -n 40`;  print.bend `SLet` arm;  global.bend `^def ` outline.
2. Edit rir.bend (XLet), erase_typed.bend (BLet, let_plan, built arm, has_slot), emit.bend (tail flatten,
   nodes arm, let_ty), lift.bend (KLet, tail_job, walk, kind), resolve/infer/lower arms.  Write the fixtures.
3. `zsh /Users/oobi/Documents/mech-rust/e1-let.sh emit` until E1-EMIT-OK, then `all`.
4. Docs, E-PROGRESS.md "E1 session 2" entry (decisions: F2 Maybe type, F3 ownership checks and complete
   collision checks, refusal
   policy), W/COMMIT-MSG-E1.txt, `git add` in both worktrees, `git status --short`, `git write-tree`.
