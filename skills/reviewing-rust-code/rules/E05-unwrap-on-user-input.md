# Rule: unwrap-on-user-input

**Severity:** warning

## Problem

`unwrap()` or `expect()` is called on data derived from external input (user input, file contents, network data), which will panic on malformed input instead of returning an error. Malformed input from users, files, or the network causes a panic, crashing the process or aborting the request with no actionable error message.

## Example

### Bad
```rust
let port: u16 = args.port.parse().unwrap();

let config: Config = serde_json::from_slice(&body).unwrap();
```

### Good
```rust
let port: u16 = args.port.parse()
    .context("invalid port number")?;

let config: Config = serde_json::from_slice(&body)
    .context("invalid config JSON")?;
```

## When to flag

- `.unwrap()` or `.expect()` on the result of parsing, deserialization, or conversion of data that originates from outside the program.
- `.unwrap()` on `Option` values derived from user-controlled strings (e.g., `.split().next().unwrap()`).
- `.unwrap()` on I/O results in non-setup code (e.g., after the program has started serving requests).

## When NOT to flag

- `.unwrap()` in test code (`#[cfg(test)]`, `#[test]`).
- `.expect()` with a message explaining why the value is guaranteed (e.g., after a preceding validation check).
- `.unwrap()` on `Mutex::lock()` — this is conventional Rust style (panics only on poisoned mutex).
- Static/compile-time values (e.g., `Regex::new("literal").unwrap()` in a `lazy_static` or `OnceLock`).
- `.unwrap()` in CLI tools where panicking on bad input is acceptable by design.
