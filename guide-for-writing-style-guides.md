# A Guide to Writing Style Guides
### For use as the basis of a Claude code review skill

---

## Preface: Why This Guide Exists

Most style guides are written for human readers who can tolerate ambiguity, fill gaps with judgment, and ask questions when confused. A style guide that will power an AI code reviewer has different requirements. Claude will apply your rules consistently and literally — which is a superpower when rules are well-specified, and a liability when they are vague, contradictory, or missing context.

This guide will help you write a style guide that is:

- **Actionable by Claude** — rules are specific enough to be applied without human interpretation
- **Trustworthy to developers** — every rule comes with a rationale, so feedback feels principled rather than arbitrary
- **Maintainable** — structured in a way that scales from solo project to open-source team without rewriting

---

## Part 1: Philosophy

### The fundamental purpose of a style guide is consistency, not correctness

There is rarely one objectively correct way to write code. The value of a style guide is not that it always picks the best option — it's that it picks *one* option and applies it everywhere. A codebase with consistent "good enough" conventions is far easier to work in than one with inconsistent "optimal" choices made by six different people.

This matters when writing your guide because it frees you from the trap of trying to justify every rule as objectively superior. Sometimes the honest rationale is: "We chose this because we had to choose something, and this is what we chose."

### A style guide is a social contract, not a law

For a solo project, your style guide is a promise to your future self. For a team, it is a shared agreement that reduces friction during code review. For an open-source project, it is onboarding documentation and a statement of values.

All three framings matter even when you start solo — because the document you write today will be read by collaborators tomorrow.

### Claude applies the spirit of rules, not just the letter — if you give it the spirit

When Claude reviews code, it does more than pattern-match against rules. If you write a rule like *"avoid deeply nested conditionals"* and also explain *"because nesting depth correlates strongly with cognitive load and makes control flow hard to reason about"*, Claude will flag a function with four levels of nesting even if your rule only says "two levels maximum." The rationale expands the effective coverage of the rule.

If you write only the rule, Claude applies only the rule — and misses the spirit.

---

## Part 2: Document Structure

A style guide for Claude code review should have the following top-level structure:

### 1. Preamble

State what the guide covers, what it does not cover, and what language or domain it applies to. Also state any overriding meta-principles (e.g. "optimize for readability" or "correctness over cleverness") that Claude should use when two rules conflict or when a situation falls outside the guide.

**Example:**
```
This guide covers Python code in the `src/` directory of this project.
It does not cover infrastructure scripts, notebooks, or generated code.

Overriding principle: when in doubt, prefer the option that is easier
to understand when reading the code six months from now.
```

### 2. Severity Taxonomy

Define your severity levels explicitly before listing any rules. Every rule must be tagged with a severity. This tells Claude when to block, when to suggest, and when to simply note.

A recommended three-tier taxonomy:

| Level | Name | Claude behavior | Human meaning |
|---|---|---|---|
| 1 | **Error** | Always flag; block merge | This violates correctness or safety |
| 2 | **Warning** | Always flag; request change | This violates the style contract |
| 3 | **Suggestion** | Flag once; do not repeat | This is an improvement, not a requirement |

You may add a fourth level, **Note**, for informational observations Claude should surface at most once per review session (e.g. "this pattern is deprecated but not yet migrated").

### 3. Rule Sections

Group rules by topic. Common groupings:

- Naming conventions
- Formatting and whitespace
- Comments and documentation
- Function and module structure
- Error handling
- Testing
- Language-specific idioms

Each section should begin with a one-paragraph summary of its governing philosophy, followed by individual rules.

### 4. Exceptions Registry

A dedicated section listing known legitimate exceptions to rules, and how Claude should recognize them. This prevents false positives that erode trust in the reviewer.

### 5. Out of Scope

Explicitly list things Claude should not flag. This section is as important as the rules themselves.

### 6. Changelog

