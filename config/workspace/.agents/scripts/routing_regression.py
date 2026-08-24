#!/usr/bin/env python
"""
Skill routing regression runner for AGENTS.md.

Usage:
  python .agents/scripts/routing_regression.py
  python .agents/scripts/routing_regression.py --verbose
  python .agents/scripts/routing_regression.py --cases path/to/cases.json
"""

from __future__ import annotations

import argparse
import json
import re
import sys
from dataclasses import dataclass
from pathlib import Path
from typing import Dict, Iterable, List, Optional, Sequence, Tuple


SECTION_ORDER: Sequence[str] = (
    "Extension-Based Routing (Highest Priority)",
    "Intent-Based Routing",
    "Planning and Execution Routing",
    "Academic Composite Routing",
    "Research and Academic Routing",
)


@dataclass
class Rule:
    section: str
    raw_bullet: str
    groups: List[List[str]]
    skills: List[str]
    line_number: int


@dataclass
class RouteResult:
    skills: List[str]
    reason: str
    matched_rule: Optional[Rule]


def normalize(text: str) -> str:
    text = text.lower()
    text = text.replace("’", "'")
    text = text.replace("`", "")
    # Keep dots and hyphens to preserve extensions and skill names.
    text = re.sub(r"[^0-9a-zA-Z\uac00-\ud7a3\.\-\_\+\s]", " ", text)
    text = re.sub(r"\s+", " ", text).strip()
    return text


def unique_in_order(items: Iterable[str]) -> List[str]:
    seen = set()
    out: List[str] = []
    for item in items:
        if item not in seen:
            out.append(item)
            seen.add(item)
    return out


def clean_phrase(value: str) -> str:
    value = value.strip().strip(",").strip()
    value = value.strip("()")
    value = re.sub(r"\s+", " ", value).strip()
    return value


def extract_group_phrases(group_text: str) -> List[str]:
    phrases: List[str] = []
    segments = [seg.strip() for seg in group_text.split(",") if seg.strip()]

    for segment in segments:
        quoted = re.findall(r'"([^"]+)"|`([^`]+)`', segment)
        for q1, q2 in quoted:
            token = clean_phrase(q1 or q2)
            if token:
                phrases.append(token)

        remainder = re.sub(r'"[^"]*"|`[^`]*`', "", segment)
        remainder = clean_phrase(remainder)
        if remainder and remainder.lower() not in {"and", "or"}:
            phrases.append(remainder)

    if not phrases:
        fallback = clean_phrase(group_text)
        if fallback:
            phrases.append(fallback)

    return unique_in_order([p for p in phrases if p])


def parse_rule_from_bullet(section: str, bullet_line: str, line_number: int) -> Optional[Rule]:
    if "->" not in bullet_line:
        return None

    left, right = bullet_line.split("->", 1)
    left = left.lstrip("-").strip()
    right = right.strip()

    skills = re.findall(r"`([^`]+)`", right)
    if not skills:
        return None

    raw_groups = [grp.strip() for grp in left.split("+") if grp.strip()]
    groups: List[List[str]] = []
    for raw_group in raw_groups:
        phrases = extract_group_phrases(raw_group)
        if phrases:
            groups.append(phrases)

    if not groups:
        return None

    return Rule(
        section=section,
        raw_bullet=bullet_line.strip(),
        groups=groups,
        skills=unique_in_order(skills),
        line_number=line_number,
    )


def parse_agents_rules(agents_path: Path) -> Dict[str, List[Rule]]:
    lines = agents_path.read_text(encoding="utf-8").splitlines()
    section = ""
    rules: Dict[str, List[Rule]] = {name: [] for name in SECTION_ORDER}

    for index, line in enumerate(lines, start=1):
        if line.startswith("## "):
            section = line[3:].strip()
            continue
        if not line.startswith("- "):
            continue
        if section not in rules:
            continue
        rule = parse_rule_from_bullet(section, line, index)
        if rule:
            rules[section].append(rule)

    return rules


