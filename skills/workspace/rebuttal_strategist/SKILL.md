---
name: rebuttal-strategist
description: >
  Helps navigate the academic peer review rebuttal process. Use when the user
  receives peer review comments, needs to write a rebuttal or author response,
  wants to address reviewer criticism, or asks about responding to "reject",
  "major revision", or "minor revision" decisions. Triggers on: "rebuttal",
  "reviewer response", "author response", "point-by-point", "how to respond to reviewer",
  "reviewer said", "reviewer complained", "AC/reviewer thinks", "리뷰어 답변",
  "리버털", "리뷰어 코멘트 답변", "심사 의견 대응", "리뷰 응답", "리뷰어가 말하길".
---

# rebuttal-strategist Skill

## Description

This skill transforms the high-stress rebuttal period into a structured, strategic process. It helps users organize reviewer comments, group similar concerns, and draft responses that are polite, evidence-based, and persuasive. Designed for top-tier conferences (MICCAI, CVPR, NeurIPS) where tone and clarity are critical.

## When to Use

- 리뷰 결과를 받은 뒤 point-by-point rebuttal 문서를 작성해야 할 때
- 감정적인 초안을 학술적으로 정중하고 설득력 있는 톤으로 바꿔야 할 때
- 여러 리뷰어의 중복 이슈를 묶어 대응 전략을 최적화해야 할 때
- 추가 실험/분석 우선순위를 rebuttal 제한 시간 안에 결정해야 할 때
- 수정 원고(revision)에서 변경 사항을 표시(tracked changes)해야 할 때

## Output Format

1. `Issue Map`: 리뷰어별 코멘트 분해와 우선순위 (Must-Fix / Can-Clarify / Can-Ignore)
2. `Response Draft`: 바로 제출 가능한 point-by-point 답변 초안
3. `Evidence Checklist`: 각 답변을 뒷받침할 실험/수치/문장 변경 목록
4. `Tone Check`: 공격적 표현 완화 및 학술 톤 교정 포인트
5. `Revision Markup`: 수정 원고에 변경사항 표시 가이드

## Workflow

### Step 1: Triage All Comments

| Label | Meaning | Action |
|-------|---------|--------|
| **Must-Fix** | Core concern that could justify rejection | Run experiments or restructure |
| **Can-Clarify** | Misunderstanding or missing explanation | Write clear explanation + cite existing evidence |
| **Can-Ignore** | Out-of-scope or contradicted by other reviewers | Acknowledge politely, redirect |

**Cluster cross-reviewer duplicates first.** If R1, R2, and R3 all ask about ablation — address once, reference across all three.

### Step 2: Prioritize by Impact

| Conference | Word Limit | Budget Allocation |
|-----------|-----------|------------------|
| MICCAI/CVPR/ICCV | ~500 words | Must-Fix 60% / Clarify 30% / Ignore 10% |
| NeurIPS/ICML | ~1000 words | Must-Fix 50% / Clarify 35% / Ignore 15% |
| ECCV | 2-page PDF | Proportional to page space |

### Step 3: Draft Each Response

#### Template A: Agree + New Experiment
```
We thank R[N] for this important observation. [Acknowledge validity.]
To address this, we conducted [experiment description].
The results in [new Table/Figure X] show [specific metric], demonstrating [conclusion].
We have updated [Section X, lines Y-Z] to reflect this finding.
```

#### Template B: Clarify + Existing Evidence
```
We thank R[N] for raising this point. We believe there may be a misunderstanding.
As shown in [Table/Figure/Section X] (line Y), [specific existing evidence].
We have added a clarifying sentence in [Section X] to make this more prominent.
```

#### Template C: Polite Disagreement
```
We thank R[N] for this perspective. While we respect this view,
[factual counter-point with citation or logical argument].
This design choice was deliberate because [justification].
We have added a clarifying note to [Section X].
```

### Step 4: Tracked Changes in Revision

수정 원고를 제출할 때 변경사항을 명확히 표시해야 합니다:

**LaTeX 방법 (추천):**
```latex
% 프리앰블에 추가
\usepackage{xcolor}
\usepackage{ulem}  % for strikeout

% 삭제된 텍스트
\newcommand{\deleted}[1]{\textcolor{red}{\sout{#1}}}
% 추가된 텍스트
\newcommand{\added}[1]{\textcolor{blue}{#1}}
% 수정된 텍스트
\newcommand{\revised}[2]{\deleted{#1} \added{#2}}

% 사용 예:
We \revised{used}{leveraged} a novel framework that
\added{significantly reduces inference latency by 35\%}.
```

**`latexdiff` 자동 도구:**
```bash
# 원본과 수정본 비교하여 자동 tracked changes PDF 생성
latexdiff original.tex revised.tex > diff.tex
pdflatex diff.tex
```

**Overleaf 방법:**
- History → Compare versions → Download as PDF with tracked changes

## Key Capabilities

### 1. Review Parsing & Organization
- **Decomposition**: 리뷰 텍스트를 개별 actionable "Point"로 분해
- **Clustering**: 여러 리뷰어의 공통 우려 식별
- **Prioritization**: Must-Fix vs Can-Clarify vs Can-Ignore

### 2. Strategy & Tone Check
- **Tone Transformation**: 방어적 초안 → 전문적 학술 문체
- **"Sandwich" Method**: Acknowledge → Evidence → Resolution
- **Polite Disagreement**: Template C

### 3. Response Drafting
- 러프 노트 기반 초안 생성
- 인용/수치 기반 근거 정리
- 포맷팅 (구분 가능한 인용 vs 답변)

## Guidelines

1. **Never be defensive**: 리뷰어가 틀려도 항상 감사로 시작
2. **Evidence is king**: "We believe" (약함) → "Table 3 shows" (강함)
3. **Be concise**: 리뷰어의 시간은 제한적
4. **Never say "the reviewer missed"**: "to clarify" 사용
5. **Show, don't tell**: 새 실험 결과는 반드시 표/그림으로

## Example

**User**: "Reviewer 2 hates our method, says it's too slow. But they missed Table 4!"

**Agent** (Template B):
```
We thank R2 for raising the important issue of inference speed.
As shown in Table 4 (line 350), our method achieves 45 FPS on an A100 GPU,
which meets the real-time requirement (≥30 FPS). We have moved this result
to the Abstract and highlighted it in the revised Conclusion (lines 412-415)
to ensure it is not overlooked.
```
