# Architecture (summary)

Living version with diagrams: the "Vibe Coding Environment — Architecture" doc in Claude.
This file is the offline copy of the decisions.

## Seven layers, one live tool each

| # | Layer | Live | Add-on | Parked / dropped |
|---|---|---|---|---|
| 1 | Spec and planning | gsd-core | — | OpenSpec, spec-kit, GSD redux (parked); GSD original (archived, dropped) |
| 2 | Methodology and skills | Superpowers, Pocock skills, Anthropic skills, plugin marketplace | agent-starter (hooks only) | — |
| 3 | Loops and orchestration | ralph-loop plugin | ralph-orchestrator | Paperclip, cl-agent |
| 4 | Agent runtime | Claude Code | Aider, OpenHands Agent Canvas | — |
| 5 | Code intelligence (MCP) | Serena, codebase-memory-mcp, MCP reference servers (fetch, sequential-thinking) | — | rag-rat, RepoGraph (parked); src-mcp (dropped) |
| 6 | Quality and security gates | security-audit (Cloudflare), skillsaw, harness-audit | — | Polyspace (C/C++ only, needs license) |
| 7 | Observability | context-monitor, built-in task list and /cost | — | — |

## Flow of one feature
Idea → Discuss and spec (gsd-core) → Brainstorm and grill (Superpowers, Pocock) → Plan in waves (gsd-core)
→ Execute wave (Claude Code + Serena, fresh-context subagent) → tests and lint pass? (no → ralph-loop re-runs)
→ Verify and review → Security audit → gates pass? (no → back to execute) → Ship (PR, ADR, STATE.md).

## Hard rules
1. One agent runtime, one spec system, one loop.
2. Never a third code-intelligence MCP server in one project.
3. Every loop carries `--max-iterations` and a completion promise.
4. Gates run as hooks or commands the loop cannot skip.
5. Global once in `~/.claude`; project carries only CLAUDE.md, `.planning/`, `.mcp.json`.

## Windows notes
- Full stack runs in WSL2. Native Windows loses context-monitor and agent-starter hooks; ralph-loop needs `jq` on PATH.
- Keep repos on the WSL filesystem (`~/projects`), not `/mnt/c`, for Serena and codebase-memory indexing speed.