Date-stamped entries noting what changed and why. Even for a solo project, this is valuable — you will forget why you added a rule.

---

## Part 3: Anatomy of a Rule

Every rule in your style guide should contain the following components. Think of this as a schema.

### Required fields

**ID**
A short, stable identifier. Use it to reference rules in the changelog, in code comments, and in exceptions. Example: `NAM-001`, `ERR-003`.

**Title**
A short, scannable label. One sentence or less. Written as an imperative. Example: *"Use snake_case for all variable names."*

**Severity**
One of the levels defined in your taxonomy. Example: `Warning`.

**Rule statement**
The rule itself, stated precisely. Avoid words like "generally", "usually", "often" — these introduce exactly the ambiguity you are trying to eliminate. If exceptions exist, do not mention them here; address them in the Exceptions Registry.

**Rationale**
Why this rule exists. This is the most important component. See Part 4 for how to write rationale well.

**Examples**
At minimum, one "do this" and one "don't do this" example. See Part 5 for how to write examples well.

### Optional fields

**Autofix**
If this rule can be automatically fixed (by a formatter, linter, or Claude), note how. This helps distinguish rules that need judgment from rules that are purely mechanical.

**Related rules**
Cross-references to rules that interact with this one. Especially useful for rules where applying one in isolation might appear to violate another.

**Since**
The date or version this rule was introduced. Useful for teams migrating existing code.

### Example of a complete rule entry

```
ID: DOC-002
Title: Every public function must have a docstring.
Severity: Warning

Rule:
All functions, methods, and classes that are importable from outside
their defining module must have a docstring. Docstrings must describe
what the function does, not how it does it. Parameters and return
values must be documented if their type or purpose is not obvious from
the signature.

Rationale:
Public APIs are used by callers who cannot see the implementation.
Docstrings are the first line of documentation — IDEs surface them on
hover, and tools like Sphinx generate reference docs from them. A
function without a docstring forces callers to read the implementation
to understand the contract, which defeats the purpose of an API
boundary. "Not obvious from the signature" is intentionally subjective:
when in doubt, document it. Over-documentation is far less costly than
under-documentation.

Do this:
    def calculate_discount(price: float, tier: str) -> float:
        """
        Return the discounted price for a given customer tier.

        Args:
            price: The pre-discount price in USD.
            tier: One of 'standard', 'preferred', or 'vip'.

        Returns:
            The discounted price. Returns the original price if
            the tier is unrecognized.
        """
        ...

Don't do this:
    def calculate_discount(price: float, tier: str) -> float:
        # applies the discount
        ...

Exceptions: See DOC-002-EX in the Exceptions Registry.

Related rules: NAM-005 (parameter naming), TST-001 (test functions
are exempt from this rule).

Since: 2024-01-15
```

---

## Part 4: Writing Rationale

Rationale is the hardest part to write and the most important part to get right. Here is how to do it well.

### State the problem the rule solves, not just the solution

Weak rationale: *"We use snake_case because it is the Python convention."*

Strong rationale: *"We use snake_case because Python's standard library uses it, most third-party packages use it, and mixing conventions within a single codebase creates cognitive load when reading code. camelCase is not wrong — it is just different in a way that requires readers to context-switch."*

The first version tells Claude to enforce the rule. The second version tells Claude *why* it matters, which enables Claude to recognize when the spirit of the rule applies even in cases not directly covered.

### Acknowledge tradeoffs honestly

No rule is costless. Acknowledging tradeoffs builds trust with developers who push back on rules and makes the guide more credible overall.

*"This rule requires more boilerplate in small scripts where the types are obvious. We accept that cost because the codebase also contains complex modules where the documentation is essential, and we prefer a consistent standard across both."*

### Distinguish convention from correctness

Some rules prevent bugs or security issues. Others are purely aesthetic conventions. A developer deserves to know the difference.

*"This rule is a correctness requirement — the alternative can cause silent data loss under specific conditions. See [link] for a detailed example."*

