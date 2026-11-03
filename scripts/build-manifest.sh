#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
MANIFEST="$ROOT/MANIFEST.json"

command -v jq >/dev/null || { printf '%s\n' 'jq is required.' >&2; exit 1; }
command -v shasum >/dev/null || { printf '%s\n' 'shasum is required.' >&2; exit 1; }
command -v omp >/dev/null || { printf '%s\n' 'omp is required.' >&2; exit 1; }

omp_version="$(omp --version 2>/dev/null || true)"
skill_count="$(find "$ROOT/omp/agent/skills" -type f -name SKILL.md | wc -l | tr -d ' ')"

tmp_dir="$(mktemp -d)"
trap 'rm -rf "$tmp_dir"' EXIT
file_records="$tmp_dir/file-records"
path_review_raw="$tmp_dir/path-review-raw"
files_json="$tmp_dir/files.json"
path_review_json="$tmp_dir/path-review.json"
: > "$file_records"
: > "$path_review_raw"

find "$ROOT/AGENTS.md" "$ROOT/README.md" "$ROOT/.cursor" "$ROOT/omp" "$ROOT/cursor" "$ROOT/external" "$ROOT/projects" "$ROOT/scripts" -type f -print0 2>/dev/null |
while IFS= read -r -d '' file; do
  relative="${file#"$ROOT/"}"
  hash="$(shasum -a 256 "$file" | cut -d ' ' -f 1)"
  bytes="$(wc -c < "$file" | tr -d ' ')"
  jq -n --arg path "$relative" --arg sha256 "$hash" --argjson bytes "$bytes" '{path:$path,sha256:$sha256,bytes:$bytes}' >> "$file_records"
done
jq -s '.' "$file_records" > "$files_json"

if grep -RIlE --exclude='*.md' --exclude='*.mdc' --exclude='MANIFEST.json' \
  '(/Users/|/opt/homebrew/|/usr/local/|\.pyenv/)' \
  "$ROOT/omp" "$ROOT/cursor" "$ROOT/external" 2>/dev/null |
  while IFS= read -r file; do printf '%s\n' "${file#"$ROOT/"}"; done > "$path_review_raw"; then
  :
fi
jq -R . "$path_review_raw" | jq -s '.' > "$path_review_json"

omp_agent_dir='~/.omp/agent'
config_root='~/.omp'
profile='default'
if [[ -n "${OMP_PROFILE:-}" ]]; then profile="$OMP_PROFILE"; fi

tmp="$tmp_dir/manifest.json"
jq \
  --arg ompVersion "$omp_version" \
  --argjson skillFiles "$skill_count" \
  --slurpfile files "$files_json" \
  --slurpfile pathReviewRequired "$path_review_json" \
  --arg agentDirectory "$omp_agent_dir" \
  --arg configRoot "$config_root" \
  --arg profile "$profile" \
  --arg generatedAt "$(date -u +%Y-%m-%dT%H:%M:%SZ)" \
  '.source.ompVersion=$ompVersion
   | .source.agentDirectory=$agentDirectory
   | .source.configRoot=$configRoot
   | .profile=$profile
   | .skillFiles=$skillFiles
   | .files=$files[0]
   | .pathReviewRequired=$pathReviewRequired[0]
   | .generatedAt=$generatedAt' \
  "$MANIFEST" > "$tmp"
mv "$tmp" "$MANIFEST"

printf 'Manifest written: %s (%s skills, %s files)\n' "$MANIFEST" "$skill_count" "$(jq '.files|length' "$MANIFEST")"
