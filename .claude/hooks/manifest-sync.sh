#!/usr/bin/env bash
# PostToolUse hook: when any plugins/*/.*-plugin/plugin.json is edited,
# verify name/version/description agree across the three host manifests.
set -euo pipefail

payload=$(cat)
path=$(printf '%s' "$payload" | jq -r '.tool_input.file_path // empty')

case "$path" in
  */plugins/*/.claude-plugin/plugin.json|*/plugins/*/.cursor-plugin/plugin.json|*/plugins/*/.codex-plugin/plugin.json) ;;
  *) exit 0 ;;
esac

plugin_dir=$(dirname "$(dirname "$path")")
claude="$plugin_dir/.claude-plugin/plugin.json"
cursor="$plugin_dir/.cursor-plugin/plugin.json"
codex="$plugin_dir/.codex-plugin/plugin.json"

for f in "$claude" "$cursor" "$codex"; do
  [ -f "$f" ] || { echo "manifest-sync: missing $f" >&2; exit 2; }
done

fail=0
for field in name version description; do
  c=$(jq -r ".${field} // \"\"" "$claude")
  u=$(jq -r ".${field} // \"\"" "$cursor")
  x=$(jq -r ".${field} // \"\"" "$codex")
  if [ "$c" != "$u" ] || [ "$c" != "$x" ]; then
    echo "manifest-sync: '$field' diverged across host manifests:" >&2
    echo "  claude: $c" >&2
    echo "  cursor: $u" >&2
    echo "  codex:  $x" >&2
    fail=1
  fi
done

exit $fail
