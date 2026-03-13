---
name: reviewing-rust-code
description: Reviews Rust code
user-invocable: false
---

## Process

Consult the rule index below.
For rules that seem applicable,
read the full rule file at `rules/<id>.md` (e.g., `rules/L001.md`).

## Rule Index

### Logic Errors

- **L001** `off-by-one-boundary` — Range bounds that include/exclude one too many or too few elements.
  Look for: `..`, `..=`, `< len`, `<= len` in loops and slices.

- **L002** `inverted-condition` — Boolean condition that is the opposite of what surrounding logic expects.
  Look for: `if ! ...`, guard clauses, early returns.

- **L030** `unbounded-recursion` — Recursive function without a depth limit processing external input, risking stack overflow.
  Look for: recursive `fn` without a depth/fuel parameter, especially on parsed or deserialized data.

- **L031** `loop-without-exit-bound` — `loop` or `while` without a clear upper bound on iterations.
  Look for: `loop { ... }`, `while` with external-state-dependent condition, retry loops without max attempts.

- **L033** `missing-invariant-assertion` — Function relies on invariants the type system cannot express but does not assert them.
  Look for: doc comments mentioning "sorted", "non-empty", "normalized" without corresponding `debug_assert!`.

### Error Handling

- **E003** `swallowed-error` — Error value silently discarded via `let _ =`, `.ok()`, or `_ =>`.
  Look for: `let _ =`, `.ok()`, `if let Ok` without else.

- **E004** `lost-error-context` — Error mapped/wrapped without preserving the original cause.
  Look for: `map_err(|_|`, `anyhow!("failed")` with no context.

- **E005** `unwrap-on-user-input` — `unwrap()`/`expect()` on data derived from external input.
  Look for: `.unwrap()`, `.expect()` in non-test code.

- **E006** `fallible-in-infallible` — Function returns `Result`/`Option` but all paths succeed, or vice versa.
  Look for: `-> Result` where `Err` is never constructed.

- **E043** `manual-result-forwarding` — Manual `match` on `Result` to propagate errors where `?` would suffice.
  Look for: nested `match` on `Result`/`Option` forming a "staircase" pattern.

### API / Semantic Misuse

- **A007** `path-join-absolute` — `Path::join` called with an absolute path argument, silently replacing the base.
  Look for: `.join("/...`)`, `.join(variable)` where variable may be absolute.

- **A008** `silent-saturation` — Numeric cast via `as` that silently saturates or truncates.
  Look for: `as u8`, `as i32`, `as usize` on values of larger types.

- **A009** `format-string-mismatch` — Format string placeholders that don't match the intended arguments.
  Look for: `format!`, `println!`, `log::` macros with complex arguments.

### Documentation

- **D010** `doc-contradicts-code` — Doc comment promises behavior the code doesn't deliver.
  Look for: `///` or `//!` near functions with different behavior.

- **D011** `stale-safety-comment` — `// SAFETY:` comment lists invariants that don't match the actual `unsafe` code.
  Look for: `// SAFETY:` above `unsafe` blocks.

- **D012** `stale-todo-or-fixme` — TODO/FIXME comment that refers to work already done or no longer relevant.
  Look for: `TODO`, `FIXME`, `HACK`, `XXX`.

- **D036** `suppressed-warning` — `#[allow(...)]` that hides a real issue instead of fixing it.
  Look for: `#[allow(dead_code)]`, `#[allow(unused_*)]`, `#[allow(clippy::...)]` without justification.

- **D044** `comment-restates-code` — Comment inside a function body that restates what the code already says.
  Look for: per-line comments that translate code to English, per-arm comments in `match`.

- **D045** `missing-pub-doc-comment` — Public item without a `///` doc comment.
  Look for: `pub fn`, `pub struct`, `pub enum`, `pub trait` without `///`.

### Incomplete Logic

- **I013** `catch-all-hides-variant` — Wildcard match arm silently handles enum variants that deserve explicit handling.
  Look for: `_ =>` in match on enums that may grow.

- **I014** `silent-none-drop` — `if let Some(x)` or `while let` silently ignores `None` case where action is needed.
  Look for: `if let Some`, `while let Some`.

- **I015** `missing-status-code` — Handling of HTTP/gRPC/exit codes that covers success + one error but misses others.
  Look for: status code matching with incomplete coverage.

### Naming and Clarity

- **N016** `misleading-name` — Name implies behavior different from what the code does (e.g., `is_valid` mutates state).
  Look for: functions with `is_`, `get_`, `check_` prefixes; booleans.

- **N017** `boolean-param-ambiguity` — Public function with bare `bool` parameter whose meaning is unclear at call sites.
  Look for: `fn foo(..., bool)` in public APIs.

- **N032** `excessive-function-length` — Function too long to review as a single unit.
  Look for: functions exceeding ~60 lines of executable code, multiple separable responsibilities.

- **N034** `complex-macro` — Macro complex enough to hinder readability, tooling, and error messages.
  Look for: nested macro definitions, macros affecting control flow, macros replacing generic functions.

- **N038** `name-scope-mismatch` — Public name too short/cryptic, or local name too verbose for its scope.
  Look for: single-letter public function parameters, verbose loop variables in short scopes.

