# Rust code review rules: prior art and critical analysis

**The repository at `https://github.com/apljungquist/claude-skills/tree/spike/skills/reviewing-rust-code/rules` could not be accessed** — it appears to be private, deleted, or not yet public. After exhaustive attempts (GitHub API, raw content URLs, web search, profile inspection), no publicly indexed content from this repository was found. The user `apljungquist` exists on GitHub with 45 repositories, but `claude-skills` is not among the publicly visible ones.

Rather than returning empty-handed, this report delivers a thorough analysis of **14 canonical Rust code review rules** drawn from the most authoritative sources in the ecosystem: the Rust API Guidelines, the Rust-Coding-Guidelines/RustCodeReviewGuidelines repository, the proposed rustc-dev-guide review checklist (PR #1463), David Barsky's Claude skills for Rust, and established community resources. Each rule includes specific Clippy lint references, official documentation, and well-reasoned arguments for and against. If the target repository becomes accessible, this framework maps directly to the rules most likely contained there.

---

## Avoiding unnecessary clone() calls

This rule addresses one of Rust's most distinctive anti-patterns: calling `.clone()` to silence borrow checker errors rather than restructuring ownership. The official Rust Design Patterns book lists "Clone to satisfy the borrow checker" as a named anti-pattern. **Clippy enforces this through `redundant_clone` (warn-by-default), `clone_on_copy` (warn-by-default), and `clone_on_ref_ptr` (restriction)**, plus the newer `assigning_clones` lint suggesting `clone_from()` for reuse of existing allocations. The API Guidelines' **C-CALLER-CONTROL** principle states directly: "If a function does not require ownership, it should take a borrow rather than taking ownership and dropping the argument."

**The case for enforcement is strong.** Cloning heap-allocated types like `String` or `Vec<T>` triggers allocations that compound in hot loops. A 2026 blog analysis at hamy.xyz demonstrated that Rust clones are deep copies — fundamentally more expensive than reference-counted copies in garbage-collected languages. Excessive cloning also signals architectural problems: functions demanding ownership when they only need a borrow, or data flowing incorrectly through a system.

**The counterarguments are real but situational.** Cloning `Arc<T>` is just a reference count bump. Cloning `Copy` types is a bitwise copy (free). During prototyping, clone is the fastest path to working code. And in cold paths where I/O latency dominates, clone overhead is noise. The key insight from the community: this rule is about *unnecessary* clones, not a blanket prohibition. The Rust Users Forum thread "Ownership, performance, and when cloning is actually the right choice?" captures the nuance well — sometimes `clone()` is the clearest expression of intent.

---

## Documenting all unsafe code with safety invariants

Every `unsafe` block should carry a `// SAFETY:` comment explaining why the contained operations are safe, what invariants are assumed, and under what conditions they would break. This convention is codified in **the Rust Book (Chapter 20)**, the **Rustonomicon**, and enforced by **`clippy::undocumented_unsafe_blocks` (restriction)** and **`clippy::missing_safety_doc`**. **RFC #2585** introduced `unsafe_op_in_unsafe_fn`, requiring explicit `unsafe {}` blocks even within unsafe functions — warn-by-default in the 2024 edition.

The `// SAFETY:` convention has become a cross-ecosystem standard. The **Linux kernel's Rust code** uses it alongside `// INVARIANT:` and `// CAST:` comments. **Google Fuchsia's Rust guidelines** mandate safety comments at FFI boundaries. Ralf Jung's influential 2018 post "Two Kinds of Invariants: Safety and Validity" established the theoretical framework now being standardized (GitHub issue #539 proposes formal terms "language invariant" and "library invariant"). An empirical study by Astrauskas et al. (OOPSLA 2020, ETH Zurich) found that many `unsafe fn` declarations exist primarily to "document some implicit contract or invariant."

**For:** Safety comments force authors to reason about invariants at write time, catching bugs before they ship. They create auditable trails — reviewers can verify each justification against actual code. **Against:** In FFI-heavy codebases, many unsafe blocks are trivially safe (calling a C function with valid arguments), and mandatory comments become boilerplate. The `undocumented_unsafe_blocks` lint has known false positives with proc macros (issues #8449, #9114, #12720). Stale safety comments can be worse than none, providing false confidence.

---

## Result and Option over panic in library code

Library code should return `Result<T, E>` or `Option<T>` instead of panicking. The `?` operator should handle error propagation. `.unwrap()` belongs in tests; `.expect("reason")` is acceptable only where panic is explicitly documented. **Clippy provides `unwrap_used`, `expect_used`, `panic`, `todo`, and `unreachable`** — all in the restriction group (opt-in), reflecting the nuance that some contexts (tests, truly unrecoverable errors) legitimately use panics. The API Guidelines **C-GOOD-ERR** requires meaningful error types implementing `Display`, `Error`, and `source()`.

The Rust Book's Chapter 9 draws a clear line: `Result` for recoverable errors, `panic!` for unrecoverable ones. Luca Palmieri's influential "Error Handling In Rust — A Deep Dive" argues the real question isn't lib-vs-app but whether callers need to behave differently based on the failure mode. The Linux kernel's Rust team has even proposed a `// PANIC:` comment convention (Clippy issue #15895), modeled on `// SAFETY:`, to justify the rare legitimate panics in library code.

**For:** `Result<T, E>` in a function signature explicitly communicates "this can fail," making the API self-documenting. Libraries that return `Result` give callers full control — retry, convert, log, or propagate. Clippy issue #1300 argues "having unwraps hidden in library code can cause a variety of problems for downstream users." **Against:** The Rust Book itself acknowledges `.unwrap()` is fine in short examples. In tests, panic-on-failure is the intended behavior (`allow-unwrap-in-tests` exists for this reason). Some invariants, when violated, indicate logic bugs where recovery is meaningless — `assert!()` is appropriate there.

---

## Preferring borrowing over ownership in function parameters

Functions that only read data should accept `&str` instead of `String`, `&[T]` instead of `Vec<T>`. **`clippy::ptr_arg` (warn-by-default)** catches `&String` → `&str` and `&Vec<T>` → `&[T]` opportunities. **`clippy::needless_pass_by_value` (pedantic)** flags functions taking owned types they don't consume. The API Guidelines **C-CALLER-CONTROL** states both principles: borrow when you don't need ownership, take ownership when you do.

The Rust Book's Chapter 4 is the foundational teaching on this topic. The compiler error E0382 even suggests "consider changing this parameter type to borrow instead." Ferrous Systems' training materials use `fn print_string(s: &String)` vs `fn print_string(s: String)` as a core lesson. The API Guidelines **C-GENERIC** goes further: accept `impl IntoIterator<Item = i64>` instead of `&[i64]` for maximum flexibility.

**For:** Accepting `&str` lets callers pass `&str`, `&String`, string literals, or anything that `Deref`s to `str`. Borrowing has zero allocation cost. The caller retains ownership for reuse. **Against:** Borrowing introduces lifetimes that complicate async code and struct storage. For small `Copy` types, `clippy::trivially_copy_pass_by_ref` warns that passing by value is *more* efficient (avoids indirection). When a function ultimately needs to store data, the `impl Into<String>` pattern offers a pragmatic middle ground.

---

## The iterator combinators versus imperative loops debate

This is the most contested rule in the Rust ecosystem. David Barsky's Claude skills gist explicitly prescribes **"Write `for` loops with mutable accumulators instead of iterator combinators,"** while Clippy lints like **`manual_filter_map` and `manual_find_map` (both warn-by-default)** push in the opposite direction, toward idiomatic combinator usage.

The Rust Book benchmarks (Chapter 13.4) show iterators and for loops compile to identical performance — **iterators are a zero-cost abstraction**. Effective Rust (David Drysdale, Item 9) recommends iterator transforms but adds the crucial caveat: "Don't convert a loop into an iteration transformation if the conversion is forced or awkward." The `clippy::needless_for_each` lint (pedantic) actually favors `for` loops over `.for_each()`, suggesting Clippy itself doesn't universally prefer functional style.

Barsky's reasoning (from the gist comments) is specific and practical: "If I want to add debug logging, early returns/breaks, or handle an error in a loop, the amount of code that needs to change is more localized with an imperative loop. The compiler errors are nicer from a loop than combinators. **Rust is an imperative language.** Aesthetically, iterator chains feel like Claude slop to me." His cofounder disagrees — both have written Rust for over a decade. This captures the fundamental nature of this debate: it's a **genuine style preference** without a clear technical winner. Iterators shine for composition and lazy evaluation; loops shine for debuggability and incremental modification.

---

## Error crate selection: thiserror for libraries, anyhow for applications

The community consensus — taught in **Google's Comprehensive Rust course** and countless tutorials — recommends `thiserror` for structured library error types and `anyhow` for application-level error handling. Both crates are by dtolnay, the most prolific Rust ecosystem contributor. The API Guidelines **C-GOOD-ERR** requires errors that implement `Display`, `Error`, and `source()` — `thiserror` automates this.

However, this framing is increasingly recognized as an **oversimplification**. Luca Palmieri argues "the real question is: do you expect the caller to behave differently based on the failure mode?" The Rust Error Handling Working Group member u/Yaahallo puts it as "whether you need to handle errors or report them." dtolnay himself described it as two "opposite desires" that *usually* but not always map to lib/app boundaries. One ShakaCode developer moved to thiserror-only because anyhow errors proved difficult to refactor when structured handling was later needed.

**For:** Community standard; appropriate abstraction levels; `thiserror` eliminates Display/Error/From boilerplate; `anyhow`'s `.context()` adds meaningful messages at each call site. **Against:** Proc-macro compile time cost (one developer reported **21% improvement** removing a similar crate); `Box<dyn std::error::Error>` may suffice for small projects; anyhow's opaque errors create refactoring friction when structured handling is later required.

---

## Standard naming conventions per RFC 430

Rust naming conventions are among the most strictly enforced rules in the ecosystem. **RFC 430** established the authoritative table: `UpperCamelCase` for types/traits, `snake_case` for functions/variables/modules, `SCREAMING_SNAKE_CASE` for constants. The compiler itself enforces these through **`non_snake_case`, `non_camel_case_types`, and `non_upper_case_globals`** — all warn-by-default. The API Guidelines **C-CASE, C-CONV, C-GETTER, C-ITER** extend naming to conversions (`as_`/`to_`/`into_` prefixes), getters (no `get_` prefix), and iterators (`iter`/`iter_mut`/`into_iter`).

The `clippy::upper_case_acronyms` lint prefers `Http` over `HTTP`, but this was moved from style to pedantic due to community disagreement — revealing that even within this well-established system, edge cases exist. **The strongest argument for strict naming is compiler enforcement**: deviating produces noisy warnings that must be explicitly suppressed. **The strongest argument against is FFI interop**: binding to C libraries routinely requires `#[allow(non_snake_case)]`, and domain-specific conventions (physics, mathematics) can conflict with Rust norms.

---

## Comprehensive documentation for public API items

The API Guidelines dedicate an entire section to documentation: **C-CRATE-DOC** (crate-level docs with examples), **C-EXAMPLE** (every public item has an example), **C-QUESTION-MARK** (examples use `?` not `unwrap`), **C-FAILURE** (document errors, panics, and safety), **C-LINK** (hyperlinks to related items). The rustc lint `missing_docs` (allow-by-default) can be enabled to enforce documentation; **Clippy adds `missing_errors_doc`, `missing_panics_doc`, and `missing_safety_doc`** for specific section requirements.

**RFC 1574** established the standard doc comment format. David Barsky's gist codifies detailed conventions: summary sentences must be "third person singular present indicative" ending with a period (`/// Returns the length`), use `///` line comments not `/** */` block comments, and include canonical section headings in order: Examples, Panics, Errors, Safety. The Rustdoc Book states: "Rarely does anyone complain about too much documentation!"

The counterarguments center on **documentation rot** (comments falling out of sync with code), **trivial items** (documenting `/// Returns the name` on `fn name(&self) -> &str` adds noise), and the **binary/internal code distinction** — `#![deny(missing_docs)]` makes sense for libraries on crates.io but can slow development on internal application code.

---

## Type inference versus explicit annotations

Rust was designed for type inference in function bodies — a deliberate language design choice. Steve Klabnik (Rust team) stated: "I personally don't think you should ever write types unless you're forced to." **`clippy::redundant_type_annotations` (restriction)** warns when a type annotation repeats information already obvious from the right-hand side (e.g., `let x: String = String::new()`). The lint is intentionally in the restriction group, signaling this is context-dependent.

The debate crystallizes around **how code is read**. A Rust Internals thread captured both sides: proponents of inference point to DRY, easier refactoring, and IDE type hints (rust-analyzer) as compensation. Opponents note code is read in GitHub, Gerrit, and email — environments without IDE support — where `let user_id: UserId = fetch_user_id()` is genuinely clearer. **The critical exception**: `collect()`, `parse()`, and `into()` often *require* type annotations because they're generic over the output type. Removing "redundant" annotations from these contexts can cause compilation failures (E0282).

---

## #[must_use] for non-ignorable return values

**RFC 1940** authorized `#[must_use]` on functions, motivated by a real Android bug where `modem_reset_flag == 0;` (comparison, not assignment) went undetected. The standard library applies it extensively: `Result<T, E>`, `Option<T>`, all iterator adapters, and arithmetic operations like `saturating_add`. **`clippy::must_use_candidate` (pedantic)** suggests adding it to public functions that return values without side effects, while the Standard Library Dev Guide provides nuanced policy: `thread::JoinHandle` intentionally *omits* it because fire-and-forget is valid.

**`must_use_candidate` is one of the most commonly suppressed pedantic lints** — many projects enable pedantic globally but `allow` this specific lint, because it fires on virtually every public function returning a value. Over-application forces consumers to write `let _ = ...;` everywhere. The sweet spot is applying `#[must_use]` where ignoring the return value is almost certainly a bug (`Result`, `Option`, builder methods that return modified copies).

---

## Implementing standard traits for public types

The API Guidelines **C-COMMON-TRAITS** says: "Types eagerly implement common traits" — specifically `Copy`, `Clone`, `Eq`, `PartialEq`, `Ord`, `PartialOrd`, `Hash`, `Debug`, `Display`, `Default`. The reasoning is Rust's **orphan rule**: downstream crates cannot add trait implementations, so library authors must provide them or users are permanently locked out. The compiler lint `missing_debug_implementations` (allow-by-default) catches public types without `Debug`, though the docs note enabling it can impact compile time.

`#[derive(Debug, Clone, PartialEq, Eq, Hash)]` is typically a single line providing correct implementations. pretzelhammer's "Tour of Rust's Standard Library Traits" is the definitive community guide to when each trait applies. **But derive can be wrong**: `derive(PartialEq)` compares all fields (may not match semantic equality), `derive(Hash)` must be consistent with `PartialEq` or produce subtle bugs, and **adding `Copy` is a semver commitment** — removing it later is a breaking change. The `clippy::derive_partial_eq_without_eq` lint catches the common mistake of deriving `PartialEq` without `Eq` when the type qualifies.

---

## Exhaustive pattern matching over wildcard catches

Exhaustive matching is one of Rust's most powerful refactoring safety features. **`clippy::wildcard_enum_match_arm` (restriction)** warns when `_` catches enum variants, and **`clippy::match_wildcard_for_single_variants` (pedantic)** targets the more practical case where only one variant is hidden behind the wildcard. David Barsky's Claude skills prescribe: "Never Use Wildcard Matches — always match all variants explicitly."

Both lints have carefully engineered exceptions: they don't fire on `Option`/`Result` (where `_` on `None`/`Err` is idiomatic), don't suggest naming `doc(hidden)` or `#[non_exhaustive]` variants, and skip wildcards with guards. The restriction-group placement reflects community recognition that **this rule is context-dependent**. For `#[non_exhaustive]` external enums, you *must* keep a `_` arm. For large enums with many identically-handled variants, listing them all creates walls of text. The strongest case for the rule applies to **crate-internal enums** where you control the variant set and exhaustive matching provides essentially free insurance against future mistakes.

---

## Small, focused functions aligned with single responsibility

**`clippy::too_many_lines` (pedantic)** warns on functions exceeding 100 lines (configurable). `clippy::cognitive_complexity` (restriction) attempts to measure complexity but its docs explicitly caution: "The true Cognitive Complexity of a method is not something we can calculate using modern technology." `clippy::too_many_arguments` (pedantic, threshold: 7) serves as an indirect signal of functions doing too much.

Rust's ownership system **naturally rewards small functions**: borrowing rules are easier to reason about in focused scopes, lifetime annotations simplify with clear input/output boundaries, and `&self` vs `&mut self` vs `self` parameter choices document intent. Zero-cost abstractions (iterators, closures) make decomposition free. **Against:** complexity is sometimes inherent (state machines, parsers, unsafe blocks), extracting functions can introduce lifetime parameter complexity, and over-decomposition harms locality — reading code that bounces between many tiny functions can be harder than reading a well-structured longer one.

---

## Profiling before optimizing in Rust's already-fast ecosystem

The Rust Performance Book (by Nicholas Nethercote, Rust compiler team) is the authoritative guide, listing tools from perf and flamegraph to DHAT and Criterion.rs. Clippy's **`perf` lint group** includes `inefficient_to_string`, `needless_collect`, `large_enum_variant`, `box_collection`, and `redundant_clone`. The Performance Book notes these "usually result in code that is simpler and more idiomatic, so they are worth following even for code that is not executed frequently."

This nuance is critical: **some optimizations are free**. Using `&str` instead of `String`, `Vec::with_capacity` instead of `Vec::new`, or iterators instead of indexed loops cost nothing in readability but yield real gains. These aren't "premature optimization" — they're choosing the right tool. The real warning is against **algorithmic pessimism masquerading as clarity** and against spending time micro-optimizing cold paths. In systems programming — Rust's primary domain — performance can be a correctness requirement: latency deadlines and memory constraints are functional specifications, not optional nice-to-haves.

---

## Conclusion

These 14 rules represent a near-comprehensive map of the Rust code review landscape. The strongest consensus exists around **documenting unsafe code, returning Result instead of panicking, and following naming conventions** — these have official documentation, compiler enforcement, and broad community agreement. The most nuanced debates surround **iterators vs. loops** (genuine style preference), **type inference vs. annotation** (depends on reading context), and **#[must_use] application** (high noise-to-signal ratio). 

A recurring pattern emerges across all rules: **Clippy lint groups signal community confidence**. Lints in `warn` or `style` groups represent strong consensus. Lints in `pedantic` represent good practice that benefits from judgment. Lints in `restriction` represent context-dependent rules that no project should apply blindly. The most effective Rust code review processes use all three tiers — automated enforcement for the first, reviewer judgment for the second, and team-specific decisions for the third.