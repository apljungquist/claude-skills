# Rule: quadratic-collection-ops

**Severity:** warning

## Problem

Nested iteration or repeated linear searches on Vec/slice create O(n^2) or worse behavior when a HashSet/HashMap would give O(n). Code that works fine in development with small datasets becomes a bottleneck or causes timeouts in production with larger inputs.

## Example

### Bad
```rust
// O(n*m) — linear search for each item
let mut result = Vec::new();
for item in &list_a {
    if list_b.contains(item) {
        result.push(item);
    }
}

// O(n^2) — repeated remove from Vec
for id in &ids_to_remove {
    if let Some(pos) = items.iter().position(|i| i.id == *id) {
        items.remove(pos);  // Also shifts elements: O(n) each
    }
}
```

### Good
```rust
let set_b: HashSet<_> = list_b.iter().collect();
let result: Vec<_> = list_a.iter().filter(|item| set_b.contains(item)).collect();

let ids_to_remove: HashSet<_> = ids_to_remove.iter().collect();
items.retain(|item| !ids_to_remove.contains(&item.id));
```

## When to flag

- `.contains()`, `.position()`, or `.find()` on a Vec/slice inside a loop iterating over another collection.
- `.remove()` called repeatedly on a Vec inside a loop (each removal is O(n) due to shifting).
- Nested `for` loops where the inner loop searches/filters the outer loop's collection.
- Pattern occurs where either collection could be large (not bounded to a small constant).

## When NOT to flag

- Collections are known to be small (documented, bounded by a constant, or derived from a small enum).
- The code runs once at startup or in a cold path.
- Using `Vec` for cache locality is an intentional performance choice (documented).
