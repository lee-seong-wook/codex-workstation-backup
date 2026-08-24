# Stage Routing

Use this reference when the user asks for multi-stage research help or wants to resume from mixed artifacts.

## Capability Coverage

The local workspace already covers most single-stage research work:

| Stage | Preferred local skill(s) | Notes |
| --- | --- | --- |
| Topic framing, gap analysis, early planning | `research-ideation` | Best first stop when the project is not yet stable. |
| Systematic literature review | `literature-review` | Stronger than the imported harness for verified review work. |
| Related-work comparison and synthesis | `literature_reviewer` | Use for narrative comparison and prior-work framing. |
| Strict results analysis | `results-analysis` | Use when real metrics, logs, or tables exist. |
| Experiment wrap-up report | `results-report` | Use only after `results-analysis`. |
| Manuscript drafting or section rewriting | `scientific-writing`, `research-paper-writer` | Choose based on target output style. |
| Manuscript review and strengthening | `scientific-manuscript-review`, `lead_paper_architect`, `peer-review`, `sci_paper_validator` | Use for high-stakes revision and review simulation. |
| Citation package and submission readiness | `citation-verification`, `bibtex_manager`, `submission_manager` | Use near the end of the workflow. |

## Imported Ideas Worth Preserving

Preserve these patterns from the harness repo:
- resume from the nearest valid stage instead of restarting everything,
- make the current stage explicit,
- define stable output paths,
- separate literature, analysis, and manuscript artifacts,
- maintain a final "next step" record after each stage.

Do not preserve these parts:
- duplicate agent-role prompts that overlap with stronger local skills,
- Claude-specific `.claude` assumptions,
- claims of execution for work that still requires real data, database access, or software runs.

## Stage Selection Rules

### Start at `framing`

Use when the user has:
- a domain or idea but no stable research question,
- unclear novelty,
- unclear method choice,
- no artifact set worth resuming from.

### Start at `literature`

Use when the user has:
- search terms,
- a paper list,
- PDFs,
- related-work notes,
- a request for systematic review or prior-work synthesis.

### Start at `design`

Use when the literature state is known enough and the next need is:
- hypotheses,
- dataset choice,
- benchmark design,
- ablation plan,
- methods outline.

### Start at `analysis`

Use when the user already has:
- CSV or TSV metric tables,
- repeated-run logs,
- training curves,
- evaluation JSON,
- ablation outputs,
- error-analysis artifacts.

### Start at `manuscript`

Use when the user has:
- a real draft,
- section notes,
- results already analyzed,
- a venue target and wants prose or restructuring.

### Start at `submission`

Use when the manuscript is mostly complete and the request is:
- citation cleanup,
- reviewer-style precheck,
- formatting,
- anonymization,
- submission checklist.

## Mixed-Artifact Precedence

When the user brings artifacts from different stages, do not pick the latest-looking file by default. Pick the earliest incomplete stage that still blocks trustworthy downstream work.

Apply this order:
1. If there are raw experiment outputs but no validated analysis bundle, start at `analysis`.
2. If analysis is validated but the manuscript is missing, weak, or structurally incomplete, start at `manuscript`.
3. If the manuscript is stable and the remaining work is bibliography, formatting, peer-style review, or checklisting, start at `submission`.
4. If the literature corpus exists but the question or method is still unstable, fall back to `framing` or `design`.

Examples:
- PDFs + draft methods + raw ablation logs -> `analysis`
- analyzed figures + stats appendix + rough intro -> `manuscript`
- near-final manuscript + BibTeX cleanup + submission checklist -> `submission`

## Boundary Non-Triggers

These should usually bypass the orchestrator and go straight to one local skill:
- "Do a systematic literature review on X" -> `literature-review`
- "Analyze these CSVs statistically" -> `results-analysis`
- "Rewrite this discussion section" -> `scientific-writing`
- "Simulate reviewer feedback on this manuscript" -> `peer-review` or `sci_paper_validator`
