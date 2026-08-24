---
name: autoresearch
description: Audit, research, verify, and upgrade local Codex skills. Use when the user explicitly asks to improve, update, evolve, organize, validate, or audit skill files, skill routing, skill drift, trigger quality, or the workspace skill set. Triggers include "upgrade this skill", "make this skill better", "research improvements for X skill", "manage skills", "verify skill drift", "self-improve skills", "스킬 관리", "스킬 점검", "스킬 업그레이드", "스킬 검증", and "스킬 드리프트". For read-only audits, report findings first; apply edits only when the user asks to upgrade or fix.
---

# Autoresearch: Self-Improving Skill Loop

A skill that automatically researches and upgrades other skills using an iterative experiment loop inspired by Karpathy's autoresearch paradigm: **analyze → research → propose → implement → evaluate → repeat**.

---

## The Core Loop

```
┌─────────────────────────────────────────┐
│           OUTER LOOP                    │
│  Audit all skills → Prioritize targets  │
│                                         │
│   ┌─────────────────────────────────┐   │
│   │        INNER LOOP               │   │
│   │  Research → Improve → Evaluate  │   │
│   │  Keep if better, revert if not  │   │
│   └─────────────────────────────────┘   │
└─────────────────────────────────────────┘
```

The outer loop finds *which* skills need improvement. The inner loop finds *how* to improve each one.

---

## Phase 1: Outer Loop — Skill Audit

### Step 1.1: Discover All Available Skills

