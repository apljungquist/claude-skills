# Rule: integer-overflow-in-release

**Severity:** warning

## Problem

Integer arithmetic on user-influenced values silently wraps in release mode (Rust's default). Debug mode panics on overflow, but release builds wrap, producing incorrect results without any indication of error. Arithmetic silently produces a wrapped value — potentially allocating a huge buffer from a small multiplication, indexing the wrong element, or computing an incorrect total.

## Example

### Bad
```rust
fn calculate_total(price: u32, quantity: u32) -> u32 {
    price * quantity  // Wraps silently in release if > u32::MAX
}

fn offset_index(base: usize, user_offset: usize) -> usize {
    base + user_offset  // Can wrap to a small number
}
```

### Good
```rust
fn calculate_total(price: u32, quantity: u32) -> Option<u32> {
    price.checked_mul(quantity)
}

fn offset_index(base: usize, user_offset: usize) -> Result<usize, Error> {
    base.checked_add(user_offset)
        .ok_or(Error::OffsetTooLarge)
}
```

## When to flag

- `+`, `-`, `*` on integer types where operands derive from user input, network data, or file contents.
- Arithmetic result used as an index, allocation size, or loop bound.
- Multiplication of two user-provided values without overflow check.
- Subtraction that could underflow (unsigned types going below zero).

## When NOT to flag

- Arithmetic on compile-time constants or small bounded values.
- Code using `Wrapping<T>` or `wrapping_*` methods where wraparound is intentional.
- The values have been validated/bounded before the arithmetic.
- Arithmetic in `#[cfg(test)]` or debug-only code paths.
- Counter increments where the maximum value is astronomically unlikely (e.g., `u64` loop counter).
