---
name: analyze-url-investigation
description: Investigate a single URL in a Lumar Analyze crawl — metrics, stored HTML and screenshots, accessibility fix suggestions, site-speed audits, search queries, AI title/description optimisation, and structured-data findings. Use when someone asks why a URL is flagged, wants captured page content, asks for a page's accessibility/site-speed/schema breakdown, or wants search-query-based content suggestions.
---

# Analyze URL Investigation

Pull a Resource-Detail-style view of one URL: status, canonical, content metrics, plus the datasource-specific tabs (accessibility issues, site-speed audits, GSC queries, structured-data blocks/issues) the Lumar UI surfaces.

## Parameters

- **project_or_crawl**: Project name, domain, or specific crawl reference.
- **url**: The URL the user wants to investigate. May be a full URL or a `urlDigest` from a report row.
- **datasources**: Optional list — restrict the tabs fetched (default: all core datasources).
- **include_html**: Optional — fetch the stored rendered or static page source captured by the crawl.

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
- **Site-speed audits** — show the worst-scoring audits (lowest `score`). For affected resources/elements, call `analyze_get_site_speed_audit` with `crawlId`, `urlId` and the row's `auditId`; page its items using `cursor: pagination.next_cursor`. Savings are returned in seconds (`savingsSecs` / `wastedSecs`) and KiB (`savingsKib` / `wastedKib`). Opportunities also live in `CrawlSiteSpeedAuditOpportunities`, which is **not** in the default datasource set — add it to `datasources` when needed.
- **Search queries (GSC)** — top 5 queries by clicks; flag queries with high impressions but low CTR.
- **Structured-data** — list block types and issues by severity.

When the user asks for the crawled source, call `analyze_get_crawl_url_html` with `crawlId` and exactly one of `url` or `urlId`. It returns the body inline and auto-picks stored HTML, preferring `HtmlStoring/rendered-body.html` over the static body. Pass `attachmentName: "HtmlStoring/static-body.html"` when the user specifically needs pre-JavaScript source. Page through a truncated response with `offset: nextOffset`.

Stored HTML only exists when the HTML custom metric container was enabled for that crawl. On `not_found/stored_html`, do not say the page is unreachable: offer a fresh capture with `analyze_create_single_page_request` followed by `analyze_get_single_page_request_html`. Other attachments are listed in `otherAttachments` and can be selected with `attachmentName`.

### Screenshots

Call `analyze_get_crawl_url_screenshots` with `crawlId` and `urlId` (the page's `urlDigest`). It returns signed download links for historical captures from ScreenshotStoring, plus retention expiry. Share the returned links; image bytes are not embedded. `expiredScreenshots` lists captures whose retained files have expired and cannot be downloaded.

On missing screenshots, check `analyze_get_crawl_summary` for `ScreenshotStoring` in `containers` and the crawl's archive status. Restore an archived crawl before reading its captures. A new crawl captures today's page; it cannot recover an expired historical screenshot.

### AI fix and content suggestions

Read existing accessibility fixes with `analyze_get_accessibility_issue_solution_suggestion` (`crawlId`, `issueDigest` from the accessibility row). Use the issue digest, not its WCAG rule ID or the page's URL digest.

When the user requests generation, check `tools/list`: both generation tools below require `analyze:write`, a user session, and account AI features. If absent, direct the user to a user-authenticated session or the Lumar dashboard. Existing suggestions and optimisation results remain readable from service-account sessions.

- **Accessibility**: when the read returned null, call `analyze_create_accessibility_issue_solution_suggestion` with the same inputs. It returns the generated suggestion directly, or null if none was produced. If creation reports a conflict, read the existing suggestion again.
- **Title, description and H1**: call `analyze_create_element_optimisation_request` with `crawlId` and `urlId`; optionally provide one to five unique `searchQueryDigests` from this page's `CrawlSearchQueriesWithLandingPages` rows. Omit them to use the top five by clicks. At least one search query with this landing page must exist, and Editor access is required. Poll `analyze_get_element_optimisation_request` with `requestId` from creation while status is `Created` or `Generating`. Stop at `Generated` and present the result, or at `Failed` and explain `failureReason`. Each create call starts a new request, so reuse the returned ID for polling.

These tools store suggestions in Lumar; applying them to the website is a separate action.

## Step 4: Diagnose

A few sentences answering: **why is this URL in the crawl's issue reports?** Tie each datasource finding back to a likely report match (e.g. "low Lighthouse performance score + high LCP savings → this URL is in `site_speed_lcp_slow`; accessibility violations → `accessibility_critical_issues`").

## Step 5: Deliverable

Markdown:

1. **TL;DR** — URL, status, headline problem in one sentence.
2. **Crawl-row table** — key metrics + values.
3. **Per-datasource sections** as above (omit empties).
4. **Stored source** — only when requested; identify whether it is rendered or static and note truncation.
5. **Diagnosis** — narrative tying findings to reports.
6. **Next steps** — invoke `analyze-report-deep-dive` on the implicated reports, or create a focused task.

## Common pitfalls

- **`url` matching is exact** — a typo, missing trailing slash, or protocol mismatch yields `validation/url_not_found`, not a fuzzy match. Pass exactly one of `url` / `urlId`; supplying both (or neither) is a validation error.
- **Datasource availability varies by module** — a project on the `Basic` / `SEO` module won't have accessibility audit data; `CrawlAccessibilityIssues` will return empty. Don't treat empty as broken.
- **`CrawlSearchQueries` vs `CrawlSearchQueriesWithLandingPages`** — the WithLandingPages variant is what Core UI's ResourceDetail uses. Default to it.
- **Stored HTML is opt-in crawl data** — its absence means the HTML container was not enabled or the attachment expired, not that the URL failed to crawl.
