# Rule: deadlock-ordering

**Severity:** error

## Problem

Multiple locks (Mutex, RwLock) are acquired in inconsistent order across different code paths, creating the possibility of deadlock. Two threads each wait on the lock the other holds, freezing the affected code paths permanently — typically requiring a process restart.

## Example

### Bad
```rust
// Thread 1:
let _a = self.accounts.lock().unwrap();
let _b = self.ledger.lock().unwrap();    // Lock order: accounts → ledger

// Thread 2:
let _b = self.ledger.lock().unwrap();
let _a = self.accounts.lock().unwrap();  // Lock order: ledger → accounts  💀
```

### Good
```rust
// Consistent lock ordering everywhere: accounts → ledger
fn transfer(&self) {
    let _a = self.accounts.lock().unwrap();
    let _b = self.ledger.lock().unwrap();
}

fn audit(&self) {
    let _a = self.accounts.lock().unwrap();
    let _b = self.ledger.lock().unwrap();
}
```

## When to flag

- Two or more `.lock()` / `.read()` / `.write()` calls on different mutexes where the order differs across functions or code paths.
- Lock held across an `.await` point where another task may try to acquire the same locks in different order.
- Lock acquired inside a callback or closure where the caller already holds a different lock.

## When NOT to flag

- Only one lock is ever held at a time.
- Lock ordering is documented and consistent across the codebase.
- Using `try_lock()` with fallback logic to avoid blocking.
- Using a single coarse-grained lock.
