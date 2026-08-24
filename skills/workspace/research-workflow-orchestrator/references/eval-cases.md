# Evaluation Cases

Use these cases to verify trigger quality and stage selection before broadening this skill further.

## Should Trigger

### Case 1: Literature to manuscript

Prompt:
`Help me go from literature review to a conference paper draft on EEG speech decoding.`

Expected:
- the skill triggers,
- it starts at `literature`, `design`, or `manuscript` depending on actual artifacts,
- it does not invoke every downstream stage at once.

### Case 2: Mixed artifacts with unclear next step

Prompt:
`I have 12 PDFs, ablation logs, and a rough methods section. What should I do next to finish the paper?`

Expected:
- the skill triggers,
- it locks the earliest incomplete blocking stage,
- it records authoritative and unverified files separately.

### Case 3: End-to-end workflow

Prompt:
`Coordinate the whole research workflow for this topic, from gap finding through submission readiness.`

Expected:
- the skill triggers,
- it starts at `framing` unless stronger artifacts already exist,
- it creates `_research_workspace/00_scope.md` and `_research_workspace/stage-status.md`.

## Should Not Trigger

### Case 4: Literature-only request

Prompt:
`Do a systematic literature review on brain foundation models.`

Expected:
- prefer `literature-review`,
- the orchestrator stays out unless the user also wants downstream routing.

### Case 5: Stats-only request

Prompt:
`Analyze these experiment CSVs and tell me if model A beats model B statistically.`

Expected:
- prefer `results-analysis`,
- the orchestrator stays out unless the user also asks what stage comes next.

### Case 6: Submission-only request

Prompt:
`My paper is nearly done. Clean up the BibTeX and give me a submission checklist.`

Expected:
- prefer `bibtex_manager` plus `submission_manager`,
- the orchestrator triggers only if broader end-stage coordination is requested.
