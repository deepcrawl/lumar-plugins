---
name: analyze-topic-configuration
description: Manage content relevance topic configurations on Lumar Analyze projects. Use when listing topics, creating or editing descriptions and keywords, changing similarity thresholds, enabling or disabling topics, or deleting topic configurations used by crawls.
---

# Analyze Topic Configuration

These configurations define the topics used to score crawl content relevance. For AI Visibility topics and their prompts, use the topic-bootstrap skill.

## Resolve the target

1. Use `lumar_get_me` to find the account and `analyze_list_projects` to resolve a named Analyze project. System admins can find the account with `lumar_search_accounts`.
2. Call `analyze_list_topic_configurations` with `projectId`. Follow `pagination.next_cursor` until all topics are read, including disabled ones.
3. For an update or deletion, match the requested topic and use its returned `id` as `topicConfigurationId`. Ask if the project or topic match is ambiguous. For a list request, return the configurations and stop.

## Apply the requested change

- **Create:** `analyze_create_topic_configuration` needs `projectId`, a unique `name`, `description`, and `keywords`. Topics default to enabled. The project limit of 30 includes disabled topics.
- **Update:** `analyze_update_topic_configuration` accepts only the changed fields. Preserve existing user edits. A supplied `keywords` array replaces the full list; merge retained keywords before sending an add/remove request.
- **Threshold:** `minSimilarityThreshold` accepts 0–1. On update, omission preserves the existing override and `null` clears it.
- **Pause/resume:** update `enabled` to `false`/`true`. Pausing keeps the topic available for later reuse.
- **Delete:** use `analyze_delete_topic_configuration` once the user has authorized deletion of the identified topic. Deletion frees a configuration slot; pausing does not.

Names allow 1–200 characters, descriptions 1–2000, and keywords 1–20 entries of 1–100 characters each. Draft any AI-suggested description or keywords for user review before saving. Use supplied or approved content directly.

## Verify and report

Read the configurations again and verify each requested change. Report the topic name, ID, and changed settings. Enabled topics are snapshotted when a crawl starts: changes affect future crawls, while finished crawls retain their original topics and metrics. Start a new crawl only when requested.
