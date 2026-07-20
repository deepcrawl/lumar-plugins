---
name: provider-management
description: Manage which AI providers (OpenAI, Anthropic, Gemini, Perplexity, etc.) are linked to an AI Visibility project, browse the catalog of available providers, or sync the linked set with the account's subscription. Use this skill whenever someone asks to "add Claude to my project", "turn off Perplexity", "what providers are running on this project?", "what providers could I enable?", "sync providers with my subscription", or "why isn't <provider> in my runs?". Also trigger when users wonder why an enable/disable didn't stick — explains the subscription-sync mode caveat.
---

# AI Provider Management

Curate which AI providers a project queries on each scheduled run. Catalog discovery (what's in the subscription), per-project link/unlink, and on-demand subscription sync. Built around the constraint that some accounts auto-sync providers with the subscription, which can revert per-project toggles. Defaults are per account type: self-serve accounts keep auto-sync **on**; enterprise accounts manage their linked set manually (sync **off**).

## Parameters

- **project**: Project name or domain (ask if ambiguous).
- **action**: Often inferred from the user's wording — list / enable / disable / sync. Confirm before any mutation.
- **provider**: For enable/disable, the provider's name or type (e.g. "OpenAI", "Claude", "Perplexity", `AnthropicApi`).

## Step 0: Resolve account + check sync mode

Always start here — the result changes how the rest of the skill behaves.

1. `lumar_get_me` → pick an AI-Visibility-entitled account (ask if multiple). For Lumar system admins no account list is returned — resolve the account by name with `lumar_search_accounts` instead.
2. `aivis_get_account_settings` (`accountId`). Capture the `aiProvidersSyncWithSubscription` flag — this is the critical context for any per-project enable/disable. Self-serve accounts default to `true`; enterprise accounts default to `false` (manual management).
3. If the user asked to mutate providers (enable/disable) AND `aiProvidersSyncWithSubscription === true`, **tell them up front**:

   > "Your account has `aiProvidersSyncWithSubscription` turned on, which means the project's provider set is auto-synced with the subscription. Per-project enable/disable mutations will be reverted on the next prompt/topic/run mutation. To make manual toggles stick, this needs to be turned off in account settings first. Want to proceed anyway (one-time toggle), or stop here?"

   Wait for confirmation before mutating.
4. Even with sync off, providers the account is no longer entitled to are still removed automatically — manual mode only protects toggles within the entitled set.

## Step 1: Resolve project

1. `aivis_list_projects` with `query` filtering on the user-supplied name/domain. Match exactly; if multiple, ask.

## Step 2: Pick the workflow

### A. "What's currently linked to this project?"

1. `aivis_list_project_ai_providers` (`projectId`) → the providers currently linked, regardless of run activity.
2. Optionally pair with `aivis_list_active_providers` (`projectId`, `timeframe: last_30d`) to show which of the linked providers actually produced finished runs vs which are linked-but-idle. Idle providers are usually a sign that a recent enable hasn't run yet, or the subscription auto-sync dropped them.

### B. "What providers could I add?"

1. `aivis_list_ai_providers` (`accountId`) → the full catalog of providers AI Visibility knows about.
2. Annotate each row:
   - **`included: true`** — in the account's subscription addon. Eligible to link.
   - **`included: false`** — not in the subscription. Cannot be linked (the mutation will reject); the user needs to upgrade the addon via the Lumar dashboard.
3. Cross-reference with the project-linked set (workflow A) to label each as "already linked" / "available to add" / "blocked by subscription".

### C. "Enable provider <X> on this project"

1. Confirm subscription-sync mode from Step 0 — if on, get user confirmation per the prompt above.
2. Resolve the provider's `aiProviderId` from the catalog (workflow B). If the user named it ambiguously ("Claude"), match against `name` and `type` (`AnthropicApi`); if multiple, ask.
3. If the catalog shows `included: false`, stop and tell the user — link will fail.
4. `aivis_enable_project_ai_provider` (`accountId`, `projectId`, `aiProviderId`).
5. **Verify it stuck**: re-call `aivis_list_project_ai_providers` and show the user the provider is now in the list. Especially important under sync mode — if it's already missing, surface that immediately.

### D. "Disable provider <X> on this project"

1. Same sync-mode warning as enable.
2. Confirm the provider id via `aivis_list_project_ai_providers` (use the linked set, not the catalog — only currently-linked providers can be disabled).
3. `aivis_disable_project_ai_provider` (`accountId`, `projectId`, `aiProviderId`) — destructive; existing runs/analytics are preserved.
4. Verify by re-listing.

### E. "Sync providers with my subscription"

For when the subscription changed and the user wants the project to pick up newly-included providers (or drop removed ones) without waiting for the auto-sync to fire on the next mutation.

1. `aivis_sync_project_ai_providers` (`accountId`, `projectId`) → returns `{ success: true }`.
2. **Always** follow up with `aivis_list_project_ai_providers` to show the new linked set — the mutation itself doesn't return the resulting providers.
3. This is independent of the `aiProvidersSyncWithSubscription` flag; the sync mutation works regardless of mode. It's an MCP/API-only utility — the Lumar apps don't surface it (they rely on the automatic subscription sync).

## Step 3: Report

Show before/after for any mutation:

```
Project: <project name> (#<projectId>)
Sync mode: aiProvidersSyncWithSubscription = <true|false>

Before: <provider list, comma-separated>
After:  <provider list>
Change: +<added>  -<removed>
```

For a pure read, just the linked set with each provider's `type`, `name`, and (if cross-referenced with active providers) "active" / "idle".

## Important constraints

- **Subscription is the source of truth** when `aiProvidersSyncWithSubscription=true` (the default for self-serve accounts; enterprise accounts default to manual). Enable/disable still execute, but the next prompt/topic/run mutation re-runs the sync and may undo them. Don't promise the user a sticky toggle without checking sync mode first. Regardless of mode, providers the account loses entitlement to are removed automatically.
- **`included: false` catalog rows are hard-blocked.** No mutation works around it — the user must upgrade the addon.
- **No bulk mutation.** Enable/disable take one provider at a time. For "swap providers wholesale", loop the mutation per provider, then verify with `aivis_list_project_ai_providers`.
- **No "list all providers across all projects"** — `aivis_list_project_ai_providers` is per-project; `aivis_list_ai_providers` is the account-wide catalog.
