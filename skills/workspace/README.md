# Local Skills

This is the canonical repo-local skill root.

Use this path when another IDE, CLI agent, or human needs to discover the workspace-local skill set:
- `{{WORKSPACE_ROOT}}\skills`

Compatibility entry points:
- `.agents/skills` -> junction to this directory
- `.cursor/skills` -> junction to this directory
- `.claude/skills` -> junction to this directory

Rule:
- Add or edit local skills here first.
- Keep integration and utility skills in `{{CODEX_HOME}}\skills` unless a repo-specific override is needed.
