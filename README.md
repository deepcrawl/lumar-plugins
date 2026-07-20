# Lumar plugins for Claude Code, Cursor, and Codex

Lumar analytics as a plugin for **Claude Code**, **Cursor**, and **OpenAI Codex**. Covers both **AI Visibility** (audit, competitor benchmark, topic bootstrap, prompt investigation, trend, page evaluation, GSC, provider management, brand curation) and **Lumar Analyze** (crawl health, report deep-dive, URL investigation, export, tasks, crawls, segments, single-page requests, custom metrics, Jira links, project admin). Backed by the unified Lumar MCP server at `https://mcp.lumar.io/mcp`.

The same `skills/` tree is shared across all three hosts — each host reads its own manifest (`.claude-plugin/`, `.cursor-plugin/`, or `.codex-plugin/`) and points at the same skill files.

## Plugins

| Plugin            | Description                                                                           |
| :---------------- | :------------------------------------------------------------------------------------ |
| `lumar-analytics` | Lumar analytics skills for AI Visibility and Lumar Analyze, backed by the unified Lumar MCP server |

## Quickstart — Claude Code

### Option A: Install from Marketplace (recommended)

1. **Add the marketplace** inside Claude Code:

   ```
   /plugin marketplace add deepcrawl/lumar-plugins
   ```

2. **Install the plugin** — run `/plugin`, open the **Marketplaces** section, select **lumar-plugins**, and install `lumar-analytics`.

3. **Authenticate the Lumar MCP server** — run `/mcp` inside Claude Code and follow the browser auth flow. The plugin wires up `https://mcp.lumar.io/mcp`; on first connect you'll be sent to log in with your Lumar account.

4. **Use a skill** — skills auto-trigger from natural language. Just describe what you want.

   **AI Visibility**

   - "Audit AI Visibility for `<brand>`" → `ai-visibility-audit`
   - "How does `<brand>` compare to its competitors in AI search?" → `competitor-benchmark`
   - "Set up AI Visibility tracking for `<brand>`" → `topic-bootstrap`
   - "Why did prompt `<id>` score low? What did ChatGPT actually say?" → `prompt-investigation`
   - "Why did our visibility drop last week? Trend the score over 90 days" → `visibility-trend`
   - "Why does `<url>` score so low? Evaluate this page" → `page-evaluation`
   - "Merge these duplicate brands — they're the same company" → `brand-curation`
   - "Connect Google Search Console to my AI Visibility project" → `gsc-setup`
   - "Add Claude to this project's AI providers" → `provider-management`

   **Lumar Analyze**

   - "How is my last crawl doing? Show me the top issues" → `analyze-crawl-health`
   - "Drill into duplicate pages — filter by status 200 and create a task" → `analyze-report-deep-dive`
   - "What's wrong with `<url>`? Show me the resource detail" → `analyze-url-investigation`
   - "Export the broken links report as CSV" → `analyze-export`
   - "What SEO tasks are open and what's overdue?" → `analyze-task-review`
   - "Run a new crawl now on `<project>`" → `analyze-run-crawl`
   - "Create a segment for 404 product pages" → `analyze-segment-management`
   - "Run a single-page request for `<url>`" → `analyze-single-page-request`
   - "Generate a custom metric for pricing schema" → `analyze-custom-metrics`
   - "Create a Jira ticket for this task" → `analyze-jira-ticketing`
   - "Create a new SEO project for `<domain>`" → `analyze-project-admin`

### Option B: Install from a local clone

```bash
git clone https://github.com/deepcrawl/lumar-plugins.git
```

Then inside Claude Code:

```
/plugin marketplace add /path/to/lumar-plugins
```

and install `lumar-analytics` from the **Marketplaces** view. Run `/mcp` to authenticate.

## Quickstart — Cursor

Cursor reads `.cursor-plugin/marketplace.json` at the repo root and the per-plugin manifest at `plugins/lumar-analytics/.cursor-plugin/plugin.json`.

1. **Add the plugin marketplace** in Cursor — open the Cursor plugin manager and add `deepcrawl/lumar-plugins` as a marketplace source (or point Cursor at a local clone of this repo).

2. **Install `lumar-analytics`** from the marketplace listing.

