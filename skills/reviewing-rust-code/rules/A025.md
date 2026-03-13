# Rule: missing-common-traits

**Severity:** suggestion

## Problem

Public types omit commonly expected trait implementations (`Debug`, `Clone`, `PartialEq`), making them harder to use in tests, logging, collections, and general-purpose code. Users of the type cannot log it with `{:?}`, compare it in tests with `assert_eq!`, or store it in common collections — leading to workarounds or wrapper types.

## Example

### Bad
```rust
pub struct Config {
    pub timeout: Duration,
    pub retries: u32,
}
// No Debug — can't use {:?} in logs or error messages
// No Clone — can't duplicate for testing
// No PartialEq — can't assert_eq! in tests
```

### Good
```rust
#[derive(Debug, Clone, PartialEq)]
pub struct Config {
    pub timeout: Duration,
    pub retries: u32,
}
```

## When to flag

- `pub struct` or `pub enum` without `#[derive(Debug)]` — nearly all public types should be Debug.
- Public config/value types without `Clone` and `PartialEq`.
- Public error types without `Debug` and `Display`.
- `pub struct` used as a key or in collections without `Hash` and `Eq`.

## When NOT to flag

- Types containing fields that don't implement the trait (e.g., contains a `dyn Trait`, `File`, `Mutex`).
- Types where implementing the trait would be misleading (e.g., `PartialEq` on a type with intentional identity semantics).
- Internal types (not `pub` or `pub(crate)`).
- Types where `Clone` would be expensive and the author intentionally prevents it.
- Types that implement the trait manually instead of deriving.
