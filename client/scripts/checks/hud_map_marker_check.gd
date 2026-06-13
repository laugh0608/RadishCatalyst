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
	host._expect_equal(initial_map_labels.size(), 12, "minimap marker count includes demo stabilization core")
	host._expect_array_has(initial_map_labels, "基地\n当前\n目标", "outpost minimap current target marker")
	host._expect_array_has(initial_map_labels, "晶体\n未解锁", "crystal minimap locked marker")
	host._expect_array_has(initial_map_labels, "回声\n未解锁", "echo plateau minimap locked marker")
	host._expect_array_has(initial_map_labels, "盐壳\n未解锁", "salt flat minimap locked marker")
	host._expect_array_has(initial_map_labels, "碎晶\n未解锁", "shattered crystal ravine minimap locked marker")
	host._expect_array_has(initial_map_labels, "风蚀\n未解锁", "wind cut conduit minimap locked marker")
	host._expect_array_has(initial_map_labels, "锁相\n未解锁", "phase lock frame minimap locked marker")
	host._expect_array_has(initial_map_labels, "锚定\n未解锁", "anchor bridge minimap locked marker")
	host._expect_array_has(initial_map_labels, "核心\n未解锁", "demo stabilization core minimap locked marker")
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
	host._expect_text_contains(presenter.format_region_markers(marker_world, "quest.scout_ruin_outer_ring"), "封锁：更东，目标", "sealed ruin scouting points to sealed ruin marker")
	host._expect_array_has(presenter.format_map_marker_labels(marker_world, "quest.scout_ruin_outer_ring"), "封锁\n目标", "sealed ruin minimap objective marker")
	host._expect_text_contains(presenter.format_region_markers(marker_world, "quest.salvage_signal_echo"), "封锁：更东，目标", "signal echo salvage stays in sealed ruin")
	host._expect_text_contains(presenter.format_region_markers(marker_world, "quest.analyze_deep_signal"), "基地：当前位置，目标", "deep signal analysis returns to outpost reactor")
	host._expect_array_has(presenter.format_map_marker_labels(marker_world, "quest.analyze_deep_signal"), "基地\n当前\n目标", "deep signal analysis minimap returns to outpost")
	host._expect_text_contains(presenter.format_region_markers(marker_world, "quest.unlock_deep_ruin_entrance"), "封锁：更东，目标", "deep ruin door stays in sealed ruin")
	marker_world.unlock_region("region.deep_ruin_threshold")
	host._expect_text_contains(presenter.format_region_markers(marker_world, "quest.harvest_phase_filament"), "裂相：更深，目标", "phase filament salvage points to fracture ridge")
	host._expect_array_has(presenter.format_map_marker_labels(marker_world, "quest.harvest_phase_filament"), "裂相\n目标", "fracture ridge minimap objective marker")
	host._expect_text_contains(presenter.format_region_markers(marker_world, "quest.refine_phase_filament"), "晶体：东侧，目标", "phase filament filter points back to treatment filter")
	host._expect_text_contains(presenter.format_region_markers(marker_world, "quest.assemble_deep_override"), "基地：当前位置，目标", "deep override assembly returns to outpost reactor")
	host._expect_text_contains(presenter.format_region_markers(marker_world, "quest.unlock_deep_ruin_cache"), "裂相：更深，目标", "deep latch returns objective to fracture ridge")
	host._expect_text_contains(presenter.format_region_markers(marker_world, "quest.analyze_deep_core"), "基地：当前位置，目标", "deep core analysis returns to outpost reactor")
	host._expect_array_has(presenter.format_map_marker_labels(marker_world, "quest.analyze_deep_core"), "基地\n当前\n目标", "deep core analysis minimap returns to outpost")
	host._expect_text_contains(presenter.format_region_markers(marker_world, "quest.activate_deep_array"), "裂相：更深，目标", "deep array activation returns objective to fracture ridge")
	host._expect_text_contains(presenter.format_region_markers(marker_world, "quest.assemble_deep_signal_matrix"), "基地：当前位置，目标", "deep signal matrix assembly returns to outpost reactor")
	host._expect_text_contains(presenter.format_region_markers(marker_world, "quest.deploy_phase_relay_anchor"), "裂相：更深，目标", "phase relay anchor deployment returns to fracture ridge")
	host._expect_text_contains(presenter.format_region_markers(marker_world, "quest.reenter_phase_frontline"), "基地：当前位置，目标", "relay reentry starts from outpost pad")
	host._expect_text_contains(presenter.format_region_markers(marker_world, "quest.trace_phase_splinters"), "裂相：更深，目标", "phase splinter tracing returns objective to fracture ridge")
	host._expect_text_contains(presenter.format_region_markers(marker_world, "quest.refine_phase_splinters"), "晶体：东侧，目标", "phase splinter refinement returns to treatment filter")
	host._expect_text_contains(presenter.format_region_markers(marker_world, "quest.inspect_phase_fault_spire"), "裂相：更深，目标", "phase fault spire returns objective to fracture ridge")
	host._expect_text_contains(presenter.format_region_markers(marker_world, "quest.analyze_inner_fault_trace"), "基地：当前位置，目标", "inner fault analysis returns to outpost reactor")
	host._expect_text_contains(presenter.format_region_markers(marker_world, "quest.collect_fault_residue"), "裂相：更深，目标", "fault residue collection returns objective to fracture ridge")
	host._expect_text_contains(presenter.format_region_markers(marker_world, "quest.refine_fault_residue"), "晶体：东侧，目标", "fault residue refinement returns to treatment filter")
	host._expect_text_contains(presenter.format_region_markers(marker_world, "quest.unlock_phase_well"), "裂相：更深，目标", "phase well lock returns objective to fracture ridge")
	marker_world.current_region_id = "region.outpost_platform"
	marker_world.quest_state.completed_quest_ids.append("quest.deploy_phase_relay_anchor")
	host._expect_text_contains(presenter.format_region_markers(marker_world, ""), "裂相：更深，目标", "phase relay completion keeps fracture ridge targeted from outpost")
	marker_world.quest_state.completed_quest_ids.append("quest.unlock_phase_well")
	host._expect_text_contains(presenter.format_region_markers(marker_world, ""), "基地：当前位置，目标", "phase well completion returns runtime followup to outpost analysis")
	marker_world.unlock_region("region.inner_phase_well")
	host._expect_text_contains(presenter.format_region_markers(marker_world, "quest.collect_well_flux"), "回声：更东，目标", "well flux collection points to echo plateau marker")
	host._expect_array_has(presenter.format_map_marker_labels(marker_world, "quest.collect_well_flux"), "回声\n目标", "echo plateau minimap objective marker")
	marker_world.quest_state.completed_quest_ids.append("quest.inspect_inner_phase_well")
	host._expect_text_contains(presenter.format_region_markers(marker_world, ""), "基地：当前位置，目标", "inner phase well completion returns runtime followup to outpost analysis")
	marker_world.unlock_region("region.phase_well_sink")
	host._expect_text_contains(presenter.format_region_markers(marker_world, "quest.collect_well_ash"), "盐壳：更深，目标", "well ash collection points to salt flat marker")
	host._expect_array_has(presenter.format_map_marker_labels(marker_world, "quest.collect_well_ash"), "盐壳\n目标", "salt flat minimap objective marker")
	marker_world.quest_state.completed_quest_ids.append("quest.inspect_phase_well_sink")
	host._expect_text_contains(presenter.format_region_markers(marker_world, ""), "基地：当前位置，目标", "phase well sink completion returns runtime followup to outpost analysis")
	marker_world.unlock_region("region.phase_well_chamber")
	host._expect_text_contains(presenter.format_region_markers(marker_world, "quest.collect_heart_spine"), "碎晶：更东，目标", "heart spine collection points to shattered crystal ravine marker")
	host._expect_array_has(presenter.format_map_marker_labels(marker_world, "quest.collect_heart_spine"), "碎晶\n目标", "shattered crystal ravine minimap objective marker")
	marker_world.quest_state.completed_quest_ids.append("quest.inspect_phase_well_chamber")
	host._expect_text_contains(presenter.format_region_markers(marker_world, ""), "基地：当前位置，目标", "phase well chamber completion returns runtime followup to outpost analysis")
	host._expect_text_contains(presenter.format_region_markers(marker_world, "quest.analyze_phase_well_spindle"), "基地：当前位置，目标", "phase well spindle analysis returns to outpost reactor")
	marker_world.unlock_region("region.phase_well_loom")
	host._expect_text_contains(presenter.format_region_markers(marker_world, "quest.collect_weft_bundle"), "风蚀：更东，目标", "weft bundle collection points to wind cut conduit marker")
	host._expect_array_has(presenter.format_map_marker_labels(marker_world, "quest.collect_weft_bundle"), "风蚀\n目标", "wind cut conduit minimap objective marker")
	marker_world.quest_state.completed_quest_ids.append("quest.inspect_phase_well_loom")
	host._expect_text_contains(presenter.format_region_markers(marker_world, ""), "基地：当前位置，目标", "phase well loom completion returns runtime followup to outpost analysis")
	host._expect_text_contains(presenter.format_region_markers(marker_world, "quest.analyze_phase_well_weave_core"), "基地：当前位置，目标", "phase well weave core analysis returns to outpost reactor")
	marker_world.unlock_region("region.phase_well_frame")
	host._expect_text_contains(presenter.format_region_markers(marker_world, "quest.collect_selvedge_strip"), "锁相：更东，目标", "selvedge strip collection points to phase lock frame marker")
	host._expect_array_has(presenter.format_map_marker_labels(marker_world, "quest.collect_selvedge_strip"), "锁相\n目标", "phase lock frame minimap objective marker")
	marker_world.quest_state.completed_quest_ids.append("quest.inspect_phase_well_frame")
	host._expect_text_contains(presenter.format_region_markers(marker_world, ""), "基地：当前位置，目标", "phase well frame completion returns runtime followup to outpost analysis")
	marker_world.unlock_region("region.phase_well_tether")
	host._expect_text_contains(presenter.format_region_markers(marker_world, "quest.collect_tether_fiber"), "锚定：更东，目标", "tether fiber collection points to anchor bridge marker")
	host._expect_array_has(presenter.format_map_marker_labels(marker_world, "quest.collect_tether_fiber"), "锚定\n目标", "anchor bridge minimap objective marker")
	marker_world.quest_state.completed_quest_ids.append("quest.inspect_phase_well_tether")
	host._expect_text_contains(presenter.format_region_markers(marker_world, ""), "基地：当前位置，目标", "phase well tether completion returns runtime followup to outpost analysis")
	var survey_intel_world := WorldState.create_default()
	survey_intel_world.current_region_id = "region.outpost_platform"
	survey_intel_world.unlock_region("region.phase_well_tether")
	survey_intel_world.quest_state.completed_quest_ids.append("quest.analyze_phase_survey_trace")
	host._expect_text_contains(
		presenter.format_region_markers(survey_intel_world, ""),
		"锚定：更东，目标，测绘预告",
		"phase survey feedback reveals anchor bridge route target on map"
	)
	host._expect_array_has(
		presenter.format_map_marker_labels(survey_intel_world, ""),
		"锚定\n目标\n测绘预告",
		"phase survey feedback minimap labels anchor bridge route intel target"
	)
	host._expect_array_missing(
		presenter.format_map_marker_labels(survey_intel_world, "quest.collect_tether_fiber"),
		"锚定\n目标\n测绘预告",
		"phase survey route intel does not relabel normal quest targets as survey preview"
	)
	var active_window_world := WorldState.create_default()
	active_window_world.current_region_id = "region.outpost_platform"
	active_window_world.unlock_region("region.phase_well_tether")
	active_window_world.set_base_action_state_value(BaseActionDispatchPlan.FRONTLINE_WINDOW_STATUS_KEY, BaseActionDispatchPlan.STATUS_ACTIVE)
	active_window_world.set_base_action_state_value(BaseActionDispatchPlan.FRONTLINE_WINDOW_PLAN_KEY, BaseActionDispatchPlan.PLAN_STEADY_SUPPLY)
	host._expect_text_contains(
		presenter.format_region_markers(active_window_world, ""),
		"锚定：更东，目标",
		"active frontline window targets the anchor bridge on map"
	)
	var resolved_window_world := WorldState.create_default()
	resolved_window_world.current_region_id = "region.phase_well_tether"
	resolved_window_world.set_base_action_state_value(BaseActionDispatchPlan.FRONTLINE_WINDOW_STATUS_KEY, BaseActionDispatchPlan.STATUS_RESOLVED)
	resolved_window_world.set_base_action_state_value(BaseActionDispatchPlan.FRONTLINE_WINDOW_PLAN_KEY, BaseActionDispatchPlan.PLAN_STEADY_SUPPLY)
	resolved_window_world.set_base_action_state_value(BaseActionDispatchPlan.FRONTLINE_WINDOW_FEEDBACK_KEY, "前线异常窗口已处理。")
	host._expect_text_contains(
		presenter.format_region_markers(resolved_window_world, ""),
		"基地：西侧，目标",
		"resolved frontline window points map target back to base while player is still in front line"
	)
	var completed_window_review_world := WorldState.create_default()
	completed_window_review_world.current_region_id = "region.outpost_platform"
	completed_window_review_world.unlock_region("region.phase_well_tether")
	completed_window_review_world.set_base_action_state_value(
		BaseActionDispatchPlan.FRONTLINE_WINDOW_REVIEW_COUNT_KEY,
		BaseActionDispatchPlan.FRONTLINE_WINDOW_REVIEW_LIMIT + 1
	)
	host._expect_text_contains(
		presenter.format_region_markers(completed_window_review_world, ""),
		"核心：更东，目标",
		"completed frontline window review targets demo stabilization core on map"
	)
	host._expect_array_has(
		presenter.format_map_marker_labels(completed_window_review_world, ""),
		"核心\n目标",
		"completed frontline window review marks demo stabilization core as minimap target"
	)
	var completed_core_frontline_world := WorldState.create_default()
	completed_core_frontline_world.current_region_id = "region.demo_stabilization_core"
	completed_core_frontline_world.unlock_region("region.demo_stabilization_core")
	completed_core_frontline_world.quest_state.completed_quest_ids.append("quest.write_demo_stabilization_core")
	host._expect_text_contains(
		presenter.format_region_markers(completed_core_frontline_world, ""),
		"基地：西侧，目标",
		"completed demo core write points map target back to base from front line"
	)
	var completed_core_base_world := WorldState.create_default()
	completed_core_base_world.current_region_id = "region.outpost_platform"
	completed_core_base_world.unlock_region("region.demo_stabilization_core")
	completed_core_base_world.quest_state.completed_quest_ids.append("quest.write_demo_stabilization_core")
	host._expect_text_contains(
		presenter.format_region_markers(completed_core_base_world, ""),
		"核心：更东，目标",
		"completed demo core write points next sortie target back to core from base"
	)
	host._expect_array_has(
		presenter.format_map_marker_labels(completed_core_base_world, ""),
		"核心\n目标",
		"completed demo core write keeps core visible as next sortie minimap target"
	)

	var hud := PrototypeHudScene.instantiate() as PrototypeHud
	root_window.add_child(hud)
	hud._ensure_runtime_nodes()
	host._expect_equal(hud.map_marker_rects.size(), 12, "prototype hud runtime map marker count includes demo stabilization core")
	host._expect_equal(hud.map_marker_labels.size(), 12, "prototype hud runtime map label count includes demo stabilization core")
	if hud.get_node_or_null("MapPanel/PhaseWellFrameMarker") == null:
		host.failures.append("prototype hud scene should include phase well frame marker node")
	if hud.get_node_or_null("MapPanel/PhaseWellFrameLabel") == null:
		host.failures.append("prototype hud scene should include phase well frame label node")
	if hud.get_node_or_null("MapPanel/PhaseWellTetherMarker") == null:
		host.failures.append("prototype hud scene should include phase well tether marker node")
	if hud.get_node_or_null("MapPanel/PhaseWellTetherLabel") == null:
		host.failures.append("prototype hud scene should include phase well tether label node")
	if hud.get_node_or_null("MapPanel/DemoStabilizationCoreMarker") == null:
		host.failures.append("prototype hud scene should include demo stabilization core marker node")
	if hud.get_node_or_null("MapPanel/DemoStabilizationCoreLabel") == null:
		host.failures.append("prototype hud scene should include demo stabilization core label node")
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
