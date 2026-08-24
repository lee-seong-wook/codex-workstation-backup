# writing-style.md

Slide copy is part of the design. Sloppy writing breaks even the cleanest layout. These rules apply to titles, subtitles, bullets, callouts, and chart takeaways.

---

## 1. The single most important rule

**Slide titles state the insight, not the topic.**

| Bad (topic) | Good (insight) |
|---|---|
| Q3 financial results | Q3 revenue beat plan by 12%, driven by enterprise expansion |
| Market overview | The TAM doubled in two years, but four players take 80% of it |
| Customer feedback | Onboarding friction is the #1 churn driver — confirmed across three studies |
| Our roadmap | We will sequence platform extensibility before vertical expansion in 2026 |

A good title can be read alone — without seeing the rest of the slide — and still tell the audience what the slide says. If the title fails that test, rewrite it.

---

## 2. Title rules

- One sentence. Sentence case. No terminal period.
- ≤ 14 words. If longer, break into title (≤ 9 words) + subtitle (≤ 14 words).
- Must contain a verb. ("X grew 38%" yes; "Growth in X" no.)
- Subjects should be concrete: a metric, a segment, a product, a customer cohort.
- Numbers belong in titles when they exist. "Revenue beat plan by 12%" is stronger than "Revenue beat plan."
- Korean titles: same rules. End with `–다` form (declarative); avoid `~입니다`/`~합니다` honorifics in titles.

---

## 3. Subtitle rules

- Optional, ≤ 2 lines.
- Adds the *because* or the *implication*. "Net new ARR was 71% enterprise, vs. a 58% Q1 baseline."
- Never restates the title. Never lists what the slide will cover ("This slide shows…").

---

## 4. Bullet rules

- 5–9 words each. Phrases, not sentences. No terminal periods unless the bullet is a complete sentence and you have a reason.
- **Parallel grammatical structure** within a list. If the first bullet starts with a verb, all do.
- 3–5 bullets per block, 6 max. If you have more, split the slide or promote the rest to a sidebar.
- Optional sub-line under a bullet, in MUTE 11pt, ≤ 14 words. Use to add a number, a source, or a single piece of evidence.

**Bad bullet block (broken parallelism, too long):**

- Customers are reporting that onboarding takes too long.
- Time-to-first-value
- 23% of churned accounts cite this as the primary reason.
- Need to invest more in self-serve resources.

**Good bullet block:**

- Onboarding now takes 11 days median, up from 6 in 2024
- 23% of churned accounts cite onboarding as the primary reason
- Self-serve docs cover only 4 of the top 12 setup tasks
- Field engineers are spending 30% of their time on onboarding tickets

---

## 5. Numbers and units

- First mention always carries a unit. `38%`, `₩2.3B`, `12 days`, `4×`.
- Subsequent references in the same slide can be bare ("38" in a follow-up bullet).
- Avoid spurious precision. If the number is "approximately 23.4%", round to 23%. Reserve decimals for figures where decimals matter (margin, ratio, error).
- Prefer ranges or comparisons over absolutes. "12% above plan" beats "$2.3M revenue."
- Always tabular figures (`tnum`) so columns align.

---

## 6. Callouts and sidebars

Format inside MUTE_FILL sidebars:

```
HEADER (UPPERCASE, 11pt 600)
One short paragraph (12pt 400, ≤ 4 lines) that adds the
"why it matters" or "what we did about it." Specific, not
abstract.
```

Headers we like: `WHY IT MATTERS`, `WHAT'S NEW`, `BLOCKER`, `RISK`, `DECISION`, `NEXT STEP`.

---

## 7. Chart takeaway sentence (template T9)

Always one sentence, 14 pt 500 INK. State the *finding*, not the *figure*. Examples:

- "Conversion peaks at month two, then drops sharply through month six."
- "The two newest cohorts already exceed legacy LTV after 90 days."
- "Cost per acquisition is roughly flat, but mix has shifted from search to outbound."

Never write "As you can see in the chart…" or "This chart shows…"

---

## 8. Source attribution

- Every chart and every non-self-evident table gets a source line in the slide footer (y=688), in caption style.
- Format: `SOURCE: <DATASET / TEAM / DATE>`. UPPERCASE, tracked +20.
- For internal: `SOURCE: PRODUCT ANALYTICS, 2026-04-30`.
- For external: `SOURCE: GARTNER, "MARKET GUIDE FOR X", 2025`.
- If an estimate: `SOURCE: INTERNAL ESTIMATE`.

---

## 9. Voice and tone

- Active voice. Present tense. ("We shipped X." Not "X was shipped by us.")
- Concrete > abstract. Names > pronouns. ("Acme renewed at 2.3× ACV" beats "they renewed at 2.3× ACV.")
- Drop hedges: very, really, quite, rather, somewhat, fairly.
- Drop boosters: world-class, best-in-class, robust, cutting-edge, next-generation, unprecedented.
- Drop transitions: also, furthermore, moreover, additionally, in addition.

---

## 10. Korean style notes

- 슬라이드 제목은 인사이트 한 문장으로. 끝에 마침표 없음. (`엔터프라이즈 매출이 3분기 연속 SMB를 앞섰다`)
- 본문 불릿: 5–9 단어, 명사구 또는 짧은 술어구 위주. 평행 구조 유지.
- 영문 약어와 한글 단위는 띄어쓰기 일관: `ARR 38% 증가`, `MAU 220만 명`.
- 통계/숫자에는 항상 단위, 첫 등장에서 명시: `12.3%p`, `2.3 배`, `11 일`.
- 존댓말 지양 (제목/불릿). 본문 설명에서만 필요시 사용.

---

## 11. Quick rewrite drills

Before writing original copy, rewrite each of these. They surface most common mistakes.

| Source line | Rewrite to |
|---|---|
| "Discussion of Q3 revenue performance" | A title that states what Q3 revenue did |
| "Customer feedback summary" | A title that names the strongest finding |
| "Strategic options" | A title that names which option you are recommending |
| "Next steps" | A title that names the single most important action |
| "Roadmap" | A title that names the bet you are making |
