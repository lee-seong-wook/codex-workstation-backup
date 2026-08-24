# design-reference.md

Visual reference for the PPT design system — typography, color, spacing, components. Use this as the lookup when generating slides. Coordinates and slide-anatomy details live in `slide-layout-rules.md`.

> Inspirations (reusable principles only, not visuals): editorial broadsheet density, mono-uppercase kicker, single-accent on monochrome (WIRED-style); weight-300 elegance and restrained gradient accent (Stripe-style).

---

## 1. Canvas

| Property | Value |
|---|---|
| Aspect ratio | 16:9 |
| Slide size | 13.333 in × 7.5 in |
| Reference px | 1280 × 720 |
| python-pptx EMU | width 12,192,000 / height 6,858,000 |

---

## 2. Type ramp (Pretendard, weights 400/500/600/700)

```
Role            pt   weight  tracking  leading  color      use
─────────────────────────────────────────────────────────────────
Kicker          11   600     +120      1.0      #6E6E6E    UPPERCASE chapter label
Page number     10   500     +60       1.0      #9A9A9A    tabular, top-right
Title           28   700     -10       1.15     #111111    sentence case, no terminal period
Title (cover)   44   700     -20       1.10     #111111    cover only
Subtitle        16   500     -5        1.35     #4A4A4A    optional, ≤2 lines
Lead body       14   400      0        1.40     #1F1F1F    narrative slides
Body            12   400      0        1.45     #1F1F1F    bullets and prose
Body emphasis   12   600      0        1.45     #111111    inline highlight only
Data label      11   500      0        1.30     #4A4A4A    chart/table labels (tabular)
Big number      56   700     -20       1.0      ACCENT     KPI hero
Caption         9    500     +20       1.30     #9A9A9A    UPPERCASE, sources
```

**Rules**

- Pretendard only. No fallback declared.
- Two type sizes max inside a single content block.
- Numbers always tabular figures.
- Korean and Latin in the same family. Do not switch faces for Korean.

---

## 3. Color tokens

```
PAPER         #FAFAF7   default slide background (warm broadsheet white)
PAPER_PURE    #FFFFFF   covers and tables only
INK           #111111   primary text, KPI numerals
INK_SOFT      #1F1F1F   body text
MUTE          #4A4A4A   secondary text, captions
SUBMUTE       #6E6E6E   kicker, sub-labels
HAIRLINE      #E6E4DD   1px rules and dividers
MUTE_FILL     #F2F0EA   light fill blocks, table zebra rows
ACCENT        #1E3A8A   primary accent (links, KPIs, primary chart series)
ACCENT_SOFT   #93C5FD   accent's lightest companion (chart fades)
POSITIVE      #166534   trend up — chart and KPI only
NEGATIVE      #9F1239   trend down — chart and KPI only
```

**Sequential palette (5 steps):** `#1E3A8A → #2C5282 → #3B82F6 → #60A5FA → #93C5FD`.
**Categorical palette (max 5):** `#111111`, `#4A4A4A`, `#1E3A8A`, `#166534`, `#9F1239`.

**Accent rule of three.** ≤ 3 accent uses per slide. The accent is meaning, not decoration.

---

## 4. Spacing system

8 px baseline. All y-positions are multiples of 8.

```
4   8   12   16   24   32   40   48   56   64   80   96
```

- Block-to-block vertical spacing: 24 px (default), 32 px (narrative slides).
- Bullet-to-bullet vertical spacing: 12 px.
- Caption-to-figure spacing: 8 px.
- Section gutter (between two-col halves): 32 px.

---

## 5. Components

### 5.1 Hairline rules

- 1 px solid `#E6E4DD`.
- Used for: top frame rule (y=88), bottom frame rule (y=672), section dividers within content, chart axes.
- Never doubled. Never above 1 px.

### 5.2 Callout / sidebar

Right 1/3 of the content area (x=824, w=400). Background `#F2F0EA`, padding 16 px, no border. Header in 11 pt weight 600 UPPERCASE, body 12 pt regular.

### 5.3 KPI block

Big number 56 pt 700 in ACCENT, label 11 pt 500 UPPERCASE in MUTE below, change indicator (`▲ 12.4%` / `▼ 3.1%`) 12 pt 500 in POSITIVE/NEGATIVE next to label.

### 5.4 Tag / chip

11 pt 500 UPPERCASE, padding 4 × 8 px, hairline border, no fill. Used for status (e.g., `IN PROGRESS`, `BLOCKED`).

### 5.5 Numbered marker (frameworks/timelines)

24 × 24 px circle, hairline outline, number 12 pt 600 ink. No filled discs.

### 5.6 Quote

Lead body 14 pt italicized off (Pretendard has no italic; use weight 500 instead). Em-dash + attribution in 11 pt 500 UPPERCASE MUTE below.

---

## 6. Charts

| Property | Value |
|---|---|
| Background | PAPER |
| Primary series | ACCENT |
| Secondary series | INK_SOFT, MUTE, SUBMUTE in that order |
| Gridlines | horizontal hairline only |
| Legend | omitted in favor of in-place labels |
| 3D / shadows | never |
| Source line | required, caption style, 8 px under chart |

### Acceptable chart types

bar (vertical), bar (horizontal), line, area (single), stacked bar (≤4 series), small-multiples grid, dot/lollipop, simple table.

### Forbidden

pie (use 100% stacked bar), 3D anything, donut with center label, radar, gradient-filled area, dual-axis (split into two charts).

---

## 7. Tables

```
Header row     12 pt   weight 600   INK         padding 8/8 top/bottom
Body row       12 pt   weight 400   INK_SOFT    padding 6/6
Numeric col    tabular, right-aligned
Hairline       top of table, under header, bottom of table — only
Vertical rules never
Zebra rows     optional, MUTE_FILL on every other row, never on columns
Max size       7 columns × 10 rows on a single slide
```

---

## 8. Imagery & icons

- Icons: 1.5 px stroke, 24 × 24 px, monochrome INK or ACCENT, single set per deck.
- Photography: full-bleed cover/divider only; otherwise framed in a 6-col block with a 1 px hairline border.
- No illustrations, no AI-stock vectors, no emoji as content.

---

## 9. Source references (for the curious)

- WIRED design system on getdesign.md — source for the broadsheet density model, mono-uppercase kicker, ink-on-paper hierarchy, single-accent restraint.
- Stripe design system on getdesign.md — source for the weight-300 body elegance and the *restrained* accent treatment for KPI emphasis.

These were used as **principle sources only**; no logos, brand colors, brand fonts, or proprietary visuals were copied. The Pretendard typeface is mandated by the user. The accent hex (`#1E3A8A`) is a generic ink-blue, chosen to be brand-neutral and to print well in grayscale.
