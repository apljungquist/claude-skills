---
name: reviewing-information-placement
description: Reviews whether information is recorded in the right place
user-invocable: false
---

## Process

Review both the code and the commit message that introduces it.
For every fact recorded in either, ask whether it is in the right place.
For every fact a reader would need and cannot find, ask where it should have been.

Consult the rule index below.
For rules that seem applicable,
read the full rule file at `reference/<id>.md` (e.g., `reference/W001.md`).

## Routing Model

Two questions decide where a fact belongs.

**Does it outlive the change?**
A fact that is true of the code as it stands belongs with the code.
A fact that is true only of a transition belongs in the commit message.
Test: would this sentence make sense to a reader who has never seen a previous version of this file?
If not, it is about the change (W002, W004).

**Who needs it?**
Callers cannot see the function body, so facts they need go in `///` (W005).
Maintainers reading the body get `//`.
Operators get log events and error messages (W013).
People upgrading get the commit subject and the changelog (W011).

Where more than one destination would work,
prefer the one on which a lie is hardest to sustain.

| Destination                                                             | How a stale statement surfaces                            |
|-------------------------------------------------------------------------|-----------------------------------------------------------|
| Type system: newtype, enum, `#[non_exhaustive]`, typestate               | It cannot go stale; the compiler rejects the mismatch (W001) |
| `debug_assert!`                                                          | At runtime, in tests                                       |
| Doctest                                                                  | In CI (W007)                                               |
| `#[must_use = "…"]`, `#[deprecated(note = …)]`, `expect("… should …")`    | It does not surface, but the text is delivered at the moment of misuse (W008) |
| `///` doc comment                                                        | It does not surface, though the presence of `# Panics`, `# Errors`, and `# Safety` is lintable (W005) |
| `//` comment                                                             | It does not surface                                        |
| Commit message                                                           | It does not surface, and it also cannot be corrected (W003) |

The last row is the one most often misused.
A commit message is immutable,
which makes it a good record of a past event
and a bad home for a fact that must stay true.

### Two kinds of "why"

Splitting "why" is what makes the code/commit boundary decidable.

- **Why-still** — the reason is a property of the current code:
  a live upstream bug, a required ordering, a constraint that still binds.
  Test: if I deleted this tomorrow, would I be making a mistake?
  This goes at the code (W003).
- **Why-then** — the reason is a property of the change:
  alternatives rejected, measurements, the report that prompted it.
  Test: does the reason mention the old code?
  This goes in the commit body (W004).

## Rule Index

### Choosing the destination

- **[W001](reference/W001.md)** `encode-dont-document` — A fact stated in prose that the type system could enforce.
  Look for: units, ranges, or orderings described in doc comments; `bool` and primitive parameters; "call X before Y"; "do not construct directly".

- **[W003](reference/W003.md)** `rationale-at-the-fence` — Code that looks removable, whose reason for existing lives only in the commit message.
  Look for: explicit `drop`, `sleep`, retry counts, magic constants, `#[allow(...)]`, apparently redundant operations, deviations from the surrounding pattern.

- **[W004](reference/W004.md)** `transition-rationale-in-commit` — A non-trivial change whose problem, impact, and rejected alternatives are recorded nowhere.
  Look for: bodyless commits on non-mechanical changes; performance claims without numbers; messages that paraphrase the diff.

- **[W009](reference/W009.md)** `document-once` — The same fact written in more than one place, where the copies can diverge.
  Look for: crate docs restating `README.md`; commit bodies pasting the doc comment they added; paraphrases of external specifications.

### Comments and doc comments

- **[W002](reference/W002.md)** `change-relative-comment` — A comment that describes the code relative to a version that no longer exists.
  Look for: "new", "now", "previously", "used to", "no longer", "changed to", "as of", commented-out code, version-history blocks at the top of a file.

- **[W005](reference/W005.md)** `contract-in-doc-not-body` — A fact the caller must obey, written inside the function body where callers cannot see it.
  Look for: `//` comments stating preconditions; public functions that can panic without `# Panics`; public functions returning `Result` without `# Errors`.

- **[W006](reference/W006.md)** `safety-two-sided` — `# Safety` and `// SAFETY:` collapsed into one, or one of them missing.
  Look for: `unsafe fn` without `# Safety`; `unsafe` blocks without `// SAFETY:`; either one saying only "must be valid" or "this is safe".

- **[W007](reference/W007.md)** `example-over-prose` — Usage explained in prose the compiler never checks, where a doctest would be checked.
  Look for: public items describing a call sequence or argument shape with no `# Examples`; examples using `unwrap` instead of `?`.

- **[W008](reference/W008.md)** `guidance-in-attribute-messages` — A delivery mechanism that reaches the person misusing the API, left empty.
  Look for: bare `#[must_use]`, bare `#[deprecated]`, `expect` messages phrased as errors rather than expectations, `unwrap()` where a precondition could be stated.

### Commit messages and releases

- **[W011](reference/W011.md)** `commit-subject-is-a-changelog-entry` — A subject written for the reviewer rather than for the person reading release notes.
  Look for: "address feedback", "fix review", "wip"; public signature changes without `!` or a `BREAKING CHANGE:` footer; subjects naming files instead of effects.

### Destinations outside the source file

- **[W010](reference/W010.md)** `todo-links-issue` — A plan recorded in a marker that has no owner, no state, and no way to be closed.
  Look for: `TODO`, `FIXME`, `HACK`, `XXX` with no issue reference; markers carrying several sentences of plan.

- **[W012](reference/W012.md)** `cross-module-decision-needs-a-home` — A decision spanning modules, explained in one arbitrary file or in no file.
  Look for: rationale comments whose subject matter is not local to their file; the same rationale repeated across modules.

- **[W013](reference/W013.md)** `operator-info-in-logs` — What an operator needs during an incident, written as a comment they cannot read at runtime.
  Look for: comments describing retries, fallbacks, data loss, or restarts with no corresponding event; error types whose `Display` omits the identifying value.

## Rules That Live Elsewhere

This skill does not restate rules that already exist,
which is W009 applied to itself.
Consult these in `reviewing-rust-code`:

- **L033** `missing-invariant-assertion` — prose invariants that should also be a `debug_assert!`.
- **D010** `doc-contradicts-code` — a doc comment in the right place, saying the wrong thing.
- **D011** `stale-safety-comment` — a `// SAFETY:` comment that no longer matches its block.
- **D012** `stale-todo-or-fixme` — a marker whose work is already done.
- **D036** `suppressed-warning` — `#[allow(...)]` used instead of a fix.
- **D044** `comment-restates-code` — a comment at the same level of detail as the code.
- **D045** `missing-pub-doc-comment` — a public item with no `///` at all.
- **A047** `undocumented-shared-ownership` — `Arc`/`Rc` with no stated reason.

W-rules ask *where* a fact is recorded.
The rules above ask whether a fact is present, true, or worth stating.

## Out of Scope

Claude should not comment on the following:

- **Whether a statement is true.** This skill asks only where it is recorded.
- **Prose style, grammar, and spelling.**
- **Doc comment formatting** — handled by `rustfmt` and `clippy::doc_markdown`.
- **Whether a public item should exist** — that is API design.
- **Choice of issue tracker, changelog tool, or decision-record format.**
- **Generated files and vendored code.**
- **Test code** — relax W005 and W008 in `#[cfg(test)]` modules and `#[test]` functions.
