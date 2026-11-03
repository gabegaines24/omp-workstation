#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

if [[ "$(uname -s)" != "Darwin" ]]; then
  printf '%s\n' 'sync-from-mac.sh requires macOS.' >&2
  exit 1
fi

command -v omp >/dev/null || { printf '%s\n' 'omp is not on PATH.' >&2; exit 1; }
command -v rsync >/dev/null || { printf '%s\n' 'rsync is required.' >&2; exit 1; }

AGENT_DIR="$(omp config path)"
[[ -d "$AGENT_DIR" ]] || { printf 'OMP agent directory missing: %s\n' "$AGENT_DIR" >&2; exit 1; }

copy_tree() {
  local source="$1"
  local destination="$2"
  [[ -d "$source" ]] || return 0
  mkdir -p "$destination"
  rsync -aL --delete \
    --exclude='*.db' \
    --exclude='*.db-*' \
    --exclude='sessions/' \
    --exclude='terminal-sessions/' \
    --exclude='blobs/' \
    --exclude='cache/' \
    --exclude='logs/' \
    --exclude='run/' \
    --exclude='natives/' \
    --exclude='predict/' \
    --exclude='*.lock' \
    --exclude='config.yml.broken-*' \
    --exclude='.env' \
    --exclude='.env.*' \
    --exclude='secrets.yml' \
    --exclude='secret-placeholder.key' \
    "$source/" "$destination/"
}

mkdir -p "$ROOT/omp/agent" "$ROOT/omp/plugins" "$ROOT/omp/caveman-plugin" "$ROOT/cursor/skills-cursor" "$ROOT/cursor/user" "$ROOT/external/codex/plugins"
copy_tree "$AGENT_DIR" "$ROOT/omp/agent"
copy_tree "$HOME/.agents/skills" "$ROOT/omp/agent/skills"
copy_tree "$HOME/.omp/plugins" "$ROOT/omp/plugins"
copy_tree "$HOME/.omp/caveman-plugin" "$ROOT/omp/caveman-plugin"
copy_tree "$HOME/.cursor/skills-cursor" "$ROOT/cursor/skills-cursor"
copy_tree "$HOME/.codex/.tmp/plugins/plugins" "$ROOT/external/codex/plugins"

CURSOR_USER="$HOME/Library/Application Support/Cursor/User"
if [[ -d "$CURSOR_USER" ]]; then
  mkdir -p "$ROOT/cursor/user"
  [[ -f "$CURSOR_USER/settings.json" ]] && cp "$CURSOR_USER/settings.json" "$ROOT/cursor/user/settings.json"
  [[ -f "$CURSOR_USER/keybindings.json" ]] && cp "$CURSOR_USER/keybindings.json" "$ROOT/cursor/user/keybindings.json"
  copy_tree "$CURSOR_USER/snippets" "$ROOT/cursor/user/snippets"
fi
[[ -f "$HOME/.cursor/extensions/extensions.json" ]] && cp "$HOME/.cursor/extensions/extensions.json" "$ROOT/cursor/extensions.json"

"$ROOT/scripts/inventory-workflow.sh"
"$ROOT/scripts/audit-secrets.sh"
"$ROOT/scripts/build-manifest.sh"

printf 'OMP snapshot refreshed at %s\n' "$ROOT"
