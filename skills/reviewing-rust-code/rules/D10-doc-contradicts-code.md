# Rule: doc-contradicts-code

**Severity:** warning

## Problem

A doc comment promises behavior that the code doesn't deliver. Stale or inaccurate documentation is worse than no documentation because it actively misleads callers. Callers rely on the documented contract and write code that works in testing but fails when the implementation does something different than promised.

## Example

### Bad
```rust
/// Returns the smallest element in the slice.
/// Returns `None` if the slice is empty.
fn find_min(data: &[i32]) -> Option<i32> {
    data.iter().max().copied()  // BUG: returns max, not min
}

/// Retries the operation up to 3 times.
fn fetch(url: &str) -> Result<Response> {
    client.get(url).send()  // No retry logic
}
```

### Good
```rust
/// Returns the smallest element in the slice.
/// Returns `None` if the slice is empty.
fn find_min(data: &[i32]) -> Option<i32> {
    data.iter().min().copied()
}

/// Sends a GET request to the given URL.
fn fetch(url: &str) -> Result<Response> {
    client.get(url).send()
}
```

## When to flag

- Doc comment describes a return value or behavior that the implementation contradicts.
- Doc comment mentions error conditions that can't actually occur (or vice versa).
- Doc comment lists parameters or fields that have been renamed or removed.
- `# Panics` section is missing when the function can panic, or present when it can't.
- `# Safety` section on `unsafe fn` lists requirements that aren't actually needed, or omits real requirements.

## When NOT to flag

- Minor wording differences that don't change the semantic meaning.
- Doc comments on trait methods that describe the general contract (implementations may vary).
- Comments that are vague but not wrong (e.g., "processes the input" — unhelpful but not contradictory).
