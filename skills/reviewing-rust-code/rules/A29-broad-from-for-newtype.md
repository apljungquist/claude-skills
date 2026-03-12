# Rule: broad-from-for-newtype

**Severity:** warning

## Problem

`From<T>` is implemented for a semantically specific newtype where `T` is a general-purpose type (e.g., `From<u128> for UserId`). This allows any value of the general type to silently convert into the domain type via `.into()`, bypassing validation and making type confusion invisible at call sites. A caller can pass a completely unrelated value — a directory ID, a timestamp, a byte count — and `.into()` will happily convert it to a `UserId` with no compiler warning.

## Example

### Bad
```rust
pub struct UserId(u128);

impl From<u128> for UserId {
    fn from(value: u128) -> Self {
        Self(value)
    }
}

// In calling code — the bug is invisible:
let directory_id: u128 = 123;
delete_user(directory_id.into());  // Deletes wrong thing! No compiler error.
```

### Good
```rust
pub struct UserId(u128);

impl UserId {
    /// Create a UserId from a raw database identifier.
    pub fn from_raw(id: u128) -> Self {
        Self(id)
    }
}

// In calling code — the intent is explicit:
let directory_id: u128 = 123;
delete_user(UserId::from_raw(directory_id));  // Explicit, reviewable
```

## When to flag

- `impl From<primitive> for DomainType` where the domain type represents a specific entity (IDs, keys, handles, tokens) and the primitive is a general-purpose type (`u32`, `u64`, `u128`, `String`, `&str`).
- `impl From<GeneralType> for SpecificType` where `SpecificType` adds semantic meaning or invariants beyond what `GeneralType` carries.
- The `From` impl performs no validation — any value of the source type is accepted, even though not all values are semantically valid.
- Multiple newtype wrappers over the same primitive all implement `From<primitive>`, making cross-conversion trivially easy (e.g., `UserId` and `OrderId` both implement `From<u64>`).

## When NOT to flag

- `From` impls between types where the conversion is genuinely lossless and semantically correct (e.g., `From<&str> for String`).
- `From` impls that perform validation and return via `TryFrom` instead — this is the right pattern.
- Newtype wrappers intended purely for type safety in a builder or configuration context where all values are valid (e.g., `struct Meters(f64)` where any `f64` is a valid measurement).
- Internal/private types where the `From` impl is only used in controlled contexts.
- The Rust API Guidelines [C-CONV-TRAITS](https://github.com/rust-lang/api-guidelines/blob/97a0969cb07fe4cabb0eed8a56234053f47d83dc/src/interoperability.md#conversions-use-the-standard-traits-from-asref-asmut-c-conv-traits) recommend implementing `From` "where it makes sense" — this rule articulates one common case where it does not.
