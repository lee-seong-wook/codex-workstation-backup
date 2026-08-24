---
name: repo-orientation
description: Quickly orient in an unfamiliar or stale repository before nontrivial coding, debugging, review, or planning. Use when Codex needs local facts about repository structure, stack, commands, conventions, active git state, or likely task touchpoints before acting. Do not use for trivial one-command tasks or when the repository is already understood.
---

# Repo Orientation

Produce a short factual map of the repository so the next action is grounded in local evidence. Do not edit files, design features, debug root causes, or validate completion while using this skill.

## Workflow

1. Read local instructions first.
   - Check the nearest `AGENTS.md` that applies to the current working directory.
   - Read root `README*`.
   - Read `CONTRIBUTING*`, top-level `docs/`, or equivalent files only when they clearly affect the requested work.

2. Inspect the current worktree.
   - Run `pwd`.
   - Run `git status --short --branch` when inside a Git repository.
   - Run `git diff --stat` only if there are local changes.
   - Run `git log -5 --oneline` only when recent direction matters.

3. Map structure cheaply.
   - Use `rg --files` first.
   - Identify app, library, source, test, config, script, docs, CI, and example areas.
   - Avoid generated, vendor, dependency, cache, build, and artifact directories unless the user specifically asks about them.

4. Identify stack and commands from evidence.
   - Inspect manifests such as `package.json`, `pyproject.toml`, `requirements*.txt`, `Cargo.toml`, `go.mod`, `Makefile`, `Dockerfile`, CI workflows, and similar files.
   - Extract likely install, run, lint, test, and build commands only when backed by repository files.
   - Do not install dependencies, start servers, run migrations, or run long test suites during orientation.

5. Locate task-relevant touchpoints.
   - If the user named a feature, route, error, file type, module, or command, search for those terms.
   - Read only the smallest relevant files needed to understand ownership and boundaries.
   - For monorepos, distinguish apps, packages, shared tooling, and local package-level commands.

6. Stop when oriented.
   - Summarize facts, not guesses.
   - Name unknowns and confidence where evidence is thin.
   - Recommend the next skill or action only when it is clearly useful.

## Output

Use `references/output-template.md` for the final structure. Keep the orientation concise: usually under 40 lines unless the repository is large or the user requested a deeper map.

The output should help a future agent decide what to open or run next. Prefer a short path table over a raw directory dump.

## Boundaries

- Do not edit files.
- Do not produce an implementation plan; use `writing-plans` for that.
- Do not brainstorm feature design; use `brainstorming` for that.
- Do not perform root-cause debugging; use `systematic-debugging` for that.
- Do not evaluate broad architecture quality or propose refactors; use `improve-codebase-architecture` for that.
- Do not claim completion or validation; use `verification-before-completion` for that.
- Do not create checkpoints or handoffs.
- Do not call external review CLIs unless local repository instructions explicitly require them for orientation.

