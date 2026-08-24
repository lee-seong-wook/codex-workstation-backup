---
name: context-checkpoint
description: >
  Automatically save structured progress checkpoints before context overflow.
  This skill detects when a session is getting heavy (many tool calls, large
  conversation, complex multi-step work) and proactively writes a `progress.md`
  file that captures everything needed to resume in a new session.

  AUTO-TRIGGER CONDITIONS:
  - After every 15+ tool calls in a single session
  - When working on multi-file changes spanning 5+ files
  - Before any `/clear` or session reset
  - When the user says "save progress", "checkpoint", "save state"
  - When the conversation exceeds ~30 back-and-forth exchanges
  - When the model detects it's repeating context or losing track

  EXPLICIT TRIGGERS: "save progress", "checkpoint", "save state", "dump progress",
  "진행 상황 저장", "체크포인트", "저장해줘", "상태 저장", "이어서 하려면",
  "다음 세션에서 이어서", "컨텍스트 저장".
---

# Context Checkpoint — 자동 진행상황 보존 스킬

## 개요

긴 작업 중 컨텍스트 윈도우가 꽉 차면 이전 작업이 모두 사라진다.
이 스킬은 **작업 도중 자동으로 `progress.md`에 체크포인트를 기록**하여,
다음 세션에서 파일 하나만 읽으면 바로 이어서 작업할 수 있게 한다.

> **핵심 원칙**: 내가 지금 교체된다면, 다음 AI가 `progress.md`만 읽고 바로 이어서 할 수 있어야 한다.

## 자동 트리거 조건 (Auto-Trigger)

모델이 스스로 다음 조건을 감지하면 **자동으로** 체크포인트를 수행한다:

```yaml
auto_trigger:
  # 도구 호출 기반 (가장 신뢰할 수 있는 휴리스틱)
  tool_calls_threshold: 15          # 15회 이상 도구 호출 시
  tool_calls_interval: 20           # 이후 매 20회마다 갱신

  # 대화 길이 기반
  exchange_threshold: 30            # 30회 이상 왕복 대화 시

  # 파일 변경 기반
  files_modified_threshold: 5       # 5개 이상 파일 수정 시

  # 작업 복잡도 기반
  multi_step_task: true             # 계획 실행, 대규모 리팩토링 등

  # 위험 신호 (즉시 트리거)
  danger_signals:
    - 같은 내용을 반복 설명하고 있음
    - 이전에 한 작업을 다시 확인하고 있음
    - 파일 내용을 다시 읽어야 하는 상황
    - 에러 → 수정 루프가 3회 이상 반복
```

## 수동 트리거

사용자가 명시적으로 요청할 때:
- "진행 상황 저장해줘"
- "체크포인트"
- "다음 세션에서 이어서 하려면?"
- "save progress"
- "checkpoint"

## progress.md 형식

### 저장 위치

```
<project-root>/progress.md        # 기본 위치
docs/progress.md                  # docs/ 디렉토리가 있으면
.gemini/progress.md               # 프로젝트 외부 작업이면
```

### 필수 구조

```markdown
# Progress Checkpoint

> **생성 시각**: YYYY-MM-DD HH:MM
> **세션 요약**: [한 줄 요약]
> **재개 방법**: 이 파일을 새 세션에서 보여주면 됩니다.

## 🎯 목표

[이 세션에서 달성하려는 최종 목표]

## ✅ 완료된 작업

1. [구체적 작업 1] — [결과/상태]
2. [구체적 작업 2] — [결과/상태]
3. ...

## 🔄 진행 중인 작업

- [현재 하고 있던 작업] — [어디까지 했는지]
- [막힌 부분이 있으면 설명]

## ❌ 아직 안 한 작업

1. [남은 작업 1]
2. [남은 작업 2]
3. ...

## 📁 변경된 파일

| 파일 | 변경 유형 | 요약 |
|------|----------|------|
| `path/to/file.py` | 생성 | [무슨 파일인지] |
| `path/to/existing.py` | 수정 | [뭘 바꿨는지] |

## 🧠 핵심 결정 & 컨텍스트

- [중요한 설계 결정 1]: [왜 그렇게 결정했는지]
- [중요한 설계 결정 2]: [대안은 뭐였고 왜 이걸 택했는지]
- [발견한 사실/제약사항]: [다음 세션에서 알아야 할 것]

## ⚠️ 주의사항 & 알려진 이슈

- [이슈 1]: [상태]
- [이슈 2]: [상태]

## 🔜 다음 세션에서 할 일 (우선순위순)

1. **즉시**: [가장 먼저 해야 할 것]
2. **이어서**: [그 다음 할 것]
3. **마무리**: [최종 검증/정리]

## 📋 참고 명령어 & 경로

```bash
# 현재 작업 디렉토리
cd <path>

