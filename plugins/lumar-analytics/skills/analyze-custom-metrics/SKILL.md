---
name: analyze-custom-metrics
description: How to discover a project's custom metrics and the extensions it could enable, tell where each one came from (product module, Lumar extension such as ContentEvals, AI-generated, account-authored, uploaded), understand what each costs in credits, read or filter their values, and reach the custom reports that extensions ship with. Use when asked what custom metrics a project has, what extensions are available, what enabling one costs, why a custom metric is missing from a report, which crawls have stored HTML or screenshots available (including which archived crawl to unarchive), or to filter/segment/export on one.
---

# Work with Analyze custom metrics

Custom metrics are extra columns a container contributes to a crawl's URL rows.
They behave differently from standard datasource metrics in three ways that
trip agents up:

1. They are **not** in `analyze_get_report_metadata`'s metric catalog.
2. They are **not** in the default column projection of `analyze_list_report_rows`.
3. They **cannot** be aggregated or used as dimensions in `analyze_explore_urls_aggregates`.

So always start from discovery.

## 1. Discover what the project has

```
analyze_list_project_custom_metrics(projectId)
```

Returns `metrics[]` (one row per column, each with a ready-to-use
`filterMetricCode`) and `containers[]` (the linked containers, including any
that currently produce nothing). Narrow with `origins` or `query`.

Use `analyze_get_custom_metric_container(projectId, customMetricContainerId)`
when you need one container's parameters (`paramsSchema`, the configured
`containerParams`), its requirements, or its version status.

For "what could we turn on?" — a different question — use:

```
analyze_list_available_custom_metric_containers(projectId, verbose?)
```

That is the catalog of Lumar-authored global extensions the project can link,
already filtered server-side by the account's feature flags and the project's
module. It is also the only way to find a `customMetricContainerId` to pass to
`analyze_link_custom_metric_container_to_project`. Notable entries:

- **ContentEvals** — agentic content analysis (content precision, semantic
  recall, uniqueness vs. search results, GSC query evaluation, LLM brand
  monitoring). Bills against its own ContentEvals credit pool.
- **GEO**, **SemanticRelevance**, **StructuredData**, **LanguageDetection**
- **HtmlStoring** / **ScreenshotStoring** — page capture; HtmlStoring is what
  makes `analyze_get_crawl_url_html` work for a crawl.

Containers backing a first-class module (Accessibility, SiteSpeed) are
deliberately absent — they arrive with the module, not via a link.

## 2. Read the `origin` before you interpret a metric

| origin            | what it means                                                                                                                                                                                           | who controls it              |
| ----------------- | ------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- | ---------------------------- |
| `lumar_module`    | Ships with a first-class module (Accessibility, SiteSpeed, SEO, Basic). `moduleCode` names it.                                                                                                          | Module addon entitlement     |
| `lumar_extension` | Lumar-authored global container linked per project — ContentEvals, stored HTML, and similar. See `billing` (section 3) for what it costs and `requiredAddons` / `requiredFeatureFlags` for entitlement. | Account links it per project |
| `ai_generated`    | Built by the Analyze AI wizard on this account. `generation` links back to the draft.                                                                                                                   | The account's own users      |
| `account_custom`  | Account-authored container, not generated, not global.                                                                                                                                                  | The account's own users      |
| `uploaded`        | Values come from an uploaded data file, not executed container code.                                                                                                                                    | The account's own uploads    |

This distinction matters when advising: a `lumar_module` or `lumar_extension`
metric behaves the same for every customer and is documented product surface, so
describe it as a Lumar feature. An `ai_generated` or `account_custom` metric was
defined by this account — its semantics live in the container's own
description/prompt, so quote those rather than inferring meaning from the name.

## 3. Check what it costs before recommending one

Never say "just enable it" without reading the container's `billing` block.
There are three distinct models:

| `billing.model`        | What happens                                                                                            |
| ---------------------- | ------------------------------------------------------------------------------------------------------- |
| `free`                 | Adds no per-URL cost. The crawl still costs its baseline 1 credit/URL.                                  |
| `additional_credits`   | `addedCostPerUrl` extra credits per crawled URL, on top of the baseline, from the module's normal pool. |
| `separate_credit_pool` | Redirects the **whole crawl** to `billing.creditPool` instead of the module's normal credits.           |

The third case has a subtlety worth stating to users: when
`zeroesOtherContainerCosts` is true (ContentEvals today), the crawler forces
every other container and feature per-URL cost to zero, so the crawl costs
exactly 1 credit per URL — but drawn from that pool, not from SEO crawl credits.
Enabling it therefore changes _which_ budget the crawl spends, not just how much.

