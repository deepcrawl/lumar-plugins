---
name: analyze-single-page-request
description: Run or inspect Lumar Analyze Single Page Requester jobs for one URL against a project's current crawl settings, custom metrics, and custom extractions. Use this skill whenever someone asks to "test this URL", "run a single page request", "spot-check this page", "preview what the crawler sees", "why did this SPR fail?", or wants quick page-level crawl output without running a full crawl.
---

# Analyze Single Page Request

Use Single Page Requester (SPR) for one-off URL crawls. It runs one URL through the project's current crawl settings, including attached custom metrics and custom extractions, and usually finishes in seconds to minutes.

## Parameters

- **project**: Analyze project name/domain.
- **url**: Absolute URL to test.
- **request_id**: Existing SPR `requestId` to inspect.
- **include_links**: Optional. Default false (`skipLinks: true`) for speed; set true when the user needs outgoing link data.
- **profile_overrides**: Optional per-run `userAgentCode`, `userAgentIsMobile`, `useRenderer`, and `useStealthMode`.
- **output_name**: Optional named result document, such as `publishedDcCrawlerStep` or `publishedDcCrawlerLinkSeo`.
- **verbose**: Optional. Use only when the user needs raw outputs, response headers, signed output URLs, or crawl settings snapshots.

## Step 0: Resolve project

1. `lumar_get_me` → Analyze-entitled account. System admins get no account list — resolve the account by name with `lumar_search_accounts`.
2. `analyze_list_projects` with `query` to resolve `projectId`.

If the user only gave a `requestId`, still resolve the project: SPR lookups are project-scoped.

## Step 1: Choose the mode

**Create a new SPR**

Call `analyze_create_single_page_request` with:

- `projectId`
- `url`
- `skipLinks: true` (the default) unless the user needs link graph data — `skipLinks: false` only populates link reports on SEO-module projects
- any requested one-run crawl-profile overrides: `userAgentCode`, `userAgentIsMobile`, `useRenderer`, `useStealthMode`

Return the `requestId`, initial status, and `expiresAt`.

**Inspect or poll an existing SPR**

Call `analyze_get_single_page_request` with `projectId`, `requestId`, and `verbose` only when needed. If the user does not know the request ID, call `analyze_list_single_page_requests` with `projectId`, optional `url` (exact match) or `status` filter, and `limit: 10`. Runs spawned by custom-metric generation jobs are hidden unless `includeAutomated: true`.

**Read the captured HTML**

The `*DownloadUrl` fields on a run are presigned links an MCP client cannot open. To read the page body as text, call `analyze_get_single_page_request_html` with `projectId`, `requestId`, and optional `bodyType`: `rendered` (default — the post-JavaScript DOM) or `static` (the raw pre-JS HTML). The response windows the body by `maxChars` (default 50000, max 80000) from `offset`; when `truncated` is true, call again with `offset: nextOffset` to page through. Very large bodies hit a paging ceiling signalled by `readLimitReached`. The run must be `Finished`; a `rendered` body only exists when the run used the renderer (fall back to `static`).

**Read metrics, links, and other result documents**

Call `analyze_get_single_page_request_output` with `projectId`, `requestId`, and `name`. Prefer:

- `publishedDcCrawlerStep` for all page metrics, including custom metrics and extractions.
- `publishedDcCrawlerLinkSeo` for outgoing-link results.
- the relevant accessibility or site-speed output named by `availableOutputs` when those modules ran.

The name matches exactly first, then by prefix. If the correct name is unclear, call `analyze_get_single_page_request` with `verbose: true` to inspect `signedOutputs`, or use the `availableOutputs` returned by a `not_found/single_page_request_output` error. Output content uses the same `maxChars`, `offset`, `truncated`, and `nextOffset` paging pattern as HTML.

## Step 2: Interpret results

For finished runs, summarise:

- status and timing
- failure reason, if any
- HTTP/status/crawl output highlights
- custom metric, extraction, link, accessibility, or site-speed output requested by the user
- signed output URLs when `verbose: true` returns them

Do not poll indefinitely. For a newly queued run, one follow-up status check is enough unless the user explicitly asks you to wait.

## Deliverable

Give a compact result:

1. `requestId` and status.
2. What settings context matters (renderer, custom metrics, custom extractions) if visible.
3. Findings or failure reason.
4. What to run next: poll with the same `requestId`, run a full crawl, or adjust project settings in the dashboard.

## Common pitfalls

- **Project-scoped IDs** — a `requestId` from another project will not resolve.
- **Project settings are inherited by default** — the four common profile settings can be overridden per run; robots, headers, cookies, and other settings still come from the project and must be changed there first.
- **Heavy verbose payloads** — request `verbose: true` only to discover raw outputs or inspect the settings snapshot. Prefer `analyze_get_single_page_request_html` and `analyze_get_single_page_request_output` over signed URLs.
- **Expiry** — SPR results and signed output URLs expire after `expiresAt` (90 days). Expired bodies need a fresh run via `analyze_create_single_page_request`.
