---
name: brand-curation
description: Curate the tracked-brand set on an AI Visibility project — merge duplicate variants, promote the right one as primary, classify auto-discovered brands as Own/Competitor/Other, and attach domains for citation attribution. Use this skill whenever someone says "clean up brands", "merge these brands", "this is a duplicate of <brand>", "mark <X> as a competitor", "<X> is the same as <Y>", "fix the primary brand", or "why are there two of us in the list?". Also trigger when users review the brand list after the first prompt-run cycle and want to consolidate variants AI providers surfaced under different spellings.
---

# Brand Curation

Tidy a project's brand list so analytics (top-brands ranking, competitor benchmarks, citation share) reflect reality. New brands appear automatically once prompt runs mention them and default to type `Other`; this skill is the workflow for reclassifying, deduping, and rewiring them.

## Parameters

- **project**: Project name, domain, or "my project" — ask if ambiguous.
- **action**: What the user wants to do. Often phrased ambiguously; common cases below.

## Step 0: Resolve account + project

1. `lumar_get_me` → pick an AI-Visibility-entitled account (ask if multiple).
2. `aivis_list_projects` to resolve the project. Capture `projectId` and the primary brand id for reference.

## Step 1: See the current brand list

1. `aivis_list_brands` with the project, default timeframe `last_30d`. Note `type` (`Own` | `Competitor` | `Other`), `primary` flag, `domain`, and `avgVisibilityScore` per brand.
2. `aivis_get_top_brands` with the primary brand id to get the ranked view — useful when the user says "fix my leaderboard".
3. Look for obvious duplicates: variants of the same name (`Lumar` / `Lumar Inc` / `LumarSEO`), the brand surfacing under multiple casings or with/without "Ltd"/"Inc", domain typos, etc. List them for the user to confirm.

## Step 2: Pick the workflow

Match the user's intent to one of these patterns. Confirm before any mutation.

### A. Reclassify a brand's type

When the user says "<X> is a competitor" or "<Y> is one of ours":

1. `aivis_update_brand` with the target `brandId` and `type: Own | Competitor | Other`.
2. Re-run `aivis_get_top_brands` to confirm the ranking now treats it as a benchmark.

### B. Merge duplicate variants

When the user says "<A> and <B> are the same brand" / "merge these":

1. **Decide the target** — usually the variant with the most citations / cleanest name. Show the user both rows side-by-side and confirm.
2. `aivis_merge_brands` with `targetBrandId` (the keeper) and `sourceBrandIds` (the variants to absorb). Multiple sources are allowed; the target absorbs every source's citations + mentions + domains.
3. **You cannot merge the primary brand** — if the user wants to swap the primary, see workflow C below first.
4. Each source brand's response includes `mergedAt` + `mergedIntoAiVisibilityBrandRawId` — confirm the link in the response before reporting.

### C. Fix the wrong variant being primary

When the user says "the primary brand is wrong" or "make <X> the main one" and `<X>` is currently merged:

1. `aivis_promote_brand` with the merged variant's `brandId`. The currently-primary brand is demoted into the merged set in the same operation.
2. The response returns both `promotedBrand` and `previousMainBrand` — show the swap.
3. If the variant the user wants as primary is _not_ currently merged, they need to merge it under the current primary first (workflow B), then promote it.

### D. Reverse a merge

When the user says "undo the merge" / "split <X> back out":

1. `aivis_unmerge_brand` with the merged variant's `brandId`. Only that one variant detaches; other variants merged into the same target stay merged.

### E. Attach a domain to a brand

When the user says "attribute citations from <domain> to <brand>" or "this domain belongs to us":

1. Confirm the brand id via `aivis_list_brands` (search by name).
2. `aivis_create_brand_domain` (`brandId`, bare hostname, optional `includeSubdomains: true` when the brand owns every subdomain). Manage existing domains via `aivis_list_brand_domains` / `aivis_update_brand_domain` / `aivis_delete_brand_domain`.

## Step 3: Verify the result

After any mutation, re-call `aivis_list_brands` (and `aivis_get_top_brands` if relevant) and show the user the new state so they can confirm. Surface counts that changed — for a merge, the target's `totalBrandCitations` should be the sum of source + previous target.

## Important constraints

- **Cannot create a new competitor brand from MCP.** New brands appear automatically once prompt runs cite/mention them. If a competitor never shows up in runs, the user must add it via the Lumar dashboard.
- **Cannot rename brands from MCP.** Names come from how the brand surfaced in answers; `aivis_update_brand` only changes `type`. If the user wants a different display name, send them to the dashboard.
- **Destructive operations.** Merges and deletes always confirm with the user first — show the rows you're about to operate on by name + id + citation count.

## Output

Per workflow, a tight before/after diff:

```
Merged <source A> (#123), <source B> (#456) into <target> (#789)
  Target citations: 47 → 113 (+66)
  Sources now show mergedAt; subsequent listings will hide them.
```

Or for reclassification:

```
Reclassified <brand> (#234): Other → Competitor
Top-brands ranking updated (now position #3 of 8).
```
