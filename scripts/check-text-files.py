#!/usr/bin/env python3
import subprocess
import sys
from pathlib import Path


TEXT_EXTENSIONS = {
    ".cs", ".gd", ".gdshader", ".ts", ".tsx", ".js", ".jsx", ".rs", ".py",
    ".json", ".yaml", ".yml", ".toml", ".ini", ".cfg", ".xml", ".csproj",
    ".fsproj", ".props", ".targets", ".sln", ".godot", ".tscn", ".tres",
    ".md", ".txt", ".csv", ".ps1", ".sh", ".bat", ".cmd", ".gitattributes",
    ".gitignore", ".editorconfig", ".dockerignore", ".svg", ".gltf",
}
SOURCE_EXTENSIONS = {".cs", ".gd", ".ts", ".tsx", ".js", ".jsx", ".rs", ".py", ".ps1", ".sh"}
SKIP_TRAILING_WHITESPACE_EXTENSIONS = {".md", ".csv"}


def repository_files(repo_root: Path) -> list[Path]:
    result = subprocess.run(
        ["git", "ls-files", "--cached", "--others", "--exclude-standard"],
        cwd=repo_root,
        text=True,
        capture_output=True,
        check=False,
    )
    if result.returncode == 0 and result.stdout.strip():
        return [Path(line) for line in result.stdout.splitlines() if line.strip()]

    return [
        path.relative_to(repo_root)
        for path in repo_root.rglob("*")
        if path.is_file() and ".git" not in path.relative_to(repo_root).parts
    ]


def is_text_file(relative_path: Path) -> bool:
    name = relative_path.name.lower()
    suffix = relative_path.suffix.lower()
    return name in TEXT_EXTENSIONS or suffix in TEXT_EXTENSIONS


def main() -> int:
    repo_root = Path(sys.argv[1]).resolve() if len(sys.argv) > 1 else Path(__file__).resolve().parents[1]
    errors: list[str] = []

    for relative_path in repository_files(repo_root):
        if not is_text_file(relative_path):
            continue

        full_path = repo_root / relative_path
        if not full_path.is_file():
            continue

        data = full_path.read_bytes()
        if not data:
            continue

        display_path = relative_path.as_posix()
        if data.startswith(b"\xef\xbb\xbf"):
            errors.append(f"{display_path}: contains UTF-8 BOM")
            continue

        try:
            content = data.decode("utf-8")
        except UnicodeDecodeError:
            errors.append(f"{display_path}: is not valid UTF-8")
            continue

        if "\r" in content:
            errors.append(f"{display_path}: contains CR or CRLF line endings")

        if not content.endswith("\n"):
            errors.append(f"{display_path}: missing final newline")

        suffix = relative_path.suffix.lower()
        if suffix not in SKIP_TRAILING_WHITESPACE_EXTENSIONS:
            for index, line in enumerate(content.split("\n"), start=1):
                if line.endswith(" ") or line.endswith("\t"):
                    errors.append(f"{display_path}:{index}: trailing whitespace")
                    break

        if suffix in SOURCE_EXTENSIONS:
            line_count = len(content.split("\n"))
            if content.endswith("\n"):
                line_count -= 1
            if line_count > 1500:
                errors.append(f"{display_path}: source file has {line_count} lines, over 1500 line hard limit")

    if errors:
        for error in errors:
            print(error, file=sys.stderr)
        return 1

    print("Repo hygiene passed.")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
