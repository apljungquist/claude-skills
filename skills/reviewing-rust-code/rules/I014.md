# Rule: silent-none-drop

**Severity:** warning

## Problem

`if let Some(x)` or `while let Some(x)` silently ignores the `None` case when the absence of a value should trigger an action (logging, error return, default behavior). An expected side effect (notification, write, cleanup) silently doesn't happen, and no error is reported — the failure is invisible.

## Example

### Bad
```rust
if let Some(user) = db.find_user(id) {
    send_notification(&user);
}
// If user not found, notification is silently skipped — caller never knows
```

### Good
```rust
match db.find_user(id) {
    Some(user) => send_notification(&user),
    None => {
        log::warn!("Cannot notify user {id}: not found");
        return Err(UserNotFound(id));
    }
}
```

## When to flag

- `if let Some` with no `else` where the function's purpose suggests `None` is an error condition.
- The `None` case causes a side effect to silently not happen (e.g., notification not sent, event not recorded).
- The return type of the enclosing function is `Result`, suggesting errors should be propagated, but `None` is silently dropped.
- A chain of `if let Some` where missing any step silently aborts the whole operation.

## When NOT to flag

- `None` is genuinely a valid "nothing to do" case (e.g., optional configuration, optional callback).
- The `if let Some` is used for conditional formatting or display.
- `while let Some` on an iterator or channel — `None` just means "done."
- The code pattern is `if let Some(x) = option { ... }` where `option` is explicitly documented as optional.
