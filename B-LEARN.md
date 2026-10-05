# B-LEARN: kernel + Bend 2 crib for mech-rust unit B

Source: the report of read-only agent ad5097572b735dc88 (10-03), written here by the main loop.  The agent read each
fact at the cited lines; the main loop did not check it again, so each line is a hypothesis.  GUESS = not read.
Paths are relative to /Users/oobi/Documents/mechanism-lang-rust-m0/bend2 (kernel/, surface/, cli/, tests/, rust/).
The directory of a cited file is not always recorded: use `rg --files bend2 | rg '/<name>.bend$'`.

## S1 TERM ENCODING
- Var 0 is the innermost binder (check.bend:68-83, eval.bend:148-149).  Values use de Bruijn levels; quote gives
  `Var{size-1-level}` (eval.bend:560-563).
- Pi: `Ran{SPi{q,x,A},B}`, B under 1 binder.  `A -> B` is `SPi{QMany,"_",A}`.
- Lambda: `Sec{SPi{q,x,A},[Leg{[(q,x)],body}]}`, one per binder, domain filled.
- Application: `Out{SPi{q,x,dom},APt{q,arg},head}`, dom filled (quoted).
- Family application: `Lan{SMu{F, indices}, Sec{SColl n, [Leg{[],p}..]}}`.  The params are in the Sec diagram; the
  indices are in the SMu args (elab_term.bend:762-768, 186-194).
- Constructor application: `In{SMu{F, indices}, ACtor{c}, fields}`.  Family params are NOT stored.  All Ctor.args
  fields are present, the quantity-0 ones too, in declaration order (elab_term.bend:797-852).
- Case: `Elim{ElimData{SMu{F,indices}, scrut, QOne, motive, branches}}`.  A branch is `Pair{ACtor{c}, Leg{binders,
  body}}`.  The binders are in source order with the quantity from the PATTERN (default QMany), not from the ctor
  declaration.  The body is under the fields only, so the last field is Var 0.  Motive is `Motive{ind, indices, self,
  body}`; in its body Var 0 = self and Var 1 = last index (elab_term.bend:1003-1094).
- Other forms: a non-local name is `Global{name}`; a Nat literal is `Lit{LInt{n}}`; let is `Let{name,ty,value,body}`.
- Sorts: Prop = `Univ{LZero{}}` (Level.zero()).  Type 0 = `Univ{LSucc{1,LZero}}` = Level.one().  Test for Prop with
  `Level.always_zero(level)` (level.bend:50).

## S2 QUANTITY
- `QZero | QOne | QMany`.  A binder with no annotation and `A -> B` both get QMany (parser.bend:75-82, 461).
- Zero test: `Quantity.equal(q, Quantity.QZero{})`.

## S3 FAMILIES
- Rows are in SOURCE order (elab.bend:579).  `mu` only calls Global.add_family (check.bend:247, 335).
- GUESS: the family and its ctors are not Entries and not Rows.  The sort of a family is `Family.level`.
- OPEN: check.bend 238-341 and elab.bend 490-569 not read.  GUESS: Ctor.args does not include the params.

## S4 CHECKED FORM
- Each row prints as `def N : TY := BODY\n`, `axiom N : TY\n` or `prim N : TY\n` with Pp.term([], ..)
  (elab.bend:610-617).  No golden example was read (candidates: tests/cli_core_expected.json, dev/bend2/cli-cases.json).

## S5 EVAL
- `Eval.eval(+globals, +env, term) -> Result<&2,&2,Error.T,Value.T>`, no budget argument; then `Eval.whnf(globals, v)`.
- A constructor value is `VIn{SMu{F,idx}, VACtor{c}, args}`.  Read-back is `quote(globals, size, value)` (eval.bend:567).
- OPEN: the exact `quote` law signature; how to apply a value (GUESS: `out_value(globals, SPi{..}, VAPt{q,arg}, f)`
  then whnf; eval.bend 109-122 and 225-243 not read).

## S6 TYPE OF A TERM
- `Check.infer(+ctx, mode, term) -> Result<..Value.T>` (check.bend:105); `Check.infer_univ(+ctx, term) ->
  Result<..Level.T>` (:121).
- Context: `Elab.context(globals, arity)` = `Check.make(globals, Budget.unlimited(), arity)`.  Extend with
  `Check.bind(name, q, tyValue, ctx)`.

## S8 IO AND CLI (part)
- io.bend:33 `read_file(path: String) -> IO(Result<&2,&2,String,String>)`.  The publish semantics were not read.

