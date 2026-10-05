# mech-rust unit C crib (C-LEARN.md)

2026-10-04, hand extract in the main loop (both wf-builder agents died, see C-PROGRESS.md log).
Worktree /Users/oobi/Documents/mechanism-lang-rust-m0, branch mech-rust/m1, HEAD 317131b + the C0 position change.
Line numbers are those of the C0 working tree (after the position change). Paths are relative to the worktree.
STATE: L1, L2 and L7 are complete (files read in full: emit.bend, ast.bend, rust_frontend.bend, the two gate
scripts). L3, L5 and L6 were written by hand on 2026-10-04 in the C1 session (HEAD acfdfd6, the C0 commit; span
reads, each open point is named). L4 is complete: the probe of Part 2 gave C1-CRIB-OK.

## L1 emit.bend lowering table
Each line: RIR shape -> A shape (bend2/rust/emit.bend:<line>). `lift` (C1) is the inverse of this table.
Helpers: m0() = Meta{False, [], [], 0:0} (:12).  gap(ats) = Meta{True, [], ats, 0:0} (:15).
path1(a) = [Seg{a, []}] (:18).  path2(a, b) = [Seg{a, []}, Seg{b, []}] (:21).
tail(e) = [SExpr{m0(), e, False}] (:104).
Types (`tys`, :38):
- R.TBool            -> A.TPath{path1("bool")} (:43)
- R.TCon{name, args} -> A.TPath{[Seg{name, tys(args)}]} (:45)
- R.TBox{i}          -> A.TPath{[Seg{"Box", [ty(i)]}]} (:47)
- R.TRef{i}          -> A.TRef{ty(i)} (:49)
- R.TFn{args, ret}   -> A.TImpl{[A.TFnSugar{"Fn", tys(args), Some{ty(ret)}}]} (:51)
Params and patterns:
- R.Param{name, t} of a fn      -> A.PTyped{PPath{path1(name)}, ty(t)} (`params`, :59)
- R.Param{name, t} of a closure -> A.CParam{PPath{path1(name)}, Some{ty(t)}} (`cparams`, :66)
- R.BVar{name} -> A.PPath{path1(name)};  R.BSkip -> A.PWild (`binds`, :73)
- R.PCtor{family, ctor, Nil} -> A.PPath{path2(family, ctor)} (:85)
- R.PCtor{family, ctor, bs}  -> A.PTupleStruct{path2(family, ctor), binds(bs)} (:87)
Expressions (`nodes`, :126):
- XVar{name}                -> EPath{path1(name)} (:131)
- XInt{text}                -> ELit{LInt{text}} (:133);  XBool{value} -> ELit{LBool{value}} (:135)
- XCall{func, targs, args}  -> ECall{EPath{[Seg{func, tys(targs)}]}, nodes(args)} (:137)
- XCtor{family, ctor, Nil}  -> EPath{path2(family, ctor)} (:139)
- XCtor{family, ctor, args} -> ECall{EPath{path2(family, ctor)}, nodes(args)} (:141)
- XMatch{scrut, arms}       -> EMatch{scrut, [Arm{m0(), pat(p), None, arm_body(body)}]} (:143, `zip_arms` :119)
                               arm_body: a body that is an EIf becomes EBlock{tail(EIf)} (:108)
- XIf{c, yes, no}           -> EIf{c, tail(yes), Some{EBlock{tail(no)}}} (:145)
- XClosure{ps, body}        -> EClosure{False, cparams(ps), None, body} (:147)
- XBorrow{i}                -> EUnary{"&", i} (:149)
- XClone{i}                 -> EMethod{i, "clone", [], []} (:151)
- XBox{i}                   -> ECall{EPath{path2("Box", "new")}, [i]} (:153)
Items (`items(xs, use_gap)`, :189):
- IUse{m} -> A.IUse{Meta{use_gap, [], [], 0:0}, Priv, UPath{"crate", UPath{m, UGlob}}} (:194).  use_gap is True for
  the first item and after an item that is not a `use`;  it is False after a `use`.
