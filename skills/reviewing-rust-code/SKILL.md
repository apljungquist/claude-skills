---
name: reviewing-rust-code
description: Reviews Rust code
user-invocable: false
---

## Process

Consult the rule index below.
For rules that seem applicable, read the full rule file in `rules/<code>.md` (e.g., `rules/L01.md` for rule L01).

## Rule Index

### Logic Errors

- **L01** `off-by-one-boundary` — Range bounds that include/exclude one too many or too few elements.
  Look for: `..`, `..=`, `< len`, `<= len` in loops and slices.

- **L02** `inverted-condition` — Boolean condition that is the opposite of what surrounding logic expects.
  Look for: `if ! ...`, guard clauses, early returns.

- **L30** `unbounded-recursion` — Recursive function without a depth limit processing external input, risking stack overflow.
  Look for: recursive `fn` without a depth/fuel parameter, especially on parsed or deserialized data.

- **L31** `loop-without-exit-bound` — `loop` or `while` without a clear upper bound on iterations.
  Look for: `loop { ... }`, `while` with external-state-dependent condition, retry loops without max attempts.

- **L33** `missing-invariant-assertion` — Function relies on invariants the type system cannot express but does not assert them.
  Look for: doc comments mentioning "sorted", "non-empty", "normalized" without corresponding `debug_assert!`.

### Error Handling

- **E03** `swallowed-error` — Error value silently discarded via `let _ =`, `.ok()`, or `_ =>`.
  Look for: `let _ =`, `.ok()`, `if let Ok` without else.

- **E04** `lost-error-context` — Error mapped/wrapped without preserving the original cause.
  Look for: `map_err(|_|`, `anyhow!("failed")` with no context.

- **E05** `unwrap-on-user-input` — `unwrap()`/`expect()` on data derived from external input.
  Look for: `.unwrap()`, `.expect()` in non-test code.

- **E06** `fallible-in-infallible` — Function returns `Result`/`Option` but all paths succeed, or vice versa.
  Look for: `-> Result` where `Err` is never constructed.

### API / Semantic Misuse

- **A07** `path-join-absolute` — `Path::join` called with an absolute path argument, silently replacing the base.
  Look for: `.join("/`, `.join(variable)` where variable may be absolute.

- **A08** `silent-saturation` — Numeric cast via `as` that silently saturates or truncates.
  Look for: `as u8`, `as i32`, `as usize` on values of larger types.

- **A09** `format-string-mismatch` — Format string placeholders that don't match the intended arguments.
  Look for: `format!`, `println!`, `log::` macros with complex arguments.

### Documentation

- **D10** `doc-contradicts-code` — Doc comment promises behavior the code doesn't deliver.
  Look for: `///` or `//!` near functions with different behavior.

- **D11** `stale-safety-comment` — `// SAFETY:` comment lists invariants that don't match the actual `unsafe` code.
  Look for: `// SAFETY:` above `unsafe` blocks.

- **D12** `stale-todo-or-fixme` — TODO/FIXME comment that refers to work already done or no longer relevant.
  Look for: `TODO`, `FIXME`, `HACK`, `XXX`.

- **D36** `suppressed-warning` — `#[allow(...)]` that hides a real issue instead of fixing it.
  Look for: `#[allow(dead_code)]`, `#[allow(unused_*)]`, `#[allow(clippy::...)]` without justification.

### Incomplete Logic

- **I13** `catch-all-hides-variant` — Wildcard match arm silently handles enum variants that deserve explicit handling.
  Look for: `_ =>` in match on enums that may grow.

- **I14** `silent-none-drop` — `if let Some(x)` or `while let` silently ignores `None` case where action is needed.
  Look for: `if let Some`, `while let Some`.

- **I15** `missing-status-code` — Handling of HTTP/gRPC/exit codes that covers success + one error but misses others.
  Look for: status code matching with incomplete coverage.

### Naming and Clarity

