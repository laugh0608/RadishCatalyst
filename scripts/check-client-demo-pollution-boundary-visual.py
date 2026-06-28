#!/usr/bin/env python3
import sys
from pathlib import Path


REQUIRED_TEXT_BY_FILE = {
    "client/scripts/map/demo_pollution_boundary_visual_layer.gd": [
        "class_name DemoPollutionBoundaryVisualLayer",
        "demo_default_path_asset_language_art_pass.gd",
        "refresh_pollution_chain_state",
        "boundary.filter_build_site",
        "boundary.pressure_gate",
        "residue.entry_patch",
        "flow.filter_to_base_return",
        "operation_relation.pollution.residue_to_filter",
        "operation_relation.pollution.slurry_split",
        "get_terrain_material_shape_count",
        "terrain.pollution.sediment_fan",
        "terrain.pollution.filter_gravel_bed",
        "terrain.pollution.output_slurry_basin",
        "pollution_chain.boundary_residue_queue",
        "pollution_chain.boundary_core_prep_route",
        "DemoPollutionShortChallengeReadinessArtPass",
        "PollutionToCoreHandoffArtPass",
        "get_pollution_short_challenge_shape_count",
        "get_pollution_short_challenge_focus_shape_count",
        "get_pollution_core_handoff_shape_count",
        "pollution_short_challenge.focus.chain_overlay_suppressed",
        "pollution_short_challenge.focus.pressure_haze",
        "refresh_focus_visibility",
        "_deemphasize_legacy_pollution_blocks",
        "map_object.pollution_residue_patch",
    ],
    "client/scripts/map/demo_default_path_asset_language_art_pass.gd": [
        "class_name DemoDefaultPathAssetLanguageArtPass",
        "terrain.pollution.assetized_pollution_pool",
        "terrain.pollution.assetized_pipe_bundle",
        "terrain.pollution.pressure_haze_band",
        "terrain.pollution.corroded_edge_scars",
        "terrain.pollution.short_challenge_pressure_pulses",
        "draw_pollution_language",
    ],
    "client/scripts/map/demo_pollution_to_core_handoff_art_pass.gd": [
        "class_name DemoPollutionToCoreHandoffArtPass",
        "create_state",
        "get_pollution_shape_ids",
        "get_core_shape_ids",
        "pollution_to_core_handoff.challenge_result",
        "core_handoff.write_energy",
        "core_handoff.demo_hook",
    ],
    "client/scripts/map/demo_pollution_short_challenge_readiness_art_pass.gd": [
        "class_name DemoPollutionShortChallengeReadinessArtPass",
        "create_state",
        "get_shape_ids",
        "pollution_short_challenge.staging_pad",
        "pollution_short_challenge.supply.filter_module",
        "pollution_short_challenge.supply.resistance_vial",
        "pollution_short_challenge.supply.repair_gel",
        "pollution_short_challenge.combat_pocket",
        "pollution_short_challenge.filter_handoff",
    ],
    "client/scenes/maps/VerticalSliceMap.tscn": [
        "DemoPollutionBoundaryVisualLayer",
        "demo_pollution_boundary_visual_layer.gd",
    ],
    "client/scripts/checks/demo_pollution_boundary_visual_check.gd": [
        "Demo pollution boundary visual checks passed.",
        "_check_pollution_boundary_layer_exists_and_registers_visuals",
        "_check_pollution_boundary_focus_visibility",
        "_check_pollution_boundary_operation_relation_shapes",
        "_check_pollution_boundary_chain_state_visuals",
        "_check_pollution_boundary_short_challenge_readiness_visuals",
        "_check_pollution_to_core_handoff_visuals",
        "pollution relation links slurry output to return routes",
        "_check_pollution_boundary_visual_priority_replaces_old_blocks",
        "_check_pollution_boundary_runtime_anchors_are_tagged",
        "pollution boundary registers terrain material shapes",
        "terrain.pollution.recovery_loading_pad",
        "terrain.pollution.assetized_pipe_bundle",
        "pollution boundary fills empty space with pressure haze",
    ],
    "docs/devlogs/2026-W25.md": [
        "污染处理边界视觉第一轮",
        "晶体矿脉与污染边界地貌材质第二轮",
        "DemoPollutionBoundaryVisualLayer",
    ],
    "scripts/check-client.sh": [
        "check-client-demo-pollution-boundary-visual.py",
        "demo_pollution_boundary_visual_check.gd",
    ],
    "scripts/check-client.ps1": [
        "check-client-demo-pollution-boundary-visual.ps1",
    ],
    "scripts/check-client-flow.ps1": [
        "demo_pollution_boundary_visual_check.gd",
    ],
}


def main() -> int:
    repo_root = Path(sys.argv[1]).resolve() if len(sys.argv) > 1 else Path(__file__).resolve().parents[1]
    errors: list[str] = []

    for relative_path, required_texts in REQUIRED_TEXT_BY_FILE.items():
        path = repo_root / relative_path
        if not path.is_file():
            errors.append(f"{relative_path}: missing file")
            continue
        content = path.read_text(encoding="utf-8")
        for required_text in required_texts:
            if required_text not in content:
                errors.append(f"{relative_path}: missing pollution boundary visual text '{required_text}'")

    if errors:
        for error in errors:
            print(error, file=sys.stderr)
        return 1

    print("Client demo pollution boundary visual checks passed.")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
