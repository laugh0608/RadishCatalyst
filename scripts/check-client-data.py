#!/usr/bin/env python3
import json
import re
import sys
from pathlib import Path
from typing import Any


DATA_FILES = [
    "items.json",
    "fluids.json",
    "recipes.json",
    "buildings.json",
    "equipment.json",
    "enemies.json",
    "regions.json",
    "map_objects.json",
    "pollution_types.json",
    "weather_types.json",
    "quests.json",
]
ID_PATTERN = re.compile(r"^[a-z]+[a-z0-9_]*\.[a-z0-9_]+$")
REFERENCE_PREFIXES_TO_SKIP = ("effect.", "drop.", "slice_", "world.")


def walk_values(value: Any):
    if isinstance(value, dict):
        for child in value.values():
            yield from walk_values(child)
    elif isinstance(value, list):
        for child in value:
            yield from walk_values(child)
    elif isinstance(value, str):
        yield value


def main() -> int:
    repo_root = Path(sys.argv[1]).resolve() if len(sys.argv) > 1 else Path(__file__).resolve().parents[1]
    data_root = repo_root / "client" / "data"
    errors: list[str] = []
    loaded: dict[str, dict[str, Any]] = {}
    definitions: dict[str, str] = {}

    for file_name in DATA_FILES:
        path = data_root / file_name
        relative_path = path.relative_to(repo_root).as_posix()
        if not path.is_file():
            errors.append(f"{relative_path}: missing data file")
            continue

        try:
            content = json.loads(path.read_text(encoding="utf-8"))
        except json.JSONDecodeError as error:
            errors.append(f"{relative_path}: invalid JSON: {error}")
            continue

        if "schema_version" not in content:
            errors.append(f"{relative_path}: missing schema_version")

        entries = content.get("entries")
        if not isinstance(entries, list) or not entries:
            errors.append(f"{relative_path}: missing entries")
            continue

        loaded[file_name] = content
        for entry in entries:
            if not isinstance(entry, dict):
                errors.append(f"{relative_path}: entry is not an object")
                continue
            entry_id = str(entry.get("id", "")).strip()
            if not entry_id:
                errors.append(f"{relative_path}: entry has empty id")
                continue
            if not ID_PATTERN.match(entry_id):
                errors.append(f"{relative_path}: invalid id format '{entry_id}'")
            if entry_id in definitions:
                errors.append(f"{relative_path}: duplicate id '{entry_id}'")
            else:
                definitions[entry_id] = relative_path

            for field in ("display_name_key", "description_key", "public_level"):
                if not str(entry.get(field, "")).strip():
                    errors.append(f"{relative_path}: '{entry_id}' missing {field}")

    for file_name, content in loaded.items():
        relative_path = (data_root / file_name).relative_to(repo_root).as_posix()
        for entry in content.get("entries", []):
            if not isinstance(entry, dict):
                continue
            source_id = str(entry.get("id", ""))
            for value in walk_values(entry):
                if value == source_id:
                    continue
                if "." not in value or value.startswith(REFERENCE_PREFIXES_TO_SKIP):
                    continue
                if ID_PATTERN.match(value) and value not in definitions:
                    errors.append(f"{relative_path}: '{source_id}' has unknown reference '{value}'")

    if errors:
        for error in errors:
            print(error, file=sys.stderr)
        return 1

    print("Client static data checks passed.")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
