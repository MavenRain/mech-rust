# mech-rust unit E progress (`let`, and the struct with private fields and accessors)

Scope source: design brief section 5 (rows 1 and 2 of the type and term map), 6, 8.1, 8.3, and D-PROGRESS.md
"Scope of unit D" (E, F, G, H as HYPOTHESIS).  The scope of E below is the choice of the opening session
(2026-10-05).  It is an ASSUMPTION until the USER rules (Rulings wanted, U9).
Worktree /Users/oobi/Documents/mechanism-lang-rust-m0, branch mech-rust/m1.  W = /Users/oobi/Documents/mech-rust.
NEVER commit or push.  Stage own paths only.  No Co-Authored-By line.  One sub-unit per fresh session.  Read the
tail of this file first.  The rules of D-PROGRESS.md (header) stay in force: never touch
/Users/oobi/Documents/mechanism-lang;  do not run dev/gates.sh;  stop if one Bend run exceeds 20 minutes;  disk
floor 30 GiB;  4 GB per run;  rg/sd;  no `cd X &&` or `VAR=` prefix;  no em-dashes.
Build mode: U7 of D-PROGRESS.md.  Both builder launches of the opening session died on the `[reasoning_extraction]`
classifier before any file change (fable req_011CfkGZwBWbZH27y1wXMzhw; opus with the marker
req_011CfkGeuvF7joTDEnKBha6o), the twelfth and thirteenth deaths in a row on this project.  Each E sub-unit is a
hand build in the main loop, in a session launched with CLAUDE_STEP_BUDGET=0 (the step-budget hook stops Bash at
20 steps, which is less than one driver build plus one gate).

## Start state 10-05 (claude7, session 09d06b8e; read-only, facts by one wf-mechanical agent, no worktree change)
EF1  Unit D is closed.  The USER committed D4 as 9f1fc14 (code) and 5067bc8 (W).  Both trees are clean.
     Disk 38 GiB free;  load average about 30 at the start.
EF2  Gates GREEN at 9f1fc14: RUST-IN pass=31, ROUND-TRIP pass=90, RUST-PARSE pass=35, RUST-INFER-OK,
     RUST-LOWER-OK, RUST-IN-CLI-OK (prebuilt inputs), DIFF-EXEC-OK 238 values.  Runner:
     `zsh ~/Documents/mech-rust/d3-points.sh [in|rt|parse|gates|py|exec|all]`.
EF3  Unit A (the Rust frontend) already parses every form of E.  bend2/rust/ast.bend: `IStruct{meta, vis, name,
     generics, body}` :120 with `BNamed{fields}` :78 and `NField{meta, vis, name, ty}` :71;  `BTuple{fields}` :77
     with `TField{meta, vis, ty}` :72;  `IImpl{meta, generics, tr, self_ty, items}` :124 (methods are `IFn`
     items);  `SLet{meta, pat, ty: Maybe<Ty>, init: Maybe<N>}` :91 (`ELet{pat, init}` :113 is `if let` only);
     `EField{recv, name}` :106;  `EStruct{segs, fields, base}` :115 with `FieldInit{name, value: Maybe<N>}` :99;
     `PStruct{segs, fields, rest}` :54 with `FieldPat{name, pat}` :48;  `PSelf{by_ref}` :64.  Parser sites:
     parser.bend `MItemV KStruct` :1134, `MBody` :1224-1234, `KImpl` :1158 to `MImplBody` :1315, `MStmt KLet` :911
     to `MLetTy`/`MLetInit` :927-931, `MPost Dot Name` :724, `MInits` :774-893, `MFieldPats` :983-997, receivers
     :1211-1214.  Fixture test/rust/parse/04_impl.rs covers `impl`.
