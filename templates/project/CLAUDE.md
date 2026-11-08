# <Project name>

<One sentence: what this is and who uses it.>

## Stack
- Language/runtime: <TypeScript 5 / Node 24> | <Python 3.12 / uv>
- Framework: <...>
- Data: <...>

## Commands
- Install: `<npm ci | uv sync>`
- Dev: `<npm run dev>`
- Test: `<npm test | uv run pytest>`
- Lint + typecheck: `<npm run lint && npm run typecheck | uv run ruff check . && uv run pyright>`

## Where things are
- Specs and plan: `.planning/` (gsd-core) — read `STATE.md` first
- Decisions: `docs/adr/`
- Serena project memories: `.serena/memories/`

## Do not touch
- <generated files, vendored dirs, migrations already applied>

## Project-specific rules
- <e.g. all DB access through repository layer; no raw SQL in handlers>
