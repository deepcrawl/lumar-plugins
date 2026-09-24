---
name: analyze-project-settings
description: How to inspect and edit a project's crawl settings over MCP — which wizard section a setting belongs to, the read → patch → verify loop, which fields replace a whole list instead of merging, which fields must be sent in pairs, and how to apply the same change to every project on an account. Use when asked to change any crawl setting (scope, link restrictions, limits, rendering, user agent, robots, test site, extractions, report thresholds), list or manage sitemaps and manual URL file uploads, audit what a project is configured to do, or roll a settings change out across an account.
---

# Analyze project crawl settings

`analyze_update_project` covers the whole settings surface the Analyze
"Edit crawl settings" wizard writes. Field names match graph-api's
`UpdateProjectInput` exactly, and every field is optional — anything omitted is
left untouched. Changes apply to the **next crawl**, not the current one.

Requires the Editor role on the project's account, and the `analyze:admin`
toolset. Step 1 below additionally needs `analyze:read`.

## Always read before you write

1. `analyze_get_project_settings(projectId)` — returns `settings` (keys spelled
   exactly as `analyze_update_project` arguments), `readOnly`, and `truncated`.
2. Change only the fields you mean to change.
3. `analyze_update_project(projectId, <just those fields>)` — the response
   echoes the full post-write state, so you can verify in the same call.

Send only what you are changing. Do NOT spread the whole `settings` block into
the update: while a crawl is running graph-api rejects any setting outside a small
allowlist — `maximumCrawlRate`, `maximumCrawlRateAdvanced`, `limitLevelsMax`,
`limitPagesMax`, `autoFinalizeOnCrawlLimits`, `compareToCrawl` and the three
`failureRate*` fields — and submitting a field counts as changing it even when
the value matches what is stored. Resending everything therefore fails mid-crawl
with `validation/crawl_running` (its `data.disallowedSettings` names the
offenders) for a change the server would otherwise have allowed.

Settings with no value are **omitted** from `settings` rather than returned as
null, so an absent key means "not set". Every key that is present is valid input
for `analyze_update_project` — but see the allowlist above before sending more
than the fields you actually changed.

Never pass `readOnly` values back: they have no counterpart on the mutation and
the whole call fails. That block holds `hasTestSitePassword`,
`effectiveLimitPagesMax`, `maxLinksProcessed`, `sitemapUrls`, the resolved
`userAgent` object, and the four toggles Lumar manages itself
(`crawlOtherRelInternal`, `crawlOtherRelExternal`, `crawlSitemapsInternal`,
`crawlSitemapsExternal`).

Pass `sections` to narrow a read, e.g. `sections: ["scope-links"]`. Lists over 20
entries and strings over 2000 chars are summarised unless you pass
`verbose: true`; whatever was trimmed is named in `truncated`.

Anything trimmed is **dropped from `settings`** and summarised under
`truncated` instead, so `settings` always stays valid input — a summary is not,
and writing a sample back would delete the rest of the list.

To edit a trimmed list you need it in full first: re-read with `verbose: true`,
narrowing to the owning section so the payload stays inside the response limit
(e.g. `sections: ["sources"], verbose: true` for `startUrls`). A handful of
projects carry lists so large — thousands of `startUrls` or `secondaryDomains` —
that even a single-section verbose read exceeds it and comes back as
`response/too_large`. Those lists can only be edited in the Lumar app; say so
rather than writing a truncated list back, which would delete the rest.

## Sections

Every field description is prefixed with its wizard section, so you can locate a
setting without guessing:

