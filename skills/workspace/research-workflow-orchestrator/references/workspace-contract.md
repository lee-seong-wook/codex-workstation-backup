# Workspace Contract

The orchestration skill should create a stable project-level workspace only when the user is asking for multi-stage coordination.

## Directory Layout

```text
_research_workspace/
  00_scope.md
  stage-status.md
  01_literature/
  02_design/
  03_analysis/
  04_manuscript/
  05_submission/
```

Create only the directories that are actually needed. Do not create empty stages just for symmetry.

## Required Files

### `00_scope.md`

Must contain:
- research objective,
- current artifact inventory,
- active stage,
- target deliverable,
- key constraints,
- current blockers.

Suggested template:

```markdown
# Scope

- research_objective:
- active_stage:
- target_deliverable:
- key_constraints:
- current_blockers:

## authoritative_artifacts
- [path]: [why this file is authoritative]

## unverified_artifacts
- [path]: [what still needs validation]
```

### `stage-status.md`

Update after every major stage with:
- current stage,
- completed artifacts,
- unverified artifacts,
- missing evidence,
- next recommended stage,
- exact files to continue from next time.

Suggested template:

```markdown
# Stage Status

- current_stage:
- authoritative_inputs:
- completed_artifacts:
- unverified_artifacts:
- missing_evidence:
- blockers:
- next_recommended_stage:
- next_entry_files:
```

## Stage Output Conventions

### `01_literature/`

Typical contents:
- literature review,
- search protocol,
- bibliography,
- notes on gaps and themes.

### `02_design/`

Typical contents:
- research questions,
- hypotheses,
- dataset or cohort choice,
- benchmark plan,
- analysis plan,
- methods outline.

### `03_analysis/`

Typical contents:
- analysis bundle from `results-analysis`,
- figures,
- stats appendix,
- result interpretation notes.

### `04_manuscript/`

Typical contents:
- outline,
- section drafts,
- figure and table placement plan,
- unresolved citation placeholders.

### `05_submission/`

Typical contents:
- citation cleanup notes,
- venue checklist,
- review findings,
- anonymization or submission checklist.

## Resume Rules

- Prefer continuing from existing files over regenerating upstream stages.
- If the user provides authoritative files outside `_research_workspace/`, record them in `00_scope.md` and continue from them.
- Mark raw logs, unverified citations, and draft prose explicitly as unverified until the relevant stage has checked them.
- If a stage is incomplete because evidence is missing, record the blocker and stop at the planning boundary.
