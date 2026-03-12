# Rule: blocking-in-async

**Severity:** warning

## Problem

Blocking I/O or long computation inside an async context blocks the executor thread, causing latency spikes or deadlocks in other tasks sharing the same runtime. Other tasks sharing the same executor thread stall, causing latency spikes, timeout cascades, or deadlocks if the blocked task holds resources other tasks need.

## Example

### Bad
```rust
async fn read_config(path: &Path) -> Result<Config> {
    let data = std::fs::read_to_string(path)?;  // Blocks the async runtime
    Ok(toml::from_str(&data)?)
}

async fn process(data: &[u8]) -> Result<Hash> {
    let hash = sha256(data);  // CPU-intensive, blocks the executor
    Ok(hash)
}
```

### Good
```rust
async fn read_config(path: &Path) -> Result<Config> {
    let data = tokio::fs::read_to_string(path).await?;
    Ok(toml::from_str(&data)?)
}

async fn process(data: Vec<u8>) -> Result<Hash> {
    let hash = tokio::task::spawn_blocking(move || sha256(&data)).await?;
    Ok(hash)
}
```

## When to flag

- `std::fs::*` operations inside `async fn` or blocks containing `.await`.
- `std::net::*` (synchronous TCP/UDP) inside async context.
- `std::thread::sleep` inside async code (should be `tokio::time::sleep`).
- `Mutex::lock()` (std) held across `.await` — use `tokio::sync::Mutex` instead.
- CPU-heavy computation (hashing, compression, serialization of large data) without `spawn_blocking`.

## When NOT to flag

- The async runtime is configured with `flavor = "multi_thread"` and the blocking operation is brief.
- `tokio::sync::Mutex` used instead of `std::sync::Mutex`.
- Code uses `block_in_place` from tokio to signal intentional blocking.
- The function is `async` only because it calls one async function at the end (the blocking part runs first and is fast).