| Section                 | What lives there                                                                        |
| ----------------------- | --------------------------------------------------------------------------------------- |
| `basic`                 | name, primaryDomain, industryCode, WCAG level/version, best practices                   |
| `sources`               | crawlTypes, dataOnlyCrawlTypes, startUrls, sitemap discovery                            |
| `limits`                | crawl rate (incl. advanced windows), level/page limits, auto-finalize, crawler location |
| `scope-domain`          | includeSubdomains, includeHttpAndHttps, secondaryDomains                                |
| `scope-urls`            | include/exclude URL patterns, urlSampling                                               |
| `scope-resources`       | non-HTML, CSS, JS, images, invalid SSL                                                  |
| `scope-links`           | which internal link types to follow, incl. links and hreflang found on 4xx pages        |
| `scope-redirects`       | internal / external redirect following                                                  |
| `scope-link-validation` | external link + rel validation, first-level disallowed/excluded                         |
| `spider-js`             | renderer on/off, timeout, blocking, injected JS, flattening, cookies                    |
| `spider-user-agent`     | userAgentCode, custom string/token, viewport                                            |
| `spider-mobile`         | mobile site settings and mobile user agent/viewport                                     |
| `spider-robots`         | robots overwrite, X-Robots, renderer robots mode                                        |
| `spider-headers`        | customRequestHeaders, rendererCookies                                                   |
| `spider-safeguard`      | failure-rate limit, threshold, lookback window                                          |
| `spider-stealth`        | useStealthMode                                                                          |
| `extraction`            | customExtractions                                                                       |
| `test-settings`         | test site domain/auth, custom DNS, URL rewriting                                        |
| `report-setup`          | API callback, crawl email alerts, compareToCrawl, excluded datasources                  |
| `thresholds`            | title/description/HTML/link/thin-page/etc. report thresholds                            |

## Lists replace, they do not merge

Sending a list-valued field **overwrites the stored array**. To add one entry,
read the current list and send it back with the new entry appended. Affected:
`crawlTypes`, `dataOnlyCrawlTypes`, `startUrls`, `secondaryDomains`,
`includeUrlPatterns`, `excludeUrlPatterns`, `urlSampling`,
`customExtractions`, `customRequestHeaders`, `rendererCookies`,
`rendererBlockCustom`, `rendererJsUrls`, `customDns`, `urlRewriteRules`,
`urlRewriteQueryParameters`, `maximumCrawlRateAdvanced`, `apiCallbackHeaders`,
`alertEmails`, `excludedDatasources`. Passing `[]` clears the list.

Two of these bite harder than the rest:

- `customExtractions` — dropping an entry also deletes the project Tests derived
  from its `reportTemplateCode`.
- `crawlTypes` — dropping `GoogleSearchConsole` / `GoogleAnalytics` /
  `Backlinks` unwires integrations configured by
  `analyze_configure_gsc_integration` / `analyze_set_ga4_integration`.

## Fields that come in pairs

Each of these is rejected with `validation/missing_dependent_param` unless both
halves end up set (either in this call, or already stored on the project):

- `useRobotsOverwrite: true` needs `robotsOverwrite`
- `crawlTestSite: true` needs `testSiteDomain`
- `useMobileSettings: true` needs `mobileHomepageUrl` AND `mobileUrlPattern` to
  end up set. Nothing rejects enabling it without them — the crawl just silently
  skips the mobile site, so check the values before or with the toggle.

Clearing works the other way round: `testSiteDomain: null`,
`robotsOverwrite: null`, `mobileHomepageUrl: null` and `mobileUrlPattern: null`
need their toggle turned off in the same call (`crawlTestSite: false`,
`useRobotsOverwrite: false`, `useMobileSettings: false`), otherwise the mode stays
on with nothing to act on and the next crawl quietly uses the primary site or the
live robots.txt. Passing `false` when it is already off is harmless.

- `userAgentString` needs `userAgentToken`
- `userAgentStringMobile` needs `userAgentTokenMobile`

### Switching to a preset user agent

A stored custom user-agent pair **overrides `userAgentCode`** in the crawler, so
setting `userAgentCode` alone on a project that has one changes nothing about
what the crawl actually sends. Clear the pair in the same call:

```
analyze_update_project(projectId, userAgentCode: "googlebot-smartphone",
                       userAgentString: null, userAgentToken: null)
```

Both halves must go to null together — one alone is rejected. The same applies to
`userAgentStringMobile` / `userAgentTokenMobile` versus `mobileUserAgentCode`.
Check `readOnly.userAgent` after writing to confirm which agent resolved.

## Ceilings the account controls

`maximumCrawlRate`, `limitLevelsMax`, `limitPagesMax` and `renderTimeout` are
capped per account. These come back as `validation/crawl_rate_exceeded` or
`validation/limit_exceeded` with the real ceiling in the error's `data`. For the
page limit, `readOnly.effectiveLimitPagesMax` tells you the value and why
(linked custom-metric containers can lower it) before you write.

## Credential-bearing settings are never read back