`analyze_list_project_custom_metrics` also returns `project.costPerUrl` —
graph-api's own preview of the current total per URL, its component breakdown,
and the pool(s) it draws from. Prefer quoting that over adding up container costs
yourself. Pair it with `lumar_get_account_credits` to answer "can we afford
this crawl?", and with `lumar_get_credit_usage` (`includeCostBreakdown: true`)
to answer "what did this container actually cost us?" — its
`summary.byCustomMetricContainer` totals past spend per container. Read
`creditsUsed` there, not `ratePerUrl`: Lumar stores container costs as a
per-URL rate plus a URL count, so the rate alone (often 0.1) is not the amount
charged. A group is only a single figure when it is marked `exact`; otherwise
`creditsUsed` is a lower bound and `creditsUsedUpperBound` the upper, because a
crawl spanning several credit pools stores its container counts once per pool
with an overlap the ledger does not record — quote the range, not one end of
it. Credit usage needs the account's Admin role.

## 4. Read the values

First check the metric's `datasourceCode` (echoed as `readVia`). Custom metrics
come in two scopes and they are read from different places:

- `CrawlUrls` — per-URL metrics. Everything below applies.
- `CrawlProjectMetricsItems` — **project-level** metrics, produced by containers
  whose tableType is `ProjectMetricsItem`. These rows describe the crawl as a
  whole (keyed by `itemType` / `itemKey`) and have **no URL**, so
  `analyze_get_url_detail` can never return them. Read them with
  `analyze_list_report_rows` on the `all_crawl_project_metrics_items` report,
  and filter/sort with the same `customMetrics.<code>` form. That report only
  exists on crawls where a project-metrics container actually ran, so its
  absence from `analyze_list_reports` means "none ran", not "not supported".

For per-URL metrics:

- **One URL:** `analyze_get_url_detail` includes custom metrics by default.
- **Many URLs:** `analyze_list_report_rows` omits them from the default
  projection. Pass `metrics: ["customMetrics"]` for all of them as one object,
  `metrics: ["<code>", ...]` for specific columns, or `metrics: ["all"]` for the
  whole row (heavy — expect to lower `limit`).
- **Filter / segment:** use the dotted `filterMetricCode` from discovery, e.g.
  `{ metricCode: "customMetrics.wordCountBand", predicate: "eq", value: "short" }`.
  Address a member of an object-array metric as `customMetrics.<code>.<member>`.
  Custom-metric filters only work on Crawl URLs reports (e.g. `all_pages`).
- **Export:** pass the codes in `selectedMetrics` on `analyze_export_report`.
- **Spot-check one page live:** `analyze_get_single_page_request_output` with
  `publishedDcCrawlerStep`.

## 5. When a custom metric returns nothing

Check, in order, from the `containers[]` entry:

1. `enabled: false` — linked but switched off; no columns on the next crawl.
   (`enabledSetting` shows the configured value; `enabled` accounts for unmet
   requirements too.)
2. `unmetRequiredCrawlTypes` non-empty — the project isn't configured with a
   crawl type the container needs as input.
3. `paramsValid: false` — required container parameters are missing or invalid;
   inspect `paramsSchema` via `analyze_get_custom_metric_container`.
4. `requiredAddons` / `requiredFeatureFlags` / `requiresAiFeatures` — the
   account may not be entitled.
5. Everything looks right but the columns are empty — the container was linked
   after the crawl you're reading. Custom metrics only populate on crawls that
   ran with the container enabled; confirm against that crawl's own
   `containers` (section 6) rather than the project's current links, then run
   `analyze_run_crawl` for fresh data.

## 6. Which crawls actually ran it (and what they captured)

`analyze_list_project_custom_metrics` answers "what is linked **now**". What a
**past** crawl actually ran is a property of the crawl:

```
analyze_list_crawls(projectId, includeContainers: true)   # per crawl, opt-in
analyze_get_crawl_summary(crawlId)                        # one crawl, always included
```

Each crawl then carries `containers[]` — `name`, `displayName`, `version` and
the same `origin` taxonomy as section 2 (`uploaded` never appears: uploads are
not executable containers). `containersTruncated: true` means the crawl ran
more containers than were listed.

Two of them answer a recurring support question — which crawls have page
captures available:

- **HtmlStoring** — the crawl captured stored page source, so
  `analyze_get_crawl_url_html` can return it.
- **ScreenshotStoring** — the crawl captured screenshots.

### Archived crawls

This is the _only_ way to tell what an archived crawl captured. The record of
which containers ran lives in the business database and survives archiving,
while the per-URL attachments they produced are read from Elasticsearch and are
unreachable until the crawl is unarchived — so an archived crawl whose
`containers` include `HtmlStoring` still fails `analyze_get_crawl_url_html`
with `not_found/stored_html`.

To investigate a past change:

1. `analyze_list_crawls(projectId, includeContainers: true)` — pick the crawls
   that captured what you need; each row carries `archivedAt`.
2. Restore it with `analyze_unarchive_crawl` and poll until it reads
   `Finished` (unarchiving is asynchronous).
3. `analyze_get_crawl_url_html` for the page.

Do not silently fall back to a fresh Single Page Request capture instead: that
returns today's page, which answers a different question when the user is
comparing against the past.

