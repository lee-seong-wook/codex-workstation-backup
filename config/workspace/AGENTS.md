# AGENTS.md

## Workspace-Wide Multi-Model CLI Policy

These rules apply to `{{WORKSPACE_ROOT}}` and all descendant folders unless a deeper `AGENTS.md` overrides them.

- Gemini CLI is the **default working model**. Most tasks should be handled by Gemini alone.
- Only consult Claude CLI for **complex and important** work such as: new method design, architecture decisions, experiment design, critical debugging, or major refactoring.
- For routine tasks (status checks, simple fixes, config changes, log analysis, Q&A), Gemini handles independently without calling Claude.
- When Claude is consulted:
  - Claude CLI = lead reviewer and final tie-breaker
  - Claude review helpers must use `opus5` with `--effort xhigh`; explicit model override parameters are not accepted.
  - Gemini CLI = skeptical independent reviewer
  - Gemini review helpers must use `gemini-3.5-flash`; explicit model override parameters are not accepted.
- The preferred local helpers are:
  - `{{WORKSPACE_ROOT}}/scripts/run_smart_review.ps1`
  - `{{WORKSPACE_ROOT}}/scripts/run_claude_review.ps1`
  - `{{WORKSPACE_ROOT}}/scripts/run_gemini_review.ps1`
  - `{{WORKSPACE_ROOT}}/scripts/run_dual_review.ps1`
- Smart review routing keeps model choices fixed. It changes only the review depth: `routine`, `review`, `deep`, or `critical`.
- Route by risk signals rather than ambiguous difficulty labels. Escalate for design decisions, sensitive files, repeated failures, security/auth/schema/deploy changes, data-loss risk, or major refactoring.
- If automatic routing is uncertain, gather read-only evidence first, then escalate only when the evidence shows meaningful risk or uncertainty. Manual overrides may use `-Mode routine|review|deep|critical`.
- Default review order for **complex** tasks: relevant local skill(s) -> local evidence -> Gemini analysis -> Claude review (if needed) -> final synthesis.
- Default for **routine** tasks: Gemini handles directly.
- If one CLI is unavailable, times out, or returns a tooling error, state that briefly and continue with the remaining evidence. Do not silently skip the attempt.

## Goal
This workspace should prefer automatic skill routing. The model must infer and apply the most relevant skill(s) from user prompts without requiring explicit skill names.

## Canonical Local Paths
- Local skills: `{{WORKSPACE_ROOT}}/skills`
- Local MCP: `{{WORKSPACE_ROOT}}/mcp`

Compatibility entry points may exist under `.agents`, `.cursor`, and `.claude`, but the canonical repo-local source is the root-level `skills` and `mcp` directories.

## Skill Source Priority
1. Prefer local skills in `{{WORKSPACE_ROOT}}/skills`.
2. If a local skill is missing, fallback to global skills in `{{CODEX_HOME}}/skills`.
3. If both exist, use local first unless user explicitly asks for global behavior.

## Routing Policy
1. If the user explicitly names a skill, use it.
2. If a file extension is present, extension-based routing has highest priority.
3. Otherwise, route by domain keywords/intents.
4. If multiple skills match, pick the most specific one and run minimal required set.
5. If still ambiguous, ask one short clarification question; otherwise do not ask and proceed.
6. Normalize prompt text before matching: lowercase, trim punctuation, and collapse repeated spaces.
7. Accept common Korean/romanized variants for key terms (for example: `MICCAI`, `miccai`, `미카이`).

## Extension-Based Routing (Highest Priority)
- `.pdf` -> `pdf:pdf`
- `.pptx`, "slides", "deck", "presentation", "슬라이드", "발표자료", "덱" -> `presentations:Presentations`
- `.docx` -> `documents:documents`
- `.ipynb`, "notebook", "주피터" -> `jupyter-notebook`
- `.xlsx`, `.csv`, `.tsv`, "spreadsheet", "스프레드시트", "엑셀" -> `spreadsheets:Spreadsheets`

