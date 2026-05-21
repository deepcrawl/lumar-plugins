---
name: ai-visibility-audit
description: Audit how a brand appears in AI-generated answers — visibility scores, citations, mentions, and topic coverage gaps. Use this skill whenever someone asks for an AI Visibility audit, wants to see how their brand is performing in AI search (ChatGPT, Perplexity, Gemini, Claude, Google AI Overviews), asks "how visible am I in AI?", "am I being cited?", or wants a snapshot of their AI Visibility project. Also trigger when users mention GEO (generative engine optimisation), AI search performance, or ask to review a Lumar AI Visibility project — even if they don't say "audit" explicitly.
---

# AI Visibility Audit

Produce a structured report on how a brand is performing in AI-generated answers across providers (ChatGPT, Perplexity, Gemini, Claude, Google AI Overviews). Synthesises visibility scores, citation share, brand mention quality, and per-topic performance.

## Parameters

- **brand_or_project**: What the user provides — could be a brand name, project name, or "my project". Often ambiguous.
- **timeframe**: The time period for the audit (default: `last_30d`). Accepts `last_7d`, `last_30d`, `last_90d`, `mtd`, `qtd`, or an explicit `{ start, end }` ISO-8601 range.

## Step 0: Resolve account and project

1. Call `lumar_get_me` to discover which accounts the user has access to and whether AI Visibility is entitled.
2. If multiple AI-Visibility-entitled accounts exist, ask the user which one to use.
3. Call `aivis_list_projects` for the selected account. If the user named a brand/project, match against returned projects; otherwise show a numbered list and ask which to audit. Never silently pick when there are multiple.
4. From the chosen project, identify the **primary brand** — that's the subject of the audit. Note all brand IDs (primary + competitors tracked on the project) for later steps.

## Step 1: Headline visibility

Pull the headline numbers first so the user gets a fast read. Steps 1–3 below issue independent reads — fire their primary tool calls in parallel in a single batch, then synthesise.

1. `aivis_get_visibility_scores` with `projectId` + the primary `brandId` over `timeframe`. Pass `comparisonTimeframe` set to an equal-length prior window so each trend returns a `previousPeriod` for delta calculation. Example: for `timeframe: "last_30d"`, pass `comparisonTimeframe: { start: <60 days ago>, end: <30 days ago> }`.
2. `aivis_get_top_brands` (`brandId` = primary brand, `projectId` = chosen project) — note rank and which brands sit immediately above/below.

Report:

- Current visibility score (1 dp) and delta vs previous period (↑/↓ with absolute and relative change).
- Rank in top-brands leaderboard with names of the two brands above and two below.
- Whether the score is driven more by **citations** (avg_citation_quality_score) or **brand mentions** (avg_brand_mention_quality_score) — the two components weight 25 % / 75 %.

## Step 2: Topic coverage

1. `aivis_list_topics` for the primary brand. Sort by visibility score.
2. Identify three buckets:
   - **Strong topics** — top 5 by visibility score
   - **Weak topics** — bottom 5 by visibility score, excluding any with zero runs
   - **Coverage gaps** — topics with 0 mention runs or score below a meaningful threshold (e.g. < 5)

For weak topics and coverage gaps, surface 1–2 example prompts via `aivis_list_prompts` (`projectId` + primary `brandId` + `topicId`, `limit: 2`). Issue all the per-topic calls **in parallel as one batch** — they're independent.

## Step 3: Citation vs mention quality

1. `aivis_get_brand_signals` for the primary brand with `type: "both"` over `timeframe`.
2. Summarise:
   - **Citations**: how often the brand's own pages were cited as sources. Surface top-cited URLs.
   - **Mentions**: how often the brand was mentioned in answer text (regardless of whose source).
   - Highlight any asymmetry — high citations + low mentions (Google is finding you but other brands are being talked about) is a different problem than the inverse.

## Step 4: Provider breakdown

`aivis_list_prompt_runs` requires both `promptId` and `brandId` — it can't be called at project scope. To get a provider breakdown:

1. Pick a representative sample of 5–10 prompts from Step 2 (mix of strong, weak, and gap topics).
2. Issue `aivis_list_prompt_runs` for each `promptId` against the primary `brandId` **in parallel as a single batch**.
3. Aggregate runs by provider and compare brand-mention/citation rates. If one provider scores far higher/lower than the others, call it out — it usually points to a specific weakness (search-grounded providers like Perplexity reward different content than pure-LLM providers).

Be explicit that this is a sample, not the full population.

## Step 5: Deliverable

Write the audit as a markdown report with these sections:

1. **TL;DR** — 3 bullets max: current score + delta, rank position, single biggest opportunity.
2. **Headline metrics** — score table with primary brand, top 3 competitors, deltas.
3. **What's working** — strong topics, citation wins.
4. **What's not** — weak topics, mention gaps, provider-specific weaknesses.
5. **Recommended next steps** — 3–5 specific actions (add prompts to topic X, investigate why provider Y scores low, etc.). Where useful, point the user at a sibling skill by name (e.g. *"run the `prompt-investigation` skill next"*); skills are matched on intent, not invoked as slash commands.

Always include the project ID and the timeframe at the top of the report so the user can re-run the same analysis later.

## Common pitfalls

- **Auto-account selection**: read tools auto-pick the account when the user has only one AI-Visibility-entitled account; if `lumar_get_me` shows several, pass `accountId` explicitly or the tool will return `validation/missing_account_id` with a `candidates` list.
- **Comparing across periods**: visibility scores are noisy week-to-week. Prefer `last_30d` vs `last_90d` over `last_7d` deltas unless the user explicitly asked for a short window.
- **Zero-mention topics**: a topic with 0 mentions and 0 citations may simply have no runs yet — confirm `total_runs > 0` before declaring a gap.
