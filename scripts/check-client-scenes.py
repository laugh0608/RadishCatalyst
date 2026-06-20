#!/usr/bin/env python3
import json
import re
import sys
from pathlib import Path
from typing import Any


PANEL_NAMES = [
    "SavePanel",
    "CompletionPanel",
    "QuickSlotPanel",
    "StatusPanel",
    "VitalsPanel",
    "MapPanel",
    "PromptPanel",
    "DevicePanel",
    "LogPanel",
    "EvacuationPanel",
    "SupplyFeedbackPanel",
]
DEBUG_PANEL_NAMES = {"SavePanel", "QuickSlotPanel"}
POST_DEMO_OBJECTIVE_REGION_EXEMPT_INSTANCE_IDS = {
    "map_object_instance.pollution_residue_logistics_maintenance_retest_cache",
    "enemy_instance.polluted_skitter_logistics_maintenance_retest_guard",
}


def read_text(path: Path) -> str:
    return path.read_text(encoding="utf-8")


def relative(repo_root: Path, path: Path) -> str:
    return path.relative_to(repo_root).as_posix()


def read_json(repo_root: Path, path: Path, errors: list[str]) -> dict[str, Any] | None:
    try:
        return json.loads(read_text(path))
    except json.JSONDecodeError as error:
        errors.append(f"{relative(repo_root, path)}: invalid JSON: {error}")
        return None


def get_config_number(content: str, key: str, default: float) -> float:
    match = re.search(rf"^{re.escape(key)}=(?P<value>-?\d+(\.\d+)?)$", content, re.MULTILINE)
    if not match:
        return default
    return float(match.group("value"))


def get_gdscript_constant_number(content: str, constant_name: str, default: float) -> float:
    match = re.search(rf"^const {re.escape(constant_name)} := (?P<value>-?\d+(\.\d+)?)$", content, re.MULTILINE)
    if not match:
        return default
    return float(match.group("value"))


def get_scene_nodes(content: str) -> list[dict[str, Any]]:
    nodes: list[dict[str, Any]] = []
    current_node: dict[str, Any] | None = None

    for line in re.split(r"\r?\n", content):
        node_match = re.match(r'^\[node name="(?P<name>[^"]+)"(?P<attributes>[^\]]*)\]', line)
        if node_match:
            if current_node is not None:
                nodes.append(current_node)
            attributes = node_match.group("attributes")
            parent_match = re.search(r'parent="(?P<parent>[^"]+)"', attributes)
            current_node = {
                "name": node_match.group("name"),
                "parent": parent_match.group("parent") if parent_match else "",
                "properties": {},
            }
            continue

        if current_node is None:
            continue
        property_match = re.match(r"^(?P<key>[A-Za-z0-9_]+) = (?P<value>.+)$", line)
        if property_match:
            current_node["properties"][property_match.group("key")] = property_match.group("value").strip()

    if current_node is not None:
        nodes.append(current_node)
    return nodes


def get_hud_node_properties(content: str) -> dict[str, dict[str, str]]:
    nodes: dict[str, dict[str, str]] = {}
    for node in get_scene_nodes(content):
        nodes[str(node["name"])] = dict(node["properties"])
    return nodes


def get_node_string(properties: dict[str, str], key: str, default: str = "") -> str:
    value = properties.get(key)
    if value is None:
        return default
    if len(value) >= 2 and value.startswith('"') and value.endswith('"'):
        return value[1:-1]
    return value


def get_node_number(properties: dict[str, str], key: str, default: float) -> float:
    value = properties.get(key)
    if value is None:
        return default
    return float(value)


def get_node_vector2(properties: dict[str, str], key: str) -> dict[str, float] | None:
    value = properties.get(key)
    if value is None:
        return None
    match = re.match(r"^Vector2\((?P<x>-?\d+(\.\d+)?),\s*(?P<y>-?\d+(\.\d+)?)\)$", value)
    if not match:
        return None
    return {"x": float(match.group("x")), "y": float(match.group("y"))}


