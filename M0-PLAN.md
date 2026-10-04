# mech-rust M0 plan (for a fresh session)

Source of truth for scope: `/Users/oobi/Documents/mech-rust-transpiler-design-brief.md` (all section 12 defaults ACCEPTED 2026-10-02;  Q11 open, needed only at M2).  Memory topic: `project-mech-rust-transpiler.md`.

Session claude7 launched units A and B as two parallel opus wf-builder agents on 2026-10-02.  Both died on the `[reasoning_extraction]` safeguard before any file change (A req_011CfeWGpNNdij2Bh46Cdf9K, B req_011CfeWGrAHHUoLE39vRNkVi).  Per the builder rule there was no sonnet fallback.  Run the units by hand in the main loop, or relaunch opus wf-builders if the classifier has quieted.  Do A first:  B's M1 successor reuses A's AST and printer.

## Shared setup and rules

- Worktree `/Users/oobi/Documents/mechanism-lang-rust-m0`, branch `mech-rust/m0` at ba35171.  Never touch `/Users/oobi/Documents/mechanism-lang` (other sessions' staged work).
- W = `/Users/oobi/Documents/mech-rust-m0` for logs and `COMMIT-MSG-A.txt` / `COMMIT-MSG-B.txt`.
- NEVER commit or push.  Stage own paths with `git -C <worktree> add`.  Commit messages carry no Co-Authored-By line.
- Learn first:  the pinned Bend binary (Bend 2.0.27, `MIGRATION-BEND2.md:10`), how `bend2/tests/*.bend` drivers run, how the `mech` CLI is built and how a `.mech` program plus prelude is checked and run.  Read excerpts only.
- Do not run `dev/gates.sh` (hours).  Run only the focused drivers and gates below.  Stop if one Bend run exceeds 20 minutes.
- Keep the Data volume above 30 GiB free (32 GiB at launch).  Use `cargocho`, not `cargo`, with at most 2 jobs.
- No em-dashes.  `rg`/`sd`, never grep/sed.  No `cd X &&` or `VAR=` command prefix.

## Unit A: Rust frontend (RUST-PARSE)

Files:  `bend2/rust/{token,lexer,ast,parser,fragment,print}.bend`, `bend2/rust/FRONTEND.md`, `bend2/tests/rust_frontend.bend`, `test/rust/parse/*.rs`, `test/rust/refuse/*.rs` + `EXPECTED.tsv`, `dev/rust-parse-gate.sh`.  No `make`, no writes under `_bend2/`, `_build/`, `build/`.

- Lexer:  identifiers, raw identifiers, keywords, integer literals with suffixes, bool/char/string literals, lifetimes (lexed so they can be refused), punctuation, doc comments.  One-based positions as in `bend2/surface/lexer.bend`.
- AST and parser:  items `mod` (both forms), `use`, `struct` (tuple, named, unit), `enum` (tuple, struct, unit variants), `fn` with generics and simple bounds, `impl` and `impl Trait for T`, `trait` signatures, `const`, `type`, `pub`/`pub(crate)`, `#[derive(...)]`, doc comments.  Expressions:  paths, literals, calls, method calls, turbofish, closures (typed and untyped binders), blocks, `let` (with or without annotation), `match`, `if`/`else`, binary and unary ops, `?`, struct literals, tuples, field access, `Box::new`, `vec![...]`.  Patterns:  identifier, constructor, tuple, literal, `_`.  Types:  paths with generics, `&T`, tuples, `Box<T>`, `impl Fn(A) -> B`, `Self`.  Use the generic-binder trick of `bend2/surface/syntax.bend` if Bend 2 needs it.
- Fragment pass:  refuse with `line:col` and construct name:  loop/while/for, `&mut`, `mut` bindings, `unsafe`, `.unwrap()`, `.expect(`, `panic!`, `assert!`/`assert_eq!`, `as`, indexing, `.scan(`, `dyn Trait`, explicit lifetimes, `async`/`.await`, macros other than `vec!`, body comments (Q8:  item doc comments are kept).
- Printer:  rustfmt-stable output (default config, edition 2021).  Law:  for every accepted fixture `f`, already rustfmt-clean, `print(parse(f)) == f` byte for byte.
- Fixtures:  at least 14 accepted (each checked with `rustfmt --check --edition 2021`) and one refused fixture per refused construct.
- Gate `dev/rust-parse-gate.sh`:  one PASS/FAIL per fixture, then `RUST-PARSE-OK` or `RUST-PARSE-FAIL`.

## Unit B: mech -> Rust emitter (DIFF-EXEC)

Files:  `bend2/rust/{rir,erase_typed,emit}.bend`, `bend2/rust/EMIT.md`, the `bend2/cli/` wiring for `rust-out`, `bend2/tests/rust_emit*.bend`, `test/rust/emit/`, `dev/rust-out-diff-exec.sh`.  B owns builds under `_bend2/`, `_build/`, `build/`.

- Input:  `prelude/init.mech` + `prelude/mechanism/second-price.mech`, assembled as the repo runner does.  Start from checked kernel terms and `Global` entries (`Elab.check_in`, `elab_program_in`, `checked_form`), NOT from the untyped erased `Ktm`.
- Typed erasure to a small Rust IR:  quantity-0 type binders become generics;  Prop-typed declarations and binders leave Rust and go verbatim, in source order, to `mech-carrier.mech` (Q3);  indices and levels are dropped.  `MechBool` -> `bool` with `case` -> `if`/`else`.  A family -> `pub enum` (recursive fields boxed);  a single-constructor family -> a struct with private fields, a constructor fn and accessors.  `def rec` -> a recursive fn only if second-price needs it.
- Quantities (Q6):  1 -> by-value;  many -> `&T`, or by-value for Copy types.  Kernel `Nat`, if used -> an emitted `src/nat.rs` bignum module, no dependency (Q5).
- Refuse:  zk/fhc/mpc shapes, types that depend on runtime values, postulates in the runtime closure, `poly` universes (for now).
- Emitted Rust:  rustfmt-clean, `clippy -D warnings` clean, house conventions (no loops, unwrap, expect, panic, assert, `as`, indexing, `_` arms on enums, bool match, pub fields, mutation).  Text emission is fine at M0;  M1 routes through A's printer.
- CLI:  `mech rust-out <.mech files in order...> <out crate dir>`;  refuse an existing output dir.  Crate:  `Cargo.toml` (edition 2021, MIT OR Apache-2.0, no deps), `src/lib.rs`, one module per input file with injective name mangling, `mech-carrier.mech`.
- Gate `dev/rust-out-diff-exec.sh`:  build the emitted crate outside the tracked tree, compare values from a generated `src/bin/diff_exec.rs` (prints values, no asserts) with mechanism-lang's own runtime on every closed runtime def and on generated small inputs per runtime function.  One PASS/FAIL per value, then `DIFF-EXEC-OK` or `DIFF-EXEC-FAIL`.  Mutation control:  swap two match arms in a `$TMPDIR` copy and show RED.
