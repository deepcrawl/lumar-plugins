---
name: analyze-schedule-history
description: Investigate whether an Analyze crawl schedule ran and why a scheduled crawl was skipped or failed to start. Use for schedule history, missed scheduled crawls, and checking automated crawling.
---

# Analyze Schedule History

Resolve the project with `analyze_list_projects` using its name or domain, then call `analyze_list_schedule_logs` with the project's `id` as `projectId`. The tool needs `analyze:read` and returns the current schedule plus project logs newest first. Use `pagination.next_cursor` as `cursor` while older pages are available; `limit` defaults to 20 and is capped at 100. Logs have a six-month retention window: daily cleanup removes older entries, so pagination cannot recover expired history. For older periods, report that schedule-log evidence is unavailable rather than concluding there were no failures.

## Interpret the evidence

- Each log's `createdAt`, `errorCode`, and `errorMessage` describes a failed or skipped scheduled crawl start, such as depleted credits or a crawl already running. It is not a crawl completion record.
- Successful starts are not written to this log. An empty page does not establish success or prove that no attempt occurred.
- A new schedule initializes `schedule.latestRunTime` to the same future first-run time as `nextRunTime`, before any attempt. Later it advances for handled failures as well as successful starts. Compare both timestamps with the current time, logs, and crawl history before describing a past occurrence; the field alone does not prove that a crawl was attempted, started, or finished.
- Logs belong to the project. A null `schedule` means there is no current schedule; past logs may still exist after deletion or a one-time schedule has been consumed.

To check actual crawl outcomes, call `analyze_list_crawls` for the project and inspect crawls around the expected time. Use `analyze_get_crawl_summary` for a relevant crawl. Time proximity alone does not prove a crawl was started by the schedule.

Report the expected time, observed log timestamp and reason, any matching crawl's status, and the returned project or crawl `coreUIUrl`. Distinguish a recorded failure from an outcome the available evidence cannot establish. Checking history does not require creating or changing a schedule or starting another crawl.