def get_panel_rect(
    repo_root: Path,
    nodes: dict[str, dict[str, str]],
    node_name: str,
    viewport_width: float,
    viewport_height: float,
    errors: list[str],
) -> dict[str, float] | None:
    if node_name not in nodes:
        errors.append(f"client/scenes/ui/PrototypeHud.tscn: missing HUD panel {node_name}")
        return None

    properties = nodes[node_name]
    anchor_left = get_node_number(properties, "anchor_left", 0.0)
    anchor_right = get_node_number(properties, "anchor_right", 0.0)
    anchor_top = get_node_number(properties, "anchor_top", 0.0)
    anchor_bottom = get_node_number(properties, "anchor_bottom", 0.0)
    return {
        "name": node_name,
        "left": anchor_left * viewport_width + get_node_number(properties, "offset_left", 0.0),
        "top": anchor_top * viewport_height + get_node_number(properties, "offset_top", 0.0),
        "right": anchor_right * viewport_width + get_node_number(properties, "offset_right", 0.0),
        "bottom": anchor_bottom * viewport_height + get_node_number(properties, "offset_bottom", 0.0),
    }


def test_rect_overlap(a: dict[str, float], b: dict[str, float]) -> bool:
    if a["right"] <= b["left"]:
        return False
    if a["left"] >= b["right"]:
        return False
    if a["bottom"] <= b["top"]:
        return False
    if a["top"] >= b["bottom"]:
        return False
    return True


def test_point_in_rect(point: dict[str, float] | None, rect: dict[str, float], padding: float = 0.0) -> bool:
    if point is None:
        return False
    if point["x"] < rect["left"] - padding:
        return False
    if point["x"] > rect["right"] + padding:
        return False
    if point["y"] < rect["top"] - padding:
        return False
    if point["y"] > rect["bottom"] + padding:
        return False
    return True


def resolve_camera_axis(focus: float, min_edge: float, max_edge: float, viewport_size: float) -> float:
    half_viewport = viewport_size * 0.5
    min_center = min_edge + half_viewport
    max_center = max_edge - half_viewport
    if min_center > max_center:
        return (min_edge + max_edge) * 0.5
    return min(max(focus, min_center), max_center)


def convert_to_snake_case(name: str) -> str:
    with_word_boundaries = re.sub(r"([A-Z]+)([A-Z][a-z])", r"\1_\2", name)
    with_lower_boundaries = re.sub(r"([a-z0-9])([A-Z])", r"\1_\2", with_word_boundaries)
    return with_lower_boundaries.lower()


def get_map_object_instance_id(node_name: str) -> str:
    return f"map_object_instance.{convert_to_snake_case(node_name)}"


def get_enemy_instance_id(node_name: str) -> str:
    return f"enemy_instance.{convert_to_snake_case(node_name)}"


def add_unique_string_value(values_by_key: dict[str, list[str]], key: str, value: str) -> None:
    if not key.strip() or not value.strip():
        return
    values_by_key.setdefault(key, [])
    if value not in values_by_key[key]:
        values_by_key[key].append(value)


def add_quest_region_requirement(
    requirements: dict[str, list[str]],
    quest_id: str,
    region_id: str,
    reason: str,
) -> None:
    if not quest_id.strip() or not region_id.strip() or not reason.strip():
        return
    key = f"{quest_id}|{region_id}"
    requirements.setdefault(key, [])
    if reason not in requirements[key]:
        requirements[key].append(reason)


def get_map_region_id(position: dict[str, float] | None, regions: dict[str, float]) -> str:
    if position is None:
        return ""
    x = position["x"]
    y = position["y"]
    if x >= regions["DEMO_STABILIZATION_CORE_REGION_X"]:
        return "region.demo_stabilization_core"
    if x >= regions["PHASE_WELL_TETHER_REGION_X"]:
        return "region.phase_well_tether"
    if x >= regions["PHASE_WELL_FRAME_REGION_X"]:
        return "region.phase_well_frame"
    if x >= regions["PHASE_WELL_LOOM_REGION_X"]:
        return "region.phase_well_loom"
    if x >= regions["PHASE_WELL_CHAMBER_REGION_X"]:
        return "region.phase_well_chamber"
    if x >= regions["PHASE_WELL_SINK_REGION_X"]:
        return "region.phase_well_sink"
    if x >= regions["INNER_PHASE_WELL_REGION_X"]:
        return "region.inner_phase_well"
    if x >= regions["DEEP_RUIN_REGION_X"]:
        return "region.deep_ruin_threshold"
    if x >= regions["RUIN_OUTER_RING_X"]:
        return "region.ruin_outer_ring"
    if x >= regions["POLLUTION_REGION_X"] and y >= regions["POLLUTION_DEEP_Y"]:
        return "region.pollution_edge"
    if x >= regions["CRYSTAL_REGION_X"]:
        return "region.crystal_vein_field"
    return "region.outpost_platform"


