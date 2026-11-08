#!/usr/bin/env bash
# vibe-env installer — WSL2 / Linux / macOS. Usage: ./install.sh <phase0|phase1|phase2|phase3|phase4|rollback PHASE>
set -euo pipefail
HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
CLAUDE_DIR="${CLAUDE_DIR:-$HOME/.claude}"
REF_DIR="${REF_DIR:-$HOME/reference}"
LOG="$HERE/.install.log"

say()  { printf '\n\033[1;34m==> %s\033[0m\n' "$*"; }
ok()   { printf '   \033[32m✓\033[0m %s\n' "$*"; }
warn() { printf '   \033[33m!\033[0m %s\n' "$*"; }
die()  { printf '   \033[31m✗\033[0m %s\n' "$*" >&2; exit 1; }
have() { command -v "$1" >/dev/null 2>&1; }
mark() { echo "$(date -Is) $1" >> "$LOG"; }

need_claude() { have claude || die "Claude Code CLI not found. Install it first: https://docs.claude.com/en/docs/claude-code"; }

# ---------------------------------------------------------------- phase 0
phase0() {
  say "Phase 0 — prerequisites"
  if grep -qi microsoft /proc/version 2>/dev/null; then ok "running inside WSL2"; else warn "not WSL2 — fine on Linux/macOS, but on native Windows use install.ps1"; fi
  have node   && ok "node $(node -v)"   || die "node missing (need 24+): https://github.com/nvm-sh/nvm then 'nvm install 24'"
  local major; major=$(node -v | sed 's/v\([0-9]*\).*/\1/'); [ "$major" -ge 24 ] || warn "node $major < 24: OpenHands and Paperclip need 24+; the rest works"
  have uv     && ok "uv $(uv --version)" || { warn "uv missing — installing"; curl -LsSf https://astral.sh/uv/install.sh | sh; export PATH="$HOME/.local/bin:$PATH"; }
  have python3 && ok "python3 $(python3 --version | cut -d' ' -f2)" || die "python3 missing"
  have git    && ok "git $(git --version | cut -d' ' -f3)" || die "git missing"
  have jq     && ok "jq present (ralph-loop hook needs it)" || { warn "jq missing — sudo apt-get install -y jq"; sudo apt-get install -y jq; }
  have docker && ok "docker present (OpenHands sandbox)" || warn "docker missing — only needed in phase 3 for OpenHands; install Docker Desktop with WSL integration"
  need_claude && ok "claude $(claude --version 2>/dev/null | head -1)"
  mkdir -p "$CLAUDE_DIR/skills" "$REF_DIR"
  mark phase0
}

# ---------------------------------------------------------------- phase 1
phase1() {
  say "Phase 1 — core: marketplaces, methodology, spec system, observability, lint"
  need_claude
  claude plugin marketplace add anthropics/claude-plugins-official || true
  claude plugin marketplace add anthropics/skills || true
  ok "marketplaces registered"

  claude plugin install superpowers@claude-plugins-official && ok "Superpowers"
  claude plugin install example-skills@anthropic-agent-skills || warn "anthropic example-skills: check name with 'claude plugin marketplace list'"

  # Matt Pocock skills — generic skills installer, Claude Code target, global
  npx -y skills@latest add mattpocock/skills -a claude-code -g && ok "Pocock skills (run /setup-matt-pocock-skills once per repo)"

  # gsd-core — interactive: choose Claude Code, global
  say "gsd-core installer (pick: Claude Code, global)"
  npx -y @opengsd/gsd-core@latest && ok "gsd-core"

  # context-monitor — Linux/macOS only
  claude plugin marketplace add fomyio/claude-context-monitor || true
  claude plugin install context-monitor@claude-context-monitor && ok "context-monitor (reload Claude Code: /reload-plugins)"

  # skillsaw — lints CLAUDE.md / SKILL.md / hooks / MCP configs
  uv tool install skillsaw && ok "skillsaw ($(skillsaw --version 2>/dev/null || echo installed))"

  # harness-audit — skill folder, Python stdlib
  if [ ! -d "$CLAUDE_DIR/skills/harness-audit" ]; then
    git clone --depth 1 https://github.com/fabianmartinelli-fm/harness-audit "$REF_DIR/harness-audit"
    cp -r "$REF_DIR/harness-audit/skills/harness-audit" "$CLAUDE_DIR/skills/harness-audit"
  fi
  ok "harness-audit skill (/harness-audit diagnose)"

  # global CLAUDE.md — never overwrite silently
  if [ -f "$CLAUDE_DIR/CLAUDE.md" ]; then
    cp "$CLAUDE_DIR/CLAUDE.md" "$CLAUDE_DIR/CLAUDE.md.bak.$(date +%s)"; warn "existing ~/.claude/CLAUDE.md backed up"
  fi
  cp "$HERE/config/global/CLAUDE.md" "$CLAUDE_DIR/CLAUDE.md" && ok "global CLAUDE.md"

  skillsaw lint "$CLAUDE_DIR" || warn "skillsaw found issues in ~/.claude — review above"
  mark phase1
  say "Smoke test: open Claude Code in a test project and run /gsd-new-project, then /brainstorming. Status line should show context %."
}

# ---------------------------------------------------------------- phase 2
phase2() {
  say "Phase 2 — context: Serena, codebase-memory-mcp, fetch, sequential-thinking"
  need_claude
  uv tool install -p 3.13 serena-agent && ok "Serena"
  claude mcp add -s user serena -- serena start-mcp-server --context ide-assistant || warn "serena already registered"

  if ! have codebase-memory-mcp; then
    curl -fsSL https://raw.githubusercontent.com/DeusData/codebase-memory-mcp/main/install.sh | sh
  fi
  ok "codebase-memory-mcp (installer auto-configures Claude Code; verify with 'claude mcp list')"

  claude mcp add -s user fetch -- uvx mcp-server-fetch || true
  claude mcp add -s user sequential-thinking -- npx -y @modelcontextprotocol/server-sequential-thinking || true
  ok "reference servers: fetch, sequential-thinking"

  claude mcp list
  mark phase2
  say "Smoke test: in a project ask Claude Code to 'find_symbol <any class>' (Serena) and 'what does changing <file> impact' (codebase-memory). Then: /harness-audit diagnose → apply, and check session-start context < 80k in the status line."
}

# ---------------------------------------------------------------- phase 3
phase3() {
  say "Phase 3 — autonomy: ralph-loop, security-audit, agent-starter hooks, OpenHands, ralph-orchestrator"
  need_claude
  claude plugin install ralph-loop@claude-plugins-official \
    || claude plugin install ralph-wiggum@claude-plugins-official \
    || warn "ralph plugin slug changed — run 'claude plugin marketplace list' and install the Ralph entry"
  ok "ralph-loop  (use: /ralph-loop \"<task>\" --max-iterations 10 --completion-promise \"DONE\")"

  npx -y skills add https://github.com/cloudflare/security-audit-skill --skill security-audit --global && ok "cloudflare security-audit skill"

  # agent-starter — hooks only (its /new-project duplicates gsd-core)
  [ -d "$REF_DIR/agent-starter" ] || git clone --depth 1 https://github.com/sneg55/agent-starter "$REF_DIR/agent-starter"
  ( cd "$REF_DIR/agent-starter" && ./install.sh ) && ok "agent-starter enforcement hooks"

  read -r -p "Install OpenHands Agent Canvas (needs Node 24+, Docker)? [y/N] " yn
  if [[ "${yn:-N}" =~ ^[Yy]$ ]]; then npm i -g @openhands/agent-canvas && ok "OpenHands (run: agent-canvas, UI at localhost:8000, Docker sandbox only)"; fi

  read -r -p "Install ralph-orchestrator for long unattended runs? [y/N] " yn
  if [[ "${yn:-N}" =~ ^[Yy]$ ]]; then npm i -g @ralph-orchestrator/ralph-cli && ok "ralph-orchestrator (ralph init / plan / run)"; fi

  skillsaw lint "$CLAUDE_DIR" || warn "skillsaw found issues after hook install — review"
  mark phase3
  say "Smoke test: /ralph-loop on one small gsd-core phase with --max-iterations 5, then 'security audit this codebase'."
}

# ---------------------------------------------------------------- phase 4
phase4() {
  say "Phase 4 — hardening: Aider, parked repos, pre-commit"
  python3 -m pip install --user -q aider-install && aider-install && ok "Aider (never run it and Claude Code on the same tree at once)"
  "$HERE/scripts/park.sh"
  have pre-commit || uv tool install pre-commit
  ok "pre-commit available — templates/project/.pre-commit-config.yaml wires skillsaw"
  mark phase4
}

rollback() {
  local p="${1:-}"; need_claude
  case "$p" in
    phase1) for x in superpowers@claude-plugins-official context-monitor@claude-context-monitor; do claude plugin uninstall "$x" || true; done; uv tool uninstall skillsaw || true; rm -rf "$CLAUDE_DIR/skills/harness-audit";;
    phase2) for s in serena fetch sequential-thinking codebase-memory; do claude mcp remove -s user "$s" || true; done; uv tool uninstall serena-agent || true;;
    phase3) claude plugin uninstall ralph-loop@claude-plugins-official || claude plugin uninstall ralph-wiggum@claude-plugins-official || true; rm -rf "$CLAUDE_DIR/skills/security-audit";;
    *) die "rollback phase1|phase2|phase3";;
  esac
  ok "rolled back $p"
}

case "${1:-}" in
  phase0|phase1|phase2|phase3|phase4) "$1";;
  rollback) rollback "${2:-}";;
  *) echo "usage: $0 phase0|phase1|phase2|phase3|phase4|rollback <phase>"; exit 2;;
esac
