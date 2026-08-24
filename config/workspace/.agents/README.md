# Local Skills Maintenance

This area contains project-local skill assets used by the current workspace.

## Validate Skills

Run the validator to check:
- frontmatter completeness (`name`, `description`)
- missing local file references in backticks
- deprecated `superpowers:*` references

```powershell
powershell -ExecutionPolicy Bypass -File .agents/scripts/validate-skills.ps1 -Root skills
```

Write a Markdown report:

```powershell
powershell -ExecutionPolicy Bypass -File .agents/scripts/validate-skills.ps1 `
  -Root skills `
  -ReportPath .agents/skill-maintenance/validation-report.md
```

Fail on issue (useful for CI):

```powershell
powershell -ExecutionPolicy Bypass -File .agents/scripts/validate-skills.ps1 -Root skills -FailOnIssue
```
