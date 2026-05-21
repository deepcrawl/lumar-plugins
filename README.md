# Lumar plugins for Claude Code, Cursor, and Codex

Lumar analytics as a plugin for **Claude Code**, **Cursor**, and **OpenAI Codex**. Covers both **AI Visibility** (audit, competitor benchmark, topic bootstrap, prompt investigation, trend) and **Lumar Analyze** (crawl health, report deep-dive, URL investigation, export, task review). Backed by the unified Lumar MCP server at `https://mcp.lumar.io/mcp`.

The same `skills/` tree is shared across all three hosts — each host reads its own manifest (`.claude-plugin/`, `.cursor-plugin/`, or `.codex-plugin/`) and points at the same skill files.

## Plugins

| Plugin            | Description                                                                           |
| :---------------- | :------------------------------------------------------------------------------------ |
| `lumar-analytics` | Lumar analytics skills — AI Visibility and Lumar Analyze; Content Relevance to follow |

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
| `analyze-task-review`       | List and prioritise Analyze remediation tasks; flag overdue, due-soon, and unassigned work (read-only)                                       |
| `analyze-run-crawl`         | Queue a fresh Analyze crawl outside the schedule, sanity-check for in-flight runs, hand back the new crawl id + dashboard link               |
| `brand-curation`            | Curate the AI Visibility brand list — merge variants, promote the right primary, classify Own/Competitor/Other, attach domains               |
| `page-evaluation`           | Deep-dive one URL's content evaluation — aggregated scores, LLM reasoning, per-snippet precision, per-competitor uniqueness, GSC queries     |
| `gsc-setup`                 | Connect a Google Search Console property to an AI Visibility project so page runs unlock real-search-query relevance scoring                 |
| `provider-management`       | List the AI provider catalog, manage per-project provider links, sync with subscription — flags the `aiProvidersSyncWithSubscription` caveat |

## MCP server

The `lumar-analytics` plugin auto-configures one MCP server:

| Server  | URL                        | Purpose                                                         |
| :------ | :------------------------- | :-------------------------------------------------------------- |
| `lumar` | `https://mcp.lumar.io/mcp` | Unified Lumar MCP — exposes opt-in toolsets per product surface |

### Scoping by toolset (advanced)

The server is opt-in per toolset. The default URL (`/mcp`) enables every toolset the authenticated user is entitled to. To restrict to a single surface, point the plugin at a scoped URL:

```
https://mcp.lumar.io/mcp/x/ai-visibility
```

You can also pass `X-MCP-Toolsets: ai-visibility,context` as a header in custom configurations. Unknown toolset names are silently ignored.

### Available toolsets

| Toolset         | Tools                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                | Status                                                                                     |
| :-------------- | :--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- | :----------------------------------------------------------------------------------------- |
| `context`       | `lumar_get_me`                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                       | Always on — returns authenticated user + accessible accounts with per-product entitlements |
| `ai-visibility` | `aivis_*_projects`, `aivis_*_topics`, `aivis_*_prompts`, `aivis_*_brands`, `aivis_*_brand_domains`, `aivis_get_brand_signals`, `aivis_get_visibility_scores`, `aivis_*_prompt_runs`, `aivis_get_prompt_run_details`, `aivis_*_suggested_*`, `aivis_list_active_*`, `aivis_list_discovered_urls`, `aivis_list_serp_discovery_runs`, `aivis_*_page_*`, `aivis_list_search_queries`, `aivis_list_prompt_provider_visibility`, `aivis_run_project_prompts`, `aivis_*_gsc_property`, `aivis_list_google_connections`, `aivis_*_ai_providers`, `aivis_*_project_ai_provider`, `aivis_get_account_settings` | Available now                                                                              |
| `analyze`       | `analyze_list_projects`, `analyze_list_crawls`, `analyze_run_crawl`, `analyze_get_crawl_summary`, `analyze_list_segments`, `analyze_list_reports`, `analyze_get_report_metadata`, `analyze_list_report_rows`, `analyze_get_url_detail`, `analyze_get_health_trend`, `analyze_list_tasks`, `analyze_create_report_task`, `analyze_export_report`, `analyze_get_report_export`                                                                                                                                                                                                                         | Available now                                                                              |

More surfaces (Content Relevance) will be added as opt-in toolsets without changing the connector URL.

### Pointing at a different MCP URL (staging / self-hosted / scoped)

The plugin defaults to production (`https://mcp.lumar.io/mcp`), but the URL is just a value in `plugins/lumar-analytics/mcp.json`. You can override it for any host by editing that file in a **local clone** of this repo and installing the plugin from the local path instead of the GitHub marketplace.

Common reasons to override:

