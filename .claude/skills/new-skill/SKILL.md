---
name: new-skill
description: Scaffold a new Lumar plugin skill under plugins/<plugin>/skills/<name>/. Creates SKILL.md from the template, reminds the user which manifests and README sections to update so the skill is discoverable across Claude Code, Cursor, and Codex hosts.
disable-model-invocation: true
---

Use this when the user asks to "add a new skill", "create a skill", or invokes `/new-skill`.

# Inputs to collect

1. **Plugin** — which `plugins/<plugin>/` it belongs to. If only one exists (`lumar-analytics`), pick that without asking.
2. **Skill name** — kebab-case, will become the directory name and the `name:` field.
3. **One-line purpose** — used to seed the description.
4. **Trigger phrases** — 2–4 realistic user utterances that should fire this skill.

# Steps

1. Confirm `plugins/<plugin>/skills/<name>/` does not already exist.
2. Create `plugins/<plugin>/skills/<name>/SKILL.md` from the template in `template.md` next to this file. Fill in `name`, `description` (purpose + trigger phrases), and a stub body.
3. Print the following follow-up checklist to the user, with the exact lines to add:
   - Add a row to the skill table in `README.md` (find the table heading that matches AI Visibility / Lumar Analyze).
   - If the host manifests under `.claude-plugin/`, `.cursor-plugin/`, `.codex-plugin/` enumerate skills (some don't — check), add the new entry to each.
   - Bump nothing in `version:` yet — that's the `release-plugin` skill's job.
4. Do NOT edit the README or the manifests automatically. Show the user the diffs and let them apply.

# Quality bar

The `description:` must include at least two concrete user phrases in quotes. The SKILL.md frontmatter PostToolUse hook will reject anything thinner than 40 chars; aim for 150–400.
