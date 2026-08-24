---
name: executing-plans
description: >
  Execute a written implementation plan with batch processing and review checkpoints.
  Use when you have an existing plan from writing-plans or brainstorming and need to
  implement it systematically in batches. Triggers on: "execute the plan", "implement
  the plan", "run the plan", "start implementation", "begin coding",
  "계획 실행", "구현 시작", "플랜 실행해줘", "실행해줘".
---

# Executing Plans

## Overview

Load plan, review critically, execute tasks in batches, report for review between batches.

**Core principle:** Batch execution with checkpoints for review.

**Announce at start:** "I'm using the executing-plans skill to implement this plan."

## When to Use

- A written implementation plan already exists (from `writing-plans` or `brainstorming`)
- You are executing in a separate or clean session
- You need checkpoint-based progress reporting between task batches

## The Process

### Step 1: Load and Review Plan

1. Read plan file
2. Review critically — identify any questions or concerns
3. If concerns: Raise them with your human partner before starting
4. If no concerns: Create task checklist and proceed

### Step 2: Execute Batch

**Default batch size: 3 tasks** (adjust based on complexity)

| Task Complexity | Batch Size | Rationale |
|-----------------|-----------|-----------|
| Simple (config, rename) | 5 tasks | Low risk, fast verification |
| Medium (new function, test) | 3 tasks | Default — good balance |
| Complex (architecture, API) | 1-2 tasks | High risk, careful review needed |

For each task:
1. Mark as in_progress
2. Follow each step exactly (plan has bite-sized steps)
3. Run verifications as specified
4. Mark as completed

### Step 3: Report

When batch complete:
- Show what was implemented
- Show verification output (test results, build status)
- Say: "Ready for feedback."

### Step 4: Continue

Based on feedback:
- Apply changes if needed
- Execute next batch
- Repeat until complete

### Step 5: Complete Development

After all tasks complete and verified:
- Announce: "I'm using the verification-before-completion skill before claiming completion."
- **REQUIRED SUB-SKILL:** Use `verification-before-completion`
- Run full verification commands from the plan, then report status with evidence

## Error Recovery

### When a Test Fails Mid-Batch

1. **STOP** the current batch
2. Read the error message completely
3. Check: Is this a test bug or a code bug?
4. If test bug → fix test, re-run, continue batch
5. If code bug → use `systematic-debugging` skill
6. Report the issue and recovery action in the checkpoint

### When a Step is Unclear

1. **DO NOT GUESS** — stop and ask
2. Quote the unclear instruction
3. Suggest what you think it means
4. Wait for clarification before proceeding

### When Dependencies Are Missing

1. Note the missing dependency
2. Check if it's in a later task (dependency ordering issue)
3. If yes: reorder tasks and note the change
4. If no: stop and report the blocker

## When to Stop and Ask for Help

**STOP executing immediately when:**
- Hit a blocker mid-batch (missing dependency, repeated test failure)
- Plan has critical gaps preventing progress
- You don't understand an instruction
- Verification fails repeatedly (3+ times)

**Ask for clarification rather than guessing.**

## Example Checkpoint Report

```markdown
## Batch 1/4 Complete ✓

### Implemented
- [x] Task 1: Created `src/utils/parser.py` with `parse_config()`
- [x] Task 2: Added unit tests in `tests/test_parser.py`
- [x] Task 3: Integrated parser into `main.py`

### Verification
$ pytest tests/test_parser.py -v
3 passed in 0.12s ✓

### Issues
- None

### Next Batch
- Task 4: Add error handling
- Task 5: Add CLI argument support
- Task 6: Update README

Ready for feedback.
```

## Remember

- Review plan critically first
- Follow plan steps exactly
- Don't skip verifications
- Reference skills when plan says to
- Between batches: just report and wait
- Stop when blocked, don't guess
- Never start implementation on main/master branch without explicit user consent

## Integration

**Required workflow skills:**
- **writing-plans** — Creates the plan this skill executes
- **verification-before-completion** — Validate results before completion claims
- **systematic-debugging** — Use when plan execution hits test failures or unexpected behavior