## Intent-Based Routing
- "bug", "error", "failing test", "unexpected behavior", "버그", "에러", "오류", "테스트 실패", "이상 동작" -> `systematic-debugging`
- "debug strategy", "root cause analysis", "디버깅 전략", "원인 분석" -> `systematic-debugging`
- "deploy", "publish", "host", "배포", "호스팅" + "vercel" -> `deploy-platforms`
- "deploy", "publish", "host", "배포", "호스팅" + "netlify" -> `deploy-platforms`
- "deploy", "publish", "host", "배포", "호스팅" + "render" -> `deploy-platforms`
- "deploy", "publish", "host", "배포", "호스팅" + "cloudflare" -> `deploy-platforms`
- "fix CI", "failing GitHub checks", "actions failing", "CI 실패", "깃허브 체크 실패" -> `github:gh-fix-ci`
- "address PR comments", "review comments", "PR 코멘트 반영", "리뷰 코멘트 처리" + GitHub PR -> `github:gh-address-comments`
- "linear ticket", "issue in Linear", "리니어 이슈", "리니어 티켓" -> `linear:linear`
- "Sentry issue", "production error in sentry", "센트리 이슈", "프로덕션 에러" -> `sentry-issue-routing`
- "sora", "generate video", "remix video", "영상 생성", "영상 리믹스" -> `media-tools`
- "text to speech", "voiceover", "narration audio", "TTS", "음성 합성", "나레이션" -> `media-tools`
- "transcribe", "diarization", "audio to text", "음성 인식", "전사", "화자 분리" -> `media-tools`
- "figma", "figma url", "node id", "design to code", "피그마", "디자인 구현" -> `figma-design-routing`
- "security best practices", "secure coding review", "보안 베스트 프랙티스", "보안 리뷰" -> `security-review`
- "threat model", "abuse path", "trust boundary", "위협 모델링", "공격 경로" -> `security-review`
- "security ownership", "bus factor on sensitive code", "보안 소유권", "버스 팩터" -> `security-review`
- "openai docs", "how to use openai api/products", "오픈AI 문서", "오픈AI API 사용법" -> `openai-docs`
- "find skill", "is there a skill for", "스킬 찾아줘", "이런 스킬 있어?", "추천 스킬", "어떤 스킬 있어" -> `find-skills`
- "install skill", "add skill", "curated skill", "스킬 설치", "스킬 추가" -> `skill-installer`
- "create skill", "update skill metadata/workflow", "스킬 만들기", "스킬 업데이트" -> `skill-creator`
- "manage skills", "verify skill drift", "sync verify skills", "스킬 점검", "스킬 드리프트", "스킬 관리", "스킬 매니징", "매니징해줘", "스킬 확인", "스킬들 확인", "전역 스킬", "로컬 스킬", "스킬 자동 사용" -> `autoresearch`
- "paper review", "peer review", "review my manuscript", "논문 리뷰", "논문 심사", "사전 심사", "리뷰어처럼" -> `peer-review`
- "advisor-like manuscript coaching", "지도교수처럼", "교수처럼 피드백", "논문 방향 코칭" -> `lead-paper-architect` + `scientific-manuscript-review`
- "professor mode", "advisor mode", "교수님 모드", "지도교수 모드", "교수님처럼" -> `lead-paper-architect` + `scientific-manuscript-review`
- "manuscript revision", "edit manuscript", "논문 첨삭", "논문 교정", "논문 수정", "원고 수정", "원고 교정", "문장 교정" -> `scientific-manuscript-review`
- "write paper from notes", "draft full paper", "논문 초안 작성", "원고 초안", "paper drafting" -> `research-paper-writer`
- "related work", "prior work comparison", "선행연구", "관련연구", "관련 연구", "비교 분석", "논문 분석", "페이퍼 분석" -> `literature-reviewer`

## Planning and Execution Routing
- New feature/design/modifying behavior, "기능 추가", "동작 변경" -> run `brainstorming` first.
- Multi-step implementation from requirements/spec, "구현 계획", "요구사항 기반 작업" -> `writing-plans`.
- Execute an existing written plan, "계획 실행" -> `executing-plans`.
- About to claim completion/fix/pass, "완료 보고 직전" -> `verification-before-completion`.
- Final integrated validation for verify skills, "통합 검증" -> `verification-before-completion`.
- "save progress", "checkpoint", "save state", "진행 상황 저장", "체크포인트", "상태 저장", "이어서 하려면", "컨텍스트 저장" -> `context-checkpoint`.
- AUTO: After 15+ tool calls or 5+ file modifications in a session -> `context-checkpoint` (auto-trigger).

