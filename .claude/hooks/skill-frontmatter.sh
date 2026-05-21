#!/usr/bin/env bash
# PostToolUse hook: validate SKILL.md frontmatter.
# Required: name (matches parent dir), description (>= 40 chars).
set -euo pipefail

payload=$(cat)
path=$(printf '%s' "$payload" | jq -r '.tool_input.file_path // empty')

[[ "$path" == */SKILL.md ]] || exit 0
[ -f "$path" ] || exit 0

parent=$(basename "$(dirname "$path")")

fm=$(awk 'BEGIN{n=0} /^---[[:space:]]*$/{n++; next} n==1{print} n==2{exit}' "$path")

if [ -z "$fm" ]; then
  echo "skill-frontmatter: $path has no YAML frontmatter" >&2
  exit 2
fi

name=$(printf '%s\n' "$fm" | awk '/^name:/{sub(/^name: */,""); print; exit}')
desc=$(printf '%s\n' "$fm" | awk '/^description:/{sub(/^description: */,""); print; exit}')

fail=0
if [ -z "$name" ]; then
  echo "skill-frontmatter: missing 'name' in $path" >&2; fail=1
elif [ "$name" != "$parent" ]; then
  echo "skill-frontmatter: name '$name' != parent dir '$parent' in $path" >&2; fail=1
fi

if [ -z "$desc" ]; then
  echo "skill-frontmatter: missing 'description' in $path" >&2; fail=1
elif [ "${#desc}" -lt 40 ]; then
  echo "skill-frontmatter: 'description' is ${#desc} chars (< 40) — too thin to trigger reliably in $path" >&2; fail=1
fi

exit $fail
