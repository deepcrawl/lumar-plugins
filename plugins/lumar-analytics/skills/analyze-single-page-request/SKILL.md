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
- **verbose**: Optional. Use only when the user needs raw outputs, response headers, signed output URLs, or crawl settings snapshots.

## Step 0: Resolve project

1. `lumar_get_me` → Analyze-entitled account.
2. `analyze_list_projects` with `query` to resolve `projectId`.

If the user only gave a `requestId`, still resolve the project: SPR lookups are project-scoped.

## Step 1: Choose the mode

**Create a new SPR**

Call `analyze_create_single_page_request` with:

- `projectId`
- `url`
- `skipLinks: true` unless the user needs link graph data

Return the `requestId`, initial status, and `expiresAt`.

**Inspect or poll an existing SPR**

Call `analyze_get_single_page_request` with `projectId`, `requestId`, and `verbose` only when needed. If the user does not know the request ID, call `analyze_list_single_page_requests` with `projectId`, optional `url`, and `limit: 10`.

## Step 2: Interpret results

For finished runs, summarise:

- status and timing
- failure reason, if any
- HTTP/status/crawl output highlights
- custom metric or extraction outputs if returned
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
- **Project settings are inherited** — user agent, renderer, robots, headers, and related crawl profile settings come from the project. Change those in the dashboard before triggering if needed.
- **Heavy verbose payloads** — request `verbose: true` only when raw outputs or signed artifacts are needed.
- **Expiry** — SPR results and signed output URLs expire after `expiresAt` (90 days).