`containers` is evidence of what the crawl **ran**, not a guarantee the stored
bytes are still retained — attachments carry their own `expiresAt`. Describe it
as "captured during the crawl" rather than promising the data is there.

## 7. Custom reports (a different thing)

Custom metric _containers_ also ship **custom reports**: saved filter + column
sets layered over a standard report template. They are a separate surface from
custom metrics and invisible to `analyze_list_reports`.

```
analyze_list_custom_report_templates(projectId)          # what exists
analyze_get_custom_report_template(projectId, code)      # filter + columns
analyze_list_custom_report_rows(crawlId, templateId)     # the data (numeric id)
```

`analyze_get_custom_report_template` is the one to reach for before filtering:
a custom report's columns are its own saved metric groupings, and the tool
joins them to the base template's catalog so each column arrives with its
`type` and `connectionPredicates`. Columns flagged `resolved: false` are
custom metrics (not in the standard catalog) — look those up with
`analyze_list_project_custom_metrics`. Rows project to that same column set by
default, so you usually do not need `metrics` at all.

Each template's `source` is `container` (came with an enabled extension) or
`project` (authored on the project).

The trap: a custom report's `code` is **not** a drop-in for a standard
`reportTemplateCode` (and its prefix varies — `crt_…` when authored on the
project, `cmc_…` when provided by an extension, so never parse it).
`analyze_list_report_rows` and `analyze_get_report_metadata` resolve codes
against the standard catalog and fail on it. Use the numeric `id` with
`analyze_list_custom_report_rows`, and when you need metric metadata, call
`analyze_get_report_metadata` on the template's `basedOnReportTemplateCode`.

The template's own saved filter always applies; anything you pass in
`filterRules` narrows further on top of it.

## 8. Creating one

If the user wants a metric that does not exist, do not send them to the
dashboard — the AI wizard is fully drivable over MCP. See the custom metric
generation tools (`analyze_create_custom_metric_generation` →
`analyze_request_custom_metric_generation` → poll
`analyze_get_custom_metric_generation` →
`analyze_link_custom_metric_container_to_project`). Requires Editor role and
`account.aiFeaturesEnabled`. Metrics populate on the next crawl after linking.

The generation needs at least one test URL: once the LLM finishes, the request
runs the container against them itself, moving through
`GeneratedWaitingForTests` and `Testing` to `Tested`. Do not call
`analyze_run_custom_metric_generation_tests` after it — that starts a second
batch and spends every test URL twice. That tool is only for a generation
requested with `runTestsAfterGeneration: false`, or to re-test one that already
reached `Tested`.

If you can write the extraction JavaScript yourself, skip the LLM run:
`analyze_submit_custom_metric_generation_source` takes the handler source in
place of `analyze_request_custom_metric_generation`, consumes no AI credits and
does not need `account.aiFeaturesEnabled`. Everything else is the same
generation, so the container stays editable in the dashboard wizard afterwards
and the test loop is unchanged — submit, read the output, fix, resubmit.
Submitting starts the test runs for you and leaves the generation in `Testing`
(a generation with no test URLs is rejected unless you opt out), so do not call
`analyze_run_custom_metric_generation_tests` next: it is rejected in that state,
and spends the test URLs a second time once they settle. Poll
`analyze_get_custom_metric_generation` instead. Pass
`runTestsAfterSubmission: false` to create the version without testing; then the
separate run-tests tool is the next step.

### Writing the handler

The source is one CommonJS file exporting an async function, `myHandler` unless
you pass `handlerName`. There is no build step and no `.oreorc`: this is not the
TypeScript container project the oreo CLI scaffolds, and imports of
`@deepcrawl/oreo` types do not belong here.

```js
const myHandler = async (input, context) => {
  const document = input?.content?.renderedHtml?.document;
  const el = document?.querySelector("[itemprop=price]");
  return { productPrice: el ? Number(el.getAttribute("content")) : undefined };
};

module.exports = { myHandler };
```

- `input.content.renderedHtml.document` is a parsed DOM `Document` taken after
  JavaScript has run. `input.content.staticHtml.document` is the same page
  before rendering. Prefer these for anything a selector can do.
- `input.page` is the Puppeteer `Page`, so `await input.page.evaluate(...)` is
  there for extraction the DOM cannot express. Reach for it second.
- `input.url` is the URL being processed; `input.response` carries the HTTP
  status and headers.

The handler returns a flat object keyed on the camel-cased metric names
derived from the generation's metric titles ("Product price" → `productPrice`),
with an array for any metric where `isList` is true. Nested objects are not
supported: flatten them. A `json` metric must be returned as a
JSON-stringified string, not an object.

The generation input `type` is `string`, `number`, `integer`, `boolean` or
`json`. `json` stores a JSON-stringified string (scalar-only — `isList` is
ignored) and is rendered as JSON in the dashboard. Such metrics report
`type: "StringifiedJson"` in `analyze_list_project_custom_metrics` — try
JSON.parse on their values before reasoning about them, and keep the raw
string when parsing fails, since occasional non-JSON values do occur.
