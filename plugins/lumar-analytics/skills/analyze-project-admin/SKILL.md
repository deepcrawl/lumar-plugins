---
name: analyze-project-admin
description: Create, update, or clone Lumar Analyze projects through MCP's project admin toolset. Use this skill whenever someone asks to "create an Analyze project", "set up a crawl project", "clone this project", "change crawl settings", "update the primary domain", "switch rendering on", manage uploaded URL lists, backlinks or log-summary files, or configure project-wide crawl settings from chat.
---

# Analyze Project Admin

Manage Analyze projects at the project-wide settings layer. These tools live in the higher-trust `analyze:admin` toolset because they create crawl targets and change crawl behavior for future runs.

## Parameters

- **operation**: `create`, `update`, or `clone`.
- **account**: Account to create under. Auto-pick only when unambiguous.
- **project**: Existing project name/domain/ID for update or clone.
- **name**: Project name.
- **primary_domain**: Base URL with protocol, no path/query/fragment (for example `https://www.example.com`).
- **module_code**: `SEO`, `Basic`, `Accessibility`, or `SiteSpeed`. Default `SEO`.
- **settings**: Optional common settings: crawl types, secondary domains, include subdomains, include HTTP+HTTPS, user agent code, renderer, stealth mode, max crawl rate, level/page limits, start URLs, alert emails/settings, location.
- **run_crawl_after**: Optional. Run a crawl after create/update when the user asks for immediate data.

## Step 0: Resolve account and entitlement

1. Confirm the `analyze_create_project`, `analyze_update_project`, and `analyze_clone_project` tools are present. If they are missing while other Analyze write tools exist, the connection lacks `analyze:admin`: reconnect and select **Lumar Analyze — Project admin** on the consent screen. Do not tell the user project administration is unsupported.
2. `lumar_get_me` → choose the account. System admins get no account list — resolve the account by name with `lumar_search_accounts`. Create/update require Editor role on the account.
3. Check `subscription.analyzeModulesAvailable` before create. Module mapping:
   - `SEO` → `seo`
   - `Basic` → `custom-crawl`
   - `Accessibility` → `accessibility`
   - `SiteSpeed` → `site-speed`

Every module is addon-gated, including Basic. If the module is not available, stop before calling create.

## Step 1: Create

Call `analyze_create_project` with:

- `accountId`
- `name`
- `primaryDomain`
- optional `moduleCode`
- only the settings the user explicitly requested

For the full settings surface and safe read → patch → verify workflow, load `analyze-project-settings`.

## Step 2: Update

1. Resolve the project with `analyze_list_projects`.
2. Call `analyze_update_project` with `projectId` and only the changed fields.

Module assignment is fixed at creation and cannot be changed here. Settings affect the next crawl; run `analyze_run_crawl` if the user asks to refresh immediately.

## Step 3: Clone

1. Resolve the source project with `analyze_list_projects`.
2. Call `analyze_clone_project`.
3. Tell the user the clone copies crawl settings, custom extraction, segments, etc., but starts with no crawls.
4. Run `analyze_run_crawl` only if requested.

## Deliverable

Include:

1. Project ID, name, module, and `coreUIUrl` if returned.
2. Settings created/changed.
3. Caveats for settings not exposed by MCP.
4. Any crawl queued after the admin action.

## Common pitfalls

- **Base URL format** — `primaryDomain` and secondary domains need protocol and no path/query/fragment.
- **Least change** — on update, omit fields the user did not ask to change.
- **Crawl rate limits** — `maximumCrawlRate` accepts `0.33`, `0.5`, or integers >= 1 and is capped by the account.
- **No module migration** — create a new project or clone if the module needs to change.
- **Crawl sources replace wholesale** — read existing `crawlTypes` before changing them with `analyze_update_project`. For uploaded lists, backlinks or log-summary files, follow the manual file upload workflow in `analyze-project-settings`.

## Member project visibility

Read current members and assignments with `account_list_user_visibility_tags`, paging until
`hasNextPage` is false. Use `account_set_user_visibility_tags` to replace an existing member's tags in one account. This
requires the account Admin role. Tags apply across Analyze, Protect and AI Visibility. Non-admin
members with tags see projects matching any tag; admins and members without tags see all projects.
Before sending an empty tag list, explicitly confirm that the user intends to grant access to every
project. Promoting a member to Admin clears their visibility tags. A tag cannot be deleted while
projects or users still reference it; remove those assignments first.

Untagged projects remain visible to everyone. Monitor dashboards are all-or-nothing across their
views; a board remains visible when at least one dashboard is accessible. Before linking AI Visibility
and crawl projects or editing tags on either linked project, call `project_preview_link_tag_warnings`
with the candidate link or complete proposed tag set. Show the returned warnings and let the user
continue. Linked datasource content remains readable across different tag sets: this is a known and
accepted gap in the Tag boundary. `aivis_get_run_usage` preserves full account totals and combines
hidden project demand into `Other projects` without naming those projects.