def phrase_matches(prompt_norm: str, phrase: str) -> bool:
    phrase_norm = normalize(phrase)
    if not phrase_norm:
        return False
    return phrase_norm in prompt_norm


def rule_matches(prompt_norm: str, rule: Rule) -> bool:
    for alternatives in rule.groups:
        if not any(phrase_matches(prompt_norm, phrase) for phrase in alternatives):
            return False
    return True


def rule_match_score(prompt_norm: str, rule: Rule) -> Optional[int]:
    score = 0
    for alternatives in rule.groups:
        matched_lengths = [len(normalize(p)) for p in alternatives if phrase_matches(prompt_norm, p)]
        if not matched_lengths:
            return None
        score += max(matched_lengths)
    # Strongly prefer rules with explicit AND groups (e.g., deploy + provider).
    score += max(0, len(rule.groups) - 1) * 1000
    return score


def discover_local_skill_names(workspace_root: Path) -> List[str]:
    skills_dir = workspace_root / "skills"
    names: List[str] = []
    if not skills_dir.exists():
        return names

    for child in skills_dir.iterdir():
        if not child.is_dir():
            continue
        if child.name.startswith("."):
            continue
        # Directory names are mostly underscore style; normalize to hyphen style.
        names.append(child.name.replace("_", "-"))
    return unique_in_order(names)


def find_explicit_skill_mentions(prompt: str, prompt_norm: str, candidate_skills: Sequence[str]) -> List[str]:
    prompt_raw_lower = prompt.lower()
    hits: List[Tuple[int, str]] = []

    for skill in candidate_skills:
        skill_norm = normalize(skill)
        if not skill_norm:
            continue

        # Highest confidence: explicit wrappers.
        if re.search(rf"`\s*{re.escape(skill_norm)}\s*`", prompt_raw_lower):
            pos = prompt_raw_lower.find(skill_norm)
            hits.append((pos, skill))
            continue
        if re.search(rf"@{re.escape(skill_norm)}(?![0-9a-zA-Z_\-])", prompt_raw_lower):
            pos = prompt_raw_lower.find(skill_norm)
            hits.append((pos, skill))
            continue

        # Contextual explicit mention: "<skill> 스킬", "skill <skill>", etc.
        token = rf"(?<![0-9a-zA-Z\uac00-\ud7a3_\-]){re.escape(skill_norm)}(?![0-9a-zA-Z\uac00-\ud7a3_\-])"
        suffix_pattern = rf"{token}\s*(스킬[0-9a-zA-Z\uac00-\ud7a3_\-]*|skill[0-9a-zA-Z_\-]*)"
        prefix_pattern = rf"(스킬[0-9a-zA-Z\uac00-\ud7a3_\-]*|skill[0-9a-zA-Z_\-]*)\s*{token}"

        if re.search(suffix_pattern, prompt_norm) or re.search(prefix_pattern, prompt_norm):
            pos = prompt_norm.find(skill_norm)
            hits.append((pos, skill))

    hits.sort(key=lambda item: item[0])
    return unique_in_order([skill for _, skill in hits])


class Router:
    def __init__(self, rules: Dict[str, List[Rule]], explicit_candidates: Sequence[str]) -> None:
        self.rules = rules
        self.explicit_candidates = unique_in_order(explicit_candidates)

    def route(self, prompt: str) -> RouteResult:
        prompt_norm = normalize(prompt)

        explicit = find_explicit_skill_mentions(prompt, prompt_norm, self.explicit_candidates)
        if explicit:
            return RouteResult(
                skills=explicit,
                reason="explicit_skill_mention",
                matched_rule=None,
            )

        for section in SECTION_ORDER:
            matched: List[Tuple[int, Rule]] = []
            for rule in self.rules.get(section, []):
                score = rule_match_score(prompt_norm, rule)
                if score is not None:
                    matched.append((score, rule))

            if matched:
                # Policy alignment: choose the most specific rule when multiple match.
                best_score, best_rule = max(matched, key=lambda item: item[0])
                return RouteResult(
                    skills=best_rule.skills,
                    reason=f"matched_{section}_specificity_{best_score}",
                    matched_rule=best_rule,
                )

        return RouteResult(skills=[], reason="no_match", matched_rule=None)


