# Rule: inverted-condition

**Severity:** error

## Problem

A boolean condition is the opposite of what the surrounding logic expects, causing the wrong branch to execute. The wrong branch executes, causing the function to accept invalid input, reject valid input, or skip critical side effects.

## Example

### Bad
```rust
fn validate(input: &str) -> Result<(), Error> {
    if input.is_empty() {
        // Proceeds with empty input instead of rejecting it
        process(input)?;
    }
    Ok(())
}
```

### Good
```rust
fn validate(input: &str) -> Result<(), Error> {
    if !input.is_empty() {
        process(input)?;
    }
    Ok(())
}
```

## When to flag

- Guard clause that returns/continues on the *non-error* condition instead of the error condition.
- `if !condition` where the body clearly expects `condition` to be true (or vice versa).
- Boolean variable named `is_valid` or `should_retry` used in a branch that contradicts its name.
- Negation added or removed during refactoring that inverts the original intent.

## When NOT to flag

- Double negations that are stylistically awkward but logically correct.
- Complex boolean expressions where correctness is ambiguous without domain context.
- The condition is covered by tests visible in the diff.
