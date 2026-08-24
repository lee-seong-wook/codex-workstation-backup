# goal-setter (dual-runtime)

Originally based on [computerphilosopher/agent-skills `goal-setter`](https://github.com/computerphilosopher/agent-skills/tree/main/skills/goal-setter), adapted so the **same Goal spec** can be activated under either runtime:

- **Codex**: `/goal @goals/<goal-name>.md`
- **Claude** (Claude Code or Cowork): open a new conversation and reference the file, e.g.
  `@goals/<goal-name>.md 의 contract 를 끝까지 진행해줘.`
  Optionally `TaskCreate` a top-level task that mirrors the Goal Text section.

The skill never activates a Goal for you. It writes a reviewable contract file at
`<project-root>/goals/<goal-name>.md` and reports both activation commands.

## Files

```
goal-setter/
├── SKILL.md                       # main skill body (read by the agent)
├── README.md                      # this file
├── agents/
│   ├── openai.yaml                # Codex interface metadata
│   └── claude.yaml                # Claude interface metadata + activation notes
└── references/
    └── goal-patterns.md           # interview prompts, file template, weak→strong, domain templates
```

## When to trigger

Use this skill whenever the user wants to turn an uncertain multi-step task into a persistent, evidence-backed contract — debugging, benchmarks, flaky tests, migrations, reproductions, doc builds, research audits, ML/CV experiments — and especially when they say:

- "이걸 goal로 만들어줘" / "골 만들어" / "goal-setter로"
- "/goal", "make this a goal", "draft a goal", "turn this into a persistent task"
- "이 작업을 지속적으로 진행할 수 있게 정리해줘"

## Trigger this skill even if the user did not literally say "goal"

If the task is multi-step, has an uncertain path, and would benefit from a persistent objective with evidence-based completion, recommend goal-setter instead of just answering inline.
