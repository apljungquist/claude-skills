# Rule: validate-then-forget

**Severity:** suggestion

## Problem

Code validates a property of its input (non-emptiness, format, range) but continues working with the original loose type, discarding the proof. Every downstream consumer must re-validate or silently trust that validation happened. This is "shotgun parsing" — scattering checks throughout the codebase instead of parsing once at the boundary into a type that makes the invalid state unrepresentable. Validated properties are not enforced by the type system, so a future code change can bypass or forget to repeat the validation, reintroducing the bug the check was meant to prevent.

See: [Parse, Don't Validate](https://lexi-lambda.github.io/blog/2019/11/05/parse-don-t-validate/)

## Example

### Bad
```rust
fn process_items(items: Vec<Item>) -> Result<Summary> {
    if items.is_empty() {
        return Err(Error::EmptyList);
    }
    // From here on, `items` is still a Vec — nothing prevents passing
    // it to a function that re-checks or wrongly assumes non-emptiness.
    let first = items[0].clone(); // safe here, but fragile
    compute_summary(&items, first)
}

fn send_email(to: &str) -> Result<()> {
    if !to.contains('@') {
        return Err(Error::InvalidEmail);
    }
    // `to` is still &str — downstream code has no proof it's valid
    queue_message(to)
}
```

### Good
```rust
struct NonEmptyVec<T> {
    first: T,
    rest: Vec<T>,
}

impl<T> NonEmptyVec<T> {
    fn new(items: Vec<T>) -> Result<Self, Error> {
        let mut iter = items.into_iter();
        let first = iter.next().ok_or(Error::EmptyList)?;
        Ok(Self { first, rest: iter.collect() })
    }

    fn first(&self) -> &T { &self.first }
}

fn process_items(items: NonEmptyVec<Item>) -> Summary {
    // Cannot be called with an empty list — the type prevents it.
    compute_summary(&items)
}

struct EmailAddress(String);

impl EmailAddress {
    fn parse(s: &str) -> Result<Self, Error> {
        if !s.contains('@') {
            return Err(Error::InvalidEmail);
        }
        Ok(Self(s.to_owned()))
    }
}

fn send_email(to: &EmailAddress) -> Result<()> {
    queue_message(to.as_ref())
}
```

## When to flag

- Function validates a property at the top (non-empty, non-negative, valid format, within range) then continues with the raw `Vec`, `&str`, `u32`, etc.
- Multiple functions independently validate the same property on the same type — a sign the invariant should be encoded once in a wrapper type.
- `assert!` or `debug_assert!` used to enforce a domain invariant that could be captured by a newtype.
- `is_valid()` / `validate()` functions that return `bool` or `Result<()>` — the proof is discarded after the check.
- Stringly-typed APIs: `&str` used for URLs, file paths, identifiers, email addresses, SQL, etc., where a dedicated type would prevent misuse.

## When NOT to flag

- Validation at a system boundary (CLI parsing, HTTP handler) that immediately converts to a domain type — this is exactly the right pattern.
- One-shot scripts or small CLI tools where the added type machinery isn't justified.
- The validated property is used exactly once and locally (e.g., a single `if` guard before a single use).
- The project already uses a validated type from a library (e.g., `url::Url`, `std::num::NonZeroUsize`) — no need to reinvent it.
- Performance-sensitive code where the newtype wrapper would force unnecessary copies or allocations.