def test_scene_interactable(interactables: list[dict[str, str]], definition_id: str, interaction_type: str = "") -> bool:
    for interactable in interactables:
        if interactable["definition_id"] != definition_id:
            continue
        if interaction_type and interactable["interaction_type"] != interaction_type:
            continue
        return True
    return False


def count_scene_interactables(interactables: list[dict[str, str]], definition_id: str, interaction_type: str = "") -> int:
    count = 0
    for interactable in interactables:
        if interactable["definition_id"] != definition_id:
            continue
        if interaction_type and interactable["interaction_type"] != interaction_type:
            continue
        count += 1
    return count


def test_scene_enemy(enemies: list[dict[str, str]], definition_id: str) -> bool:
    return any(enemy["definition_id"] == definition_id for enemy in enemies)


def check_resource_references(repo_root: Path, client_root: Path, errors: list[str]) -> None:
    scene_files = [
        path for path in client_root.rglob("*")
        if path.is_file() and path.suffix in {".tscn", ".tres", ".godot"}
    ]
    for path in scene_files:
        content = read_text(path)
        path_label = relative(repo_root, path)
        for match in re.finditer(r'path="(res://[^"]+)"', content):
            resource_path = match.group(1)
            full_resource_path = client_root / resource_path.removeprefix("res://")
            if not full_resource_path.is_file():
                errors.append(f"{path_label}: missing resource {resource_path}")
        if re.search(r"^(reward_id|reward_amount) = ", content, re.MULTILINE):
            errors.append(f"{path_label}: contains obsolete prototype reward properties")


def check_hud_layout(
    repo_root: Path,
    project_path: Path,
    hud_scene_path: Path,
    errors: list[str],
) -> tuple[float, float, dict[str, dict[str, float]]]:
    viewport_width = 2500.0
    viewport_height = 1400.0
    panels_by_name: dict[str, dict[str, float]] = {}
    if not project_path.is_file() or not hud_scene_path.is_file():
        return viewport_width, viewport_height, panels_by_name

    project_content = read_text(project_path)
    viewport_width = get_config_number(project_content, "window/size/viewport_width", viewport_width)
    viewport_height = get_config_number(project_content, "window/size/viewport_height", viewport_height)
    nodes = get_hud_node_properties(read_text(hud_scene_path))
    panels: list[dict[str, float]] = []

    for panel_name in PANEL_NAMES:
        rect = get_panel_rect(repo_root, nodes, panel_name, viewport_width, viewport_height, errors)
        if rect is None:
            continue
        panels.append(rect)
        panels_by_name[panel_name] = rect
        width = rect["right"] - rect["left"]
        height = rect["bottom"] - rect["top"]
        if rect["left"] < 0 or rect["top"] < 0 or rect["right"] > viewport_width or rect["bottom"] > viewport_height:
            errors.append(f"client/scenes/ui/PrototypeHud.tscn: {panel_name} is outside viewport bounds")
        if rect["right"] <= rect["left"] or rect["bottom"] <= rect["top"]:
            errors.append(f"client/scenes/ui/PrototypeHud.tscn: {panel_name} has invalid rect")

        if panel_name == "MapPanel" and (
            width > 640.0 or height > 220.0 or rect["left"] > 40.0
            or rect["top"] > 40.0 or rect["right"] > 660.0 or rect["bottom"] > 240.0
        ):
            errors.append("client/scenes/ui/PrototypeHud.tscn: MapPanel drifted out of distributed HUD map bounds")
        if panel_name == "StatusPanel" and (
            width > 640.0 or height > 220.0 or rect["left"] > 40.0
            or rect["top"] < 180.0 or rect["top"] > 260.0
            or rect["right"] > 660.0 or rect["bottom"] > 460.0
        ):
            errors.append("client/scenes/ui/PrototypeHud.tscn: StatusPanel drifted out of distributed HUD objective-card bounds")
        if panel_name == "VitalsPanel" and (
            width > 520.0 or height > 260.0 or rect["top"] > 40.0
            or rect["left"] < viewport_width - 560.0 or rect["right"] > viewport_width
        ):
            errors.append("client/scenes/ui/PrototypeHud.tscn: VitalsPanel drifted out of distributed HUD vitals-card bounds")
        if panel_name == "PromptPanel":
            if (
                width > 460.0 or height > 90.0
                or rect["left"] > 40.0
                or rect["top"] < viewport_height - 190.0
                or rect["bottom"] > viewport_height - 10.0
            ):
                errors.append("client/scenes/ui/PrototypeHud.tscn: PromptPanel drifted out of distributed HUD bottom-rail bounds")
        if panel_name == "LogPanel" and (
            width > 460.0 or height > 120.0 or rect["left"] < 440.0
            or rect["right"] > 940.0 or rect["top"] < viewport_height - 400.0
        ):
            errors.append("client/scenes/ui/PrototypeHud.tscn: LogPanel drifted out of distributed HUD log-rail bounds")

    for index, first_panel in enumerate(panels):
        for second_panel in panels[index + 1:]:
            first_is_debug = first_panel["name"] in DEBUG_PANEL_NAMES
            second_is_debug = second_panel["name"] in DEBUG_PANEL_NAMES
            if first_is_debug ^ second_is_debug:
                continue
            if test_rect_overlap(first_panel, second_panel):
                errors.append(
                    "client/scenes/ui/PrototypeHud.tscn: "
                    f"{first_panel['name']} overlaps {second_panel['name']}"
                )

    return viewport_width, viewport_height, panels_by_name


