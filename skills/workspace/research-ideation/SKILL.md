---
name: research-ideation
description: >
  Structured research project initiation using the 5W1H framework, systematic
  literature review with Zotero integration, gap analysis, and research planning.
  Use when starting a new research project from scratch, conducting systematic
  literature review with Zotero, performing gap analysis across 5 dimensions,
  or creating a formal research proposal.
  Triggers: "research ideation", "5W1H", "research gap", "gap analysis",
  "start research project", "define research question", "research planning",
  "연구 기획", "연구 질문 정의", "갭 분석", "연구 시작", "체계적 문헌고찰".

  **vs scientific-brainstorming**: scientific-brainstorming is for open-ended creative
  ideation and exploring interdisciplinary connections. This skill (research-ideation)
  is for structured project initiation with formal outputs (literature review, proposal).
  **vs hypothesis-generation**: hypothesis-generation is for formulating testable
  hypotheses from existing observations/data. This skill covers the earlier phase
  of identifying what to research before you have data.
---

# Research Ideation

Structured workflow for research project initiation — from idea generation to formal proposal.

## When to Use (vs Related Skills)

| Scenario | Use This Skill | Use Instead |
|----------|----------------|-------------|
| Starting a research project from scratch | ✅ | |
| Systematic literature review with Zotero | ✅ | |
| 5W1H framework brainstorming | ✅ | |
| Gap analysis (5 dimensions) | ✅ | |
| Open-ended creative brainstorming | | `scientific-brainstorming` |
| Formulating testable hypotheses from data | | `hypothesis-generation` |
| Writing Related Work section | | `literature-reviewer` |
| Code/feature design brainstorming | | `brainstorming` |

## Core Workflow

```
연구 관심사 → 5W1H 브레인스토밍 → 문헌조사 → 갭 분석 → 연구 질문 정의 → 방법 선택 → 연구 계획
```

### Phase 1: Idea Brainstorming (5W1H Framework)

| 차원 | 질문 |
|------|------|
| **What** | 어떤 문제/현상을 연구할 것인가? |
| **Why** | 왜 이 문제가 중요한가? |
| **Who** | 타겟 대상과 이해관계자는? |
| **When** | 연구의 시간적 범위와 맥락은? |
| **Where** | 적용 시나리오와 도메인은? |
| **How** | 예비 연구 방법론은? |

### Phase 2: Literature Review (Zotero 연동)

- 검색 키워드 구성 → 학술 DB 검색 (arXiv, Google Scholar)
- 논문 품질 평가 → Zotero 자동 추가 (`add_items_by_doi`)
- 컬렉션 조직: `Research-{topic}-{YYYY}` 형식
- Open-access PDF 자동 첨부 (Unpaywall)

### Phase 3: Gap Analysis (5차원)

1. **Literature gaps**: 아직 충분히 연구되지 않은 주제
2. **Methodological gaps**: 기존 방법론의 한계와 개선 기회
3. **Application gaps**: 이론→실제 적용 기회
4. **Interdisciplinary gaps**: 학제간 연구 기회
5. **Temporal gaps**: 시간 변화에 따른 새로운 연구 필요성

### Phase 4: Research Question → Proposal

- SMART 원칙 적용 (Specific, Measurable, Achievable, Relevant, Time-bound)
- 중요성, 참신성, 실현 가능성 평가
- 연구 목표와 기대 기여 정의

## Output Files

- `literature-review.md` — 구조화된 문헌 리뷰
- `research-proposal.md` — 연구 제안서 (질문, 방법, 계획)
- `references.bib` — BibTeX 참고문헌

## Integration

```
research-ideation (연구 기획)
    ↓
실험 실행 (연구자)
    ↓
results-analysis (결과 분석)
    ↓
lead-paper-architect (논문 작성)
```

## Reference Files

- `references/5w1h-framework.md` — 5W1H 프레임워크 상세 가이드
- `references/literature-search-strategies.md` — 문헌 검색 전략
- `references/zotero-integration-guide.md` — Zotero MCP 통합 가이드
- `references/gap-analysis-guide.md` — 갭 분석 가이드
- `references/research-question-formulation.md` — 연구 질문 정의
- `references/method-selection-guide.md` — 방법 선택 가이드
- `references/research-planning.md` — 연구 계획 수립

## Example Files

- `examples/example-literature-review.md` — 문헌 리뷰 예시
- `examples/example-research-proposal.md` — 연구 제안서 예시