vs.

*"This rule is a convention. Both approaches are correct; we chose this one for consistency."*

### Name the failure mode

The most compelling rationale describes concretely what goes wrong when the rule is violated.

*"Without explicit error handling here, exceptions propagate to the top-level handler, which logs them and continues. This means a failed payment attempt is silently swallowed and the user sees no error. The failure mode is invisible to both the user and the developer until a support ticket surfaces it days later."*

### Keep it proportionate

A formatting rule (trailing whitespace) does not need three paragraphs of rationale. A rule about exception handling does. Match the depth of rationale to the importance of the rule. If you find yourself unable to write a meaningful rationale for a rule, ask whether the rule is worth having.

---

## Part 5: Writing Examples

Examples do the work that rule statements cannot. A rule that seems clear in prose often has surprising edge cases that only a concrete example can resolve.

### Rules for writing examples

**Show the full context, not just the violation.** A single line showing `x = x + 1` is less useful than a three-line snippet showing why this is a problem in context.

**Annotate what is wrong.** Do not make Claude infer the problem. Mark it explicitly.

```python
# ❌ The except clause is too broad — swallows all exceptions including
#    KeyboardInterrupt, which prevents the user from stopping the process.
try:
    result = process(data)
except:
    log.error("processing failed")

# ✅ Catch only the exceptions you expect and know how to handle.
try:
    result = process(data)
except ProcessingError as e:
    log.error("processing failed: %s", e)
```

**Include edge cases for complex rules.** If a rule has a non-obvious boundary case, show it explicitly rather than leaving it as an exercise.

**Use realistic code, not toy examples.** `foo()` and `bar()` give Claude no contextual signal. `fetch_user_data()` and `validate_payment()` do.

**Pair every "don't do this" with a "do this."** Without the positive example, a developer reading the guide doesn't know what to do instead — they only know what not to do.

---

## Part 6: The Exceptions Registry

Exceptions are where style guides most commonly fail. Either they have no exceptions and generate false positives that erode trust, or they have undocumented implicit exceptions that create inconsistency.

### Structure of an exception entry

```
ID: DOC-002-EX
Rule: DOC-002 (Every public function must have a docstring)

Exception: __init__ methods that do nothing except assign constructor
arguments to instance variables are exempt if the class itself has a
docstring that describes its parameters.

Rationale: Repeating the class-level parameter documentation in the
__init__ docstring adds no information and creates a maintenance burden
(two places to update when a parameter changes).

Recognition pattern:
The __init__ body consists only of self.x = x assignments.
The class has a docstring that documents all parameters.

Example:
    class Config:
        """
        Application configuration.

        Args:
            host: The server hostname.
            port: The server port.
        """
        def __init__(self, host: str, port: int):
            self.host = host    # ✅ No __init__ docstring needed
            self.port = port
```

### Common categories of exceptions to plan for

- **Generated code** — parsers, serializers, ORM migrations. Often violates formatting rules; should be excluded by path pattern.
- **Test code** — tests often have different naming, documentation, and structure requirements. Consider whether your rules apply equally or need a separate test-code section.
- **Vendored code** — third-party code copied into the repository. Should be excluded from all style enforcement.
- **Performance-critical paths** — some optimizations require idioms that a style guide would normally discourage. Document these explicitly so Claude doesn't flag them.
- **Legacy code under migration** — if you're gradually migrating to a new convention, document which paths are excluded and until when.

### How to tell Claude to handle exceptions

The Exceptions Registry should explicitly instruct Claude on detection: what signals in the code indicate that an exception applies. Without this, Claude cannot recognize the exception and will generate false positives.

---

## Part 7: The "Out of Scope" Section

This section prevents Claude from commenting on things you did not intend to govern. Without it, Claude may import its own opinions in areas your guide is silent on.

### What to include

