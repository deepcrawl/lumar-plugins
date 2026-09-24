---
name: sentiment-themes
description: Explain how AI engines feel about a brand theme by theme — pricing, support, ease of use — and show the exact statements and sources behind each theme's sentiment score. Use this skill whenever someone asks "why is our pricing sentiment low?", "what are AI answers actually saying about our support?", "which themes are hurting our sentiment?", wants a brand sentiment breakdown, asks which sources drive a negative or positive theme, or wants to compare theme sentiment against a competitor. Also trigger when users mention sentiment themes, claims, theme drilldown, or the Sentiment page of Lumar's GEO app.
---

# Theme Sentiment & Claims

Break a brand's AI sentiment down by theme, then drill into one theme to show the verbatim claims AI answers made and the sources they cited.

## Tools

This skill uses **Lumar MCP tools** exclusively. All tool references below (`lumar_get_me`, `aivis_*`) refer to the Lumar connector (prefixed `lumar:` in the tool list).

## Parameters

- **brand_or_project**: Brand name, project name, or "my project". Defaults to the project's primary brand.
- **theme**: Optional theme to drill into (e.g. "pricing"). Matched by title against the theme list.
- **timeframe**: Default `last_30d`. Accepts named windows or `{ start, end }`.
- **competitor**: Optional second brand for a side-by-side.

## Step 0: Resolve account, project, and brand

1. `lumar_get_me` → pick an AI-Visibility-entitled account. (System admins get no account list — resolve by name with `lumar_search_accounts`.)
2. `aivis_list_projects` → pick the project. Note the primary brand and whether `brandThemeSentimentCaptureEnabled` is on.
3. If a competitor was named, `aivis_get_top_brands` (or `aivis_list_brands`) to resolve its `id`.

## Step 1: Theme profile

When the user asks _where_ sentiment is weakest rather than _what_ is being said, start one level up: `aivis_list_topics` with `sortBy: "avgBrandSentiment", sortDirection: "ASC"` ranks every topic in the project by the brand's average mention sentiment (topics the brand was never mentioned in sort last). Pick the worst topics, then drill into the themes below for the claims behind them.

`aivis_list_theme_sentiments` for the brand over `timeframe`, with `comparisonTimeframe` set to the equal-length prior window so every theme carries a `previousPeriod` delta. Order by `avgSentiment` (default) and page if `totalCount` exceeds the page. Each theme's `id` is the value the drill-down and merge tools take.

Present a table: theme title, `avgSentiment` (0–100), delta vs prior period, `totalMentions`, `runsCount`, `totalClaims` (how many quoted statements back the score — the size of the Step 2 list). Flag:

- **Weakest themes** — lowest `avgSentiment` with meaningful volume (`totalMentions` ≥ 3). One-off scores on a single answer are anecdotes, not trends.
- **Biggest movers** — largest delta either way.
- **Unresolved themes** (`unresolved: true`) — the score is real but the theme registry hasn't described it yet; label them by `upstreamThemeId` and say the title is pending.

If the list is empty: check `brandThemeSentimentCaptureEnabled` on the project. When it is off, say so and offer `aivis_update_project` to opt in; when it is on, explain capture starts on the next prompt runs and the prompt tracker may not be capturing yet — an empty list is a normal state, not a bug.

## Step 2: Drill into a theme

For the theme the user asked about (or the weakest / biggest-moving one), `aivis_list_theme_sentiment_claims` with the theme's `id` as `themeId`. It returns the claims flat, newest answers first; pass `polarities: ["Negative"]` to see only the damaging statements (or `["Positive"]` for the flattering ones) and page while `totalCount` exceeds the page. Each claim carries:

- `quote` — the statement verbatim, often a clause. Quote it as-is; never paraphrase a claim as if it were the AI's words.
- `polarity` — `Positive` / `Neutral` / `Negative`. `Neutral` means factually valenceless (e.g. "is available in 12 countries"), not balanced.
- `promptText`, `aiProviderType`, `createdAt` — which prompt and AI platform produced the statement, and when. Use them to spot a prompt or provider that keeps producing the same complaint.
- `citations` — the URLs the answer cited in that sentence. Empty means the provider cited nothing inline for it, which is common and not an error.
- `aiVisibilityPromptRunRawId` — the answer the claim came from; the same id is `aiVisibilityPromptRunRawId` on the answer rows below.

When the score of each individual answer matters (the user asks "which answers rated us lowest and what did they say?"), use `aivis_list_theme_sentiment_answers` instead: one row per scored answer (`sentiment`, `sentimentJustification`, `aiProviderType`, `aiVisibilityPromptRunRawId`) with that answer's `claims` nested.

Summarise per theme:

1. **What is being said** — group claims by polarity, quote 2–3 representative ones per group, note how many answers repeat the same point.
2. **Driving sources** — tally `citations` URLs across the negative (or positive) claims; the most-cited domains are what shape that theme. Note claims with no citation as "unsourced assertions".
3. **Provider split** — if one `aiProviderType` carries most of the negative claims, say so.

Do **not** recompute a theme's score from its claim polarities. The 0–100 `sentiment` is the evaluator's holistic judgement ("great but pricey" scores high, not medium) and the two can legitimately disagree — report both, never "correct" one with the other.

To read a claim in context, `aivis_get_prompt_run_details` with the claim's `aiVisibilityPromptRunRawId`; `textSpan` gives the character offsets into `fullAnswerText`.

## Step 3: Competitor comparison (optional)

`aivis_get_theme_sentiment_matrix` with `brandIds` set to the brand and the competitor(s) returns every theme × brand cell in one call (`avgSentiment`, `totalMentions`, `runsCount`, `totalClaims`); a missing cell means that brand had no sentiment on the theme. Line the columns up by theme. Rows are the `themeLimit` themes with the most sentiment across those brands (default 50); if `truncated` is true, raise `themeLimit` (max 100), narrow `timeframe` or pass `topicId`. For period-over-period deltas per brand, fall back to repeating Step 1 for the competitor and matching by theme title. Call out themes where the competitor scores materially higher (≥ 10 points) with comparable volume — those are the positioning gaps. Drill into the competitor's claims on that theme with Step 2 to see what the AI credits them for.

## Step 4: Deliverable

Markdown report:

1. **TL;DR** — strongest and weakest themes, biggest mover, one sentence on the dominant driver.
2. **Theme profile table** — from Step 1.
3. **Theme drilldowns** — one section per drilled theme: what is said (quoted), driving sources, provider split.
4. **Competitor gaps** — if requested.
5. **Recommended actions** — 2–3, each tied to a specific claim or source (e.g. "the pricing complaints all cite <domain>; that page is out of date").

## Common pitfalls

- **Treating a claim's polarity as the theme's sentiment**: they are different computations from different inputs. Report the score and the claims side by side.
- **Ranking themes on one answer**: sort weak themes by `avgSentiment` but require volume before calling anything a pattern.
- **Reading empty citations as missing data**: many providers cite out of band or not at all; the claim is still real.
- **Old rows**: answers scored before claims were captured contribute no claims (`totalClaims` 0 on the theme, empty `claims` on the answer rows). Narrow `timeframe` if the drill-down is mostly empty.
- **Theme duplicates** ("Pricing" and "Cost"): don't average them by hand — offer `aivis_merge_themes` (confirm first; it cannot be undone and takes effect asynchronously).
