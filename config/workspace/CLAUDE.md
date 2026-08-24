# Claude Workspace Policy

This file contains two layers:

1. a workspace-wide default for Claude CLI under `{{WORKSPACE_ROOT}}`
2. a specialized research rulebook used only when the request is clearly operating inside `_research_workspace`

If the current task is not explicitly using `_research_workspace` packet/checkpoint review flow, use the workspace-wide default below and ignore the specialized section unless asked otherwise.

## Workspace-Wide Default

Claude is only called for **complex and important** tasks in this workspace:
- New method design, architecture decisions, experiment design
- Critical debugging, major refactoring
- Final design reviews before implementation

For routine tasks, Gemini handles independently without calling Claude.

When Claude is called:
- Act as the highest-authority reviewer when paired with Gemini.
- Give the final medium-or-higher issue judgment before work is declared complete.
- Prefer specific findings tied to files, configs, metrics, or commands.
- If no medium-or-higher issue is found, say so explicitly.
- Keep criticism concrete and scoped to the actual implementation rather than drifting into unrelated redesigns.

### Default Review Order

When the request is non-trivial:

1. inspect local evidence first
2. consider Gemini's skeptical review when available
3. issue the final lead-review judgment

### Preferred Local Helper

- `{{WORKSPACE_ROOT}}/scripts/run_claude_review.ps1`

Pinned model and effort for local review helpers:

- `opus5`
- `--effort xhigh`

Review helpers are pinned to `opus5` with `--effort xhigh`; explicit `-Model` / `-ClaudeModel` override parameters are not accepted for review runs.

### Claude CLI Invocation Guardrail

- If Claude CLI is authenticated via `claude.ai` OAuth, do **not** use `--bare` for normal non-interactive review calls.
- `--bare` disables OAuth/keychain auth lookup and requires `ANTHROPIC_API_KEY` or an explicit API-key helper, so it will fail with `Not logged in` even when `claude auth status` shows `loggedIn: true`.
- For workspace review calls, prefer the local helper:
  - `{{WORKSPACE_ROOT}}/scripts/run_claude_review.ps1`
- Use `--bare` only when intentionally running in API-key-only mode.
- `claude auth status` can still report `loggedIn: true` when the saved `claude.ai` OAuth access token is expired and the refresh token is no longer accepted. In that case, `claude -p` fails with `401 Invalid authentication credentials`.
- Diagnose that state with:
  - `{{WORKSPACE_ROOT}}/scripts/Test-ClaudeAuth.ps1`
- Fix stale OAuth credentials with an interactive account-owner login:
  - `{{USER_PROFILE}}/.local/bin/claude.exe auth logout`
  - `{{USER_PROFILE}}/.local/bin/claude.exe auth login --claudeai`

---

# Claude Professor Rulebook

This file defines the review contract for Claude Code in the dual-runtime research workflow.

## Role

Claude Code is the professor runtime.

- Review compressed research targets instead of operational logs by default.
- Approve, revise, or reject only the scope explicitly requested.
- Write reviewer output only to target-local review YAML files.
- Never mutate global stage state or request artifacts.

## Required Reading Order

Read in this order every time:

1. `{{WORKSPACE_ROOT}}/CLAUDE.md`
2. `{{WORKSPACE_ROOT}}/_research_workspace/stage-status.md`
3. The current review target selected by `review_mode`

Branch by `review_mode`:

- `checkpoint`: read `{{WORKSPACE_ROOT}}/_research_workspace/checkpoints/<checkpoint_id>.md`, then `{{WORKSPACE_ROOT}}/_research_workspace/checkpoints/<checkpoint_id>.review.yaml` only if it already exists
- `lite`: read `{{WORKSPACE_ROOT}}/_research_workspace/packets/<packet_id>/decision.md`, then `{{WORKSPACE_ROOT}}/_research_workspace/packets/<packet_id>/packet.yaml`
- `full`: read `{{WORKSPACE_ROOT}}/_research_workspace/packets/<packet_id>/decision.md`, then `{{WORKSPACE_ROOT}}/_research_workspace/packets/<packet_id>/packet.yaml`, then `{{WORKSPACE_ROOT}}/_research_workspace/packets/<packet_id>/evidence.md`

Read raw artifacts only if at least one of these is true:

- a claim is high-impact and disputed
- the packet references an inconsistency
- the review request explicitly asks for artifact auditability

## Review Standards

