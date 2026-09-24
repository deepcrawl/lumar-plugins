---
name: analyze-segment-preview
description: Preview how many URLs match proposed Lumar Analyze segment filters without saving a segment. Use when someone asks to preview a segment, check a segment's match count, or refine URL criteria before saving, including read-only sessions.
---

# Analyze Segment Preview

Count matching URLs using `analyze:read`. This workflow ends with a proposed filter and count; it does not save a segment or start a crawl.

## Resolve the crawl

1. Use the supplied crawl ID, or resolve the Analyze account and project with `lumar_get_me` and `analyze_list_projects`. For system admins, resolve the account with `lumar_search_accounts`.
2. Use `analyze_list_crawls` with the target `projectId`, `status: "finished"`, and `limit: 1` to choose a recent finished crawl. Ask if the project is ambiguous.
3. For an existing segment, get its canonical `filter` from `analyze_list_segments` and preserve criteria the user did not ask to change.

## Build and preview the filter

1. Discover valid CrawlUrl metric codes and predicates with `analyze_get_report_metadata` using `reportTemplateCode: "all_pages"`. Discover custom metrics with `analyze_list_project_custom_metrics`; use metrics on the `CrawlUrls` datasource.
2. Translate the criteria into exactly one filter input:
   - `filterRules`: one to twenty `{ metricCode, predicate, value }` entries. Use `filterOperator: "or"` only for OR criteria; the default is AND. Custom metrics use the returned dotted `filterMetricCode`.
   - `filter`: raw nested `_and` / `_or` / `_not` JSON for mixed logic. Custom metrics are nested objects here, such as `{ "customMetrics": { "category": { "eq": "blog" } } }`. Preserve the canonical OR-of-ANDs shape when editing a dashboard-compatible filter.
3. Call `analyze_preview_segment` with `crawlId` and the filter inputs.
4. Check `matchingUrlCount` against the intended scope. For zero or unexpectedly broad matches, verify the criteria and metric codes, refine the filter, and preview again. Keep refinements within the user's requested criteria.

Both the `filterRules` shorthand and raw nested `filter` accept at most 20 predicates per preview. Segment writes can accept larger raw filters, but those cannot be previewed in one call. Regex whitespace is normalized in the same way as segment saving.

Accessibility and SiteSpeed projects accept only URL, discovery-source, custom-extraction, and custom-metric fields joined with `_and` / `_or`, matching their segment write restrictions. They reject `_not` and other Crawl URL metrics.

An unavailable-data error is not zero matches. Choose another finished, unarchived crawl from the same project when available; otherwise report why the preview cannot be completed.

## Deliverable

Return the criteria in plain English, the exact proposed filter inputs, `matchingUrlCount`, `crawlId`, and `projectId`. Counts describe the selected crawl and can change on future crawls. Previewing does not validate segment write permissions or quotas. Stop after presenting the preview; saving requires a separately authorized workflow with write access.
