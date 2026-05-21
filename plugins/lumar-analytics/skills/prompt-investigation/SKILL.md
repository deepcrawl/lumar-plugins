---
name: prompt-investigation
description: Drill into a specific AI Visibility prompt to understand exactly what AI providers said, which brands and pages they cited, and why the primary brand did (or didn't) appear. Use this skill whenever someone asks why a prompt is scoring low, wants to see the actual AI answer to a prompt, asks "what did ChatGPT say about <topic>?", wants to debug a specific prompt run, or needs to understand the gap between expected and actual brand mentions. Also trigger when users want to see search queries the provider used, inspect citations on a run, or compare provider answers for the same prompt.
---

# Prompt Investigation

Open the black box on a single AI Visibility prompt. Shows the full provider answer, which brands were cited and mentioned, what search queries the provider issued, and where the primary brand ranks in the answer.

## Tools

This skill uses **Lumar MCP tools** exclusively. All tool references below (`lumar_get_me`, `aivis_*`) refer to the Lumar connector (prefixed `lumar:` in the tool list).

## Parameters

- **prompt_id**: The prompt to investigate. If the user gives a prompt text instead, search for it first.
- **timeframe**: The window of prompt runs to consider (default: `last_30d`).
- **provider**: Optional — narrow to a single provider (OpenAI, Perplexity, Gemini, Claude, Google AI Overviews).

## Step 0: Resolve account, project, and prompt

1. `lumar_get_me` → pick AI-Visibility-entitled account.
2. If the user named a prompt by text, call `aivis_list_prompts` to find it. If multiple prompts match, present a disambiguation list and ask. Never silently pick.
3. Note the prompt's project ID and the project's primary brand.

## Step 1: Pull the run set

`aivis_list_prompt_runs` filtered by `promptId` over `timeframe`. Optionally filter by `provider`.

Build a one-line summary per run:

| Date | Provider | Primary brand cited? | Primary brand mentioned? | Visibility contribution |

Sort by date desc. If there are more than 10 runs, summarise the rest and focus the rest of the skill on the most recent 3–5.

## Step 2: Inspect individual runs

For each focused run, call `aivis_get_prompt_run_details`. Surface:

- **AI answer** (the full text). Render in a quoted block.
- **Search queries** the provider issued (if available — Perplexity, Google AI Overviews, and recent ChatGPT runs expose these via the `searchQueries` field).
- **Citations** — list of URLs the answer cited, with their attributed brand if any.
- **Mentions** — brand names mentioned inline, with quality score.
- **Other brand citations** — citations to brands tracked on the project that aren't the primary brand. This is the competitive view: who is the AI recommending instead?
- **Component scores** — citation quality and brand-mention quality the run contributed.

## Step 3: Diagnose the pattern

Look across the runs and answer these questions explicitly:

1. **Is the primary brand appearing at all?** If 0 mentions and 0 citations across all runs, the prompt is a complete miss — likely the brand has no content matching the intent, or its content isn't being indexed/cited by AI providers.
2. **Where in the answer does the brand appear?** A brand mentioned in the first paragraph beats one in a "see also" tail. Quote position.
3. **Who is winning?** If the same competitor keeps appearing first, that's the brand the user needs to displace. Name them.
4. **Are providers using different search queries?** When provider answers diverge, search-grounded providers (Perplexity, Google AI Overviews) often reveal _why_ — they show the queries they ran and the sources they pulled. LLM-only providers (older ChatGPT, older Claude) reflect training-data baked-in associations.
5. **Are cited sources owned by the brand or third-party?** Citations to the brand's own domain are usually under their control. Citations to third-party reviews / listicles / Reddit aren't — but tell you which third-party content to influence.

## Step 4: Recommendations

For each diagnosis above, suggest a specific action. Examples:

- "Three of the four cited sources on this prompt are listicles on `competitor-blog.com`. Pitch <brand> to be added to those listicles, or commission similar listicles."
- "Perplexity's search queries for this prompt include `<query>`. There's no page on <brand-domain> targeting that query — consider creating one."
- "ChatGPT places <brand> last in a 6-item list; the top 3 are positioned as 'enterprise leaders'. The brand may be perceived as mid-market — review positioning copy."

Avoid generic advice ("write more content"). Tie every recommendation to a specific observation in the run data.

## Step 5: Optional follow-ups

If the investigation surfaces a topic-wide pattern (not just this one prompt), suggest the user run `/lumar-analytics:competitor-benchmark` next to confirm.

If the prompt is fine and the user was investigating a hunch, say so explicitly — false alarms are useful signal.

## Common pitfalls

- **`searchQueries` is optional**: not every provider on every run records the queries it issued. Don't fabricate when the field is empty — say "this provider didn't expose the search queries used."
- **Pending / failed runs**: `aivis_list_prompt_runs` returns runs in any state. Filter to finished runs before drawing conclusions — a failed run has no answer and no scores.
- **Citation vs mention scoring weights**: the visibility formula weights mentions 75 % and citations 25 %. A run with strong citations but no mention will still score below one with a strong mention — don't equate the two.
