#!/usr/bin/env python3
import sys
from pathlib import Path


def doc_kind(relative_path: str) -> str:
    if (
        relative_path == "docs/README.md"
        or relative_path == "docs/planning/current.md"
        or relative_path == "docs/planning/daily-start.md"
        or (relative_path.startswith("docs/") and relative_path.endswith("/README.md"))
    ):
        return "entry"
    if relative_path.startswith("docs/archive/"):
        return "archive"
    if relative_path.startswith("docs/devlogs/"):
        return "devlog"
    if relative_path.startswith("docs/reference/"):
        return "reference"
    return "active"


def line_count(content: str) -> int:
    if not content:
        return 0
    count = len(content.split("\n"))
    if content.endswith("\n"):
        count -= 1
    return count


def main() -> int:
    repo_root = Path(sys.argv[1]).resolve() if len(sys.argv) > 1 else Path(__file__).resolve().parents[1]
    errors: list[str] = []
    warnings: list[str] = []

    for full_path in sorted((repo_root / "docs").rglob("*.md")):
        relative_path = full_path.relative_to(repo_root).as_posix()
        content = full_path.read_text(encoding="utf-8")
        lines = line_count(content)
        chars = len(content)
        kind = doc_kind(relative_path)

        if kind == "entry":
            if lines > 120:
                errors.append(f"{relative_path}: entry document has {lines} lines, over 120 line hard limit")
            if chars > 6000:
                warnings.append(
                    f"{relative_path}: entry document has {chars} chars, over 6000 char budget; "
                    "trim detail or link to source documents"
                )
        elif kind == "active":
            if lines > 280:
                warnings.append(
                    f"{relative_path}: active document has {lines} lines, over 280 line soft limit; "
                    "split into overview and child documents"
                )
        elif kind == "devlog":
            if lines > 350:
                warnings.append(
                    f"{relative_path}: development log has {lines} lines, over 350 line soft limit; "
                    "tighten the summary or split long retrospectives"
                )
        elif kind == "reference":
            if lines > 350:
                warnings.append(
                    f"{relative_path}: reference document has {lines} lines, over 350 line soft limit; "
                    "split by topic or move raw material to archive"
                )

    if warnings:
        print("Documentation budget warnings:", file=sys.stderr)
        for warning in warnings:
            print(warning, file=sys.stderr)

    if errors:
        for error in errors:
            print(error, file=sys.stderr)
        return 1

    if warnings:
        print("Documentation budget check passed with warnings.")
    else:
        print("Documentation budget check passed.")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
