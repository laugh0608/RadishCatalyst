#!/usr/bin/env python3
"""Dependency-free RadishCatalyst repository governance checks."""

from __future__ import annotations

import argparse
import json
import re
import subprocess
import sys
from pathlib import Path
from urllib.parse import unquote


REPO_ROOT = Path(__file__).resolve().parents[1]
MAX_PATH_LENGTH = 180
MAX_FILE_BYTES = 10 * 1024 * 1024
FILE_SIZE_LIMITS = {
    "client/assets/fonts/NotoSansSC-wght.ttf": 20 * 1024 * 1024,
}

REQUIRED_FILES = (
    ".editorconfig",
    ".gitattributes",
    ".gitignore",
    ".github/ISSUE_TEMPLATE/bug-report.yml",
    ".github/ISSUE_TEMPLATE/change-proposal.yml",
    ".github/ISSUE_TEMPLATE/config.yml",
    ".github/PULL_REQUEST_TEMPLATE.md",
    ".github/rulesets/README.md",
    ".github/rulesets/master-protection.json",
    ".github/workflows/pr-check.yml",
    ".github/workflows/release-check.yml",
    "AGENTS.md",
    "CLAUDE.md",
    "CODE_OF_CONDUCT.md",
    "CONTRIBUTING.md",
    "LICENSE",
    "README.md",
    "SECURITY.md",
    "docs/README.md",
    "docs/adr/0001-branch-and-pr-governance.md",
    "docs/planning/current.md",
    "docs/process/agent-collaboration.md",
    "docs/process/image-generation-and-review-workflow.md",
    "scripts/check-repo.ps1",
    "scripts/check-repo.py",
    "scripts/check-repo.sh",
    "scripts/tests/test_check_repo.py",
    "scripts/tests/test_check_docs.py",
)

FORBIDDEN_DIRECTORY_NAMES = {"__pycache__", "node_modules"}
CONVENTIONAL_COMMIT = re.compile(
    r"^(feat|fix|docs|refactor|test|chore|ci|build|perf|revert)"
    r"(\([a-z0-9._/-]+\))?!?: .+"
)
ALLOWED_MERGE_COMMIT = re.compile(
    r"^Merge (pull request|branch|remote-tracking branch)"
)
MARKDOWN_LINK = re.compile(
    r"!?\[[^\]]*\]\(([^)\s]+)(?:\s+['\"][^'\"]*['\"])?\)"
)


def git(repo_root: Path, *args: str) -> subprocess.CompletedProcess[str]:
    return subprocess.run(
        ["git", *args],
        cwd=repo_root,
        check=False,
        capture_output=True,
        text=True,
    )


def repository_files(repo_root: Path) -> list[Path]:
    result = git(repo_root, "ls-files", "--cached", "--others", "--exclude-standard", "-z")
    if result.returncode != 0:
        raise RuntimeError(result.stderr.strip() or "git ls-files failed")
    return sorted(
        (repo_root / item for item in result.stdout.split("\0") if item),
        key=lambda path: path.as_posix(),
    )


def relative(repo_root: Path, path: Path) -> str:
    return path.relative_to(repo_root).as_posix()


def check_required_files(repo_root: Path, errors: list[str]) -> None:
    for item in REQUIRED_FILES:
        if not (repo_root / item).is_file():
            errors.append(f"missing required file: {item}")


def check_paths_and_sizes(repo_root: Path, paths: list[Path], errors: list[str]) -> None:
    for path in paths:
        name = relative(repo_root, path)
        parts = set(path.relative_to(repo_root).parts)
        if len(name) > MAX_PATH_LENGTH:
            errors.append(f"path exceeds {MAX_PATH_LENGTH} characters: {name}")
        size_limit = FILE_SIZE_LIMITS.get(name, MAX_FILE_BYTES)
        if path.is_file() and path.stat().st_size > size_limit:
            errors.append(f"file exceeds {size_limit // (1024 * 1024)} MiB: {name}")
        if path.name in {".DS_Store", "Thumbs.db", "Desktop.ini"}:
            errors.append(f"operating-system metadata must not be committed: {name}")
        if parts.intersection(FORBIDDEN_DIRECTORY_NAMES):
            errors.append(f"generated dependency or cache directory must not be committed: {name}")
        if path.name == ".env" or (
            path.name.startswith(".env.") and not path.name.endswith(".example")
        ):
            errors.append(f"environment file must not be committed: {name}")


def check_json_files(repo_root: Path, paths: list[Path], errors: list[str]) -> None:
    for path in paths:
        if not path.is_file() or path.suffix.lower() != ".json":
            continue
        try:
            json.loads(path.read_text(encoding="utf-8"))
        except (UnicodeDecodeError, json.JSONDecodeError) as exc:
            errors.append(f"invalid JSON: {relative(repo_root, path)}: {exc}")


