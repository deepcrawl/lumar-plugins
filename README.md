# Lumar plugins for Claude Code and Cursor

> Previously named `claude-lumar-plugin`. The old GitHub URL still redirects, but new installs should use `deepcrawl/lumar-plugins`.

Lumar analytics as a plugin for both **Claude Code** and **Cursor**. Covers both **AI Visibility** (audit, competitor benchmark, topic bootstrap, prompt investigation, trend) and **Lumar Analyze** (crawl health, report deep-dive, URL investigation, export, task review). Backed by the unified Lumar MCP server at `https://mcp.lumar.io/mcp`.

The same `skills/` tree is shared across both hosts — each host reads its own manifest (`.claude-plugin/` or `.cursor-plugin/`) and points at the same skill files.

## Plugins

| Plugin | Description |
|:-------|:------------|
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

   **Lumar Analyze**

   - "How is my last crawl doing? Show me the top issues" → `analyze-crawl-health`
   - "Drill into duplicate pages — filter by status 200 and create a task" → `analyze-report-deep-dive`
   - "What's wrong with `<url>`? Show me the resource detail" → `analyze-url-investigation`
   - "Export the broken links report as CSV" → `analyze-export`
   - "What SEO tasks are open and what's overdue?" → `analyze-task-review`

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

## Skills

| Skill | Description |
|:------|:------------|
| `ai-visibility-audit` | Snapshot a brand's AI Visibility — headline score, topic coverage, citations vs mentions, provider breakdown |
| `competitor-benchmark` | Compare the primary brand against tracked competitors across topics, citation share, and mention quality |
| `topic-bootstrap` | Onboard a new brand — create the project, propose a topic + prompt set, bulk-create up to 50 topics atomically |
| `prompt-investigation` | Drill into a single prompt — full AI answers, search queries, citations, mentions, and competitor positioning |
| `visibility-trend` | Trace visibility score over time, attribute movement to specific topics, flag step changes |
| `analyze-crawl-health` | Lumar Analyze CrawlOverview-style snapshot — top issue reports, category health trend, segment status |
| `analyze-report-deep-dive` | Filter URLs inside one Analyze report by metric predicates; optionally create a tracked remediation task |
| `analyze-url-investigation` | Resource-Detail-style view of one URL — crawl metrics, accessibility, site speed, GSC, structured data |
| `analyze-export` | Async CSV/XML export of a report (or filtered subset) with a polling handoff so the conversation stays responsive |
| `analyze-task-review` | List and prioritise Analyze remediation tasks; flag overdue, due-soon, and unassigned work (read-only) |

## MCP server

The `lumar-analytics` plugin auto-configures one MCP server:

| Server | URL | Purpose |
|:-------|:----|:--------|
| `lumar` | `https://mcp.lumar.io/mcp` | Unified Lumar MCP — exposes opt-in toolsets per product surface |

### Scoping by toolset (advanced)

The server is opt-in per toolset. The default URL (`/mcp`) enables every toolset the authenticated user is entitled to. To restrict to a single surface, point the plugin at a scoped URL:

```
https://mcp.lumar.io/mcp/x/ai-visibility
```

You can also pass `X-MCP-Toolsets: ai-visibility,context` as a header in custom configurations. Unknown toolset names are silently ignored.

### Available toolsets

| Toolset | Tools | Status |
|:--------|:------|:-------|
| `context` | `lumar_get_me` | Always on — returns authenticated user + accessible accounts with per-product entitlements |
| `ai-visibility` | `aivis_list_projects`, `aivis_create_project`, `aivis_*_topics`, `aivis_*_prompts`, `aivis_*_brands`, `aivis_get_brand_signals`, `aivis_get_visibility_scores`, `aivis_*_prompt_runs`, `aivis_get_prompt_run_details`, `aivis_*_brand_domains` | Available now |
| `analyze` | `analyze_list_projects`, `analyze_list_crawls`, `analyze_get_crawl_summary`, `analyze_list_segments`, `analyze_list_reports`, `analyze_get_report_metadata`, `analyze_list_report_rows`, `analyze_get_url_detail`, `analyze_get_health_trend`, `analyze_list_tasks`, `analyze_create_report_task`, `analyze_export_report`, `analyze_get_report_export` | Available now |

