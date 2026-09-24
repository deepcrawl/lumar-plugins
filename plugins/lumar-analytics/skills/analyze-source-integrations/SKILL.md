---
name: analyze-source-integrations
description: Configure Logz.io or Splunk log summary connections and project queries, or bind an Adobe Analytics report suite to an Analyze project.
---

# Analyze source integrations

Use a user session with `analyze:read`, `analyze:external`, and `analyze:admin`. Provider connection discovery, creation, and updates need a user identity; service accounts can inspect and delete existing project queries or Adobe bindings. Missing grants require reconnecting with those toolsets.

## Read, configure, verify

1. Resolve the project and read `analyze_get_project_settings`. Read existing queries with `analyze_list_logzio_project_queries` / `analyze_list_splunk_project_queries`, or the binding with `analyze_get_adobe_integration`. Follow `pagination.next_cursor` until complete before deciding whether to create or update.
2. Follow the relevant provider steps below. Use returned IDs; `id` is numeric, while Adobe discovery also returns an opaque `nodeId` for its resource tools. Project changes require Editor access and a stopped crawl.
3. Activate imports with `analyze_update_project` if needed: add `LogSummary` for Logz.io/Splunk or `GoogleAnalytics` for Adobe to the existing `crawlTypes` list. Preserve every other source. To import data without adding its URLs to the crawl, also add that source to `dataOnlyCrawlTypes`; retain another URL crawl source. These lists replace wholesale, so read them again immediately before patching. Creating a binding or enabling a query does not activate the shared crawl source automatically.
4. Re-read the integration and project settings. Report the connection, query/binding ID, enabled state, date range and whether URLs are crawled or data-only. Finish only when the requested configuration is persisted and its shared source has the intended state. Start a crawl only when requested.

## Logz.io

- `analyze_list_logzio_connections` checks connection health. Reuse a working connection or use `analyze_create_logzio_connection` with a label and API token; its region is detected automatically. `analyze_update_logzio_connection` can rename it or rotate the token.
- Use `analyze_create_logzio_project_query` or `analyze_update_logzio_project_query`. Set field names, base URL, date window and bot user-agent patterns only when needed. Omitted update fields retain their values, including advanced filters created in the app.
- `logFilters` accepts up to 20 ANDed `term`, `match`, or `regexp` conditions with optional `exclude`. The generated filter is limited to 4096 characters. This replaces the stored `queryFilter`; null or [] clears it. Show the proposed filter/query to the user when generating one, then persist it through a separate create/update call after they choose to save it. Preserve user edits.
- At most 30 queries exist per project, including disabled queries. Use `enabled: false` to keep a query for later, or `analyze_delete_logzio_project_query` to remove it.

## Splunk

- `analyze_list_splunk_connections` checks connection health. Create/update through `analyze_create_splunk_connection` / `analyze_update_splunk_connection` with the API URL and credentials for a user with search capability. `customProxy` sets its matching proxy mode; null clears both proxy fields, omission preserves them.
- Use `analyze_create_splunk_project_query` / `analyze_update_splunk_project_query`. Supply a search expression without the initial `search` command; Lumar adds it and validates the query with Splunk. When rebinding to another connection, also supply the existing query so it is validated there. Keep user-edited searches intact. Preview generated searches before a separate explicit save/update.
- Set a base URL when log paths are relative. Date range defaults to 30 days; `useLastCrawlDate` starts from the last finished crawl instead. At most 30 queries exist per project, including disabled queries. Disable with `enabled: false` or remove with `analyze_delete_splunk_project_query`.

## Adobe Analytics

1. `analyze_list_adobe_connections` discovers existing OAuth server-to-server connections and checks health. If none works, the user must configure/repair an Adobe connection in Analyze; these tools manage report-suite bindings, not Adobe credentials.
2. Pass a working connection's opaque `nodeId` to `analyze_list_adobe_report_suites`, then call `analyze_list_adobe_url_dimensions` for the chosen reportSuiteId. Use the returned dimension ID without `variables/`.
3. `analyze_create_adobe_integration` creates the project's single binding. Use `analyze_update_adobe_integration` for an existing binding, preserving omitted settings. When changing the suite or Adobe connection, supply reportSuiteId, its matching suiteName and a dimension available on that suite together; suiteName cannot be changed independently. Defaults: 90 days, 0 minimum visits; optional perPage/maxRows can be cleared with null.

## Removal and credentials

Deleting a Logz.io/Splunk connection disables its queries across every project using it and leaves them disconnected. Inspect its usage and get explicit authorization for that cross-project effect. Deleting a project query or Adobe binding leaves historical crawl data intact.

Shared crawl sources remain unchanged on removal. Keep `LogSummary` while other log queries, Log Manager sources or log uploads use it. Keep `GoogleAnalytics` while GA4 or analytics uploads use it. Only remove a shared source after checking all dependencies and retaining another URL crawl source.

Passwords and API tokens are write-only. Never repeat credentials in confirmations; identify connections by ID/label and health. Treat provider validation failures as failed saves, correct the supplied settings, and re-read state before retrying.
