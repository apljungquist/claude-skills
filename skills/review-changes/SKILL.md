---
name: review-changes
description: Reviews the diff compared to the merge base
allowed-tools: Bash(git show:*), Read, Skill
disable-model-invocation: true
---

## Process

Consider the cumulative diff to the merge base:
```
git diff HEAD !`git merge-base origin/HEAD HEAD`
```
Report any deviations from the guidelines below.

It is not part of the code review to run any tests or static analysis.
Any problems that would be detected by the tests or the linter are out of scope for the code review.

Invoke all applicable language- or domain-specific reviewing skills (e.g., reviewing-rust-code) using the Skill tool before starting the review.
If a guideline has a code, include it in the output.

## Guidelines

When it comes to tests, quality matters more than quantity.

## Output Format

Use exactly this heading format per finding:
```
### {emoji} {number}: [{guideline-code}] `{file}:{line}`
```

Example:
```
### 🔴 1: [A003] `src/auth.rs:88`
```

If no existing _guideline-code_ applies, make up a descriptive identifier.
Always use the full 7-character commit hash.

The _emoji_ must be one of:
- 🟢 (Good)
- 🟡 (May fix)
- 🟠 (Should fix)
- 🔴 (Must fix)

Order the findings in ascending order of importance (most important last).
