#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
WORKFLOW_ROOT="${WORKFLOW_ROOT:-$HOME/workflow}"
OUTPUT="$ROOT/projects/repos.json"

command -v jq >/dev/null || { printf '%s\n' 'jq is required.' >&2; exit 1; }
[[ -d "$WORKFLOW_ROOT" ]] || { printf '%s\n' '{"format":1,"workflowRoot":"~/workflow","repositories":[],"generatedBy":"scripts/inventory-workflow.sh"}' > "$OUTPUT"; exit 0; }

records="$(mktemp)"
trap 'rm -f "$records"' EXIT

find "$WORKFLOW_ROOT" -type d -name .git -prune -print0 |
while IFS= read -r -d '' git_dir; do
  repo_dir="${git_dir%/.git}"
  relative="${repo_dir#"$WORKFLOW_ROOT"/}"
  name="$(basename "$repo_dir")"
  branch="$(git -C "$repo_dir" branch --show-current 2>/dev/null || true)"
  dirty_count="$(git -C "$repo_dir" status --porcelain 2>/dev/null | wc -l | tr -d ' ')"
  origin="$(git -C "$repo_dir" remote get-url origin 2>/dev/null || true)"
  if [[ "$origin" =~ ^https?://[^/]*@ ]]; then
    origin="<redacted-credential-url>"
  fi

  has_omp=false
  has_cursor=false
  has_agents=false
  [[ -d "$repo_dir/.omp" ]] && has_omp=true
  [[ -d "$repo_dir/.cursor" ]] && has_cursor=true
  [[ -f "$repo_dir/AGENTS.md" ]] && has_agents=true

  jq -n \
    --arg name "$name" \
    --arg relativePath "$relative" \
    --arg branch "$branch" \
    --arg origin "$origin" \
    --argjson dirty "${dirty_count:-0}" \
    --argjson hasOmp "$has_omp" \
    --argjson hasCursor "$has_cursor" \
    --argjson hasAgents "$has_agents" \
    '{name:$name,relativePath:$relativePath,origin:$origin,branch:$branch,dirtyFileCount:$dirty,hasOmp:$hasOmp,hasCursor:$hasCursor,hasAgents:$hasAgents}' >> "$records"
done

jq -s \
  --arg workflowRoot '~/workflow' \
  --arg generatedBy 'scripts/inventory-workflow.sh' \
  '{format:1,workflowRoot:$workflowRoot,generatedAt:(now|todateiso8601),generatedBy:$generatedBy,repositories:.}' \
  "$records" > "$OUTPUT"

printf 'Workflow inventory written: %s\n' "$OUTPUT"
