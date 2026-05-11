extends RefCounted

const VerticalSliceMapScene := preload("res://scenes/maps/VerticalSliceMap.tscn")
const PrototypeHudScene := preload("res://scenes/ui/PrototypeHud.tscn")

var host


func _init(check_host) -> void:
	host = check_host


func run(root_window: Window) -> void:
	var presenter := HudMapPresenter.new()
	var map := VerticalSliceMapScene.instantiate() as VerticalSliceMap
	root_window.add_child(map)
	presenter.configure(host.data_registry, map)
	var marker_world := WorldState.create_default()
	host._expect_text_contains(
		presenter.format_region_markers(marker_world, "quest.restore_outpost"),
		"基地：当前位置，目标",
		"outpost marker as current objective"
	)
	host._expect_text_contains(
		presenter.format_region_markers(marker_world, "quest.restore_outpost"),
		"晶体：东侧，未解锁",
		"locked crystal marker"
	)
	var initial_map_labels := presenter.format_map_marker_labels(marker_world, "quest.restore_outpost")
	host._expect_equal(initial_map_labels.size(), 11, "minimap marker count includes phase well tether")
	host._expect_array_has(initial_map_labels, "基地\n当前\n目标", "outpost minimap current target marker")
	host._expect_array_has(initial_map_labels, "晶体\n未解锁", "crystal minimap locked marker")
	host._expect_array_has(initial_map_labels, "井口\n未解锁", "inner phase well minimap locked marker")
	host._expect_array_has(initial_map_labels, "井底\n未解锁", "phase well sink minimap locked marker")
	host._expect_array_has(initial_map_labels, "心室\n未解锁", "phase well chamber minimap locked marker")
	host._expect_array_has(initial_map_labels, "井纺\n未解锁", "phase well loom minimap locked marker")
	host._expect_array_has(initial_map_labels, "井纹\n未解锁", "phase well frame minimap locked marker")
	host._expect_array_has(initial_map_labels, "井系\n未解锁", "phase well tether minimap locked marker")
	marker_world.unlock_region("region.crystal_vein_field")
	host._expect_text_contains(
		presenter.format_region_markers(marker_world, "quest.scout_crystal_field"),
		"晶体：东侧，目标",
		"crystal marker as objective"
	)
	host._expect_array_has(
		presenter.format_map_marker_labels(marker_world, "quest.scout_crystal_field"),
		"晶体\n目标",
		"crystal minimap objective marker"
	)
	marker_world.quest_state.set_objective_progress(
		"quest.calibrate_reactor",
		"gather_item",
		"item.salvage_scrap",
		4.0
	)
	host._expect_text_contains(
		presenter.format_region_markers(marker_world, "quest.calibrate_reactor"),
		"基地：当前位置，目标",
		"calibrator crafting returns to outpost reactor"
	)
	marker_world.quest_state.set_objective_progress(
		"quest.bring_back_sample",
		"sample_object",
		"map_object.anomaly_crystal",
		1.0
	)
	host._expect_text_contains(
		presenter.format_region_markers(marker_world, "quest.bring_back_sample"),
		"晶体：东侧，目标",
		"sample marker remains in crystal field"
	)
	marker_world.quest_state.set_objective_progress(
		"quest.analyze_anomaly_sample",
		"gather_item",
		"item.anomaly_residue",
		2.0
	)
	host._expect_text_contains(
		presenter.format_region_markers(marker_world, "quest.analyze_anomaly_sample"),
		"基地：当前位置，目标",
		"analysis crafting returns to outpost reactor"
	)
	marker_world.quest_state.set_objective_progress(
		"quest.prepare_treatment_supplies",
		"craft_item",
		"item.repair_gel",
		1.0
	)
	host._expect_text_contains(
		presenter.format_region_markers(marker_world, "quest.prepare_treatment_supplies"),
		"晶体：东侧，目标",
		"treatment enemy stays in crystal field"
	)
	marker_world.unlock_region("region.pollution_edge")
	marker_world.quest_state.set_objective_progress(
		"quest.enter_pollution_edge",
		"visit_region",
		"region.pollution_edge",
		1.0
	)
	marker_world.quest_state.set_objective_progress(
		"quest.enter_pollution_edge",
		"gather_item",
		"item.polluted_residue",
		2.0
	)
	host._expect_text_contains(
		presenter.format_region_markers(marker_world, "quest.enter_pollution_edge"),
		"晶体：东侧，目标",
		"resistance vial crafting points back to treatment filter"
	)
	marker_world.quest_state.set_objective_progress(
		"quest.enter_pollution_edge",
		"craft_item",
		"item.resistance_vial_t1",
		1.0
	)
	host._expect_text_contains(presenter.format_region_markers(marker_world, "quest.enter_pollution_edge"), "污染：东南，目标", "polluted skitter returns objective to pollution edge")
	marker_world.unlock_region("region.locked_ruin_gate")
	host._expect_text_contains(presenter.format_region_markers(marker_world, "quest.unlock_ruin_signal"), "污染：东南，目标", "ruin gate objective follows scene placement in pollution edge")
	host._expect_array_has(presenter.format_map_marker_labels(marker_world, "quest.unlock_ruin_signal"), "污染\n目标", "ruin gate minimap objective follows pollution edge marker")
	marker_world.unlock_region("region.ruin_outer_ring")
	host._expect_text_contains(presenter.format_region_markers(marker_world, "quest.scout_ruin_outer_ring"), "外圈：更东，目标", "outer ring scouting points to outer ring marker")
	host._expect_array_has(presenter.format_map_marker_labels(marker_world, "quest.scout_ruin_outer_ring"), "外圈\n目标", "outer ring minimap objective marker")
	host._expect_text_contains(presenter.format_region_markers(marker_world, "quest.salvage_signal_echo"), "外圈：更东，目标", "signal echo salvage stays in outer ring")
	host._expect_text_contains(presenter.format_region_markers(marker_world, "quest.analyze_deep_signal"), "基地：当前位置，目标", "deep signal analysis returns to outpost reactor")
	host._expect_array_has(presenter.format_map_marker_labels(marker_world, "quest.analyze_deep_signal"), "基地\n当前\n目标", "deep signal analysis minimap returns to outpost")
	host._expect_text_contains(presenter.format_region_markers(marker_world, "quest.unlock_deep_ruin_entrance"), "外圈：更东，目标", "deep ruin door stays in outer ring")
	marker_world.unlock_region("region.deep_ruin_threshold")
	host._expect_text_contains(presenter.format_region_markers(marker_world, "quest.harvest_phase_filament"), "深段：更深，目标", "phase filament salvage points to deep region")
	host._expect_array_has(presenter.format_map_marker_labels(marker_world, "quest.harvest_phase_filament"), "深段\n目标", "deep region minimap objective marker")
	host._expect_text_contains(presenter.format_region_markers(marker_world, "quest.refine_phase_filament"), "晶体：东侧，目标", "phase filament filter points back to treatment filter")
	host._expect_text_contains(presenter.format_region_markers(marker_world, "quest.assemble_deep_override"), "基地：当前位置，目标", "deep override assembly returns to outpost reactor")
	host._expect_text_contains(presenter.format_region_markers(marker_world, "quest.unlock_deep_ruin_cache"), "深段：更深，目标", "deep latch returns objective to deep region")
	host._expect_text_contains(presenter.format_region_markers(marker_world, "quest.analyze_deep_core"), "基地：当前位置，目标", "deep core analysis returns to outpost reactor")
	host._expect_array_has(presenter.format_map_marker_labels(marker_world, "quest.analyze_deep_core"), "基地\n当前\n目标", "deep core analysis minimap returns to outpost")
	host._expect_text_contains(presenter.format_region_markers(marker_world, "quest.activate_deep_array"), "深段：更深，目标", "deep array activation returns objective to deep region")
	host._expect_text_contains(presenter.format_region_markers(marker_world, "quest.assemble_deep_signal_matrix"), "基地：当前位置，目标", "deep signal matrix assembly returns to outpost reactor")
	host._expect_text_contains(presenter.format_region_markers(marker_world, "quest.deploy_phase_relay_anchor"), "深段：更深，目标", "phase relay anchor deployment returns to deep region")
	host._expect_text_contains(presenter.format_region_markers(marker_world, "quest.reenter_phase_frontline"), "基地：当前位置，目标", "relay reentry starts from outpost pad")
	host._expect_text_contains(presenter.format_region_markers(marker_world, "quest.trace_phase_splinters"), "深段：更深，目标", "phase splinter tracing returns objective to deeper region")
	host._expect_text_contains(presenter.format_region_markers(marker_world, "quest.refine_phase_splinters"), "晶体：东侧，目标", "phase splinter refinement returns to treatment filter")
	host._expect_text_contains(presenter.format_region_markers(marker_world, "quest.tune_relay_lens"), "基地：当前位置，目标", "relay tuning lens returns to outpost reactor")
	host._expect_text_contains(presenter.format_region_markers(marker_world, "quest.inspect_phase_fault_spire"), "深段：更深，目标", "phase fault spire returns objective to deeper region")
	host._expect_text_contains(presenter.format_region_markers(marker_world, "quest.analyze_inner_fault_trace"), "基地：当前位置，目标", "inner fault analysis returns to outpost reactor")
	host._expect_text_contains(presenter.format_region_markers(marker_world, "quest.collect_fault_residue"), "深段：更深，目标", "fault residue collection returns objective to deeper region")
	host._expect_text_contains(presenter.format_region_markers(marker_world, "quest.refine_fault_residue"), "晶体：东侧，目标", "fault residue refinement returns to treatment filter")
	host._expect_text_contains(presenter.format_region_markers(marker_world, "quest.assemble_phase_well_key"), "基地：当前位置，目标", "phase well key assembly returns to outpost reactor")
	host._expect_text_contains(presenter.format_region_markers(marker_world, "quest.unlock_phase_well"), "深段：更深，目标", "phase well lock returns objective to deeper region")
	marker_world.current_region_id = "region.outpost_platform"
	marker_world.quest_state.completed_quest_ids.append("quest.deploy_phase_relay_anchor")
	host._expect_text_contains(presenter.format_region_markers(marker_world, ""), "深段：更深，目标", "phase relay completion keeps deep region targeted from outpost")
	marker_world.quest_state.completed_quest_ids.append("quest.unlock_phase_well")
	host._expect_text_contains(presenter.format_region_markers(marker_world, ""), "基地：当前位置，目标", "phase well completion returns runtime followup to outpost analysis")
	marker_world.unlock_region("region.inner_phase_well")
	host._expect_text_contains(presenter.format_region_markers(marker_world, "quest.collect_well_flux"), "井口：更东，目标", "well flux collection points to inner phase well marker")
	host._expect_array_has(presenter.format_map_marker_labels(marker_world, "quest.collect_well_flux"), "井口\n目标", "inner phase well minimap objective marker")
	marker_world.quest_state.completed_quest_ids.append("quest.inspect_inner_phase_well")
	host._expect_text_contains(presenter.format_region_markers(marker_world, ""), "基地：当前位置，目标", "inner phase well completion returns runtime followup to outpost analysis")
	marker_world.unlock_region("region.phase_well_sink")
	host._expect_text_contains(presenter.format_region_markers(marker_world, "quest.collect_well_ash"), "井底：更深，目标", "well ash collection points to phase well sink marker")
	host._expect_array_has(presenter.format_map_marker_labels(marker_world, "quest.collect_well_ash"), "井底\n目标", "phase well sink minimap objective marker")
	marker_world.quest_state.completed_quest_ids.append("quest.inspect_phase_well_sink")
	host._expect_text_contains(presenter.format_region_markers(marker_world, ""), "基地：当前位置，目标", "phase well sink completion returns runtime followup to outpost analysis")
	marker_world.unlock_region("region.phase_well_chamber")
	host._expect_text_contains(presenter.format_region_markers(marker_world, "quest.collect_heart_spine"), "心室：更东，目标", "heart spine collection points to phase well chamber marker")
	host._expect_array_has(presenter.format_map_marker_labels(marker_world, "quest.collect_heart_spine"), "心室\n目标", "phase well chamber minimap objective marker")
	marker_world.quest_state.completed_quest_ids.append("quest.inspect_phase_well_chamber")
	host._expect_text_contains(presenter.format_region_markers(marker_world, ""), "基地：当前位置，目标", "phase well chamber completion returns runtime followup to outpost analysis")
	host._expect_text_contains(presenter.format_region_markers(marker_world, "quest.analyze_phase_well_spindle"), "基地：当前位置，目标", "phase well spindle analysis returns to outpost reactor")
	marker_world.unlock_region("region.phase_well_loom")
	host._expect_text_contains(presenter.format_region_markers(marker_world, "quest.collect_weft_bundle"), "井纺：更东，目标", "weft bundle collection points to phase well loom marker")
	host._expect_array_has(presenter.format_map_marker_labels(marker_world, "quest.collect_weft_bundle"), "井纺\n目标", "phase well loom minimap objective marker")
	marker_world.quest_state.completed_quest_ids.append("quest.inspect_phase_well_loom")
	host._expect_text_contains(presenter.format_region_markers(marker_world, ""), "基地：当前位置，目标", "phase well loom completion returns runtime followup to outpost analysis")
	host._expect_text_contains(presenter.format_region_markers(marker_world, "quest.analyze_phase_well_weave_core"), "基地：当前位置，目标", "phase well weave core analysis returns to outpost reactor")
	marker_world.unlock_region("region.phase_well_frame")
	host._expect_text_contains(presenter.format_region_markers(marker_world, "quest.collect_selvedge_strip"), "井纹：更东，目标", "selvedge strip collection points to phase well frame marker")
	host._expect_array_has(presenter.format_map_marker_labels(marker_world, "quest.collect_selvedge_strip"), "井纹\n目标", "phase well frame minimap objective marker")
	marker_world.quest_state.completed_quest_ids.append("quest.inspect_phase_well_frame")
	host._expect_text_contains(presenter.format_region_markers(marker_world, ""), "基地：当前位置，目标", "phase well frame completion returns runtime followup to outpost analysis")
	marker_world.unlock_region("region.phase_well_tether")
	host._expect_text_contains(presenter.format_region_markers(marker_world, "quest.collect_tether_fiber"), "井系：更东，目标", "tether fiber collection points to phase well tether marker")
	host._expect_array_has(presenter.format_map_marker_labels(marker_world, "quest.collect_tether_fiber"), "井系\n目标", "phase well tether minimap objective marker")
	marker_world.quest_state.completed_quest_ids.append("quest.inspect_phase_well_tether")
	host._expect_text_contains(presenter.format_region_markers(marker_world, ""), "基地：当前位置，目标", "phase well tether completion returns runtime followup to outpost analysis")

	var hud := PrototypeHudScene.instantiate() as PrototypeHud
	root_window.add_child(hud)
	hud._ensure_runtime_nodes()
	host._expect_equal(hud.map_marker_rects.size(), 11, "prototype hud runtime map marker count includes phase well tether")
	host._expect_equal(hud.map_marker_labels.size(), 11, "prototype hud runtime map label count includes phase well tether")
	if hud.get_node_or_null("MapPanel/PhaseWellFrameMarker") == null:
		host.failures.append("prototype hud scene should include phase well frame marker node")
	if hud.get_node_or_null("MapPanel/PhaseWellFrameLabel") == null:
		host.failures.append("prototype hud scene should include phase well frame label node")
	if hud.get_node_or_null("MapPanel/PhaseWellTetherMarker") == null:
		host.failures.append("prototype hud scene should include phase well tether marker node")
	if hud.get_node_or_null("MapPanel/PhaseWellTetherLabel") == null:
		host.failures.append("prototype hud scene should include phase well tether label node")
	hud._set_control_rect(hud.map_panel, Vector2.ZERO, Vector2(448.0, 208.0))
	hud._layout_map_panel_contents()
	for label in hud.map_marker_labels:
		_assert_control_within_panel(label, hud.map_panel, "prototype hud minimap label")
	hud.free()
	map.free()


func _assert_control_within_panel(control: Control, panel: Control, label: String) -> void:
	if control == null:
		host.failures.append("%s should exist" % label)
		return
	if panel == null:
		host.failures.append("%s panel should exist" % label)
		return
	if control.position.x < -0.01 or control.position.y < -0.01:
		host.failures.append("%s should stay within panel bounds, got position %s" % [label, var_to_str(control.position)])
		return
	if control.position.x + control.size.x > panel.size.x + 0.01 or control.position.y + control.size.y > panel.size.y + 0.01:
		host.failures.append("%s should stay within panel bounds, got position %s size %s panel %s" % [
			label,
			var_to_str(control.position),
			var_to_str(control.size),
			var_to_str(panel.size)
		])