## Research and Academic Routing
- "literature review", "systematic review", "survey paper", "문헌 리뷰", "체계적 문헌고찰", "서베이 논문" -> `literature-reviewer`
- "academic paper writing", "manuscript drafting", "논문 작성" -> `research-paper-writer` or `lead-paper-architect`
- "MICCAI paper format/strategy", "MICCAI 논문", "미카이 논문", "미카이", "miccai", "mikai" -> `lead-paper-architect` + `venue-templates`
- "rebuttal to reviewers", "리뷰어 답변", "리뷰어 코멘트 답변", "리버털" -> `rebuttal-strategist`
- "bibtex", "reference entry", "citation metadata", "BibTeX", "참고문헌 엔트리" -> `bibtex-manager`
- "polish academic prose", "학술 문장 다듬기" -> `scientific-manuscript-review`
- "SCI-level validation", "top-tier reviewer simulation", "SCI 검증", "리뷰어 시뮬레이션" -> `sci-paper-validator`
- "submission checklist", "anonymization", "submission package", "익명화", "제출 체크리스트", "제출 패키징" -> `submission-manager`
- "medical deep learning coding", "MONAI", "3D medical volumes", "PyHealth", "의료영상 딥러닝" -> `medical-deep-learning`
- "plots/figures/charts for paper", "ablation", "논문 그림", "그래프 생성", "그래프 그려줘", "학습 곡선" -> `plotmaster`
- "scientific diagram/schematic", "과학 도식", "아키텍처 다이어그램", "아키텍처 도식" -> `scientific-visualization` or `plotmaster`
- "poster design", "포스터 디자인", "학회 포스터" -> `scientific-slides` or `venue-templates`

## Academic Composite Routing
- Drafting a new MICCAI manuscript end-to-end -> `research-paper-writer` then `lead-paper-architect` then `venue-templates`
- Manuscript polishing for submission -> `scientific-manuscript-review`
- Reviewer-style precheck before submission -> `peer-review` + `sci-paper-validator`
- Related-work writing from literature search -> `paper-lookup` then `literature-reviewer`
- Final submission package checks -> `bibtex-manager` + `submission-manager`

## Professor Feedback Mode
- Trigger when prompt includes advisor/professor intent (`지도교수처럼`, `교수님 모드`, `교수님처럼`, `advisor mode`, `professor mode`).
- Apply to academic writing/review skills (`lead-paper-architect`, `scientific-manuscript-review`, `peer-review`, `sci-paper-validator`).
- Response format is fixed in this order:
  1. `문제`: what is wrong or weak.
  2. `근거`: specific evidence (text logic, experiment gap, formatting rule, reviewer perspective).
  3. `수정안`: concrete replacement text/structure/experiment action.
  4. `우선순위`: `P0`/`P1`/`P2` with expected impact.
- Do not return only abstract advice in this mode; provide actionable fixes.

## General Behavior
- Prefer automatic routing and execution over asking the user to choose skills manually.
- Use multiple skills only when each is clearly required by task scope.
- Keep outputs concise and action-focused; do not narrate internal routing.

## Skills
A skill is a set of local instructions stored in a `SKILL.md` file.

Discovery rules:
- Local skills live under `{{WORKSPACE_ROOT}}/skills/*/SKILL.md`.
- Global skills live under `{{CODEX_HOME}}/skills/*/SKILL.md`.
- Prefer local first.
- Open only the specific `SKILL.md` files needed for the current task.

## How to use skills
- If the user names a skill or the task clearly matches a skill description, use that skill for that turn.
- If multiple skills apply, choose the minimal set that covers the task and state the order briefly.
- Resolve relative paths in a skill from that skill directory first.
- Reuse skill-local `scripts/`, `assets/`, `templates/`, and `references/` instead of recreating them.
- If a skill cannot be applied cleanly, state the issue briefly and continue with the best fallback.