def check_script_uids(repo_root: Path, client_root: Path, errors: list[str]) -> None:
    for script_path in (client_root / "scripts").rglob("*.gd"):
        uid_path = script_path.with_name(f"{script_path.name}.uid")
        if not uid_path.is_file():
            errors.append(f"{relative(repo_root, script_path)}: missing Godot script uid file")


def load_region_constants(vertical_slice_map_script_path: Path, errors: list[str]) -> dict[str, float]:
    regions = {
        "CRYSTAL_REGION_X": -20.0,
        "POLLUTION_REGION_X": 240.0,
        "POLLUTION_DEEP_Y": -40.0,
        "RUIN_OUTER_RING_X": 390.0,
        "DEEP_RUIN_REGION_X": 700.0,
        "INNER_PHASE_WELL_REGION_X": 1460.0,
        "PHASE_WELL_SINK_REGION_X": 1760.0,
        "PHASE_WELL_CHAMBER_REGION_X": 2040.0,
        "PHASE_WELL_LOOM_REGION_X": 2320.0,
        "PHASE_WELL_FRAME_REGION_X": 2600.0,
        "PHASE_WELL_TETHER_REGION_X": 2880.0,
        "DEMO_STABILIZATION_CORE_REGION_X": 3640.0,
    }
    if not vertical_slice_map_script_path.is_file():
        errors.append("client/scripts/map/vertical_slice_map.gd: missing map region source for scene region checks")
        return regions
    content = read_text(vertical_slice_map_script_path)
    return {
        key: get_gdscript_constant_number(content, key, default)
        for key, default in regions.items()
    }


def parse_map_scene(
    content: str,
    regions: dict[str, float],
) -> tuple[list[dict[str, str]], list[dict[str, str]], dict[str, Any], dict[str, Any] | None, dict[str, Any] | None]:
    interactables: list[dict[str, str]] = []
    enemies: list[dict[str, str]] = []
    interactables_by_instance_id: dict[str, Any] = {}
    player_position = None
    outpost_core_position = None
    background_bounds = None

    for node in get_scene_nodes(content):
        name = str(node["name"])
        parent = str(node["parent"])
        properties = dict(node["properties"])
        if parent == "." and name == "Player":
            player_position = get_node_vector2(properties, "position")
        if parent == "." and name == "Background":
            background_bounds = {
                "left": get_node_number(properties, "offset_left", 0.0),
                "top": get_node_number(properties, "offset_top", 0.0),
                "right": get_node_number(properties, "offset_right", 0.0),
                "bottom": get_node_number(properties, "offset_bottom", 0.0),
            }
        if parent == "Interactables" and "definition_id" in properties:
            instance_id = get_map_object_instance_id(name)
            position = get_node_vector2(properties, "position")
            if name == "OutpostCore":
                outpost_core_position = position
            interactable = {
                "name": name,
                "instance_id": instance_id,
                "definition_id": get_node_string(properties, "definition_id"),
                "interaction_type": get_node_string(properties, "interaction_type"),
                "prerequisite_instance_id": get_node_string(properties, "prerequisite_instance_id"),
                "region_id": get_map_region_id(position, regions),
            }
            interactables.append(interactable)
            interactables_by_instance_id[instance_id] = interactable
        if parent == "Enemies" and "definition_id" in properties:
            position = get_node_vector2(properties, "position")
            enemies.append({
                "name": name,
                "instance_id": get_enemy_instance_id(name),
                "definition_id": get_node_string(properties, "definition_id"),
                "region_id": get_map_region_id(position, regions),
            })

    map_context = {
        "interactables_by_instance_id": interactables_by_instance_id,
        "player_position": player_position,
        "outpost_core_position": outpost_core_position,
        "background_bounds": background_bounds,
    }
    return interactables, enemies, map_context, player_position, outpost_core_position


