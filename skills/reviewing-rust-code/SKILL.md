---
name: reviewing-rust-code
description: Reviews Rust code
user-invocable: false
---

## Process

When a file is changed,
read the entire module to understand invariants that may depend on the changed code.

Consult the rule index below.
For rules that seem applicable,
read the full rule file at `reference/<id>.md` (e.g., `reference/RS000.md`).

## Rule Index

### Logic Errors

- **[RS000](reference/RS000.md)** `missing-invariant-assertion` — Function relies on invariants the type system cannot express but does not assert them.
  Look for: doc comments mentioning "sorted", "non-empty", "normalized" without corresponding `debug_assert!`.

### Error Handling

- **[RS001](reference/RS001.md)** `lost-error-context` — Error mapped/wrapped without preserving the original cause.
  Look for: `map_err(|_|`, `anyhow!("failed")` with no context.

### API / Semantic Misuse

- **[RS002](reference/RS002.md)** `silent-saturation` — Numeric cast via `as` that silently saturates or truncates.
  Look for: `as u8`, `as i32`, `as usize` on values of larger types.

### Documentation

- **[RS003](reference/RS003.md)** `suppressed-warning` — `#[allow(...)]` that hides a real issue instead of fixing it.
  Look for: `#[allow(dead_code)]`, `#[allow(unused_*)]`, `#[allow(clippy::...)]` without justification.

- **[RS004](reference/RS004.md)** `comment-restates-code` — Comment inside a function body that restates what the code already says.
  Look for: per-line comments that translate code to English, per-arm comments in `match`.

### Naming and Clarity

- **[RS005](reference/RS005.md)** `boolean-param-ambiguity` — Public function with bare `bool` parameter whose meaning is unclear at call sites.
  Look for: `fn foo(..., bool)` in public APIs.

- **[RS006](reference/RS006.md)** `name-scope-mismatch` — Public name too short/cryptic, or local name too verbose for its scope.
  Look for: single-letter public function parameters, verbose loop variables in short scopes.

### API Design

- **[RS007](reference/RS007.md)** `missing-common-traits` — Public types that omit commonly expected trait implementations (Debug, Clone, PartialEq).
  Look for: `pub struct` / `pub enum` without `#[derive(Debug, ...)]`.

- **[RS008](reference/RS008.md)** `validate-then-forget` — Code validates a property then continues with the raw type, discarding the proof.
  Look for: `is_valid()` returning bool, validation followed by raw type usage.

- **[RS009](reference/RS009.md)** `broad-from-for-newtype` — `From<primitive>` implemented for a domain-specific newtype, enabling silent type confusion via `.into()`.
  Look for: `impl From<u32>`, `impl From<String>` for ID/handle/token types.

### Observability

- **[RS010](reference/RS010.md)** `log-level-mismatch` — Log event uses a level that does not match the severity of the situation.
  Look for: `error!` for transient failures, `warn!` for routine events, `info!` for per-request detail.

- **[RS011](reference/RS011.md)** `println-for-diagnostics` — `println!`/`eprintln!` used for diagnostic output where a logging facade would be appropriate.
  Look for: `println!`, `eprintln!`, `dbg!()` in non-CLI library or server code.

## Out of Scope

Claude should not comment on the following during Rust code review:

- **Formatting** — handled by `rustfmt`.
- **Import ordering** — handled by tooling.
