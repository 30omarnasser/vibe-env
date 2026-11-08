# Remaining manual steps

All four phases are installed (2026-11-09). Update on the former pending items:

- **OpenHands Agent Canvas 1.37.0**: INSTALLED and working (`agent-canvas`). Needs Docker
  Desktop running; use sandbox mode only. npm skipped 4 postinstall scripts by default
  (core-js, @openrouter/sdk etc.) — CLI verified working without them.
- **ralph-orchestrator**: NOT INSTALLABLE on native Windows — upstream v2.10.1 ships
  macOS/Linux binaries only (confirmed via GitHub releases; no -pc-windows assets).
  Options if ever needed for overnight runs: run it inside WSL2
  (`npm i -g @ralph-orchestrator/ralph-cli` there, after provisioning node), or
  `cargo build` from the clone at `~/reference/ralph-orchestrator`. ralph-loop (the
  Anthropic plugin) remains the default loop and works natively.

Notes:
- `agent-starter` hooks are NOT installed natively (bash/jq hooks, per install.ps1 header
  they are WSL-only). Repo is cloned at `~/reference/agent-starter` if wanted under WSL2.
- WSL2 Ubuntu-24.04 is bare (no node/uv/jq, runs as root). Only needed if you want
  agent-starter hooks or the WSL variant of the stack; the native install above is primary.
- After the next context-monitor plugin update, re-run its Windows patch:
  `node ~/.claude/integrations/context-monitor-vscode/apply-windows-patch.js` (see memory).
- Restart Claude Code sessions to pick up: serena MCP (now that uv + UV_NATIVE_TLS are set),
  codebase-memory-mcp, gsd-core hooks, and the skillsaw PostToolUse lint hook
  (or open /hooks once to reload).