EF4  Emitter (unit B).  The RIR items are `IUse`, `IEnum{name, generics, copy, variants}`, `IUnit{name, ctor}`
     and `IFn{name, generics, params, ret, body}` (bend2/rust/rir.bend:50-54;  `Variant{name, fields}` :45).
     There is no struct-with-fields item.  A family with one constructor and at least one kept field is a
     one-variant `pub enum` today (erase_typed.bend `unit_ctor` :645-650, the `CData` arm :683-689, comment
     :664).  `IUnit` lowers to `A.IStruct{.., A.BUnit{}}` plus the constructor fn (emit.bend:197-199);  derive
     lists at emit.bend:158-159.
EF5  Emitter `let` refusal: erase_typed.bend:1574-1575 in `plan_term`, `case Term.Let{name, ty, value, body}:
     no_plan("a let (M0)")`.  The kernel term is `Let{name: String, ty: T, value: T, body: T}`
     (bend2/kernel/term.bend:36);  no quantity field on the binder.
EF6  mech surface `let`: `SLet{name, ty, value, body}` (bend2/surface/syntax.bend:68);  parser.bend:665-674,
     entry `PTerm KLet` :427.  The only form is `let x : T := e in body`.  The type is REQUIRED.  Elab keeps it
     (elab_term.bend:1209-1216 gives `Term.Let`, `Check.define` puts the value in the context, no inlining).  The
     kernel printer prints `let x : T := v in b` (kernel/pp.bend:155), so a checked row keeps its lets.  NOT read:
     the body of `checked_form` (elab.bend:619), to confirm that it prints through pp.
EF7  Importer (unit C).  `let` statements are refused in lift.bend:366-368 with the text `` `let` statement ``
     (fixture test/rust/import/refuse/01_let: `pub fn good(x: bool) -> bool { let y = x; y }`, EXPECTED.tsv row
     `01_let .. 2:5`).  Structs: lift.bend:609-624 `body_ok` refuses `BTuple` and `BNamed` with ``struct `<name>`
     with fields``, `unit_body` refuses generics;  the unit struct must be followed directly by its constructor
     fn (`ctor_of` :627-633, pairing :653-668, `unit_copy` :606-607 wants `Copy` in the derives).  Fixtures:
     02_struct_fields (`Pair { left: bool, right: bool }`), 10_tuple_struct (`Wrap(bool)`), 09_unit_no_ctor.
     NOT read: lift.bend after :668, so how `IImpl`, `PSelf` and `EField` are refused today is not confirmed.
EF8  Name map (D7): `fn_name = rust_name . snake` (erase_typed.bend:78), variant `upper_first` :55, inverse
     `fn_back = camel . unkw` :113-134;  the importer uses the same inverse (resolve.bend:217-225).  No `__`
     module-path rule exists in either direction;  `__` is legal only as the image of `_` plus an upper-case
     letter (seed 09_names).  The come-back check covers item names only, not parameters or local binders.
EF9  Seeds 01-09 (MANIFEST names in dev/rt-mech-gate.sh order: the gate loops over `test/rust/seed/*(/)` :71,
     `joined()` :60-66 reads each MANIFEST;  GREEN control on 01_enum_match :105, RED controls on 05_proofs
     :135, the three `names_*` REFUSE controls :212-216).  The next seed number is 10.

## Scope of unit E (ASSUMPTION, U9)
The M1 fragment grows by two forms, in both directions, with a seed and controls for each: `let`, and the
struct with private fields (brief 5, rows 1 and 2).  No other growth (RsOption, RsResult, RsVec, integers,
methods, traits stay out).  Each sub-unit keeps every gate of EF2 GREEN with its counts raised.
Target, for each new form F:
- rust-out emits F from the canonical mech form, and refuses nothing that it emitted before.
- rust-in imports the canonical Rust form of F, and keeps a located refusal for each non-canonical variant.
- A seed program with F passes SEED-CHECK, RT-MECH, FIXPOINT and RT-RUST (ROUNDTRIP.md).
- One RED control per form.

