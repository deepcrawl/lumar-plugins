---
name: analyze-task-review
description: Review Lumar Analyze remediation tasks — list active tasks across an account or project, prioritise by deadline and severity, and flag overdue or stale work. Use this skill whenever someone asks "what tasks do I have open?", "show me the SEO backlog", "what's assigned to <person>?", "any tasks due this week?", or wants a prioritised view of remediation work. Also trigger when users want to clean up the task list and decide what to tackle next.
---

# Analyze Task Review

Surface Analyze remediation tasks (project- or account-scoped), prioritise them, and call out anything overdue, deadline-imminent, or unassigned.

**This skill is read-only.** The Lumar MCP server exposes task **creation** (via `analyze-report-deep-dive` → `analyze_create_report_task`) but **not** task updates. Status, priority, assignee, and deadline changes happen in the Lumar dashboard.

## Parameters

- **scope**: `project` or `account`. Default `account` when the user asks "what's on my plate" without naming a project.
- **project_or_account**: Project name/domain when `scope=project`. Account name when `scope=account` (auto-pick if single).
- **status**: Optional `Backlog`, `ToDo`, `InProgress`, `Testing`, `Done`. Default: all active.
- **priority**: Optional `Critical`, `High`, `Medium`, `Low`, `Note`.
- **assignee**: Optional email or name to filter by.
- **active_only**: Default `true` (excludes tasks with `fixedAt` set). Set `false` only when the user explicitly wants the full history.

## Step 0: Resolve scope

1. `lumar_get_me` → Analyze-entitled account (auto-pick if single, ask if multiple).
2. If `scope=project`, `analyze_list_projects` with `query` to resolve `projectId`.

## Step 1: Fetch tasks

`analyze_list_tasks` with:

- Either `projectId` (project scope) or `accountId` (account scope; omit to auto-resolve).
- `activeOnly`, `status`, `priority`, `query` (substring on title), `segmentId` as supplied.
- `limit: 100` to minimise pagination on review-style use.

If `pagination.has_next_page`, mention the cap and offer to page further only if the user asks.

## Step 2: Prioritise client-side

Sort and bucket the returned tasks:

- **Overdue** — `deadline < now` and `status != "Done"`.
- **Due this week** — `deadline` within next 7 days.
- **High signal, no deadline** — `priority` in (`Critical`, `High`) with no `deadlineAt`. Flag for assignment.
- **Stale** — `status: "InProgress"` with `updatedAt` > 14 days ago (if returned). Suggest a status check.
- **Unassigned** — `assignees` empty.

Apply assignee filter (if given) before bucketing — match against `assignees[].email` or display name.

## Step 3: Surface report context

Each task carries `reportTemplate.code` + the saved filter rules. Where useful, name the report in plain English (e.g. "duplicate_pages → Duplicate pages report on crawl <id>") so the user remembers what each task is about. If `identified` is set, include the count.

## Step 4: Deliverable

Markdown:

1. **TL;DR** — total active tasks, overdue count, due-this-week count.
2. **Overdue** table — title, priority, deadline, days late, assignees, report.
3. **Due this week** table — same columns.
4. **High-priority unscheduled** — items needing deadlines/assignees.
5. **Recommended next steps** — 2–3 specific moves. For status/priority changes, point at the Lumar dashboard URL (each task carries enough context to deep-link via the Core UI).

## Common pitfalls

- **No update mutation** — be explicit when the user asks to "mark this done" or "reassign". Direct them to the dashboard; don't pretend the change happened.
- **`activeOnly=true` by default** — completed tasks (`fixedAt` set) are excluded. Switch off only when the user wants history.
- **Account-scope is broad** — multi-project accounts can have hundreds of tasks. Default to `priority: ["Critical", "High"]` + a short window unless the user explicitly wants everything.
- **`segmentId` filter** only matters for projects with segments enabled; passing it to a project without segments narrows results to nothing.