# 테스트 실행 명령
<command>

# 빌드/실행 명령
<command>
```

## 🔗 관련 파일 & 문서

- [계획서](path/to/plan.md)
- [설계 문서](path/to/design.md)
- [이전 체크포인트](path/to/previous_progress.md)
```

## 체크포인트 품질 기준

### MUST HAVE (없으면 체크포인트 실패)

- [ ] 목표가 명확히 기술됨
- [ ] 완료/미완료 작업이 구체적으로 나열됨
- [ ] 변경된 파일 목록이 정확함
- [ ] 다음 세션에서 첫 번째로 할 일이 명시됨
- [ ] 재개 시 필요한 명령어/경로가 포함됨

### NICE TO HAVE

- [ ] 핵심 결정의 근거 기록
- [ ] 알려진 이슈와 우회 방법
- [ ] 이전 체크포인트 링크 (체인)

## 재개 프로토콜

새 세션에서 이전 작업을 이어받을 때:

1. **사용자가 progress.md를 제시**하거나, 프로젝트 루트에서 자동 감지
2. **에이전트가 읽고 상태 확인**:
   ```
   "이전 세션의 체크포인트를 확인했습니다.
   목표: [목표]
   완료: [N/M 작업]
   다음 할 일: [첫 번째 작업]
   이어서 진행할까요?"
   ```
3. **작업 재개** 후 기존 progress.md를 갱신

## 체크포인트 체인

장기 프로젝트에서는 여러 세션에 걸쳐 체크포인트가 쌓일 수 있다:

```
progress.md                    ← 현재 (항상 최신)
progress_2026-04-30_1800.md    ← 이전 세션 1 (자동 아카이빙)
progress_2026-04-30_1500.md    ← 이전 세션 2
```

새 체크포인트를 쓸 때 기존 파일은 타임스탬프 접미사로 아카이빙한다.

## 통합 규칙

### 다른 스킬과의 관계

| 스킬 | 통합 방법 |
|------|----------|
| `executing-plans` | 배치 완료 시 자동 체크포인트 |
| `systematic-debugging` | 디버깅 3회 이상 반복 시 자동 체크포인트 |
| `brainstorming` | 설계 확정 후 자동 체크포인트 |
| `writing-plans` | 계획 작성 완료 후 자동 체크포인트 |
| `planning-with-files` | progress.md 형식 공유 (호환) |

### 자동 삽입 문구

체크포인트를 저장한 후 사용자에게:
```
💾 체크포인트 저장 완료 (progress.md)
   완료: N개 작업 / 남음: M개 작업
   컨텍스트가 무거워지면 새 세션에서 progress.md를 보여주세요.
```

## Anti-Patterns

| ❌ 하지 말 것 | ✅ 대신 할 것 |
|-------------|-------------|
| 코드 전체를 progress.md에 복사 | 파일 경로 + 변경 요약만 기록 |
| 추상적 상태 ("잘 진행 중") | 구체적 상태 ("parser.py 43줄까지 완료") |
| 이전 체크포인트 덮어쓰기 | 타임스탬프로 아카이빙 후 새로 작성 |
| 체크포인트만 쓰고 검증 안 함 | 파일 존재 여부 등 기본 검증 포함 |

## 관련 스킬

- **planning-with-files** — 세션 복구를 위한 파일 기반 계획 관리 (task_plan.md, findings.md)
- **executing-plans** — 계획 실행 중 배치 체크포인트
- **verification-before-completion** — 완료 전 검증 (체크포인트 후 재개 시에도 적용)