def check_build_prerequisites(interactables: list[dict[str, str]], errors: list[str]) -> None:
    by_instance = {interactable["instance_id"]: interactable for interactable in interactables}
    for interactable in interactables:
        if interactable["interaction_type"] != "build" or not interactable["prerequisite_instance_id"].strip():
            continue
        if interactable["prerequisite_instance_id"] not in by_instance:
            errors.append(
                "client/scenes/maps/VerticalSliceMap.tscn: "
                f"build interactable '{interactable['name']}' references missing prerequisite_instance_id "
                f"'{interactable['prerequisite_instance_id']}'"
            )


def check_demo_core_placement(
    interactables: list[dict[str, str]],
    enemies: list[dict[str, str]],
    scene_nodes: list[dict[str, Any]],
    errors: list[str],
) -> None:
    demo_core = next((item for item in interactables if item["name"] == "DemoStabilizationCore"), None)
    demo_recovery = next((item for item in interactables if item["name"] == "DemoStabilizationRecoveryCache"), None)
    demo_guard = next((enemy for enemy in enemies if enemy["name"] == "DemoStabilizationGuard"), None)
    if demo_core is None:
        errors.append("client/scenes/maps/VerticalSliceMap.tscn: missing demo stabilization core device")
    elif demo_core["region_id"] != "region.demo_stabilization_core":
        errors.append("client/scenes/maps/VerticalSliceMap.tscn: demo stabilization core device must sit in demo stabilization core region")
    if demo_recovery is None:
        errors.append("client/scenes/maps/VerticalSliceMap.tscn: missing demo stabilization side recovery point")
    elif demo_recovery["region_id"] != "region.demo_stabilization_core":
        errors.append("client/scenes/maps/VerticalSliceMap.tscn: demo stabilization recovery point must sit in demo stabilization core region")
    if demo_guard is None:
        errors.append("client/scenes/maps/VerticalSliceMap.tscn: missing demo stabilization guard")
    elif demo_guard["region_id"] != "region.demo_stabilization_core":
        errors.append("client/scenes/maps/VerticalSliceMap.tscn: demo stabilization guard must sit in demo stabilization core region")
    scene_nodes_by_name = {str(node["name"]): node for node in scene_nodes}
    for node_name in [
        "CoreStabilizationApproachLane",
        "CoreStabilizationRecoveryPocket",
        "CoreStabilizationGuardPressureZone",
        "CoreStabilizationWritebackLine",
        "CoreStabilizationCorePad",
        "CoreStabilizationPressureLabel",
    ]:
        node = scene_nodes_by_name.get(node_name)
        if node is None or str(node["parent"]) != "OpeningSceneLayer":
            errors.append(f"client/scenes/maps/VerticalSliceMap.tscn: missing demo stabilization pressure scene node {node_name}")


