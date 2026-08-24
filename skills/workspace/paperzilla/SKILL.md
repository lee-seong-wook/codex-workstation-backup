---
name: paperzilla
description: >
  Interact with the Paperzilla platform for AI-curated paper recommendations and
  canonical paper management. Use when users ask for paper recommendations, want to
  browse research feeds, read canonical papers as markdown, leave recommendation
  feedback, or export feeds. Triggers on: "paperzilla", "paper recommendations",
  "research feed", "canonical paper", "pz feed", "pz paper", "추천 논문",
  "논문 피드", "논문 추천", "페이퍼질라", "연구 피드".
license: MIT
metadata:
  skill-author: "Paperzilla Inc"
---

# Paperzilla

Paperzilla is an AI-powered paper recommendation platform. This skill provides
CLI-based access to projects, recommendations, canonical papers, and feeds.

## When to Use

- Paperzilla 프로젝트의 최신 논문 추천을 확인할 때
- 추천 논문의 상세 정보를 markdown으로 읽고 싶을 때
- 논문 추천에 피드백(upvote/downvote/star)을 남길 때
- 프로젝트 피드를 JSON이나 Atom으로 내보낼 때
- canonical paper를 요약하거나 연구 관련성을 분석할 때

## What You Can Ask

- "Give me the latest recommendations from project X."
- "Open recommendation Y and explain why it matters."
- "Fetch canonical paper Z as markdown and summarize it."
- "Tell me how this paper is relevant to my research."
- "Show me the feed for project X."
- "Leave feedback on a recommendation."
- "Export this paper, recommendation, or feed as JSON."

## Prerequisites

### Installation

**macOS:**
```bash
brew install paperzilla-ai/tap/pz
```

**Windows (Scoop):**
```bash
scoop bucket add paperzilla-ai https://github.com/paperzilla-ai/scoop-bucket
scoop install pz
```

**Linux / Build from source:**
See https://docs.paperzilla.ai/guides/cli-getting-started

### Authentication
```bash
pz login
```

### Update
```bash
pz update
```

## CLI Quick Reference

| Command | Description |
|---------|-------------|
| `pz project list` | List all projects |
| `pz project <id>` | Show project details |
| `pz feed <id>` | Browse project feed |
| `pz feed <id> --must-read --since YYYY-MM-DD --limit N` | Filtered feed |
| `pz feed <id> --json` | Feed as JSON |
| `pz feed <id> --atom` | Feed as Atom URL |
| `pz paper <id>` | Read canonical paper |
| `pz paper <id> --markdown` | Paper as markdown |
| `pz rec <id>` | Open recommendation |
| `pz rec <id> --markdown` | Recommendation as markdown |
| `pz feedback <id> upvote/star/downvote` | Leave feedback |
| `pz feedback clear <id>` | Clear feedback |

**Feed markers:** `[↑]` upvote, `[↓]` downvote, `[★]` star

## Example Workflow

**User**: "Show me the must-read papers from my ML project this month."

**Agent**:
```bash
pz feed ml-safety --must-read --since 2026-04-01 --limit 10
```
Then summarize each recommendation with relevance analysis.

**User**: "Read that paper on alignment and summarize it."

**Agent**:
```bash
pz paper alignment-tax-2026 --markdown
```
Then provide a structured summary with key contributions and relevance.

## Configuration

```bash
export PZ_API_URL="https://paperzilla.ai"
```

## Troubleshooting

| Issue | Solution |
|-------|----------|
| `pz: command not found` | Install via Scoop/Homebrew |
| `401 Unauthorized` | Run `pz login` |
| Markdown not ready | `pz rec` queues generation; retry after a moment |

## References

- Docs: https://docs.paperzilla.ai/guides/cli
- Quickstart: https://docs.paperzilla.ai/guides/cli-getting-started
- Repo: https://github.com/paperzilla-ai/pz
