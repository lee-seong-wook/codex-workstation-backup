---
name: figma-design-routing
description: Route Figma design inspection and design-to-code work. Use when the user provides a Figma URL, node id, design file, screenshot, or asks to implement a Figma design, extract layout/style tokens, compare UI to a design, or says "피그마" or "디자인 구현".
---

# Figma Design Routing

## Workflow

1. Use `tool_search` to check whether a Figma connector/tool is available.
2. If Figma access is unavailable, ask for a screenshot, exported assets, or a written spec. Do not pretend to inspect a Figma URL.
3. Extract concrete implementation facts: frame size, layout grid, spacing, typography, colors, components, variants, states, assets, and interaction notes.
4. For UI implementation, follow the repo's existing frontend stack and design system. Use `design-html` only when creating a standalone design artifact is appropriate.
5. Verify against the source by screenshot or visual comparison when possible.