- IEnum{name, gs, copy, vs} -> A.IEnum{gap(derive(copy)), Pub, name, bounds(gs, []), variants(vs)} (:196).
  derive(True) = derive(Clone, Copy, Debug, PartialEq, Eq);  derive(False) has no Copy (:158).
  R.Variant{name, Nil} -> A.Variant{m0(), name, BUnit} (:181).
  R.Variant{name, fs}  -> A.Variant{m0(), name, BTuple{[TField{m0(), Priv, ty}]}} (:183, `fields` :169).
- IUnit{name, ctor} -> TWO items: A.IStruct{gap(derive(True)), Pub, name, [], BUnit}, then
  fn_item(ctor, [], [], TPath{path1(name)}, EPath{path1(name)}) (:197).
- IFn{name, gs, ps, ret, body} -> fn_item (:200) =
  A.IFn{gap([]), Pub, Sig{name, bounds(gs, [TPath{path1("Clone")}]), params(ps), Some{ret}}, Some{tail(body)}} (:185).
Module{source, its} -> SrcFile{[" Emitted by `mech rust-out` from `" ++ source ++ "`."], items(its, True)} (:203).
Inverse hints for lift (HYPOTHESIS, to check in C1): EPath with 1 segment = XVar, with 2 = nullary XCtor.
ECall on EPath{[Box, new]} = XBox;  on a 2-segment path = XCtor;  on a 1-segment path = XCall (targs in the Seg).
TPath "bool" = TBool;  "Box" with one argument = TBox;  other = TCon.  PPath with 1 segment in a tuple-struct
pattern = BVar.  A unit struct and the next fn (body = the struct name) make one IUnit.

## L2 ast.bend constructors and positions
Types of bend2/rust/ast.bend (constructor fields in order;  a match names ALL fields by position):
- Vis (:7) Priv | Pub | PubCrate.  Attr (:13) Attr{name, args: Maybe<List<String>>}.
- Pos (:17) Pos{line: Nat, col: Nat}.  NEW in C0.
- Meta (:22) Meta{gap: Bool, docs: List<String>, attrs: List<Attr>, pos: Pos}.  `pos` is NEW in C0.
- Seg<T> (:26) Seg{name, args: List<T>}.
- Ty (:29) TPath{segs} | TRef{inner} | TTuple{items} | TSlice{inner} | TInfer | TImpl{bounds} |
  TFnSugar{name, args, ret: Maybe<Ty>}.
- GParam (:38) GParam{name, bounds: List<Ty>}.  Lit (:41) LInt{text} | LStr{text} | LChar{text} | LBool{value}.
- FieldPat<P> (:47).  Pat (:50) PWild | PPath{segs} | PTupleStruct{segs, items} | PStruct{segs, fields, rest} |
  PTuple{items} | PLit{lit} | PRef{inner} | POr{alts}.
- CParam (:60) CParam{pat, ty: Maybe<Ty>}.  Param (:63) PSelf{by_ref} | PTyped{pat, ty}.
- Sig (:67) Sig{name, generics: List<GParam>, params: List<Param>, ret: Maybe<Ty>}.
- Field (:70) NField{meta, vis, name, ty} | TField{meta, vis, ty}.
- Body (:75) BUnit | BTuple{fields} | BNamed{fields}.  Variant (:80) Variant{meta, name, body}.
- UseTree (:83) UPath{seg, sub} | UName{name, alias} | UGlob | UGroup{items}.
- Stmt<N> (:90) SLet{meta, pat, ty, init} | SExpr{meta, expr, semi} | SItem{item}.
- Arm<N> (:95) Arm{meta, pat, guard, body}.  FieldInit<N> (:98).
- Node (:101), expressions (no meta): EPath{segs} | ELit{lit} | ECall{func, args} | EMethod{recv, name, generics,
  args} | EField | ETry | EUnary{op, inner} | EBinary | EClosure{mv, params, ret, body} | EBlock{stmts} |
  EIf{cond, body, els} | ELet | EMatch{scrut, arms} | EStruct | ETuple{items} | EParen | EMacro.