## S9 TEST DRIVERS AND BUILD (part)
- Build: `$BEND driver.bend -o x.js`; BEND from env BEND, fallback ~/.bend/bin/bend (dev/rust-parse-gate.sh:10,
  dev/bend2-build.py:311).  dev/bend2/test-manifest.json has a "drivers" list.
- tests/rust_frontend.bend:1-7 imports Base and ../rust/{token as Tk, lexer as Lexer, ast as A, parser as Parser,
  print as Pr, fragment as Fr}.bend; :105-108 `main() -> IO(Unit): args : List<String> <- IO.args();
  IO.write(run_args(args))`.
- dev/rust-parse-gate.sh:79 `if ! $BEND $DRIVER -o $BIN > $WORK/build.log 2>&1; then`; :52 `$NODE $BIN check
  "${src%x}" > $WORK/out 2> $WORK/err < /dev/null`.  Build about 1 min; each node run about 1 s.
- MIGRATION-BEND2.md: compiler pinned to Bend 2.0.27; build outputs go to `_bend2/`.

## VERBATIM DEFINITIONS
term.bend:10-40
  type Addr<-A: Data> is Data: APt{quantity: Quantity.T, arg: A} | ALeg{index: Bignum.T} | ACtor{name: String}
  type Leg<-A: Data> is Data: Leg{binders: List<&2, Common.Pair<Quantity.T, String>>, body: A}
  type Motive<-A: Data> is Data: Motive{ind: Maybe<&2, String>, indices: List<&2, String>, self: String, body: A}
  type ElimData<-A: Data> is Data: ElimData{shape: Shape.T<A>, scrut: A, scrut_q: Quantity.T,
    motive: Maybe<&2, Motive<A>>, branches: List<&2, Common.Pair<Addr<A>, Leg<A>>>}
  type T is Data: Var{index: Nat} Univ{level: Level.T} Lan{shape: Shape.T<T>, body: T} Ran{shape: Shape.T<T>, body: T}
    In{shape: Shape.T<T>, addr: Addr<T>, args: List<&2, T>} Elim{data: ElimData<T>}
    Sec{shape: Shape.T<T>, legs: List<&2, Leg<T>>} Out{shape: Shape.T<T>, addr: Addr<T>, head: T}
    Let{name: String, ty: T, value: T, body: T} Ann{body: T, ty: T} Global{name: String} Lit{value: Literal.T} Auto{}
shape.bend:5-13
  SPi{quantity: Quantity.T, name: String, domain: A} SColl{count: Bignum.T} SPar{left: A, right: A}
  SMu{name: String, args: List<&2, A>} SNu{name: String, args: List<&2, A>}
  SZk{quantity: Quantity.T, name: String, domain: A} SFhc{level: A} SMpc{parties: A, access: A}
level_var.bend:4-9 (Level.T = LevelVar.T)
  LZero{} LSucc{amount: Bignum.T, base: T} LMax{left: T, right: T} LIMax{left: T, right: T} LVar{index: Nat}
literal.bend:4-6      LString{value: String} LInt{value: Bignum.T}
quantity.bend:4-7     QZero{} QOne{} QMany{}
positivity.bend:10-25
  Binder{quantity: Quantity.T, name: String, ty: Term.T}; Telescope = List<&2, Binder>
  CtorStatus: Provisional{} Builtin{} Complete{names: List<&2, String>}
  Ctor{name: String, args: Telescope, res_idx: List<&2, Term.T>, full_arity: Nat, self_rec: Bool}
  Family{name: String, params: Telescope, indices: Telescope, level: Level.T, status: CtorStatus,
    ctors: List<&2, Ctor>, positive: Bool}
global.bend:8-17
  DefEntry{ty: Term.T, body: Term.T, reducible: Bool, rec_arg: Maybe<&2, Nat>, partial: Bool}
  Entry: Def{value: DefEntry} Axiom{ty: Term.T} Prim{ty: Term.T, prim: Prim.T}
  Globals{entries: List<&2, Common.Pair<String, Entry>>, families: List<&2, Common.Pair<String, Positivity.Family>>,
    entry_index: Map<..>, family_index: Map<..>}
  Lookups: :66 find_family(name, globals) -> Maybe<&2, Positivity.Family>; :111 find_def; :86 entry_ty.
  add and add_family cons at the head (newest first).