- Topics you consciously decided not to govern (e.g. "we do not have rules about logging format; use your judgment")
- Decisions delegated to other tools (e.g. "formatting is handled entirely by Black; Claude should not flag formatting issues that Black would fix automatically")
- Architectural decisions that belong in a separate document (e.g. "questions of module structure and dependency injection are out of scope for this guide")
- Code paths that are excluded from review (e.g. "the `migrations/` directory is excluded")

### Example

```
## Out of Scope

The following are explicitly out of scope for this style guide.
Claude should not comment on these topics during code review.

- Line length and indentation. These are enforced by the Black
  formatter. Running `make format` before committing resolves all
  such issues automatically.

- Import ordering. Enforced by isort.

- Database schema design. Covered separately in the architecture
  decision records in `docs/adr/`.

- Code in `tests/fixtures/` — these files are generated and should
  not be reviewed for style.

- Performance micro-optimizations. Claude should not suggest
  optimizations unless they relate to a known correctness issue.
```

---

## Part 8: Writing for Multiple Audiences

If your guide may be used by solo developers, small teams, *and* open-source contributors, structure it to serve all three without creating a confusing document.

### The layered approach

Organize rules into tiers based on their universality:

**Core rules** — apply to all code in all contexts. Every contributor, regardless of experience level, must follow these. Keep this list short. If everything is a priority, nothing is.

**Team rules** — apply to team members with commit access. May require more context or judgment to apply correctly.

**Community rules** — guidelines for external contributors. These should be the most lenient and the most clearly explained, because contributors have the least context about the project.

### What changes between audiences

| Dimension | Solo | Team | Open source |
|---|---|---|---|
| Rule count | Whatever you need | Moderate — only rules you'll actually enforce | Fewer — enforce only what matters to the project |
| Rationale depth | Can be brief — you already know why | Should be thorough — new members need context | Must be thorough — strangers need to trust the rule |
| Tone | Imperative is fine | Collaborative ("we" language) | Educational — treat every reader as a newcomer |
| Exceptions | Can be informal | Should be documented | Must be documented with examples |
| Enforcement | Claude + your memory | Claude + human review | Claude + CI + documented process |

### A practical approach

Write the guide as if it's for open-source from the start. This forces you to be explicit, which benefits you as a solo developer (you'll thank yourself in six months) and scales naturally to teams. Then add a section at the top that says "if you're a core contributor, read everything; if you're an external contributor, start with [section X]."

---

## Part 9: Structuring for Claude Specifically

A style guide used by a human reviewer can be vague in places — humans ask for clarification, notice when something doesn't feel right, and apply accumulated judgment. Claude does not fill gaps with tacit knowledge. Here are specific techniques for making your guide Claude-readable.

### Be explicit about decision boundaries

Instead of: *"Functions should be short."*

Write: *"Functions should not exceed 40 lines of executable code (excluding comments and blank lines). A function over 40 lines is a Warning; a function over 80 lines is an Error."*

### Tell Claude when to aggregate vs. when to flag individually

Some rules produce a lot of noise if flagged on every instance. Tell Claude how to handle this.

*"Flag the first three instances of this violation in a review. After three, add a summary note that there are additional instances and suggest a project-wide fix."*

### Define what counts as a violation

Ambiguous terms create inconsistent behavior. Define them.

*"A 'magic number' is any numeric literal other than 0, 1, or -1 used in a non-trivially-obvious context. Indices into a known-length tuple are not magic numbers. Configuration thresholds are magic numbers."*

### Specify Claude's feedback style

Tell Claude how to phrase feedback, not just what to flag.

*"For Error-level violations, Claude should explain the specific problem, quote the offending code, and provide a corrected version. For Warning-level violations, Claude should explain the violation and suggest a fix but not write the code. For Suggestions, Claude should describe the improvement and explain the benefit, without rewriting the code."*

### Include a confidence threshold

Tell Claude how to handle situations where it is uncertain whether a rule applies.