## Sub-units (each ends with checks clean, a runner script in W, and a log entry here)
E1  `let`, both directions.  Emitter: `Term.Let{x, T, v, b}` becomes the Rust statement `let x: T = v;`
    followed by the statements and tail of `b` when the let is the body of a fn or the tail of a block;  in any
    other position it becomes the block expression `{ let x: T = v; b }`.  The type is always written (EF6: the
    mech side always has it).  Importer: `let x: T = e;` becomes `let x : T := e in <rest>`;  `let x = e;` takes
    the type of `e` from infer.bend, else the refusal ``let `<x>` with no type (E1)`` at the statement;  `mut`, a
    pattern other than a name, `let` with no initializer and `let else` keep a located refusal.  The fixture
    01_let changes from REFUSE to an import fixture (its `let y = x` has the type of `x`).  Files: rir.bend (a
    block with statements), erase_typed.bend, emit.bend, lift.bend, resolve.bend, infer.bend, lower.bend, one
    emit fixture, import fixtures, seed `10_let`, EMIT.md, IMPORT.md, ROUNDTRIP.md, W/e1-let.sh.
    Learn first (runner mode `learn`): L1 the RIR expression constructors (is there a block?);  L2 the lowering of
    a fn body block in lower.bend and the entry of infer.bend for an expression;  L3 whether `checked_form` keeps
    the let (EF6, confirm);  L4 the quantity of a let binder in the kernel check (does a QOne value in a let
    count as one use?).
E2  The struct, emitter side.  A family with one constructor, at least one kept field, no index and no generic
    becomes `pub struct S { a: A, b: B }` with private fields (binder names of the constructor), a constructor
    fn named from the mech constructor through D7, and one accessor per field (ED5, U10).  A constructor with
    only `_` binders becomes the tuple struct `pub struct N(A, B);` (one field = the newtype, brief row 1).
    Mixed named and `_` binders are refused with a located reason.  A `case` on the family in the same module
    becomes `match s { S { a, b } => body }` (a struct pattern, `_` for an unused field);  in another module it
    is refused (ED6, U11).  A constructor application becomes a call of the constructor fn.  Emit fixture,
    classify fixture, EMIT.md.  The one-variant enum of EF4 is then no longer emitted (U12).
E3  The struct, importer side.  `pub struct S { a: A, b: B }` (no `pub` on a field) followed by its constructor
    fn becomes `mu S : Type 0 with | <ctor> (a : A) (b : B)`;  the tuple struct likewise with `_` binders.  A
    generated accessor (`impl S { pub fn a(&self) -> &A { &self.a } }`, by value for the Copy set) is recognized
    by shape and dropped;  any other `impl` item is refused (methods are M2).  A `match` with a struct pattern
    becomes a `case`;  a struct literal becomes a constructor application;  `e.f` is refused (ED7).
    Keep 02_struct_fields and 10_tuple_struct as REFUSE fixtures: both lack the required constructor fn.
    Update their located refusal reasons when fields are supported, and add separate positive fixtures with
    the constructor fn and canonical accessors.  IMPORT.md.
E4  Close: seeds `11_struct` (named fields) and `12_newtype`, one RED control per form, ROUNDTRIP.md, the
    limits in EMIT.md and IMPORT.md, W/COMMIT-MSG-E.txt, full rerun (RUST-PARSE, RUST-IN, the three Python
    gates, ROUND-TRIP;  DIFF-EXEC with the sandbox off).

## Design defaults (HYPOTHESES; each is confirmed or changed in the sub-unit that names it)
ED1  Emitted `let` shape: `let x: T = v;` as a statement, type always written, no `mut`, no pattern.  Nested
     lets flatten into one statement list.  A let in a non-tail position is a block expression.  (E1)
ED2  Let binder names go through the parameter rule (`camelCase` to `snake_case` and back).  The come-back check
     is NOT extended to local binders (same limit as parameters, EMIT.md).  This does not permit variable
     capture: emission and import must preserve binding identity when the name map merges distinct names.
     Freshen local names against in-scope parameters, locals and referenced value items, or give a located
     refusal before translation.  Add a regression for a parameter `fooBar` and a let binder `foo_bar` with
     the body returning `fooBar`: both map to Rust `foo_bar`, so naive emission silently returns the let value
     instead of the parameter.  Also cover nested shadowing and a let initializer that reads the outer binder.
     The collision case must preserve the result or be refused; it must never emit captured references.  (E1)
