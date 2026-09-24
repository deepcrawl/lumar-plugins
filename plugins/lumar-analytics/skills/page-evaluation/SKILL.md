---
name: page-evaluation
description: Drill into one URL's AI Visibility content evaluation — precision, recall, uniqueness, quality, trust, brand mention/sentiment/position, evergreen health, topical opportunity, plus the LLM reasoning and per-snippet/per-competitor evaluation arrays. Use this skill whenever someone asks "why does <url> score poorly?", "evaluate this page", "what should I fix on <url>?", "show me the content evaluation for <url>", "is <url> being cited?", or "trigger a re-eval on <url>". Also trigger when users want to understand AI engine references (Google AI Mode / AI Overview text blocks) for a single page.
---

# Page Evaluation

Produce a deep-dive report on one URL's content evaluation in AI Visibility: aggregated scores, the latest run's lifecycle, the LLM's reasoning, per-snippet precision evaluations, per-competitor uniqueness analysis, and brand mention/sentiment results. Also handles "re-evaluate this URL" requests.

## Parameters

- **url**: The URL to evaluate. Required, unless the user already has a `pageId` from another AI Visibility tool.
- **project**: AI Visibility project name or domain (ask if ambiguous; needed for the brand-scoped scores).
- **brand**: Which brand the URL's scores should be attributed to — usually the project's primary brand. Required for citation-quality fields, otherwise those are null/empty.
- **timeframe**: Optional window (default `last_30d`) — applies to score aggregation.

## Step 0: Resolve account, project, brand

1. `lumar_get_me` → pick an AI-Visibility-entitled account (ask if multiple). For Lumar system admins no account list is returned — resolve the account by name with `lumar_search_accounts` instead.
2. `aivis_list_projects` to resolve the project.
3. `aivis_list_brands` to confirm the brand id — usually the project's primary brand.

## Step 1: Decide whether evaluation data exists

Page runs only exist for URLs that have been crawled. Two ways to check:

1. `aivis_list_page_runs` (`projectId`, `url`, `limit: 5`, newest-first). Evaluation data exists only when a row has `status: Completed`. If the newest row has `isTerminal: false`, evaluation is still in flight — return its run id + status and say so. Decide "still running?" from `isTerminal` rather than listing the in-progress statuses yourself, so a status added later still reads correctly (the Failed case is handled below).
2. Alternatively, `aivis_get_brand_signals` (`type: citations`) — the tool has no URL filter, so scan the returned citation rows for the URL; if its row has `pageRunStatus: Completed` and a recent `latestRunAt`, scores are available.
   Match on `pageId`, never on the URL string: page scores, citations, discovered pages and page runs all carry the same `pageId` for the same page, and the raw `url` on each row is only a representative spelling. Two rows whose `url` differs by `http`/`https`, `www.`, a trailing slash or a `?ref=`/`utm_*` parameter are one page and share one `pageId`.
3. For URLs that surfaced via SERP discovery, `aivis_list_discovered_pages` (one row per URL) also carries `pageRunStatus` — null/`Discovered` means the URL hasn't been content-evaluated yet.

**If no run exists** for the URL:

- Tell the user.
- Offer to queue one via `aivis_trigger_page_run` (`projectId`, `url`). The mutation returns the run. If it errors saying the existing run is stuck, report that to the user and stop — retrying cannot clear it. If `alreadyInProgress` is true, nothing new was started and no further credit was committed (the run may be an automatic one, from a citation or SERP discovery, that the user never triggered) — an evaluation for this URL was already running and the returned run is that one; report it as in flight, not as newly queued.
- Don't auto-loop on completion — give the user the new run id and tell them content evaluation takes a few minutes. Re-run this skill once the run completes.

**If a run exists but `status: Failed`**, branch on `failureCode` and stop, quoting `failureReason` as the human-readable detail — never match on that text, which is prose and can be reworded. `CrawlRequestUnconfirmed` means the crawl request could not be confirmed — it may or may not have started, but nothing it produces will reach this run, so the page may have been crawled and a credit spent; escalate that one rather than offering a retry; `ProcessingExhaustedRetries` means it was retried to its limit; `ProcessingFailed` means the crawl itself failed, and `failureReason` carries why (page blocked by robots, 4xx/5xx, JS-rendered content that timed out). A run that failed before the code existed has `failureCode: null` and only `failureReason`.

## Step 2: Aggregated scores (one-screen summary)

Fire Step 2 + Step 3 in parallel — they're independent reads.

