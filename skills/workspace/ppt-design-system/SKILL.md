---
name: ppt-design-system
description: Turn PDFs, memos, notes, raw documents, or existing decks into polished editable 16:9 business presentations using a fixed Pretendard-only design system. Use this skill whenever the user asks for a deck, slides, presentation, PPT, PPTX, executive summary, consulting deck, strategy deck, report deck, or wants an existing presentation redesigned. Trigger on any of "make a deck," "PPT으로", "프레젠테이션", "슬라이드로 만들어", "executive summary," "redesign these slides," "convert this PDF/doc/memo to slides," even when the user does not say the word "design system." Slides must be 16:9, Pretendard-only, dense but clean, with consistent chapter-label / title / subtitle anchor positions on every slide.
---

# PPT Design System

A reusable design system that turns input content (PDF, doc, memo, raw notes, an existing deck) into a polished editable 16:9 business presentation. The full spec lives in `{{WORKSPACE_ROOT}}\PRESENTATION_SYSTEM.md`. This skill is the operating manual for following that spec.

## When this skill triggers

- "Make a deck/slides/presentation/PPT/PPTX from this PDF / document / memo / report."
- "Build an executive summary deck."
- "Redesign this deck — it looks AI-generated."
- "Build a consulting-style / startup-strategy / product-strategy deck."
- "이 문서로 PPT 만들어줘" / "발표 자료 만들어줘" / "슬라이드 정리해줘".
- Any request mentioning *deck, slides, presentation, PPT, .pptx*, even casually.

## The contract (non-negotiable, read every time)

1. **16:9 only.** Canvas: 13.333 in × 7.5 in. In python-pptx EMU: width `12192000`, height `6858000`. Never 4:3.
2. **Pretendard only.** Weights 400/500/600/700. No system fallback.
3. **Anchor positions are fixed** for chapter kicker, page number, top hairline, slide title, subtitle, bottom hairline, footer. Coordinates in `references/slide-layout-rules.md`.
4. **Density rule.** Content must reach ≥ 70% down the content zone (y ≥ 568 on a 1280×720 reference) on every non-exception slide. Empty lower halves are the #1 AI-deck tell.
5. **Single accent.** `#1E3A8A` (ink blue). Used ≤ 3 times per slide. Monochrome on neutrals everywhere else.
6. **Editable PPTX is the primary deliverable.** Use `python-pptx`. Fallback to HTML only if PPTX is impossible in the environment. Never deliver a flattened image.

## Workflow

Always follow these phases. Don't skip the planning phase even on small decks.

### Phase 1 — Read the input

- If a PDF: read it via the `pdf` skill or `pdfplumber` and capture each page's takeaway, key data, and any tables/figures.
- If a doc/memo/notes: identify thesis, supporting evidence, and asks/next steps.
- If an existing deck: extract slide-by-slide *content only*; throw out their visual design.
- Build a mental outline before opening any tooling.

### Phase 2 — Plan the deck (do this with the user)

Decide and confirm:

- **Audience** (executive / board / customer / investor / internal team).
- **Deck type** (executive summary / consulting / startup-strategy / report-style).
- **Target length** (typical: exec summary 8–12, consulting 15–25, strategy 20–35, report 25–50).
- **Outline:** title slide → 2–4 section dividers → content slides → closing/next-steps.

Write the outline as a numbered list with one-sentence titles that already follow the writing-style rules in `references/writing-style.md` (titles are insights, not topics).

### Phase 3 — Map content to templates

For each outline item, choose exactly one of the 13 templates listed in `references/slide-layout-rules.md`. Repeat the same template ≤ 2 times in a row. Diversity of templates is part of the polish.

### Phase 4 — Generate