More surfaces (Content Relevance) will be added as opt-in toolsets without changing the connector URL.

### Tools currently exposed

| Tool | Toolset | Purpose |
|:-----|:--------|:--------|
| `lumar_get_me` | `context` | Authenticated user, accessible accounts, per-product entitlements |
| `aivis_list_projects` | `ai-visibility` | List AI Visibility projects |
| `aivis_create_project` | `ai-visibility` | Create a project with a primary brand |
| `aivis_search_topics` | `ai-visibility` | Lightweight topic name lookup (id + name) |
| `aivis_list_topics` | `ai-visibility` | List topics with per-topic visibility metrics |
| `aivis_bulk_create_topics` | `ai-visibility` | Atomically create up to 50 topics + prompts in one call |
| `aivis_list_prompts` | `ai-visibility` | List prompts with analytics |
| `aivis_list_brands` | `ai-visibility` | List/search brands with visibility metrics |
| `aivis_get_top_brands` | `ai-visibility` | Top brands ranked by visibility score |
| `aivis_get_brand_signals` | `ai-visibility` | Brand citations and/or mentions |
| `aivis_get_visibility_scores` | `ai-visibility` | Time-series visibility scores |
| `aivis_list_prompt_runs` | `ai-visibility` | Prompt execution runs |
| `aivis_get_prompt_run_details` | `ai-visibility` | Full AI answer, mentions, citations, scores for a single run |
| `aivis_list_brand_domains` | `ai-visibility` | List domains attached to a brand |
| `aivis_create_brand_domain` | `ai-visibility` | Attach a domain to an existing brand for citation attribution |
| `aivis_update_brand_domain` | `ai-visibility` | Update an attached brand domain |
| `aivis_delete_brand_domain` | `ai-visibility` | Detach a domain from a brand |
| `analyze_list_projects` | `analyze` | List Analyze crawl projects for an account |
| `analyze_list_crawls` | `analyze` | List crawl history for a project (status, timing, URL count) |
| `analyze_get_crawl_summary` | `analyze` | Crawl metadata + report category snapshot + segment generation status |
| `analyze_list_segments` | `analyze` | Project segments or crawl segment generation statuses |
| `analyze_list_reports` | `analyze` | Report stats for a crawl/segment (totals, not rows) |
| `analyze_get_report_metadata` | `analyze` | Report definition + filterable metrics with allowed predicates |
| `analyze_list_report_rows` | `analyze` | URL rows for a report with structured `filterRules` and sort |
| `analyze_get_url_detail` | `analyze` | ResourceDetail view: crawl metrics, accessibility, site speed, GSC, structured data |
| `analyze_get_health_trend` | `analyze` | Health score time-series for a report category |
| `analyze_list_tasks` | `analyze` | Project- or account-scoped remediation tasks |
| `analyze_create_report_task` | `analyze` | Create a task linked to a report + optional structured filter |
| `analyze_export_report` | `analyze` | Async CSV/XML export with optional filter and selected columns |
| `analyze_get_report_export` | `analyze` | Poll export status and fetch the file URL once Generated |

### Timeframes

Analytics tools accept a `timeframe` parameter — a named window (`last_7d`, `last_30d`, `last_90d`, `mtd`, `qtd`) or an explicit `{ start, end }` ISO-8601 range. Default: `last_30d`.

## Requirements

- Claude Code (with plugin support) **or** Cursor (with plugin support)
- A [Lumar](https://www.lumar.io) account with entitlements for the products whose toolsets you want to use (AI Visibility and/or Lumar Analyze)
- Browser available on first connect for OAuth login

## License

MIT
