---
name: analyze-report-adjustment
description: Inspect, create, update or reset a project's report scoring direction and weight with report template overrides. Use when asked to adjust report impact or priority, exclude a report from scoring, or restore its default scoring.
---

# Analyze report adjustment

Requires `analyze:read`, `analyze:write`, and Editor or Admin access on the
project’s account. Service accounts must belong to that account. Overrides affect future crawls;
existing crawl results keep their settings snapshot.

## Read, change, verify

1. Resolve the project with `analyze_list_projects` and the standard report
   code with `analyze_list_reports`. Use the report's exact code, not a custom
   report template code.
2. Call `analyze_list_report_template_overrides(projectId, reportTemplateCode)`.
   Follow `pagination.next_cursor` until `has_next_page` is false to inspect
   every matching override. The key is project ID + report code + aggregate
   code. A null aggregate code targets the report total; a non-null code
   targets one aggregate. Preserve that distinction in every write.
3. Apply the requested change:
   - **Create** with `analyze_create_report_template_override` only when the
     matching key is absent. Supply both `totalSign` and `totalWeight`.
   - **Update** with `analyze_update_report_template_override` when it exists.
     Send only the scoring values being changed; at least one is required.
   - **Reset** with `analyze_delete_report_template_override`. This restores
     template defaults for that key. The response contains the removed
     values, not the defaults.
4. Verify the returned scoring values for create/update. After deletion,
   list again and confirm the matching key is absent. Report the project,
   report, aggregate (if any), and the change. Start a crawl only if the
   user's request includes refreshing crawl results.

## Scoring and scope

`totalSign`: `-1` = negative impact (more issues is worse), `0` = neutral,
`1` = positive impact (more is better).

`totalWeight` is a fraction from `0` to `1`, not a percentage. Zero removes
scoring impact; it does not delete the report or its rows.

Report-total changes also create/update/delete any linked health-score parent
override. Aggregate overrides affect only the selected aggregate. Use known
aggregate codes from existing settings; the API validates codes on creation.

Creation is limited by the account's maximum overrides per project. If the
limit is reached, inspect existing overrides and ask which adjustment the
user wants to replace; do not delete an unrelated override to make room.

Numeric report thresholds (such as title length or thin-page limits) are
separate crawl settings. For those, read `analyze_get_project_settings` with
`sections: ["thresholds"]`; editing requires `analyze:admin` and the
`analyze-project-settings` skill's read → patch → verify workflow.
