---
name: analyze-custom-report-management
description: Create, update, or delete saved Analyze custom reports. Use when a user wants to save a filtered report for the team, change its columns or filter, or remove a custom report.
---

# Analyze custom report management

## Prepare the definition

1. Resolve the project with `analyze_list_projects`. Use `analyze_list_custom_report_templates` to find existing reports before creating a duplicate.
2. For an existing report, read `analyze_get_custom_report_template` with the project's numeric ID and the report's opaque `code`. Retain its numeric template ID for update/delete and its `basedOnReportTemplateCode` for metadata lookup.
3. Discover standard metric codes and predicates with `analyze_get_report_metadata` on the base report and a finished crawl. Discover custom metrics with `analyze_list_project_custom_metrics`; match their datasource to the base report.
4. Preview the proposed name, filter, columns, and sort. When a suitable crawl exists, preview matching rows with `analyze_list_report_rows` against the base report. Save only when the user asks to persist the view. Preserve existing user edits by sending only the settings being changed.

## Save or update

- Create with `analyze_create_custom_report_template`: pass `projectId`, `name`, a standard `reportTemplateCode` (defaults to `all_pages`), and either `filterRules` or `filter`. A non-empty filter is required. The base report cannot be changed after creation.
- Update with `analyze_update_custom_report_template` and the numeric `customReportTemplateId`. Omitted settings are preserved. Filters, column groups, and sort replace their entire saved values; start from the current definition when modifying one part.
- `filterRules` accepts up to 20 `{metricCode, predicate, value}` rules joined by `filterOperator` (`and` by default). For mixed AND/OR/NOT logic, keep the raw `filter` intact instead of flattening it. Raw filters and shorthand rules are mutually exclusive.
- `metricsGroupings` takes `[{metrics: ["url", "httpStatusCode"]}]`; convert the read tool's string-array groups to these objects. Custom columns use `customMetrics.<code>`. Pass `null` to restore the base report's columns.
- `sort` takes `{metricCode, direction}` and replaces the full saved sort. Pass `null` to restore the base report's sort. For a report with multiple saved sort keys, omit this field to preserve them unless the user intends to replace them.
- `description` and `defaultView` (`Table` or `Grid`) accept `null` to clear. The filter cannot be cleared.
- Templates with `source: container` belong to an extension and cannot be updated or deleted here. To customize one, create a project report using its base code, saved filter, and column groups.

After saving, report the returned numeric ID and code. Verify the definition with `analyze_get_custom_report_template`; use the numeric ID for `analyze_list_custom_report_rows`. A custom code cannot be passed to standard report tools. Row availability depends on report generation, so an empty or unavailable row response is not a reason to repeat a successful create.

## Delete

Read the report first and confirm its identity and the removal of its associated Monitor alert rules with the user. Then call `analyze_delete_custom_report_template` using the numeric ID. There is no restore tool. Task-linked templates are protected by the API; report that rejection instead of deleting the task or changing the extension.
