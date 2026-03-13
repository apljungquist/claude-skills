# Rule: stale-safety-comment

**Severity:** error

## Problem

A `// SAFETY:` comment above an `unsafe` block lists invariants or justifications that no longer match what the unsafe code actually does. This gives false confidence that the unsafe code has been audited. Reviewers and auditors approve the unsafe block based on the stale justification, missing actual unsoundness that can cause undefined behavior.

## Example

### Bad
```rust
// SAFETY: `ptr` is guaranteed to be non-null and aligned because
// it was allocated by `Vec::as_mut_ptr()`.
unsafe {
    // ptr was changed to come from raw pointer arithmetic
    let val = *ptr.add(offset);
    std::ptr::write(other_ptr, val);
    // `other_ptr` is not mentioned in the SAFETY comment at all
}
```

### Good
```rust
// SAFETY:
// - `ptr` is valid because it comes from `Vec::as_mut_ptr()` and `offset < vec.len()`.
// - `other_ptr` is valid and properly aligned: it was obtained from `Box::into_raw()`.
// - The two pointers do not alias because they point into different allocations.
unsafe {
    let val = *ptr.add(offset);
    std::ptr::write(other_ptr, val);
}
```

## When to flag

- The SAFETY comment mentions variables or pointers not present in the unsafe block.
- The unsafe block uses pointers or operations not addressed by the SAFETY comment.
- The SAFETY comment references a condition that was true in a previous version but not after recent changes.
- No SAFETY comment exists on a non-trivial unsafe block.

## When NOT to flag

- The SAFETY comment is present and accurately covers all unsafe operations, even if terse.
- Unsafe blocks that are trivial (e.g., calling a well-known FFI function with obvious invariants).
- Generated code or macro expansions where the SAFETY justification is in the macro definition.