- Default path: build a `.pptx` via python-pptx. Use the production scaffold below.
- Render every content slide with the fixed anchor frame (kicker / page # / top rule / title / subtitle / bottom rule / footer). Then place the template-specific content inside the content zone (y=200–664).
- Apply the density rule per slide before moving on. If content stops short, add a sidebar callout, sub-bullet, or footnote rather than leaving whitespace.

### Phase 5 — QA pass

Run the checklist in `PRESENTATION_SYSTEM.md` § 12. Common failures to look for:

- A slide ends visually at y < 568 → density violation.
- More than 3 accent uses on one slide.
- A title that names a topic instead of stating an insight.
- A chart with vertical gridlines, 3D, or shadow.
- A table with vertical rules.
- More than 5 distinct icon styles or any filled/emoji-style icons.

### Phase 6 — Deliver

Save the PPTX to the workspace folder (`{{WORKSPACE_ROOT}}\`). Provide a `computer://` link. Include a one-paragraph summary of what's in the deck — not a slide-by-slide retread.

## Production scaffold (python-pptx)

This is the canonical starting point. Adapt per deck, but never deviate from the fixed anchor coordinates or the type ramp.

```python
from pptx import Presentation
from pptx.util import Inches, Pt, Emu
from pptx.dml.color import RGBColor
from pptx.enum.shapes import MSO_SHAPE
from pptx.enum.text import PP_ALIGN

# Canvas: 16:9
W_EMU, H_EMU = 12192000, 6858000   # 13.333 x 7.5 inches
PX = W_EMU / 1280                  # 1 px in EMU on the 1280-px reference

def px(p): return Emu(int(p * PX))

INK        = RGBColor(0x11, 0x11, 0x11)
INK_SOFT   = RGBColor(0x1F, 0x1F, 0x1F)
MUTE       = RGBColor(0x4A, 0x4A, 0x4A)
HAIRLINE   = RGBColor(0xE6, 0xE4, 0xDD)
PAPER      = RGBColor(0xFA, 0xFA, 0xF7)
ACCENT     = RGBColor(0x1E, 0x3A, 0x8A)

FONT = "Pretendard"

prs = Presentation()
prs.slide_width  = W_EMU
prs.slide_height = H_EMU

def add_text(slide, x, y, w, h, text, *, size=12, weight=400, color=INK_SOFT,
             align=PP_ALIGN.LEFT, upper=False):
    tb = slide.shapes.add_textbox(px(x), px(y), px(w), px(h))
    tf = tb.text_frame
    tf.margin_left = tf.margin_right = 0
    tf.margin_top  = tf.margin_bottom = 0
    tf.word_wrap = True
    p = tf.paragraphs[0]
    p.alignment = align
    r = p.add_run()
    r.text = text.upper() if upper else text
    r.font.name = FONT
    r.font.size = Pt(size)
    r.font.bold = weight >= 600
    r.font.color.rgb = color
    return tb

def add_rule(slide, x, y, w, color=HAIRLINE):
    line = slide.shapes.add_shape(MSO_SHAPE.RECTANGLE, px(x), px(y), px(w), px(1))
    line.fill.solid(); line.fill.fore_color.rgb = color
    line.line.fill.background()

def add_frame(slide, *, kicker, page_num, footer="", title=None, subtitle=None):
    add_text(slide, 56,   48, 600, 16, kicker, size=11, weight=600,
             color=MUTE, upper=True)
    add_text(slide, 1124, 48,  100, 16, str(page_num), size=10, weight=500,
             color=RGBColor(0x9A,0x9A,0x9A), align=PP_ALIGN.RIGHT)
    add_rule(slide, 56, 88,  1168)
    if title:
        add_text(slide, 56, 104, 1168, 40, title, size=28, weight=700, color=INK)
    if subtitle:
        add_text(slide, 56, 152, 1168, 24, subtitle, size=16, weight=500, color=MUTE)
    add_rule(slide, 56, 672, 1168)
    if footer:
        add_text(slide, 56, 688, 1168, 16, footer, size=9, weight=500,
                 color=RGBColor(0x9A,0x9A,0x9A), upper=True)

def new_slide():
    s = prs.slides.add_slide(prs.slide_layouts[6])  # blank
    bg = s.background
    bg.fill.solid(); bg.fill.fore_color.rgb = PAPER
    return s

# Example: bullet-narrative content slide
s = new_slide()
add_frame(s, kicker="01 · MARKET CONTEXT", page_num=4,
          title="Enterprise demand outpaced SMB for the third quarter running",
          subtitle="Net new ARR was 71% enterprise, vs. a 58% Q1 baseline.",
          footer="SOURCE: INTERNAL FINANCE, Q3 2026 CLOSE")

# ... content blocks placed within y=200..664 ...

prs.save("deck.pptx")
```

When python-pptx is unavailable, fall back to the HTML scaffold in `references/slide-layout-rules.md` — same coordinates, same constraints.

## What to consult and when

| If you're about to… | Read this first |
|---|---|
| Pick a template for a slide | `references/slide-layout-rules.md` |
| Decide spacing, type sizes, colors | `references/design-reference.md` |
| Write a title or bullet | `references/writing-style.md` |
| Generate the deck end-to-end | `PRESENTATION_SYSTEM.md` (top-level spec) |

## Things to avoid (the "AI deck" tells)

- Empty lower 30–40% of slides ("balloon slides").
- Three different fonts. Or two. Pretendard only.
- Pastel-rounded clipart icon sets.
- Gradient blobs as background decoration.
- Title that restates the section name ("Market Overview") instead of the insight.
- "Thank you" slides with a giant emoji-style logo.
- Stock photography of diverse hands on a laptop.
- Charts with 3D, drop shadows, or rainbow palettes.
- Bullets that are full four-line sentences ending in periods.
- Same layout repeated for every single content slide.

## Output

Always save the final `.pptx` to `{{WORKSPACE_ROOT}}\`, share via `computer://` link. Brief one-paragraph summary only. Do not narrate slide-by-slide.
