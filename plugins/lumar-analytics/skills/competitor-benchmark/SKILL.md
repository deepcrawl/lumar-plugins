---
name: competitor-benchmark
description: Compare a brand against its competitors across visibility score, topic-by-topic performance, citation share, and brand mention quality. Use this skill whenever someone asks how their brand stacks up against competitors in AI search, wants a competitive AI Visibility analysis, asks "how do I compare to <competitor>?", "who's beating us in AI?", or wants to find topics where competitors dominate. Also trigger when users mention competitive analysis for GEO / AI search, brand share-of-voice in AI answers, or benchmarking against a specific competitor list.
---

# Competitor Benchmark

Compare a Lumar AI Visibility primary brand against tracked competitors. Highlights where the brand wins, where it loses, and which topics drive the gap.

## Tools

This skill uses **Lumar MCP tools** exclusively. All tool references below (`lumar_get_me`, `aivis_*`) refer to the Lumar connector (prefixed `lumar:` in the tool list).

## Parameters

- **brand_or_project**: What the user provides — brand name, project name, or "my project".
- **competitors**: Optional explicit list of competitor names/IDs. Defaults to all competitors tracked on the project.
- **timeframe**: Default `last_30d`. Accepts named windows or `{ start, end }`.

## Step 0: Resolve account, project, and brand set

1. `lumar_get_me` → pick AI-Visibility-entitled account (ask if multiple).
2. `aivis_list_projects` → pick project. Note its primary brand.
3. `aivis_list_brands` for the project to get the full tracked-brand list.
4. If the user named specific competitors, filter to those (warn on any name that didn't match a tracked brand — suggest they add it on the project before re-running).
5. If no list given, use the top 5 tracked competitors by visibility score from `aivis_get_top_brands`.

## Step 1: Leaderboard

`aivis_get_top_brands` for the project over `timeframe`. Build a single table:

| Rank | Brand | Visibility | Citations component | Mentions component | Δ vs prior period |

Mark the primary brand row (⭐). If the primary brand isn't in the top N, extend the list until it appears.

## Step 2: Per-topic head-to-head

For each topic returned by `aivis_list_topics` (primary brand), pull the same metric for each competitor:

1. Call `aivis_list_topics` once per competitor brand ID. (Topics are project-scoped, so the topic IDs are stable across brands — you're just changing the lens.)
2. Build a matrix:
   - Rows: topics (project-wide)
   - Columns: primary brand + each competitor
   - Cells: visibility score

3. Surface:
   - **Topics where the primary wins** (highest score in row) — at least 3 examples.
   - **Topics where a competitor wins by ≥ 10 points** — at least 3 examples. These are the priority gaps.
   - **Topics where no brand is doing well** (all < 20) — "open territory" the primary can claim with more prompts/content.

## Step 3: Citation vs mention asymmetry

For the primary brand and the top 2 competitors, call `aivis_get_brand_signals` with `type: "both"`. Compare:

- Citation count and average citation quality.
- Mention count and average mention quality.

Two common patterns to call out:

- **Citation-rich, mention-poor**: brand has authoritative pages but isn't being talked about by name. Implies a brand-recognition or category-positioning problem.
- **Mention-rich, citation-poor**: brand has buzz but no content AI providers trust as sources. Implies a content/SEO problem.

## Step 4: Prompt-level wins and losses (optional, gated by depth)

If the user asked for a "deep" or "detailed" benchmark — or if Step 2 surfaced a topic gap they want to drill into — pick the 1–2 most lopsided topics and:

1. `aivis_list_prompts` filtered by that topic.
2. For the worst-performing prompt for the primary brand on that topic, call `aivis_get_prompt_run_details` on a recent run to surface the actual AI answer, which brands were cited/mentioned, and which sources beat the primary brand.

Don't do this for every topic — keep it to 1–2 illustrative drill-downs so the report stays scannable.

## Step 5: Deliverable

Write the benchmark as a markdown report with:

1. **TL;DR** — 3 bullets: where the primary brand stands, biggest competitor threat, most actionable gap.
2. **Leaderboard table** — top brands with deltas.
3. **Topic matrix** — wins / losses / open territory.
4. **Citation vs mention pattern** — which side of the asymmetry each brand sits on.
5. **Recommended actions** — 3–5 specific moves. For each, suggest which skill to run next (e.g. `/lumar-analytics:prompt-investigation <prompt-id>`).

## Common pitfalls

- **Comparing brands across projects**: AI Visibility brands belong to a project. If a competitor is tracked under a different project, you can't compare them directly — point that out instead of returning a misleading table.
- **Tiny sample sizes**: in short windows, a competitor with 1 winning run on a topic can look like a "leader" when it's noise. Filter topic-level comparisons to those with `total_runs >= 5` for stability.
- **Domain attribution**: a brand only gets credit for citations to domains attached to it. If the user is surprised a competitor's citations are low, check whether their domains are fully attached via `aivis_list_brand_domains`.
