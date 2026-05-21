# Lumar plugins for Claude Code

Lumar analytics for Claude Code: AI Visibility audits, competitor benchmarking, topic bootstrapping, prompt-run investigation, and visibility trend analysis. Backed by the unified Lumar MCP server at `https://mcp.lumar.io/mcp`.

## Plugins

| Plugin | Description |
|:-------|:------------|
| `lumar-analytics` | Lumar analytics skills — AI Visibility today; Lumar Analyze and Content Relevance toolsets to follow |

## Quickstart

### Option A: Install from Marketplace (recommended)

1. **Add the marketplace** inside Claude Code:
   ```
   /plugin marketplace add deepcrawl/claude-lumar-plugin
   ```

2. **Install the plugin** — run `/plugin`, open the **Marketplaces** section, select **lumar-plugins**, and install `lumar-analytics`.

3. **Authenticate the Lumar MCP server** — run `/mcp` inside Claude Code and follow the browser auth flow. The plugin wires up `https://mcp.lumar.io/mcp`; on first connect you'll be sent to log in with your Lumar account.

4. **Use a skill** — skills auto-trigger from natural language. Just describe what you want:

   - "Audit AI Visibility for `<brand>`" → `ai-visibility-audit`
   - "How does `<brand>` compare to its competitors in AI search?" → `competitor-benchmark`
   - "Set up AI Visibility tracking for `<brand>`" → `topic-bootstrap`
   - "Why did prompt `<id>` score low? What did ChatGPT actually say?" → `prompt-investigation`
   - "Why did our visibility drop last week? Trend the score over 90 days" → `visibility-trend`

### Option B: Install from a local clone

```bash
git clone https://github.com/deepcrawl/claude-lumar-plugin.git
```

Then inside Claude Code:

```
/plugin marketplace add /path/to/claude-lumar-plugin
```

and install `lumar-analytics` from the **Marketplaces** view. Run `/mcp` to authenticate.

## Skills

| Skill | Description |
|:------|:------------|
| `ai-visibility-audit` | Snapshot a brand's AI Visibility — headline score, topic coverage, citations vs mentions, provider breakdown |
| `competitor-benchmark` | Compare the primary brand against tracked competitors across topics, citation share, and mention quality |
| `topic-bootstrap` | Onboard a new brand — create the project, propose a topic + prompt set, bulk-create up to 50 topics atomically |
| `prompt-investigation` | Drill into a single prompt — full AI answers, search queries, citations, mentions, and competitor positioning |
| `visibility-trend` | Trace visibility score over time, attribute movement to specific topics, flag step changes |

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
| `ai-visibility` | `aivis_list_projects`, `aivis_create_project`, `aivis_*_topics`, `aivis_*_prompts`, `aivis_*_brands`, `aivis_get_brand_signals`, `aivis_get_visibility_scores`, `aivis_*_prompt_runs`, `aivis_get_prompt_run_details` | Available now |

More surfaces (Lumar Analyze, Content Relevance) will be added as opt-in toolsets without changing the connector URL.

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

### Timeframes

Analytics tools accept a `timeframe` parameter — a named window (`last_7d`, `last_30d`, `last_90d`, `mtd`, `qtd`) or an explicit `{ start, end }` ISO-8601 range. Default: `last_30d`.

## Requirements

- Claude Code with plugin support
- A [Lumar](https://www.lumar.io) account with entitlements for the products whose toolsets you want to use (AI Visibility today)
- Browser available on first connect for OAuth login

## License

MIT
