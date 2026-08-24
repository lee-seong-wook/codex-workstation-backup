---
name: find-skills
description: Find, compare, and recommend installed local/global Codex skills and plugin-provided skills. Use when the user asks "is there a skill for X", "find skill", "recommend skills", "스킬 찾아줘", "이런 스킬 있어?", "추천 스킬", or wants to inspect skill routing without modifying skills.
---

# Find Skills

## Workflow

1. Search local skills first: `{{WORKSPACE_ROOT}}/skills/*/SKILL.md`.
2. Search global skills next: `{{CODEX_HOME}}/skills/*/SKILL.md`.
3. Include plugin/system skills from the current Codex skill list when relevant.
4. Compare by `name`, `description`, trigger phrases, and whether the body actually supports the request.
5. Return exact skill names and paths. Say when a requested skill is absent.

For upgrading or editing skills, hand off to `autoresearch`. For installing curated skills, use `skill-installer`.
