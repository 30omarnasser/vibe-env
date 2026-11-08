<#
 vibe-env — native Windows subset. Prefer WSL2 + install.sh for the full stack.
 Not available natively: context-monitor (no Windows build), agent-starter hooks (bash/jq), ralph-loop hook in Git Bash (jq).
 Usage:  powershell -ExecutionPolicy Bypass -File .\install.ps1 -Phase phase1
#>
param([ValidateSet('phase0','phase1','phase2','phase3')][string]$Phase = 'phase0')
$ErrorActionPreference = 'Stop'
function Say($m){ Write-Host "`n==> $m" -ForegroundColor Cyan }
function Ok($m){ Write-Host "   OK  $m" -ForegroundColor Green }
function Warn($m){ Write-Host "   !   $m" -ForegroundColor Yellow }
function Have($c){ $null -ne (Get-Command $c -ErrorAction SilentlyContinue) }
$ClaudeDir = Join-Path $env:USERPROFILE '.claude'

switch ($Phase) {
 'phase0' {
   Say 'Phase 0 — prerequisites (Windows)'
   if (Have node) { Ok "node $(node -v)" } else { throw 'node missing: winget install OpenJS.NodeJS.LTS' }
   if (Have uv)   { Ok "uv $(uv --version)" } else { Warn 'installing uv'; irm https://astral.sh/uv/install.ps1 | iex }
   if (Have git)  { Ok 'git' } else { throw 'git missing: winget install Git.Git' }
   if (Have claude) { Ok 'claude CLI' } else { throw 'Claude Code CLI missing' }
   if (Have wsl) { Ok 'WSL present — run install.sh inside it for the full stack' } else { Warn 'WSL missing: wsl --install  (needed for context-monitor, agent-starter hooks)' }
   New-Item -ItemType Directory -Force -Path (Join-Path $ClaudeDir 'skills') | Out-Null
 }
 'phase1' {
   Say 'Phase 1 — core'
   claude plugin marketplace add anthropics/claude-plugins-official
   claude plugin marketplace add anthropics/skills
   claude plugin install superpowers@claude-plugins-official; Ok 'Superpowers'
   npx -y skills@latest add mattpocock/skills -a claude-code -g; Ok 'Pocock skills'
   Say 'gsd-core installer (pick Claude Code, global)'; npx -y @opengsd/gsd-core@latest
   uv tool install skillsaw; Ok 'skillsaw'
   $ref = Join-Path $env:USERPROFILE 'reference'; New-Item -ItemType Directory -Force -Path $ref | Out-Null
   if (-not (Test-Path "$ref\harness-audit")) { git clone --depth 1 https://github.com/fabianmartinelli-fm/harness-audit "$ref\harness-audit" }
   Copy-Item -Recurse -Force "$ref\harness-audit\skills\harness-audit" (Join-Path $ClaudeDir 'skills\harness-audit'); Ok 'harness-audit'
   $g = Join-Path $ClaudeDir 'CLAUDE.md'; if (Test-Path $g) { Copy-Item $g "$g.bak.$(Get-Date -Format yyyyMMddHHmmss)"; Warn 'existing CLAUDE.md backed up' }
   Copy-Item "$PSScriptRoot\config\global\CLAUDE.md" $g; Ok 'global CLAUDE.md'
   Warn 'context-monitor skipped: no Windows build (use WSL2)'
 }
 'phase2' {
   Say 'Phase 2 — context'
   uv tool install -p 3.13 serena-agent; Ok 'Serena'
   claude mcp add -s user serena -- serena start-mcp-server --context ide-assistant
   irm https://raw.githubusercontent.com/DeusData/codebase-memory-mcp/main/install.ps1 | iex; Ok 'codebase-memory-mcp'
   claude mcp add -s user fetch -- uvx mcp-server-fetch
   claude mcp add -s user sequential-thinking -- npx -y '@modelcontextprotocol/server-sequential-thinking'
   claude mcp list
 }
 'phase3' {
   Say 'Phase 3 — autonomy (partial on Windows)'
   try { claude plugin install ralph-loop@claude-plugins-official } catch { claude plugin install ralph-wiggum@claude-plugins-official }
   Warn 'ralph-loop Stop hook needs jq on PATH: winget install jqlang.jq'
   npx -y skills add https://github.com/cloudflare/security-audit-skill --skill security-audit --global; Ok 'security-audit'
   Warn 'agent-starter hooks and OpenHands: use WSL2'
 }
}
