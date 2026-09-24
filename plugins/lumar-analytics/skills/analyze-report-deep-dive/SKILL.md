---
name: analyze-report-deep-dive
description: Drill into a single Lumar Analyze report — filter URLs by metric criteria, surface patterns, and optionally create a remediation task scoped to the same filter. Use this skill whenever someone names a specific report (e.g. "duplicate pages", "broken_links", "non_indexable_urls"), wants to filter rows ("show me URLs with status 404", "pages with word count under 200"), asks for the worst offenders on a report, or says "create a task for these findings". Also trigger when users want to compare a report across two crawls — the skill explains the fan-out pattern.
---

# Analyze Report Deep-Dive

Filter and inspect URLs inside one Analyze report, then (optionally) create a tracked Lumar task with the same filter applied so remediation work is scoped to exactly the rows the user reviewed.

## Parameters

- **project_or_crawl**: Project name, domain, or specific crawl reference.
- **report**: Report template code or human name (e.g. `duplicate_pages`, "broken internal links"). Resolved against the crawl's report list.
- **filters**: Optional flat list of `{metricCode, predicate, value}` criteria, or a raw nested `filter` for mixed AND/OR/NOT logic (see Step 2).
- **segment**: Optional segment to scope to.
- **create_task**: Optional flag — if the user wants a Lumar task created from the filtered rows.

## Step 0: Resolve account, project, crawl, and report

1. `lumar_get_me` → pick Analyze-entitled account and record `me.isServiceAccount` (ask if multiple; system admins get no account list — resolve by name with `lumar_search_accounts`).
2. `analyze_list_projects` (`query`) → pick project. Capture `projectId`.
3. `analyze_list_crawls` (`projectId`, `status: "finished"`, `limit: 5`) → latest finished crawl unless named.
4. Resolve the **report template code**: if the user named a code, use it directly; otherwise `analyze_list_reports` (`crawlId`, `query: <user phrase>`, `limit: 10`) and ask if multiple match. Never silently pick.

## Step 1: Discover metrics before filtering

`analyze_get_report_metadata` (`crawlId`, `reportTemplateCode`, optional `segmentId`) — returns the report definition, available metrics, and per-metric allowed predicates. **Required before any filtering — `filterRules` or a raw nested `filter` alike** (their leaves carry the same metric predicates) so the predicate enum matches the metric type (string metrics → `contains`/`beginsWith`/etc.; numeric → `eq`/`gt`/`lt`/etc.).

If the user gave filters in natural language, map them to `{metricCode, predicate, value}` using the metadata. Confirm the mapping back to the user when the mapping is non-obvious. Custom metrics are **not** in this catalog — resolve a `customMetrics.<code>` filter via `analyze_list_project_custom_metrics` (its `filterMetricCode` + `connectionPredicates`), and only on a report whose datasource matches the metric's `datasourceCode`. Object-array metrics — custom ones as `customMetrics.<code>.<member>`, standard ones such as `schemaIssuesCountByType.schemaType` as plain `<code>.<member>` — accept only the array predicates (`arrayContains`/`arrayNotContains`, plus the `Like` pair on string members), and two member predicates may match different entries of the array rather than the same one.

## Step 2: Pull filtered rows

`analyze_list_report_rows` (`crawlId`, `reportTemplateCode`, optional `segmentId`, optional `reportType`, `filterRules`, optional `sort`, `limit`). Use `filterOperator: "or"` only when the user explicitly asked for OR semantics — default is AND. For mixed AND/OR/NOT trees the flat shorthand can't express, pass a raw nested `filter` instead (mutually exclusive with `filterRules`).

Rows are projected to the report template's `defaultMetrics` plus the identity keys `url`/`urlDigest` by default — the same columns the Core UI grid shows. If the analysis needs other columns (e.g. the metric you filtered or sorted on), pass `metrics: ["code1", "code2"]`, or `metrics: ["all"]` for every metric on the row. Default page size is 10; raise `limit` (max 100) only once a narrowing filter and/or column projection is in place.

If `pagination.has_next_page` is true and the user asked for "all", pass `pagination.next_cursor` as `cursor` on the next `analyze_list_report_rows` call to continue paging — but warn first if the total looks large (> 500 rows); offer to export instead (suggest invoking the `analyze-export` skill).

## Step 3: Surface patterns

Don't dump 100 rows verbatim. Pick a useful lens based on the metrics available:

- **Status code distribution** — if `statusCode` is in the rows, group counts by code.
- **Top offending paths / hosts** — group rows by URL prefix or path segment.
- **Worst metric values** — for numeric reports (page weight, time-to-interactive), call out the top 5.
- **Sample rows** — show the 5–10 most representative rows in a table. The response carries a top-level `coreUIUrl` linking to the same report (and `reportType` slice) in the Lumar dashboard — share it verbatim; never assemble report URLs from ids and codes yourself.

## Step 4: Cross-crawl compare (only if asked)

There is **no `analyze_compare_crawls` tool**. To compare the same report across two crawls, run `analyze_list_report_rows` against each crawl with identical `reportTemplateCode` and the identical filter shape from Step 2 — the same `filterRules`, or the same raw nested `filter` verbatim if one was used; don't down-convert it — (issue them in parallel as one batch) and diff the URL sets client-side. Tell the user when the work is non-trivial — for large reports, suggest exporting both and diffing offline.

## Step 5: Create a task (optional)

If the user opted in:

1. If `me.isServiceAccount: true`, explain that `analyze_create_report_task` is user-bound and is not registered for service-account sessions. Stop the task-creation branch and offer an interactive user session or the Lumar dashboard; do not imply the selected service-account role can unlock it.
2. Confirm: title, optional description, priority (default `Low`; suggest `High` if total ≥ 100 URLs or status codes ≥ 500), assignees (email list), deadline (ISO-8601), and whether to notify.
3. `analyze_create_report_task` (`crawlId`, `reportTemplateCode`, `taskType`, `title`, plus the same filter shape from Step 2 — `filterRules` + `filterOperator`, or the raw nested `filter` verbatim if Step 2 used one — along with `reportType` + `segmentId`; this is how the Lumar UI scopes the task to the same URL set. Don't down-convert a raw `filter` into `filterRules`: the flat form can't express mixed AND/OR/NOT trees and the task would track a different row set). `taskType` is required: `Default` = filter task, recomputed each crawl (the usual choice here); `TaggedURLs` snapshots a fixed URL set and needs the account's tagged-URLs feature plus a Crawl URLs report (e.g. `all_pages`).
4. Echo the returned task ID and the filter that was attached.

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
- **Task updates are separate** — create the scoped task here, then use `analyze-task-review` for later status, assignee, deadline, priority, or close/reopen changes.