*"If it is unclear whether a rule applies, Claude should mention the relevant rule, note that the application is uncertain, and ask the developer to clarify — rather than flagging definitively or staying silent."*

---

## Part 10: Maintenance

A style guide that is not maintained becomes a source of conflict, not consistency.

### Versioning

Assign a version number and a date to your guide. When you change a rule, increment the version. Use semantic versioning if you like: major version for breaking changes (rules that invalidate existing code), minor version for new rules, patch for clarifications.

### The changelog entry format

```
## v1.3.0 — 2024-09-01

Added:
- ERR-007: Require explicit timeout on all HTTP requests (Warning).
  Rationale: Several production incidents traced to requests hanging
  indefinitely.

Changed:
- DOC-002: Relaxed to allow __init__ exemption (see DOC-002-EX).
  Previously flagged all __init__ methods without docstrings.

Removed:
- FMT-004: Line length rule removed. Delegated entirely to Black.
```

### When to add a rule

Add a rule when:
- A recurring pattern in code review reveals a systematic issue
- A bug or incident can be traced to a missing convention
- A new contributor makes a reasonable but inconsistent choice

Do not add a rule just because you have an opinion. The cost of a rule is real: every rule must be read, learned, remembered, and maintained.

### When to remove a rule

Remove a rule when:
- The tool it complements is no longer in use
- The codebase has evolved past the problem the rule was solving
- The rule generates more debate than consistency

---

## Appendix: Rule Writing Checklist

Use this checklist before adding any rule to your style guide.

- [ ] The rule has a stable ID
- [ ] The title is a single imperative sentence
- [ ] The severity is explicitly assigned from the defined taxonomy
- [ ] The rule statement uses no weasel words ("generally", "usually", "try to")
- [ ] The rationale states the problem the rule solves
- [ ] The rationale names the failure mode when the rule is violated
- [ ] The rationale acknowledges any real tradeoffs honestly
- [ ] There is at least one "do this" example with realistic code
- [ ] There is at least one "don't do this" example, annotated
- [ ] Any known legitimate exceptions are registered in the Exceptions Registry
- [ ] If automatable, the autofix method is noted
- [ ] Any related rules are cross-referenced
- [ ] The date introduced is recorded
- [ ] Include footnotes to external references that helped inform the rule

---

## Appendix: Style Guide Template

Copy this template to start your style guide.

```markdown
# [Project Name] Style Guide
Version: 1.0.0 — [Date]

## Preamble

[What this guide covers, what it does not cover, and the overriding
principle Claude should use when rules conflict.]

## Severity Taxonomy

| Level | Name | Description |
|---|---|---|
| 1 | Error | ... |
| 2 | Warning | ... |
| 3 | Suggestion | ... |

## Out of Scope

[List topics Claude should not comment on.]

---

## [Section Name, e.g. Naming]

[One-paragraph philosophy for this section.]

### [RULE-ID]: [Rule Title]

**Severity:** [Error / Warning / Suggestion]

**Rule:** [Precise rule statement.]

**Rationale:** [Why this rule exists. What goes wrong without it.]

**Do this:**
\`\`\`
[Example of compliant code]
\`\`\`

**Don't do this:**
\`\`\`
[Example of non-compliant code, annotated]
\`\`\`

**Exceptions:** [Reference to Exceptions Registry, or "None."]

---

## Exceptions Registry

### [RULE-ID]-EX: [Exception Title]

**Rule:** [Rule this is an exception to]
**Exception:** [Description of the exception]
**Rationale:** [Why this exception exists]
**Recognition pattern:** [How Claude should detect this exception]
**Example:** [Code showing the exception in action]

---

## Changelog

### v1.0.0 — [Date]
Initial release.
```

---

*This guide was written to be used directly as a reference when authoring a Claude code review skill. The structure it describes is also the structure it tries to model — each section has a rationale, examples where useful, and explicit guidance for the audience it serves.*
