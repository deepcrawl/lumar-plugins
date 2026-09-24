---
name: analyze-run-crawl
description: Start, pause, resume, or stop and finalize a Lumar Analyze crawl and hand back its status and dashboard link. Use for one-off crawl runs outside the schedule and for controlling an existing crawl.
---

# Analyze Crawl Lifecycle

Start and control Analyze crawls without spinning on long-running status checks.

## Parameters

- **action**: `run`, `pause`, `resume`, or `stop_and_finalize`.
- **project_or_domain**: Required for `run` when no project id is supplied.
- **crawl**: Crawl id, or enough project context to find the active crawl, for pause/resume/stop-and-finalize.
- **priority**: Optional for `run` — `Default` (most cases) or `High` (time-sensitive; throttled per account).

## Run a crawl

### Step 1: Resolve account + project

1. `lumar_get_me` → confirm an Analyze-entitled account is available; ask if multiple. System admins get no account list — resolve the account by name with `lumar_search_accounts` or use a known `accountId`.
2. `analyze_list_projects` with `query` filtering on the user-supplied name/domain. Match exactly; if multiple match, ask which to crawl. Never silently pick.

### Step 2: Sanity check before queuing

A run consumes URL quota and overlaps the schedule. Before calling the mutation, do a quick read so the user isn't surprised:

1. `analyze_list_crawls` (`projectId`, `limit: 3`, newest-first).
2. Resolve the crawl's real cost before checking balances: `analyze_list_project_custom_metrics` (`projectId`) returns `project.costPerUrl` — the exact per-URL cost and the `creditAllocationTypes` pool(s) it draws from. A standard crawled URL consumes one credit of the project's module pool (`seo` for SEO projects), but enabled custom-metric containers can add per-URL costs or redirect the whole crawl to a separate pool (e.g. ContentEvals), so don't assume the module pool. Then `lumar_get_account_credits` (`accountId`) and check **every** pool named in `creditAllocationTypes`: if any required pool's balance is zero or obviously below the expected crawl size, stop and explain the quota risk. To ground the estimate in what this project actually spends, call `lumar_get_credit_usage` (`accountId`, `projectId`, `timeframe: 'last_90d'`) — its `summary` and `charges` are per-crawl rows, so you can quote what the last few runs cost instead of guessing (`crawlId` reports a single crawl). Two parts of its answer are not period totals: `monthlyBuckets` (Single Page Requester and AI Visibility credits, stored as one running row per month — quote those as monthly figures only) and `crawlsCrossingPeriodBoundary` (crawls that were still charging across one end of the period; when that list is non-empty the period total is incomplete, so say so). It needs the account's Admin role; without it, fall back to `project.costPerUrl` and the dashboard's Credit Usage page.
3. If the most recent crawl is `Queued` or `Crawling`, **stop and tell the user** there's already a crawl in flight (return its `id`, `coreUIUrl`, `statusEnum`, and `createdAt`). Ask whether to queue another one anyway — usually they'll prefer to wait.
4. If the most recent finished crawl is < 1 hour old, surface that fact and confirm the user really wants another run. Don't block — just make the cost visible.

### Step 3: Queue the crawl

1. `analyze_run_crawl` with `projectId` and `crawlPriority` (`Default` unless the user explicitly said urgent).
2. The mutation returns the new crawl with its numeric `id`, `statusEnum` (usually `Queued` or `Crawling` immediately), `crawlTypes`, `createdAt`, and `coreUIUrl`. Keep all of these for the deliverable.

### Step 4: Hand off cleanly

Tell the user:

- The new crawl id (numeric — they can paste it into other tools).
- The `coreUIUrl` as a clickable link to the Lumar dashboard for live progress.
- How to poll from here: "Call `analyze_get_crawl_summary` with crawl id `<id>` whenever you want a refreshed snapshot, or just open the dashboard link." Crawls take minutes-to-hours, so check again only when the user asks.
- If the user is on `High` priority, remind them it's throttled per account so they can't queue a stack of them.

## Control an existing crawl

### Step 1: Resolve exactly one crawl

1. With a crawl id, call `analyze_get_crawl_summary` to verify its project and current status.
2. Without a crawl id, resolve the project exactly as in the run flow, then call `analyze_list_crawls` with `status: "running"`. If multiple crawls match, ask which one; never silently choose.

### Step 2: Apply the state transition

- **Pause**: if the crawl is already `Paused`, report that state. Otherwise call `analyze_pause_crawl`. The API rejects phases that cannot be paused.
- **Resume**: only call `analyze_resume_crawl` for a `Paused` crawl. If the account has no crawl credits, surface the returned credit error and leave the crawl paused.
- **Stop and finalize**: only call `analyze_stop_and_finalize_crawl` when `statusEnum` is `Crawling` or `Paused`. This stops fetching new pages and finalizes the data collected so far. If the crawl is `Queued`, explain that it cannot be stopped until it starts crawling; if it is already `Finalizing`, report that no stop request is needed. A direct request such as "stop and finalize crawl 123" is confirmation; otherwise confirm the exact crawl and consequence before calling the tool. The crawl remains in project history, and `stopRequestedAt` confirms the request while `statusEnum` is `Finalizing`.

Return the crawl id, new status, and `coreUIUrl`. Include `pauseReason` after pausing and `stopRequestedAt` after stopping.

## Watching for completion

If the user explicitly asks "let me know when it's done" within the same conversation:

1. Estimate from the project's typical crawl duration (use the most recent finished crawl's `createdAt → finishedAt` delta as a hint).
2. Schedule a single follow-up check well after the estimate — `analyze_get_crawl_summary` against the new `id`. If still `Crawling`, report and ask whether to keep checking.

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

For a control action, use the same compact block with `Paused`, `Resumed`, or `Stopped and finalizing` as the leading verb.
