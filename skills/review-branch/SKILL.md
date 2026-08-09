---
name: review-branch
description: Reviews the checked out branch before rebase merging
allowed-tools: Bash(git show:*), Read, Skill
disable-model-invocation: true
---

## Process

Consider each commit since !`git merge-base origin/HEAD HEAD` individually.
Report any deviations from the guidelines below.

It is not part of the code review to run any tests or static analysis.
Any problems that would be detected by the tests or the linter are out of scope for the code review.

Invoke the reviewing-information-placement skill,
and all applicable language- or domain-specific reviewing skills (e.g., reviewing-rust-code),
using the Skill tool before starting the review.
If a guideline has a code, include it in the output.

## Guidelines

Commit messages MUST adhere to [conventional commits](https://www.conventionalcommits.org/en/v1.0.0/).

The code and its comments MUST explain what the code does.

A reason that still binds — a constraint, a required ordering, a workaround for a live bug —
MUST be recorded at the code,
because that is where a maintainer stands when they decide to remove it.
Remember Chesterton's fence.

A reason that describes the change itself —
alternatives rejected, measurements, the report that prompted it —
MUST be documented in the commit message.

Conversely, every statement made in the commit message MUST be true, or at least falsifiable.

Deviations from existing patterns MUST be motivated in the PR description.

When it comes to tests, quality matters more than quantity.

## Output Format

Use exactly this heading format per finding:
```
### {emoji} `{commit-id}` [{guideline-code}] `{file}:{line}`
```

Example:
```
### 🔴 `a1b2c3d` [A003] `src/auth.rs:88`
```

If no existing _guideline-code_ applies, make up a descriptive identifier.
Always use the full 7-character commit hash.

The _emoji_ must be one of:
- 🟢 (Good)
- 🟡 (May fix)
- 🟠 (Should fix)
- 🔴 (Must fix)

When reviewing the commit message, use `.git/COMMIT_EDITMSG` as the _file_.

Order the findings in ascending order of importance (most important last).