def check_markdown_links(repo_root: Path, paths: list[Path], errors: list[str]) -> None:
    resolved_root = repo_root.resolve()
    for path in paths:
        if not path.is_file() or path.suffix.lower() != ".md":
            continue
        if relative(repo_root, path).startswith("docs/archive/"):
            continue
        text = path.read_text(encoding="utf-8")
        for match in MARKDOWN_LINK.finditer(text):
            target = unquote(match.group(1))
            if target.startswith(("#", "/", "http://", "https://", "mailto:")):
                continue
            target = target.split("#", 1)[0].split("?", 1)[0]
            if not target:
                continue
            resolved = (path.parent / target).resolve()
            try:
                resolved.relative_to(resolved_root)
            except ValueError:
                errors.append(
                    f"relative link escapes repository: {relative(repo_root, path)} -> {target}"
                )
                continue
            if not resolved.exists():
                errors.append(
                    f"broken relative link: {relative(repo_root, path)} -> {target}"
                )


def check_issue_templates(repo_root: Path, errors: list[str]) -> None:
    contracts = {
        ".github/ISSUE_TEMPLATE/config.yml": (
            "blank_issues_enabled: false",
            "RadishCatalyst/security/policy",
        ),
        ".github/ISSUE_TEMPLATE/bug-report.yml": (
            "Private Vulnerability Reporting",
            "最小复现步骤",
            "未脱敏存档",
        ),
        ".github/ISSUE_TEMPLATE/change-proposal.yml": (
            "验证计划与失败判据",
            "开发决策闸门",
            "SECURITY.md",
        ),
    }
    for name, fragments in contracts.items():
        path = repo_root / name
        if not path.is_file():
            continue
        text = path.read_text(encoding="utf-8")
        for fragment in fragments:
            if fragment not in text:
                errors.append(f"{name} is missing contract fragment: {fragment}")


def find_rule(rules: list[object], rule_type: str) -> dict[str, object] | None:
    for rule in rules:
        if isinstance(rule, dict) and rule.get("type") == rule_type:
            return rule
    return None


def check_ruleset_contract(repo_root: Path, errors: list[str]) -> None:
    path = repo_root / ".github/rulesets/master-protection.json"
    if not path.is_file():
        return
    try:
        ruleset = json.loads(path.read_text(encoding="utf-8"))
    except json.JSONDecodeError:
        return

    if ruleset.get("target") != "branch" or ruleset.get("enforcement") != "active":
        errors.append("master ruleset must be an active branch ruleset")
    include = ruleset.get("conditions", {}).get("ref_name", {}).get("include", [])
    if sorted(include) != ["refs/heads/main", "refs/heads/master"]:
        errors.append("master ruleset must cover refs/heads/master and refs/heads/main")

    rules = ruleset.get("rules")
    if not isinstance(rules, list):
        errors.append("master ruleset must define a rules array")
        return
    for required_type in ("deletion", "non_fast_forward", "pull_request", "required_status_checks"):
        if find_rule(rules, required_type) is None:
            errors.append(f"master ruleset is missing rule: {required_type}")

    pull_request = find_rule(rules, "pull_request")
    if pull_request is not None:
        parameters = pull_request.get("parameters", {})
        if parameters.get("allowed_merge_methods") != ["merge", "rebase"]:
            errors.append("master ruleset must allow merge and rebase, in that order")
        if parameters.get("required_review_thread_resolution") is not True:
            errors.append("master ruleset must require review thread resolution")

    checks = find_rule(rules, "required_status_checks")
    if checks is not None:
        parameters = checks.get("parameters", {})
        contexts = [
            item.get("context")
            for item in parameters.get("required_status_checks", [])
            if isinstance(item, dict)
        ]
        if contexts != ["Repo Hygiene"]:
            errors.append("master ruleset must require only Repo Hygiene")
        if parameters.get("strict_required_status_checks_policy") is not True:
            errors.append("master ruleset must require the branch to be up to date")


def check_workflow_contract(repo_root: Path, errors: list[str]) -> None:
    contracts = {
        ".github/workflows/pr-check.yml": (
            "pull_request:",
            "      - dev",
            "      - master",
            "      - main",
            "persist-credentials: false",
            "./scripts/check-repo.sh --base-ref",
        ),
        ".github/workflows/release-check.yml": (
            "name: Release Checks",
            "persist-credentials: false",
            "./scripts/check-repo.sh",
        ),
    }
    for name, fragments in contracts.items():
        path = repo_root / name
        if not path.is_file():
            continue
        text = path.read_text(encoding="utf-8")
        for fragment in fragments:
            if fragment not in text:
                errors.append(f"{name} is missing contract fragment: {fragment.strip()}")
        for forbidden in ("pull_request_target:", "workflow_run:"):
            if forbidden in text:
                errors.append(f"{name} must not use privileged trigger: {forbidden}")


