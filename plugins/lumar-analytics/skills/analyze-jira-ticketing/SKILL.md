---
name: analyze-jira-ticketing
description: Generate ticket details for Lumar Analyze remediation tasks and link them to existing or new Jira issues. Use this skill whenever someone asks to "create a Jira ticket", "link this task to Jira", "push this task to Jira", "generate ticket details", "find the Jira issue for this task", or remove a task's Jira link.
---

# Analyze Jira Ticketing

Bridge Lumar Analyze tasks to Jira. This skill uses the first-party Analyze task tools plus the `analyze:external` Jira toolset, which reads and writes the user's connected Jira tenant.

## Parameters

- **task**: Task ID, title, or task from the current conversation.
- **jira_authentication**: Jira connection/site if multiple exist.
- **jira_issue**: Existing Jira issue key/ID to link, or search text.
- **create_new**: Whether to create a new Jira issue.
- **project_or_issue_type**: Jira project and issue type for new issues.
- **use_ai_ticket_details**: Whether to generate/use AI ticket copy.

## Step 0: Resolve task

1. If the task ID is known, call `analyze_get_task`.
2. Otherwise call `analyze_list_tasks` with `query` or the current project/account scope and ask if multiple tasks match.

When the user asks for ticket copy, call `analyze_generate_task_ticket_details` with the task ID and optional `crawlId`. It is async; poll `analyze_get_task` for `ticketGenerationFinishedAt` and `ticketDetails` only when the user wants to wait.

## Step 1: Resolve Jira authentication

Call `analyze_list_jira_authentications`. If several working connections exist, ask which Jira site to use. If `isWorking: false`, tell the user to re-authenticate Jira in the Lumar dashboard before linking.

## Step 2: Link existing issue or create a new one

**Existing issue**

1. Use `analyze_search_jira_issues` when the user gave search text or a partial key.
2. Call `analyze_create_task_external_link` with `taskId`, `jiraAuthenticationId`, and `jiraIssueIdOrKey`.

**New issue**

1. Call `analyze_list_jira_projects`.
2. Call `analyze_list_jira_issue_types` for the chosen Jira project.
3. Call `analyze_get_jira_create_field_metadata` when required custom fields, priority, components, labels, or non-default description fields are involved.
4. Call `analyze_create_task_external_link` with `jiraProjectId`, `jiraIssueTypeId`, optional `jiraIssueSummary`, optional `additionalFields`, and `useAiTicketDetails: true` only when generated details exist or the user asked to use them.

Confirm before creating a new Jira issue or deleting an external link.

## Step 3: Remove a link

Use `analyze_get_task` to find `externalLinks[].id`, then confirm and call `analyze_delete_task_external_link`. This removes only the Lumar ↔ Jira link; it does not delete the Jira issue.

## Deliverable

Include:

1. Analyze task ID/title.
2. Jira site and issue key/link when available.
3. Whether a new issue was created or an existing issue was linked.
4. Any generated ticket detail status.

## Common pitfalls

- **External scope** — Jira tools require the `analyze:external` toolset. If unavailable, explain that Jira access was not granted.
- **Two create modes** — pass either `jiraIssueIdOrKey` for existing issues, or both `jiraProjectId` and `jiraIssueTypeId` for new issues. Do not mix them.
- **Required fields** — use `analyze_get_jira_create_field_metadata` before guessing Jira custom field IDs.
- **AI ticket details are async** — generate and poll before passing `useAiTicketDetails: true`.
