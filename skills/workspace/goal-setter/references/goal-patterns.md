# Goal Patterns (dual-runtime: Codex + Claude)

## Core Summary

Use Goals for persistent objectives where the finish line is clear but the path is uncertain. The important shift is:

- Prompt: ask → work → result → wait
- Goal: work → check → continue or complete

A strong Goal names the end state, proof, constraints, scope, iteration policy, and blocked stop condition. Evidence decides completion.

This skill targets two runtimes, but the spec format is the same:

- **Codex** activation: `/goal @goals/<goal-name>.md`
- **Claude** activation: open a new conversation and reference the file (e.g. `@goals/<goal-name>.md 를 끝까지 진행해줘`), or call `TaskCreate` from the contract block.

## Intent Interview Prompts

Use these prompts selectively. Ask the questions whose answers would most affect the Goal contract.

### Core alignment

```text
Goal로 만들기 전에 contract를 먼저 맞춰두고 싶어요. 잘못된 방향을 최적화하지 않게요:
1. 끝났다고 판정할 정확한 end state는 무엇인가요?
2. 에이전트가 절대 건드리지 말아야 할 것은 무엇인가요?
3. 성공을 판정할 evidence는 무엇인가요?
```

### Verification

```text
어떤 구체적인 체크를 authoritative로 삼을까요? 로컬 테스트, CI, 벤치마크 임계값, 생성된 artifact, 수동 검토, source citation, 그 외 무엇?
```

### Scope

```text
허용되는 scope는 무엇인가요? 특정 파일/모듈만, 레포 전체, 외부 리서치, 네트워크 접근, 의존성 변경, 마이그레이션, 생성 artifact 등.
```

### Autonomy and risk

```text
얼마나 autonomous하게 진행할까요? 그럴듯한 fix를 계속 시도, 저위험 변경만, 편집 전 멈춤, 비싸거나 destructive한 단계 전에 ask 등.
```

### Budget

```text
어떤 limit으로 멈출까요? 시간, 토큰 예산, iteration 횟수, 명령/런타임 비용, 혹은 "defensible path가 없으면 멈춤".
```

### Blocked condition

```text
Evidence를 얻을 수 없거나 target이 도달 불가능해 보이면, 에이전트가 무엇을 report해야 하고 무엇이 unlock에 필요할까요?
```

### Runtime preference

```text
이 Goal을 주로 Codex(`/goal @...`)에서 돌릴 건가요, Claude(대화로 로드 / TaskCreate)에서 돌릴 건가요, 아니면 둘 다? 기본값은 둘 다입니다.
```

### Confirmation before activation

```text
제가 이해한 Goal:
- Outcome: <outcome>
- Evidence: <evidence>
- Constraints: <constraints>
- Scope: <scope>
- Blocked/budget: <stop condition>
- Non-goals: <non-goals>
이 contract로 goals/<goal-name>.md 에 저장해도 될까요?
```

## Markdown Goal File Template

Save Goal specs at `project-root/goals/{goal-name}.md`. Use the project Git root when available; otherwise use the current working directory or ask the user which root should own the Goal.

A Goal file is **not** active Goal state. It is a reviewable activation artifact; the Goal becomes active in the chosen runtime only when the user invokes it.

Use this structure:

```markdown
# Goal: <Human-readable title>

Slug: `<goal-name>`
Status: Draft

## Activation

This file is not an active Goal. It becomes active runtime-scoped state only after one of the activations below is run.

- **Codex**: `/goal @goals/<goal-name>.md`
- **Claude**: open a new conversation and say
  `@goals/<goal-name>.md 의 contract 를 끝까지 진행해줘. 증거가 충족되거나 blocked 조건이 되면 멈춰.`
  Optionally, also `TaskCreate` a top-level task that mirrors the Goal Text below.

## Goal Text

<A single strong Goal statement. Do not include the literal "/goal" prefix here unless the user wants it.>

## Interview Summary

- Desired outcome: <what done means>
- Non-goals: <what the agent should avoid>
- Evidence: <tests, benchmarks, artifacts, logs, sources, or review checks>
- Constraints: <things that must not regress>
- Scope: <allowed repos, files, tools, data, network, credentials>
- Autonomy: <how aggressively the agent may iterate>
- Budget: <time, token, iteration, command, or cost limits>
- Blocked condition: <when to stop and ask>
- Reporting: <expected progress/final format>
- Runtime preference: <codex | claude | both>

## Assumptions

- <assumption made because the user did not specify it>

## Verification Checklist

- [ ] <evidence check>
- [ ] <constraint check>

## Notes

<Optional context, links, or prompt history.>
```

When reporting back, say something like:

