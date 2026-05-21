---
name: topic-bootstrap
description: Bootstrap a new AI Visibility project from scratch — create the project, infer topics from a brand description, and seed prompts in bulk. Use this skill whenever someone wants to start tracking a new brand's AI Visibility, asks to create an AI Visibility project, needs to generate topics and prompts for a brand, says "set up AI Visibility for <brand>", or wants to onboard a new customer to AI Visibility. Also trigger when users ask "what should I track?" for a brand or want help brainstorming prompts for an AI Visibility project.
---

# Topic Bootstrap

Onboard a brand to Lumar AI Visibility in one pass: create the project, propose a starter topic set from the brand's category and positioning, and bulk-create up to 50 topics with their prompts atomically.

## Parameters

- **brand_name**: The primary brand to track (e.g. "Lumar").
- **brand_domain**: The brand's primary domain as a bare hostname (e.g. `lumar.io` — no protocol, no path).
- **brand_description**: A few sentences about what the brand does, who it serves, and its primary category. The richer this is, the better the proposed topics.
- **competitors**: Optional list of competitor names + domains to track alongside the primary brand.
- **country**: Optional ISO 3166-1 alpha-2 region for the prompts (e.g. `US`, `GB`, `DE`). Set per-prompt at creation time; omit for worldwide. Ask the user if the brand is region-specific.

## Step 0: Resolve account

1. `lumar_get_me` → confirm the user has an AI-Visibility-entitled account.
2. If multiple accounts, ask which to use.

## Step 1: Confirm project doesn't already exist

1. `aivis_list_projects` → check for any existing project on the chosen account whose primary brand matches `brand_name` or `brand_domain`.
2. If a match exists, stop and ask whether the user wants to:
   - Add topics/prompts to the existing project (skip Step 2, jump to Step 3 with the existing project ID), or
   - Create a separate project anyway (rare — usually a mistake).

## Step 2: Create the project

1. Validate `brand_domain` is a bare hostname. Strip any `https://`, trailing slash, or path the user accidentally included.
2. `aivis_create_project` with the primary brand name and the cleaned hostname.
3. Capture the returned project ID and primary brand ID — every subsequent call needs them.

## Step 3: Propose a topic set

This is the highest-leverage step. A good topic set has 8–15 topics, each focused enough that prompts within it share a clear intent.

### Topic-shape heuristics

- **Category questions** — "best CRM for startups", "how to choose a project management tool". Broad, high-volume, competitive.
- **Branded questions** — "is <brand> good?", "<brand> vs <competitor>", "<brand> pricing". Lower volume but high signal — these directly probe how AI talks about the brand.
- **Job-to-be-done questions** — "how to reduce churn", "how to track SEO". The brand may or may not be the recommended answer; tracks whether it shows up in adjacent contexts.
- **Comparison questions** — "<brand> vs <competitor>", "alternatives to <competitor>". One per major competitor.
- **Decision-stage questions** — "how to evaluate <category>", "what to look for in <category>". Catches research-phase mindshare.

### Prompt set per topic

5–10 prompts per topic. Cover phrasing variations (question form, listicle form, comparison form) so per-provider quirks don't bias the score. Example for a "best <category>" topic:

- "What's the best <category> tool?"
- "Top 10 <category> tools in 2026"
- "Which <category> tool should I use for <use case>?"
- "Recommend a <category> tool for <persona>"

### Present for review

Show the proposed topics + sample prompts as a table. **Wait for the user to approve or edit** before any creation step. They almost always tweak names, drop topics, or swap in domain-specific phrasing.

## Step 4: Bulk-create topics and prompts

1. `aivis_bulk_create_topics` with the approved list — up to 50 topics in one atomic call. Each topic carries its prompts as a nested array; each prompt may set a `country` (ISO 3166-1 alpha-2) for per-region targeting, or omit it for worldwide. Each topic needs ≥ 1 prompt; each prompt ≤ 2500 chars.
2. If the user approved more than 50 topics (rare), batch into multiple calls — but warn first, since later batches won't roll back if an earlier batch fails.

Show the resulting topic IDs in a confirmation table so the user can sanity-check.

## Step 5 (optional): Attach competitor domains

There is **no MCP mutation to create a new competitor brand** — competitor brands are surfaced automatically once prompt runs start mentioning them, or added in the Lumar dashboard. The MCP toolset only exposes `aivis_create_brand_domain`, which attaches a domain to a brand that already exists.

If the user supplied competitor names + domains:

1. Tell them up front: new competitor brands cannot be created from here. They will either appear automatically after the first run cycle (if AI providers mention them) or need to be created in the Lumar dashboard.
2. Once a competitor brand exists on the project, list it via `aivis_list_brands` (use `query` to filter by name) to capture its `brandId`.
3. For each existing competitor brand, attach its domain(s) with `aivis_create_brand_domain` (`brandId` + bare hostname) so its citations attribute correctly. Set `includeSubdomains: true` when appropriate.

## Step 6: Set expectations

Before signing off, tell the user:

- First prompt runs typically complete within a few hours. They can poll `aivis_list_prompt_runs` or come back tomorrow.
- A useful visibility score needs at least a few days of runs across multiple providers — don't pull `aivis_get_visibility_scores` on day one and expect signal.
- They can re-run this skill to add more topics later, or ask for an AI Visibility audit (the `ai-visibility-audit` skill) once data is in.

## Common pitfalls

- **Hostname validation**: `aivis_create_project` and `aivis_create_brand_domain` reject protocols, paths, and trailing slashes on `domain`. Always pre-strip.
- **Atomicity boundary**: `aivis_bulk_create_topics` is atomic per call. If a single topic in the batch fails (e.g. duplicate name), the whole batch rolls back — fix the bad entry rather than retrying the rest piecemeal.
- **Archival not exposed**: there's no MCP tool to archive a project. If the user creates a project they meant to merge into another, they must archive it via the Lumar dashboard.
