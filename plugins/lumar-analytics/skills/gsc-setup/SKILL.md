---
name: gsc-setup
description: Connect a Google Search Console property to an AI Visibility project so page runs unlock real-search-query relevance scoring (gscQueryScore + gscQueryEvaluations). Use this skill whenever someone asks to "connect GSC", "attach Google Search Console", "set up GSC for AI Visibility", "wire up search console", or wants to know "why are my GSC scores empty?". Also trigger when users mention bringing real search-query data into their content evaluations, or ask which Google account / property is currently linked to a project.
---

# GSC Setup for AI Visibility

Wire a Google Search Console property to an AI Visibility project. Once attached, page runs gain `gscQueryScore` and `gscQueryEvaluations` (per-query relevance scoring against the page's content) — without a binding, those fields are always null.

In the UI, GSC setup lives in the self-serve Lumar GEO app only (not Lumar Analyze); updating an existing binding's filters is MCP/API-only. All tools work over MCP regardless.

## Parameters

- **project**: Which AI Visibility project to attach to — name or domain. Ask if ambiguous.
- **site_url**: The GSC property URL (e.g. `https://example.com/` or `sc-domain:example.com`). The skill lists valid options if the user doesn't know which to pick.
- **filters** (optional): What slice of GSC data to feed the scoring. Defaults are usually fine; ask only if the user mentions a country focus, click threshold, or query allow/blocklist.

## Step 0: Resolve account + project

1. `lumar_get_me` → pick an AI-Visibility-entitled account and record `me.isServiceAccount` (ask if multiple). For Lumar system admins no account list is returned — resolve the account by name with `lumar_search_accounts` instead.
2. `aivis_list_projects` to resolve the project. Capture `projectId`.

## Step 1: Discover available Google connections + GSC sites

If `me.isServiceAccount: true`, skip this discovery step: `aivis_list_google_connections` is user-bound and not registered. Existing project bindings can still be inspected and managed, and an attachment can use an already-known `googleConnectionId`; discovering or re-authenticating a user's Google connection requires an interactive user session or the Lumar dashboard.

1. In a user session, `aivis_list_google_connections` → enumerates every Google OAuth credential the authenticated user has, each with the list of `searchConsoleSites` that token can read.
2. Filter to working, GSC-capable connections:
   - `isWorking: true` — `isWorking: false` means the OAuth token failed at last use; tell the user to re-auth in the Lumar dashboard before continuing.
   - `searchConsoleSites: non-null` — null means the token wasn't granted the Search Console scope. The user needs to reconnect Google with the right scope in the Lumar dashboard.
3. If multiple connections are present, ask which one to use. Show the connection's `name` + how many sites it can read.
4. If multiple `searchConsoleSites` are available, present them and ask which site URL maps to this project. Match obvious cases automatically (e.g. project domain `lumar.io` ↔ site `https://lumar.io/` or `sc-domain:lumar.io`) but always confirm.

## Step 2: Check existing bindings on the project

Before attaching, see what's already there:

1. `aivis_list_gsc_properties` (`projectId`).
2. If a binding for the same `siteUrl` already exists, **stop and tell the user** — return the existing binding's id, filters, and underlying connection. Ask whether they want to update its filters (Step 4) or detach + re-attach with a different connection.

## Step 3: Attach the property

1. `aivis_attach_gsc_property` with `projectId`, `googleConnectionId` (from Step 1), and `siteUrl`.
2. Optional filter args — only pass what the user asked for:
   - `searchType` — `Web` (default), `Image`, or `Video`. Leave default unless asked.
   - `country` — ISO 3166-1 alpha-2 (e.g. `US`, `GB`). Omit to include all countries.
   - `includeQueries` / `excludeQueries` — case-insensitive substring lists for allow/blocklisting. Useful when the user wants to focus on branded terms or exclude noisy categories.
   - `lastNDays` — lookback window. Lumar default is fine for most cases.
   - `minClicks` — filter long-tail noise. Suggest 5–10 when the user mentions "ignore one-off queries".
   - `permissionLevel` — pass through from `searchConsoleSites[].permissionLevel` if surfaced.
3. The response returns the new binding's id, the resolved filters, and the underlying `googleConnection` summary. Keep the id for follow-up.

## Step 4: Update filters on an existing binding

When the user already has a binding and wants to change filters:

1. `aivis_update_gsc_property` (`gscPropertyId`, only the fields to change).
2. Pass `includeQueries: []` or `excludeQueries: []` to clear an existing filter list, and `country: null` to clear a country filter (revert to all-countries) — omitting a field leaves it untouched.
3. Re-pointing `siteUrl` or `googleConnectionId` is allowed but unusual — usually detach + re-attach is clearer.

## Step 5: Detach (when asked)

When the user says "disconnect GSC", "remove the search console link", etc.:

1. `aivis_detach_gsc_property` (`gscPropertyId`). Destructive — confirm first.
2. Existing page-run data is preserved; future runs simply stop computing `gscQueryScore` / `gscQueryEvaluations`.

## Step 6: Tell the user what to expect

After a successful attach:

- The binding is live, but `gscQueryScore` only appears on **new** page runs (existing rows aren't backfilled). Trigger a page run via `aivis_trigger_page_run` (per URL) or `aivis_run_project_prompts` (project-wide) to see scores quickly — or wait for the next scheduled cycle. Before a project-wide run, call `lumar_get_account_credits` and surface the combined `aiVisibility` balance.
- If the user wants to verify the scoring is working, point them at `aivis_get_page_scores` or `aivis_list_page_runs` (with `verbose: true` to see the `gscQueryEvaluations` array) once a fresh run completes.

## Output

```
Attached GSC property <siteUrl> to <project name>
  Binding id: <gscPropertyId>
  Connection: <connection name> (<connectionType>)
  Filters: searchType=<Web|Image|Video>, country=<code or "all">, lastNDays=<n>, minClicks=<n>
  Include/exclude queries: <summary or "none">

gscQueryScore + gscQueryEvaluations will populate on the next page run for this project.
```