```text
Saved the Goal spec to goals/<goal-name>.md. Review it, then activate it in whichever runtime you prefer:
- Codex: /goal @goals/<goal-name>.md
- Claude: 새 대화에서 `@goals/<goal-name>.md 를 끝까지 진행해줘` 라고 입력 (또는 TaskCreate로 미러)
```

## Weak to Strong

### Weak

```text
Improve performance
```

### Strong

```text
Reduce p95 checkout latency below 120 ms, verified by the checkout benchmark, while keeping the correctness suite green. Use only the checkout service, benchmark fixtures, and related tests. Between iterations, record what changed, what the benchmark showed, and the next best experiment to try. If the benchmark cannot run or no valid paths remain, stop with the attempted paths, evidence gathered, blocker, and next input needed.
```

### Weak

```text
Write docs for this feature
```

### Strong

```text
Produce a docs page for this feature that explains the lifecycle, command surface, and two realistic examples, verified by the local docs build and by checking that referenced commands match current CLI behavior. Preserve existing docs style and avoid changing unrelated pages. If the build or command verification is blocked, stop with the failing command, evidence, and the next input needed.
```

### Weak

```text
Reproduce this paper
```

### Strong

```text
Produce the strongest evidence-backed reproduction of the paper using available materials and local resources. Build a claim inventory, attempt the headline results where feasible, verify outputs where possible, and end with a report separating confirmed findings, approximate reconstructions, blocked exact replay, and remaining uncertainty. If source data, seeds, checkpoints, or methods are unavailable, label those claims as blocked instead of overstating success.
```

## Templates

### Performance tuning

```text
Reduce <metric> below <threshold>, verified by <benchmark command or report>, while keeping <correctness tests or behavior constraints> green. Use <service/modules/fixtures> only. Between iterations, compare measurements before and after the change and choose the next smallest defensible experiment. If measurement cannot run or no valid paths remain, stop with attempted changes, evidence, blocker, and next input needed.
```

### Flaky test investigation

```text
Make <test name or suite> pass reliably on the current branch, verified by <repeat command/count or CI check>, while preserving public API behavior and unrelated tests. First reproduce the failure, then isolate cause before changing code. Between iterations, record reproduction evidence, hypothesis, change, and result. If the failure cannot be reproduced or the cause cannot be isolated under current limits, stop with evidence, attempted paths, and what would unlock progress.
```

### Migration

```text
Complete <migration target>, verified by <build/test/lint/runtime checks>, while preserving <public behavior, data compatibility, or API contract>. Limit changes to <scope>. Between iterations, fix the next highest-confidence incompatibility shown by evidence. If a dependency, API gap, or manual decision blocks completion, stop with the blocker, affected files, evidence, and decision needed.
```

### Research audit

```text
Produce an evidence-backed audit of <research question/source>, verified by a final report with claim-by-claim evidence. Use <allowed sources/resources>. Separate confirmed claims, proxy support, contradictions, blocked claims, and remaining uncertainty. Between iterations, map each claim to the strongest available evidence before adding conclusions. If source material is unavailable or evidence is insufficient, label the claim blocked or uncertain and explain what evidence would resolve it.
```

### Generated artifact

```text
Produce <artifact>, verified by <render/build/check command and manual/visual inspection criteria>, while preserving <style, compatibility, or content constraints>. Use <templates/assets/source material>. Between iterations, inspect the artifact, fix the highest-impact defect, and rerun verification. If the artifact cannot be generated or verified, stop with logs, partial output path, blocker, and next input needed.
```

### ML/CV experiment (Claude-friendly extra)

```text
Train/evaluate <model/method> on <dataset/task> to reach <metric ≥ threshold> on <split>, verified by <evaluation script + seed protocol + log path>, while preserving <baseline reproducibility, compute budget, license constraints>. Use <allowed code paths, configs, checkpoints> only. Between iterations, log each run's diff (config, seed, metric, wall-clock) and choose the next change with the highest expected info gain per compute unit. If compute, data, or a required ckpt is unavailable, stop with the gap, partial results, and next input needed.
```

## Completion Language

When reporting progress under a Goal, keep status evidence-based:

- **Complete** — objective was verified against the named evidence.
- **Improved but incomplete** — evidence moved in the right direction but missed the target or violated a constraint.
- **Blocked** — a required command, artifact, source, credential, data set, or decision is unavailable.
- **Budget-limited** — work stopped due to budget; this is **not** completion.

For research, preserve levels of support:

```text
Claim: <claim>
Route: <how it was tested or reconstructed>
Evidence surface: <files, commands, figures, outputs, sources>
Status: <confirmed | approximate support | contradicted | blocked | uncertain>
Remaining uncertainty: <what is still unknown>
```
