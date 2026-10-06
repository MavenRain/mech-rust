# HANDOFF E2: the struct, emitter side (2026-10-06, claude7, session 9d1e3ea8)

## Review status (2026-10-06)

E2 is still partial. The staged RIR/emitter scaffold now compiles, with exhaustive
item and pattern consumers in the eraser, CLI dependency tracking, resolver,
inference and lowering. Importing field structs remains an explicit typed refusal
until E3. Named struct match patterns now follow the printer's rustfmt layout.

Direct coverage is in `bend2/tests/rust_struct_emit.bend`,
`bend2/tests/rust_struct_walkers.bend`, and `bend2/tests/rust_struct_import.bend`.
Run `python3 dev/rust-struct-gate.py` in CODE; it checks 24 cases, including
generated Rust formatting, compilation and execution. The existing emitter
driver also accepts `sample struct`. Final gate results are in E-PROGRESS.md.

Resume Session 3 NEXT at step 3: source family classification, constructor and
case plans, refusals, the value oracle, source fixtures and feature documentation.
Before enabling classification, resolve accessor names such as `clone`: an
inherent getter can shadow derived Clone, while RIR `XClone` explicitly denotes
`.clone()` syntax. No supported source path produces that conflicting struct yet.

The original handoff and session logs below describe earlier states.

## Original handoff


Status: NO code change.  Both trees are at the staged E1 state:  code write-tree 1cf8ba3e, W write-tree 6ec0b81f
before this file.  Do E2 as a HAND BUILD in a fresh session that is launched with CLAUDE_STEP_BUDGET=0.

## Why a hand build
- The fable wf-builder died on a Fable usage limit (HTTP 429) before its first edit:  req_011CfmNVw4AAXE5FcyGuAmmY.
- The opus fallback (marked `[builder-tier-explicit]`) died on `[reasoning_extraction]` before its first edit:
  req_011CfmNa98or62UrqMZFoAWT.
- USER ruling 10-05:  after the opus fallback dies, halt the delegation and hand build in the main loop.  Do not use sonnet.

## Task (E-PROGRESS.md E2, defaults ED5, ED6, ED8;  rulings U10 to U12 are still open)
A family with ONE constructor, at least one KEPT field, no index and no generic becomes a struct:
1. Named binders:  `pub struct S { a: A, b: B }`, private fields, field names = binder names through `fn_name`
   (erase_typed.bend:78).  Constructor fn named through D7 as for `IUnit`:  `pub fn mk_s(a: A, b: B) -> S { S { a, b } }`.
   Then one `impl S` block, one accessor per field in field order:  `pub fn a(&self) -> &A { &self.a }`, or
   `pub fn a(&self) -> A { self.a }` when A is TBool or a family in `copies`.
2. All binders `_`:  tuple struct `pub struct N(A, B);`.  Constructor fn parameters `x0`, `x1`, ... (check that
   they cannot clash).  No accessors on a tuple struct (new ASSUMPTION U14:  add it under "Rulings wanted").
3. Mixed named and `_` binders:  located refusal ``a constructor with named and `_` fields (E2)``.
4. Derives `Clone, Debug, PartialEq, Eq` (ED8).  A struct is never in `copies`.
5. A constructor application becomes `XCall{ctor_fn, [], args}` (as `IUnit`).
6. A same-module `case` becomes `match s { S { a: x, b: _ } => body }` (no `..`);  tuple struct `N(x, _)`.  A case
   on a struct from another module:  located refusal ``a case on the struct `<S>` outside its module (E2)``
   (find how erase_typed knows the module:  how `IUse{module}` is made, and `classify2` :980).
7. U12:  such a family is no longer a one-variant enum.  A one-ctor family with only erased fields stays `IUnit`.

## Proposed RIR (bend2/rust/rir.bend, 62 lines)
- `Item.IStruct{name: String, ctor: String, named: Bool, fields: List<&2, Param>}` (tuple struct:  Param names
  are the ctor fn parameter names).
