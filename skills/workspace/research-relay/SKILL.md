---
name: research-relay
description: >
  Collaborative research workflow using file-based handoff between multiple AI agents
  or between an AI agent and a human researcher. Use when research tasks span multiple
  sessions, require agent-to-agent collaboration, or need structured experiment handoffs.
  Triggers on: "research relay", "handoff", "multi-agent research", "agent collaboration",
  "experiment handoff", "research workflow", "relay workflow", "에이전트 협업",
  "연구 릴레이", "핸드오프", "실험 인수인계", "멀티에이전트 연구".
  Also triggers when the user mentions splitting research work across sessions or agents.
allowed-tools: [Read, Write, Edit, Bash]
---

# Research Relay — Multi-Agent Collaborative Research

## 개요

여러 AI 에이전트(또는 에이전트-연구자) 간 파일 기반 핸드오프를 통해 협업하는 연구 워크플로우.
각 에이전트는 자신의 전문 영역을 수행하고, `HANDOFF.md`를 통해 컨텍스트를 전달한다.

## When to Use

- 연구 작업이 여러 세션에 걸쳐 진행될 때
- 에이전트 간 역할 분담이 필요할 때 (예: 문헌조사 → 실험 → 논문)
- 실험 결과를 다른 에이전트에게 인수인계할 때
- 장기 연구 프로젝트의 진행 상황을 추적할 때

## 워크스페이스 구조

프로젝트 루트에 다음 구조를 생성한다:

```
<project>/
├── HANDOFF.md              ← 항상 여기부터 읽기 시작 (핵심 문서)
├── 01_literature/
│   └── review.md           ← 문헌조사 결과
├── 02_hypothesis/
│   ├── candidates.md       ← 가설 후보들
│   └── selected.md         ← 선택된 가설
├── 03_experiment/
│   ├── plan.md             ← 실험 계획서
│   ├── code/               ← 실험 코드
│   └── results.md          ← 실험 결과 (핸드오프 핵심)
└── 04_proposal/
    └── final_proposal.md   ← 최종 제안서/논문 초안
```

> 디렉토리명은 프로젝트 특성에 맞게 변경 가능. 핵심은 `HANDOFF.md`의 존재.

## HANDOFF.md 프로토콜

### 필수 필드

```markdown
## 현재 단계: [01_literature | 02_hypothesis | 03_experiment | 04_proposal]
## 마지막 작업자: [에이전트명 또는 연구자]
## 완료 시각: [YYYY-MM-DD HH:MM]

### 완료된 작업
- [x] 작업 1
- [x] 작업 2

### 다음 작업자: [에이전트명 또는 연구자]
### 다음 단계: [단계명]
### 해야 할 일
1. 구체적 작업 1
2. 구체적 작업 2

### 컨텍스트
- 핵심 결과: [요약]
- 주의사항: [알려진 이슈]
- 참고 파일: [경로]
```

### 규칙

1. **시작 전**: 항상 `HANDOFF.md` → `selected.md` → 이전 `results.md` 순서로 읽기
2. **작업 중**: 진행 상황을 `HANDOFF.md`에 실시간 업데이트
3. **완료 후**: `다음 작업자`, `다음 단계`, `해야 할 일`을 명확히 기록

## 에이전트 역할 분담 예시

| 역할 | 담당 단계 | 전문 영역 |
|------|----------|----------|
| **Agent A** (문헌/기획) | 01, 02, 04 | 문헌조사, 가설 수립, 논문 작성 |
| **Agent B** (실험/코드) | 03 | 실험 설계, 코드 구현, 결과 분석 |
| **연구자** | 모든 단계 | 의사결정, 방향 설정, 최종 검토 |

## 실험 결과 기록 형식

`03_experiment/results.md`는 반드시 다음 형식을 따른다:

```markdown
# 실험 결과

## 실험 설정
- 날짜: YYYY-MM-DD
- 데이터셋: [이름]
- 주요 파라미터: [설정값]
- 하드웨어: [GPU 등]

## 주요 결과

| 방법 | Metric 1 | Metric 2 | 비고 |
|------|----------|----------|------|
| Baseline | X.XX | X.XX | |
| Proposed | X.XX | X.XX | |

## 가설 검증 결과
- 검증됨 / 부분 검증 / 검증 안됨

## 다음 에이전트에게
### 핵심 발견
### 개선 제안
### 다음 실험 제안 (선택)
```

## 기존 코드 참고

프로젝트에 기존 코드베이스가 있다면, 실험 코드 작성 시 해당 구조를 우선 참고한다.

## 참고 문서

- `references/handoff-protocol.md` — HANDOFF.md 상세 스펙
- `references/research-context.md` — 연구 배경 및 목표
- `references/experiment-templates.md` — 실험 코드 템플릿
