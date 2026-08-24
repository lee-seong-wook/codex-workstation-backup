---
name: goal-setter
description: Draft, critique, strengthen, and save a persistent Goal/Task spec as a reviewable markdown file. Use when the user explicitly asks for `/goal`, `goal-setter`, "make this a goal", "turn this into a persistent task", "draft a goal", "목표로 저장", "장기 목표", or wants a durable completion contract for long-running work. Do not trigger for ordinary debugging, research, documentation, or implementation unless the user asks to create or manage a persistent goal.
---

# Goal Setter (dual-runtime: Codex + Claude)

## Overview

Help the user turn uncertain multi-step work into a strong **Goal/Task spec**. A Goal here is a runtime-scoped completion contract: define the outcome, verify it with evidence, preserve constraints, and continue only until the evidence says the work is complete or honestly blocked.

This skill is designed to be **runtime-agnostic**. The same `goals/<goal-name>.md` file can be activated either way:

- **Codex runtime** — activate with `/goal @goals/<goal-name>.md`
- **Claude runtime** — open a new conversation and paste/reference the file (e.g., "@goals/<goal-name>.md 를 끝까지 진행해줘"), or call `TaskCreate` from the spec, or use plan mode with the file as the plan source

Default to **interviewing before drafting or saving** a Goal. Small mismatches can waste substantial time and tokens, so align on intent before encoding the objective.

A saved Goal file is **not active state**. It is a reviewable activation artifact; the Goal becomes active only after the user invokes it in whichever runtime they choose.

## Decision Rules

Recommend a Goal when the task has:

- a durable objective that may take several turns,
- an evidence-based finish line such as tests, benchmarks, logs, source material, or a final artifact,
- an uncertain path where the next step depends on what the agent learns.

Prefer a normal prompt (or a single TaskCreate) for one-line edits, simple explanations, short code reviews, and questions where the user wants one answer and then a stop.

Reject vague finish lines. Do not save goals like "improve this", "make it better", or "refactor the code" unless the expected end state, verification surface, and constraints are clear.

## Intent Alignment Interview

Interview first unless the user already supplied all completion-critical details. Keep questions concise, but be thorough enough to prevent distorted work.

Before drafting, establish:

- **Desired outcome** — What should be true when the Goal is complete?
- **Non-goals** — What should the agent avoid doing, even if it seems useful?
- **Evidence** — Which tests, benchmarks, logs, artifacts, sources, or review checks prove success?
- **Constraints** — Which behavior, APIs, performance, style, data, files, or compatibility must not regress?
- **Scope** — Which repositories, directories, files, tools, networks, credentials, or data sources are allowed?
- **Autonomy** — Should the agent keep iterating aggressively, make only low-risk changes, or stop before edits?
- **Budget** — What time, token, iteration, command, or cost limit should stop work?
- **Blockers** — When should the agent stop and ask instead of continuing?
- **Reporting** — What progress format or final artifact does the user expect?
- **Runtime preference** — Will this Goal be activated mainly under Codex (`/goal @...`), Claude (conversation/TaskCreate), or both? Default: both.

Ask the highest-risk missing questions first. Prefer 2–5 targeted questions over a long questionnaire. Continue the interview if the answers reveal new ambiguity.

After interviewing, restate the interpreted contract in plain language and ask for confirmation before writing or updating the Goal file. Include assumptions in the file.

## Goal File Workflow

Use file-based Goals as the default handoff for both runtimes.

1. Identify the project root. Prefer the Git root when available; otherwise use the current working directory or ask if multiple roots are plausible.
2. Create `goals/` under the project root if needed.
3. Derive `{goal-name}` from the intended outcome using lowercase kebab-case.
4. Write the Goal spec to `goals/{goal-name}.md`.
5. Include **both activation paths** in the file and the final response:
   - Codex: `/goal @goals/{goal-name}.md`
   - Claude: open a new conversation and say `@goals/{goal-name}.md 를 끝까지 진행해줘` (or English equivalent), or feed it into TaskCreate.
