# assets/

Place static resources used by the PPT design system here.

## Recommended layout

```
assets/
├── README.md                  ← this file
├── pretendard/                ← (optional) local Pretendard font files
│   ├── Pretendard-Regular.otf       (weight 400)
│   ├── Pretendard-Medium.otf        (weight 500)
│   ├── Pretendard-SemiBold.otf      (weight 600)
│   └── Pretendard-Bold.otf          (weight 700)
├── icons/                     ← (optional) project-specific icon set
│   └── *.svg                  ← 1.5px stroke, 24×24, monochrome only
└── samples/                   ← (optional) reference output PPTX/HTML files
    └── *.pptx
```

## Pretendard

The skill mandates Pretendard for **all** slide text. If the system rendering the PPTX has Pretendard installed, the file will display correctly. If not, install it from:

- Open-source release: <https://github.com/orioncactus/pretendard>
- Web `@font-face` (used by the HTML fallback): the CDN URL embedded in `references/slide-layout-rules.md`

For environments where users may not have Pretendard installed, drop the four OTF files listed above into `assets/pretendard/` and embed them into the `.pptx` (python-pptx supports embedded fonts via the underlying OOXML; for hard reliability, pre-render any heading text as outlines using the optional helper documented in `references/slide-layout-rules.md`).

## Icons

When a deck calls for icons, pick **one** monochrome stroke set and reuse it across the deck. Recommended open-source families that match the system's tone:

- Tabler Icons (1.5 px stroke, 24×24) — the closest natural fit
- Lucide (1.5–2 px stroke) — also acceptable
- Heroicons "outline" — heavier stroke; use only when Lucide/Tabler unavailable

Never mix sets in a single deck.

## Samples

If you want a starting `.pptx` to inspect the system in PowerPoint or Keynote, generate one with the scaffold in `SKILL.md` and drop it here. The skill does not depend on a sample file existing — this directory is purely a convenience for human inspection.

## What does NOT belong here

- Brand logos, customer logos, or any third-party trademarked visual.
- Stock photography.
- Decorative gradients, illustrations, or "AI-generated" cover art.

The system is intentionally restrained. Adding decoration here will tempt slide generation away from the design rules.
