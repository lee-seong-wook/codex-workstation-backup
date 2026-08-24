# Description Optimization

Use this reference when improving a skill frontmatter `description`.

## Goal

The description is the main trigger surface. It should let Codex decide when to load the full `SKILL.md` without reading the body first.

## Checklist

- Front-load the core use case in the first sentence.
- Include the most common user phrases, file extensions, and domain synonyms.
- Include Korean trigger variants when this workspace uses Korean prompts.
- State boundaries when neighboring skills overlap.
- Avoid "any task" language unless the skill truly owns that broad scope.
- Prefer explicit edit/improvement intent for skills that modify files.

## Trigger Test

Before changing a description, write:

- 10 prompts that should trigger the skill.
- 5 prompts that should not trigger it.
- 3 overlapping prompts where another skill might be better.

The revised description passes if it catches the true positives, avoids the negatives, and explains overlaps clearly enough for routing.

## Good Pattern

```yaml
description: Audit, research, verify, and upgrade local Codex skills. Use when the user explicitly asks to improve, update, organize, validate, or audit skill files, skill routing, skill drift, trigger quality, or the workspace skill set. For read-only audits, report findings first; apply edits only when the user asks to upgrade or fix.
```

