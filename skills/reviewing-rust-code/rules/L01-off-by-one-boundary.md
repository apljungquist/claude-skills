# Rule: off-by-one-boundary

**Severity:** error

## Problem

Range bounds include or exclude one too many or too few elements, causing missed items, out-of-bounds access, or fencepost errors. This can cause skipped elements, duplicated processing, or panics from out-of-bounds indexing.

## Example

### Bad
```rust
// Processes all items except the last one
for i in 0..items.len() - 1 {
    process(&items[i]);
}

// Slices one element too many
let first_half = &data[0..=data.len() / 2];
```

### Good
```rust
// Processes all items
for i in 0..items.len() {
    process(&items[i]);
}

// Correct exclusive upper bound for first half
let first_half = &data[0..data.len() / 2];
```

## When to flag

- `..=` used where `..` was intended (or vice versa), based on surrounding context (variable names, comments, function purpose).
- `<= len` in a loop condition (usually should be `< len`).
- Manual index arithmetic (`len - 1`, `len + 1`) at range boundaries where the intent doesn't match the result.
- Window/chunk/sliding operations where the final partial window is silently dropped or duplicated.

## When NOT to flag

- Idiomatic `0..len` iteration — this is correct.
- `..=` on inclusive ranges where inclusivity is clearly intended (e.g., `1..=n` for 1-indexed math).
- Off-by-one is in a test or fuzzing harness.
- The range is guarded by a subsequent bounds check.
