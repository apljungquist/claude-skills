---
name: review-commits
description: Reviews each commit since the merge base individually
allowed-tools: Bash(git show:*), Read, Skill
disable-model-invocation: true
---

## Process

Consider each commit since !`git merge-base origin/HEAD HEAD` individually.
Report any deviations from the guidelines below.

It is not part of the code review to run any tests or static analysis.
Any problems that would be detected by the tests or the linter are out of scope for the code review.

Invoke all applicable language- or domain-specific reviewing skills (e.g., reviewing-rust-code) using the Skill tool before starting the review.
If a guideline has a code, include it in the output.

## Guidelines

Commit messages MUST adhere to [conventional commits](https://www.conventionalcommits.org/en/v1.0.0/).

Every design decision that is not obvious from the code MUST be documented in the commit message.
Remember Chesterton's fence.

Conversely, every statement made in the commit message MUST be true, or at least falsifiable.

Deviations from existing patterns MUST be motivated in the PR description.

When it comes to tests, quality matters more than quantity.

## Output Format

Use exactly this heading format per finding:
```
### {emoji} {number}: `{commit-id}` [{guideline-code}] `{file}:{line}`
```

Example:
```
### 🔴 1: `a1b2c3d` [A003] `src/auth.rs:88`
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