- **N039** `non-inclusive-terminology` — Code uses terminology superseded by inclusive alternatives.
  Look for: `master`/`slave`, `whitelist`/`blacklist` in identifiers or doc comments.

- **N040** `multiple-responsibilities` — Function performs multiple conceptually distinct operations.
  Look for: function names containing "and", clearly separable phases within one function.

- **N041** `too-many-locals` — Function has too many local variable bindings to follow easily.
  Look for: functions with more than 10 `let` bindings.

### Performance (high bar)

- **P018** `clone-in-hot-loop` — `.clone()` or `.to_string()` called inside a loop when borrowing would suffice.
  Look for: `.clone()`, `.to_owned()`, `.to_string()` in loops.

- **P019** `quadratic-collection-ops` — Nested iteration or repeated `.contains()`/`.remove()` on Vec/slice that should use a Set/Map.
  Look for: nested `for`/`iter` with `.contains()`, `.position()`.

- **P020** `unbounded-growth` — Collection grows without bound (no capacity hint, no eviction, no size limit).
  Look for: `.push()`, `.insert()` in loops without capacity management.

- **P042** `excessive-inline` — `#[inline]` or `#[inline(always)]` on functions too large to benefit from inlining.
  Look for: `#[inline(always)]` on functions longer than 3–5 lines without benchmark justification.

### Concurrency (high bar)

- **C021** `deadlock-ordering` — Multiple locks acquired in inconsistent order across code paths.
  Look for: multiple `.lock()` / `.read()` / `.write()` calls.

- **C022** `blocking-in-async` — Blocking I/O or long computation inside an async context without `spawn_blocking`.
  Look for: `std::fs::`, `std::net::`, `.lock()` inside `async fn` or `.await` blocks.

### API Design

- **A023** `deref-polymorphism` — Using `Deref`/`DerefMut` to emulate struct inheritance instead of composition.
  Look for: `impl Deref for` on non-smart-pointer types.

- **A024** `panic-in-library` — Library code that panics instead of returning `Result`, forcing callers to handle panics.
  Look for: `panic!`, `unreachable!`, `unwrap()`, `expect()` in `pub fn` of library crates.

- **A025** `missing-common-traits` — Public types that omit commonly expected trait implementations (Debug, Clone, PartialEq).
  Look for: `pub struct` / `pub enum` without `#[derive(Debug, ...)]`.

- **A028** `validate-then-forget` — Code validates a property then continues with the raw type, discarding the proof.
  Look for: `is_valid()` returning bool, validation followed by raw type usage.

- **A029** `broad-from-for-newtype` — `From<primitive>` implemented for a domain-specific newtype, enabling silent type confusion via `.into()`.
  Look for: `impl From<u32>`, `impl From<String>` for ID/handle/token types.

- **A030** `library-initializes-subscriber` — Library crate initializes a global logger or tracing subscriber.
  Look for: `env_logger::init()`, `tracing_subscriber::fmt::init()`, `log::set_logger()` in library code.

- **A037** `missing-must-use` — Public function or type where ignoring the return value is likely a bug, but `#[must_use]` is absent.
  Look for: builder types/methods returning `Self`, pure functions, functions returning guards or status booleans.

- **A046** `type-alias-over-newtype` — `type` alias used where a newtype would provide compile-time safety.
  Look for: `type Alias = Primitive` where another alias over the same primitive represents a different concept.

- **A047** `undocumented-shared-ownership` — `Arc` or `Rc` used without a comment explaining why shared ownership is necessary.
  Look for: `Arc::new(...)`, `Rc::new(...)` without nearby justification comment.

- **A048** `reimplemented-std-facility` — Code reimplements functionality already in the standard library or a well-known dependency.
  Look for: hand-rolled min/max, custom collection types, manual string parsing.

- **A049** `prefer-cfg-macro` — `#[cfg(...)]` used where `cfg!()` in an `if` would allow both branches to be type-checked.
  Look for: duplicate function definitions guarded by `#[cfg(X)]` and `#[cfg(not(X))]`.

### Numeric Safety

- **N026** `integer-overflow-in-release` — Arithmetic on user-influenced integers that silently wraps in release mode.
  Look for: `+`, `-`, `*` on integers derived from external input without `checked_` or `saturating_` methods.

### Security (high bar)

- **S027** `unsanitized-path-input` — User-provided string used in file path construction without canonicalization/validation.
  Look for: `Path::new(user_input)`, `.join(user_input)`.

- **S035** `unnecessary-unsafe` — `unsafe` block where a safe alternative exists, or `unsafe` that is broader than needed.
  Look for: `unsafe { ... }` with safe equivalents, oversized `unsafe` blocks, `get_unchecked` without profiling justification.

### Observability

- **O031** `log-level-mismatch` — Log event uses a level that does not match the severity of the situation.
  Look for: `error!` for transient failures, `warn!` for routine events, `info!` for per-request detail.

- **O032** `println-for-diagnostics` — `println!`/`eprintln!` used for diagnostic output where a logging facade would be appropriate.
  Look for: `println!`, `eprintln!`, `dbg!()` in non-CLI library or server code.

## Out of Scope

Claude should not comment on the following during Rust code review:

- **Formatting** — handled by `rustfmt`.
- **Import ordering** — handled by tooling.
- **Test code** — relax rules E005, A024, A025 in `#[cfg(test)]` modules and `#[test]` functions.
