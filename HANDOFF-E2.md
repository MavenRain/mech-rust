# HANDOFF E2: the struct, emitter side (2026-10-06, claude7, session 9d1e3ea8)

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