3. **Authenticate the Lumar MCP server** — open Cursor's **MCP** settings, find the `lumar` server provisioned by the plugin, and complete the OAuth flow in your browser.

4. **Use a skill** — same natural-language triggers as Claude Code (see the prompt examples above and the skills table below).

## Quickstart — Codex

Codex reads `.agents/plugins/marketplace.json` at the repo root and the per-plugin manifest at `plugins/lumar-analytics/.codex-plugin/plugin.json`.

1. **Add the marketplace** from your shell:

   ```bash
   codex plugin marketplace add deepcrawl/lumar-plugins
   ```

   (Or point at a local clone: `codex plugin marketplace add /path/to/lumar-plugins`.)

2. **Install `lumar-analytics`** — inside Codex CLI run `/plugins`, open the marketplace, and install.

3. **Authenticate the Lumar MCP server** — Codex will prompt on first install (`ON_INSTALL` policy) and run the browser OAuth flow against `https://mcp.lumar.io/mcp`.

4. **Use a skill** — same natural-language triggers as Claude Code and Cursor.

## Skills

| Skill                       | Description                                                                                                                                  |
| :-------------------------- | :------------------------------------------------------------------------------------------------------------------------------------------- |
| `ai-visibility-audit`       | Snapshot a brand's AI Visibility — headline score, topic coverage, citations vs mentions, provider breakdown                                 |
| `competitor-benchmark`      | Compare the primary brand against tracked competitors across topics, citation share, and mention quality                                     |
| `topic-bootstrap`           | Onboard a new brand — create the project, propose a topic + prompt set, bulk-create up to 50 topics atomically                               |
| `prompt-investigation`      | Drill into a single prompt — full AI answers, search queries, citations, mentions, and competitor positioning                                |
| `visibility-trend`          | Trace visibility score over time, attribute movement to specific topics, flag step changes                                                   |
| `analyze-crawl-health`      | Lumar Analyze CrawlOverview-style snapshot — top issue reports, category health trend, segment status                                        |
| `analyze-report-deep-dive`  | Filter URLs inside one Analyze report by metric predicates; optionally create a tracked remediation task                                     |
| `analyze-url-investigation` | Resource-Detail-style view of one URL — crawl metrics, accessibility, site speed, GSC, structured data                                       |
| `analyze-export`            | Async CSV/XML export of a report (or filtered subset) with a polling handoff so the conversation stays responsive                            |
| `analyze-task-review`       | List and prioritise Analyze remediation tasks; optionally update status, priority, assignees, deadlines, or close tasks                      |
| `analyze-run-crawl`         | Queue a fresh Analyze crawl outside the schedule, sanity-check for in-flight runs, hand back the new crawl id + dashboard link               |
| `analyze-segment-management` | Create, update, or delete Analyze segments from structured CrawlUrl filter rules                                                              |
| `analyze-single-page-request` | Run or inspect Single Page Requester jobs for one URL against a project's current crawl settings                                             |
| `analyze-custom-metrics`    | Generate, test, and link AI-assisted custom metric containers to Analyze projects                                                             |
| `analyze-jira-ticketing`    | Generate task ticket details and link Analyze remediation tasks to existing or new Jira issues                                                |
| `analyze-project-admin`     | Create, update, or clone Analyze projects with the common crawl settings exposed by MCP                                                       |
| `brand-curation`            | Curate the AI Visibility brand list — merge variants, promote the right primary, classify Own/Competitor/Other, attach domains               |
| `page-evaluation`           | Deep-dive one URL's content evaluation — aggregated scores, LLM reasoning, per-snippet precision, per-competitor uniqueness, GSC queries     |
| `gsc-setup`                 | Connect a Google Search Console property to an AI Visibility project so page runs unlock real-search-query relevance scoring                 |
| `provider-management`       | List the AI provider catalog, manage per-project provider links, sync with subscription — flags the `aiProvidersSyncWithSubscription` caveat |

## MCP server

The `lumar-analytics` plugin auto-configures one MCP server:

| Server  | URL                        | Purpose                                                         |
| :------ | :------------------------- | :-------------------------------------------------------------- |
| `lumar` | `https://mcp.lumar.io/mcp` | Unified Lumar MCP — exposes opt-in toolsets per product surface and trust boundary |

