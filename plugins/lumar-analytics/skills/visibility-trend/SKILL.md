---
name: visibility-trend
description: Analyse how a brand's AI Visibility score has changed over time, attribute movement to specific topics or prompts, and detect step changes. Use this skill whenever someone asks "why did our visibility drop?", "what changed in our AI Visibility?", wants to see a visibility trend chart, asks for a week-over-week or month-over-month comparison, or needs to investigate a sudden score change. Also trigger when users mention visibility drift, attribution, or want to understand which topics moved the overall score.
---

# Visibility Trend Analysis

Trace a Lumar AI Visibility score over time, attribute changes to the topics and prompts that moved, and flag step changes worth investigating.

## Tools

This skill uses **Lumar MCP tools** exclusively. All tool references below (`lumar_get_me`, `aivis_*`) refer to the Lumar connector (prefixed `lumar:` in the tool list).

## Parameters

- **brand_or_project**: Brand name, project name, or "my project".
- **timeframe**: Default `last_90d` so trend is visible. Accepts named windows or `{ start, end }`.
- **granularity**: How to bucket the series — `day`, `week`, or `month`. Default `week` for `last_90d`+, `day` for shorter windows.

## Step 0: Resolve account, project, and brand

1. `lumar_get_me` → pick AI-Visibility-entitled account.
2. `aivis_list_projects` → pick project. Note the primary brand.

## Step 1: Pull the score time series

`aivis_get_visibility_scores` for the primary brand over `timeframe`, with the requested granularity and `previousPeriod` enabled.

Render a compact text-mode chart (sparkline characters or a simple table — markdown can't draw real charts). Annotate:

- Current vs prior-period score and delta.
- Max and min points in the window with their dates.
- Any single-bucket move ≥ 5 points (up or down) — these are step changes worth investigating.

## Step 2: Decompose the score

The visibility score has two components:

- `avg_citation_quality_score` × √(citation_runs / total_runs) × 0.25
- `avg_brand_mention_quality_score` × √(mention_runs / total_runs) × 0.75

Plot both components alongside the headline score. If they move together, the change is broad-based. If only one moved, the diagnosis narrows:

- **Mentions component dropped, citations stable**: AI answers stopped talking about the brand by name. Often follows a category shift, a competitor PR moment, or a brand positioning change.
- **Citations component dropped, mentions stable**: AI providers stopped citing the brand's pages as sources. Often follows a sitemap / robots / canonical change, a site migration, or content being deindexed.
- **Both dropped uniformly**: usually a coverage issue — fewer prompt runs completed in the window. Check `total_runs` per bucket; if it dropped, runs were paused or failed, not visibility itself.

## Step 3: Attribute movement to topics

For the period showing the biggest delta:

1. `aivis_list_topics` for the primary brand at the start of the window and at the end (use two `aivis_get_visibility_scores` calls scoped per topic if needed — or just compare topic-level visibility from the most recent run set).
2. Compute per-topic delta. Sort.
3. Surface:
   - **Top 3 topics that gained score**.
   - **Top 3 topics that lost score**.
   - Whether the overall change is concentrated in 1–2 topics or spread across many.

If concentrated (one topic explains > 50 % of the move), recommend the user drill into that topic with `/lumar-analytics:prompt-investigation` on its worst-moving prompt.

## Step 4: Step-change investigation

If Step 1 flagged a step change (≥ 5 point move in a single bucket):

1. Note the bucket boundary date.
2. `aivis_list_prompt_runs` filtered to that bucket. Compare the run mix to the surrounding buckets — did a provider start or stop? Did the run volume jump?
3. Check whether the project added or removed topics/prompts around that date. (`aivis_list_topics` and `aivis_list_prompts` don't return creation dates directly, but the user usually knows.)
4. If none of those explain it, the answer is in the prompt-run details — pick one prompt that scored very differently in the step bucket vs neighbouring buckets and recommend `/lumar-analytics:prompt-investigation` on it.

## Step 5: Deliverable

Markdown report:

1. **TL;DR** — current score, delta, biggest mover.
2. **Trend chart** — text/markdown table or sparkline.
3. **Component breakdown** — citations vs mentions over time.
4. **Topic attribution** — winners and losers.
5. **Step changes** — annotated bucket boundaries with hypothesised cause.
6. **Recommended next steps** — 2–3 follow-ups, each tied to a specific observation.

## Common pitfalls

- **Short window noise**: `last_7d` trends are usually noise unless run volume is very high. Default to `last_90d` with weekly granularity for trend questions; only zoom to daily when investigating a confirmed step change.
- **Comparing visibility scores across brands**: the score is brand-relative. The same topic can produce a 60 for one brand and 20 for another simply because they're being measured differently — never present cross-brand deltas without `aivis_get_top_brands` context.
- **Confusing run-volume changes with visibility changes**: if `total_runs` per bucket varies, the `√(runs/total_runs)` dampener can swing scores even when raw quality scores are flat. Always plot run volume alongside the score.