def check_spawn_occlusion(
    repo_root: Path,
    game_root_scene_path: Path,
    viewport_width: float,
    viewport_height: float,
    panels_by_name: dict[str, dict[str, float]],
    map_context: dict[str, Any],
    errors: list[str],
) -> None:
    player_position = map_context["player_position"]
    outpost_core_position = map_context["outpost_core_position"]
    background_bounds = map_context["background_bounds"]
    if not game_root_scene_path.is_file() or player_position is None or outpost_core_position is None or not panels_by_name:
        return

    game_root_nodes = get_scene_nodes(read_text(game_root_scene_path))
    map_root_node = next((node for node in game_root_nodes if node["parent"] == "." and node["name"] == "VerticalSliceMap"), None)
    camera_node = next((node for node in game_root_nodes if node["parent"] == "." and node["name"] == "WorldCamera"), None)
    if map_root_node is None:
        errors.append("client/scenes/game/GameRoot.tscn: missing VerticalSliceMap instance")
        return
    if camera_node is None:
        errors.append("client/scenes/game/GameRoot.tscn: missing WorldCamera follow camera")
        return

    map_root_properties = dict(map_root_node["properties"])
    map_root_position = get_node_vector2(map_root_properties, "position")
    map_root_scale = get_node_vector2(map_root_properties, "scale") or {"x": 1.0, "y": 1.0}
    if map_root_position is None:
        errors.append("client/scenes/game/GameRoot.tscn: VerticalSliceMap is missing position")
        return

    hotspots = [
        {"label": "player spawn", "position": player_position},
        {"label": "outpost core", "position": outpost_core_position},
    ]
    for hotspot in hotspots:
        position = hotspot["position"]
        world_point = {
            "x": map_root_position["x"] + position["x"] * map_root_scale["x"],
            "y": map_root_position["y"] + position["y"] * map_root_scale["y"],
        }
        camera_center = dict(world_point)
        if background_bounds is not None:
            background_left = map_root_position["x"] + background_bounds["left"] * map_root_scale["x"]
            background_top = map_root_position["y"] + background_bounds["top"] * map_root_scale["y"]
            background_right = map_root_position["x"] + background_bounds["right"] * map_root_scale["x"]
            background_bottom = map_root_position["y"] + background_bounds["bottom"] * map_root_scale["y"]
            camera_center = {
                "x": resolve_camera_axis(world_point["x"], background_left, background_right, viewport_width),
                "y": resolve_camera_axis(world_point["y"], background_top, background_bottom, viewport_height),
            }
        screen_point = {
            "x": viewport_width * 0.5 + (world_point["x"] - camera_center["x"]),
            "y": viewport_height * 0.5 + (world_point["y"] - camera_center["y"]),
        }
        for panel_name in ("MapPanel", "StatusPanel", "PromptPanel"):
            if panel_name not in panels_by_name:
                continue
            if test_point_in_rect(screen_point, panels_by_name[panel_name], 12.0):
                errors.append(f"client/scenes/game/GameRoot.tscn: {panel_name} occludes {hotspot['label']} hotspot")