### Authentication

The server authenticates via OAuth: on first connect the host opens a browser login against your Lumar account, followed by a consent screen where you pick toolsets. Clients don't need to be on an allow list — the gateway supports standard Dynamic Client Registration, and clients that publish a Client ID Metadata Document (an https URL hosting their registration) can authenticate with that instead; the consent screen names the requesting application either way.

Access requires the **MCP Server subscription addon** on at least one of your active Lumar accounts (Lumar system admins keep access regardless). Without it, sign-in is refused, and removing the addon locks out existing sessions within a few minutes.

For shared-credential surfaces that cannot run an interactive login (e.g. Claude Tag / Claude in Slack), the server also accepts a static Lumar user key as a bearer credential (`Authorization: Bearer <userKeyId>:<secret>`). User-key connections are read-only — only the read toolsets (`context`, `ai-visibility:read`, `analyze:read`) are available, enforced server-side — and the MCP Server addon is still required. Revoking the user key cuts off access within a minute.

### Toolset consent and scoping

The server groups tools by product surface and trust boundary. For remote HTTP clients, the OAuth consent screen is the source of truth: the user grants leaf scopes such as `toolset:ai-visibility:read` or `toolset:analyze:external`, and the server registers only those toolsets for that token. The `context` toolset is always on so agents can call `lumar_get_me` / `lumar_search_accounts` and discover accounts.

For scoped local or custom connector configs, use the URL path or `X-MCP-Toolsets` header. Leaf selectors are explicit:

```
https://mcp.lumar.io/mcp/x/ai-visibility:read,analyze:read
```

Bare product selectors are shortcuts: `ai-visibility` expands to `ai-visibility:read,ai-visibility:write`; `analyze` expands to `analyze:read,analyze:write,analyze:external,analyze:admin`. Unknown toolset names are silently ignored.

### Available toolsets

| Toolset               | What it grants                                                                                                                                                                                                                                                      |
| :-------------------- | :------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------ |
| `context`             | `lumar_get_me` + `lumar_search_accounts` — always on; identifies the authenticated user, lists their accessible accounts with per-product entitlements, and resolves accounts by name. Lumar system admins get no account list from `lumar_get_me` (they can access every account) — `lumar_search_accounts` is how they find one. |
| `ai-visibility:read`  | Read AI Visibility projects, topics, prompts, brands, visibility/citation/mention metrics, discovered URLs, content-evaluation scores, GSC bindings, provider catalog, suggestions.                                                                                 |
| `ai-visibility:write` | Create / update / delete AI Visibility projects, topics, prompts, brand-domains; classify and merge brands; attach / update / detach GSC properties; enable / disable / sync project AI providers; trigger prompt + page runs; generate suggested topics / prompts. |
| `analyze:read`        | Read Analyze crawl projects, crawls, segments, reports, report rows, URL detail, health / report trends, tasks, single-page requests, custom-metric generations, report export status.                                                                              |
| `analyze:write`       | Create / update / delete Analyze segments and tasks; start exports; run crawls; start single-page requests; manage custom-metric generations and project links.                                                                                                     |
| `analyze:external`    | Read and write the user's connected Jira tenant — list Jira projects / issue types / field metadata, search issues, create and delete task ↔ Jira links.                                                                                                             |
| `analyze:admin`       | Create, update, and clone Analyze projects. Higher-trust project-wide crawl settings and new crawl targets live here, separate from per-crawl writes.                                                                                                                 |

More surfaces (Content Relevance) will be added as opt-in toolsets without changing the connector URL.

### Tools by toolset

**`context`** — `lumar_get_me`, `lumar_search_accounts`.

**`ai-visibility:read`** — `aivis_list_projects`, `aivis_search_topics`, `aivis_list_topics`, `aivis_list_prompts`, `aivis_list_brands`, `aivis_get_top_brands`, `aivis_list_brand_domains`, `aivis_get_brand_signals`, `aivis_get_visibility_scores`, `aivis_list_prompt_runs`, `aivis_get_prompt_run_details`, `aivis_list_discovered_urls`, `aivis_list_discovered_pages`, `aivis_get_suggested_topics`, `aivis_get_suggested_prompts`, `aivis_list_active_providers`, `aivis_list_active_countries`, `aivis_get_page_scores`, `aivis_list_page_runs`, `aivis_list_serp_discovery_runs`, `aivis_list_prompt_provider_visibility`, `aivis_list_search_queries`, `aivis_list_google_connections`, `aivis_list_gsc_properties`, `aivis_get_account_settings`, `aivis_list_ai_providers`, `aivis_list_project_ai_providers`.