`customRequestHeaders`, `rendererCookies`, `apiCallbackHeaders`,
`apiCallbackUrl`, `rendererJsString` and `rendererJsUrls` routinely hold
basic/bearer auth,
staging session cookies, a secret in the URL itself (incoming-webhook
endpoints), or a token injected into the page by script. A read reports only
their key/name plus `valueSet: true`, under `readOnly` — never the values, not
even the host of a URL, and never inside `settings`, so a round-trip patch cannot
echo a redacted value back over the real one.

Crawl targets are deliberately NOT redacted — `primaryDomain`,
`secondaryDomains`, `startUrls`, `mobileHomepageUrl` and `sitemapUrls` are what
the project crawls, and hiding them would make the read useless. If a project has
userinfo in a crawl URL — the `user:password@` part some URLs carry before the
host — that field is withheld from `settings` and reported sanitised instead.
Anything else a crawl URL carries, a signed query parameter for example, is
returned as-is: it cannot be told apart from an ordinary one, and stripping query
strings would break managing real crawl seeds. Such a token is no more hidden here
than in the Analyze app, so treat it as visible to anyone who can read the
project. Tell the user to move those to test-site authentication or a custom request
header instead, both of which are redacted.

The consequence: you cannot append to one of these lists from a read alone,
because writing the list back would blank the entries whose values you never
saw. Ask the user for the full set (or send only the complete list you were
given). Same rule as `testSitePassword`.

## Web Bot Auth signatures do not belong in customRequestHeaders

A `Signature` / `Signature-Input` / `Signature-Agent` header trio — the Web Bot
Auth credential a platform such as Shopify issues so its edge admits Lumar's
crawler instead of blocking it — has a dedicated home:
`analyze_create_web_bot_auth_signature`, keyed per (account, domain).

Setting it through `customRequestHeaders` still works and is still validated
against the signer's key directory on save and at crawl start, so a bad trio is
rejected either way. But that path is per-project rather than per-account, is
invisible to the emails that warn account admins before a signature expires, and
its values cannot be read back to check what is set. If a user asks to add these
headers to a project, point them at the signature store instead.

Two consequences if a project already has one in `customRequestHeaders`:
changing `primaryDomain` re-validates the trio against the new host and will
reject an otherwise untouched header set, and any `customRequestHeaders` write
re-validates it too — so an unrelated header edit can fail on an expired
signature you did not touch.

## Unsetting a value

Scalar settings that graph-api stores as nullable accept `null` to clear them —
`testSiteDomain`, `mobileHomepageUrl`, `industryCode`, `robotsOverwrite`, most
report thresholds, the viewport overrides, and so on. Two exceptions reject null
despite a nullable column, because their upstream validators do not skip it:
`renderingRobotsCheckMode` and `thinPageThreshold` — write the value you want
instead. List settings clear with
`[]`. Settings with a fixed server default (crawl rate, level/page limits, the
boolean toggles) have nothing to clear — write the value you want.

## Two traps worth naming

- `urlSampling[].samplePercentage` is a **fraction, not a percent**: `1` = 100%,
  `0.1` = 10%. (`failureRateThreshold`, confusingly, IS a percent, 0-100.)
- `testSitePassword` is write-only. It never comes back from a read, and sending
  an empty string silently drops test-site auth, so the next crawl fails to
  authenticate.

## Applying one change to a whole account

There is no bulk settings mutation — do it project by project:

1. `analyze_list_projects(accountId)` — page through with `pagination.next_cursor`.
2. For each project, `analyze_update_project(projectId, <the fields>)`. Send only
   the fields you are changing so nothing else is disturbed.
3. Spot-check a few with `analyze_get_project_settings`.

Tell the user up front that this is one call per project and that the change
takes effect on each project's next crawl. If instead they want a NEW project
that matches an existing one, `analyze_clone_project` copies every setting in
one call — cheaper than replaying a patch.

## Sitemaps

Sitemap URLs have dedicated tools; `sitemapUrls` is read-only in the project
settings response. Use `analyze:read` to list and `analyze:admin` to manage them.

1. `analyze_list_sitemaps(projectId)` — page through `pagination.next_cursor`
   to find the target URL and its `urlDigest`. Results include disabled entries.