- `Pat.PStruct{family: String, named: Bool, fields: List<&2, String>, binds: List<&2, Bind>}`.

## Stop check (do it first)
The importer still refuses `struct with fields` (lift.bend `body_ok` ~:609-624) until E3.  If a ROUND-TRIP seed
(test/rust/seed/*) has a one-ctor family with a kept field, E2 alone breaks ROUND-TRIP:  then E2 and E3 land
together.  An awk scan for one-ctor `mu` blocks in test/rust/seed and test/rust/emit printed nothing, but the
scan is NOT trusted.  Confirm with `rg -n -A3 '^mu ' <code>/test/rust/seed` before the first edit.

## Sites (rg of the staged tree, 2026-10-06)
erase_typed.bend (2051 lines;  read windows of 120 lines or less):
- Env/`copies` :185-197, `mode` :343, `unit_ctor` :645-650, `Class`/`CData` :656, IUnit class :677, IEnum class
  :689 (`all_unit(vars)` = Copy), `unit_class` :692, `family_class` :694, `classify_family` :701, `family_or_skip` :774.
- Item arms :855-915 (:861, :892, :901;  `copy_names` :914).  `no_plan` :1068.
- Constructor application :1150-1170 (`R.IUnit` arm :1154).
- Case branches :1461 (`Br{R.PCtor{fam, upper_first(c), ..}}`) and :1470;  case plan :1505-1545 (`match_plan` :1542).
- `skip_binds` arm :1747-1748;  arm walker :1777.
emit.bend (224 lines):  pattern :84-86, `arm_pats` :89, `zip_arms` :131, `nodes` :140-170, `derive` :172-173,
`items` :203-224 (IUnit :211-214 = `A.IStruct{.., A.BUnit{}}` plus the ctor fn;  copy its shape).
ast.bend:  `NField` :71, `TField` :72, `BTuple` :77, `BNamed` :78, `IStruct` :120, `IImpl` :124, `PSelf` :64,
`EField` :106, `EStruct` :115 with `FieldInit` :99, `PStruct` :54 with `FieldPat` :48.
print.bend already prints IImpl :753-755, PSelf :488, EField :529, EStruct :551, PStruct :451-469, BTuple/BNamed
:781-795.  Expect no printer change.
Other walkers of `R.Item` / `R.Pat` (each match needs an arm for the new constructors):
- bend2/cli/rust_out.bend :129 (arms), :174, :193 (items).
- lift.bend :231, :235, :720;  resolve.bend :149, :246, :366, :469, :480;  infer.bend :231, :256, :530, :606;
  lower.bend :134, :162, :439.  The importer never makes IStruct/PStruct in E2:  give a refusal arm or a
  pass-through, as E1 did for XLet.
- bend2/tests/rust_emit_oracle.bend :68 (`Et.CData` arm);  bend2/tests/rust_emit.bend (unit list :60;  add a struct case).

## Fixtures, runner, gates
- New test/rust/emit/struct_probe.mech:  a named struct with a Copy field and a non-Copy field, a newtype, a
  constructor application, a same-module case with one unused field.
- neg_classify.mech:  rows for mixed binders and (if one file can express it) the case outside its module;  lines
  3-6 are E1.  Else a two-file fixture after the existing two-file pattern.
- Runner:  copy e1-let.sh to e2-struct.sh, change only the E2 parts;  `emit` mode prints `E2-EMIT-OK <n> lines`
  after rustfmt is clean and `rustc --edition 2021 --crate-type lib` compiles the output.
- Baselines after the staged review: RUST-IN pass=33, ROUND-TRIP pass=99, RUST-PARSE pass=36, RUST-LET-OK 5,
  RUST-INFER-OK cases=39 golden-functions=22, RUST-LOWER-OK cases=46. Under load, prebuild drivers and pass
  `--driver`/`--emitter`.  DIFF-EXEC needs the sandbox off.  `dev/rust-in-cli-gate.py` is the USER's (quiet box).

## Bend 2 traps (E1)
A match scrutinee must be a parameter (one helper def per computed scrutinee).  A variable used twice needs `+`.
No forward references (helper above its caller).  `@unsafe def` where `nodes` needs one arm per constructor.

## Close
EMIT.md `## Struct (E2)` (style of `## Let (E1)`, refusal rows, limits);  E-PROGRESS.md entry "E2 session 2";
COMMIT-MSG-E2.txt (`E2: emit a one-constructor family as a struct with accessors`, no Co-Authored-By);  stage.

## Session 3 state (2026-10-06, claude7, main-loop hand build, stopped at the context cap)
Builders: both fable wf-builders died on the Fable usage limit (HTTP 429) before any edit:  req_011CfmUbNRVT5msViczsc6YH
(emitter core), req_011CfmUbNqY3xuRpcjE7pamD (walker arms).  Both opus fallbacks (`[builder-tier-explicit]`) died on
`[reasoning_extraction]` before any edit:  req_011CfmUeyBcK2pFnoPijx8mf, req_011CfmUf5X7PBzjmgSf7vvL5.  Delegation HALTED.
Stop check DONE:  every one-ctor family in test/rust/seed and test/rust/emit is a Prop (python scan), so E2 does not need E3.

DONE (STAGED, NOT COMPILED):
- rir.bend:  `Pat.PStruct{family, named: Bool, fields: List<String>, binds: List<Bind>}` and
  `Item.IStruct{name, ctor, named: Bool, fields: List<Param>, getters: List<Param>}`.  Design change from the proposal:
  `getters` carries the accessor return type, so erase_typed (not emit) decides Copy:  getter ty `TRef{A}` = borrow
  (`&self.a`), any other ty = copy (`self.a`).  A tuple struct has `getters` empty and its field names are the ctor
  parameter names (`x0`, `x1`, ...).
- emit.bend:  `pat` arm PStruct -> `struct_pat` (named:  `S { a, b: x, c: _ }` with shorthand when bind = field name,
  rest False;  tuple:  PTupleStruct `N(x, _)`);  `items` arm IStruct -> struct with `derive(False{})` + ctor fn via
  `fn_item` (`S { a, b }` or `N(x0, x1)`) + `impl_block` (one IImpl, first accessor without a blank line).  Helpers
  FB/field_pat/field_pats/struct_pat above `pat`;  nfields/param_tys/inits/args/struct_body/struct_new/getter_body/
  getter/getters/impl_block above `items`.

FIRST BUILD ERROR (bend reports one at a time;  build:  `~/.bend/bin/bend <CODE>/bend2/tests/rust_emit.bend -o
$TMPDIR/e2/re.js`):  `expected : cases for ../rust/rir.IStruct` at erase_typed.bend `show_item` :855.

NEXT (in order):  1. erase_typed `show_item` :855 + every other R.Item / R.Pat match (rebuild until clean);
2. walker arms lift/resolve/infer/lower/rust_out (list above, E1 XLet precedent in 2323e44 + 6ed4700);
3. erase_typed classification (Task 1-7:  CData class, item, ctor application -> XCall, case -> PStruct, the 3 refusals);
4. tests rust_emit_oracle `Et.CData` :68 + rust_emit struct case;  5. struct_probe.mech + e2-struct.sh (from e1-let.sh,
drop the `py` call of dev/rust-in-cli-gate.py);  6. gates (baselines above) + Close.

## Session 4 state (2026-10-06, claude7):  step 3 task, ready to run
Code 65aa35e and W b2a96e8 (plus this entry).  No code change in session 4 (builders dead, E-PROGRESS "E2 session 4").
Give this section to one builder, or hand build it in a session launched with CLAUDE_STEP_BUDGET=0.

Classification in CODE/bend2/rust/erase_typed.bend (line numbers at 65aa35e).  A family with ONE constructor, at
least one KEPT (non-Prop) field, no index and no generic becomes a struct:
1. All kept binders named:  `IStruct{name, ctor, named: True, fields, getters}`.  Field names through `fn_name`
   (:78).  Ctor fn name through D7 as `unit_kept` (:674).  Getter ty = field ty when it is `TBool` or a `TCon` in
   `copies_of(env)`, else `TRef{field ty}`.
   Check uniqueness AFTER `fn_name` on the kept fields, before producing IStruct.  For example, `fooBar` and
   `foo_bar` both become `foo_bar`, which duplicates the Rust field, ctor parameter and accessor.  Give a located
   CNo ``constructor fields `<a>` and `<b>` both map to `<rust>` (E2)``; do not emit invalid Rust.  Apply the same
   check to keyword escaping collisions such as `type` and `type_`.  Erased fields do not participate.
2. All kept binders `_`:  tuple struct, `named: False`, Params `x0`, `x1`, ..., `getters` empty (check no clash).
3. Mixed:  CNo ``a constructor with named and `_` fields (E2)``.
4. U15:  accessor name AFTER `fn_name` in {clone, clone_from, eq, ne, fmt}:  CNo ``a field named `<name>` shadows a derived trait
   method (E2)``.  Record U14 and U15 under "Rulings wanted" in E-PROGRESS.md.
5. A struct is never in `copies` (ED8, `copy_names` :901).
6. Ctor application:  `XCall{ctor_fn, [], args}`, kept args erased and boxed as the enum path does (`item_plan`
   :1156, `enum_plan` :1153, BCtor, box_flags).
7. Same-module case:  `R.PStruct{family, named, field names (empty for tuple), binds}`, no `..` (`br` :1463, `br_of`,
   `brs`, `elim_plan` :1539, `match_plan`).  Case on a struct from another module:  CNo ``a case on the struct `<S>`
   outside its module (E2)`` (how `IUse{module}` is made;  `classify2` :984;  if no reliable signal, refuse every
   case on an imported struct and log it).
8. U12:  no more one-variant enum for such a family.  All fields erased stays `IUnit` (:645, :683).  With generics:
   today (one-variant IEnum).  Entry `classify_family` :701 -> `family_class` -> `data_class` -> `unit_class`;  add a
   name-keeping sibling of `variants`/`fields`/`field_step` (:562-605) for the one-ctor case.
Tests:  rust_emit_oracle `Et.CData` (~:68) for IStruct;  a SOURCE fixture (named struct with a Bool field and a
family field, tuple struct, ctor application, same-module case with a renamed and a skipped bind) plus refusal
fixtures for items 1 (mapped-name collisions), 3, 4, 7; include `fooBar`/`foo_bar`, `type`/`type_`, and `cloneFrom`
(maps to the reserved accessor `clone_from`).  EMIT.md.  Expect zero changed goldens (stop check); if one changes,
stop and report.
Gates:  W/e2-struct.sh = copy of e1-let.sh minus `pygate RUST-IN-CLI`, plus `pygate RUST-STRUCT
dev/rust-struct-gate.py`.  Baselines:  RUST-PARSE 36/36, RUST-IN 33/33, ROUND-TRIP 99/99, RUST-INFER 39 + 22 golden,
RUST-LOWER 46, RUST-LET as e1, struct 24/24;  both drivers build;  emitted crate fmt check through gateledger plus
DIFF-EXEC.  The copied e1 runner has no `exec` mode: run `zsh ~/Documents/mech-rust/d3-points.sh exec` separately
with the sandbox off, or add the equivalent mode to e2-struct.sh.  DIFF-EXEC is required for these emitter
changes; the lack of a runner mode does not waive it.  Sequential runs.  RUST-IN-CLI remains a separate USER
quiet-box gate, as recorded in E-PROGRESS session 2; omitting it from the local runner does not count as a pass.
Record any pending gate explicitly and do not report full validation while it is pending.  Close: E-PROGRESS
entry, this file top status, stage own paths, print write-trees and `E2: ` commit messages (no Co-Authored-By).
NEVER commit or push.