value.bend:10-42
  Head: HLocal{level: Nat} HGlobal{name: String}; Closure{env: List<&2, A>, body: Term.T}; VLeg{binders, clo: Closure<A>}
  VAddr: VAPt{quantity, arg: A} VALeg{index: Bignum.T} VACtor{name: String}
  Spine: SOut{shape, addr: VAddr<A>} SElim{data: StuckElim<A>}
  T: VUniv{level} VLan{shape, diagram: Closure<T>, level: Maybe<&2, Level.T>} VRan{same}
    VIn{shape, addr: VAddr<T>, args: List<&2, T>} VSec{shape, legs: List<&2, VLeg<T>>} VLit{value: Literal.T}
    VNeutral{head: Head, spine: List<&2, Spine<T>>}
elab.bend
  :44 def context(globals: Global.T, arity: Nat) -> Check.Ctx: Check.make(globals, Budget.unlimited(), arity)
  :579 def finish_program(state: Program) -> Checked: match state: case Program{globals, definitions, families,
       reversed}: Common.Pair{globals, List.reverse(&2, Common.Pair<String, Global.Entry>, reversed)}
  :589 def elab_program_in(globals: Global.T, budget: Budget.T, decls: List<&2, Syntax.Decl>)
       -> Result<&2, &2, Error.T, Checked>: Budget.run(Checked, elab_program_comp(globals, decls), budget)
  :602 def check_in(globals: Global.T, budget: Budget.T, source: String) -> Result<&2, &2, Error.T, Checked>:
       decls <- Parser.program(source); elab_program_in(globals, budget, decls)
  :610 entry_text: "def " ++ name ++ " : " ++ Pp.term([], ty) ++ " := " ++ Pp.term([], body) ++ "\n" | "axiom " .. | "prim " ..
host.bend:231-234
  def kernel_outcome(+globals:Global.T,export:String) -> Outcome:
    kernel_value(do Result<&2,&2,Error.T,V.T>:
      value : V.T <- Eval.eval(globals,[],Term.Global{export})
      Eval.whnf(globals,value))

## REMAINING READS (sections that the first agent did not reach; a second agent may add them below)
- S3: check.bend 238-341; elab.bend 490-569.            - S4: pp.bend 136-163.
- S5: eval.bend 109-122 and 225-243.
- S7: erase.bend 1-70; erase_util.bend 30-60, 110-160, 205-215; prim.bend 1-96.
- S8: io.bend 1-205; host.bend 200-217.
- S9: tests/rust_frontend.bend 70-108; dev/rust-parse-gate.sh 1-103.
- S10: rust/ast.bend 1-149; rust/print.bend (rg '^def ' and 'width|100'); rust/FRONTEND.md 1-93.
- S11: W/A-PROGRESS.md 1-78.