def check_scene_backed_objectives(
    repo_root: Path,
    client_root: Path,
    interactables: list[dict[str, str]],
    enemies: list[dict[str, str]],
    errors: list[str],
) -> None:
    quests_json = read_json(repo_root, client_root / "data" / "quests.json", errors)
    map_objects_json = read_json(repo_root, client_root / "data" / "map_objects.json", errors)
    recipes_json = read_json(repo_root, client_root / "data" / "recipes.json", errors)
    regions_json = read_json(repo_root, client_root / "data" / "regions.json", errors)
    enemies_json = read_json(repo_root, client_root / "data" / "enemies.json", errors)
    if None in (quests_json, map_objects_json, recipes_json, regions_json, enemies_json):
        return

    map_objects_by_id = {
        str(map_object.get("id", "")): map_object
        for map_object in map_objects_json.get("entries", [])
        if isinstance(map_object, dict)
    }
    enemies_by_id = {
        str(enemy.get("id", "")): enemy
        for enemy in enemies_json.get("entries", [])
        if isinstance(enemy, dict)
    }
    quest_refs_by_region = {
        str(region.get("id", "")): [
            str(quest_ref) for quest_ref in region.get("quest_refs", [])
            if str(quest_ref).strip()
        ]
        for region in regions_json.get("entries", [])
        if isinstance(region, dict)
    }
    processor_regions_by_building: dict[str, list[str]] = {}
    for interactable in interactables:
        if interactable["interaction_type"] == "process_recipe":
            add_unique_string_value(
                processor_regions_by_building,
                interactable["definition_id"],
                interactable["region_id"],
            )

    recipes_by_crafted_ref: dict[str, list[dict[str, Any]]] = {}
    gather_regions_by_item: dict[str, list[str]] = {}
    craft_regions_by_item: dict[str, list[str]] = {}
    for recipe in recipes_json.get("entries", []):
        if not isinstance(recipe, dict):
            continue
        required_building_id = str(recipe.get("required_building_id", ""))
        processor_regions = processor_regions_by_building.get(required_building_id, [])
        for ref in recipe.get("outputs", []) + recipe.get("byproducts", []):
            if not isinstance(ref, dict):
                continue
            crafted_id = str(ref.get("id", ""))
            recipes_by_crafted_ref.setdefault(crafted_id, []).append(recipe)
            for region_id in processor_regions:
                add_unique_string_value(craft_regions_by_item, crafted_id, region_id)
                add_unique_string_value(gather_regions_by_item, crafted_id, region_id)

    for interactable in interactables:
        if interactable["instance_id"] in POST_DEMO_OBJECTIVE_REGION_EXEMPT_INSTANCE_IDS:
            continue
        map_object = map_objects_by_id.get(interactable["definition_id"])
        if not isinstance(map_object, dict):
            continue
        for drop in map_object.get("drops", []):
            if isinstance(drop, dict):
                add_unique_string_value(gather_regions_by_item, str(drop.get("id", "")), interactable["region_id"])
        for sample_result_id in map_object.get("sample_result_refs", []):
            add_unique_string_value(gather_regions_by_item, str(sample_result_id), interactable["region_id"])

    for enemy in enemies:
        if enemy["instance_id"] in POST_DEMO_OBJECTIVE_REGION_EXEMPT_INSTANCE_IDS:
            continue
        enemy_definition = enemies_by_id.get(enemy["definition_id"])
        if not isinstance(enemy_definition, dict):
            continue
        for drop in enemy_definition.get("drops", []):
            if isinstance(drop, dict):
                add_unique_string_value(gather_regions_by_item, str(drop.get("id", "")), enemy["region_id"])

    quest_region_requirements: dict[str, list[str]] = {}
    for quest in quests_json.get("entries", []):
        if not isinstance(quest, dict):
            continue
        quest_id = str(quest.get("id", ""))
        for objective in quest.get("objectives", []):
            if not isinstance(objective, dict):
                continue
            objective_type = str(objective.get("type", ""))
            target_id = str(objective.get("target_id", ""))
            required_amount = float(objective.get("amount", 1.0))
            objective_regions: list[str] = []

            if objective_type == "interact" and not test_scene_interactable(interactables, target_id):
                errors.append(f"client/scenes/maps/VerticalSliceMap.tscn: quest '{quest_id}' interact target '{target_id}' has no scene interactable")
            if objective_type == "sample_object" and not test_scene_interactable(interactables, target_id, "sample"):
                errors.append(f"client/scenes/maps/VerticalSliceMap.tscn: quest '{quest_id}' sample_object target '{target_id}' has no sample scene interactable")
            if objective_type == "inspect" and not test_scene_interactable(interactables, target_id, "inspect"):
                errors.append(f"client/scenes/maps/VerticalSliceMap.tscn: quest '{quest_id}' inspect target '{target_id}' has no inspect scene interactable")
            if objective_type == "build":
                build_site_count = count_scene_interactables(interactables, target_id, "build")
                if build_site_count < required_amount:
                    errors.append(
                        f"client/scenes/maps/VerticalSliceMap.tscn: quest '{quest_id}' build target "
                        f"'{target_id}' needs {required_amount:g} build sites, got {build_site_count}"
                    )
            if objective_type == "defeat_enemy" and not test_scene_enemy(enemies, target_id):
                errors.append(f"client/scenes/maps/VerticalSliceMap.tscn: quest '{quest_id}' defeat_enemy target '{target_id}' has no scene enemy")
            if objective_type == "craft_item" and target_id in recipes_by_crafted_ref:
                has_scene_processor = False
                for recipe in recipes_by_crafted_ref[target_id]:
                    if test_scene_interactable(interactables, str(recipe.get("required_building_id", "")), "process_recipe"):
                        has_scene_processor = True
                        break
                if not has_scene_processor:
                    errors.append(f"client/scenes/maps/VerticalSliceMap.tscn: quest '{quest_id}' craft_item target '{target_id}' has no scene processor for its recipe")
            if objective_type == "gather_item":
                scene_gather_amount = 0.0
                for interactable in interactables:
                    if interactable["instance_id"] in POST_DEMO_OBJECTIVE_REGION_EXEMPT_INSTANCE_IDS:
                        continue
                    if interactable["interaction_type"] != "gather":
                        continue
                    map_object = map_objects_by_id.get(interactable["definition_id"])
                    if not isinstance(map_object, dict):
                        continue
                    for drop in map_object.get("drops", []):
                        if isinstance(drop, dict) and str(drop.get("id", "")) == target_id:
                            scene_gather_amount += float(drop.get("amount", 0.0))
                if 0.0 < scene_gather_amount < required_amount:
                    errors.append(
                        f"client/scenes/maps/VerticalSliceMap.tscn: quest '{quest_id}' gather_item target "
                        f"'{target_id}' needs {required_amount:g} from scene gather nodes, got {scene_gather_amount:g}"
                    )

            if objective_type in {"visit_region", "return_region"} and target_id.startswith("region."):
                objective_regions.append(target_id)
            if objective_type in {"interact", "sample_object", "inspect", "build"}:
                for interactable in interactables:
                    matches_target = interactable["definition_id"] == target_id
                    matches_interaction = (
                        objective_type not in {"sample_object", "inspect", "build"}
                        or interactable["interaction_type"] == {
                            "sample_object": "sample",
                            "inspect": "inspect",
                            "build": "build",
                        }[objective_type]
                    )
                    if matches_target and matches_interaction:
                        objective_regions.append(interactable["region_id"])
            if objective_type == "defeat_enemy":
                for enemy in enemies:
                    if enemy["definition_id"] == target_id:
                        objective_regions.append(enemy["region_id"])
            if objective_type == "craft_item":
                objective_regions.extend(craft_regions_by_item.get(target_id, []))
            if objective_type == "gather_item":
                objective_regions.extend(gather_regions_by_item.get(target_id, []))

            for region_id in sorted(set(region for region in objective_regions if region.strip())):
                add_quest_region_requirement(
                    quest_region_requirements,
                    quest_id,
                    region_id,
                    f"{objective_type}:{target_id}",
                )

    for key, reasons in quest_region_requirements.items():
        quest_id, region_id = key.split("|", 1)
        if region_id not in quest_refs_by_region:
            errors.append(f"client/data/regions.json: missing region '{region_id}' required by quest '{quest_id}' objective region check")
            continue
        if quest_id in quest_refs_by_region[region_id]:
            continue
        errors.append(
            f"client/data/regions.json:{region_id}.quest_refs is missing quest '{quest_id}' "
            f"required by scene-backed objective regions ({', '.join(reasons)})"
        )


