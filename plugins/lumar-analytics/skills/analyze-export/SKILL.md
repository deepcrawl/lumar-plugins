---
name: analyze-export
description: Export built-in or custom Lumar Analyze report rows as CSV/XML, or list, download, and delete existing report exports. Use when someone needs report data offline or wants to manage exported files.
---

# Analyze Export

Kick off an async report export with the same filter logic the Lumar UI uses, return the `reportDownloadId` immediately, and explain how to fetch the file once it's ready. The skill does **not** block the conversation polling for completion — large exports can take minutes, and a tied-up assistant is worse UX than a quick handoff.

## Parameters

- **project_or_crawl**: Project name, domain, or specific crawl reference.
- **report**: Built-in report template code, custom report template ID, or human name.
- **filters**: Optional structured filter — same shape as `analyze-report-deep-dive`.
- **selected_metrics**: Optional list of metric codes (columns) to include. Default = all columns.
- **format**: Optional output type: `CsvZip` (default), `CsvGzip`, `CsvTarGz`, or `XmlZip` (Crawl URLs datasource only).
- **segment**: Optional segment scope.
- **filename**: Optional filename (3–218 chars, `[0-9a-zA-Z_-]`, no extension).
- **limit**: Optional max rows for built-in exports only; custom exports have no row-limit option.

## Step 0: Resolve account, project, crawl, and report

Same as `analyze-report-deep-dive`. If the user is continuing from a prior deep-dive in this conversation, reuse the resolved IDs + filters without re-asking.

For custom reports, resolve the numeric `customReportTemplateId` with `analyze_list_custom_report_templates`. Inspect its columns using `analyze_get_custom_report_template` with the project ID and template code. Use the custom export tool with the numeric ID; the built-in export tool accepts only built-in template codes.

If the user wants an existing file, go straight to **Manage existing exports** below.

## Step 1: Validate filters and columns (if applicable)

For built-in reports, validate filters and columns with `analyze_get_report_metadata` (`crawlId`, `reportTemplateCode`, optional `segmentId`). For custom reports, use the resolved columns and predicates from `analyze_get_custom_report_template`; use its `basedOnReportTemplateCode` with `analyze_get_report_metadata` for the base catalog. Check:

- Every `filterRules[i].metricCode` exists; its `predicate` is in `allowedPredicates`.
- Every `selected_metrics` value is a valid metric code on the report.
- Custom metrics are **not** in that catalog: validate any `customMetrics.<code>` filter or column against `analyze_list_project_custom_metrics` instead — use its `filterMetricCode` verbatim when constructing the filter, require the requested predicate to appear in that metric's `connectionPredicates`, and require the metric's `datasourceCode` to match the report's datasource.

For a custom report's displayed columns, pass its resolved saved column codes as `selectedMetrics`; omitting this argument uses the backend's export columns, which may differ from the custom report's display.

## Step 2: Kick off the export

For built-in reports, call `analyze_export_report` with:

- `crawlId`, `reportTemplateCode` (required)
- `reportType` (default `Basic`)
- `segmentId`, `filterRules`, `filterOperator` (or a raw nested `filter` for mixed AND/OR/NOT trees — supply one or the other), `selectedMetrics`, `outputType`, `fileName`, `limit` as supplied
- `unwindMetrics`: only when the user explicitly needs an array/object metric flattened into rows (max 1 per export).

For custom reports, call `analyze_export_custom_report` with `crawlId` and `customReportTemplateId`. It accepts `reportType`, `segmentId`, filters, `selectedMetrics`, `outputType`, `fileName`, and `unwindMetrics` as above. The API has no custom-export `limit`, `taskId`, or `aggregateCode`. Export generation combines the crawl's saved custom template filter with the supplied filters and segment scope, including on diff slices; custom row previews on diff slices can therefore differ from exported rows.

Capture the returned `reportDownload.id` (opaque), `status` (will be `Generating`), and `createdAt`.

## Step 3: Hand off, don't block

Report back to the user:

- The `reportDownloadId` (call it the "download token").
- A one-liner: "Ask me to fetch the export when you're ready — I'll call `analyze_get_report_export` with this ID. Typical generation time is 10–60 seconds depending on row count."

**Do not loop on `analyze_get_report_export`.** Skill exits after Step 2. The user (or a follow-up turn) will re-trigger fetching when they want the file. If they ask for it immediately in the same turn, call `analyze_get_report_export` once — if status is still `Generating`, surface that and let them ask again.

## Step 4: Fetch the file (when user asks again)

`analyze_get_report_export` (`reportDownloadId`). Branch on `status`:

- `Generated` — return `fileURL`. It's a short-lived presigned link — remind the user it expires. An optional `fileName` override (same 3–218 char charset) can be passed here to rename the download.
- `Generating` (or `Draft`) — tell them it's still in progress; suggest trying again in 30 s.
- There is **no `Failed` status** — if an export sits in `Generating` unusually long, offer a narrower filter (or a smaller `limit` for built-in exports).

## Manage existing exports

1. Call `analyze_list_report_exports` with `crawlId`, optional `segmentId`, `limit` (default 20, max 100), and `cursor`. Follow `pagination.next_cursor` while looking for a matching file. Results include both built-in and custom exports, identified by `reportTemplate` or `customReportTemplate`, plus status, columns, and filters. Task-linked files are excluded by the API.
2. For downloads, pass the chosen opaque `id` unchanged as `reportDownloadId` to `analyze_get_report_export`, then follow Step 4. This also refreshes expired links.
3. For user-requested deletion, resolve the exact export from this list or a previously returned token and call `analyze_delete_report_export`. It removes the export record and requests file removal; the report and crawl remain available. The API rejects deleting task-linked exports.

If creation reports that an export already exists, find it in the list and fetch its link. Delete an existing export only when the user has requested deletion or replacement.

## Common pitfalls

- **`fileName` charset is strict** — alphanumerics, underscore, hyphen only; no extension. The server rejects spaces, dots, and slashes.
- **`unwindMetrics` is capped at 1** — for two array metrics, run two exports.
- **The link expires** — `fileURL` is a short-lived presigned URL. Don't cache it; re-fetch via `analyze_get_report_export` to mint a fresh one if the user comes back hours later.
- **Compressed formats default to ZIP** — `outputType: "CsvGzip"` or `CsvTarGz` is useful for very large reports where Zip's per-entry size matters.
- **No long-polling**: the polling responsibility is the user's (or a follow-up turn's), not this skill's. Don't burn assistant turns busy-waiting.