## S10 UNIT A ASSETS (rust/ast.bend, rust/print.bend)
Paths are under /Users/oobi/Documents/mechanism-lang-rust-m0/bend2/rust/. Module aliases: `A` = ast.bend, `Pr` = print.bend (FRONTEND.md:24).
AST types (ast.bend; all `is Data`; list type is `List<&2, T>`, maybe is `Maybe<&2, T>`):
- ast.bend:7 Vis: Priv{} | Pub{} | PubCrate{}
- ast.bend:13 Attr: Attr{name: String, args: Maybe<&2, List<&2, String>>}
- ast.bend:17 Meta: Meta{gap: Bool, docs: List<&2, String>, attrs: List<&2, Attr>}
- ast.bend:21 Seg<-T: Seg{name: String, args: List<&2, T>}
- ast.bend:24 Ty: TPath{segs: List<&2, Seg<Ty>>} | TRef{inner} | TTuple{items} | TSlice{inner} | TInfer{} | TImpl{bounds: List<&2, Ty>} | TFnSugar{name: String, args: List<&2, Ty>, ret: Maybe<&2, Ty>}
- ast.bend:33 GParam: GParam{name: String, bounds: List<&2, Ty>}
- ast.bend:36 Lit: LInt{text} | LStr{text} | LChar{text} | LBool{value: Bool}
- ast.bend:42 FieldPat<-P: FieldPat{name: String, pat: Maybe<&2, P>}
- ast.bend:45 Pat: PWild{} | PPath{segs} | PTupleStruct{segs, items: List<&2, Pat>} | PStruct{segs, fields: List<&2, FieldPat<Pat>>, rest: Bool} | PTuple{items} | PLit{lit} | PRef{inner} | POr{alts}
- ast.bend:55 CParam: CParam{pat: Pat, ty: Maybe<&2, Ty>}
- ast.bend:58 Param: PSelf{by_ref: Bool} | PTyped{pat: Pat, ty: Ty}
- ast.bend:62 Sig: Sig{name: String, generics: List<&2, GParam>, params: List<&2, Param>, ret: Maybe<&2, Ty>}
- ast.bend:65 Field: NField{meta, vis, name: String, ty: Ty} | TField{meta, vis, ty: Ty}
- ast.bend:70 Body: BUnit{} | BTuple{fields: List<&2, Field>} | BNamed{fields: List<&2, Field>}
- ast.bend:75 Variant: Variant{meta: Meta, name: String, body: Body}
- ast.bend:78 UseTree: UPath{seg: String, sub: UseTree} | UName{name: String, alias: Maybe<&2, String>} | UGlob{} | UGroup{items}
- ast.bend:85 Stmt<-N: SLet{meta, pat, ty: Maybe<&2, Ty>, init: Maybe<&2, N>} | SExpr{meta, expr: N, semi: Bool} | SItem{item: N}
- ast.bend:90 Arm<-N: Arm{meta, pat, guard: Maybe<&2, N>, body: N}
- ast.bend:93 FieldInit<-N: FieldInit{name: String, value: Maybe<&2, N>}
- ast.bend:96 Node (exprs and items in one type): EPath{segs} | ELit{lit} | ECall{func, args} | EMethod{recv, name, generics: List<&2, Ty>, args} | EField{recv, name} | ETry{inner} | EUnary{op: String, inner} | EBinary{op: String, lhs, rhs} | EClosure{mv: Bool, params: List<&2, CParam>, ret, body} | EBlock{stmts} | EIf{cond, body: List<&2, Stmt<Node>>, els: Maybe<&2, Node>} | ELet{pat, init} | EMatch{scrut, arms} | EStruct{segs, fields, base} | ETuple{items} | EParen{inner} | EMacro{name: String, bracket: Bool, args: List<&2, Node>}
- ast.bend:114 Node items: IFn{meta, vis, sig: Sig, body: Maybe<&2, List<&2, Stmt<Node>>>} | IStruct{meta, vis, name, generics, body: Body} | IEnum{meta, vis, name, generics, variants: List<&2, Variant>} | IUse{meta, vis, tree} | IMod{meta, vis, name, inline: Bool, inner: List<&2, String>, items} | IImpl{meta, generics, tr: Maybe<&2, Ty>, self_ty: Ty, items} | ITrait{meta, vis, name, generics, supers: List<&2, Ty>, items} | IConst{meta, vis, name, ty, value: Maybe<&2, Node>} | IType{meta, vis, name, generics, ty: Maybe<&2, Ty>}
- ast.bend:125 SrcFile: SrcFile{inner: List<&2, String>, items: List<&2, Node>}
- ast.bend:128 `def item_line(n: Node) -> String` is a debug label printer only.
Printer entry point:
- print.bend:830 `def file(f: A.SrcFile) -> String:` (inner docs, items, one trailing newline; print.bend:829)
- print.bend:389 `def pp(j: Job) -> String:` is the worker; `Job` is a type of work items (print.bend:307).
- print.bend:62 `def sp(n: Nat) -> String:`; print.bend:70 `def room(ind: Nat, used: Nat) -> Nat:` = 100 minus (ind + used) (print.bend:71).
Width handling (VERDICT: print.bend breaks long lines, yes):
- print.bend:9-11 header: models rustfmt max_width 100, fn_call_width 60, chain_width 60, struct_lit_width 18, struct_variant_width 35, single_line_if_else_max_width 50.
- print.bend:632-634 JArgs: try flat `head args close` if args text <= 60 cols (`capped(.., 60n)`) and it fits `avail`; else JOvf (overflow last arg) else JVert.
- print.bend:641-642 JVert: head, newline, one arg per line, `,` after each arg (print.bend:645 JArgLines `... ++ ",\n"`), then `close` at the outer indent. Trailing comma: yes.
- print.bend:764-768 JFn: flat `fn name<G>(params) -> R` if it fits `room(ind, body_len(body))`, else JFnV: `(` newline, one param per line via JParamLines (indent+4), `)` ret. Params one per line: yes.
- print.bend:790-791 enum struct variants go multi-line when wider than 100 / w (35).
- print.bend:676 method call args use JArgs; chains break one link per line (print.bend:665-668 JLinks).
Printer gaps (FRONTEND.md:87-93, copied):
- A raw identifier prints without `r#`.
- A binary expression breaks only after the last operator. There is no rustfmt layout for operator chains.
- A match arm body that is too wide is not put in a block.
- A long `if` condition, long function generics and a long use tree do not break.
- Tuple-struct fields and generic lists are always on one line.
Fragment-pass gaps are refusals (FRONTEND.md:36-63): loop while for &mut mut unsafe .unwrap() .expect( .scan( panic! assert! assert_eq! other macros (not vec!) as indexing dyn lifetime async .await non-doc comments.
Construct table (construct | AST | printer | cite):
- enum, tuple variants + generics | yes | yes | ast.bend:116,72,34; print.bend:742-744,785,480
- unit struct `pub struct X;` | yes (BUnit) | yes (";") | ast.bend:71; print.bend:775-776
- tuple struct, private field | yes (TField vis Priv) | yes (vis prints "" for Priv, GUESS from print.bend:131) | ast.bend:67,72; print.bend:777-778,806
- `#[derive(..)]` | yes (Attr args) | yes | ast.bend:13,18; print.bend:151,158,173 (bodies not read, GUESS on exact form)
- `use crate::m::*;` | yes (UPath..UGlob) | yes | ast.bend:79,81; print.bend:505-511,745-746
- fn generics with bounds `<A: Clone>` | yes (GParam bounds) | yes, flat only | ast.bend:34; print.bend:482-486 (never breaks, FRONTEND.md:92)
- param `&impl Fn(&A) -> C` | yes (TRef of TImpl of TFnSugar) | yes | ast.bend:26,30,31; print.bend:403-404,413-416
- `Box<T>` | yes (Seg args) | yes (JSegs, turbo False) | ast.bend:21,25; print.bend:401-402,437-443
- match, path patterns, `_` in tuple-struct pattern | yes (PPath, PTupleStruct, PWild) | yes | ast.bend:46-48; print.bend:445-450
- empty match `match e {}` | yes (EMatch arms Nil) | NO: prints `match e {` newline `}` (JBrk, no empty case) | print.bend:615-616,719-720
- if/else as expression | yes (EIf cond body els) | yes (JIf, JIfFlat) | ast.bend:107; print.bend:543,613-614,713
- closure `|x: &T| expr` | yes (CParam ty) | yes | ast.bend:55,105; print.bend:502,537-538,617-618
- turbofish `f::<T>(a)` | yes (Seg args in EPath; EMethod generics) | yes (JSegs turbo True, JTurbo) | ast.bend:97,100; print.bend:433-443,520-521
- method call `x.clone()` | yes (EMethod) | yes (chain logic) | ast.bend:100; print.bend:526-528,603-604
- ref expression `&expr` | yes (EUnary op String; parser builds it, parser.bend:701) | yes (op ++ inner) | ast.bend:103; print.bend:533-534,621-622
- `impl Trait for Type` | yes (IImpl tr Some) | yes | ast.bend:119; print.bend:751-752
- `//!` inner doc | yes (SrcFile.inner, IMod.inner) | yes (file head; JModBody) | ast.bend:118,126; print.bend:820-823,830 (file body not read)
- macro `println!("{:?}", x)` | yes (EMacro name bracket args; LStr text) | yes (JFl, JBrk, JArgs) | ast.bend:113; print.bend:557,601-602
Only "no" in the table: empty match. All other rows are yes, but fragment pass refuses `println!` (macro name rule, FRONTEND.md:54) so a macro call other than vec! is refused before printing.

## S11 BEND 2 AUTHORING RULES (from unit A)
Source: /Users/oobi/Documents/mech-rust/A-PROGRESS.md (lines cited).
Syntax facts:
- A-PROGRESS:24 `(a, b) = p` in a do block is REJECTED. `Pd{+a, r} <- m` is REJECTED (annotated form is a syntax error). Built-in pair is Type, not Data.
- A-PROGRESS:25 Use `+a : Parsed<T> <- ...` plus pv/pr accessors (reference style, bend2/surface/parser.bend).
- A-PROGRESS:25-26 No mutually recursive types. Use one recursive `Node` and helper types that take a type parameter (`Seg<T>`, `Stmt<N>`, `Arm<N>`).
- A-PROGRESS:29 `File` clashed with Base; renamed `A.SrcFile`. Name clashes with Base are possible.
- A-PROGRESS:40-41 Nested constructor patterns work. `case other:` works.
- A-PROGRESS:41 `Bool.pick` is EAGER: both branches are evaluated.
- A-PROGRESS:44-45 Eager `Bool.pick` ran lex + parse + print on every call (~3 min/run). Fix: pick a Mode constructor, then `run_mode(mode_of(mode), src)` with a `match` (~1 min/run).
- A-PROGRESS:19 Parser shape: one `@unsafe parse(mode, tokens) -> Result<&2, &2, String, Value>` as bend2/surface/parser.bend:197-510.
- A-PROGRESS:17 No string-literal patterns in the parser design: classify an Ident once with `String.eq`; keyword and punct tables via String.eq (A-PROGRESS:27).
Termination check rule:
- A-PROGRESS:40-41 The check reads args left to right ("each passed unchanged until one shrinks"). So list walkers take the LIST FIRST: `last_from(xs, x)`.
`@unsafe def` + `law` pattern:
- A-PROGRESS:28 `--check-only` output listed "(unsafe: parse, file)"; A-PROGRESS:36 "(unsafe: pp, file)". One big `@unsafe def` holds the worker (`pp`, `parse`). `law` not mentioned in lines 1-78 (GUESS: not used in unit A).
`+x` and `&2` annotations:
- A-PROGRESS:19 `&2` is in the types `List<&2, String>`, `Result<&2, &2, String, Value>`. `+x` is a strict-argument marker on defs and on case binders (print.bend:59 `def min(+a: Nat, +b: Nat)`, print.bend:632 `case JArgs{+head, ...}`). Meaning is GUESS (forces the value before the call).
String and list helpers used:
- String.eq, `++` (String concat), `<>` (cons: `text <> docs`, A-PROGRESS:19 via parser.bend:1073), List.reverse(&2, String, docs) (parser.bend:1079), Nat.add (print.bend:71), Bool.pick(T, c, a, b).
- print.bend: slen, flen, sp(n), join, lines, capped, fit (print.bend:15-96) are local helpers.
Commands and timings:
- Check: `~/.bend/bin/bend <file> --check-only` (A-PROGRESS:7). Bend there is 2.0.25 (repo pin 2.0.27) (A-PROGRESS:4).
- Run: `~/.bend/bin/bend bend2/tests/rust_frontend.bend lex "$(cat f.rs)"` (A-PROGRESS:8). ~30 s/run for lex (A-PROGRESS:22).
- JS build: `bend <driver> -o <file>.js` ~1 min, then `node` ~1 s per run (FRONTEND.md:77). Native build 8 to 20 min with 2.0.25 (FRONTEND.md:77).
Traps that cost time:
- Eager Bool.pick (3 min/run). Dropped `"$(cat f)"` trailing newlines: compare is off by one newline; use a sentinel `x` (A-PROGRESS:49-50, gate:47-51).
- Native build of the driver stalled 6+ min (A-PROGRESS:75-76).
- Bend runs carry `# [skip-disk]` when disk is under the floor (A-PROGRESS:23).
- A hook denies writing fixtures with `loop`, `while`, `for` (A-PROGRESS:70). A hook blocks `let x = e?; Ok(..x..)` tails in written Rust (A-PROGRESS:51-52).
- Opus wf-builder agents died on [reasoning_extraction] twice (A-PROGRESS:3,16); hand build instead.
- rustfmt rule: one multi-line enum variant next to a one-line variant makes every struct variant vertical (A-PROGRESS:42-43).

## S9 TEST DRIVERS AND BUILD (rest)
Driver bend2/tests/rust_frontend.bend (dispatch shape, lines 70-108):
- :70 `type Md is Data:` MLex{} | MParse{} | MPrint{} | MCheck{} | MNone{}
- :77 `def mode_of(+mode: String) -> Md:` nested `Bool.pick(Md, String.eq(mode, "lex"), MLex{}, Bool.pick(...))` ending in MNone{}
- :82 `def run_mode(m: Md, src: String) -> String:` match m: MLex -> lex_report(Lexer.lex(src)); MParse -> parse_report(Parser.file(src)); MPrint -> print_report(Parser.file(src)); MCheck -> check_report(Lexer.lex(src)); MNone -> "unknown mode\n"
- :95 `def dispatch(+mode: String, +src: String) -> String:` = run_mode(mode_of(mode), src)
- :98 `def run_args(args: List<String>) -> String:` match args: `case Con{mode, Con{src, rest}}:` dispatch(mode, src); `case other:` usage text "usage: rust_frontend.bend <lex|parse|print|check> <source text>\n"
- :105 `def main() -> IO(Unit):` `do IO<Unit>:` `args : List<String> <- IO.args()` then `IO.write(run_args(args))`
- Files are NOT read by the driver: the source text comes in as the 2nd argv (`"$(cat file.rs)"`). IO.write prints the report string.
Gate dev/rust-parse-gate.sh (zsh, `set -u`):
- Env vars: BEND (default $HOME/.bend/bin/bend), NODE (default node), TMPDIR (mktemp dir) (:10-11,19).
- Build: one `$BEND $DRIVER -o $BIN` with BIN=$WORK/rust_frontend.js (:21,79). Build failure prints `FAIL build: ...` and finishes.
- Per fixture: `node $BIN check "<src>"` with a sentinel `x` to keep newlines (:49-53); accepted: rustfmt --check --edition 2021, then `cmp` of output with file (:55-61); refused: expects `REFUSED <loc> <what>` from EXPECTED.tsv (:63-71).
- Line formats: `PASS <parse|refuse>/<name>` (:27); `FAIL <name>: <reason>` (:32); summary `pass=N fail=M` (:37).
- Final token: `RUST-PARSE-OK` exit 0, or `RUST-PARSE-FAIL` exit 1 (:39-43).
- Floors: accepted >= 14, refused >= 20, EXPECTED rows == refused files, names unique (:16-17,99-102).
Manifest registration:
- `rg -n -C 3 'rust_frontend' dev/bend2/test-manifest.json` printed nothing: the driver is NOT registered in dev/bend2/test-manifest.json. Registered entries look like `"mode": "surface-trust", "source": "bend2/tests/surface_trust.bend"` (test-manifest.json:120-121).

## OPEN POINTS CLOSED
(a) `mu` declaration (bend2/kernel/check.bend, bend2/surface/elab.bend):
- check.bend:247 declare_family adds ONE Global entry: `Global.add_family(name, Positivity.Family{name, params, indices, level, Positivity.Provisional{}, [], False{}}, globals)`.
- check.bend:335 define_ctors_comp replaces that family entry with `completed(family, ctors)`; ctors live INSIDE the Family record (check.bend:323-326). No separate Global entry per constructor in these two defs.
- elab.bend:548-551 `case Syntax.DMu{group}` returns `Program{globals, definitions, families, rows}` with `rows` UNCHANGED: no Row for the family or its ctors. (elab_mu_group_comp itself not read: GUESS it calls the check.bend defs.) Contrast elab.bend:520-521 append_one, which adds a Row for other decls.
- Ctor.args does NOT include family params: check.bend:296 `Positivity.Ctor{name, args, res_idx, Nat.add(np, depth), Positivity.self_rec(args, group)}`; args = the ctor's own fields; params are in `family.params`; `res_params` must equal the params as Vars (check.bend:291), and the 4th field (arity) is np + depth.
(b) eval.bend:
- No def named apply/app in eval.bend (rg). Function-value application goes through `@unsafe def out_value(globals, shape, addr, value)` (eval.bend ~221, SPi case calls `out_point`) and `@unsafe def out_point(value: Value.T, globals: Global.T, shape: Shape.T<Value.T>, addr: Value.VAddr<Value.T>) -> Result<&2, &2, Error.T, Value.T>` (eval.bend:211). Closure entry: `@unsafe def open_closure(globals: Global.T, closure: Value.Closure<Value.T>, args: List<&2, Value.T>) -> Result<&2, &2, Error.T, Value.T>` (eval.bend:109; args reversed then appended to env).
- quote: `@unsafe def quote(globals, size, value):` (eval.bend:567); `law quote: for +globals: Global.T, for +size: Nat, for value: Value.T -> Result<&2, &2, Error.T, Term.T>` (eval.bend:407). Order: globals, size, value.
- whnf (eval.bend:386-390; law at 33): head only. `VNeutral{HGlobal{name}, spine}` goes to whnf_global; any other value returns `Done{value}`. Constructor arguments are not forced by whnf.
(c) pp.bend (`@unsafe def term(names, tm)`, pp.bend:136):
- Constructor application: no special case; a constructor intro `Term.In{s, a, args}` prints `(In <shape> <addr> [a1; a2])` (pp.bend:145-146).
- Nat literal: `Term.Lit{value}` calls `literal` (pp.bend:32-37): LInt prints `Bignum.to_string(value)`, plain decimal, no suffix; LString prints quoted and escaped.

## S8 IO AND CLI (rest)
bend2/io.bend signatures (defs seen at lines 5-201):
- :5 `def error_text(error: U32 & String, path: String) -> String:` :9 `def convert(-A: Data, result: Result<&1, &1, U32 & String, A>, path: String) -> Result<&2, &2, String, A>:`
- :16 `def fs(operation: U32, +path: String, other: String) -> IO(Result<&2, &2, String, String>):` :21 `def unit_result(result: Result<&2, &2, String, String>) -> Result<&2, &2, String, Unit>:` :28 `def fs_unit(operation: U32, path: String, other: String) -> IO(Result<&2, &2, String, Unit>):`
- :33 `def read_file(path: String) -> IO(Result<&2, &2, String, String>):` :36 `def write_file(path: String, contents: String) -> IO(Result<&2, &2, String, Unit>):` :39 `def remove(path: String) -> IO(Result<&2, &2, String, Unit>):` :42 `def remove_dir(path: String) -> ...Unit>):`
- :45 `def exists_result(result: Result<&2, &2, String, String>) -> Bool:` :52 `def exists(path: String) -> IO(Bool):` :57 `def temp_file(prefix: String, suffix: String) -> IO(Result<&2, &2, String, String>):`
- :60 `def write_bytes(+path: String, bytes: List<&2, U32>) -> IO(Result<&2, &2, String, Unit>):`
- :65 strip_slashes, :72 target_name, :83 `def normalize_target(+directory: String) -> String:`, :86 remove_if_exists, :98 cleanup_more, :105 cleanup_files, :116 cleanup_error, :123 finish_publish, :137 write_more, :144 write_files, :153 rename_error, :157 rename_result, :164 publish_rename, :173 publish_written, :182 publish_staged, :192 publish_exists
- :201 `def publish(+directory: String, files: List<&2, Common.Pair<String, String>>) -> IO(Result<&2, &2, String, Unit>):`
Bodies:
- publish (:201-205): normalize_target, `exists(target)`, then publish_exists. exists = `fs(5, path, "")` (:54). So publish checks for an existing path first.
- publish_exists (:192-199): present True gives `Fail{"output already exists: " ++ original}`: it REFUSES an existing directory. Present False runs `fs(1, target, "")` (op code 1; GUESS it is mkdir), then publish_staged: so it creates the directory. Files are written into a temp path (write_files, publish_written) and renamed (publish_rename); bodies not read.
- write_bytes (:60-63): `Host.mechanism_write_bytes(path, bytes)` then convert; no directory creation.
- `die`: NOT FOUND. No `def die(` in io.bend or anywhere under bend2 (rg).

## S7 EXISTING ERASURE + PRIM CATALOG
bend2/kernel/prim.bend (all prims are Nat prims; arity 2 each, prim.bend:34-35):
- prim.bend:11 `type T is Data:` Nat_add{} Nat_sub{} Nat_mul{} Nat_eq{} Nat_lt{}; catalog list :31-32.
- Surface names (prim.bend:18-29): natAdd, natSub, natMul, natEq, natLt. `def of_name(n: String) -> Maybe<&2, T>:` (:44).
- Types (:72-73): `Nat -> Nat -> R` with `QMany` pi binders "a", "b"; Nat = `Term.Global{"Nat"}` (:47-48). R = Nat for add, sub, mul; R = bool_ty for eq, lt (:59-70). bool_ty = `SColl 2` with two unit legs (:53-54).
- Semantics (`def apply(p: T, args: List<&2, Literal.T>) -> Maybe<&2, Value.T>:` :91): only two non-negative `LInt` args, else None (:93-96). add/sub/mul via Bignum (:80-85); eq via Bignum.equal; lt = `Bool.not(Bignum.le(b, a))` (:89). Bool value is `VIn{SColl 2, VALeg{0|1}, [..]}` (:75-76).
bend2/kernel/erase.bend (lines 1-70 only):
- Entry point signature NOT in lines 1-70 (not read; GUESS it is further down). Imports erase_repr.bend (R), erase_util.bend (U), eterm.bend (E).
- Types: `Entry`: Dropped{} | Postulate{repr: E.Repr} | Code{decls: List<&2, E.Kdecl>} (:21-24); `Slot`: SDrop{} | SKeep{} | SExtra{} (:26-29); `Found`: LKeep{index} | LDrop{} | LOut{} (:31-34).
- Drop rule seen: `quantity_runtime(q)`: QZero is False (erased), QOne and QMany are True (kept) (:52-56). `lookup(slots, ix, seen)` renumbers kept variable indexes, `LDrop{}` for a dropped slot (:39-50).

END-OF-CRIB (new sections go above this line)