- Node, items (each has `meta` first): IFn{meta, vis, sig, body: Maybe<List<Stmt>>} | IStruct{meta, vis, name,
  generics, body} | IEnum{meta, vis, name, generics, variants} | IUse{meta, vis, tree} | IMod | IImpl | ITrait |
  IConst | IType.
- SrcFile (:130) SrcFile{inner: List<String>, items: List<Node>}.
- Defs: no_pos (:133), show_pos (:137), meta_pos (:142), item_pos (:148), item_line (:171).
(a) Meta: the 9 item constructors of Node, Field (2), Variant, SLet, SExpr and Arm have a `meta` field.  The 17
    expression constructors of Node, SItem, Ty, Pat, Param, CParam, Sig, Body, UseTree, GParam and Lit have none.
(b) Token position: Tk.Loc{line, col}, one-based (bend2/rust/token.bend:4), in Tk.Tok{kind, loc, gap} (:24).  Text:
    Tk.show_loc = `<line>:<col>` (:39).  The parser has no state type: it passes the token list
    List<PT>, PT{k, Info{text, loc, gap}} (bend2/rust/parser.bend:81, :84).  `head_kind` (:148), `head_gap` (:155)
    and the new `head_pos` (:163) read the first token.  The fragment pass prints `REFUSED <line>:<col> <construct>`
    (FRONTEND.md "Pipeline", step 2).
(c) Edit surface.  Meta: 1 construction site in the parser (parser.bend:1087, the last MMeta arm), 3 in emit.bend
    (:12, :15, :194), 2 match sites in print.bend (:175, :181).  No other file names `Meta{`.  A new field on each
    Node constructor has a far larger surface (26 constructors, each match in parser.bend and print.bend names
    all fields):  NOT counted.
(d) Chosen in C0: `pos` in `Meta`.  The parser sets it in the last MMeta arm, from the first token after the
    outer docs and attributes (all five MMeta starts go through that arm: arm :861, stmt :909, item :1120,
    field :1246, variant :1270).  An expression, type or pattern has no position;  a refusal for one of these
    takes the position of the nearest statement, arm or item.

## L3 syntax.bend surface types
bend2/surface/syntax.bend, read :1-90.  Import: `import ../surface/syntax.bend as Syntax` (bend2/cli/rust_out.bend:6).
In the source each list is `List<&2, X>` and each option is `Maybe<&2, X>`.  The types below T have a type
parameter A;  the instance in use is A = T.
- Prim (:7) PAdd | PSub | PMul | PEq | PLt.  The text names are in prim_name (:89, NOT read).
- Binder<A> (:14) Binder{quantity: Quantity.T, name: String, ty: A}.
- Motive<A> (:17) Motive{self: String, ind: Maybe<String>, indices: List<String>, body: A}.
- Field<A> (:20) Field{quantity: Quantity.T, name: String, ty: Maybe<A>}.  A field of a case branch.
- Branch<A> (:23) BrLeg{index: Bignum.T, binders: List<Binder<A>>, body: A} |
  BrCtor{name: String, fields: List<Field<A>>, body: A}.  `| mechSucc previous => e` is a BrCtor.
