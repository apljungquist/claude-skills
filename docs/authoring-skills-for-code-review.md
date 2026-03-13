# Writing Review Guidelines

This guide describes how to write a review skill for Claude Code.
A review skill defines *what* to look for;
*how* to report belongs in a separate skill (e.g., a review-branch skill).
For a worked example, see `skills/reviewing-rust-code/`.
For general skill authoring guidelines, see `authoring-skills.md`.

## What This Guide Covers

A review skill consists of a SKILL.md file and a set of rule files.
Together they tell Claude what to look for during code review.

The audiences are:
- Claude, applying guidelines during review.
- Humans, writing and maintaining the guidelines.

The purpose of a review skill is **correctness and consistency**.
Guidelines promote practices that surface and prevent correctness issues.
Where correctness is not at stake,
they reduce friction by picking one option and applying it everywhere.

## Guideline Levels

Every guideline has a level: **rule** or **default**.

| Level   | RFC 2119 | Meaning                                               |
|---------|----------|-------------------------------------------------------|
| rule    | MUST     | Always follow. Violations are always flagged.         |
| default | SHOULD   | Follow unless there is a motivated reason to deviate. |

Use **rule** sparingly — only for guidelines where deviation is always wrong.
Use **default** for everything else.
When starting out, make everything a default and promote individually.

## Skill Structure

### SKILL.md

**Process section** tells Claude how to use the skill:

```markdown
## Process

Consult the rule index below.
For rules that seem applicable,
read the full rule file at `rules/<id>.md`.
```

**Guideline index** lists every guideline
with enough information to decide whether to read the full file.
Each entry follows this format:

    - **E003** `swallowed-error` — Error value silently discarded.
      Look for: `let _ =`, `.ok()`, `if let Ok` without else.

The "Look for" hints help Claude and humans quickly decide if a rule is relevant.

Group by topic or list flat — both are valid.
The letter prefix in IDs (E for Error handling, A for API, etc.)
provides implicit grouping even in a flat list.
If the skill has many guidelines,
grouping by topic under subheadings improves scannability.
For a small skill, a flat list is fine.

**Out of Scope section** lists topics the skill does not cover at all.
This prevents Claude from importing its own opinions
in areas the skill is silent on.

```markdown
## Out of Scope

Claude should not comment on the following:

- Formatting — handled by rustfmt.
- Import ordering — handled by tooling.
- Test code — relax rules E005, A024 in `#[cfg(test)]` modules.
```

Out of Scope is different from "When NOT to flag".
Out of Scope restricts the skill's global scope (topics it ignores entirely).
"When NOT to flag" lists situations where a specific guideline does not apply.
Both are needed, but they live in different places.

### Individual Guideline Files

Each guideline lives in its own file under `rules/`.

File naming: `rules/<id>.md` (e.g., `rules/E003.md`).
This keeps file names short,
which matters because the SKILL.md index already carries the slug and description.

ID format: `<letter><three-digit number>` (e.g., `E003`, `A007`).
The letter indicates the topic category.
The number is unique within the skill.

## Anatomy of a Guideline

Every guideline file follows this structure.

### Header

Use the ID and slug as the heading
(the slug appears here even though the file name omits it):

    # E003: swallowed-error

### Level

    **Level:** default

One of `rule` or `default`.

### Problem

    ## Problem

    An error value is silently discarded,
    hiding failures that should be logged, propagated, or handled.

Name the failure mode.
Describe concretely what goes wrong when the guideline is violated.

### Pros / Cons / Decision

````markdown
## Pros / Cons / Decision

**Pros of explicit error handling:**
- Failures become visible in logs and metrics.
- Callers can react to errors instead of silently continuing.

**Cons:**
- Adds verbosity for best-effort operations where failure is harmless.
- Requires choosing a handling strategy (log, propagate, ignore with comment).

**Decision:**
Require explicit handling for all errors
except documented best-effort operations.
````

This section replaces a bare "Rationale" field.
It forces the author to acknowledge tradeoffs honestly,
which builds trust with developers who push back on guidelines.
Both rules and defaults use this format.

### Example

````markdown
## Example

### Bad
```rust
// Err case silently ignored
let _ = fs::remove_file(&path);
```

### Good
```rust
if let Err(e) = fs::remove_file(&path) {
    log::warn!("Failed to clean up {}: {e}", path.display());
}
```
````

Use realistic code, not `foo`/`bar`.
Annotate what is wrong in the bad example.
Pair every bad example with a good one.

### When to Flag

    ## When to Flag

    - `let _ = expr` where `expr` returns `Result` and the error case matters.
    - `.ok()` used to discard an error rather than intentionally converting to `Option`.

Bullet points listing specific conditions.
Be explicit about decision boundaries —
Claude applies literally what you write.

### When NOT to Flag

    ## When NOT to Flag

    - `let _ =` on a `Result` where the operation is best-effort
      and a comment explains why.
    - `.ok()` used to genuinely convert to `Option` for `?` chaining.
    - Code is in a `Drop` implementation where panicking is not allowed.

These are inline exceptions for this specific guideline.
They prevent false positives that erode trust.

## Writing Tips

**Name the failure mode.**
"Functions should be short" is vague.
"Functions over 40 lines correlate with bugs
because nesting depth exceeds working memory" names what goes wrong.

**Use realistic code.**
`fetch_user_data()` gives Claude contextual signal.
`foo()` does not.

**Be explicit about decision boundaries.**
Instead of "avoid deeply nested conditionals",
write "a function over 40 lines of executable code
(excluding comments and blank lines) should be split."
Claude does not fill gaps with tacit knowledge.

**Annotate what is wrong in bad examples.**
Do not make the reader infer the problem.
A comment like `// Err case silently ignored` is enough.

**Pair every "don't" with a "do".**
Without the positive example,
the reader knows what to avoid but not what to write instead.

**One sentence per line.**
Commas are also good split points.
This makes diffs cleaner and review easier.
