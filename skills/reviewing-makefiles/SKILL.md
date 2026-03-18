---
name: reviewing-makefiles
description: Reviews Makefiles
user-invocable: false
---

Makefiles are written to work with the `mkhelp` program:
- Lines starting with `##` are docstrings for the following recipe.
- Lines starting with `## _` are replaced with the name of the recipe in Camel case.
- Underlining a docstring line with `===` creates a section.
- Underlining a docstring line with `---` creates a subsection.

There are two sections of particular importance, verbs and nouns.
Nouns:
- SHOULD have no side effects
- MUST have no side effects on other nouns.
- MUST create the path that they reference

Verbs:
- MAY have side effects.
- MUST have a name starting with a verb