Check the skills directories in this order:
```
Current workspace skills: `{{WORKSPACE_ROOT}}/skills/*/SKILL.md`
User/global skills: `$CODEX_HOME/skills/*/SKILL.md` or `{{CODEX_HOME}}/skills/*/SKILL.md`
Plugin/system skills: use the skills list provided by Codex; read only the relevant `SKILL.md`.
```

Read each `SKILL.md` frontmatter + first 50 lines. Build a quick mental inventory:
- Name + description
- Last apparent update (look for version notes, dates, or tool references)
- Complexity (lines of content)

### Step 1.2: Score Each Skill on 5 Dimensions

Rate each skill 1–5 on:

| Dimension | What to assess |
|-----------|---------------|
| **Freshness** | Are tools/APIs/frameworks referenced still current? Any deprecated patterns? |
| **Coverage** | Does it cover edge cases? Missing workflows? Incomplete sections? |
| **Trigger Quality** | Is the description specific enough to fire reliably? Would Claude skip it? |
| **Structure** | Progressive disclosure? Clear sections? Under 500 lines? |
| **Examples** | Concrete examples of inputs/outputs? Before/after comparisons? |

Sum scores → prioritize lowest-scoring skills for inner loop.

### Step 1.3: Confirm with User

Present the audit results clearly:

```
Skill Audit Results:
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
 Skill          Fresh  Cover  Trigger  Score
─────────────────────────────────────────────
 docx            3/5    4/5    3/5     10/15  ← needs work
 pptx            4/5    3/5    4/5     11/15
 skill-creator   5/5    5/5    5/5     15/15  ✓ good
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
```

Ask: "Which skill(s) should we focus on first?" — or proceed with the lowest scorer if user says "just do it."

---

## Phase 2: Inner Loop — Research & Improve

Run this loop for each target skill. **Do not skip the research step** — even if you think you know the answer, search first.

### Step 2.1: Baseline Reading

Read the full target `SKILL.md`. Note:
- What it claims to do
- What tools/libraries it references and their versions
- Any explicit gaps or TODOs
- The current description (frontmatter)

### Step 2.2: Research Phase

**This is the core of autoresearch.** Run web searches to find what's changed.

**Search strategy — use all 4 angles:**

1. **Currency check**: `"[tool/framework name] 2025 2026 new features"`
   - What changed in the last year?
   - Any breaking changes or deprecations?

2. **Best practices**: `"[skill domain] best practices guide [current year]"`
   - What do experts recommend now?
   - What patterns have emerged?

3. **Common failures**: `"[skill domain] mistakes avoid common errors"`
   - What do people get wrong that the skill should warn about?
   - Edge cases not currently covered?

4. **Competitive analysis**: `"[skill domain] tutorial advanced techniques"`
   - What are other guides covering that this skill misses?
   - Any new workflows or tools the skill should incorporate?

**For each search hit:** Use `web_fetch` on the top 2–3 results to get full content (not just snippets).

### Step 2.3: Gap Analysis

Compare research findings vs. current skill content. Produce a gap list:

```
Gap Analysis for [skill-name]:
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
OUTDATED:
  - References python-docx 0.x API → now uses 1.x (breaking changes)
  - Recommends deprecated method X → use Y instead

MISSING:
  - No coverage of [new feature Z] released in 2025
  - No error handling examples for [common failure mode]
  - No example for [frequent user request pattern]

TRIGGER ISSUES:
  - Description too narrow → misses "[synonym phrase]" queries
  - No mention of "[adjacent use case]" that should also trigger this

STRUCTURAL:
  - Section on X is 200+ lines → should be split into reference file
  - No progressive disclosure → model loads everything upfront
```

### Step 2.4: Propose Improvements

For each gap, write the specific change you'll make. Show the user **before/after** for significant changes:

```diff
- description: Create Word documents when user asks for .docx files.
+ description: Create, edit, read, and manipulate Word documents (.docx). 
+   Use whenever user mentions Word doc, report, letter, memo, template, 
+   letterhead, tracked changes, or any .docx output. Also triggers for 
+   converting content into formatted professional documents.
```

Ask the user: "Here are my proposed changes. Approve all, select specific ones, or modify?"

### Step 2.5: Implement

Before editing, confirm the target is writable and prefer editing the canonical local skill directly when it lives under `{{WORKSPACE_ROOT}}/skills`. For read-only or plugin/system skills, copy the skill to a writable local location first:

```bash
cp -r /path/to/read-only-skill/ /tmp/[skill-name]-improved/
```

Apply approved changes to `/tmp/[skill-name]-improved/SKILL.md`.

For large additions, create reference files rather than bloating the main SKILL.md:
```
/tmp/[skill-name]-improved/
├── SKILL.md          ← keep under 500 lines
└── references/
    └── [new-topic].md  ← detailed content goes here
```

### Step 2.6: Evaluate

Test the improved skill by running 3–5 representative prompts through it yourself (Claude.ai mode: you execute the skill, not a subagent):

**Test types to run:**
1. **Happy path**: Standard use case the skill was designed for
2. **Trigger boundary**: A query that should trigger the skill but might not
3. **Edge case**: An unusual input the skill should handle
4. **New coverage**: A query that specifically exercises the newly added content

For each test, assess:
- Did the skill produce noticeably better output?
- Was anything broken by the changes?
- Did the trigger description correctly identify when to apply the skill?

### Step 2.7: Keep or Revert

**Keep the changes if:**
- At least 4/5 tests show improvement or no regression
- The trigger description is more precise without being narrower
- The SKILL.md is still under 500 lines (or properly structured with references)

**Revert and try again if:**
- Changes broke existing functionality
- New content added confusion without adding value
- Trigger description became so broad it would fire incorrectly

If reverting, go back to Step 2.3 with updated understanding.

---

## Phase 3: Iterate Until Satisfied

Repeat the inner loop (Phase 2) until:
- Quality score improves by ≥ 2 points (on the 15-point scale)
- OR the user says "this looks good"
- OR you've run 3 iterations without meaningful improvement (plateau signal)

If plateaued, document what you tried and suggest the user consider a full skill rewrite vs. incremental improvement.

---

## Special Case: Description-Only Optimization

If the user only wants to improve the **triggering** (not the content), focus exclusively on the description field:

1. List 10 real user queries that should trigger this skill
2. List 5 queries that should NOT trigger it
3. Check: does the current description correctly separate them?
4. Rewrite description to maximize true positives, minimize false positives
5. Apply the "pushy" principle: descriptions should lean toward over-triggering rather than under-triggering

See `references/description-optimization.md` for detailed techniques.

---

## Special Case: Adding a New Skill (Rapid Mode)

If the user asks autoresearch to create a new skill from scratch:

1. **Research first**: 3+ web searches on the domain before writing a single line
2. **Find the best existing guide** in the domain and fetch its full content
3. **Draft SKILL.md** following the anatomy in skill-creator
4. **Run 3 test prompts** before presenting to user
5. **Iterate once** based on test results before final delivery

Do NOT write skills from memory alone — always research first.

---

## Output Formats

### When presenting the audit:
Use a table. Keep it scannable. Include score and top-priority action for each skill.

### When presenting proposed changes:
Use diff format (`+`/`-`) for description changes. Use prose paragraphs for structural changes. Use bullet lists for missing content additions.

### When delivering the improved skill:
- Show the changed SKILL.md in full (or key changed sections)
- Summarize: "What changed, why, and what we tested"
- Package with: `python -m scripts.package_skill /tmp/[skill-name]-improved/` if the scripts tool is available
- Use `present_files` if available to let user download

---

## Quality Principles

Carry these into every skill improvement:

**1. Principle of No Surprise** — The skill should do exactly what its description promises. If the description says "creates Word docs," it should not silently also create PDFs.

**2. Principle of Progressive Disclosure** — SKILL.md metadata triggers → SKILL.md body provides workflow → reference files provide depth. Don't load everything upfront.

**3. Principle of Pushy Descriptions** — Skill descriptions should lean toward over-triggering. Users hate when a skill fails to activate more than when it activates unnecessarily.

**4. Research Before Writing** — Every improvement should be grounded in fresh web research. Never rely on memory alone for technical details.

**5. Measure, Don't Guess** — Run test prompts before and after. If you can't tell whether the skill got better, you haven't improved it.

---

## Reference Files

- `references/description-optimization.md` — Deep guide on writing trigger descriptions
- `references/skill-quality-rubric.md` — Full scoring rubric with examples at each level

Read these when you need more detail on specific topics.