def check_vertical_slice_scene(
    repo_root: Path,
    client_root: Path,
    vertical_slice_map_scene_path: Path,
    vertical_slice_map_script_path: Path,
    game_root_scene_path: Path,
    viewport_width: float,
    viewport_height: float,
    panels_by_name: dict[str, dict[str, float]],
    errors: list[str],
) -> None:
    if not vertical_slice_map_scene_path.is_file():
        return
    regions = load_region_constants(vertical_slice_map_script_path, errors)
    content = read_text(vertical_slice_map_scene_path)
    scene_nodes = get_scene_nodes(content)
    interactables, enemies, map_context, _, _ = parse_map_scene(content, regions)
    check_build_prerequisites(interactables, errors)
    check_demo_core_placement(interactables, enemies, scene_nodes, errors)
    check_spawn_occlusion(
        repo_root,
        game_root_scene_path,
        viewport_width,
        viewport_height,
        panels_by_name,
        map_context,
        errors,
    )
    check_scene_backed_objectives(repo_root, client_root, interactables, enemies, errors)


def main() -> int:
    repo_root = Path(sys.argv[1]).resolve() if len(sys.argv) > 1 else Path(__file__).resolve().parents[1]
    client_root = repo_root / "client"
    errors: list[str] = []

    project_path = client_root / "project.godot"
    game_root_scene_path = client_root / "scenes" / "game" / "GameRoot.tscn"
    hud_scene_path = client_root / "scenes" / "ui" / "PrototypeHud.tscn"
    vertical_slice_map_scene_path = client_root / "scenes" / "maps" / "VerticalSliceMap.tscn"
    vertical_slice_map_script_path = client_root / "scripts" / "map" / "vertical_slice_map.gd"

    check_resource_references(repo_root, client_root, errors)
    viewport_width, viewport_height, panels_by_name = check_hud_layout(
        repo_root,
        project_path,
        hud_scene_path,
        errors,
    )
    check_script_uids(repo_root, client_root, errors)
    check_vertical_slice_scene(
        repo_root,
        client_root,
        vertical_slice_map_scene_path,
        vertical_slice_map_script_path,
        game_root_scene_path,
        viewport_width,
        viewport_height,
        panels_by_name,
        errors,
    )

    if errors:
        for error in errors:
            print(error, file=sys.stderr)
        return 1

    print("Client scene references passed.")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
