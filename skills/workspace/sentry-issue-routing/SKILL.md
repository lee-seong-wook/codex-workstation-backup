---
name: sentry-issue-routing
description: Investigate Sentry production errors and issue links. Use when the user mentions Sentry, a production error in Sentry, issue id, event id, release regression, stack trace, affected users, "센트리 이슈", or "프로덕션 에러".
---

# Sentry Issue Routing

## Workflow

1. Use `tool_search` to check whether a Sentry connector/tool is available.
2. If connector access is unavailable, work from pasted issue details: stack trace, event id, release, environment, tags, breadcrumbs, request data, and affected user count.
3. Reproduce or localize the failing code path before patching.
4. Correlate with release/deploy changes when possible.
5. For code fixes, use `systematic-debugging`: create a focused regression test or reproduction, patch root cause, then verify.

Do not claim a production root cause from a Sentry title alone.
