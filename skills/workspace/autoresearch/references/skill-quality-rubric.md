# Skill Quality Rubric

Score each dimension from 1 to 5.

## Freshness

1. References obsolete tools or paths.
3. Mostly current, with a few stale details.
5. Uses current tool names, paths, APIs, and workflow assumptions.

## Coverage

1. Handles only the happy path.
3. Covers normal workflow plus some edge cases.
5. Covers setup, execution, verification, failures, and handoff.

## Trigger Quality

1. Vague, too broad, or missing likely user wording.
3. Understandable but weak on boundaries or synonyms.
5. Clear trigger phrases, negative boundaries, and overlap guidance.

## Structure

1. Bloated `SKILL.md`, missing references, or broken paths.
3. Usable but longer than needed.
5. Lean `SKILL.md` with direct references, scripts, and assets only when useful.

## Examples

1. No concrete prompts or outputs.
3. Some examples but incomplete edge cases.
5. Includes representative happy path, boundary, and failure examples.

## Priority

Start with skills that score low on trigger quality or structure, because those failures prevent the skill from being selected or followed correctly.

