#!/usr/bin/env python3
"""Small log scanner for common error-handling smells."""

from __future__ import annotations

import re
import sys
from pathlib import Path


PATTERNS = {
    "bare except": re.compile(r"\bexcept\s*:", re.I),
    "swallowed error": re.compile(r"\b(pass|return\s+None)\b", re.I),
    "todo error handling": re.compile(r"\bTODO\b.*\b(error|exception|retry|logging)\b", re.I),
    "secret-like token": re.compile(r"(api[_-]?key|token|password|secret)\s*[:=]", re.I),
}


def scan(path: Path) -> int:
    count = 0
    for lineno, line in enumerate(path.read_text(encoding="utf-8", errors="replace").splitlines(), 1):
        for label, pattern in PATTERNS.items():
            if pattern.search(line):
                print(f"{path}:{lineno}: {label}: {line.strip()}")
                count += 1
    return count


def main(argv: list[str]) -> int:
    if len(argv) < 2:
        print("usage: error-analyzer.py <file> [<file> ...]", file=sys.stderr)
        return 2
    total = 0
    for arg in argv[1:]:
        path = Path(arg)
        if path.is_file():
            total += scan(path)
    return 1 if total else 0


if __name__ == "__main__":
    raise SystemExit(main(sys.argv))