ED3  Importer type of an unannotated let: the type that infer.bend gives the initializer, written into the mech
     `let` (so the re-emitted Rust has the annotation: RT-RUST holds on emitter output, and a Rust-first file
     with `let x = e;` is not canonical).  (E1, U13)
ED4  Let binder quantity: the kernel `Let` has no quantity;  the binder is treated as the value's use count
     decides.  If the kernel refuses a seed because a QOne value is bound by a let and used once, the seed is
     changed and the fact recorded.  (E1 learn, L4)
ED5  Accessors: the emitter writes one accessor per field, `pub fn <field>(&self) -> &<T>` (`-> <T>` and a copy
     when `<T>` is in the Copy set), in one `impl S` block after the constructor fn.  Canonical Rust has these
     accessors.  The importer drops a method of exactly this shape and refuses every other method.  (E2, E3, U10)
ED6  A `case` on a struct family from another module is refused in E: ``a case on the struct `<S>` outside its
     module (E2)``.  The accessors are the Rust-side read of a struct from another module;  a mech-side read is
     a case, and the two meet only inside the module in E.  (E2, U11)
ED7  `e.f` (field access) on the Rust side is refused in E with a located reason;  the canonical read of a
     field outside its module is the accessor, which has no mech form in E (it is dropped, ED5).  (E3)
ED8  Derives on a struct with fields: `Clone, Debug, PartialEq, Eq` (not Copy), as for an enum with a field.
     (E2)
ED9  Seed layout as DD1: test/rust/seed/<nn>_<name>/{MANIFEST, *.mech}.  (E1, E4)

## Rulings wanted (the session continues on the defaults in brackets)
U9   Scope of E: [`let` and the struct, as above] or a different order among E, F, G, H.
U10  Accessor shape: [generated `impl S { pub fn a(&self) -> &A }` per field, dropped by shape on import, other
     methods refused] or free fns `pub fn s_a(s: &S) -> &A` or eliminator defs on the mech side (brief 5, row 1
     note) with method emission.
U11  A case on a struct from another module: [refused in E] or emitted through the accessors.
U12  A one-variant `enum` on the Rust side: [imports as a one-constructor family as today;  it re-emits as a
     struct, so RT-RUST fails on it;  recorded as non-canonical] or refused.
U13  `let x = e;` with no type on the Rust side: [accepted when infer.bend gives the type] or refused (canonical
     Rust writes the type).

## Log

### 2026-10-05 E OPENED (claude7, session 09d06b8e): facts and split written, no worktree change
Builders: both launches dead (header).  One wf-mechanical facts agent lived and gave EF3-EF9.  The step-budget
hook stopped Bash before the hand build of E1 could start, so nothing is staged in the code worktree.
NEXT: E1 in a fresh session launched with CLAUDE_STEP_BUDGET=0.  Steps: (1) W/e1-let.sh modes `learn`, `emit`,
`in`, `rt`, `parse`, `all` (drivers built once to $TMPDIR/e1, shape of d3-points.sh);  (2) learn L1-L4 and
record them here;  (3) emitter: a block node in rir.bend, the `Term.Let` plan in erase_typed.bend, the statement
in emit.bend, one emit fixture with two lets (one nested in a non-tail position);  (4) importer: lift.bend
`SLet` to a lifted let, resolve, infer (binder enters the environment with the given or inferred type), lower to
`Syntax.SLet`;  01_let becomes an import fixture, a new REFUSE crate for `let mut`, and one for a let that infer
cannot type if such an initializer exists in the fragment;  (5) seed `10_let`, ROUND-TRIP, RUST-IN, RUST-PARSE,
the Python gates;  (6) EMIT.md, IMPORT.md, ROUNDTRIP.md line 102;  (7) the E1 log entry, both write-trees.

