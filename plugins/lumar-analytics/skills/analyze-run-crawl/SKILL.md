---
name: analyze-run-crawl
description: Trigger a fresh Lumar Analyze crawl for a project and hand back a clickable dashboard link plus a polling plan. Use this skill whenever someone asks to "run a crawl", "start a crawl now", "re-crawl my site", "kick off a crawl on <project>", or wants to crawl outside the schedule (e.g. after a release). Also trigger when users say "crawl my site" or "queue a high-priority crawl" — the skill picks priority, returns the new crawl id, and tells them how to watch progress without spinning the conversation.
---

# Analyze Run Crawl

Queue a new crawl for an Analyze project, bypassing its schedule, and hand the user back the new crawl's id, dashboard link, and a clear "what next" plan. Designed for the common "we just shipped a release, re-crawl staging now" workflow without the agent having to invent polling logic.

## Parameters

- **project_or_domain**: Project name or primary domain (e.g. `lumar.io`, "My Test Suite"). Often "my project" — ask if ambiguous.
- **priority**: Optional — `Default` (most cases) or `High` (time-sensitive; throttled per account). Ask if the user implies urgency without naming a level.

## Step 0: Resolve account + project

1. `lumar_get_me` → confirm an Analyze-entitled account is available; ask if multiple. System admins get no account list — resolve the account by name with `lumar_search_accounts` or use a known `accountId`.
2. `analyze_list_projects` with `query` filtering on the user-supplied name/domain. Match exactly; if multiple match, ask which to crawl. Never silently pick.

## Step 1: Sanity check before queuing

A run consumes URL quota and overlaps the schedule. Before calling the mutation, do a quick read so the user isn't surprised:

1. `analyze_list_crawls` (`projectId`, `limit: 3`, newest-first).
2. If the most recent crawl is `Queued` or `Crawling`, **stop and tell the user** there's already a crawl in flight (return its `id`, `coreUIUrl`, `statusEnum`, and `createdAt`). Ask whether to queue another one anyway — usually they'll prefer to wait.
3. If the most recent finished crawl is < 1 hour old, surface that fact and confirm the user really wants another run. Don't block — just make the cost visible.

## Step 2: Queue the crawl

1. `analyze_run_crawl` with `projectId` and `crawlPriority` (`Default` unless the user explicitly said urgent).
2. The mutation returns the new crawl with its numeric `id`, `statusEnum` (usually `Queued` or `Crawling` immediately), `crawlTypes`, `createdAt`, and `coreUIUrl`. Keep all of these for the deliverable.

## Step 3: Hand off cleanly

Tell the user:

- The new crawl id (numeric — they can paste it into other tools).
- The `coreUIUrl` as a clickable link to the Lumar dashboard for live progress.
- How to poll from here: "Call `analyze_get_crawl_summary` with crawl id `<id>` whenever you want a refreshed snapshot, or just open the dashboard link." Do **not** loop on `analyze_get_crawl_summary` inside this conversation — crawls take minutes-to-hours; spin checks only when the user asks.
- If the user is on `High` priority, remind them it's throttled per account so they can't queue a stack of them.

## Step 4 (optional): Watching for completion

If the user explicitly asks "let me know when it's done" within the same conversation:

1. Estimate from the project's typical crawl duration (use the most recent finished crawl's `createdAt → finishedAt` delta as a hint).
2. Schedule a single follow-up check well after the estimate — `analyze_get_crawl_summary` against the new `id`. If still `Crawling`, report and ask whether to keep checking; do not auto-loop.

There is **no MCP mutation to cancel a crawl** — if the user changes their mind, direct them to the Lumar dashboard.

## Output

A short status block:

```
Queued crawl <id> for <project name> (<primaryDomain>)
  Priority: <Default|High>
  Status:   <Queued|Crawling>
  Dashboard: <coreUIUrl>

Watch progress in the dashboard or call analyze_get_crawl_summary with crawl id <id>.
```

If a crawl was already in flight and the user chose not to queue another, return the in-flight crawl's status instead.
