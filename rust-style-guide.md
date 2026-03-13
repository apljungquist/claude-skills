# Rust Style Guide
### Adapted from the Linux Kernel Coding Style

Version: 1.0.0 — 2026-03-12

---

## Preamble

This guide adapts principles from the [Linux kernel coding style](https://www.kernel.org/doc/html/v6.4/process/coding-style.html) for Rust codebases. Not all kernel rules transfer — C and Rust are different languages with different guardrails — but the kernel guide's emphasis on readability, simplicity, and maintainability is language-independent. Each rule in this guide references its kernel origin so you can read the original rationale.

This guide covers Rust source code (`.rs` files). It does not cover build scripts, CI configuration, or generated code.

Overriding principle: when two rules conflict or a situation falls outside this guide, prefer the option that is easier to understand when reading the code six months from now. As the kernel guide puts it: "if you need more than 3 levels of indentation, you're screwed anyway, and should fix your program."

## Severity Taxonomy

| Level | Name | Claude behavior | Human meaning |
|---|---|---|---|
| 1 | **Error** | Always flag; block merge | This violates correctness or safety |
| 2 | **Warning** | Always flag; request change | This violates the style contract |
| 3 | **Suggestion** | Flag once; do not repeat | This is an improvement, not a requirement |

## Out of Scope

The following are explicitly out of scope for this style guide. Claude should not comment on these topics during code review.

- **Indentation, line length, brace placement, and spacing.** These are enforced by `rustfmt`. Running `cargo fmt` before committing resolves all such issues automatically. (Kernel §1, §2, §3 — in Rust the formatter owns these decisions.)

- **Import ordering.** Enforced by `rustfmt` or project-level configuration.

- **Editor modelines and configuration.** Do not embed editor-specific markers in source files. Respect each developer's personal editor preferences. (Kernel §19.)

- **Code in auto-generated files** (e.g., `build.rs` output, protobuf bindings). These files are generated and should not be reviewed for style.

---

## Naming

Names are the primary tool for communicating intent. The kernel guide's advice is simple: short names for small scopes, descriptive names for large scopes, and never Hungarian notation. Rust's compiler already enforces `snake_case` for variables/functions and `CamelCase` for types, so this section focuses on the semantic choices that remain.

*Adapted from kernel §4.*

### NAM-001: Scale name length to scope size

**Severity:** Warning

**Rule:** Local variables in short functions may use concise names (`i`, `n`, `buf`). Public functions, types, traits, and constants must use descriptive names that convey purpose without requiring the reader to look at the implementation.

**Rationale:** A loop counter named `i` in a five-line function is immediately clear. A public function named `proc()` forces every caller to read its body to understand what it does. The kernel guide states: "global functions need descriptive names... local variable names should be short, and to the point." The failure mode of short public names is that every consumer of your API must do extra work to understand it, and that cost multiplies with every call site.

**Do this:**
```rust
// Local: short scope, short name
for i in 0..items.len() {
    process(&items[i]);
}

// Public: descriptive, conveys the contract
pub fn calculate_shipping_cost(order: &Order, destination: &Address) -> Result<Money> {
    // ...
}
```

**Don't do this:**
```rust
// Public function with opaque name — callers cannot understand
// the contract without reading the implementation.
pub fn calc(o: &Order, a: &Address) -> Result<Money> {
    // ...
}
```

**Exceptions:** None.

---

### NAM-002: Use inclusive terminology

**Severity:** Warning

**Rule:** Use `primary`/`secondary` instead of `master`/`slave`. Use `allowlist`/`denylist` instead of `whitelist`/`blacklist`. Use `blocklist` instead of `blacklist` when the list blocks rather than denies.

**Rationale:** The kernel guide explicitly adopted these replacements. The technical meaning is preserved; the only change is that the metaphor is neutral. This is a convention — both sets of terms are understood — but consistency with the kernel guide and the broader industry trend makes the codebase more welcoming. The failure mode of not following this is not technical but social: contributors may feel excluded, and some organizations' contribution policies require inclusive language.

**Do this:**
```rust
struct ReplicationConfig {
    primary_address: SocketAddr,
    secondary_addresses: Vec<SocketAddr>,
}

fn is_allowed(domain: &str, allowlist: &[String]) -> bool {
    allowlist.iter().any(|d| d == domain)
}
```

**Don't do this:**
```rust
// Outdated terminology
struct ReplicationConfig {
    master_address: SocketAddr,
    slave_addresses: Vec<SocketAddr>,
}
```

**Exceptions:** None. When interfacing with external systems that use legacy terminology, use the external term only at the boundary and map to inclusive terms internally.

---

## Functions

Short functions that do one thing are the single most important structural property of readable code. The kernel guide devotes an entire section to this, and the advice is identical in Rust.

*Adapted from kernel §6 and §15.*

### FUN-001: Keep functions short

**Severity:** Warning (over 40 lines), Error (over 80 lines)

**Rule:** Functions should not exceed 40 lines of executable code (excluding comments, blank lines, and closing braces). A function over 80 lines is an Error.

**Rationale:** The kernel guide says functions should fit on "one or two screenfuls of text" and that "the maximum length of a function is inversely proportional to the complexity and indentation level of that function." Short functions are easier to name, easier to test, and easier to reason about. When a function is long, it is almost always doing more than one thing. The failure mode is a function that nobody wants to modify because it is too hard to understand, and bugs hide in the interactions between its many responsibilities.

**Do this:**
```rust
fn process_order(order: &Order, inventory: &mut Inventory) -> Result<Receipt> {
    let validated = validate_order(order)?;
    let reserved = reserve_inventory(&validated, inventory)?;
    let receipt = charge_payment(&reserved)?;
    confirm_reservation(&reserved, inventory);
    Ok(receipt)
}
```

**Don't do this:**
```rust
fn process_order(order: &Order, inventory: &mut Inventory) -> Result<Receipt> {
    // 120 lines of validation, inventory checking, payment processing,
    // email sending, logging, and metrics — all in one function.
    // ...
}
```

**Exceptions:** See FUN-001-EX in the Exceptions Registry.

---

### FUN-002: Each function does one thing

**Severity:** Warning

**Rule:** A function should perform one conceptual operation. If you can describe what a function does using the word "and", it should be two functions.

**Rationale:** The kernel guide states: "Functions do one thing and do it well." A function that validates input *and* writes to the database is doing two things. If either changes, the entire function must be re-examined. The failure mode is shotgun surgery: a single business requirement change forces edits in a function that also handles unrelated concerns, increasing the risk of regressions.

**Do this:**
```rust
fn validate_email(input: &str) -> Result<Email> {
    // Only validation logic
}

fn store_user(user: &User, db: &Database) -> Result<UserId> {
    // Only persistence logic
}
```

**Don't do this:**
```rust
// This function validates AND persists — two responsibilities.
fn validate_and_store_user(input: &str, db: &Database) -> Result<UserId> {
    // validation logic mixed with database calls
}
```

**Exceptions:** None.

---

### FUN-003: Limit local variables

**Severity:** Suggestion

**Rule:** A function should have no more than 5 to 10 local variables.

**Rationale:** The kernel guide prescribes this limit because "the human brain can generally easily keep track of about 7 different things." More variables means more state to track mentally, which means more opportunities for mistakes. A function with many locals is usually doing too many things (see FUN-002). The failure mode is that a developer modifies one variable thinking it is independent, but it interacts with another variable in a non-obvious way.

**Do this:**
```rust
fn summarize(transactions: &[Transaction]) -> Summary {
    let total = transactions.iter().map(|t| t.amount).sum();
    let count = transactions.len();
    let average = if count > 0 { total / count as f64 } else { 0.0 };
    Summary { total, count, average }
}
```

**Don't do this:**
```rust
fn summarize(transactions: &[Transaction]) -> Summary {
    let total = /* ... */;
    let count = /* ... */;
    let average = /* ... */;
    let min = /* ... */;
    let max = /* ... */;
    let median = /* ... */;
    let std_dev = /* ... */;
    let variance = /* ... */;
    let skewness = /* ... */;
    let kurtosis = /* ... */;
    let percentile_90 = /* ... */;
    let percentile_95 = /* ... */;
    // 12 locals — extract helper functions for statistical measures
    Summary { /* ... */ }
}
```

**Exceptions:** None.

**Related rules:** FUN-001, FUN-002.

---

### FUN-004: Use `#[inline]` sparingly

**Severity:** Warning

**Rule:** Apply `#[inline]` only to functions that are three lines or fewer, or where a parameter is a compile-time constant that enables the optimizer to eliminate branches. Do not apply `#[inline(always)]` unless benchmarking proves it is necessary.

**Rationale:** The kernel guide calls this "the inline disease." Excessive inlining increases binary size, pollutes the instruction cache, and can make code *slower*, not faster. The Rust compiler and LLVM are good at making inlining decisions; overriding them without measurement is premature optimization. The failure mode is a project where everything is `#[inline(always)]`, binaries are bloated, and nobody can explain why because no benchmarks were ever run.

**Do this:**
```rust
#[inline]
fn is_empty(&self) -> bool {
    self.len == 0
}
```

**Don't do this:**
```rust
// 30-line function forced inline without benchmarking evidence.
#[inline(always)]
fn process_batch(items: &[Item], config: &Config) -> Result<Vec<Output>> {
    // ... many lines of logic ...
}
```

**Exceptions:** None. If you believe a function needs `#[inline(always)]`, add a comment citing the benchmark that justifies it.

---

## Error Handling

Rust's type system makes error handling explicit in a way that C cannot. The kernel guide's advice about centralized cleanup via `goto` and cautious use of `panic` (§7, §16, §22) maps naturally onto Rust's `Result`, `?` operator, and `Drop`.

*Adapted from kernel §7, §16, and §22.*

### ERR-001: Prefer `Result` over `panic!` in library code

**Severity:** Error

**Rule:** Library code must not call `panic!()`, `.unwrap()`, or `.expect()` on `Result` or `Option` values in any code path reachable during normal operation. Use `Result` to propagate errors to the caller.

**Rationale:** The kernel guide says "do not crash the kernel" — the equivalent in Rust is "do not panic in library code." A panic unwinds the stack (or aborts), giving the caller no opportunity to handle the error, log context, or clean up. The failure mode is an application that crashes in production because a library panicked on unexpected input instead of returning an error.

**Do this:**
```rust
pub fn parse_config(input: &str) -> Result<Config, ConfigError> {
    let value: serde_json::Value = serde_json::from_str(input)
        .map_err(|e| ConfigError::InvalidJson(e))?;
    let port = value["port"]
        .as_u64()
        .ok_or(ConfigError::MissingField("port"))?;
    Ok(Config { port: port as u16 })
}
```

**Don't do this:**
```rust
pub fn parse_config(input: &str) -> Config {
    // Panics if input is not valid JSON — caller cannot recover.
    let value: serde_json::Value = serde_json::from_str(input).unwrap();
    let port = value["port"].as_u64().expect("missing port");
    Config { port: port as u16 }
}
```

**Exceptions:** See ERR-001-EX in the Exceptions Registry.

**Related rules:** ERR-002.

---

### ERR-002: Use `?` for error propagation

**Severity:** Warning

**Rule:** Use the `?` operator to propagate errors up the call stack. Do not manually match on `Result` to re-wrap and return errors unless you need to add context or transform the error type.

**Rationale:** The kernel guide recommends `goto` labels for centralized cleanup (§7). In Rust, `?` and `Drop` serve the same purpose: they ensure cleanup runs and errors propagate without scattering cleanup logic across every call site. Manual `match` on every `Result` obscures the happy path and increases the chance of forgetting an error case. The failure mode is deeply nested match arms where the actual logic is buried under boilerplate error handling.

**Do this:**
```rust
fn load_and_validate(path: &Path) -> Result<Config> {
    let content = fs::read_to_string(path)?;
    let config = parse_config(&content)?;
    validate(&config)?;
    Ok(config)
}
```

**Don't do this:**
```rust
fn load_and_validate(path: &Path) -> Result<Config> {
    // Unnecessary match nesting — the happy path is buried.
    match fs::read_to_string(path) {
        Ok(content) => match parse_config(&content) {
            Ok(config) => match validate(&config) {
                Ok(()) => Ok(config),
                Err(e) => Err(e.into()),
            },
            Err(e) => Err(e.into()),
        },
        Err(e) => Err(e.into()),
    }
}
```

**Exceptions:** Adding context (e.g., via `map_err` or `anyhow::Context`) before `?` is encouraged, not a violation.

---

### ERR-003: Match function names to return type semantics

**Severity:** Warning

**Rule:** Functions that perform actions should return `Result<T, E>` where `Ok` means success and `Err` means failure. Functions that answer yes/no questions (predicates) should return `bool` and be named with `is_`, `has_`, `can_`, or `should_` prefixes.

**Rationale:** The kernel guide (§16) distinguishes between "action" functions that return error codes and "predicate" functions that return booleans, and warns that confusing the two "is a difficult-to-find bug." The same applies in Rust: a function named `is_valid` that returns `Result` confuses callers, and a function named `validate` that returns `bool` swallows error details. The failure mode is callers who misinterpret the return value because the name implies a different contract than the type delivers.

**Do this:**
```rust
/// Returns true if the token has not expired.
fn is_valid(token: &Token) -> bool {
    token.expires_at > Utc::now()
}

/// Validates the request, returning an error describing what is wrong.
fn validate_request(req: &Request) -> Result<(), ValidationError> {
    if req.body.is_empty() {
        return Err(ValidationError::EmptyBody);
    }
    Ok(())
}
```

**Don't do this:**
```rust
// Name says "is_valid" (predicate) but returns Result (action).
// Callers expect a bool and are confused by the error type.
fn is_valid(req: &Request) -> Result<(), ValidationError> {
    // ...
}
```

**Exceptions:** None.

---

## Comments and Documentation

Comments should explain things that the code cannot. Rust's doc comments (`///`) are first-class — they appear in `cargo doc`, IDE hover, and docs.rs. This makes documentation a part of the API surface, not an afterthought.

*Adapted from kernel §8.*

### DOC-001: Explain what code does, not how it does it

**Severity:** Warning

**Rule:** Comments inside function bodies should explain *what* the code is accomplishing or *why* a non-obvious approach was chosen. Do not write comments that restate the code in English.

**Rationale:** The kernel guide says: "you want your comments to tell WHAT your code does, not HOW." A comment that says `// increment counter` above `counter += 1` adds no information and must be maintained alongside the code. When the code changes but the comment doesn't, the comment becomes a lie — which is worse than no comment at all. The failure mode is a codebase full of stale comments that actively mislead readers.

**Do this:**
```rust
// Retry with exponential backoff because the upstream service
// rate-limits clients that reconnect too aggressively.
for attempt in 0..MAX_RETRIES {
    match client.send(&request).await {
        Ok(response) => return Ok(response),
        Err(_) if attempt < MAX_RETRIES - 1 => {
            sleep(Duration::from_millis(100 << attempt)).await;
        }
        Err(e) => return Err(e.into()),
    }
}
```

**Don't do this:**
```rust
// Loop from 0 to MAX_RETRIES
for attempt in 0..MAX_RETRIES {
    // Send the request
    match client.send(&request).await {
        // If ok, return the response
        Ok(response) => return Ok(response),
        // If error and not last attempt, sleep
        Err(_) if attempt < MAX_RETRIES - 1 => {
            sleep(Duration::from_millis(100 << attempt)).await;
        }
        // Otherwise return the error
        Err(e) => return Err(e.into()),
    }
}
```

**Exceptions:** None.

---

### DOC-002: All public items must have doc comments

**Severity:** Warning

**Rule:** All public functions, methods, types, traits, and constants must have a `///` doc comment. Doc comments must describe what the item does, not how it does it. Parameters and return values must be documented if their purpose is not obvious from the name and type.

**Rationale:** Public items are used by callers who may not read the implementation. Rust's `///` comments are rendered by `cargo doc` and surfaced by IDEs on hover — they are the first thing a user sees. An undocumented public function forces consumers to read source code to understand the contract, which defeats the purpose of an API boundary. The failure mode is a library that is technically correct but practically unusable because nobody can figure out how to call it.

**Do this:**
```rust
/// Compresses the input data using the specified algorithm.
///
/// Returns the compressed bytes, or an error if the input exceeds
/// the maximum supported size (4 GiB).
pub fn compress(data: &[u8], algorithm: Algorithm) -> Result<Vec<u8>> {
    // ...
}
```

**Don't do this:**
```rust
pub fn compress(data: &[u8], algorithm: Algorithm) -> Result<Vec<u8>> {
    // No doc comment — callers must read the source to understand
    // the size limit, error conditions, and algorithm behavior.
    // ...
}
```

**Exceptions:** See DOC-002-EX in the Exceptions Registry.

**Related rules:** NAM-001 (good names reduce documentation burden).

---

## Type System

Rust's type system is more expressive than C's. The kernel guide's caution about typedefs (§5) and booleans (§17) translates into Rust-specific advice about type aliases, newtype wrappers, and enums.

*Adapted from kernel §5 and §17.*

### TYP-001: Prefer newtype wrappers over `type` aliases

**Severity:** Suggestion

**Rule:** When two values have the same underlying type but different semantics, use a newtype wrapper (`struct Meters(f64)`) rather than a `type` alias (`type Meters = f64`). Use `type` aliases only for shortening complex generic types where no semantic distinction exists.

**Rationale:** The kernel guide warns against typedefs that hide the actual type without adding safety. A `type` alias in Rust is transparent to the compiler — `type UserId = u64` and `type OrderId = u64` are interchangeable, so you can pass an `OrderId` where a `UserId` is expected without a compiler error. A newtype catches this at compile time. The tradeoff is more boilerplate (implementing `Display`, `From`, etc.), which is acceptable when the semantic distinction matters. The failure mode is swapping two semantically different values of the same type, which the compiler cannot catch.

**Do this:**
```rust
struct UserId(u64);
struct OrderId(u64);

fn get_user_orders(user_id: UserId) -> Vec<OrderId> {
    // Compiler rejects: get_user_orders(order_id)
    // ...
}
```

**Don't do this:**
```rust
type UserId = u64;
type OrderId = u64;

// Compiler accepts get_user_orders(order_id) — silent bug.
fn get_user_orders(user_id: UserId) -> Vec<OrderId> {
    // ...
}
```

**Exceptions:** `type` aliases are appropriate for shortening complex generics where no semantic distinction exists, e.g., `type Result<T> = std::result::Result<T, MyError>`.

---

### TYP-002: Prefer enums over boolean parameters

**Severity:** Suggestion

**Rule:** When a function takes a boolean parameter that controls behavior, consider replacing it with a two-variant enum. This is especially important when the function takes multiple boolean parameters.

**Rationale:** The kernel guide (§17) advises caution with `bool` in structures and function signatures. A call like `process(true, false)` at the call site is opaque — the reader must look up the function signature to understand what each boolean means. An enum like `Mode::Overwrite` is self-documenting. The tradeoff is slightly more code for the enum definition. The failure mode is a function call where the reader cannot determine the behavior without jumping to the definition.

**Do this:**
```rust
enum WriteMode {
    Append,
    Overwrite,
}

fn write_log(entry: &str, mode: WriteMode) {
    // Call site: write_log(&entry, WriteMode::Append)
    // — self-documenting
}
```

**Don't do this:**
```rust
fn write_log(entry: &str, overwrite: bool) {
    // Call site: write_log(&entry, true)
    // — what does `true` mean here?
}
```

**Exceptions:** A single boolean parameter with an obvious meaning (e.g., `set_visible(true)`) is acceptable.

---

## Data Structures

The kernel guide (§11) emphasizes that data structures visible outside a single-threaded context require reference counting. In Rust, the ownership system handles most of this automatically, but shared ownership still requires explicit decisions.

*Adapted from kernel §11.*

### DAT-001: Document shared ownership with `Arc`/`Rc`

**Severity:** Warning

**Rule:** When using `Arc` or `Rc`, add a comment explaining why shared ownership is necessary and which components share the reference. Prefer single ownership (`Box`, stack allocation, or passing references) when shared ownership is not required.

**Rationale:** The kernel guide requires reference counting for any structure visible outside a single-threaded environment and warns that getting it wrong causes use-after-free or memory leaks. Rust's `Arc`/`Rc` prevent use-after-free at compile time, but overusing them hides ownership relationships and can create reference cycles that leak memory. Each `Arc` is a statement that "multiple parts of the system need to independently own this value" — if that statement is false, the `Arc` adds unnecessary complexity and overhead. The failure mode is a codebase where everything is `Arc<Mutex<T>>` and nobody knows which component is responsible for what.

**Do this:**
```rust
/// Shared across the request handler and the background metrics collector,
/// both of which outlive individual requests.
let stats: Arc<Stats> = Arc::new(Stats::default());
```

**Don't do this:**
```rust
// Arc used without explanation — is sharing actually needed?
let config: Arc<Config> = Arc::new(load_config()?);
// If only one component uses config, Box or a reference suffices.
```

**Exceptions:** None.

---

## Macros

Rust macros are more hygienic than C macros, but they share the same fundamental problem: they generate code that does not look like the code the developer wrote. The kernel guide's warnings about macros that hide control flow and act as "disguised functions" apply with equal force.

*Adapted from kernel §12.*

### MAC-001: Do not hide control flow in macros

**Severity:** Error

**Rule:** Macros must not contain `return`, `break`, `continue`, or `?` that affect control flow in the calling function. A reader of the call site must be able to understand the control flow without expanding the macro.

**Rationale:** The kernel guide lists "macros that affect control flow" as a cardinal sin. When a macro invocation like `validate!(input)` secretly contains a `return Err(...)`, a reader scanning the function sees what looks like an expression but is actually an early return. This breaks the fundamental contract that control flow is visible at the call site. The failure mode is a bug caused by a macro returning early before a side effect that the developer assumed would always run.

**Do this:**
```rust
// The function body shows the control flow explicitly.
fn handle_request(req: &Request) -> Result<Response> {
    let input = parse_input(req)?;
    let validated = validate(input)?;
    Ok(process(validated))
}
```

**Don't do this:**
```rust
macro_rules! try_validate {
    ($input:expr) => {
        // Hidden return — callers cannot see this at the call site.
        match validate($input) {
            Ok(v) => v,
            Err(e) => return Err(e.into()),
        }
    };
}

fn handle_request(req: &Request) -> Result<Response> {
    let input = parse_input(req)?;
    let validated = try_validate!(input); // Looks like an expression, secretly returns
    Ok(process(validated))
}
```

**Exceptions:** None. The `?` operator is Rust's sanctioned way to do early-return error propagation; there is no reason to reinvent it in a macro.

---

### MAC-002: Prefer functions or generics over macros

**Severity:** Suggestion

**Rule:** Use declarative or procedural macros only when functions and generics cannot express the pattern. Common legitimate uses include: reducing boilerplate for trait implementations, compile-time code generation, and DSLs. If a macro could be a generic function, make it a generic function.

**Rationale:** The kernel guide says to use inline functions instead of macros that "resemble functions." Functions have typed parameters, appear in stack traces, and are understood by IDE navigation. Macros bypass all of this. The tradeoff is that some patterns (variadic arguments, code generation, compile-time string manipulation) genuinely require macros. The failure mode is a codebase where macros are used for convenience rather than necessity, and developers cannot navigate or debug the generated code.

**Do this:**
```rust
fn max<T: Ord>(a: T, b: T) -> T {
    if a >= b { a } else { b }
}
```

**Don't do this:**
```rust
// A macro where a generic function suffices.
macro_rules! max {
    ($a:expr, $b:expr) => {
        if $a >= $b { $a } else { $b }
    };
}
```

**Exceptions:** None.

**Related rules:** MAC-001.

---

## Standard Library

The kernel provides many utility macros and helpers (`ARRAY_SIZE`, `min`, `max`, `container_of`). The kernel guide (§18) says: don't reimplement them. Rust's standard library is richer, and the same advice holds — but extends to well-established crates in the ecosystem.

*Adapted from kernel §18.*

### STD-001: Do not reimplement standard library facilities

**Severity:** Warning

**Rule:** Use standard library types, traits, and functions rather than writing equivalent implementations. This extends to widely-used crates (`serde`, `log`/`tracing`, `thiserror`/`anyhow`, etc.) when the project already depends on them.

**Rationale:** A hand-rolled hash map or error type is unlikely to be as correct, as fast, or as well-tested as the standard library version. Every custom reimplementation is code that must be maintained, documented, and tested. The failure mode is a subtle bug in a hand-rolled utility that would never have occurred with the standard version — discovered in production, after months of use.

**Do this:**
```rust
use std::collections::HashMap;

let mut counts: HashMap<&str, usize> = HashMap::new();
for word in words {
    *counts.entry(word).or_insert(0) += 1;
}
```

**Don't do this:**
```rust
// Hand-rolled word counting with a Vec of tuples instead of HashMap.
let mut counts: Vec<(&str, usize)> = Vec::new();
for word in words {
    if let Some(entry) = counts.iter_mut().find(|(w, _)| *w == word) {
        entry.1 += 1;
    } else {
        counts.push((word, 1));
    }
}
```

**Exceptions:** Performance-critical paths where benchmarking demonstrates that a standard facility is a bottleneck. Document the benchmark results in a comment.

---

## Conditional Compilation

Rust uses `#[cfg(...)]` attributes and the `cfg!()` macro where C uses `#ifdef`. The kernel guide (§21) prefers constructs that the compiler can still type-check even when disabled, and the same principle applies in Rust.

*Adapted from kernel §21.*

### CFG-001: Prefer `cfg!()` over `#[cfg]` when the compiler can still type-check both paths

**Severity:** Suggestion

**Rule:** When both branches of a conditional compilation are valid Rust code, prefer using `cfg!()` in an `if` expression over `#[cfg]` attributes on separate blocks. This allows the compiler to type-check the dead branch even when the feature is disabled.

**Rationale:** The kernel guide recommends `IS_ENABLED()` in normal conditionals over `#ifdef` because the compiler can check code correctness in both branches. The same applies in Rust: `#[cfg(feature = "x")]` causes the annotated code to be completely invisible to the compiler when the feature is off. If someone renames a function or changes a type, the `#[cfg]`-gated code silently breaks and nobody discovers it until that feature is enabled. With `cfg!()`, both branches are compiled (the dead one is eliminated by the optimizer), so the compiler catches type errors in both. The tradeoff is that `cfg!()` requires both branches to be valid code, which is not always possible (e.g., when the gated code uses a type that only exists with the feature).

**Do this:**
```rust
fn log_level() -> Level {
    if cfg!(debug_assertions) {
        Level::Debug
    } else {
        Level::Info
    }
}
```

**Don't do this:**
```rust
// If a refactor changes Level::Debug to Level::Trace,
// this code silently breaks when debug_assertions is off.
#[cfg(debug_assertions)]
fn log_level() -> Level {
    Level::Debug
}

#[cfg(not(debug_assertions))]
fn log_level() -> Level {
    Level::Info
}
```

**Exceptions:** Use `#[cfg]` when the gated code depends on types, traits, or imports that only exist under the feature flag. In such cases, `cfg!()` cannot work because the dead branch would not compile.

---

## Exceptions Registry

### ERR-001-EX: `unwrap()` in tests and proven-safe contexts

**Rule:** ERR-001 (Prefer `Result` over `panic!` in library code)

**Exception:** `.unwrap()` and `.expect()` are acceptable in:
1. Test code (`#[cfg(test)]` modules and integration tests), where a panic is the correct failure behavior.
2. Contexts where the `None`/`Err` case has been structurally excluded by a preceding check (e.g., calling `.unwrap()` immediately after `.is_some()` or inside a branch that already matched the `Some`/`Ok` variant).
3. Program entry points (`main`) where there is no caller to propagate to and a panic with a message is a reasonable behavior.

**Rationale:** Requiring `Result` propagation in tests adds noise without benefit — a panicking test is a failed test, which is exactly what we want. In proven-safe contexts, the `unwrap` is effectively a static assertion. Requiring a redundant `match` or `if let` would add boilerplate without adding safety.

**Recognition pattern:** The call is inside a `#[test]` function, inside a `fn main()`, or immediately follows a conditional check that guarantees the value is `Some`/`Ok`.

**Example:**
```rust
#[test]
fn test_parse_config() {
    let config = parse_config(VALID_INPUT).unwrap(); // Acceptable in test
    assert_eq!(config.port, 8080);
}
```

---

### DOC-002-EX: Private helper functions

**Rule:** DOC-002 (All public items must have doc comments)

**Exception:** Private helper functions (not `pub`) are exempt from requiring doc comments if the calling public function documents the behavior. Private types, constants, and traits used only within a single module are also exempt.

**Rationale:** Requiring doc comments on every private helper increases maintenance burden without proportional benefit. The public function's doc comment is the contract consumers see; the private helper is an implementation detail. Over-documenting internals creates a maintenance burden where internal comments rot as the implementation evolves.

**Recognition pattern:** The function has no `pub` visibility modifier, or has `pub(crate)` / `pub(super)` visibility and is called only from functions that are themselves documented.

**Example:**
```rust
/// Parses a configuration file and returns the validated config.
///
/// Returns an error if the file is malformed or contains invalid values.
pub fn parse_config(input: &str) -> Result<Config, ConfigError> {
    let raw = parse_raw(input)?;       // private helper, no doc needed
    let validated = validate(raw)?;     // private helper, no doc needed
    Ok(validated)
}

fn parse_raw(input: &str) -> Result<RawConfig, ConfigError> {
    // ...
}

fn validate(raw: RawConfig) -> Result<Config, ConfigError> {
    // ...
}
```

---

### FUN-001-EX: Generated code and macro expansions

**Rule:** FUN-001 (Keep functions short)

**Exception:** Functions generated by macros (including derive macros and build scripts) are exempt from the line-length limit. Hand-written functions in modules annotated with a comment indicating they are generated (e.g., `// @generated`) are also exempt.

**Rationale:** Generated code optimizes for correctness and completeness, not human readability. Applying length limits to generated functions would either constrain the generator unnecessarily or create noise in code review for code that no human maintains directly.

**Recognition pattern:** The function is inside a `#[cfg(test)]` module generated by a framework, inside a file with a `// @generated` header, or produced by a `derive` macro.

---

## Changelog

### v1.0.0 — 2026-03-12

Initial release. Rules adapted from the [Linux kernel coding style v6.4](https://www.kernel.org/doc/html/v6.4/process/coding-style.html):

| Rule | Kernel origin |
|---|---|
| NAM-001 | §4 Naming |
| NAM-002 | §4 Naming |
| FUN-001 | §6 Functions |
| FUN-002 | §6 Functions |
| FUN-003 | §6 Functions |
| FUN-004 | §15 The inline disease |
| ERR-001 | §22 Do not crash the kernel |
| ERR-002 | §7 Centralized exiting of functions |
| ERR-003 | §16 Function return values and names |
| DOC-001 | §8 Commenting |
| DOC-002 | §8 Commenting |
| TYP-001 | §5 Typedefs |
| TYP-002 | §17 Using bool |
| DAT-001 | §11 Data structures |
| MAC-001 | §12 Macros, Enums and RTL |
| MAC-002 | §12 Macros, Enums and RTL |
| STD-001 | §18 Don't re-invent kernel macros |
| CFG-001 | §21 Conditional compilation |
