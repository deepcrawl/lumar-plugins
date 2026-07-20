---
name: analyze-url-investigation
description: Investigate a single URL in a Lumar Analyze crawl — crawl metrics, search-query performance, site-speed audits, accessibility issues, and structured-data findings, like the Resource Detail screen in Core UI. Use this skill whenever someone asks "why is this URL flagged?", "what's wrong with `<url>`?", names a specific URL and wants a full diagnostic, or asks for the accessibility/site-speed/schema breakdown of one page. Also trigger when users want to see the GSC search queries a URL ranks for.
---

# Analyze URL Investigation

Pull a Resource-Detail-style view of one URL: status, canonical, content metrics, plus the datasource-specific tabs (accessibility issues, site-speed audits, GSC queries, structured-data blocks/issues) the Lumar UI surfaces.

## Parameters

- **project_or_crawl**: Project name, domain, or specific crawl reference.
- **url**: The URL the user wants to investigate. May be a full URL or a `urlDigest` from a report row.
- **datasources**: Optional list — restrict the tabs fetched (default: all core datasources).

## Step 0: Resolve account, project, and crawl

1. `lumar_get_me` → Analyze-entitled account (system admins get no account list — resolve by name with `lumar_search_accounts`).
2. `analyze_list_projects` (`query`) → project.
3. `analyze_list_crawls` (`projectId`, `status: "finished"`, `limit: 5`) → latest finished crawl unless named.

## Step 1: Identify the page

`analyze_get_url_detail` accepts **either** `url` (the rendered absolute URL — resolved to its `urlDigest` server-side) **or** `urlId` (the `urlDigest` metric from a report row). Pass exactly one.

- If the user gave a URL, pass it as `url` directly. Matching is exact — protocol, trailing slash, query string, and casing must match the crawled URL.
- If you already have a digest (e.g. chaining from `analyze_list_report_rows`), pass it as `urlId` — no lookup roundtrip needed.
- On a `validation/url_not_found` error, the exact string wasn't in the crawl: find the crawled variant via `analyze_list_report_rows` (`reportTemplateCode: "all_pages"`, `filterRules: [{ metricCode: "url", predicate: "contains", value: <path> }]`) and retry, or tell the user the URL wasn't crawled (could be excluded by config, robots, or scope).

## Step 2: Pull the detail

`analyze_get_url_detail` (`crawlId`, `url` or `urlId`, optional `datasources`, `limit: 20`). By default it returns the core datasource set (crawl URL row + accessibility + GSC queries with landing pages + site-speed audits + structured-data blocks/issues). Drop datasources only when the user is clearly only interested in one tab.

## Step 3: Synthesise tab by tab

Render a per-section summary. Skip a section entirely if it returned zero rows — silence is signal, don't pad.

- **Crawl metrics** — status code, canonical, title, content length, hreflang, indexability flags. Call out anything that would have flagged a report (e.g. `noindex: true`, `statusCode: 404`, missing canonical).
- **Accessibility issues** — group by WCAG impact (Critical → Minor). Show the top 5 with rule + element selector.
- **Site-speed audits** — show the worst-scoring audits (lowest `score`). Opportunities (`savingsMs`) live in `CrawlSiteSpeedAuditOpportunities`, which is **not** in the default datasource set — add it to `datasources` explicitly when the user cares about speed fixes.
- **Search queries (GSC)** — top 5 queries by clicks; flag queries with high impressions but low CTR.
- **Structured-data** — list block types and issues by severity.

## Step 4: Diagnose

A few sentences answering: **why is this URL in the crawl's issue reports?** Tie each datasource finding back to a likely report match (e.g. "low Lighthouse performance score + high LCP savings → this URL is in `site_speed_lcp_slow`; accessibility violations → `accessibility_critical_issues`").

## Step 5: Deliverable

Markdown:

1. **TL;DR** — URL, status, headline problem in one sentence.
2. **Crawl-row table** — key metrics + values.
3. **Per-datasource sections** as above (omit empties).
4. **Diagnosis** — narrative tying findings to reports.
5. **Next steps** — invoke `analyze-report-deep-dive` on the implicated reports, or create a focused task.

## Common pitfalls

- **`url` matching is exact** — a typo, missing trailing slash, or protocol mismatch yields `validation/url_not_found`, not a fuzzy match. Pass exactly one of `url` / `urlId`; supplying both (or neither) is a validation error.
- **Datasource availability varies by module** — a project on the `Basic` / `SEO` module won't have accessibility audit data; `CrawlAccessibilityIssues` will return empty. Don't treat empty as broken.
- **`CrawlSearchQueries` vs `CrawlSearchQueriesWithLandingPages`** — the WithLandingPages variant is what Core UI's ResourceDetail uses. Default to it.
