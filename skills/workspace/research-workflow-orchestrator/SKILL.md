---
name: research-workflow-orchestrator
description: Coordinate multi-stage or mixed-artifact research work across topic framing, literature review, study design, results analysis, manuscript drafting, and submission prep. Use this skill when the user wants end-to-end research help, wants to resume from papers, drafts, logs, or results from different stages, or needs the next research stage chosen and handed off to the right local skills. Do not use it for isolated requests already fully covered by one local research skill.
---

# Research Workflow Orchestrator

## Overview

This skill preserves the best part of the imported harnesses: stage-aware orchestration. It does not replace the stronger local research skills already in this workspace. Instead, it decides where the user is in the research lifecycle, creates a stable workspace contract, and routes each stage to the smallest set of existing local skills.

## When To Use

Use this skill when the request spans two or more of these phases:
- topic framing or gap finding,
- literature review or related-work synthesis,
- study or experiment design,
- strict results analysis,
- manuscript drafting or revision,
- submission readiness.

Typical triggers:
- "Help me go from literature review to paper draft"
- "I have papers, experiment results, and a rough draft - what next?"
- "I have PDFs, logs, and a rough methods section - what stage should I do next?"
- "Coordinate the whole research workflow"
- "Resume this research project from these files"
- "Turn this topic into a study plan, analysis plan, and manuscript path"

Do not use this skill when the user clearly wants only one stage:
- single literature review -> use the local `literature-review` skill
- strict experiment statistics -> use `results-analysis`
- manuscript prose only -> use `scientific-writing` or `research-paper-writer`
- rebuttal only -> use `rebuttal_strategist`

For positive and negative trigger examples, see `references/eval-cases.md`.

## Core Contract

1. Inventory the current research state before doing substantive work.
2. Create or update `_research_workspace/00_scope.md` with the problem, current artifacts, and immediate goal.
3. Create or update `_research_workspace/stage-status.md` with:
   - current stage,
   - completed artifacts,
   - blockers,
   - next recommended stage.
4. Route only to the minimum local skills needed for the current stage.
5. Prefer a single orchestrator path. Use subagents or parallel skills only when workstreams are independent and do not need shared evolving state.
6. Reuse existing artifacts instead of restarting the workflow.

Read `references/stage-routing.md` for the detailed routing map, `references/workspace-contract.md` for directory and deliverable conventions, and `references/eval-cases.md` for trigger-boundary checks.

## Success Criteria

This skill is behaving correctly when it:
- chooses the correct active stage from the artifacts actually present,
- stays out of the way when one stronger single-stage local skill is enough,
- preserves authoritative user artifacts instead of regenerating upstream work,
- leaves an explicit next step, blocker list, and continuation path in `_research_workspace/stage-status.md`.

## Stage Decision Tree

Start by checking what the user already has.

### Topic only or vague direction

Route to the local `research-ideation` skill first.

Use this path when the user has:
- a broad domain,
- a vague problem statement,
- no stable research question,
- no clear method choice.

### Papers, search terms, or related-work notes

Route to:
- `literature-review` for systematic review or verified literature work,
- `literature_reviewer` for related-work comparison or drafting.

### Study design, protocol, or benchmark plan needed

Route to:
- `research-ideation` for question and method shaping,
- `pyhealth` when the domain is healthcare or clinical ML.

### Experiment logs, metrics, CSVs, or evaluation outputs available

Route to:
- `results-analysis` for evidence-first statistics and figures,
- `results-report` after the analysis bundle is complete.

### Draft manuscript exists, or paper writing is the active phase

Route to:
- `scientific-writing` for paragraph-based manuscript drafting,
- `research-paper-writer` for conference-style paper scaffolding,
- `scientific-manuscript-review` or `lead_paper_architect` for high-stakes revision.

### Submission or final verification

Route to:
- `citation-verification`,
- `bibtex_manager`,
- `peer-review`,
- `sci_paper_validator`,
- `submission_manager`.

## Mixed-Artifact Arbitration

When the user provides artifacts from multiple stages, choose the earliest incomplete stage that blocks downstream work.

Use these precedence rules:
- raw logs, CSVs, or ablation outputs without a validated analysis bundle -> lock `analysis`
- validated analysis outputs exist, but the draft is incomplete or structurally weak -> lock `manuscript`
- manuscript is largely stable and the remaining work is citations, review simulation, or venue checklisting -> lock `submission`
- papers or notes exist, but research question or method is still unstable -> lock `framing` or `design`

Do not restart upstream stages unless missing evidence actually blocks the current stage.

## Orchestration Workflow

### 1. Inventory

Collect:
- research topic or target contribution,
- current files and artifact types,
- target venue or thesis type if relevant,
- whether data or experiment outputs already exist,
- immediate deliverable the user wants next.

Write the inventory to `_research_workspace/00_scope.md`.

### 2. Lock the Active Stage

Choose one active stage only:
- `framing`
- `literature`
- `design`
- `analysis`
- `manuscript`
- `submission`

If the user provides mid-stream artifacts, resume from the nearest valid stage instead of rerunning earlier stages.

### 3. Hand Off to Existing Skills

Invoke only the minimum stage-specific local skills needed to move the project forward. This skill is a router and continuity layer, not a replacement for deeper domain skills.

### 4. Preserve Continuity

After each stage:
- update `_research_workspace/stage-status.md`,
- record which files are authoritative,
- record what evidence is still missing,
- state the next recommended stage explicitly.

## Routing Examples

- "Help me go from literature review to a conference paper draft on EEG speech decoding." -> trigger this skill; likely start at `literature` or `manuscript` depending on whether the review already exists as a usable artifact.
- "Analyze these experiment CSVs and tell me if model A beats model B statistically." -> do not trigger this skill; use `results-analysis`.
- "I have 12 PDFs, a rough methods section, and ablation logs. What should I do next to finish the paper?" -> trigger this skill; likely lock `analysis` first because raw experimental evidence still blocks downstream manuscript work.
- "My paper is nearly done. Clean up the BibTeX and give me a submission checklist." -> usually keep work in `submission`; use this skill only when several end-stage tasks need coordinated routing.

## Quality Bar

Non-negotiable rules:
- Never fabricate citations, DOIs, datasets, statistics, or experimental results.
- If evidence is missing, label the output as planning, draft, or unverified.
- Keep evidence artifacts separate from prose artifacts.
- Prefer resuming from user-provided files over recreating them.
- Avoid over-delegation. If the current task is sequential, tightly coupled, or already fits one local skill cleanly, work directly instead of spawning extra coordination layers.
- If a stage needs real data or verified references and they are absent, stop at the planning boundary and state the blocker.

## Notes On Harness Adaptation

The imported value from the harness repo is:
- explicit stage routing,
- structured handoff between roles,
- resumable workflow modes,
- stable output locations.

Do not import the harness repo as-is. This workspace already has stronger stage-specific research skills. Preserve only the orchestration pattern.