**`ai-visibility:write`** — `aivis_create_project`, `aivis_update_project`, `aivis_delete_project`, `aivis_run_project_prompts`, `aivis_bulk_create_topics`, `aivis_update_topic`, `aivis_generate_topic_metadata`, `aivis_delete_topic`, `aivis_create_prompt`, `aivis_delete_prompt`, `aivis_create_brand_domain`, `aivis_update_brand_domain`, `aivis_delete_brand_domain`, `aivis_update_brand`, `aivis_merge_brands`, `aivis_promote_brand`, `aivis_unmerge_brand`, `aivis_generate_suggested_topics`, `aivis_generate_suggested_prompts`, `aivis_trigger_page_run`, `aivis_attach_gsc_property`, `aivis_update_gsc_property`, `aivis_detach_gsc_property`, `aivis_enable_project_ai_provider`, `aivis_disable_project_ai_provider`, `aivis_sync_project_ai_providers`.

**`analyze:read`** — `analyze_list_projects`, `analyze_list_crawls`, `analyze_get_crawl_summary`, `analyze_list_segments`, `analyze_list_reports`, `analyze_get_report_metadata`, `analyze_list_report_rows`, `analyze_get_url_detail`, `analyze_list_url_patterns`, `analyze_get_aggregation_catalog`, `analyze_explore_urls_aggregates`, `analyze_get_health_trend`, `analyze_get_report_trend`, `analyze_list_tasks`, `analyze_get_task`, `analyze_get_report_export`, `analyze_list_single_page_requests`, `analyze_get_single_page_request`, `analyze_get_single_page_request_html`, `analyze_list_custom_metric_generations`, `analyze_get_custom_metric_generation`.

**`analyze:write`** — `analyze_create_segment`, `analyze_update_segment`, `analyze_delete_segment`, `analyze_create_report_task`, `analyze_update_task`, `analyze_delete_task`, `analyze_generate_task_ticket_details`, `analyze_export_report`, `analyze_run_crawl`, `analyze_create_single_page_request`, `analyze_create_custom_metric_generation`, `analyze_update_custom_metric_generation`, `analyze_delete_custom_metric_generation`, `analyze_request_custom_metric_generation`, `analyze_run_custom_metric_generation_tests`, `analyze_link_custom_metric_container_to_project`, `analyze_update_custom_metric_container_project`, `analyze_unlink_custom_metric_container_from_project`.

**`analyze:external`** — `analyze_list_jira_authentications`, `analyze_list_jira_projects`, `analyze_list_jira_issue_types`, `analyze_get_jira_create_field_metadata`, `analyze_search_jira_issues`, `analyze_create_task_external_link`, `analyze_delete_task_external_link`.

**`analyze:admin`** — `analyze_create_project`, `analyze_update_project`, `analyze_clone_project`.

Per-tool descriptions and input schemas come back over the wire on `tools/list`; that is the canonical reference. Every `aivis_*` tool description ends with an "App availability:" tag saying where that capability is surfaced in the UI — the self-serve Lumar GEO app, Lumar Analyze (enterprise), both, or not surfaced in any app yet. All tools work over MCP regardless of the tag; it exists so agents can tell users where to find a feature in the product.

### Pointing at a different MCP URL (staging / self-hosted / scoped)

The plugin defaults to production (`https://mcp.lumar.io/mcp`), but the URL is just a value in `plugins/lumar-analytics/mcp.json`. You can override it for any host by editing that file in a **local clone** of this repo and installing the plugin from the local path instead of the GitHub marketplace.

Common reasons to override:

- Staging server (e.g. `https://mcp.staging.lumar.io/mcp`) while testing pre-release toolsets
- A scoped URL like `https://mcp.lumar.io/mcp/x/ai-visibility:read,analyze:read` to restrict the connector to selected read-only surfaces
- A self-hosted or tunnelled MCP endpoint (`http://localhost:8787/mcp`, an ngrok URL, etc.)

Edit `plugins/lumar-analytics/mcp.json`:

```json
{
  "mcpServers": {
    "lumar": {
      "type": "http",
      "url": "https://mcp.staging.lumar.io/mcp"
    }
  }
}
```

If your custom endpoint needs extra headers (e.g. forcing a toolset scope without changing the path), add a `headers` block:

```json
{
  "mcpServers": {
    "lumar": {
      "type": "http",
      "url": "https://mcp.lumar.io/mcp",
      "headers": {
        "X-MCP-Toolsets": "ai-visibility:read,analyze:read"
      }
    }
  }
}
```

#### Example — Cursor with a local checkout pointing at staging

1. Clone this repo locally:

   ```bash
   git clone https://github.com/deepcrawl/lumar-plugins.git ~/src/lumar-plugins
   ```

2. Edit `~/src/lumar-plugins/plugins/lumar-analytics/mcp.json` and change the `url` to your target — for example:

   ```json
   {
     "mcpServers": {
       "lumar": {
         "type": "http",
         "url": "https://mcp.staging.lumar.io/mcp"
       }
     }
   }
   ```

3. In Cursor, open the plugin manager and add the local checkout as a marketplace source — point it at `~/src/lumar-plugins` (the repo root, where `.cursor-plugin/marketplace.json` lives).

4. Install `lumar-analytics` from that marketplace listing. Cursor now provisions an MCP server named `lumar` pointed at your overridden URL.

5. Open Cursor's **MCP** settings, find the `lumar` server, and run the OAuth flow — it will hit whichever host you configured (staging, self-hosted, etc.) instead of production.

The same approach works for Claude Code (`/plugin marketplace add /path/to/lumar-plugins`) and Codex (`codex plugin marketplace add /path/to/lumar-plugins`) — the only thing that changes between hosts is the install command; the `mcp.json` override is shared.

> Keep your local edit on a branch (or just don't commit `mcp.json`) so a `git pull` doesn't clobber it — and remember to switch back to production before opening any PRs against this repo.

### Identifiers and pagination

Every entity in a response carries a single numeric `id`; pass that value as the matching `*Id` on follow-up tools. The exception is `analyze_export_report`, whose `reportDownload.id` is an opaque polling token for `analyze_get_report_export`.

Paginated responses include `pagination.next_cursor`, `pagination.has_next_page`, `pagination.returned`, and `pagination.total_count`. Pass `next_cursor` as the next call's `cursor`. Defaults are usually `limit=20`, max `limit=100`.

### Verbose responses

Some tools trim large fields by default and expose `verbose: true`:

| Tool                           | What `verbose=true` adds                                                                                                                           |
| :----------------------------- | :-------------------------------------------------------------------------------------------------------------------------------------------------- |
| `analyze_list_reports`         | Long report-template description, definition, effect, impact, and solutions text per row                                                            |
| `analyze_get_single_page_request` | Full crawl settings snapshot, raw outputs, container versions, response headers, and signed output URLs                                             |
| `analyze_get_custom_metric_generation` | Generated handler source / download URL for the linked custom metric container version                                                        |
| `aivis_get_prompt_run_details` | Full `fullAnswerText` and raw citation / mention / search-query arrays                                                                              |
| `aivis_list_page_runs`         | LLM reasoning text plus per-snippet precision, per-competitor uniqueness, per-model brand-mention, sentiment, GSC, and QDF evaluation arrays        |

### Timeframes

Analytics tools accept a `timeframe` parameter — a named window (`last_7d`, `last_30d`, `last_90d`, `mtd`, `qtd`) or an explicit `{ start, end }` ISO-8601 range. Default: `last_30d`.

## Requirements

- Claude Code, Cursor, **or** Codex (with plugin support)
- A [Lumar](https://www.lumar.io) account with the **MCP Server subscription addon** enabled, plus entitlements for the products whose toolsets you want to use (AI Visibility and/or Lumar Analyze)
- Browser available on first connect for OAuth login

## License

MIT