2. Apply the requested change:
   - `analyze_add_custom_sitemaps(projectId, sitemapUrls)` adds 1–50 HTTP(S)
     URLs while preserving existing entries. Adding an existing disabled URL
     leaves it disabled.
   - `analyze_enable_sitemap(projectId, urlDigest)` or
     `analyze_disable_sitemap(projectId, urlDigest)` toggles that sitemap and
     any child sitemaps.
   - `analyze_delete_sitemap(projectId, urlDigest)` removes the configured URL
     and clears its disabled state. A URL still advertised in robots.txt may
     immediately return: `deleted: false` means it remains configured. Use
     disable when the user wants to exclude it from crawling.
3. Re-list from the first page to verify the result. Mutation responses are
   summaries; `requestedCount` counts submitted URLs, including duplicates.

For a sitemap-based crawl, also read `analyze_get_project_settings` with
`sections: ["sources"]` and add `Sitemap` to `crawlTypes` using
`analyze_update_project`, preserving all other enabled sources. Managing URLs
does not switch this source on. Run `analyze_run_crawl` only when requested.

Mutations require Editor access and fail while a crawl is running. Listing
can include URLs from robots.txt when discovery is enabled, but does not save
them to project settings.
The list describes project configuration, and `status` describes URL validity;
neither proves that a sitemap was fetched successfully during a crawl.
URL credentials are removed from results; use the returned digest unchanged.

## Not available here

Report scoring direction and weight use separate report template overrides.
Read them with `analyze_list_report_template_overrides`; when `analyze:write`
is available, use the `analyze-report-adjustment` skill to create, update or
reset them. Numeric report thresholds remain in the `thresholds` section above.

Module changes (`moduleCode` is fixed at creation) and `renderIdleDuration` are
admin-only in graph-api and deliberately absent. Source _integration_ config —
Google Search Console, GA4, Majestic, Adobe, log files — lives on
separate entities: see the `analyze:external` / `analyze:admin` Google tools.
Schedules are `analyze_create_schedule` / `analyze_update_schedule`, not project
settings.

## Manual URL file uploads

These tools configure URL lists, backlinks and log-summary CSV files. Reads use
`analyze:read`; mutations use `analyze:admin`, require Editor access and fail
while the project's crawl is running.

1. Resolve the project, then call `analyze_list_url_file_uploads(projectId)`.
   Follow `pagination.next_cursor` until the relevant file is found. Preserve
   the returned opaque upload `id` exactly for reads, updates and deletion.
2. For a new file, call `analyze_get_url_file_upload_types` and choose a format
   matching the actual file. Inspect `uploadTemplate` for CSV headers and
   `requiredContainerNames` for any required custom metrics. `ListTxt` is one
   URL per line without a header; log formats require summary CSVs, not raw
   server logs. Custom column templates are not writable through these tools.
3. Ensure the client can send an HTTP PUT before creating a record. Call
   `analyze_create_signed_url_file_upload` with the project, basename and
   selected `projectUploadType`. The tool derives the crawl source. Filenames
   accept letters, digits, underscores, hyphens and dots; use `.txt` or `.csv`
   for lists and `.csv` for backlinks/log summaries. Set `uploadBaseDomain`
   when the file contains relative URLs.
4. Send the raw file bytes with HTTP PUT to `upload.url` within 15 minutes.
   Use the signed URL unchanged, without multipart encoding or the Lumar
   authorization header. Treat the URL as a temporary credential. The create
   call alone leaves a Draft record; it does not upload bytes. If the client
   cannot transfer files, ask the user to complete the upload in Analyze. Each
   create call makes a new record; inspect existing records before retrying an
   uncertain create, and remove abandoned drafts when authorized.
5. Poll `analyze_get_url_file_upload(urlFileUploadId)` until `Processed`.
   `Draft` awaits transfer, `Processing` is pending, and `Errored` requires
   inspecting `errorMessage`. Report the status and row count; only describe
   an upload as ready once processing has succeeded.
6. For changes, call `analyze_update_url_file_upload` with only requested
   fields: `enabled` toggles reuse, `uploadBaseDomain: null` clears the base,
   and `projectUploadType` changes the built-in format within the same crawl
   source. Replacement contents require a new upload: wait for it to process
   before disabling or deleting the old file. `analyze_delete_url_file_upload`
   removes a file; disable it instead when the user wants to retain it.
7. Read project settings with `sections: ["sources"]`. Add the file's
   `List`, `Backlinks` or `LogSummary` source to `crawlTypes` when requested,
   preserving other sources. A file's enabled flag does not enable its project
   source. Re-read both file and project settings to verify. Run a crawl only
   when requested and after the upload is Processed.