- Staging server (e.g. `https://mcp.staging.lumar.io/mcp`) while testing pre-release toolsets
- A scoped URL like `https://mcp.lumar.io/mcp/x/ai-visibility` to restrict the connector to one product surface
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
        "X-MCP-Toolsets": "ai-visibility,context"
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

### Tools currently exposed

| Tool                                    | Toolset         | Purpose                                                                                                           |
| :-------------------------------------- | :-------------- | :---------------------------------------------------------------------------------------------------------------- |
| `lumar_get_me`                          | `context`       | Authenticated user, accessible accounts, per-product entitlements                                                 |
| `aivis_list_projects`                   | `ai-visibility` | List AI Visibility projects                                                                                       |
| `aivis_create_project`                  | `ai-visibility` | Create a project with a primary brand                                                                             |
| `aivis_search_topics`                   | `ai-visibility` | Lightweight topic name lookup (id + name)                                                                         |
| `aivis_list_topics`                     | `ai-visibility` | List topics with per-topic visibility metrics                                                                     |
| `aivis_bulk_create_topics`              | `ai-visibility` | Atomically create up to 50 topics + prompts in one call                                                           |
| `aivis_list_prompts`                    | `ai-visibility` | List prompts with analytics                                                                                       |
| `aivis_list_brands`                     | `ai-visibility` | List/search brands with visibility metrics                                                                        |
| `aivis_get_top_brands`                  | `ai-visibility` | Top brands ranked by visibility score                                                                             |
| `aivis_get_brand_signals`               | `ai-visibility` | Brand citations and/or mentions (citation rows now include `pageRunStatus` + `latestRunAt`)                       |
| `aivis_get_visibility_scores`           | `ai-visibility` | Time-series visibility scores                                                                                     |
| `aivis_list_prompt_runs`                | `ai-visibility` | Prompt execution runs                                                                                             |
| `aivis_get_prompt_run_details`          | `ai-visibility` | Full AI answer, mentions, citations, scores for a single run                                                      |
| `aivis_list_brand_domains`              | `ai-visibility` | List domains attached to a brand                                                                                  |
| `aivis_create_brand_domain`             | `ai-visibility` | Attach a domain to an existing brand for citation attribution                                                     |
| `aivis_update_brand_domain`             | `ai-visibility` | Update an attached brand domain                                                                                   |
| `aivis_delete_brand_domain`             | `ai-visibility` | Detach a domain from a brand                                                                                      |
| `aivis_update_project`                  | `ai-visibility` | Update project settings (name, cadence, autoCrawl, serpDiscovery, autoDiscoveryThreshold, freshnessThresholdDays) |
| `aivis_delete_project`                  | `ai-visibility` | Soft-delete a project — destructive                                                                               |
| `aivis_run_project_prompts`             | `ai-visibility` | Force a full prompt-run pass across every prompt × enabled provider, bypassing the schedule                       |
| `aivis_update_topic`                    | `ai-visibility` | Rename a topic                                                                                                    |
| `aivis_delete_topic`                    | `ai-visibility` | Soft-delete a topic and its prompts/runs — destructive                                                            |
| `aivis_create_prompt`                   | `ai-visibility` | Add a single prompt to an existing topic; optional `suggestedPromptId` consumes a suggestion atomically           |
| `aivis_delete_prompt`                   | `ai-visibility` | Soft-delete a prompt and its runs — destructive                                                                   |
| `aivis_update_brand`                    | `ai-visibility` | Reclassify a brand as `Own` / `Competitor` / `Other`                                                              |
| `aivis_merge_brands`                    | `ai-visibility` | Merge variant brands into a target brand — destructive; cannot merge a primary brand                              |
| `aivis_promote_brand`                   | `ai-visibility` | Promote a merged variant to become the new primary brand                                                          |
| `aivis_unmerge_brand`                   | `ai-visibility` | Detach a merged brand so it appears as a separate entity again                                                    |
| `aivis_get_suggested_topics`            | `ai-visibility` | Read cached LLM-generated topic suggestions for a brand                                                           |
| `aivis_generate_suggested_topics`       | `ai-visibility` | Trigger a fresh batch of LLM-generated topic suggestions                                                          |
| `aivis_get_suggested_prompts`           | `ai-visibility` | Read cached LLM-generated prompt suggestions for a topic                                                          |
| `aivis_generate_suggested_prompts`      | `ai-visibility` | Trigger a fresh batch of LLM-generated prompt suggestions                                                         |
| `aivis_list_discovered_urls`            | `ai-visibility` | SERP discovery feed — every URL surfaced in AI answers / grounding before per-URL evaluation                      |
| `aivis_list_serp_discovery_runs`        | `ai-visibility` | Job-level view of SERP discovery (status, failureReason, domain)                                                  |
| `aivis_list_active_providers`           | `ai-visibility` | AI providers that produced ≥1 finished run for a project — use to populate provider filters                       |
| `aivis_list_active_countries`           | `ai-visibility` | Country codes (and worldwide) whose prompts produced finished runs                                                |
| `aivis_get_page_scores`                 | `ai-visibility` | Per-URL content-evaluation scores (precision/recall/quality/trust, evergreen health, topical opportunity, …)      |
| `aivis_list_page_runs`                  | `ai-visibility` | Per-URL content-evaluation jobs; `verbose: true` adds LLM reasoning + per-snippet/per-competitor arrays           |
| `aivis_trigger_page_run`                | `ai-visibility` | Kick off a fresh content evaluation for a URL                                                                     |
| `aivis_list_prompt_provider_visibility` | `ai-visibility` | Per-AI-provider visibility breakdown per prompt                                                                   |
| `aivis_list_search_queries`             | `ai-visibility` | The queries AI engines actually issued while answering prompts (with comparisonTimeframe support)                 |
| `aivis_list_google_connections`         | `ai-visibility` | List the user's Google OAuth connections + the GSC sites each token can read                                      |
| `aivis_list_gsc_properties`             | `ai-visibility` | List GSC properties attached to an AI Visibility project                                                          |
| `aivis_attach_gsc_property`             | `ai-visibility` | Bind a GSC `siteUrl` to a project so page runs compute `gscQueryScore` / `gscQueryEvaluations`                    |
| `aivis_update_gsc_property`             | `ai-visibility` | Change filters / search type / lookback on an existing GSC binding                                                |
| `aivis_detach_gsc_property`             | `ai-visibility` | Remove a GSC binding — destructive                                                                                |
| `aivis_get_account_settings`            | `ai-visibility` | Read `aiProvidersSyncWithSubscription`, `scheduleType`, `timezone` — check before per-project provider mutations  |
| `aivis_list_ai_providers`               | `ai-visibility` | Catalog of every AI provider; `included` flag = part of the subscription addon                                    |
| `aivis_list_project_ai_providers`       | `ai-visibility` | Providers currently linked to a project (regardless of run activity)                                              |
| `aivis_enable_project_ai_provider`      | `ai-visibility` | Link a provider to a project — may be reverted under subscription-sync mode                                       |
| `aivis_disable_project_ai_provider`     | `ai-visibility` | Unlink a provider — destructive; may be reverted under subscription-sync mode                                     |
| `aivis_sync_project_ai_providers`       | `ai-visibility` | Reset a project's linked providers to match the subscription — on-demand sync                                     |
| `analyze_list_projects`                 | `analyze`       | List Analyze crawl projects for an account                                                                        |
| `analyze_list_crawls`                   | `analyze`       | List crawl history for a project (status, timing, URL count)                                                      |
| `analyze_run_crawl`                     | `analyze`       | Trigger a new crawl bypassing the schedule (returns the queued crawl id + dashboard URL; consumes URL quota)      |
| `analyze_get_crawl_summary`             | `analyze`       | Crawl metadata + report category snapshot + segment generation status                                             |
| `analyze_list_segments`                 | `analyze`       | Project segments or crawl segment generation statuses                                                             |
| `analyze_list_reports`                  | `analyze`       | Report stats for a crawl/segment (totals, not rows)                                                               |
| `analyze_get_report_metadata`           | `analyze`       | Report definition + filterable metrics with allowed predicates                                                    |
| `analyze_list_report_rows`              | `analyze`       | URL rows for a report with structured `filterRules` and sort                                                      |
| `analyze_get_url_detail`                | `analyze`       | ResourceDetail view: crawl metrics, accessibility, site speed, GSC, structured data                               |
| `analyze_get_health_trend`              | `analyze`       | Health score time-series for a report category                                                                    |
| `analyze_list_tasks`                    | `analyze`       | Project- or account-scoped remediation tasks                                                                      |
| `analyze_create_report_task`            | `analyze`       | Create a task linked to a report + optional structured filter                                                     |
| `analyze_export_report`                 | `analyze`       | Async CSV/XML export with optional filter and selected columns                                                    |
| `analyze_get_report_export`             | `analyze`       | Poll export status and fetch the file URL once Generated                                                          |

### Timeframes

Analytics tools accept a `timeframe` parameter — a named window (`last_7d`, `last_30d`, `last_90d`, `mtd`, `qtd`) or an explicit `{ start, end }` ISO-8601 range. Default: `last_30d`.

## Requirements

- Claude Code, Cursor, **or** Codex (with plugin support)
- A [Lumar](https://www.lumar.io) account with entitlements for the products whose toolsets you want to use (AI Visibility and/or Lumar Analyze)
- Browser available on first connect for OAuth login

## License

MIT
