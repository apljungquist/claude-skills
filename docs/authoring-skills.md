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
Skills that allow model invocation (`user-invocable: false` or both)
should follow the official naming conventions[^1].
Skills that are only user-invocable should have names that sound like commands
(e.g., `review-branch`, `check-migrations`).

[^1]: [Agent Skills — Naming Conventions](https://platform.claude.com/docs/en/agents-and-tools/agent-skills/best-practices#naming-conventions)
[^2]: [Agent Skills Specification](https://agentskills.io/specification)
[^3]: [Agent Skills — Best Practices](https://platform.claude.com/docs/en/agents-and-tools/agent-skills/best-practices#naming-conventions)
[^4]: [Agent Skills — Skill Structure](https://platform.claude.com/docs/en/agents-and-tools/agent-skills/overview#skill-structure)
[^5]: [Claude Code — Skills](https://code.claude.com/docs/en/skills)