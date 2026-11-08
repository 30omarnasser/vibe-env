# vibe-env — AI coding environment for Claude Code

One primary agent (Claude Code), seven layers, one live tool per layer.
Full architecture and the reasoning behind every pick: see `docs/ARCHITECTURE.md`.

## Platform

Works on **native Windows, WSL2, Linux, and macOS**. The 2026-11-09 reference
build ran fully native on Windows (see `docs/REMAINING.md` for the final state):

- `claude` inside WSL resolves to the Windows CLI anyway — plugins/MCP/skills all
  land in the same `~/.claude`, so native install is the primary path on Windows.
- Set `UV_SYSTEM_CERTS=true` (user env) on machines with TLS interception, or uv fails.
- Not available natively: agent-starter hooks (bash/jq) and ralph-orchestrator
  (upstream ships macOS/Linux binaries only) — both optional; use WSL2 if needed.
- context-monitor needs the Windows patch (see fomyio/claude-context-monitor issues)
  or WSL2; ralph-loop's `jq` hook works natively when jq is on PATH.

## Run

```bash
# in WSL2
cd ~/projects/vibe-env          # or /mnt/c/Users/pc/projects/vibe-env
chmod +x install.sh scripts/*.sh
./install.sh phase0             # prerequisites check
./install.sh phase1             # marketplaces, Superpowers, Pocock skills, gsd-core, context-monitor, skillsaw, harness-audit
./install.sh phase2             # Serena, codebase-memory-mcp, fetch, sequential-thinking
./install.sh phase3             # ralph-loop, security-audit skill, agent-starter hooks, (optional) OpenHands, ralph-orchestrator
./install.sh phase4             # Aider, parked reference repos, pre-commit lint
./scripts/verify.sh             # checks every layer answers
```

Run a phase, open Claude Code on the testbed project, smoke-test, then run the next.
A phase that breaks the previous one is rolled back (`./install.sh rollback <phase>`), not patched forward.

## Layout

```
install.sh                  phased installer (WSL2 / Linux / macOS)
install.ps1                 native-Windows subset
config/global/CLAUDE.md     global rules -> ~/.claude/CLAUDE.md
config/global/mcp.json      user-scope MCP servers (reference; install.sh registers them via `claude mcp add`)
config/global/settings.hooks.json   hook snippet merged into ~/.claude/settings.json
templates/project/          drop into any repo: CLAUDE.md, .mcp.json, .claude/settings.json
scripts/verify.sh           layer-by-layer health check
scripts/new-project.sh      scaffold a project from templates/
scripts/park.sh             clone the parked repos read-only into ~/reference
docs/ARCHITECTURE.md        the architecture, decisions, overlaps
```

## Defaults chosen

- Spec system: **gsd-core** (OpenSpec and spec-kit parked)
- Loop: **ralph-loop** plugin, `--max-iterations 10` default; ralph-orchestrator only for overnight runs
- Context: **Serena** (symbols) + **codebase-memory-mcp** (graph); never a third indexer in one project
- Gates: cloudflare security-audit, skillsaw, harness-audit
