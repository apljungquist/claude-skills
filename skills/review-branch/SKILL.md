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

Invoke all applicable language- or domain-specific reviewing skills (e.g., reviewing-rust-code) using the Skill tool before starting the review.
If a guideline has a code, include it in the output.

## Guidelines

Commit messages MUST adhere to [conventional commits](https://www.conventionalcommits.org/en/v1.0.0/).

The code and its comments SHOULD explain what it does, not why.
Every design decision that is not obvious from the code MUST be documented in the commit message.
Remember Chesterton's fence.

Conversely, every statement made in the commit message MUST be true, or at least falsifiable.

Deviations from existing patterns MUST be motivated in the PR description.

When it comes to tests, quality matters more than quantity.

## Output Format

List all issues in ascending order of importance (most important last).
The importance should be one of:
- 🟢 (Good)
- 🟡 (May fix)
- 🟠 (Should fix)
- 🔴 (Must fix)

Include only the traffic light, not the text.

Use this template:

```markdown
# Code Review

### <importance> `<commit-id>` <summary> `<file>:<line>`

<explanation of what the issue is>

<expanation of why it is important>

<suggestion for how to imrpove the code>
```
