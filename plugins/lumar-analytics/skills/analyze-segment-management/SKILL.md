---
name: analyze-segment-management
description: Create, update, or delete Lumar Analyze segments from structured URL filter rules. Use this skill whenever someone asks to "create a segment", "save these URLs as a segment", "segment pages where status is 404", "update the segment filter", "rename this segment", or "delete a segment". Also trigger when users want report rows, health trends, or future crawls scoped to a reusable URL subset.
---

# Analyze Segment Management

Create and maintain Analyze segments: reusable URL subsets that slice reports and health trends. Segments are defined by CrawlUrl metric filter rules and populate when the next crawl finishes.

## Parameters

- **project**: Analyze project name/domain. Required unless the user provides a segment ID and only wants deletion.
- **segment**: Segment name or ID for update/delete.
- **criteria**: Natural-language URL rules, report filters, explicit `filterRules`, or a raw nested `filter`.
- **operation**: `create`, `update`, `delete`, `list`, or `inspect`. Infer from the request.
- **run_crawl_after**: Optional. Only run a crawl after create/update if the user asks or needs fresh segment data immediately.

## Step 0: Resolve project and current segments

1. `lumar_get_me` → pick an Analyze-entitled account. System admins get no account list — resolve the account by name with `lumar_search_accounts` instead.
2. `analyze_list_projects` with `query` if the project is named.
3. `analyze_list_segments` with `projectId` to find existing segments or check for name collisions.

Ask when multiple projects or segments match. Never silently update or delete a segment from an ambiguous name.

## Step 1: Build filter rules

For create/update with criteria:

1. Get a recent finished crawl via `analyze_list_crawls` (`projectId`, `status: "finished"`, `limit: 1`).
2. Call `analyze_get_report_metadata` with `crawlId` and `reportTemplateCode: "all_pages"` to discover valid CrawlUrl metric codes and allowed predicates.
3. Translate the user criteria into `filterRules` and `filterOperator`, or — when the logic mixes AND/OR/NOT in ways a flat list cannot express — a raw nested `filter`.
4. If a metric or predicate is uncertain, show the likely interpretation and ask before writing.

Two filter inputs, mutually exclusive — pass exactly one:

- **`filterRules` + `filterOperator`** (preferred shorthand): same shape as `analyze_list_report_rows`. Rules are capped at 20. Use `filterOperator: "or"` only when the user asked for OR semantics; default is AND. The server writes the segment in the nested UI-compatible format (an outer OR of AND groups) automatically. Custom metrics are referenced with the dotted `customMetrics.<code>` form in `metricCode`.
- **`filter`** (raw nested escape hatch): the exact `_and` / `_or` / `_not` ConnectionFilter JSON the API and dashboard use, sent verbatim. Metric leaves are `{ "<metricCode>": { "<predicate>": value } }`; custom metrics must be genuinely nested (`{ "customMetrics": { "<code>": { ... } } }`), never dotted keys. To keep the segment editable in the dashboard filter UI, stay with the OR-of-ANDs shape: `{ "_or": [ { "_and": [ ... ] } ] }` (deeper nesting and `_not` crawl correctly but render read-only).

When editing an existing segment, read its `filter` field from `analyze_list_segments` (the canonical nested JSON that round-trips), change what you need, and pass the result straight back to `analyze_update_segment` as `filter` — no conversion. Prefer `filter` over the raw stored `crawlUrlFilter`, which may be in a legacy flat shape.

## Step 2: Write

- Create: `analyze_create_segment` with `projectId`, `name`, optional `group`, and the filter (`filterRules` + optional `filterOperator`, or raw `filter`). A filter is required.
- Update: `analyze_update_segment` with `segmentId` plus only changed fields. When `filterRules` or `filter` is passed it fully replaces the existing filter — there is no partial merge.
- Delete: confirm first, then `analyze_delete_segment`. Deletion removes the segment definition and generated per-crawl segment data, and unscopes tasks attached to that segment.

## Step 3: Aftercare

New or changed segment filters do not backfill historic crawls. Tell the user the segment will populate on the next crawl. If they asked for immediate data, call `analyze_run_crawl` after the segment write and return the queued crawl ID/dashboard URL.

For verification, use `analyze_list_segments` again. For crawl-level generation status after a crawl starts or finishes, call `analyze_list_segments` with `crawlId`.

## Deliverable

Include:

1. Segment name and ID.
2. Filter rules in plain English.
3. Whether data is available now or waits for the next crawl.
4. Any crawl you queued.

## Common pitfalls

- **Metadata first** — do not invent metric codes or predicates. Use `analyze_get_report_metadata` on `all_pages`. Custom metric codes are not in that catalog — discover them via the project's SPR context or custom-metric tools.
- **One filter input** — `filterRules` and `filter` are mutually exclusive; passing both is a validation error.
- **Updates replace filters** — preserve the old filter unless the user asked to change it.
- **Legacy "Unsupported segment format"** — segments saved in an old flat shape show as uneditable in the dashboard; re-saving the segment through `analyze_update_segment` rewrites it in the nested format and restores editability.
- **No historic backfill** — new definitions apply to future crawls.
- **Delete is destructive** — confirm before calling `analyze_delete_segment`.
