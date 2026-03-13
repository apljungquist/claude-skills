# Rule: stale-todo-or-fixme

**Severity:** suggestion

## Problem

A TODO, FIXME, HACK, or XXX comment refers to work that has already been completed, a bug that has been fixed, or a condition that no longer applies. Stale markers create noise and erode trust in remaining markers. Developers waste time investigating already-resolved issues, or lose trust in remaining markers and start ignoring genuine TODOs.

## Example

### Bad
```rust
// TODO: add error handling here
match parse(input) {
    Ok(val) => process(val),
    Err(e) => return Err(e.into()),  // Error handling is already here
}

// FIXME: this will panic on empty input
fn first_char(s: &str) -> Option<char> {
    s.chars().next()  // Returns None on empty input, no panic
}
```

### Good
```rust
match parse(input) {
    Ok(val) => process(val),
    Err(e) => return Err(e.into()),
}

fn first_char(s: &str) -> Option<char> {
    s.chars().next()
}
```

## When to flag

- TODO/FIXME describes work that the surrounding code already implements.
- FIXME describes a bug that has been fixed in the current code.
- TODO references a tracking issue that has been closed.
- HACK comment on code that has since been refactored to a clean solution.

## When NOT to flag

- TODO/FIXME that describes genuinely pending work.
- Comments that are partially addressed — some part is still relevant.
- Cannot determine staleness without external context (e.g., issue tracker).