def load_cases(path: Path) -> List[dict]:
    data = json.loads(path.read_text(encoding="utf-8"))
    if not isinstance(data, list):
        raise ValueError("cases JSON must be a list")
    return data


def evaluate_case(case: dict, result: RouteResult) -> Tuple[bool, str]:
    expected = case.get("expected", [])
    if not isinstance(expected, list):
        return False, "invalid_case_expected_field"
    mode = case.get("mode", "exact")
    expected = [str(x) for x in expected]

    actual = result.skills

    if mode == "exact":
        ok = actual == expected
    elif mode == "contains_all":
        ok = all(item in actual for item in expected)
    elif mode == "contains_any":
        ok = any(item in actual for item in expected)
    elif mode == "starts_with":
        ok = actual[: len(expected)] == expected
    else:
        return False, f"unknown_mode:{mode}"

    if ok:
        return True, "pass"
    return False, f"expected({mode})={expected}, actual={actual}"


def run(agents_path: Path, cases_path: Path, workspace_root: Path, verbose: bool) -> int:
    rules = parse_agents_rules(agents_path)
    rule_skills: List[str] = []
    for section in SECTION_ORDER:
        for rule in rules.get(section, []):
            rule_skills.extend(rule.skills)

    explicit_candidates = unique_in_order(rule_skills + discover_local_skill_names(workspace_root))
    router = Router(rules=rules, explicit_candidates=explicit_candidates)
    cases = load_cases(cases_path)

    total = 0
    failed = 0

    for case in cases:
        total += 1
        case_id = str(case.get("id", f"case-{total}"))
        prompt = str(case.get("prompt", ""))
        result = router.route(prompt)
        ok, message = evaluate_case(case, result)

        if verbose or not ok:
            print(f"[{'PASS' if ok else 'FAIL'}] {case_id}")
            print(f"  prompt: {prompt}")
            print(f"  routed: {result.skills} ({result.reason})")
            if result.matched_rule:
                print(
                    "  rule: "
                    f"{result.matched_rule.section}:L{result.matched_rule.line_number} "
                    f"{result.matched_rule.raw_bullet}"
                )
            if not ok:
                print(f"  detail: {message}")

        if not ok:
            failed += 1

    passed = total - failed
    print("")
    print(f"TOTAL={total}")
    print(f"PASSED={passed}")
    print(f"FAILED={failed}")
    print(f"PASS_RATE={(passed / total * 100.0):.1f}%" if total else "PASS_RATE=0.0%")

    return 0 if failed == 0 else 1


def main(argv: Optional[Sequence[str]] = None) -> int:
    parser = argparse.ArgumentParser(description="Run AGENTS.md skill routing regression tests")
    parser.add_argument(
        "--agents",
        type=Path,
        default=Path("AGENTS.md"),
        help="Path to AGENTS.md (default: AGENTS.md)",
    )
    parser.add_argument(
        "--cases",
        type=Path,
        default=Path(".agents/scripts/routing_cases.json"),
        help="Path to routing regression case file",
    )
    parser.add_argument(
        "--workspace-root",
        type=Path,
        default=Path("."),
        help="Workspace root used for local skill discovery",
    )
    parser.add_argument(
        "--verbose",
        action="store_true",
        help="Print all case results, not only failures",
    )
    args = parser.parse_args(argv)

    if not args.agents.exists():
        print(f"error: AGENTS file not found: {args.agents}", file=sys.stderr)
        return 2
    if not args.cases.exists():
        print(f"error: cases file not found: {args.cases}", file=sys.stderr)
        return 2

    return run(
        agents_path=args.agents,
        cases_path=args.cases,
        workspace_root=args.workspace_root,
        verbose=args.verbose,
    )


if __name__ == "__main__":
    raise SystemExit(main())
