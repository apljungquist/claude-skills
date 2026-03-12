# Rule: fallible-in-infallible

**Severity:** warning

## Problem

A function's signature and its implementation disagree about fallibility. Either the function returns `Result`/`Option` but can never fail, or it has an infallible signature but contains operations that can fail (silently swallowed or panicking). Callers of a needlessly-fallible function pay the ergonomic cost of error handling for errors that never occur; callers of a secretly-fallible function get panics they didn't expect.

## Example

### Bad
```rust
// Returns Result but never fails
fn get_default_config() -> Result<Config, Error> {
    Ok(Config {
        timeout: Duration::from_secs(30),
        retries: 3,
    })
}

// Infallible signature but can panic
fn process(data: &[u8]) -> Output {
    let s = std::str::from_utf8(data).unwrap(); // can panic
    Output::new(s)
}
```

### Good
```rust
fn get_default_config() -> Config {
    Config {
        timeout: Duration::from_secs(30),
        retries: 3,
    }
}

fn process(data: &[u8]) -> Result<Output, ProcessError> {
    let s = std::str::from_utf8(data)?;
    Ok(Output::new(s))
}
```

## When to flag

- Function returns `Result<T, E>` but `Err` is never constructed or propagated.
- Function returns `Option<T>` but `None` is never returned.
- Function has no `Result`/`Option` return type but calls `.unwrap()` or `.expect()` on fallible operations internally.
- Trait implementation returns `Result` by trait requirement, but the doc comment claims it cannot fail without explaining this guarantee.

## When NOT to flag

- Trait implementations that must return `Result`/`Option` by the trait contract (e.g., `TryFrom`, `FromStr`) even if the implementation is infallible.
- Functions that currently can't fail but are designed for future fallibility (if documented).
- Functions where `unwrap()` is on a provably-safe operation (e.g., regex compiled from a literal).
- Functions that are infallible *because* they accept a parsed/validated type (e.g., takes `NonZeroUsize` instead of `usize`) — infallibility is correct here; the validation happened at construction time (see A28 `validate-then-forget`).
