---
name: analyze-crawl-health
description: Snapshot a Lumar Analyze crawl — overall health, top issue reports by count, category health trend, and segment status. Use this skill whenever someone asks for a crawl summary, "how is my site doing in Lumar Analyze?", "what are the top issues on my last crawl?", "show me my crawl dashboard", or wants a fast read of a finished crawl. Also trigger when users mention technical SEO health, accessibility/SEO/site-speed issue counts, or want to know whether the health score is trending up or down.
---

# Analyze Crawl Health Snapshot

Produce a structured snapshot of a Lumar Analyze crawl: identity, total URLs, top issue reports, category health trend over time, and segment generation status. Designed to mirror the Core UI's CrawlOverview dashboard.

## Parameters

- **project_or_crawl**: Project name, domain, or a specific crawl reference ("latest", crawl ID). Often "my last crawl".
- **segment**: Optional segment name to scope the snapshot.
- **category**: Optional report category for the health trend (e.g. `security`, `page_speed`, `internal_links`, `page_content`, `structured_data`, `geo_discovery`, or a parent `rankability`/`discoverability`/`experience`/`geo_technical`/`all`). Default: derive from the crawl's `reportCategoriesSnapshot`.

## Step 0: Resolve account, project, and crawl

1. `lumar_get_me` → pick an Analyze-entitled account (ask if multiple).
2. `analyze_list_projects` with `query` filtering by the user-supplied name/domain. If multiple match, ask. Never silently pick.
3. `analyze_list_crawls` (`projectId`, `status: "finished"`, `limit: 5`). Pick the most recent finished crawl unless the user named a specific one. Note the `crawlId` and the project's `coreUiUrl` for the deliverable.

## Step 1: Headline numbers and category snapshot

Issue Step 1 + Step 2 + Step 3 in **parallel as a single batch** — they're independent reads once `crawlId` is known.

1. `analyze_get_crawl_summary` (`crawlId`) — captures crawl metadata (URL count, status, run time), `reportCategoriesSnapshot` (per-category scores), and `crawlSegments` generation status.
2. `analyze_list_reports` (`crawlId`, `issuesOnly: true`, `limit: 30`) — top issue reports across the crawl, sorted by total. Pass `segmentId` if scoping.
3. `analyze_get_health_trend` (`projectId`, `reportCategoryCode`, optional `segmentId`). If the user gave a category, use it. Otherwise pick the worst-scoring category from `reportCategoriesSnapshot` (it's the most useful trend to show). Fall back to a leaf code (e.g. `security`) if `all` returns an empty trend — the project doesn't aggregate at that level.

## Step 2: Synthesise

Sort the Step 1 report list by `basic.total` descending. Bucket into:

- **Top 5 issues** — highest non-zero totals.
- **Category leaders / laggards** — match each report's `reportTemplate.categoryCode` against `reportCategoriesSnapshot` and call out which category contributes the most issues.

Trend: from `analyze_get_health_trend` output, compute current score vs first point in the window. Annotate direction and any single-bucket move ≥ 5 points.

## Step 3: Segment status (optional)

If `crawlSegments` in Step 1 contains any segment with `generationStatus` other than `Completed`, surface them — segment-scoped reports for those segments will be empty or partial until generation finishes.

## Step 4: Deliverable

Markdown report:

1. **TL;DR** — 3 bullets: URL count, top issue category, health trend direction with delta.
2. **Crawl metadata** — project, crawl ID, start/finish times, total URLs, Core UI link.
3. **Top 5 issues** — table of report name, total URLs, category.
4. **Category snapshot** — table of category code, current score, contribution to issues.
5. **Health trend** — text sparkline or value-per-bucket table; flag any step changes.
6. **Recommended next steps** — 2–3 actions. Where useful, suggest invoking the `analyze-report-deep-dive` skill on a specific report or `analyze-url-investigation` on a problem URL.

Always include the `crawlId` and `coreUiUrl` so the user can re-run or open the dashboard.

## Common pitfalls

- **`reportCategoryCode: "all"` may return empty** — projects scoped to a single module (e.g. GEO-only) don't aggregate at `all`. Use a leaf code from `reportCategoriesSnapshot` instead.
- **Issue totals are per `reportType`** — default `Basic`. If the user is investigating a comparison crawl, also pull `Added` / `Removed` / `Missing` for context.
- **Segment generation is async** — don't draw conclusions from a segment-scoped report whose segment is still `Pending`/`Generating`/`Failed`. Tell the user to retry once generation completes.
