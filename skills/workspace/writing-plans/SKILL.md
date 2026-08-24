---
name: writing-plans
description: >
  Create detailed, bite-sized implementation plans from specs or requirements.
  Use when you have approved requirements, design docs, or specs and need to produce
  an execution-ready plan before touching code. Each plan step is a 2-5 minute action.
  Triggers on: "write a plan", "create implementation plan", "plan the implementation",
  "break this into tasks", "make a step-by-step plan", "implementation roadmap",
  "구현 계획 작성", "계획 세워줘", "태스크 분해", "단계별 계획", "실행 계획 만들어줘",
  "구현 플랜", "코딩 계획".
---

# Writing Plans

## Overview

Write comprehensive implementation plans assuming the engineer has zero context for our codebase and questionable taste. Document everything they need to know: which files to touch for each task, code, testing, docs they might need to check, how to test it. Give them the whole plan as bite-sized tasks. DRY. YAGNI. TDD. Frequent commits.

Assume they are a skilled developer, but know almost nothing about our toolset or problem domain. Assume they don't know good test design very well.

**Announce at start:** "I'm using the writing-plans skill to create the implementation plan."

**Context:** This should be run in a dedicated worktree (created by brainstorming skill).

**Save plans to:** `docs/plans/YYYY-MM-DD-<feature-name>.md`

## When to Use

Use this skill when:
- You already have approved requirements or a design doc
- The implementation will require multiple tasks or files
- You want an execution-ready plan before changing code

## Bite-Sized Task Granularity

**Each step is one action (2-5 minutes):**
- "Write the failing test" — step
- "Run it to make sure it fails" — step
- "Implement the minimal code to make the test pass" — step
- "Run the tests and make sure they pass" — step
- "Commit" — step

## Plan Document Header

**Every plan MUST start with this header:**

```markdown
# [Feature Name] Implementation Plan

> **For executor:** REQUIRED SUB-SKILL: Use `executing-plans` to implement this plan task-by-task.

**Goal:** [One sentence describing what this builds]

**Architecture:** [2-3 sentences about approach]

**Tech Stack:** [Key technologies/libraries]

**Estimated time:** [Total estimated time for all tasks]

---
```

## Task Structure

````markdown
### Task N: [Component Name]

**Files:**
- Create: `exact/path/to/file.py`
- Modify: `exact/path/to/existing.py:123-145`
- Test: `tests/exact/path/to/test.py`

**Step 1: Write the failing test**

```python
def test_specific_behavior():
    result = function(input)
    assert result == expected
```

**Step 2: Run test to verify it fails**

Run: `pytest tests/path/test.py::test_name -v`
Expected: FAIL with "function not defined"

**Step 3: Write minimal implementation**

```python
def function(input):
    return expected
```

**Step 4: Run test to verify it passes**

Run: `pytest tests/path/test.py::test_name -v`
Expected: PASS

**Step 5: Commit**

```bash
git add tests/path/test.py src/path/file.py
git commit -m "feat: add specific feature"
```
````

## Example Plan Snippet

```markdown
# User Authentication Implementation Plan

> **For executor:** REQUIRED SUB-SKILL: Use `executing-plans`

**Goal:** Add JWT-based authentication to the Express API
**Architecture:** Middleware-based auth with bcrypt password hashing and JWT tokens
**Tech Stack:** Express, jsonwebtoken, bcrypt, Prisma ORM
**Estimated time:** ~2 hours

---

### Task 1: User Model

**Files:**
- Create: `prisma/migrations/001_add_user/migration.sql`
- Modify: `prisma/schema.prisma:12-25`
- Test: `tests/models/user.test.ts`

**Step 1:** Write test for User model creation...
```

## Remember

- Exact file paths always
- Complete code in plan (not "add validation")
- Exact commands with expected output
- Reference relevant skills with @ syntax
- DRY, YAGNI, TDD, frequent commits

## Execution Handoff

After saving the plan, offer execution choice:

**"Plan complete and saved to `docs/plans/<filename>.md`. Two execution options:**

**1. In-Session Execution (this session)** — I execute tasks here step-by-step with review checkpoints

**2. Parallel Session (separate)** — Open new session with executing-plans, batch execution with checkpoints

**Which approach?"**

## Related Workflow Skills

- **brainstorming** — Use BEFORE this skill to explore requirements and design
- **planning-with-files** — Persistent file-based context management for session recovery
- **executing-plans** — Batch execution framework with checkpoints

**Recommended Workflow:** `brainstorming` → `writing-plans` → `planning-with-files` (persistence) → `executing-plans` (execution)
