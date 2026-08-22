#!/usr/bin/env python3
import sys
from pathlib import Path


AGENT_ENTRY_FILES = ("AGENTS.md", "CLAUDE.md")
AGENT_ENTRY_SOFT_LIMIT = 180
AGENT_ENTRY_HARD_LIMIT = 250


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


def check_agent_entries(repo_root: Path, errors: list[str], warnings: list[str]) -> None:
    bodies: dict[str, str] = {}

    for relative_path in AGENT_ENTRY_FILES:
        full_path = repo_root / relative_path
        if not full_path.is_file():
            errors.append(f"missing Agent root entry: {relative_path}")
            continue

        content = full_path.read_text(encoding="utf-8")
        lines = line_count(content)
        if lines > AGENT_ENTRY_HARD_LIMIT:
            errors.append(
                f"{relative_path}: Agent root entry has {lines} lines, "
                f"over {AGENT_ENTRY_HARD_LIMIT} line hard limit"
            )
        elif lines > AGENT_ENTRY_SOFT_LIMIT:
            warnings.append(
                f"{relative_path}: Agent root entry has {lines} lines, "
                f"over {AGENT_ENTRY_SOFT_LIMIT} line soft limit; "
                "move task-specific detail into docs"
            )

        parts = content.split("\n", 3)
        if len(parts) < 4:
            errors.append(
                f"{relative_path}: Agent root entry must have a title, blank line, "
                "intro line, and shared body"
            )
            continue
        bodies[relative_path] = parts[3]

    if len(bodies) == len(AGENT_ENTRY_FILES):
        agents_body = bodies["AGENTS.md"]
        claude_body = bodies["CLAUDE.md"]
        if agents_body != claude_body:
            errors.append("AGENTS.md and CLAUDE.md must match exactly from line 4")


def main() -> int:
    repo_root = Path(sys.argv[1]).resolve() if len(sys.argv) > 1 else Path(__file__).resolve().parents[1]
    errors: list[str] = []
    warnings: list[str] = []

    check_agent_entries(repo_root, errors, warnings)

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
