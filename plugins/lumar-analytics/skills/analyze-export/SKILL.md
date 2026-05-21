---
name: analyze-export
description: Export a Lumar Analyze report (or a filtered subset of its rows) as a CSV/XML download. Use this skill whenever someone asks to export, download, or share a report, "give me a CSV of `<report>`", "export the filtered rows", "download the broken links as CSV", or wants a file they can hand off. Also trigger when a user is about to leave a deep-dive conversation and needs the data offline.
---

# Analyze Export

Kick off an async report export with the same filter logic the Lumar UI uses, return the `reportDownloadId` immediately, and explain how to fetch the file once it's ready. The skill does **not** block the conversation polling for completion — large exports can take minutes, and a tied-up assistant is worse UX than a quick handoff.

## Parameters

- **project_or_crawl**: Project name, domain, or specific crawl reference.
- **report**: Report template code or human name.
- **filters**: Optional structured filter — same shape as `analyze-report-deep-dive`.
- **selected_metrics**: Optional list of metric codes (columns) to include. Default = all columns.
- **format**: Optional output type: `CsvZip` (default), `CompactCsvZip`, `CsvGzip`, `CsvTarGz`, `XmlZip`.
- **segment**: Optional segment scope.
- **filename**: Optional filename (3–218 chars, `[0-9a-zA-Z_-]`, no extension).
- **limit**: Optional max rows.

## Step 0: Resolve account, project, crawl, and report

Same as `analyze-report-deep-dive`. If the user is continuing from a prior deep-dive in this conversation, reuse the resolved IDs + filters without re-asking.

## Step 1: Validate filters and columns (if applicable)

If `filters` or `selected_metrics` are present and not already validated, call `analyze_get_report_metadata` (`crawlId`, `reportTemplateCode`, optional `segmentId`) and check:

- Every `filterRules[i].metricCode` exists; its `predicate` is in `allowedPredicates`.
- Every `selected_metrics` value is a valid metric code on the report.

Echo the resolved column list back so the user can correct it before kicking off the job.

## Step 2: Kick off the export

`analyze_export_report` with:

- `crawlId`, `reportTemplateCode` (required)
- `reportType` (default `Basic`)
- `segmentId`, `filterRules`, `filterOperator`, `selectedMetrics`, `outputType`, `fileName`, `limit` as supplied
- `unwindMetrics`: only when the user explicitly needs an array/object metric flattened into rows (max 1 per export).

Capture the returned `reportDownload.id` (opaque), `status` (will be `Generating`), and `createdAt`.

## Step 3: Hand off, don't block

Report back to the user:

- The `reportDownloadId` (call it the "download token").
- A one-liner: "Ask me to fetch the export when you're ready — I'll call `analyze_get_report_export` with this ID. Typical generation time is 10–60 seconds depending on row count."

**Do not loop on `analyze_get_report_export`.** Skill exits after Step 2. The user (or a follow-up turn) will re-trigger fetching when they want the file. If they ask for it immediately in the same turn, call `analyze_get_report_export` once — if status is still `Generating`, surface that and let them ask again.

## Step 4: Fetch the file (when user asks again)

`analyze_get_report_export` (`reportDownloadId`). Branch on `status`:

- `Generated` — return `fileUrl` and `expiresAt`. Remind the user that download links expire.
- `Generating` — tell them it's still in progress; suggest trying again in 30 s.
- `Failed` — explain the export failed; offer to retry with a smaller `limit` or narrower filter.

## Common pitfalls

- **`fileName` charset is strict** — alphanumerics, underscore, hyphen only; no extension. The server rejects spaces, dots, and slashes.
- **`unwindMetrics` is capped at 1** — for two array metrics, run two exports.
- **The link expires** — `expiresAt` is short. Don't cache it; re-fetch via `analyze_get_report_export` if the user comes back hours later.
- **Compressed formats default to ZIP** — `outputType: "CsvGzip"` or `CsvTarGz` is useful for very large reports where Zip's per-entry size matters.
- **No long-polling**: the polling responsibility is the user's (or a follow-up turn's), not this skill's. Don't burn assistant turns busy-waiting.