### 2026-10-05 E1 session 1 (claude7): steps 1 and 2 done (runner, learn), no code change

The session was launched without CLAUDE_STEP_BUDGET=0, so the step-budget hook (deny at 20 steps) ended the work
after the learn step.  The code worktree is clean at 9f1fc14.  The USER committed the E plan as W 44f9584 and
added the variable-capture requirement to ED2.  Runner: `zsh ~/Documents/mech-rust/e1-let.sh [learn|emit|in|rt|
parse|py|all] [nobuild]` (drivers to $TMPDIR/e1;  `emit` wants the fixture test/rust/emit/let_probe.mech, which
does not exist yet;  DIFF-EXEC stays in d3-points.sh).
L1  rir.bend has no block and no let.  `Ex` is XVar, XInt, XBool, XCall, XCtor, XMatch, XIf, XClosure, XBorrow,
    XClone, XBox (rir.bend:31-42).  Plan: one constructor `XLet{name: String, ty: Ty, value: Ex, body: Ex}`;
    no block node (ED1: the statement list is derived at emission).
L2  Emitter: `fn_item` (emit.bend:185) takes the body as one A.Node;  `tail(e)` :104 gives `[SExpr{e, False}]`;
    `nodes` :124-154 is `@unsafe` with one arm per constructor and no `other` arm, so a new constructor needs its
    arm.  The let statement form is a new `tail`: for `XLet` give `SLet{m0(), name_pat(name), Some{ty(t)},
    Some{ex(value)}}` then `tail(body)` (nested lets flatten);  in `nodes` the non-tail position gives
    `A.EBlock{tail(XLet{..})}`.  rustfmt puts an `if` arm body in a block (`arm_body` :108);  check what it
    does with a block arm body.  Importer: `tail_job` (lift.bend:381-391) accepts `Con{SExpr, Nil}` only and
    `stmt_refusal` :369-376 refuses `SLet` with "`let` statement";  the lifted kinds are `K` (lift.bend:262).
    Lowering: `children` (lower.bend:225) and `lows` :280-300 walk one R.Ex with the name list `ns`;  `fun_of`
    :271;  inference: infer.bend `Env` :36, `Loc` :33, `Job`/`Syn`/`St` and `step_jobs` (lower.bend:209).  NOT
    read: how `Syn` carries the type of one expression and where `Env` gains a binder (the next session reads
    infer.bend around its `step`).
L3  CONFIRMED.  `checked_form` (elab.bend:619-624) prints `Pp.term([], body)` per def through `entry_text`, no
    normalization, so a `Term.Let` kept by elab prints as `let x : T := v in b`.
L4  The let binder is defined with `Quantity.QMany{}` whatever its type (elab_term.bend:1209-1216,
    `Check.define(name, QMany, ty_value, value_value, ctx)`);  the value is elaborated once in the enclosing
    context.  Kernel engine sites: check_engine.bend:333 and :432.  ED4 stays: a QOne variable used in the value
    counts once;  the binder itself is unrestricted, so a seed may use a let binder twice.
L5  (ED2) The emitter's in-scope value binders are `vs: List<Maybe<R.Param>>` in `plan_term`
    (erase_typed.bend:1556;  Rust-side names, de Bruijn order;  `bind_some` :1426 pushes a match binder as
    `Some{Param{name, TRef{ty}}}`, an erased binder is `None`);  the module fn names are in `env`.  Decision for
    E1 (ASSUMPTION): refuse, do not freshen.  `no_plan("the let binder `<rust>` collides with `<other>` after the
    name map (E1)")` when the snake image of the binder equals the name of any `Some` slot of `vs` or any fn name
    of the module.  The binder enters `vs` as an owned `Param{name, ty}` (mirror the fn parameter entry, not the
    `TRef` of a match binder).  Regressions: the `fooBar`/`foo_bar` case of ED2 as a classify row (the shape of
    test/rust/emit/neg_classify.mech).  Under this refusal policy, nested same-name shadowing is also a
    classify refusal: `let x := a in let x := b in x` collides with the outer `Some` slot, as does
    `let x := a in let x := x in x`.  A successful emit fixture uses distinct nested binder names and an
    initializer that reads the outer binder, such as `let x := a in let y := x in y`.