6. State that the file itself does not activate the Goal; it only becomes active after the user invokes it.
7. If the file already exists, update it intentionally rather than creating a duplicate, unless the new request is clearly a different Goal.

The markdown file should preserve the prompt contract, not just the final activation sentence. Include:

- title and short slug,
- activation commands (Codex + Claude),
- final Goal text,
- interview summary,
- assumptions,
- non-goals,
- verification evidence,
- constraints and boundaries,
- iteration policy,
- blocked stop condition,
- budget or stopping limits,
- expected final report format.

## Drafting Workflow

1. Interview for intent alignment and missing completion-critical details.
2. Restate the user's intent, non-goals, success evidence, constraints, and stop conditions.
3. Identify the desired end state.
4. Name the verification surface: command, test, benchmark, artifact, report, log, or source material.
5. Add constraints that must stay true while working.
6. Add boundaries around files, tools, data, repositories, or resources if scope matters.
7. Add an iteration policy for choosing the next action after each attempt.
8. Add a blocked stop condition describing when to stop and what to report.
9. Write or update the markdown Goal file with **both** activation lines.
10. Report the file path and both activation commands.

Use this contract pattern (the prose body of the Goal):

```text
<desired end state>, verified by <specific evidence>, while preserving <constraints>. Use <allowed inputs, tools, or boundaries>. Between iterations, <how to choose and record the next best action>. If blocked or no valid paths remain, stop with <attempted paths, evidence, blocker, and next input needed>.
```

Ask follow-ups when a missing detail could make the Goal unverifiable, unsafe, too broad, too costly, or likely to optimize for the wrong outcome. Otherwise, make conservative assumptions and state them briefly.

## Goal Lifecycle

If the user asks to **draft, improve, set, or prepare** a Goal, write or update the markdown Goal file.

Do **not** activate the Goal directly as part of this skill. Leave activation as an explicit user action:
- Codex: `/goal @goals/<goal-name>.md`
- Claude: load the file in a new conversation, or call TaskCreate from it.

Unless the user gives a separate instruction after reviewing the file, do not auto-activate.

If the user asks to view, pause, resume, clear, or otherwise manage an active Goal, defer to the runtime's own Goal/Task command surface. Do not invent lifecycle state.

Mark a Goal complete only when the objective has been checked against concrete evidence. Budget limits, plausible progress, or a good-looking artifact are not completion.

## Claude-Specific Notes

When this skill runs under Claude, prefer these adaptations:

- Use `TaskCreate` to mirror the Goal as a top-level tracked task **only after** the user confirms activation. The Goal file remains the source of truth; tasks are the execution mirror.
- In Cowork mode, the Goal file is typically written under the selected workspace folder. If the user has no Git root, ask them to select a folder (or use `mcp__cowork__request_cowork_directory` if no folder is selected) before saving.
- Claude does not have a literal `/goal` command. The activation phrase is whatever the user types in a new conversation that references the Goal file, e.g. `@goals/<goal-name>.md 의 contract 를 끝까지 진행해줘. 증거가 충족되거나 blocked 조건이 되면 멈춰.`

## Codex-Specific Notes

When this skill runs under Codex:

- Save under the Git root by default; respect `${CODEX_HOME}` conventions.
- The literal `/goal @goals/<goal-name>.md` invocation is what makes the Goal active. Do not run it for the user automatically.

## Completion Audit

Before calling a Goal strong enough, check:

- **Outcome** — What should be true at the end?
- **Evidence** — What proves it?
- **Constraints** — What must not regress?
- **Boundaries** — What scope is allowed?
- **Iteration** — What should the agent do after each attempt?
- **Blocked state** — What should the agent report if the work cannot be completed under current limits?
- **Intent fidelity** — Did the user confirm the interpretation, including non-goals and stop conditions?

If the Goal is for research, require the final artifact to separate confirmed findings, approximate or proxy support, blocked claims, and remaining uncertainty.

## References

Read `references/goal-patterns.md` when you need examples, interview prompts, the markdown Goal file template, weak-to-strong rewrites, or domain-specific templates for performance, flaky tests, documentation, migrations, and research audits.
