# Global rules (constitution)

You are working inside a layered environment: gsd-core owns the plan, Superpowers owns the method,
ralph-loop owns iteration, Serena and codebase-memory own code understanding, the audit skills own the gates.

## Workflow
- No code before a spec. New work starts with `/gsd-new-project` or `/gsd-discuss`; a vague ask starts with `/brainstorming` and `/grill-me`.
- Plans live in `.planning/`. Read `STATE.md` and the current phase `CONTEXT.md` before touching code; update them before stopping.
- One task per loop iteration. Finish, verify, commit, then move on. Never batch unrelated edits.
- TDD for anything with logic: failing test first (`/tdd`). Verification before claiming done (`/verification-before-completion`).

## Code understanding
- Use Serena for symbol-level navigation and edits (find_symbol, find_referencing_symbols, replace_symbol_body). Do not regex-edit identifiers.
- Use codebase-memory for impact analysis and architecture questions before a cross-cutting change.
- Never load a third code-intelligence server into a project.

## Gates
- A change is not done until tests, lint and typecheck pass locally.
- Before a PR: `/code-review`, then `security audit this codebase` for anything touching auth, input parsing, secrets, payments or shell.
- Write an ADR in `docs/adr/` for every architectural decision (`/adr`).

## Loops
- `/ralph-loop` always carries `--max-iterations` (default 10) and a `--completion-promise`.
- If an iteration cannot make progress twice in a row, stop and write the blocker to `STATE.md` instead of retrying.

## Hygiene
- Keep this file and every project `CLAUDE.md` under 150 lines; run `/harness-audit diagnose` when session-start context exceeds 80k tokens.
- Never commit indexes or caches (`.serena/cache`, `~/.cache/codebase-memory-mcp`). Commit `.planning/` and `.serena/memories/`.
- No secrets in any file an agent reads; `skillsaw lint` runs in pre-commit and CI.
