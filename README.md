# claude-skills

Opinionated code review skills for [Claude Code](https://claude.ai/claude-code).
The opinions expressed in these skills reflect those of the author.

## Skills

- **[review-commits](skills/review-commits/SKILL.md)**
  - Reviews each commit since the merge base individually.
- **[review-changes](skills/review-changes/SKILL.md)**
  - Reviews the cumulative diff compared to the merge base.
- **[reviewing-rust-code](skills/reviewing-rust-code/SKILL.md)**
  - 12 rules covering logic errors, error handling, API misuse, documentation, naming, API design, and observability.
- **[reviewing-makefiles](skills/reviewing-makefiles/SKILL.md)** —
  - Rules for Makefile conventions (noun vs verb targets, docstrings, side effects).

## Installation

Clone this repo and run the installer:

```sh
git clone https://github.com/apljungquist/claude-skills.git
cd claude-skills
./install.sh
```

This symlinks selected skills into `~/.claude/skills/`. Keep the clone around.

## Updating

Since skills are symlinked, updating is as simple as pulling the latest main:

```sh
git pull
```

## Testing

Test cases live under `tests/<case>/` with a `config.sh` (defining `REPO_URL`
and `BASE_COMMIT`) and one or more `*.patch` files.

Run a test case (executes the review 5 times for consistency analysis):

```sh
tests/run.sh tests/<case>
```

Results are written to `tests/results/`. A tally of findings across runs is
printed at the end, or can be run separately:

```sh
tests/tally.sh tests/results
```
