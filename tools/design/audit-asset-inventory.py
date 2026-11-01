#!/usr/bin/env python3
"""Read-only asset inventory; reports occurrences, never proves safe deletion."""
import argparse
import ast
from collections import Counter, defaultdict
import csv
import hashlib
import json
from pathlib import Path
import re
import struct
import subprocess

ROOT = Path(__file__).resolve().parents[2]
EVIDENCE = ROOT / "tools/runtime-intake/design-references/2026-11-01-asset-inventory"
MEDIA = {".png", ".svg", ".glb", ".gltf", ".bin", ".ttf", ".woff", ".woff2",
         ".ogg", ".wav", ".mp3", ".blend", ".webp", ".jpg", ".jpeg", ".tres", ".ico"}
TEXT = {".gd", ".tscn", ".tres", ".godot", ".gdshader", ".py", ".mjs", ".js",
        ".html", ".css", ".json", ".sh", ".ps1", ".md", ".txt"}
WEB = "tools/visual-studies/web-topdown-3d/"
BASE_EXPORT = "tools/visual-studies/topdown-3d/production/export-web-assets.mjs"
SOURCE_LINKS = {
    "client/assets/sprites/slice/collector.png": "assets/art-intake/2026-08-05-batch12-support-device-native-normalization/collector_native_v1.png",
    "client/assets/sprites/slice/storage.png": "assets/art-intake/2026-08-05-batch12-support-device-native-normalization/storage_native_v1.png",
    "client/assets/sprites/slice/power_relay.png": "assets/art-intake/2026-08-05-batch12-support-device-native-normalization/power_relay_native_v2.png",
    "client/assets/sprites/slice/outpost_core_repaired.png": "assets/art-intake/2026-08-05-batch09-native-redraw/core_native_redraw_v1.png",
    "client/assets/portraits/protagonist_portraits.png": "assets/reference/protagonist-portrait-anchor.png",
}


def digest(path):
    return hashlib.sha256(path.read_bytes()).hexdigest()


def glb_metadata(path):
    raw = path.read_bytes()
    magic, version, length = struct.unpack_from("<4sII", raw)
    chunk_length, kind = struct.unpack_from("<II", raw, 12)
    if magic != b"glTF" or version != 2 or length != len(raw) or kind != 0x4E4F534A:
        raise ValueError("Invalid GLB header: " + str(path))
    data = json.loads(raw[20:20 + chunk_length])
    return {"nodes": [node.get("name", "") for node in data.get("nodes", [])],
            "images": len(data.get("images", [])), "textures": len(data.get("textures", [])),
            "materials": len(data.get("materials", [])),
            "normal_mapped_materials": sum("normalTexture" in material for material in data.get("materials", []))}


def classify(path):
    """Explicit current ownership; not inferred from a lack of references."""
    if path.startswith("client/assets/factory/"):
        folder = Path(path).parent.name
        group = "base" if folder == "factory" else folder
        return "factory-" + group, "experiment" if group == "refinement" else "production-3d"
    if path.startswith("client/assets/icons/"):
        return ("factory-icons", "production-3d") if Path(path).name.startswith("factory_") else ("slice-icons", "retained-2d")
    if path.startswith("client/assets/fonts/"):
        return "shared-font", "shared"
    if path.startswith("client/assets/themes/"):
        return "shared-and-slice-themes", "shared-review-per-file"
    if path.startswith("client/assets/ui/"):
        return "startup-ui", "shared"
    if path.startswith("client/assets/portraits/"):
        return "slice-portrait", "retained-2d"
    if path.startswith(("client/assets/sprites/slice/", "client/assets/tiles/slice/")):
        return "slice-world", "retained-2d"
    if path.startswith("client/assets/sprites/visual_studies/"):
        return "pixel-study-" + Path(path).parent.name, "experiment"
    if "demo_presentation_rebuild/" in path:
        return "legacy-presentation", "legacy-and-study-review"
    if "demo_first_screen/" in path:
        return "legacy-first-screen", "legacy-review"
    if "demo_crystal_workface/" in path:
        return "legacy-crystal-workface", "legacy-review"
    if path.startswith("assets/concept-art/"):
        return "concept-reference", "historical-reference"
    if path.startswith("assets/reference/visual-direction/"):
        return "slice-visual-targets", "historical-reference"
    if path.startswith("assets/reference/"):
        return "historical-anchors", "historical-reference"
    if path.startswith("tools/visual-studies/topdown-3d/production/assets/"):
        return "godot-production-reference", "experiment-source-copy"
    if path.startswith("tools/visual-studies/web-style/assets/"):
        return "web-style-reference", "experiment"
    if path in {"client/icon.svg", "client/default_bus_layout.tres"}:
        return "project-shell", "shared"
    raise ValueError("Unclassified asset; add an explicit ownership rule: " + path)