- FamCtor<A> (:27) FamCtor{name: String, ty: A}.  `ty` is the full constructor type (arrows to the family).
- Fam<A> (:30) Fam{name: String, params: List<Binder<A>>, ty: A, ctors: List<FamCtor<A>>}.
- RecDef<A> (:33) RecDef{name: String, ty: A, body: A}.
- T (:36), the terms.  For the importer: SVar{name} | SNat{value: Bignum.T} | SProp | SType{level: Bignum.T} |
  SApp{head, arg} (one argument for each node) | SFun{binders: List<Binder<T>>, body} |
  SArrow{binder: Binder<T>, body} | SCase{scrut, motive: Maybe<Motive<T>>, branches: List<Branch<T>>}.
  The other constructors: SSort{level: Universe.T}, SPrim{prim}, SUnit, SAuto, SPair{left, right}, STuple{items},
  SSum{items}, SProd{items}, SProj{head, index}, SInj{index, count, value}, SAbsurd{value}, SStar{binder, body},
  SZkTy, SProve, SVerify, SFhcTy, SEnc, SEval, SDec, SMpcTy, SShare, SInput, SJoin, SOpen,
  SLet{name, ty, value, body}, SAnn{value, ty}, SMatch{scrut, motive, branches} (same fields as SCase).
- Decl (:78) DPoly{universes: Nat, name, ty, body} | DPolyMu{universes, family} | DPolyGroup | DPolyCompose |
  DSpecialize{specialization} | DDef{name: String, ty: T, body: T} | DAxiom{name, ty} |
  DMu{families: List<Fam<T>>} | DRec{definitions: List<RecDef<T>>}.
- Quantity: Quantity.T = QZero | QOne | QMany (bend2/kernel/quantity.bend:4;  syntax.bend:3 imports it as
  Quantity).  Level: `Type 0` is SType{0n} (a Bignum.T literal has the suffix `n`, syntax.bend:426);  `Prop` is
  SProp.  Universe.T (SSort) is for `poly` declarations (HYPOTHESIS, universe.bend NOT read).

## L4 Is Syntax.print parse-stable
Part 1 (read).  syntax.bend:102: "Printing uses explicit parentheses to preserve precedence and branch scope".
- `raw(term)` (law at :103) is the term printer that the declaration printers call.  `show(term)` is at :263 and the
  precedence printer `at(level, term)` at :569 (level table near :426).  NOT read: how the three call each other.
- `mark(quantity)` (:107): QZero -> "0 ", QOne -> "1 ", QMany -> "" (no mark).  `binder_text` (:117):
  `(<mark><name> : <type>)`.  `fields_text` (:131): a branch field with no type prints `<mark><name>`.
  `motive_text` (:155): None -> "";  Some -> ` as <self>[ in <family><index names>] return <body>`.
- `decl_text(decl)` (:357): DDef -> `def <name> : <ty> := <body>\n` (:370);  DAxiom -> `axiom <name> : <ty>\n`
  (:372);  DMu with one family -> fam_text("mu", family) (:376, fam_text :278);  DMu with two or more ->
  `mutual\n ... end\n` (:378);  DRec -> rec_defs_text(definitions, "def rec", "and") (:380);  DPoly* -> `poly (..)`.
- `print(decls)` (:382) joins the decl_text of each declaration.  It prints no blank line and no comment.
- bend2/surface/API.md:20: "`show(T)` and `print(List<&2, Decl>)` print parseable syntax."
- Tests that exist: bend2/tests/relational_common.bend:106 `parse_roundtrip` and bend2/tests/kernel_protocol.bend:68
  `round_trip`: parse, print, parse again, then `Same.declarations(first, second)`
  (bend2/tests/relational_syntax_equal.bend:371).  bend2/tests/surface_poly.bend:34 does it for terms
  (`Parser.term(Syntax.show(term))`).  The inputs of these tests are NOT listed here.
- Parser entries: `Parser.program(source)` -> Result<Error.T, List<Decl>> (bend2/surface/parser.bend:901),
  `Parser.term` (:895).  Error text: `E.message(error)` (bend2/kernel/error.bend:23).
Part 2 (probe on init.mech and second-price.mech).  RUN 2026-10-04 at acfdfd6.  Files: W/c1-print-probe.bend (modes
`t1` and `same`) and the runner `zsh /Users/oobi/Documents/mech-rust/c1-crib.sh`.  T1 = print(parse(src)).
      PROBE init.mech decls=26 t1_bytes=5485 fixpoint=YES decl_equal=SAME
      PROBE second-price.mech decls=30 t1_bytes=9294 fixpoint=YES decl_equal=SAME
      C1-CRIB-OK