1. `aivis_get_page_scores` (`projectId`, `brandId`, `url` or `pageId`, `timeframe`) — single-row response averaged across runs in the window. Pass `pageId` when a previous tool already returned the page; pass `url` when the user supplied one (it is canonicalised server-side, so any spelling resolves to the same page).
2. Report the scoreboard (0–100 where available):
   - **Overall**: `avgVisibilityIndex` (composite ranking blend; `avgVisibilityScore` is its deprecated alias)
   - **Content quality side**: `avgPrecisionScore`, `avgRecallScore`, `avgUniquenessScore`, `avgQualityScore` (page content quality — not the brand-visibility quality split), `avgTrustScore`
   - **Brand side**: `avgCitationQualityScore`, `avgBrandMentionScore`, `avgBrandSentimentScore`, `avgBrandPosition` (1 = first cited; lower is better), `avgBrandPositionScore`, `totalBrandCitations`
   - **Discoverability**: `avgEvergreenHealthScore`, `avgTopicalOpportunityScore`, `avgQdfScore` (query-deserves-freshness), `avgGscQueryScore` (real-search-query relevance — only populated when a GSC property is attached; see the `gsc-setup` skill)
   - **Coverage**: `topicNames` (which topics' prompts cite this URL), `aiProviderTypes` (which AI engines cite it), `totalRuns`, `latestRunAt`.
3. Flag obvious issues: any sub-score < 40 is a "red"; 40–60 is "amber"; > 60 is "green".

## Step 3: Latest run lifecycle + freshness signals

1. `aivis_list_page_runs` (`projectId`, `url`, `limit: 5`, `orderField: createdAt`, `orderDirection: DESC`). Compact view by default — already shows scores, lifecycle, freshness.
2. Report:
   - Most recent run's `status`, `source` (Citation | Manual | SerpDiscovery), `createdAt`.
   - Freshness signals: `pageFreshnessLastModifiedDate`, `pageFreshnessConfidenceLevel`, `pageFreshnessReasoning`, `contentIsOldForTrend` — these explain _why_ an `avgEvergreenHealthScore` might be low.
   - Topic-trend signals: `topicTrendDetected`, `topicTrendStrength`, `topicTrendPriority` — useful for the user to decide whether this URL is on a rising or fading topic.
3. If the user wants to dig deeper, take the latest run's `id` into Step 4.

## Step 4: Single-run drilldown (only when the user asks "why")

`aivis_get_page_run` (`projectId`, `pageRunId` from Step 3) returns the LLM's full reasoning + raw evaluation arrays for one run. The `sections` argument selects which detail blocks to include — the default is everything except `precision` and `uniqueness` (the two heaviest); fetch those in a follow-up call (`sections: ["precision"]`, then `["uniqueness"]`) when the user wants snippet-level or competitor-level fixes.

What you get back, and how to use each:

- **`intendedConcept`, `primaryPageIntent`, `userIntents`, `pageIntents`** — the LLM's read of what the page is about. Compare to the topics the project tracks.
- **`coveredSubjects`, `missingAspects`, `topSemanticRecallRecommendations`** — gap analysis. Surface `missingAspects` as a concrete fix list.
- **`contentPrecisionEvaluations[]`** — per-snippet scoring with `text`, `precisionScore`, `relevanceClassification`, plus `contributionAnalysis` and `improvementRecommendations`. Report the 3 lowest-scoring snippets with their `text` + recommendation.
- **`uniquenessEvaluations[]`** — per-competitor URL comparison: `competitorUrl`, `uniquenessScore`, `overlapScore`, `uniqueElements`, `overlappingElements`, `missingElements`, `explanation`, `suggestions`. Report the most overlap-heavy competitor with the `suggestions` text.
- **`contentEvalsBrandMentions[]`** — per-model brand mention positions (so the user sees which AI engine ranks the page where).
- **`brandSentimentResults[]`** — per-model `sentiment`, `authority`, `competitiveRanking`, `reasoning`, `recommendations`, `topics`. Best place to find _why_ a sentiment score is what it is.
- **`gscQueryEvaluations[]`** — per-query relevance (only populated when GSC is attached). Each row has `question`, `score`, `assessment`, `suggestions`, `clicks`. Surface the bottom 3 by score as concrete content-update ideas.
- **`qdfQueryEvaluations[]`** — query-deserves-freshness rationales.
- **`googleAiModeReferences[]`, `googleAiOverviewReferences[]`** — when Google AI Mode / AI Overview cite _other_ sources for the queries this URL targets, those references show up here. Useful for "who's beating us on these queries?"
- **`googleAiModeTextBlocks`, `googleAiOverviewTextBlocks`** — the actual text blocks Google AI generated. Long strings — quote selectively.

If `response/too_large` fires, request fewer `sections` per call — one section at a time always fits for all but the most extreme pages.

## Step 5: Re-evaluate (when the page has changed)

When the user updated the page and wants fresh scoring:

1. `aivis_trigger_page_run` (`projectId`, `url`) → returns the run, `alreadyInProgress` (true when an evaluation for this URL was already running, so nothing was started and no credit spent).
2. Don't poll inside the conversation — return the new run id and tell the user to re-run this skill in a few minutes (or call `aivis_list_page_runs` themselves).

## Output

A structured report:

```
URL: <url>
Project: <project name>  Brand: <brand name>
Latest run: <status> at <createdAt>  source=<Citation|Manual|SerpDiscovery>

Scoreboard (avg over <timeframe>, <totalRuns> run(s)):
  Overall visibility index: <score>/100  [red|amber|green]
  Content:  precision <n>, recall <n>, uniqueness <n>, quality <n>, trust <n>
  Brand:    citation-quality <n>, mention <n>, sentiment <n>, position <n> (rank), total citations <n>
  Discovery: evergreen <n>, topical-opportunity <n>, QDF <n>, GSC-query <n or "n/a — no GSC binding">

Topics that cite this URL: <topicNames>
AI engines that cite it:   <aiProviderTypes>

Top issues (from compact run):
  - <freshness / topic-trend / lacks-logical-chunks signals>

Recommendations (drilldown only):
  - <missingAspects, topSemanticRecallRecommendations>
  - <lowest-precision snippet text + improvementRecommendations>
  - <most-overlap competitor + suggestions>
  - <lowest-score GSC queries + suggestions>
```