def check_pr_template_contract(repo_root: Path, errors: list[str]) -> None:
    path = repo_root / ".github/PULL_REQUEST_TEMPLATE.md"
    if not path.is_file():
        return
    text = path.read_text(encoding="utf-8")
    for fragment in (
        "目标分支：`dev` / `master` / `main`",
        "docs/planning/current.md",
        "明确非目标",
        "未验证内容",
        "回滚方式",
        "`origin/master` / `origin/main` 回流到 `dev`",
    ):
        if fragment not in text:
            errors.append(f"PR template is missing project boundary: {fragment}")


def check_agent_contract(repo_root: Path, errors: list[str]) -> None:
    for name in ("AGENTS.md", "CLAUDE.md"):
        path = repo_root / name
        if not path.is_file():
            continue
        text = path.read_text(encoding="utf-8")
        for fragment in (
            "./scripts/check-repo.sh",
            "pwsh ./scripts/check-repo.ps1",
            "docs/process/agent-collaboration.md",
            "docs/process/image-generation-and-review-workflow.md",
        ):
            if fragment not in text:
                errors.append(f"{name} is missing Agent root contract: {fragment}")


def check_diff(repo_root: Path, base_ref: str | None, errors: list[str]) -> None:
    commands: list[tuple[str, ...]] = []
    if base_ref:
        if git(repo_root, "rev-parse", "--verify", base_ref).returncode != 0:
            errors.append(f"base ref does not resolve: {base_ref}")
            return
        commands.append(("diff", "--check", f"{base_ref}...HEAD"))
    else:
        commands.extend((("diff", "--check"), ("diff", "--cached", "--check")))

    for command in commands:
        result = git(repo_root, *command)
        if result.returncode != 0:
            detail = (result.stdout + result.stderr).strip()
            errors.append(f"git {' '.join(command)} failed: {detail}")


def is_allowed_commit_subject(subject: str) -> bool:
    return bool(CONVENTIONAL_COMMIT.fullmatch(subject) or ALLOWED_MERGE_COMMIT.match(subject))


def check_commit_messages(repo_root: Path, base_ref: str | None, errors: list[str]) -> None:
    if not base_ref:
        return
    result = git(repo_root, "log", "--format=%H%x09%s", f"{base_ref}...HEAD")
    for line in result.stdout.splitlines():
        commit, _, subject = line.partition("\t")
        if not is_allowed_commit_subject(subject):
            errors.append(f"non-conventional commit subject: {commit[:12]} {subject}")


def run_subcheck(repo_root: Path, label: str, args: list[str], errors: list[str]) -> None:
    result = subprocess.run(
        args,
        cwd=repo_root,
        check=False,
        capture_output=True,
        text=True,
    )
    if result.returncode != 0:
        detail = (result.stdout + result.stderr).strip()
        errors.append(f"{label} failed: {detail}")


def run_existing_checks(repo_root: Path, errors: list[str]) -> None:
    checks = (
        ("text hygiene", [sys.executable, "scripts/check-text-files.py", str(repo_root)]),
        ("documentation budget", [sys.executable, "scripts/check-docs.py", str(repo_root)]),
        ("client static data", [sys.executable, "scripts/check-client-data.py", str(repo_root)]),
        ("client scene references", [sys.executable, "scripts/check-client-scenes.py", str(repo_root)]),
        (
            "repository checker tests",
            [sys.executable, "-m", "unittest", "discover", "-s", "scripts/tests", "-p", "test_*.py"],
        ),
    )
    for label, args in checks:
        run_subcheck(repo_root, label, args, errors)


def parse_args() -> argparse.Namespace:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--base-ref", help="optional PR base commit/ref")
    return parser.parse_args()


def main() -> int:
    args = parse_args()
    errors: list[str] = []
    try:
        paths = repository_files(REPO_ROOT)
    except RuntimeError as exc:
        print(f"repository baseline failed: {exc}", file=sys.stderr)
        return 1

    check_required_files(REPO_ROOT, errors)
    check_paths_and_sizes(REPO_ROOT, paths, errors)
    check_json_files(REPO_ROOT, paths, errors)
    check_markdown_links(REPO_ROOT, paths, errors)
    check_issue_templates(REPO_ROOT, errors)
    check_ruleset_contract(REPO_ROOT, errors)
    check_workflow_contract(REPO_ROOT, errors)
    check_pr_template_contract(REPO_ROOT, errors)
    check_agent_contract(REPO_ROOT, errors)
    check_diff(REPO_ROOT, args.base_ref, errors)
    check_commit_messages(REPO_ROOT, args.base_ref, errors)
    run_existing_checks(REPO_ROOT, errors)

    if errors:
        print("RadishCatalyst repository baseline failed:", file=sys.stderr)
        for error in errors:
            print(f"- {error}", file=sys.stderr)
        return 1

    print(f"RadishCatalyst repository baseline passed ({len(paths)} files checked).")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
