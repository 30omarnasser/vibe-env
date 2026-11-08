#!/usr/bin/env bash
# Clone parked repos read-only into ~/reference for study; nothing here is installed.
set -euo pipefail
REF_DIR="${REF_DIR:-$HOME/reference}"; mkdir -p "$REF_DIR"
for r in gsd-open/get-shit-done-redux Fission-AI/OpenSpec github/spec-kit cq27-dev/rag-rat ozyyshr/RepoGraph paperclipai/paperclip dattgoswami/cl-agent mathworks/polyspace-agentic-toolkit modelcontextprotocol/servers mikeyobrien/ralph-orchestrator; do
  n="${r##*/}"
  [ -d "$REF_DIR/$n" ] && { echo "  = $n"; continue; }
  git clone -q --depth 1 "https://github.com/$r" "$REF_DIR/$n" && echo "  + $n"
done