NEXT: steps 3-7 of the plan above, in a session launched with CLAUDE_STEP_BUDGET=0.  Start with
`zsh ~/Documents/mech-rust/e1-let.sh learn`.

### E1 session 2 (2026-10-06, hand build, claude7)
Decisions (fold of HANDOFF-E1.md F1-F8):
- F2: `R.XLet{name, ty: Maybe<Ty>, value, body}`; the emitter always gives `Some{ty}`, the lifter keeps `None` for `let y = x;`.
- F3 ownership: the binder enters `vs` as an owned `Some{Param{rn, t}}`. E1 accepts a binder of a Copy type only (`let_copy`: TBool or a Copy family); a non-Copy, function or type-sorted binder is a located refusal; an EProp binder is erased like a proof parameter.
- ED2/L5: `let_clash` = `has_slot(vs, rn) || global_clash(entries, rn)` with `fn_name(global)`; refusal text "the let binder `rn` collides with a name in scope after the name map (E1)".
- Emit shape: a let in tail position is flattened into the fn block (`tail` flattens `A.EBlock`); a let in argument position stays a block (`let_arg` in let_probe.mech).
- Importer: resolve checks the type, the initializer in the outer locals and the body with the binder; infer checks the value against `Some{t}` or synthesizes it (U13: refusal "let `x` with no type (E1)" when synth fails); lower gives `Syntax.SLet{name, mty(t), value, body}` with `t` from the first child job.
- Bend 2 traps hit: a match scrutinee must be a parameter (helper def per computed scrutinee); shared `ks`/`vs`/`t` need `+`; no forward references (`let_t` sits above `lows`).
Done: rir XLet; erase_typed BLet/let_plan/let_rx/uses arm; emit tail/let_ty/nodes arm; resolve/infer/lower XLet arms; rust_out exs_refs arm; test/rust/emit/let_probe.mech; `e1-let.sh emit` = E1-EMIT-OK 24 lines rustfmt clean.
OPEN (next session): lift.bend KLet (tail_job for `SLet{PPath{name}, ty, Some{init}} <> rest`, refusals "`let` without an initializer" / "`let` with a pattern" / "`let` with no tail expression", `kind(EBlock{SLet..})`, walk arm -> `R.XLet`); fixtures (neg_classify rows negLetParam/negLetShadow/negLetGlobal/non-Copy, remove refuse/01_let row+dir, add 12_let_mut, python table rows F7, seed 10_let + RED control in rt-mech-gate.sh); docs EMIT.md/IMPORT.md let sections + ROUNDTRIP.md; `e1-let.sh all` against baselines parse 35 / in 31 / rt 90 / 22 golden fns.

### E1 session 3 (2026-10-06, hand build, claude7): importer side of `let`
The USER committed session 2 as code 2323e44 and W d686c7c.  This session was launched without
CLAUDE_STEP_BUDGET=0 again, so the work was batched into few steps and the gates ran in the background.
Decisions:
- lift.bend: `KLet{name, ty: Maybe<A.Ty>, init, rest}` and `KBlock{stmts}`.  `tail_job` has an `SLet` arm
  before the refusal arm (`let_job` -> `let_init` -> `let_rest`, one helper per matched field, Bend 2 trap);
  refusals `` `let` with a pattern ``, `` `let` without an initializer ``, `` `let` with no tail expression ``
  at the position of the `let`.  `kind(EBlock{SLet..})` gives `KBlock`; every other block stays refused, so the
  LIFT identity holds (`{ e }` would print back as `e`).  The `walk` arm gives `R.XLet{name, let_ty(t),
  one(init), one(tail_job(rest))}`;  `let_ty` keeps `None` for `let y = x;`.