fixpoint = print(parse(T1)) is byte-equal to T1.  decl_equal = Same.declarations(parse(src), parse(T1)).
The probe copy in bend2/tests/ is removed at exit (worktree clean after the run).
No Elab.check_in run of the printed text (C4 mode `check` does it).
VERDICT: Syntax.print is the printer for lower.bend (CD11 holds on the declaration shapes of the two inputs).
Shapes in the two inputs: `mu` with parameters, constructor with fields, `def`, `def rec`, quantity 0 and many,
`case` with a motive, `fun`, Nat literal.  NOT in the two inputs: quantity 1, `case` with no motive.

## L5 Surface text examples
Inputs: prelude/init.mech (I) and prelude/mechanism/second-price.mech (S).  A comment line starts with `--`.
(a) Family with parameters, I:22-24:
      mu MechSum (0 A : Type 0) (0 B : Type 0) : Type 0 with
      | mechInl : A -> MechSum A B
      | mechInr : B -> MechSum A B
    A family with no parameter: `mu AuctionChoice : Type 0 with` + `| auctionLose : AuctionChoice` (S:18-20).
    A constructor term takes the FIELDS only, no family parameter: `auctionBelow (auctionLeZero mechZero)` (S:35) for
    `mu AuctionOrder (0 bid : MechNat) (0 price : MechNat)` (S:23).  A branch pattern binds the fields only:
    `| mechInl a => left a` (I:55).  NOT verified: a constructor of a family with parameters in a position with
    no expected type (CD9 refuses it).