- **N16** `misleading-name` — Name implies behavior different from what the code does (e.g., `is_valid` mutates state).
  Look for: functions with `is_`, `get_`, `check_` prefixes; booleans.

- **N17** `boolean-param-ambiguity` — Public function with bare `bool` parameter whose meaning is unclear at call sites.
  Look for: `fn foo(..., bool)` in public APIs.

- **N32** `excessive-function-length` — Function too long to review as a single unit.
  Look for: functions exceeding ~60 lines of executable code, multiple separable responsibilities.

- **N34** `complex-macro` — Macro complex enough to hinder readability, tooling, and error messages.
  Look for: nested macro definitions, macros generating `impl` blocks, macros replacing generic functions.

### Performance (high bar)

- **P18** `clone-in-hot-loop` — `.clone()` or `.to_string()` called inside a loop when borrowing would suffice.
  Look for: `.clone()`, `.to_owned()`, `.to_string()` in loops.

- **P19** `quadratic-collection-ops` — Nested iteration or repeated `.contains()`/`.remove()` on Vec/slice that should use a Set/Map.
  Look for: nested `for`/`iter` with `.contains()`, `.position()`.

- **P20** `unbounded-growth` — Collection grows without bound (no capacity hint, no eviction, no size limit).
  Look for: `.push()`, `.insert()` in loops without capacity management.

### Concurrency (high bar)

- **C21** `deadlock-ordering` — Multiple locks acquired in inconsistent order across code paths.
  Look for: multiple `.lock()` / `.read()` / `.write()` calls.

- **C22** `blocking-in-async` — Blocking I/O or long computation inside an async context without `spawn_blocking`.
  Look for: `std::fs::`, `std::net::`, `.lock()` inside `async fn` or `.await` blocks.

### API Design

- **A23** `deref-polymorphism` — Using `Deref`/`DerefMut` to emulate struct inheritance instead of composition.
  Look for: `impl Deref for` on non-smart-pointer types.

- **A24** `panic-in-library` — Library code that panics instead of returning `Result`, forcing callers to handle panics.
  Look for: `panic!`, `unreachable!`, `unwrap()`, `expect()` in `pub fn` of library crates.

- **A25** `missing-common-traits` — Public types that omit commonly expected trait implementations (Debug, Clone, PartialEq).
  Look for: `pub struct` / `pub enum` without `#[derive(Debug, ...)]`.

- **A28** `validate-then-forget` — Code validates a property then continues with the raw type, discarding the proof.
  Look for: `is_valid()` returning bool, validation at top of function followed by raw type usage, stringly-typed APIs.

- **A29** `broad-from-for-newtype` — `From<primitive>` implemented for a domain-specific newtype, enabling silent type confusion via `.into()`.
  Look for: `impl From<u32>`, `impl From<String>` for ID/handle/token types.

- **A37** `missing-must-use` — Public function or type where ignoring the return value is likely a bug, but `#[must_use]` is absent.
  Look for: builder types/methods returning `Self`, pure functions, functions returning guards or status booleans.

### Numeric Safety

- **N26** `integer-overflow-in-release` — Arithmetic on user-influenced integers that silently wraps in release mode.
  Look for: `+`, `-`, `*` on integers derived from external input without `checked_` or `saturating_` methods.

### Security (high bar)

- **S27** `unsanitized-path-input` — User-provided string used in file path construction without canonicalization/validation.
  Look for: `Path::new(user_input)`, `.join(user_input)`.

- **S35** `unnecessary-unsafe` — `unsafe` block where a safe alternative exists, or `unsafe` that is broader than needed.
  Look for: `unsafe { ... }` with safe equivalents, oversized `unsafe` blocks, `get_unchecked` without profiling justification.

## Out of Scope

Claude should not comment on the following during Rust code review:

- **Test code** — relax rules E05, A24, A25 in `#[cfg(test)]` modules and `#[test]` functions.
