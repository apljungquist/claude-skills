# Authoring Skills

This document complements and,
where noted, overrides the official guides[^2][^3][^4][^5].

## SKILL.md

The SKILL.md file is the entry point for the skill.

**Frontmatter** follows the Agent Skills spec:

```yaml
---
name: reviewing-rust-code
description: Reviews Rust code
user-invocable: false
---
```

**Naming conventions** depend on how the skill is invoked.
Skills that allow model invocation should follow the official naming conventions[^1]:
use gerund form (verb + -ing) to describe the capability
(e.g., `reviewing-rust-code`, `processing-pdfs`, `analyzing-spreadsheets`).
Skills that are only user-invocable should instead use imperative form
(e.g., `review-branch`, `check-migrations`).

**Links to external documents** should use footnotes,
not inline links.
In the footnote definition, write the URL directly (`[^1]: https://...`),
not as a markdown link (`[^1]: [title](https://...)`).
This keeps the prose readable and groups URLs at the bottom of the file.

[^1]: https://platform.claude.com/docs/en/agents-and-tools/agent-skills/best-practices#naming-conventions
[^2]: https://agentskills.io/specification
[^3]: https://platform.claude.com/docs/en/agents-and-tools/agent-skills/best-practices#naming-conventions
[^4]: https://platform.claude.com/docs/en/agents-and-tools/agent-skills/overview#skill-structure
[^5]: https://code.claude.com/docs/en/skills