def dynamic_sites(path, family, texts):
    """Family candidates, deliberately not per-file runtime reachability."""
    sites = []
    rules = []
    if family.startswith("factory-") and family != "factory-icons":
        rules = [("client/scripts/factory/view.gd", "ASSET_ROOT"),
                 ("client/scripts/factory/device_preview.gd", "var path :=")]
        if family == "factory-refinement":
            rules = []
    elif family == "slice-world":
        rules = [("client/scripts/slice/slice_building_catalog.gd", "res://assets/sprites/slice/%s"),
                 ("client/scripts/slice/slice_conveyor.gd", "conveyor_in_%s"),
                 ("client/scripts/slice/slice_conveyor.gd", "conveyor_merge_in_%s"),
                 ("client/scripts/slice/slice_conveyor.gd", "conveyor_source_%s"),
                 ("client/scripts/slice/slice_conveyor.gd", "conveyor_sink_%s")]
    elif family.startswith("pixel-study-"):
        rules = [("client/scripts/visual_studies/industrial_volume_study.gd", "ASSET_ROOT"),
                 ("client/scripts/visual_studies/pipe_visual_path.gd", "ASSET_ROOT"),
                 ("client/scripts/visual_studies/raised_pipe_visual_path.gd", "RAISED_ASSETS"),
                 ("tools/visual-studies/web-style/server.mjs", "client/assets/sprites/visual_studies/")]
    elif family == "godot-production-reference":
        rules = [("tools/visual-studies/topdown-3d/production/view.gd", "assets/")]
    elif family == "web-style-reference":
        rules = [("tools/visual-studies/web-style/server.mjs", "assets/${name}.png")]
    for source, marker in rules:
        matches = [{"file": source, "line": i, "text": line.strip()}
                   for i, line in enumerate(texts[source].splitlines(), 1) if marker in line]
        if not matches:
            raise ValueError("Stale dynamic reference evidence: " + source + " " + marker)
        sites.extend(matches)
    return sites