(b) `case` with a motive, I:38-40:
      case b as self in MechBool return A with
      | mechFalse => no
      | mechTrue => yes
    Dependent motive: `case n as self in MechNat return P self with` (I:62).  No branch: I:44 (MechEmpty).
    A nested case in a branch has parentheses: `| mechZero => (` ... `)` (S:31-37).
    EACH case of prelude/*.mech has `return` (rg: no one-line `case ... with` without it).  The type has
    `motive: Maybe` and motive_text prints None as "", so a case with no motive parses (elab rule NOT read).
    Rule for lower.bend: always print the motive (CD9 gives the result type of each XMatch).
(c) Quantity marks: `0 ` = QZero, `1 ` = QOne, no mark = QMany (syntax.bend:107;  parser.bend:78-82).
    `A -> B` with no binder is SArrow{Binder{QMany, "_", A}, B} (parser.bend:461).  A constructor field is a
    binder of the constructor type, same rule: `(0 refute : P -> MechFalse) -> MechDecidable P` (I:27).
    A def repeats its binders: `def f : (0 A : Type 0) -> A -> A := fun (0 A : Type 0) (x : A) => x` (form of I:36).
(d) `def rec`, S:164-168:
      def rec auctionAdd : MechNat -> MechNat -> MechNat :=
        fun (left : MechNat) (right : MechNat) =>
          case left as self in MechNat return MechNat with
          | mechZero => right
          | mechSucc previous => mechSucc (auctionAdd previous right)
    The recursive call takes the field `previous` that the branch binds (also I:58-64, S:27-45).  HYPOTHESIS:
    the totality check (bend2/kernel/totality.bend, NOT read) needs this structural form.
(e) Nat: type `Nat`, literals `0` and `1`, addition `natAdd 1 previous` (S:171-173).  NOT verified: natAdd is
    SPrim{PAdd} or a global name (prim_name, syntax.bend:89).
(f) `fun`: `fun (value : MechNat) (previous : Nat) => natAdd 1 previous` (S:173).  Function types: `A -> C`,
    `(x : A) -> B x` (I:31), `(n : MechNat) -> P n -> P (mechSucc n)` (I:59).  Sigma type: `(x : A) * B x` (I:34).

## L6 Unit B reuse points
- `//!` line text: bend2/rust/emit.bend:206.  Derive lists: emit.bend:158.  `Clone` bound of each fn generic:
  emit.bend:185.  Blank line rule of `use` lines: emit.bend:189 (`use_gap`).
- VERIFIED at acfdfd6: lib.rs = `lib_rs(names)`, "//! Emitted by `mech rust-out`.\n\n" ++ pub_mods(sorted(names))
  (bend2/cli/rust_out.bend:564-565;  each line `pub mod <name>;`, :562).  Reserved module names: `reserved()` =
  bin, lib, main, nat (rust_out.bend:70-71).
- nat module: fixed text `nat_rs()` (rust_out.bend:571), file entry `nat_file(nat)` (:636), `nat_mod` (:228),
  `any_nat` (:537).  `nat_names()` = Nat, nat_small, nat_add, nat_decimal (:73-74): FOUR names (CD7 has three).
  erase_typed.bend: item_nat (:1830), nat_used (:1837), nat_use = [R.IUse{"nat"}] (:1844).
- `use` line sort: `sorted(xs)` (rust_out.bend:99, insertion sort, byte order;  comment :76 "rustfmt sorts
  lower-case names by byte").  Call site :236: use_items(sorted(nat_mod(nat) ++ used_mods(mods, refs))).
- Copy set: `copy_names(c)` (bend2/rust/erase_typed.bend:815): an IEnum with copy = True gives its name, each IUnit
  gives its name;  the names go to the `copies` list of Env (:832, :1798).  So for the importer: each enum with
  `Copy` in the derive list, and each unit struct.  NOT read: where erasure sets the copy flag of an enum.
- D7 names (erase_typed.bend): snake (:48, snake_rest :40), upper_first (:55), keywords (:62), rust_name (:75,
  a keyword gets `_`), fn_name = rust_name(snake(s)) (:78), stem (:1848, drops `.mech`).  NOT located: the
  `-` -> `_` step of the module name.  Import: `import ../rust/erase_typed.bend as Et` (rust_out.bend:11);  from
  bend2/rust/ use `./erase_typed.bend`.  HYPOTHESIS (no build): each def is visible to an importing file.

## L7 Drivers and gate commands
- bend2/tests/rust_frontend.bend: `IO.args()` gives List<String> (`main`);  arguments `<mode> <source text>`.  The
  second argument is the TEXT of the file, not a path.  Modes: lex, parse, print, check, pos (`mode_of`).
  `Bool.pick` is eager, so the mode becomes a tag (`Md`) and `run_mode` matches on it.  Output: `IO.write`.
- bend2/tests/rust_emit.bend (from the gate script, the driver source is NOT read): modes `crate <files> <out dir>`,
  `probes <files>`, `values <files>`, `bin <files>`;  file names relative to the cwd (rust-out-diff-exec.sh:38-49).
- RUST-PARSE: `dev/rust-parse-gate.sh`.  Build `$BEND $DRIVER -o $WORK/rust_frontend.js` (:84), run
  `node $BIN check "<text>"` with an `x` sentinel that keeps the trailing newlines (:51-55).  Work directory from
  mktemp below $TMPDIR.  Needs rustfmt.  Last lines: `pass=35 fail=0`, `RUST-PARSE-OK`.  Runs in the sandbox.
- DIFF-EXEC: `dev/rust-out-diff-exec.sh [emit]`.  Stack rule: `ulimit -s "$(ulimit -Hs)"` (:20) and
  `node --stack-size=16384` (:23).  Build `$bend bend2/tests/rust_emit.bend -o $O/re.js`, O = $TMPDIR/mech-diff-exec
  (:26, :35).  cargo build with `-j 2` (:57), so the sandbox must be off.  Last line: `DIFF-EXEC-OK 238 values`.
- C0 check: `zsh /Users/oobi/Documents/mech-rust/c0-pos.sh` (one JS build, mode `pos` on each accepted fixture,
  expected lines from `rg -n`;  last line C0-POS-OK).