- Fixtures: `01_let` removed (positive case now, in the python tables);  `12_let_mut` (the import parser gives a
  parse error, `parse: 2:13 expected `;`, found `y``, not the `mut binding` text) and `13_let_pattern` (`let _ = x;`) added.  `14_let_no_type` added (`let y =
  Maybe::Nothing;` with a generic `Maybe`):  `let_syn` (infer.bend:597) maps ANY synth failure to "let `y`
  with no type (E1)", so the CD9 text of the initializer does not show;  infer NEGATIVES row "let with no
  type" covers the same path.  `let_copy` accepts TBool or a family
  in `copies`;  negLetParam/negLetShadow/negLetGlobal/negLetNat are lines 3-6 of neg_classify.mech (line 6 =
  "a let of a non-Copy type (E1)", checked by running re.js on the fixture;  the F7 pair-constructor case is
  covered by this refusal, since no non-Copy binder reaches emission).  Seed `10_let` = 01_enum_match + `lightTwice` (let in the
  tail);  RED control "let initializer changed" in rt-mech-gate.sh mutates `lightNext l` to `l` in the
  imported text and wants `RT-MECH-FAIL lightTwice`.  Python rows: infer POSITIVES `let with annotation` and
  `let without annotation` (both `("good", 0)`: the synthesized type travels in the job, no note);  lower
  CONTEXTS `let in tail`, `let in argument`;  SEMANTICS `let value`, `let shadows nothing`.
- Docs: EMIT.md `## Let (E1)` + refusal row + known limit;  IMPORT.md `## Let (E1)` + ten seeds;  ROUNDTRIP.md
  known limit (the pass count line is updated when the gate reports).
Gate results (2026-10-06, final staged trees, machine load 11 to 31):
- `e1-let.sh emit` E1-EMIT-OK; neg_classify lines 3 to 6 as listed above.
- RUST-IN `pass=33 fail=0` (31 before E1: `01_let` out, `12_let_mut`, `13_let_pattern`, `14_let_no_type` in).
- ROUND-TRIP `pass=99 fail=0` (seed `10_let` and its RED control in).  RUST-PARSE `pass=35 fail=0`.
- Python: RUST-LET-OK 5;  RUST-INFER-OK `cases=35 golden-functions=22`;  RUST-LOWER-OK `cases=41`.  The infer and
  lower gates ran with prebuilt drivers (`--driver`, `--emitter`), because their own bend builds hit the 180 s
  timeout under load.
- NOT VERIFIED: `dev/rust-in-cli-gate.py`.  Its 14 driver cases passed, but the build of `bend2/mech.bend` failed
  three times (180 s timeout twice, one silent stop at 322 s with no output file).  The peak memory of that build
  is not known (the sandbox blocks `/usr/bin/time -l`).  E1 does not change `bend2/cli/rust_in.bend`.  Run the
  gate on a quiet box before the commit: `python3 dev/rust-in-cli-gate.py` from the code root.

### E2 session 1 (2026-10-06, claude7): no code change, hand-off written
The USER had not committed E1, so E2 was to build on the staged E1 trees (code 1cf8ba3e, W 6ec0b81f).  One fable
wf-builder died on a Fable usage limit (req_011CfmNVw4AAXE5FcyGuAmmY) and the marked opus fallback died on
`[reasoning_extraction]` (req_011CfmNa98or62UrqMZFoAWT), both before the first edit.  Per the USER ruling of 10-05
the delegation stops there.  The site map, the proposed RIR (`IStruct`, `PStruct`), the walker list and the stop
check are in HANDOFF-E2.md.  NEXT:  hand build E2 from HANDOFF-E2.md in a fresh session launched with
CLAUDE_STEP_BUDGET=0.
### E1 staged review (2026-10-06, Codex)
Reviewed all 17 staged code/test paths and all three staged planning files. No CI weakening found.
Two confirmed defects were fixed and staged with regressions:
- HIGH, print.bend: `JFl` is a layout probe. Using it to print a match scrutinee or an `if` condition replaced
  a nonempty let block with `{\n}`, dropping its initializer and body. Seed `lightLetGo` emitted an empty
  scrutinee and could not compile or import. These positions now use `JEx`; the parser fixture covers
  ordinary and empty matches plus `if`, and seed `10_let` covers the emitted match and conditional paths.
