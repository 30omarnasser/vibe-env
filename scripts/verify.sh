#!/usr/bin/env bash
# Layer-by-layer health check. Exit code = number of failing checks.
set -uo pipefail
CLAUDE_DIR="${CLAUDE_DIR:-$HOME/.claude}"; fails=0
chk() { if eval "$2" >/dev/null 2>&1; then printf '  ✓ %s\n' "$1"; else printf '  ✗ %s\n' "$1"; fails=$((fails+1)); fi; }
echo "Layer 1 — spec";       chk "gsd-core skills installed"      "ls -d $CLAUDE_DIR/skills/gsd-* 2>/dev/null | grep -q gsd || claude plugin list | grep -qi gsd"
echo "Layer 2 — method";     chk "Superpowers plugin"              "claude plugin list | grep -qi superpowers"
                             chk "Pocock skills"                   "ls $CLAUDE_DIR/skills | grep -qiE 'grill|tdd'"
echo "Layer 3 — loop";       chk "ralph plugin"                    "claude plugin list | grep -qiE 'ralph'"
                             chk "jq for ralph hook"               "command -v jq"
echo "Layer 4 — runtime";    chk "claude CLI"                      "command -v claude"
                             chk "aider (phase 4)"                 "command -v aider"
echo "Layer 5 — context";    chk "serena registered"               "claude mcp list | grep -qi serena"
                             chk "codebase-memory registered"      "claude mcp list | grep -qi codebase"
                             chk "fetch + sequential-thinking"     "claude mcp list | grep -qi fetch && claude mcp list | grep -qi sequential"
                             chk "no 3rd code-intel server"        "! claude mcp list | grep -qiE 'rag-rat|src-mcp'"
echo "Layer 6 — gates";      chk "security-audit skill"            "ls -d $CLAUDE_DIR/skills/security-audit"
                             chk "skillsaw"                        "command -v skillsaw"
                             chk "harness-audit skill"             "ls -d $CLAUDE_DIR/skills/harness-audit"
                             chk "skillsaw lint ~/.claude clean"   "skillsaw lint $CLAUDE_DIR"
echo "Layer 7 — observe";    chk "context-monitor plugin"          "claude plugin list | grep -qi context-monitor"
echo "Hygiene";              chk "global CLAUDE.md < 150 lines"    "[ \$(wc -l < $CLAUDE_DIR/CLAUDE.md) -lt 150 ]"
echo; echo "$fails failing"; exit $fails