def producer_candidates(family, path):
    if path in SOURCE_LINKS and family == "slice-world":
        name = "build_native_redraw.py" if path.endswith("outpost_core_repaired.png") else "build_support_device_normalization.py"
        return [str(Path(SOURCE_LINKS[path]).parent / name)]
    if family == "slice-portrait":
        return ["tools/normalize_slice_pack1.py"]
    if family == "factory-base" or family == "godot-production-reference":
        return [BASE_EXPORT]
    if family.startswith("factory-") and family not in {"factory-icons", "factory-base"}:
        name = family.removeprefix("factory-")
        return ["tools/factory-content/export-" + ("admission-asset" if name == "admission" else name + "-assets") + ".mjs"]
    if family == "factory-icons":
        return ["tools/factory-content/export-expansion-assets.mjs", "tools/factory-content/export-energy-assets.mjs"]
    studies = {"industrial_volume_v1": "industrial_volume_study", "transparent_pipe_v1": "pipe_visual_study", "raised_pipe_v1": "raised_pipe_modules"}
    if family.startswith("pixel-study-"):
        return ["tools/normalize_" + studies[family.removeprefix("pixel-study-")] + ".py"]
    if family == "slice-world":
        return ["tools/normalize_slice_pack" + str(i) + ".py" for i in [1, 2, 3]] + sorted(p.relative_to(ROOT).as_posix() for p in (ROOT / "tools").glob("normalize_l*.py"))
    if family == "legacy-first-screen":
        return ["tools/generate_demo_first_screen_raster_assets.py", "tools/prepare_art_asset.py"]
    if family in {"legacy-presentation", "slice-visual-targets", "historical-anchors", "startup-ui"}:
        return ["tools/prepare_art_asset.py"]
    return []


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--output", type=Path, default=EVIDENCE)
    args = parser.parse_args()
    out = args.output.resolve()
    if out != EVIDENCE.resolve():
        raise ValueError("Evidence must stay in its designated ignored directory.")
    tracked = subprocess.check_output(["git", "ls-files", "-z"], cwd=ROOT).decode().split("\0")
    tracked = sorted(p for p in tracked if p)
    assets = [p for p in tracked if Path(p).suffix.lower() in MEDIA]
    texts = {p: (ROOT / p).read_text(encoding="utf-8") for p in tracked
             if Path(p).suffix in TEXT and not p.startswith("docs/archive/")}
    manifests, attestations = [], defaultdict(list)
    manifest_paths = [p for p in tracked if p.endswith(("source-manifest.json", "/manifest.json"))
                      and p.startswith(("client/assets/", "tools/visual-studies/topdown-3d/production/assets/"))]
    for name in manifest_paths:
        path = ROOT / name
        data = json.loads(texts[name])
        record = {"path": name, "outputs": [], "sources": []}
        for filename, meta in data.get("files", data.get("assets", {})).items():
            target = (path.parent / filename).resolve()
            relative = target.relative_to(ROOT).as_posix()
            actual = digest(target) if target.is_file() else None
            state = "match" if actual == meta["sha256"] else "missing" if actual is None else "mismatch"
            item = {"path": relative, "state": state, "expected": meta["sha256"], "actual": actual}
            record["outputs"].append(item)
            attestations[relative].append({"manifest": name, "state": state})
        sources = dict(data.get("sources", {}))
        if "source_sha256" in data:
            sources[data["source"]] = data["source_sha256"]
        for filename, expected in sources.items():
            source = ROOT / filename if filename.startswith(("tools/", "assets/", "client/")) else ROOT / WEB / filename
            actual = digest(source) if source.is_file() else None
            record["sources"].append({"path": source.relative_to(ROOT).as_posix(), "expected": expected,
                                      "actual": actual, "state": "match" if actual == expected else "missing" if actual is None else "mismatch"})
        manifests.append(record)
    lines = {name: body.splitlines() for name, body in texts.items()}
    records = []
    for path in assets:
        family, status = classify(path)
        aliases = [path] + (["res://" + path.removeprefix("client/")] if path.startswith("client/") else [])
        refs = defaultdict(list)
        for source, source_lines in lines.items():
            if source == path:
                continue
            category = "client_literal" if source.startswith("client/") else "check_mention" if source.startswith("scripts/") else "tool_mention" if source.startswith("tools/") else "documentation"
            for line_no, line in enumerate(source_lines, 1):
                if any(alias in line for alias in aliases):
                    refs[category].append({"file": source, "line": line_no, "text": line.strip()})
        candidates = producer_candidates(family, path)
        for producer in candidates:
            if not (ROOT / producer).is_file():
                if not producer.startswith("assets/art-intake/"):
                    raise ValueError("Missing tracked producer candidate " + producer)
        source_link = SOURCE_LINKS.get(path)
        source_match = None if source_link is None else ((ROOT / source_link).is_file() and digest(ROOT / source_link) == digest(ROOT / path))
        if source_link is not None:
            lineage = "known-copy-source-matches" if source_match else "known-copy-source-missing-or-different"
        elif attestations[path]:
            lineage = "manifest-attested-output-see-source-list"
        elif Path(path).suffix in {".svg", ".tres"}:
            lineage = "tracked-editable-resource-no-independent-export-established"
        elif family == "shared-font":
            lineage = "upstream-revision-and-license-in-font-readme"
        else:
            lineage = "historical-or-producer-candidate-only-needs-per-file-proof"
        records.append({"path": path, "family": family, "status": status,
                        "bytes": (ROOT / path).stat().st_size, "sha256": digest(ROOT / path),
                        "import_sidecar": path + ".import" if path + ".import" in tracked else None,
                        "references": dict(refs), "dynamic_family_candidates": dynamic_sites(path, family, texts),
                        "manifest_attestations": attestations[path], "producer_candidates_not_replay_authorization": candidates,
                        "producer_availability": [{"path": p, "tracked": p in tracked, "exists": (ROOT / p).is_file()} for p in candidates],
                        "lineage_status": lineage, "known_copy_source": source_link, "copy_source_matches": source_match,
                        "glb_metadata": glb_metadata(ROOT / path) if path.endswith(".glb") else None,
                        "replacement": "see asset-inventory-and-transition-v1.md; no move/delete authorized"})
    # Only enumerate cache metadata; never hash or delete whole screenshot/raw batches.
    caches = []
    for root_name in ["assets/art-intake", "assets/third-party"]:
        for child in sorted((ROOT / root_name).iterdir()):
            if child.name.startswith(".") or not child.is_dir():
                continue
            files = [p for p in child.rglob("*") if p.is_file() and not p.is_symlink()]
            caches.append({"path": child.relative_to(ROOT).as_posix(), "files": len(files),
                           "bytes": sum(p.stat().st_size for p in files),
                           "manifests": [p.relative_to(ROOT).as_posix() for p in files if "manifest" in p.name.lower()],
                           "status": "local-mixed-cache-not-retirement-approved"})
    raw_inputs = []
    for name, body in texts.items():
        if not name.startswith("tools/normalize_") or not name.endswith(".py"):
            continue
        for node in ast.walk(ast.parse(body)):
            if isinstance(node, ast.Constant) and isinstance(node.value, str):
                value = node.value
                if re.fullmatch(r"(?:assets/art-intake/)?20\d\d-[\w-]+/[\w.-]+\.png", value):
                    raw = value if value.startswith("assets/") else "assets/art-intake/" + value
                    raw_inputs.append({"producer": name, "line": node.lineno, "path": raw,
                                       "exists": (ROOT / raw).is_file(), "meaning": "literal candidate; may be old input or preview, not current lineage proof"})
    duplicates = defaultdict(list)
    for row in records:
        duplicates[row["sha256"]].append(row["path"])
    # Read back all primary assets to ensure this process left their bytes unchanged.
    for row in records:
        if digest(ROOT / row["path"]) != row["sha256"]:
            raise ValueError("Asset changed during audit: " + row["path"])
    counts = Counter(row["family"] for row in records)
    bad = [item for manifest in manifests for key in ["outputs", "sources"] for item in manifest[key] if item["state"] != "match"]
    report = {"kind": "offline-asset-inventory-not-runtime-reachability", "git_head": subprocess.check_output(["git", "rev-parse", "HEAD"], cwd=ROOT, text=True).strip(),
              "script_sha256": digest(Path(__file__)), "asset_count": len(records), "family_counts": dict(sorted(counts.items())),
              "assets": records, "manifests": manifests, "manifest_exceptions": bad,
              "duplicate_byte_groups": [v for v in duplicates.values() if len(v) > 1],
              "local_caches": caches, "literal_raw_input_candidates": raw_inputs,
              "limits": ["literal occurrences include unused branches/comments and are not executed reads", "dynamic sites are family candidates, not proven per-file reachability", "producer candidates can overwrite newer assets; no exporter was executed", "cache contents not visually reviewed; no safe-delete assertion", "no Godot, client mutation, import or asset generation"]}
    out.mkdir(parents=True, exist_ok=True)
    (out / "inventory.json").write_text(json.dumps(report, ensure_ascii=False, indent=2) + "\n", encoding="utf-8")
    with (out / "inventory.csv").open("w", encoding="utf-8", newline="") as stream:
        fields = ["path", "family", "status", "bytes", "sha256", "import_sidecar", "lineage_status", "known_copy_source", "client_sites", "tool_sites", "check_sites", "dynamic_family_sites", "manifest_status", "producer_candidates"]
        writer = csv.DictWriter(stream, fieldnames=fields, lineterminator="\n")
        writer.writeheader()
        for row in records:
            writer.writerow({**{key: row[key] for key in fields[:8]},
                             **{label: ";".join(f"{s['file']}:{s['line']}" for s in row["references"].get(category, [])) for label, category in [("client_sites", "client_literal"), ("tool_sites", "tool_mention"), ("check_sites", "check_mention")]},
                             "dynamic_family_sites": ";".join(f"{s['file']}:{s['line']}" for s in row["dynamic_family_candidates"]),
                             "manifest_status": json.dumps(row["manifest_attestations"]),
                             "producer_candidates": ";".join(row["producer_candidates_not_replay_authorization"])})
    print(json.dumps({"assets": len(records), "families": dict(sorted(counts.items())), "manifests": len(manifests),
                      "manifest_exceptions": bad, "duplicate_groups": len(report["duplicate_byte_groups"]),
                      "cache_directories": len(caches), "raw_literal_candidates": len(raw_inputs), "output": str(out)}, ensure_ascii=False))


if __name__ == "__main__":
    main()
