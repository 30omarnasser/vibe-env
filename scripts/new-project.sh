#!/usr/bin/env bash
# Scaffold a project with the vibe-env templates. Usage: scripts/new-project.sh <dir>
set -euo pipefail
HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
D="${1:?usage: new-project.sh <dir>}"
mkdir -p "$D/.claude" "$D/docs/adr"
for f in CLAUDE.md .mcp.json .pre-commit-config.yaml; do [ -e "$D/$f" ] || cp "$HERE/templates/project/$f" "$D/$f"; done
[ -e "$D/.claude/settings.json" ] || cp "$HERE/templates/project/.claude/settings.json" "$D/.claude/settings.json"
cat "$HERE/templates/project/.gitignore.append" >> "$D/.gitignore"
( cd "$D" && git init -q 2>/dev/null || true )
echo "scaffolded $D — next: cd $D && claude, then /gsd-new-project and /setup-matt-pocock-skills"