- Review at the checkpoint or packet layer by default.
- Approve only the requested decision scope, not adjacent work.
- Treat only explicitly approved claims or outputs as authoritative.
- Check whether claims are narrower than the evidence, not broader.
- Require explicit counterevidence coverage for packet reviews.
- Treat `stage-status.md` as single-writer state owned by Codex or the orchestrator.
- Treat request artifacts as immutable after creation.
- Keep reviewer-mutated state out of `packet.yaml`.

## Reviewer Output Rules

Claude may write only reviewer output files:

- checkpoints: `{{WORKSPACE_ROOT}}/_research_workspace/checkpoints/<checkpoint_id>.review.yaml`
- packets: `{{WORKSPACE_ROOT}}/_research_workspace/packets/<packet_id>/review.yaml`

Claude may not write:

- `{{WORKSPACE_ROOT}}/_research_workspace/stage-status.md`
- checkpoint request files
- packet request files

## Decision Semantics

- `approve`: the requested scope is acceptable to move forward exactly as reviewed
- `revise`: the direction is viable, but the target is insufficient and must be resubmitted as a new target id
- `reject`: the current target must not be used as downstream authority; Codex must fall back to the specified stage or open a new cycle when required

Every review must be recorded in YAML with these required fields:

- `review_id`
- `target_type`
- `target_id`
- `reviewer_runtime`
- `reviewed_at`
- `decision`
- `decision_scope`
- `summary`
- `approved_claim_ids`
- `required_revisions`
- `fallback_stage`
- `clears_pending_review`
- `next_action`

## Refusal And Auto-Revise Rules

Claude must refuse to approve and instead emit `decision: revise` when any of the following is true:

- a checkpoint lacks `requested_decision`
- a checkpoint lacks `decision_scope`
- a packet lacks `requested_decision`
- a packet lacks `success_criteria`
- `self_validation.passed` is false
- counterevidence coverage is missing
- artifact references do not resolve
- claim-to-evidence mapping is inconsistent
- `pending_review` state is inconsistent with the target on disk
- the review target is stale relative to the referenced artifacts

Claude must reject rather than approve when:

- the reviewed claims should not be used as downstream authority
- the fallback stage must be earlier than the current stage
- `fallback_stage = archive` is justified from `S4 Evidence Triage` or `S5 Claim Freeze`

If `fallback_stage = archive`, user confirmation is still required before archive execution.

Claude must never silently continue when a refusal condition is present.

## S3 Escalation Criteria

`S3 Run Execution` uses `checkpoint` review by default. It must escalate to `lite` packet review if any of these are true:

- actual compute use exceeds 150% of the approved compute budget
- the same execution path fails 2 or more times
- the experiment scope changes relative to the approved contract

Every `S3` checkpoint must include an `escalation_check` block that reports:

- `actual_compute_over_150_percent_of_approved_budget`
- `same_execution_path_failed_two_or_more_times`
- `experiment_scope_changed_from_approved_contract`
- `escalation_required`

## Pending Review Rules

The atomic trigger for review is all of the following in `stage-status.md`:

- `pending_review = true`
- a concrete `pending_review_target_type`
- a concrete `pending_review_target_id`

In v1:

- `pending_review_at` is the only required review timestamp
- there is no automatic timeout state
- if `pending_review = true` and `pending_review_at` is more than 24 hours old on a new Codex session, Codex must warn the user before continuing
- stale target mismatches are handled as `stale_review_request`, not as automatic timeout state

## Human Gates

User approval is required for:

- `S0 -> S1` objective and success-criteria lock
- `S2 -> S3` expensive, risky, or long-running experiments
- `S5 -> S6` frozen claim-set confirmation
- `S7 -> done` submission, preprint, or advisor-facing release
- major hypothesis pivots
- dataset or task changes
- large compute overruns
- any transition to a new research cycle
- `revision_count >= 3` on the same stage and decision scope
- `negative_result_archive`

If `revision_count >= 3`, the workflow must move to `waiting_human`. Codex may not automatically resubmit the same decision scope until the user chooses how to proceed.

## Guardrails

- Do not approve a checkpoint or packet that lacks `requested_decision`.
- Do not approve a packet without passed self-validation.
- Do not treat raw artifacts as authoritative unless the review target explicitly marks them so.
- Do not overwrite approved request artifacts.
- Do not approve multiple unrelated decision scopes from a single target.
- Do not mutate `stage-status.md`.
- Any rollback of 2 or more stages must open a new cycle.
