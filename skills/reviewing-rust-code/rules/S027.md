# Rule: unsanitized-path-input

**Severity:** error

## Problem

User-provided strings used in file path construction without validation, allowing path traversal (`../`) or access to unintended files. An attacker uses `../` sequences to read or overwrite files outside the intended directory, potentially accessing credentials, config files, or other sensitive data.

## Example

### Bad
```rust
fn serve_file(base_dir: &Path, filename: &str) -> Result<Vec<u8>> {
    let path = base_dir.join(filename);
    // filename could be "../../etc/passwd"
    Ok(std::fs::read(path)?)
}
```

### Good
```rust
fn serve_file(base_dir: &Path, filename: &str) -> Result<Vec<u8>> {
    let path = base_dir.join(filename);
    let canonical = path.canonicalize()
        .context("invalid path")?;
    if !canonical.starts_with(base_dir.canonicalize()?) {
        return Err(Error::PathTraversal);
    }
    Ok(std::fs::read(canonical)?)
}
```

## When to flag

- `Path::new(user_input)` or `.join(user_input)` where `user_input` comes from HTTP requests, CLI args, config files, or deserialized data — without subsequent path validation.
- No `canonicalize()` + `starts_with()` check after constructing a path from external input.
- User input used to construct paths for `fs::read`, `fs::write`, `fs::remove_file`, or `File::open`.
- `..` components not stripped or rejected from user-provided path segments.

## When NOT to flag

- Paths from trusted sources (compile-time, environment variables set by the deployment).
- CLI tools where the user is the operator and path traversal is expected behavior.
- Path is validated by `canonicalize()` + `starts_with()` or equivalent check.
- Input is from an internal API that guarantees sanitized paths.