- MEDIUM, infer.bend: `synth` had no `XLet` arm. A valid `match { let y: Foo = x; y }` was refused with the
  unrelated CD9 generic-constructor diagnostic. Synthesis now gets the body type with the binder in scope
  and retains a checking job for the whole let, so it still checks the initializer in the outer scope.
  Regressions cover typed/untyped scrutinees, nested initializers, evaluation, and an invalid initializer.
Validation: inference 39 cases with 22 golden functions; lowering 46 cases; parser 36; RUST-LET 5; DIFF-EXEC passed
with its mutation controls; the emitted let-control-flow crate compiled and passed `cargo fmt --check`.
The compiler-cache wrapper was disabled for DIFF-EXEC because sccache cannot operate in this sandbox.
The final combined importer built successfully on retry. RUST-IN passed 33 checks, and ROUND-TRIP
passed 99 checks with the expanded seed. The first combined importer attempt and the CLI build exited 137;
the full CLI gate remains unverified and is still required before committing.
Review artifacts and complete execution logs are under /Users/oobi/Documents/gpt7/mech-rust-e1-review.
No commit or push was made.

## E2 session 2 (2026-10-06, claude7, session d9d08cca): no code change, builders dead
- Start state: the USER committed E1 (code 6ed4700, W 373cdae). Both trees were clean. CLAUDE_STEP_BUDGET was not set.
- Stop check: the visible part of `rg -n -A4 '^mu ' test/rust/seed test/rust/emit` showed one-constructor families only
  of sort Prop (LightSafe, MechEq, Safe, TallyEq).  Part of the output was cut.  Do the check again before the first edit.
- Builders: the fable wf-builder died on the Fable usage limit (HTTP 429), req_011CfmT6eu1pzRZrrj2T4Wur.  The opus
  fallback with `[builder-tier-explicit]` died on `[reasoning_extraction]`, req_011CfmT8jXd8wQBMGhVcVFpa.  Both died
  before an edit.  Delegation halted (ruling 10-05).
- Hand build not started: the step-budget hook allows 20 messages for each user turn.  E2 needs more (about 20 walker
  arms, Bend builds under load 32, five gates).
- Walker sites, confirmed at HEAD 6ed4700 (each needs an arm for IStruct or PStruct):
  - bend2/cli/rust_out.bend:129 (PCtor arm), :170-176 and :189-195 (Item arms).
  - bend2/rust/lower.bend:134 and :162 (PCtor arms), :435-441 (Item arms).
  - bend2/rust/infer.bend:231-233, :254-256, :694-696 (Item arms), :550 and :626 (PCtor arms).
  - bend2/rust/emit.bend:84-86 (pattern), :207-214 (items).
  - bend2/rust/lift.bend:231, :235, :702-720 (producers only, no new arm).
  - bend2/tests/rust_emit_oracle.bend:68-70;  bend2/tests/rust_emit.bend:32-48.
  - bend2/rust/resolve.bend:  sites in HANDOFF-E2.md, not confirmed in this session.
- Runner: e1-let.sh `py` mode runs dev/rust-in-cli-gate.py.  e2-struct.sh must not run it (the USER runs it on a quiet box).
- NEXT: hand build E2 from HANDOFF-E2.md in a fresh session launched with CLAUDE_STEP_BUDGET=0, or delegate again to
  a fable wf-builder after the Fable usage limit resets.
