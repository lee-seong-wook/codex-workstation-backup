---
type: results-report
date: 2026-03-18
experiment_line: freezing
round: 3
purpose: transfer-summary
status: active
source_artifacts:
  - analysis-output/analysis-report.md
  - analysis-output/stats-appendix.md
  - analysis-output/figure-catalog.md
linked_experiments:
  - Experiments/Freezing-vs-Adapter.md
linked_results:
  - Results/Adapter-Improves-Transfer.md
---

# Freezing / Round 3 / transfer-summary / 2026-03-18

## Executive Summary
- Round 3 tested whether a subject adapter recovers the performance lost by freezing most of the encoder.
- The adapter consistently improves WER over the frozen baseline and changes the default next-step recommendation.
- Full fine-tuning is still strongest overall, but adapter tuning is the best next branch for efficient transfer work.

## Experiment Identity and Decision Context
- Experiment line: freezing
- Round: 3
- Purpose: resolve whether the freezing gap is best handled by partial adaptation or by abandoning the freezing branch.

## Setup and Evaluation Protocol
- Same subject pool and split as rounds 1-2.
- 5 seeds per condition.
- Primary metric: WER.
- Compared methods: Full fine-tuning, Subject Adapter, Frozen Encoder.

## Main Findings
- Subject Adapter improves mean WER by 3.8 points over Frozen Encoder.
- The gain is consistent across all seeds.
- Adapter variance is also lower, suggesting easier optimization.

## Statistical Validation
- Paired testing supports Adapter > Frozen Encoder after correction.
- Full fine-tuning > Adapter remains suggestive but not conclusive at current n.
- Current evidence is sufficient to keep the adapter branch active and deprioritize pure freezing.

## Figure-by-Figure Interpretation
### Figure 1 — Main comparison
- Why included: this is the core performance decision figure.
- What to notice: adapter closes most of the freezing gap while keeping tighter uncertainty.
- Supported interpretation: lightweight subject adaptation addresses part of the transfer mismatch.
- Decision implication: future transfer experiments should center on adapter design, not frozen-only variants.

### Figure 2 — Training dynamics
- Why included: to explain stability differences.
- What to notice: the frozen baseline oscillates more after epoch 8.
- Supported interpretation: the weaker final mean is paired with harder optimization.
- Decision implication: instability is part of the branch weakness, not noise alone.

## Failure Cases / Negative Results / Limitations
- Full fine-tuning still leads in absolute performance.
- The evidence is limited to 5 seeds and one subject pool.
- No low-resource subject stress test yet.

## What Changed Our Belief
- Before round 3, it was unclear whether freezing should be abandoned entirely.
- After round 3, the better hypothesis is that freezing alone is too rigid, but freezing plus lightweight adaptation remains viable.

## Next Actions
- Run one low-resource robustness check for the adapter branch.
- Add width ablation around the current best adapter size.
- Update the canonical result note for adapter-improves-transfer.

## Artifact and Reproducibility Index
- `analysis-output/analysis-report.md`
- `analysis-output/stats-appendix.md`
- `analysis-output/figure-catalog.md`
- `analysis-output/figures/figure-01-main-comparison.pdf`
- `analysis-output/figures/figure-02-training-dynamics.pdf`
