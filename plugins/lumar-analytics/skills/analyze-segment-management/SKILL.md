---
name: analyze-segment-management
description: Create, update, or delete Lumar Analyze segments from structured URL filter rules. Use this skill whenever someone asks to "create a segment", "save these URLs as a segment", "segment pages where status is 404", "update the segment filter", "rename this segment", or "delete a segment". Also trigger when users want report rows, health trends, or future crawls scoped to a reusable URL subset.
---

# Analyze Segment Management

Create and maintain Analyze segments: reusable URL subsets that slice reports and health trends. Segments are defined by CrawlUrl metric filter rules and populate when the next crawl finishes.

## Parameters

- **project**: Analyze project name/domain. Required unless the user provides a segment ID and only wants deletion.
- **segment**: Segment name or ID for update/delete.
- **criteria**: Natural-language URL rules, report filters, or explicit `filterRules`.
- **operation**: `create`, `update`, `delete`, `list`, or `inspect`. Infer from the request.
- **run_crawl_after**: Optional. Only run a crawl after create/update if the user asks or needs fresh segment data immediately.

## Step 0: Resolve project and current segments

1. `lumar_get_me` → pick an Analyze-entitled account.
2. `analyze_list_projects` with `query` if the project is named.
3. `analyze_list_segments` with `projectId` to find existing segments or check for name collisions.

Ask when multiple projects or segments match. Never silently update or delete a segment from an ambiguous name.

## Step 1: Build filter rules

For create/update with criteria:

1. Get a recent finished crawl via `analyze_list_crawls` (`projectId`, `status: "finished"`, `limit: 1`).
2. Call `analyze_get_report_metadata` with `crawlId` and `reportTemplateCode: "all_pages"` to discover valid CrawlUrl metric codes and allowed predicates.
3. Translate the user criteria into `filterRules` and `filterOperator`.
4. If a metric or predicate is uncertain, show the likely interpretation and ask before writing.

Use the same `filterRules` shape as `analyze_list_report_rows`. Rules are capped at 20. Use `filterOperator: "or"` only when the user asked for OR semantics; default is AND.

## Step 2: Write

- Create: `analyze_create_segment` with `projectId`, `name`, optional `group`, `filterRules`, and optional `filterOperator`.
- Update: `analyze_update_segment` with `segmentId` plus only changed fields. When `filterRules` is passed it fully replaces the existing filter.
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

- **Metadata first** — do not invent metric codes or predicates. Use `analyze_get_report_metadata` on `all_pages`.
- **Updates replace filters** — preserve the old filter unless the user asked to change it.
- **No historic backfill** — new definitions apply to future crawls.
- **Delete is destructive** — confirm before calling `analyze_delete_segment`.
