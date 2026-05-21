---
name: release-plugin
description: Bump a plugin's version across all three host manifests (.claude-plugin, .cursor-plugin, .codex-plugin), draft a changelog entry, and prepare a release commit + tag. Use when the user says "release lumar-analytics", "bump version", "cut a release", or invokes /release-plugin.
disable-model-invocation: true
---

Use this when the user wants to ship a new version of a plugin under `plugins/<plugin>/`.

# Inputs to collect

1. **Plugin** — which `plugins/<plugin>/`. Default to the only one if there's just one.
2. **Bump type** — `patch` | `minor` | `major`. Ask if unclear; do not guess from the diff.
3. **Highlights** — 1–4 bullet points for the changelog. If omitted, derive from `git log <last-tag>..HEAD -- plugins/<plugin>/` and confirm with the user before writing.

# Steps

1. Read the current `version` from `plugins/<plugin>/.claude-plugin/plugin.json`.
2. Compute the new version per semver from the bump type.
3. Update `version` in **all three** manifests:
   - `plugins/<plugin>/.claude-plugin/plugin.json`
   - `plugins/<plugin>/.cursor-plugin/plugin.json`
   - `plugins/<plugin>/.codex-plugin/plugin.json`
   The manifest-sync PostToolUse hook will catch any one you forget.
4. Append a changelog entry. If `CHANGELOG.md` exists at the plugin root, prepend the entry under a new `## <version> — <YYYY-MM-DD>` heading. If not, create one. Write changelog entries as user-readable summaries, not PR titles — a PM should be able to follow them.
5. Stop. Show the user the staged diff. Do NOT commit, tag, or push without explicit confirmation.
6. After confirmation, create a conventional-commit release commit (`chore(release): <plugin> v<version>`) and an annotated git tag `<plugin>-v<version>`. Do not push the tag without asking.

# Notes

- The repo follows the `feat(<scope>): <message>` conventional commit style — see CLAUDE.md.
- Open PRs as **draft** per repo policy.
- If no JIRA ticket is referenced, add the `no-jira` label when the PR is opened.
