---
name: analyze-custom-metrics
description: Generate, test, inspect, link, update, or remove AI-assisted Lumar Analyze custom metric containers. Use this skill whenever someone asks to "create a custom metric", "generate a metric from this prompt", "test this metric on URLs", "link the generated container to a project", "disable a custom metric", or inspect custom metric generation status.
---

# Analyze Custom Metrics

Drive the AI-assisted custom metric generation workflow: create a draft, request LLM generation, test it with Single Page Requester runs, and link the resulting custom metric container to Analyze projects.

## Parameters

- **account**: Analyze account. Auto-pick only when unambiguous.
- **project**: Project to use for test URLs or for linking the finished container.
- **generation**: Custom metric generation ID or name.
- **metric_request**: User's natural-language metric idea, optional explicit metric definitions.
- **test_urls**: Up to 10 `{ projectId, url }` entries.
- **operation**: `create`, `generate`, `test`, `inspect`, `link`, `update-link`, `unlink`, or `delete`.

## Step 0: Resolve account and entitlement

1. `lumar_get_me` → pick an Analyze-entitled account. System admins get no account list — resolve the account by name with `lumar_search_accounts`.
2. Check that the account has AI features enabled before starting generation. If not, explain that custom metric generation needs AI features enabled. Creating a generation also requires Editor role on the account.
3. Resolve `projectId` with `analyze_list_projects` when test URLs or project linking are involved.

## Step 1: Create or find the generation

For a new generation, collect:

- `name` or explicit `metrics` (one is required — without `metrics` the LLM cannot derive a name)
- optional `description` (drives LLM name/metric inference when `metrics` are omitted)
- optional `testUrls` (max 10 `{ projectId, url }` entries; the first URL is the primary one the LLM inspects)
- optional explicit `metrics` (max 5; each is `{ name, type, isList, prompt, description? }`)
- optional `htmlNeeded` (omit to let the LLM decide from the prompts)

Call `analyze_create_custom_metric_generation`. Metric names must be valid JS identifier suffixes: start with a lowercase letter, then lowercase letters, digits, or underscores.

For existing work, use `analyze_list_custom_metric_generations` (filter with `status` or `statuses` — mutually exclusive — plus `query`; soft-deleted rows need `includeDeleted: true`) and then `analyze_get_custom_metric_generation`. Pass `verbose: true` only when the generated handler source is needed.

To edit a draft, use `analyze_update_custom_metric_generation`. `testUrls` and `metrics` are full replacement lists (pass `[]` to clear; clearing `metrics` lets the next generate step infer them from `description` again) and can only change in the `Created`, `Generated`, `Failed`, `GeneratedWaitingForTests`, or `Tested` states — not while generation or tests are in flight.

## Step 2: Generate and test

1. Call `analyze_request_custom_metric_generation`. Each call consumes AI credits. Status moves `GenerationRequested` → `Generating` → `Generated` (or `Failed`).
2. Tell the user it is async. Poll with `analyze_get_custom_metric_generation` (`status`, `generatedAt`, `failedAt`, `failureReason`) only if they ask or the status is needed immediately.
3. Run tests with `analyze_run_custom_metric_generation_tests` when the generation is in the `Generated`, `GeneratedWaitingForTests`, `Failed`, or `Tested` state and test URLs exist. Each test consumes one URL against the account quota.
4. Inspect test SPR runs through `analyze_get_custom_metric_generation` (`tests`) or `analyze_get_single_page_request` by `requestId`.

If the user wants generation and tests chained, set `runTestsAfterGeneration: true` on `analyze_request_custom_metric_generation`.

## Step 3: Link to projects

When the generation has a `customMetricContainer.id`, call `analyze_link_custom_metric_container_to_project` with `projectId` and `customMetricContainerId`. Use `enabled: true` unless the user wants it installed but inactive.

Use `analyze_update_custom_metric_container_project` to change `enabled`, `containerParams`, `customJsResources`, or `customJsScripts` on an existing link. Use `analyze_unlink_custom_metric_container_from_project` to detach it from a project; confirm first because future crawls stop producing those metrics (historical values are preserved).

Once a linked project has crawled, the metrics are filterable in reports, segments, tasks, and aggregations: reference them in `filterRules.metricCode` with the dotted `customMetrics.<code>` form (`customMetrics.<code>.<member>` for object-array metrics). Custom-metric filters only work on Crawl URLs reports (e.g. `all_pages`).

## Step 4: Delete

Use `analyze_delete_custom_metric_generation` only after explicit confirmation. It soft-deletes the generation and linked `CustomMetricContainer`; project crawls stop producing those metrics, but historical metric values remain. Deletion is only allowed in non-in-flight states (`Created`, `Generated`, `Failed`, `GeneratedWaitingForTests`, `Tested`).

## Deliverable

Report:

1. Generation ID and status.
2. Metric names/types requested or produced.
3. Test URL status and failures.
4. Linked project/container IDs.
5. Next async action: wait, poll, test, link, or run a project crawl.

## Common pitfalls

- **Async state machine** — generation and tests are long-running. Do not imply completion until status says generated/tested.
- **No partial metric patching** — updating `metrics` replaces the full metric list and discards previous LLM output.
- **Generated code is large** — avoid `verbose: true` unless the user needs the handler source.
- **Project link uniqueness** — linking the same container to the same project twice fails; update the existing link instead.
