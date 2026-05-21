---
name: analyze-report-deep-dive
description: Drill into a single Lumar Analyze report — filter URLs by metric criteria, surface patterns, and optionally create a remediation task scoped to the same filter. Use this skill whenever someone names a specific report (e.g. "duplicate pages", "broken_links", "non_indexable_urls"), wants to filter rows ("show me URLs with status 404", "pages with word count under 200"), asks for the worst offenders on a report, or says "create a task for these findings". Also trigger when users want to compare a report across two crawls — the skill explains the fan-out pattern.
---

# Analyze Report Deep-Dive

Filter and inspect URLs inside one Analyze report, then (optionally) create a tracked Lumar task with the same filter applied so remediation work is scoped to exactly the rows the user reviewed.

## Parameters

- **project_or_crawl**: Project name, domain, or specific crawl reference.
- **report**: Report template code or human name (e.g. `duplicate_pages`, "broken internal links"). Resolved against the crawl's report list.
- **filters**: Optional list of `{metric, predicate, value}` criteria the user wants applied to the rows.
- **segment**: Optional segment to scope to.
- **create_task**: Optional flag — if the user wants a Lumar task created from the filtered rows.

## Step 0: Resolve account, project, crawl, and report

1. `lumar_get_me` → pick Analyze-entitled account (ask if multiple).
2. `analyze_list_projects` (`query`) → pick project. Capture `projectId`.
3. `analyze_list_crawls` (`projectId`, `status: "finished"`, `limit: 5`) → latest finished crawl unless named.
4. Resolve the **report template code**: if the user named a code, use it directly; otherwise `analyze_list_reports` (`crawlId`, `query: <user phrase>`, `limit: 10`) and ask if multiple match. Never silently pick.

## Step 1: Discover metrics before filtering

`analyze_get_report_metadata` (`crawlId`, `reportTemplateCode`, optional `segmentId`) — returns the report definition, available metrics, and per-metric allowed predicates. **Required before any `filterRules` call** so the predicate enum matches the metric type (string metrics → `contains`/`beginsWith`/etc.; numeric → `eq`/`gt`/`lt`/etc.).

If the user gave filters in natural language, map them to `{metricCode, predicate, value}` using the metadata. Confirm the mapping back to the user when the mapping is non-obvious.

## Step 2: Pull filtered rows

`analyze_list_report_rows` (`crawlId`, `reportTemplateCode`, optional `segmentId`, optional `reportType`, `filterRules`, optional `sort`, `limit: 100`). Use `filterOperator: "or"` only when the user explicitly asked for OR semantics — default is AND.

If `pagination.has_next_page` is true and the user asked for "all", continue paging — but warn first if the total looks large (> 500 rows); offer to export instead (suggest invoking the `analyze-export` skill).

## Step 3: Surface patterns

Don't dump 100 rows verbatim. Pick a useful lens based on the metrics available:

- **Status code distribution** — if `statusCode` is in the rows, group counts by code.
- **Top offending paths / hosts** — group rows by URL prefix or path segment.
- **Worst metric values** — for numeric reports (page weight, time-to-interactive), call out the top 5.
- **Sample rows** — show the 5–10 most representative rows in a table; link out via `coreUiUrl` if returned.

## Step 4: Cross-crawl compare (only if asked)

There is **no `analyze_compare_crawls` tool**. To compare the same report across two crawls, run `analyze_list_report_rows` against each crawl with identical `reportTemplateCode` + `filterRules` (issue them in parallel as one batch) and diff the URL sets client-side. Tell the user when the work is non-trivial — for large reports, suggest exporting both and diffing offline.

## Step 5: Create a task (optional)

If the user opted in:

1. Confirm: title, optional description, priority (default `Low`; suggest `High` if total ≥ 100 URLs or status codes ≥ 500), assignees (email list), deadline (ISO-8601), and whether to notify.
2. `analyze_create_report_task` (`crawlId`, `reportTemplateCode`, `title`, plus the same `filterRules` + `filterOperator` + `reportType` + `segmentId` from Step 2 — this is how the Lumar UI scopes the task to the same URL set).
3. Echo the returned task ID and the filter that was attached.

## Step 6: Deliverable

Markdown response:

1. **TL;DR** — report name, total matching rows, filter summary in plain English.
2. **Pattern summary** — chosen lens from Step 3 with counts.
3. **Sample rows table** — small enough to scan.
4. **Next-step suggestions** — export with the `analyze-export` skill, drill into a row with `analyze-url-investigation`, or create a task (if not done in this run).
5. **Task confirmation** (only if Step 5 ran).

## Common pitfalls

- **Predicate mismatch** — applying a `contains` predicate to a numeric metric returns no rows or an error. Always go through `analyze_get_report_metadata` first; the `allowedPredicates` list is authoritative.
- **`filterRules` cap is 20** — collapse near-duplicate predicates rather than padding the array.
- **`reportType` defaults to `Basic`** — for a comparison crawl, "newly added issues" lives under `reportType: "Added"`, not Basic. Ask the user when the crawl is a comparison.
- **No update mutation for tasks** — once created, the task can only be edited in the Lumar dashboard. Set fields correctly the first time.
