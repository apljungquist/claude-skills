# Rule: misleading-name

**Severity:** warning

## Problem

A function, variable, or type name implies behavior or semantics that don't match the implementation, leading callers to misuse it.

## Example

### Bad
```rust
/// Checks if the user is authorized.
fn is_authorized(user: &User, db: &mut Db) -> bool {
    db.record_access(user.id);  // Side effect! "is_" prefix implies pure query
    user.role == Role::Admin
}

let remaining_items = items.len() + offset;  // Name says "remaining" but calculates total
```

### Good
```rust
fn check_and_record_access(user: &User, db: &mut Db) -> bool {
    db.record_access(user.id);
    user.role == Role::Admin
}

let total_items = items.len() + offset;
```

## When to flag

- `is_`, `has_`, `can_` prefix on a function that mutates state or has side effects.
- `get_` prefix on a function that creates, allocates, or has non-trivial cost.
- Variable name that describes the opposite of what it holds (e.g., `max` holding a minimum).
- Boolean variable whose name suggests the opposite polarity (e.g., `is_enabled` that is `true` when disabled).
- Function name suggests it returns a value but it returns `()` (or vice versa).
- `validate` or `is_valid` function that returns `bool` or `Result<()>` — the name suggests a check, but the result discards the proof. Consider whether it should be a `parse`/`try_from` that returns a validated type instead (see A28 `validate-then-forget`).
- Parameter or variable named after its type rather than its role — e.g., `value: &Years` instead of `age: &Years`, or `n: u32` instead of `retries: u32`. The name should convey what the value *means*, not what it *is*. Inspired by [Swift API Design Guidelines](https://www.swift.org/documentation/api-design-guidelines).
- Variable holding a quantity with ambiguous units when the type doesn't encode them — e.g., `timeout: u64` where it's unclear whether the unit is seconds, milliseconds, or microseconds. Either use a unit-carrying type (`Duration`) or encode the unit in the name (`timeout_ms`). See also A28 `validate-then-forget` for the newtype alternative.

## When NOT to flag

- Names that are merely vague or could be more descriptive — only flag when the name is actively misleading.
- Domain-specific jargon that is correct within the project's context.
- Conventional names like `new()` that may allocate (this is expected in Rust).
