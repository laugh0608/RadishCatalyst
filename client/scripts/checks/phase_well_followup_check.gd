extends RefCounted

var host


func _init(check_host) -> void:
	host = check_host


func run_flow(world_state: WorldState, character_state: CharacterState) -> void:
	host._expect_active_quest("quest.analyze_phase_well_heart", "after phase well sink returns to heart analysis")
	host._complete_active_quest("quest.analyze_phase_well_heart", [{"type": "craft_item", "target_id": "item.phase_well_pulse_sheet", "amount": 1}])
	host._expect_active_quest("quest.collect_heart_spine", "after heart analysis returns to chamber edge")
	host._expect_array_has(world_state.unlocked_region_ids, "region.phase_well_chamber", "phase well heart analysis unlocks phase well chamber region")
	host._complete_active_quest("quest.collect_heart_spine", [
		{"type": "visit_region", "target_id": "region.phase_well_chamber", "amount": 1},
		{"type": "inspect", "target_id": "map_object.phase_well_chamber_shunt_node", "amount": 2},
		{"type": "defeat_enemy", "target_id": "enemy.phase_well_reaver", "amount": 1},
		{"type": "gather_item", "target_id": "item.heart_spine", "amount": 2}
	])
	host._expect_active_quest("quest.refine_heart_spine", "after heart spine collection returns to filter")
	host._expect_array_has(world_state.quest_state.unlocked_effects, "recipe.heart_spine_stabilization", "heart spine collection unlocks stabilization recipe")
	host._expect_array_has(world_state.quest_state.unlocked_effects, "recipe.phase_well_shunt", "heart spine collection unlocks phase well shunt recipe")
	host._complete_active_quest("quest.refine_heart_spine", [
		{"type": "craft_item", "target_id": "item.phase_well_damper", "amount": 1},
		{"type": "craft_item", "target_id": "item.phase_well_shunt", "amount": 1}
	])
	host._expect_active_quest("quest.inspect_phase_well_chamber", "after phase well shunt assembly returns to chamber")
	host._complete_active_quest("quest.inspect_phase_well_chamber", [{"type": "inspect", "target_id": "map_object.phase_well_chamber", "amount": 1}])
	host._expect_active_quest("quest.analyze_phase_well_spindle", "after phase well chamber returns to spindle analysis")
	host._expect_array_has(world_state.quest_state.completed_quest_ids, "quest.inspect_phase_well_chamber", "phase well chamber quest completed")
	host._expect_array_has(world_state.quest_state.unlocked_effects, "recipe.phase_well_spindle_analysis", "phase well chamber unlocks spindle analysis recipe")
	host._expect_equal(int(character_state.inventory.items.get("item.phase_well_spindle", 0)), 1, "phase well chamber grants first spindle reward")
	host._complete_active_quest("quest.analyze_phase_well_spindle", [{"type": "craft_item", "target_id": "item.phase_well_warp_sheet", "amount": 1}])
	host._expect_active_quest("quest.collect_weft_bundle", "after spindle analysis returns to loom edge")
	host._expect_array_has(world_state.unlocked_region_ids, "region.phase_well_loom", "phase well spindle analysis unlocks phase well loom region")
	host._complete_active_quest("quest.collect_weft_bundle", [
		{"type": "visit_region", "target_id": "region.phase_well_loom", "amount": 1},
		{"type": "inspect", "target_id": "map_object.phase_well_loom_tension_spool", "amount": 2},
		{"type": "defeat_enemy", "target_id": "enemy.phase_well_tangler", "amount": 1},
		{"type": "gather_item", "target_id": "item.weft_bundle", "amount": 2}
	])
	host._expect_active_quest("quest.refine_weft_bundle", "after weft bundle collection returns to filter")
	host._expect_array_has(world_state.quest_state.unlocked_effects, "recipe.weft_bundle_stabilization", "weft bundle collection unlocks stabilization recipe")
	host._expect_array_has(world_state.quest_state.unlocked_effects, "recipe.phase_well_shuttle", "weft bundle collection unlocks phase well shuttle recipe")
	host._complete_active_quest("quest.refine_weft_bundle", [
		{"type": "craft_item", "target_id": "item.phase_well_tension_rib", "amount": 1},
		{"type": "craft_item", "target_id": "item.phase_well_shuttle", "amount": 1}
	])
	host._expect_active_quest("quest.inspect_phase_well_loom", "after phase well shuttle assembly returns to loom")
	host._complete_active_quest("quest.inspect_phase_well_loom", [{"type": "inspect", "target_id": "map_object.phase_well_loom", "amount": 1}])
	host._expect_array_has(world_state.quest_state.completed_quest_ids, "quest.inspect_phase_well_loom", "phase well loom quest completed")
	host._expect_equal(int(character_state.inventory.items.get("item.phase_well_weave_core", 0)), 1, "phase well loom grants first weave core reward")
	host._expect_array_has(world_state.quest_state.unlocked_effects, "recipe.phase_well_weave_core_analysis", "phase well loom unlocks weave core analysis recipe")
	host._expect_active_quest("quest.analyze_phase_well_weave_core", "after phase well loom returns to weave core analysis")
	host._complete_active_quest("quest.analyze_phase_well_weave_core", [{"type": "craft_item", "target_id": "item.phase_well_pattern_sheet", "amount": 1}])
	host._expect_active_quest("quest.collect_selvedge_strip", "after weave core analysis returns to frame edge")
	host._expect_array_has(world_state.unlocked_region_ids, "region.phase_well_frame", "phase well weave core analysis unlocks phase well frame region")
	host._complete_active_quest("quest.collect_selvedge_strip", [
		{"type": "visit_region", "target_id": "region.phase_well_frame", "amount": 1},
		{"type": "clear", "target_id": "map_object.phase_well_frame_route_blocker", "amount": 1},
		{"type": "defeat_enemy", "target_id": "enemy.phase_well_raker", "amount": 1},
		{"type": "gather_item", "target_id": "item.selvedge_strip", "amount": 2}
	])
	host._expect_active_quest("quest.refine_selvedge_strip", "after selvedge strip collection returns to filter")
	host._expect_array_has(world_state.quest_state.unlocked_effects, "recipe.selvedge_strip_stabilization", "selvedge strip collection unlocks stabilization recipe")
	host._expect_array_has(world_state.quest_state.unlocked_effects, "recipe.phase_well_frame_key", "selvedge strip collection unlocks phase well frame key recipe")
	host._complete_active_quest("quest.refine_selvedge_strip", [
		{"type": "craft_item", "target_id": "item.phase_well_frame_rib", "amount": 1},
		{"type": "craft_item", "target_id": "item.phase_well_frame_key", "amount": 1}
	])
	host._expect_active_quest("quest.inspect_phase_well_frame", "after phase well frame key assembly returns to frame")
	host._complete_active_quest("quest.inspect_phase_well_frame", [{"type": "inspect", "target_id": "map_object.phase_well_frame", "amount": 1}])
	host._expect_array_has(world_state.quest_state.completed_quest_ids, "quest.inspect_phase_well_frame", "phase well frame quest completed")
	host._expect_equal(int(character_state.inventory.items.get("item.phase_well_knot_core", 0)), 1, "phase well frame grants first knot core reward")
	host._expect_array_has(world_state.quest_state.unlocked_effects, "recipe.phase_well_knot_core_analysis", "phase well frame unlocks knot core analysis recipe")
	host._expect_active_quest("quest.analyze_phase_well_knot_core", "after phase well frame returns to knot core analysis")
	host._complete_active_quest("quest.analyze_phase_well_knot_core", [{"type": "craft_item", "target_id": "item.phase_well_tether_sheet", "amount": 1}])
	host._expect_active_quest("quest.collect_tether_fiber", "after knot core analysis returns to tether edge")
	host._expect_array_has(world_state.unlocked_region_ids, "region.phase_well_tether", "phase well knot core analysis unlocks phase well tether region")
	host._complete_active_quest("quest.collect_tether_fiber", [
		{"type": "visit_region", "target_id": "region.phase_well_tether", "amount": 1},
		{"type": "inspect", "target_id": "map_object.phase_well_tether_knot_node", "amount": 2},
		{"type": "defeat_enemy", "target_id": "enemy.phase_well_binder", "amount": 1},
		{"type": "gather_item", "target_id": "item.tether_fiber", "amount": 2}
	])
	host._expect_active_quest("quest.refine_tether_fiber", "after tether fiber collection returns to filter")
	host._expect_array_has(world_state.quest_state.unlocked_effects, "recipe.tether_fiber_stabilization", "tether fiber collection unlocks stabilization recipe")
	host._expect_array_has(world_state.quest_state.unlocked_effects, "recipe.phase_well_tether_spike", "tether fiber collection unlocks phase well tether spike recipe")
	host._complete_active_quest("quest.refine_tether_fiber", [
		{"type": "craft_item", "target_id": "item.phase_well_tether_rib", "amount": 1},
		{"type": "craft_item", "target_id": "item.phase_well_tether_spike", "amount": 1}
	])
	host._expect_active_quest("quest.inspect_phase_well_tether", "after phase well tether spike assembly returns to tether")
	host._complete_active_quest("quest.inspect_phase_well_tether", [{"type": "inspect", "target_id": "map_object.phase_well_tether", "amount": 1}])
	host._expect_array_has(world_state.quest_state.completed_quest_ids, "quest.inspect_phase_well_tether", "phase well tether quest completed")
	host._expect_equal(int(character_state.inventory.items.get("item.phase_well_anchor_core", 0)), 1, "phase well tether grants first anchor core reward")
	host._expect_array_has(world_state.quest_state.unlocked_effects, "slice_01_complete", "phase well tether keeps slice completion unlock present")
	host._expect_array_has(world_state.quest_state.unlocked_effects, "recipe.phase_well_anchor_core_analysis", "phase well tether unlocks anchor core analysis recipe")
	host._expect_active_quest("quest.analyze_phase_well_anchor_core", "after phase well tether returns to anchor core analysis")
	host._complete_active_quest("quest.analyze_phase_well_anchor_core", [{"type": "craft_item", "target_id": "item.phase_well_return_sheet", "amount": 1}])
	host._expect_active_quest("quest.refine_anchor_core_dust", "after anchor core analysis returns to filter")
	host._expect_array_has(world_state.quest_state.unlocked_effects, "recipe.anchor_core_dust_stabilization", "anchor core analysis unlocks anchor dust stabilization recipe")
	host._expect_array_has(world_state.quest_state.unlocked_effects, "recipe.phase_well_anchor_stake", "anchor core analysis unlocks anchor stake recipe")
	host._complete_active_quest("quest.refine_anchor_core_dust", [
		{"type": "craft_item", "target_id": "item.anchor_field_filter", "amount": 1},
		{"type": "craft_item", "target_id": "item.phase_well_anchor_stake", "amount": 1}
	])
	host._expect_active_quest("quest.stabilize_phase_well_anchor_field", "after anchor stake assembly returns to frontier")
	host._complete_active_quest("quest.stabilize_phase_well_anchor_field", [
		{"type": "inspect", "target_id": "map_object.phase_well_anchor_field", "amount": 1},
		{"type": "clear", "target_id": "map_object.phase_well_anchor_pressure_pin", "amount": 2},
		{"type": "defeat_enemy", "target_id": "enemy.phase_well_warden", "amount": 1}
	])
	host._expect_active_quest("quest.analyze_phase_well_echo_shard", "after anchor field stabilization returns to echo shard analysis")
	host._expect_array_has(world_state.quest_state.completed_quest_ids, "quest.stabilize_phase_well_anchor_field", "anchor field stabilization quest completed")
	host._expect_equal(int(character_state.inventory.items.get("item.phase_well_echo_shard", 0)), 1, "anchor field stabilization grants first echo shard reward")
	host._expect_array_has(world_state.quest_state.unlocked_effects, "recipe.phase_well_echo_shard_analysis", "anchor field stabilization unlocks echo shard analysis recipe")
	host._complete_active_quest("quest.analyze_phase_well_echo_shard", [{"type": "craft_item", "target_id": "item.phase_well_stability_readout", "amount": 1}])
	host._expect_active_quest("quest.calibrate_phase_well_stability_window", "after echo shard analysis returns to field calibration")
	host._expect_array_has(world_state.quest_state.completed_quest_ids, "quest.analyze_phase_well_echo_shard", "echo shard analysis quest completed")
	host._complete_active_quest("quest.calibrate_phase_well_stability_window", [
		{"type": "inspect", "target_id": "map_object.phase_well_stability_node_west", "amount": 1},
		{"type": "inspect", "target_id": "map_object.phase_well_stability_node_core", "amount": 1},
		{"type": "inspect", "target_id": "map_object.phase_well_stability_node_east", "amount": 1}
	])
	host._expect_active_quest("quest.plan_stability_frontline_action", "after stability window calibration returns to base frontline action")
	host._expect_array_has(world_state.quest_state.completed_quest_ids, "quest.calibrate_phase_well_stability_window", "stability window calibration quest completed")
	host._expect_array_has(world_state.quest_state.unlocked_effects, "slice_01_complete", "stability window calibration keeps slice completion unlock present")
	host._complete_active_quest("quest.plan_stability_frontline_action", [{"type": "inspect", "target_id": "map_object.frontline_action_console", "amount": 1}])
	host._expect_active_quest("quest.survey_stability_echo_probe", "after frontline action confirmation returns to stability echo probe")
	host._complete_active_quest("quest.survey_stability_echo_probe", [
		{"type": "visit_region", "target_id": "region.phase_well_tether", "amount": 1},
		{"type": "inspect", "target_id": "map_object.stability_echo_probe", "amount": 1}
	])
	host._expect_array_has(world_state.quest_state.completed_quest_ids, "quest.survey_stability_echo_probe", "stability echo probe quest completed")
	host._expect_equal(int(character_state.inventory.items.get("item.stability_echo_sample", 0)), 1, "stability echo probe grants echo sample")
	host._expect_array_has(world_state.quest_state.unlocked_effects, "recipe.stability_echo_report", "stability echo probe unlocks echo report recipe")
	host._expect_active_quest("quest.analyze_stability_echo_sample", "after stability echo probe returns to base report analysis")
	var basic_parts_before_report := int(character_state.inventory.items.get("item.basic_parts", 0))
	var repair_gel_before_report := int(character_state.inventory.items.get("item.repair_gel", 0))
	var resistance_vial_before_report := int(character_state.inventory.items.get("item.resistance_vial_t1", 0))
	host._complete_active_quest("quest.analyze_stability_echo_sample", [{"type": "craft_item", "target_id": "item.frontline_action_report", "amount": 1}])
	host._expect_active_quest("quest.confirm_supply_frontline_action", "after stability echo report returns to supply action confirmation")
	host._expect_array_has(world_state.quest_state.completed_quest_ids, "quest.analyze_stability_echo_sample", "stability echo report quest completed")
	host._expect_array_has(world_state.quest_state.unlocked_effects, "slice_01_complete", "stability echo report keeps slice completion unlock present")
	host._expect_equal(int(character_state.inventory.items.get("item.basic_parts", 0)), basic_parts_before_report + 4, "stability echo report grants base supply parts")
	host._expect_equal(int(character_state.inventory.items.get("item.repair_gel", 0)), repair_gel_before_report + 1, "stability echo report grants next sortie repair gel")
	host._expect_equal(int(character_state.inventory.items.get("item.resistance_vial_t1", 0)), resistance_vial_before_report + 1, "stability echo report grants next sortie resistance vial")
	host._complete_active_quest("quest.confirm_supply_frontline_action", [{"type": "inspect", "target_id": "map_object.frontline_supply_console", "amount": 1}])
	host._expect_active_quest("quest.inspect_supply_return_marker", "after supply action confirmation returns to supply marker")
	host._complete_active_quest("quest.inspect_supply_return_marker", [
		{"type": "visit_region", "target_id": "region.phase_well_tether", "amount": 1},
		{"type": "inspect", "target_id": "map_object.supply_return_marker", "amount": 1}
	])
	host._expect_array_has(world_state.quest_state.completed_quest_ids, "quest.inspect_supply_return_marker", "supply return marker quest completed")
	host._expect_equal(int(character_state.inventory.items.get("item.supply_return_trace", 0)), 1, "supply return marker grants trace")
	host._expect_array_has(world_state.quest_state.unlocked_effects, "recipe.short_action_feedback", "supply return marker unlocks short action feedback recipe")
	host._expect_active_quest("quest.analyze_supply_return_trace", "after supply marker returns to base feedback analysis")
	var basic_parts_before_short_feedback := int(character_state.inventory.items.get("item.basic_parts", 0))
	var repair_gel_before_short_feedback := int(character_state.inventory.items.get("item.repair_gel", 0))
	var resistance_vial_before_short_feedback := int(character_state.inventory.items.get("item.resistance_vial_t1", 0))
	host._complete_active_quest("quest.analyze_supply_return_trace", [{"type": "craft_item", "target_id": "item.short_action_feedback", "amount": 1}])
	host._expect_active_quest("quest.confirm_route_frontline_action", "after short action feedback returns to route action confirmation")
	host._expect_array_has(world_state.quest_state.completed_quest_ids, "quest.analyze_supply_return_trace", "short action feedback quest completed")
	host._expect_array_has(world_state.quest_state.unlocked_effects, "slice_01_complete", "short action feedback keeps slice completion unlock present")
	host._expect_equal(int(character_state.inventory.items.get("item.basic_parts", 0)), basic_parts_before_short_feedback + 2, "short action feedback grants base supply parts")
	host._expect_equal(int(character_state.inventory.items.get("item.repair_gel", 0)), repair_gel_before_short_feedback + 1, "short action feedback grants repair gel")
	host._expect_equal(int(character_state.inventory.items.get("item.resistance_vial_t1", 0)), resistance_vial_before_short_feedback + 1, "short action feedback grants resistance vial")
	host._complete_active_quest("quest.confirm_route_frontline_action", [{"type": "inspect", "target_id": "map_object.frontline_route_console", "amount": 1}])
	host._expect_active_quest("quest.inspect_route_signal_marker", "after route action confirmation returns to route signal marker")
	host._complete_active_quest("quest.inspect_route_signal_marker", [
		{"type": "visit_region", "target_id": "region.phase_well_tether", "amount": 1},
		{"type": "inspect", "target_id": "map_object.route_signal_marker", "amount": 1}
	])
	host._expect_array_has(world_state.quest_state.completed_quest_ids, "quest.inspect_route_signal_marker", "route signal marker quest completed")
	host._expect_equal(int(character_state.inventory.items.get("item.route_signal_trace", 0)), 1, "route signal marker grants trace")
	host._expect_array_has(world_state.quest_state.unlocked_effects, "recipe.route_action_feedback", "route signal marker unlocks route action feedback recipe")
	host._expect_active_quest("quest.analyze_route_signal_trace", "after route marker returns to base feedback analysis")
	var basic_parts_before_route_feedback := int(character_state.inventory.items.get("item.basic_parts", 0))
	var repair_gel_before_route_feedback := int(character_state.inventory.items.get("item.repair_gel", 0))
	var resistance_vial_before_route_feedback := int(character_state.inventory.items.get("item.resistance_vial_t1", 0))
	host._complete_active_quest("quest.analyze_route_signal_trace", [{"type": "craft_item", "target_id": "item.route_action_feedback", "amount": 1}])
	host._expect_equal(
		world_state.quest_state.active_quest_ids,
		["quest.choose_steady_supply_action", "quest.choose_phase_survey_action"],
		"after route action feedback should activate base action choices"
	)
	host._expect_array_has(world_state.quest_state.completed_quest_ids, "quest.analyze_route_signal_trace", "route action feedback quest completed")
	host._expect_equal(int(character_state.inventory.items.get("item.basic_parts", 0)), basic_parts_before_route_feedback + 2, "route action feedback grants base supply parts")
	host._expect_equal(int(character_state.inventory.items.get("item.repair_gel", 0)), repair_gel_before_route_feedback + 1, "route action feedback grants repair gel")
	host._expect_equal(int(character_state.inventory.items.get("item.resistance_vial_t1", 0)), resistance_vial_before_route_feedback + 1, "route action feedback grants resistance vial")
	host._complete_active_quest("quest.choose_phase_survey_action", [{"type": "inspect", "target_id": "map_object.base_survey_choice_console", "amount": 1}])
	host._expect_equal(world_state.quest_state.active_quest_ids, ["quest.inspect_phase_survey_nodes"], "phase survey choice should close supply choice and activate survey targets")
	host._expect_array_has(world_state.quest_state.completed_quest_ids, "quest.choose_phase_survey_action", "phase survey choice quest completed")
	host._complete_active_quest("quest.inspect_phase_survey_nodes", [
		{"type": "visit_region", "target_id": "region.phase_well_tether", "amount": 1},
		{"type": "inspect", "target_id": "map_object.phase_survey_node_west", "amount": 1},
		{"type": "inspect", "target_id": "map_object.phase_survey_node_east", "amount": 1}
	])
	host._expect_array_has(world_state.quest_state.completed_quest_ids, "quest.inspect_phase_survey_nodes", "phase survey nodes quest completed")
	host._expect_equal(int(character_state.inventory.items.get("item.phase_survey_trace", 0)), 1, "phase survey nodes grant survey trace")
	host._expect_array_has(world_state.quest_state.unlocked_effects, "recipe.phase_survey_feedback", "phase survey nodes unlock feedback recipe")
	host._expect_active_quest("quest.analyze_phase_survey_trace", "after survey nodes returns to base feedback analysis")
	var basic_parts_before_survey_feedback := int(character_state.inventory.items.get("item.basic_parts", 0))
	var resistance_vial_before_survey_feedback := int(character_state.inventory.items.get("item.resistance_vial_t1", 0))
	host._complete_active_quest("quest.analyze_phase_survey_trace", [{"type": "craft_item", "target_id": "item.phase_survey_feedback", "amount": 1}])
	host._expect_equal(world_state.quest_state.active_quest_ids, [], "after survey feedback should have no active quest")
	host._expect_array_has(world_state.quest_state.completed_quest_ids, "quest.analyze_phase_survey_trace", "phase survey feedback quest completed")
	host._expect_equal(int(character_state.inventory.items.get("item.basic_parts", 0)), basic_parts_before_survey_feedback + 1, "phase survey feedback grants base parts")
	host._expect_equal(int(character_state.inventory.items.get("item.resistance_vial_t1", 0)), resistance_vial_before_survey_feedback + 1, "phase survey feedback grants resistance vial")


func run_hud_and_map_checks() -> void:
	_check_onboarding_hints()
	_check_status_panel_summary()
	_check_anchor_field_recovery()
	_check_echo_shard_analysis_progress()
	_check_stability_echo_report_progress()
	_check_stability_window_calibration_runtime()
	_check_region_presence_bounds()
	_check_phase_well_chamber_gate()
	_check_phase_well_loom_gate()
	_check_phase_well_frame_gate()
	_check_phase_well_tether_gate()


func _check_onboarding_hints() -> void:
	var presenter := HudHintPresenter.new()
	var hint_world := WorldState.create_default()
	var hint_character := CharacterState.create_default()
	var heart_completion_world := WorldState.create_default()
	heart_completion_world.quest_state.active_quest_ids.clear()
	heart_completion_world.quest_state.completed_quest_ids.append("quest.inspect_phase_well_sink")
	host._expect_text_contains(presenter.format_direction_hint(heart_completion_world, hint_character, ""), "回基地解析心核", "phase well heart completion direction highlights next base analysis")
	host._expect_text_contains(presenter.format_onboarding_hint(heart_completion_world, hint_character, ""), "相位井心核不是收尾", "phase well heart completion onboarding keeps next package explicit")
	host._expect_hint_contains(presenter, hint_world, hint_character, "quest.analyze_phase_well_heart", "脉搏片", "phase well heart analysis onboarding hint")
	host._expect_hint_contains(presenter, hint_world, hint_character, "quest.refine_heart_spine", "一次井心整备", "phase well shunt package onboarding hint")
	host._expect_hint_contains(presenter, hint_world, hint_character, "quest.analyze_phase_well_spindle", "经片", "phase well spindle analysis onboarding hint")
	host._expect_hint_contains(presenter, hint_world, hint_character, "quest.refine_weft_bundle", "一次井纺整备", "weft bundle package onboarding hint")
	host._expect_hint_contains(presenter, hint_world, hint_character, "quest.inspect_phase_well_loom", "井纺梭栓", "phase well loom onboarding hint")
	var chamber_completion_world := WorldState.create_default()
	chamber_completion_world.quest_state.active_quest_ids.clear()
	chamber_completion_world.quest_state.completed_quest_ids.append("quest.inspect_phase_well_chamber")
	host._expect_text_contains(presenter.format_direction_hint(chamber_completion_world, hint_character, ""), "回基地解析纺核", "phase well chamber completion direction points to spindle analysis")
	host._expect_text_contains(presenter.format_onboarding_hint(chamber_completion_world, hint_character, ""), "相位井纺核不是收尾", "phase well chamber completion onboarding keeps loom package explicit")
	var loom_completion_world := WorldState.create_default()
	loom_completion_world.quest_state.active_quest_ids.clear()
	loom_completion_world.quest_state.completed_quest_ids.append("quest.inspect_phase_well_loom")
	host._expect_text_contains(presenter.format_direction_hint(loom_completion_world, hint_character, ""), "回基地解析织核", "phase well loom completion direction points to phase well frame analysis")
	host._expect_text_contains(presenter.format_onboarding_hint(loom_completion_world, hint_character, ""), "相位井织核不是收尾", "phase well loom completion onboarding keeps frame package explicit")
	host._expect_hint_contains(presenter, hint_world, hint_character, "quest.analyze_phase_well_weave_core", "纹谱片", "phase well weave core analysis onboarding hint")
	host._expect_hint_contains(presenter, hint_world, hint_character, "quest.refine_selvedge_strip", "一次井纹架整备", "phase well frame key package onboarding hint")
	host._expect_hint_contains(presenter, hint_world, hint_character, "quest.inspect_phase_well_frame", "井纹架键栓", "phase well frame onboarding hint")
	var frame_completion_world := WorldState.create_default()
	frame_completion_world.quest_state.active_quest_ids.clear()
	frame_completion_world.quest_state.completed_quest_ids.append("quest.inspect_phase_well_frame")
	host._expect_text_contains(presenter.format_direction_hint(frame_completion_world, hint_character, ""), "回基地解析结核", "phase well frame completion direction points to tether analysis")
	host._expect_text_contains(presenter.format_onboarding_hint(frame_completion_world, hint_character, ""), "相位井结核不是收尾", "phase well frame completion onboarding keeps tether package explicit")
	host._expect_hint_contains(presenter, hint_world, hint_character, "quest.analyze_phase_well_knot_core", "系谱片", "phase well knot core analysis onboarding hint")
	host._expect_hint_contains(presenter, hint_world, hint_character, "quest.refine_tether_fiber", "一次井系整备", "phase well tether spike package onboarding hint")
	host._expect_hint_contains(presenter, hint_world, hint_character, "quest.inspect_phase_well_tether", "井系定桩", "phase well tether onboarding hint")
	var tether_completion_world := WorldState.create_default()
	tether_completion_world.quest_state.active_quest_ids.clear()
	tether_completion_world.quest_state.completed_quest_ids.append("quest.inspect_phase_well_tether")
	host._expect_text_contains(presenter.format_direction_hint(tether_completion_world, hint_character, ""), "解析锚核", "phase well tether completion direction points to anchor core analysis")
	host._expect_text_contains(presenter.format_onboarding_hint(tether_completion_world, hint_character, ""), "锚核不是收尾", "phase well tether completion onboarding keeps anchor-field package explicit")
	host._expect_hint_contains(presenter, hint_world, hint_character, "quest.analyze_phase_well_anchor_core", "归谱片", "phase well anchor core analysis onboarding hint")
	host._expect_hint_contains(presenter, hint_world, hint_character, "quest.refine_anchor_core_dust", "一次锚场整备", "anchor stake package onboarding hint")
	host._expect_hint_contains(presenter, hint_world, hint_character, "quest.stabilize_phase_well_anchor_field", "短守场", "anchor field stabilization onboarding hint")
	host._expect_hint_contains(presenter, hint_world, hint_character, "quest.stabilize_phase_well_anchor_field", "部署后的校锚桩会保留在现场", "anchor field stabilization onboarding keeps retry rule explicit before deployment")
	host._expect_hint_contains(presenter, hint_world, hint_character, "quest.analyze_phase_well_echo_shard", "前线回充", "echo shard analysis direction explains readout payoff")
	host._expect_hint_contains(presenter, hint_world, hint_character, "quest.calibrate_phase_well_stability_window", "西侧、中央、东侧", "stability window calibration direction explains node order")
	host._expect_hint_contains(presenter, hint_world, hint_character, "quest.plan_stability_frontline_action", "前线行动台", "frontline action confirmation direction explains base console")
	host._expect_hint_contains(presenter, hint_world, hint_character, "quest.survey_stability_echo_probe", "短行动的目标密度", "stability echo probe onboarding explains short field objective")
	host._expect_hint_contains(presenter, hint_world, hint_character, "quest.analyze_stability_echo_sample", "回到基地反馈", "stability echo sample analysis onboarding explains return report")
	host._expect_hint_contains(presenter, hint_world, hint_character, "quest.confirm_supply_frontline_action", "第二条行动", "supply action confirmation onboarding explains second action")
	host._expect_hint_contains(presenter, hint_world, hint_character, "quest.inspect_supply_return_marker", "一处回执标记", "supply marker onboarding explains short target")
	host._expect_hint_contains(presenter, hint_world, hint_character, "quest.analyze_supply_return_trace", "回到基地反馈", "supply trace analysis onboarding explains feedback loop")
	host._expect_hint_contains(presenter, hint_world, hint_character, "quest.confirm_route_frontline_action", "第三条行动", "route action confirmation onboarding explains third action")
	host._expect_hint_contains(presenter, hint_world, hint_character, "quest.inspect_route_signal_marker", "一处巡线信标", "route marker onboarding explains short target")
	host._expect_hint_contains(presenter, hint_world, hint_character, "quest.analyze_route_signal_trace", "基地行动选择", "route trace analysis onboarding points to choice prototype")
	host._expect_hint_contains(presenter, hint_world, hint_character, "quest.choose_steady_supply_action", "补给方案", "steady supply choice onboarding explains option")
	host._expect_hint_contains(presenter, hint_world, hint_character, "quest.choose_phase_survey_action", "测绘方案", "phase survey choice onboarding explains option")
	host._expect_hint_contains(presenter, hint_world, hint_character, "quest.inspect_steady_supply_drop", "风险更低", "steady supply field onboarding explains low-risk target")
	host._expect_hint_contains(presenter, hint_world, hint_character, "quest.inspect_phase_survey_nodes", "两处读数点", "phase survey field onboarding explains two-point target")
	var anchor_field_completion_world := WorldState.create_default()
	anchor_field_completion_world.quest_state.active_quest_ids.clear()
	anchor_field_completion_world.quest_state.completed_quest_ids.append("quest.stabilize_phase_well_anchor_field")
	host._expect_text_contains(presenter.format_direction_hint(anchor_field_completion_world, hint_character, ""), "稳定窗口", "anchor field completion direction summarizes stabilized window")
	host._expect_text_contains(presenter.format_onboarding_hint(anchor_field_completion_world, hint_character, ""), "基地先产出稳场工具", "anchor field completion onboarding summarizes new loop")
	var readout_completion_world := WorldState.create_default()
	readout_completion_world.quest_state.active_quest_ids.clear()
	readout_completion_world.quest_state.completed_quest_ids.append("quest.stabilize_phase_well_anchor_field")
	readout_completion_world.quest_state.completed_quest_ids.append("quest.analyze_phase_well_echo_shard")
	host._expect_text_contains(presenter.format_direction_hint(readout_completion_world, hint_character, ""), "三处稳窗节点", "readout completion direction points to field calibration")
	host._expect_text_contains(presenter.format_onboarding_hint(readout_completion_world, hint_character, ""), "按序校准", "readout completion onboarding summarizes calibration payoff")
	var calibration_completion_world := WorldState.create_default()
	calibration_completion_world.quest_state.active_quest_ids.clear()
	calibration_completion_world.quest_state.completed_quest_ids.append("quest.stabilize_phase_well_anchor_field")
	calibration_completion_world.quest_state.completed_quest_ids.append("quest.analyze_phase_well_echo_shard")
	calibration_completion_world.quest_state.completed_quest_ids.append("quest.calibrate_phase_well_stability_window")
	host._expect_text_contains(presenter.format_direction_hint(calibration_completion_world, hint_character, ""), "前线行动台", "calibration completion direction points to frontline action console")
	host._expect_text_contains(presenter.format_onboarding_hint(calibration_completion_world, hint_character, ""), "最短基地-前线-基地反馈", "calibration completion onboarding summarizes next loop")
	var frontline_report_world := WorldState.create_default()
	frontline_report_world.quest_state.active_quest_ids.clear()
	frontline_report_world.quest_state.completed_quest_ids.append("quest.calibrate_phase_well_stability_window")
	frontline_report_world.quest_state.completed_quest_ids.append("quest.plan_stability_frontline_action")
	frontline_report_world.quest_state.completed_quest_ids.append("quest.survey_stability_echo_probe")
	frontline_report_world.quest_state.completed_quest_ids.append("quest.analyze_stability_echo_sample")
	host._expect_text_contains(presenter.format_direction_hint(frontline_report_world, hint_character, ""), "短行动补给台", "frontline report completion direction points to supply console")
	host._expect_text_contains(presenter.format_onboarding_hint(frontline_report_world, hint_character, ""), "第二条行动", "frontline report completion onboarding explains next action")
	var short_feedback_world := WorldState.create_default()
	short_feedback_world.quest_state.active_quest_ids.clear()
	short_feedback_world.quest_state.completed_quest_ids.append("quest.calibrate_phase_well_stability_window")
	short_feedback_world.quest_state.completed_quest_ids.append("quest.plan_stability_frontline_action")
	short_feedback_world.quest_state.completed_quest_ids.append("quest.survey_stability_echo_probe")
	short_feedback_world.quest_state.completed_quest_ids.append("quest.analyze_stability_echo_sample")
	short_feedback_world.quest_state.completed_quest_ids.append("quest.confirm_supply_frontline_action")
	short_feedback_world.quest_state.completed_quest_ids.append("quest.inspect_supply_return_marker")
	short_feedback_world.quest_state.completed_quest_ids.append("quest.analyze_supply_return_trace")
	host._expect_text_contains(presenter.format_direction_hint(short_feedback_world, hint_character, ""), "巡线短行动台", "short feedback completion direction points to route action")
	host._expect_text_contains(presenter.format_onboarding_hint(short_feedback_world, hint_character, ""), "第三条行动", "short feedback completion onboarding explains route action")
	var route_feedback_world := WorldState.create_default()
	route_feedback_world.quest_state.active_quest_ids.clear()
	route_feedback_world.quest_state.completed_quest_ids.append("quest.calibrate_phase_well_stability_window")
	route_feedback_world.quest_state.completed_quest_ids.append("quest.plan_stability_frontline_action")
	route_feedback_world.quest_state.completed_quest_ids.append("quest.survey_stability_echo_probe")
	route_feedback_world.quest_state.completed_quest_ids.append("quest.analyze_stability_echo_sample")
	route_feedback_world.quest_state.completed_quest_ids.append("quest.confirm_supply_frontline_action")
	route_feedback_world.quest_state.completed_quest_ids.append("quest.inspect_supply_return_marker")
	route_feedback_world.quest_state.completed_quest_ids.append("quest.analyze_supply_return_trace")
	route_feedback_world.quest_state.completed_quest_ids.append("quest.confirm_route_frontline_action")
	route_feedback_world.quest_state.completed_quest_ids.append("quest.inspect_route_signal_marker")
	route_feedback_world.quest_state.completed_quest_ids.append("quest.analyze_route_signal_trace")
	host._expect_text_contains(presenter.format_direction_hint(route_feedback_world, hint_character, ""), "稳场补给", "route feedback completion direction points to base choice")
	host._expect_text_contains(presenter.format_onboarding_hint(route_feedback_world, hint_character, ""), "真实取舍", "route feedback completion onboarding explains choice shift")
	var anchor_field_deployed_world := WorldState.create_default()
	anchor_field_deployed_world.quest_state.active_quest_ids = ["quest.stabilize_phase_well_anchor_field"]
	anchor_field_deployed_world.ensure_map_object("map_object_instance.phase_well_anchor_field", "map_object.phase_well_anchor_field", "region.phase_well_tether")["anchor_field_deployed"] = true
	host._expect_text_contains(presenter.format_direction_hint(anchor_field_deployed_world, hint_character, "quest.stabilize_phase_well_anchor_field"), "失败后可直接重试", "anchor field direction keeps deployed retry rule explicit")
	host._expect_text_contains(presenter.format_onboarding_hint(anchor_field_deployed_world, hint_character, "quest.stabilize_phase_well_anchor_field"), "不需要回基地重做校锚桩", "anchor field onboarding keeps deployed retry rule explicit")


func _check_status_panel_summary() -> void:
	var presenter := HudStatusPresenter.new()
	var status_character := CharacterState.create_default()
	var phase_well_sink_text_world := WorldState.create_default()
	phase_well_sink_text_world.quest_state.active_quest_ids.clear()
	phase_well_sink_text_world.quest_state.completed_quest_ids.append("quest.inspect_phase_well_sink")
	var phase_well_sink_text := presenter.format_status_text(host.data_registry, phase_well_sink_text_world, status_character)
	host._expect_text_contains(phase_well_sink_text, "目标：相位井心核待解析", "status falls back to phase well heart analysis after sink")
	host._expect_text_contains(phase_well_sink_text, "回基地解析相位井心核后", "status progress keeps phase well heart followup summary")
	var phase_well_chamber_text_world := WorldState.create_default()
	phase_well_chamber_text_world.quest_state.active_quest_ids.clear()
	phase_well_chamber_text_world.quest_state.completed_quest_ids.append("quest.inspect_phase_well_chamber")
	var phase_well_chamber_text := presenter.format_status_text(host.data_registry, phase_well_chamber_text_world, status_character)
	host._expect_text_contains(phase_well_chamber_text, "目标：相位井纺核待解析", "status falls back to phase well spindle summary after chamber")
	host._expect_text_contains(phase_well_chamber_text, "回基地解析相位井纺核后", "status progress keeps phase well chamber followup summary")
	var phase_well_loom_text_world := WorldState.create_default()
	phase_well_loom_text_world.quest_state.active_quest_ids.clear()
	phase_well_loom_text_world.quest_state.completed_quest_ids.append("quest.inspect_phase_well_loom")
	var phase_well_loom_text := presenter.format_status_text(host.data_registry, phase_well_loom_text_world, status_character)
	host._expect_text_contains(phase_well_loom_text, "目标：相位井织核待解析", "status falls back to phase well weave core analysis after loom")
	host._expect_text_contains(phase_well_loom_text, "回基地解析相位井织核后", "status progress keeps phase well loom followup summary")
	var phase_well_frame_text_world := WorldState.create_default()
	phase_well_frame_text_world.quest_state.active_quest_ids.clear()
	phase_well_frame_text_world.quest_state.completed_quest_ids.append("quest.inspect_phase_well_frame")
	var phase_well_frame_text := presenter.format_status_text(host.data_registry, phase_well_frame_text_world, status_character)
	host._expect_text_contains(phase_well_frame_text, "目标：相位井结核待解析", "status falls back to phase well knot core analysis after frame")
	host._expect_text_contains(phase_well_frame_text, "回基地解析相位井结核后", "status progress keeps phase well frame followup summary")
	var phase_well_tether_text_world := WorldState.create_default()
	phase_well_tether_text_world.quest_state.active_quest_ids.clear()
	phase_well_tether_text_world.quest_state.completed_quest_ids.append("quest.inspect_phase_well_tether")
	var phase_well_tether_text := presenter.format_status_text(host.data_registry, phase_well_tether_text_world, status_character)
	host._expect_text_contains(phase_well_tether_text, "目标：相位井锚核待解析", "status falls back to phase well anchor analysis summary after tether")
	host._expect_text_contains(phase_well_tether_text, "稳定窗口", "status progress keeps post-tether anchor-field summary")
	var anchor_field_text_world := WorldState.create_default()
	anchor_field_text_world.quest_state.active_quest_ids.clear()
	anchor_field_text_world.quest_state.completed_quest_ids.append("quest.stabilize_phase_well_anchor_field")
	var anchor_field_text := presenter.format_status_text(host.data_registry, anchor_field_text_world, status_character)
	host._expect_text_contains(anchor_field_text, "目标：相位井余响片已带回", "status falls back to anchor field completion summary")
	host._expect_text_contains(anchor_field_text, "稳定窗口已生成", "status progress keeps anchor field completion summary")
	host._expect_text_contains(anchor_field_text, "解析后可校准", "status progress points to readout calibration")
	var readout_text_world := WorldState.create_default()
	readout_text_world.quest_state.active_quest_ids.clear()
	readout_text_world.quest_state.completed_quest_ids.append("quest.stabilize_phase_well_anchor_field")
	readout_text_world.quest_state.completed_quest_ids.append("quest.analyze_phase_well_echo_shard")
	var readout_text := presenter.format_status_text(host.data_registry, readout_text_world, status_character)
	host._expect_text_contains(readout_text, "目标：相位井稳窗读数待现场校准", "status falls back to readout calibration summary")
	host._expect_text_contains(readout_text, "顺序校准稳窗节点", "status progress points to stability node calibration")
	var calibration_text_world := WorldState.create_default()
	calibration_text_world.quest_state.active_quest_ids.clear()
	calibration_text_world.quest_state.completed_quest_ids.append("quest.stabilize_phase_well_anchor_field")
	calibration_text_world.quest_state.completed_quest_ids.append("quest.analyze_phase_well_echo_shard")
	calibration_text_world.quest_state.completed_quest_ids.append("quest.calibrate_phase_well_stability_window")
	var calibration_text := presenter.format_status_text(host.data_registry, calibration_text_world, status_character)
	host._expect_text_contains(calibration_text, "目标：前线行动待确认", "status falls back to frontline action confirmation after calibration")
	host._expect_text_contains(calibration_text, "前线行动台", "status progress points to base frontline action console")
	var frontline_report_text_world := WorldState.create_default()
	frontline_report_text_world.quest_state.active_quest_ids.clear()
	frontline_report_text_world.quest_state.completed_quest_ids.append("quest.stabilize_phase_well_anchor_field")
	frontline_report_text_world.quest_state.completed_quest_ids.append("quest.analyze_phase_well_echo_shard")
	frontline_report_text_world.quest_state.completed_quest_ids.append("quest.calibrate_phase_well_stability_window")
	frontline_report_text_world.quest_state.completed_quest_ids.append("quest.plan_stability_frontline_action")
	frontline_report_text_world.quest_state.completed_quest_ids.append("quest.survey_stability_echo_probe")
	frontline_report_text_world.quest_state.completed_quest_ids.append("quest.analyze_stability_echo_sample")
	var frontline_report_text := presenter.format_status_text(host.data_registry, frontline_report_text_world, status_character)
	host._expect_text_contains(frontline_report_text, "目标：补给短行动待确认", "status falls back to supply action after frontline report")
	host._expect_text_contains(frontline_report_text, "短行动补给台", "status progress points to supply action console")
	var short_feedback_text_world := WorldState.create_default()
	short_feedback_text_world.quest_state.active_quest_ids.clear()
	short_feedback_text_world.quest_state.completed_quest_ids.append("quest.stabilize_phase_well_anchor_field")
	short_feedback_text_world.quest_state.completed_quest_ids.append("quest.analyze_phase_well_echo_shard")
	short_feedback_text_world.quest_state.completed_quest_ids.append("quest.calibrate_phase_well_stability_window")
	short_feedback_text_world.quest_state.completed_quest_ids.append("quest.plan_stability_frontline_action")
	short_feedback_text_world.quest_state.completed_quest_ids.append("quest.survey_stability_echo_probe")
	short_feedback_text_world.quest_state.completed_quest_ids.append("quest.analyze_stability_echo_sample")
	short_feedback_text_world.quest_state.completed_quest_ids.append("quest.confirm_supply_frontline_action")
	short_feedback_text_world.quest_state.completed_quest_ids.append("quest.inspect_supply_return_marker")
	short_feedback_text_world.quest_state.completed_quest_ids.append("quest.analyze_supply_return_trace")
	var short_feedback_text := presenter.format_status_text(host.data_registry, short_feedback_text_world, status_character)
	host._expect_text_contains(short_feedback_text, "目标：巡线短行动待确认", "status falls back to route action after short feedback")
	host._expect_text_contains(short_feedback_text, "巡线短行动台", "status progress points to route action console")
	var route_feedback_text_world := WorldState.create_default()
	route_feedback_text_world.quest_state.active_quest_ids.clear()
	route_feedback_text_world.quest_state.completed_quest_ids.append("quest.stabilize_phase_well_anchor_field")
	route_feedback_text_world.quest_state.completed_quest_ids.append("quest.analyze_phase_well_echo_shard")
	route_feedback_text_world.quest_state.completed_quest_ids.append("quest.calibrate_phase_well_stability_window")
	route_feedback_text_world.quest_state.completed_quest_ids.append("quest.plan_stability_frontline_action")
	route_feedback_text_world.quest_state.completed_quest_ids.append("quest.survey_stability_echo_probe")
	route_feedback_text_world.quest_state.completed_quest_ids.append("quest.analyze_stability_echo_sample")
	route_feedback_text_world.quest_state.completed_quest_ids.append("quest.confirm_supply_frontline_action")
	route_feedback_text_world.quest_state.completed_quest_ids.append("quest.inspect_supply_return_marker")
	route_feedback_text_world.quest_state.completed_quest_ids.append("quest.analyze_supply_return_trace")
	route_feedback_text_world.quest_state.completed_quest_ids.append("quest.confirm_route_frontline_action")
	route_feedback_text_world.quest_state.completed_quest_ids.append("quest.inspect_route_signal_marker")
	route_feedback_text_world.quest_state.completed_quest_ids.append("quest.analyze_route_signal_trace")
	var route_feedback_text := presenter.format_status_text(host.data_registry, route_feedback_text_world, status_character)
	host._expect_text_contains(route_feedback_text, "目标：基地行动选择待确认", "status falls back to base action choice after route feedback")
	host._expect_text_contains(route_feedback_text, "稳场补给或相位测绘", "status progress points to base action options")


func _check_anchor_field_recovery() -> void:
	var runtime := PhaseWellFrontierRuntime.new(host.data_registry)
	var world_state := WorldState.create_default()
	world_state.quest_state.completed_quest_ids.append("quest.refine_anchor_core_dust")
	var object_state := world_state.ensure_map_object(
		"map_object_instance.phase_well_anchor_field",
		"map_object.phase_well_anchor_field",
		"region.phase_well_tether"
	)
	object_state["anchor_field_deployed"] = true
	object_state["anchor_field_pressure_active"] = false
	object_state["anchor_field_pressure_cleared"] = true
	var enemy_state := world_state.ensure_enemy(
		"enemy_instance.phase_well_warden",
		"enemy.phase_well_warden",
		"region.phase_well_tether",
		20.0
	)
	enemy_state["is_defeated"] = true
	var character_state := CharacterState.create_default()
	character_state.health = 70.0
	character_state.protection = 50.0
	var result := runtime.inspect_anchor_field(character_state, world_state)
	host._expect_equal(bool(result.get("success", false)), true, "anchor field stabilization should complete after pressure is cleared")
	host._expect_equal(character_state.health, 90.0, "anchor field stabilization restores health")
	host._expect_equal(character_state.protection, 85.0, "anchor field stabilization restores protection")
	host._expect_text_contains(String(result.get("message", "")), "稳定窗口回充", "anchor field completion log mentions recovery payoff")
	world_state.quest_state.completed_quest_ids.append("quest.stabilize_phase_well_anchor_field")
	world_state.quest_state.completed_quest_ids.append("quest.analyze_phase_well_echo_shard")
	character_state.health = 40.0
	character_state.protection = 30.0
	var readout_result := runtime.inspect_anchor_field(character_state, world_state)
	host._expect_equal(bool(readout_result.get("success", false)), true, "readout-calibrated anchor field remains interactable")
	host._expect_equal(character_state.health, 75.0, "readout-calibrated anchor field restores more health")
	host._expect_equal(character_state.protection, 85.0, "readout-calibrated anchor field restores more protection")
	host._expect_text_contains(String(readout_result.get("message", "")), "稳窗读数校准", "readout-calibrated anchor field log mentions readout payoff")


func _check_echo_shard_analysis_progress() -> void:
	var runtime := QuestRuntime.new(host.data_registry)
	var world_state := WorldState.create_default()
	var character_state := CharacterState.create_default()
	world_state.quest_state.active_quest_ids = ["quest.analyze_phase_well_echo_shard"]
	var result := runtime.advance_for_interaction(
		world_state,
		character_state,
		{
			"definition_id": "building.basic_reactor",
			"interaction_type": "process_recipe",
			"recipe_id": "recipe.phase_well_echo_shard_analysis"
		},
		{"success": true, "completed_recipe_id": "recipe.phase_well_echo_shard_analysis"}
	)
	host._expect_equal(
		world_state.quest_state.get_objective_progress(
			"quest.analyze_phase_well_echo_shard",
			"craft_item",
			"item.phase_well_stability_readout"
		),
		1.0,
		"echo shard analysis recipe completion advances stability readout objective"
	)
	host._expect_array_has(
		world_state.quest_state.completed_quest_ids,
		"quest.analyze_phase_well_echo_shard",
		"echo shard analysis recipe completion completes quest"
	)
	host._expect_equal(bool(result.get("accepted", false)), true, "echo shard analysis completion result accepted")

	var recovery_world := WorldState.create_default()
	var recovery_character := CharacterState.create_default()
	recovery_world.quest_state.active_quest_ids = ["quest.analyze_phase_well_echo_shard"]
	recovery_character.inventory.add_item("item.phase_well_stability_readout", 1)
	runtime.reconcile_active_objectives(recovery_world, recovery_character)
	host._expect_array_has(
		recovery_world.quest_state.completed_quest_ids,
		"quest.analyze_phase_well_echo_shard",
		"echo shard analysis recovers completed objective from inventory"
	)


func _check_stability_echo_report_progress() -> void:
	var runtime := QuestRuntime.new(host.data_registry)
	var world_state := WorldState.create_default()
	var character_state := CharacterState.create_default()
	world_state.quest_state.active_quest_ids = ["quest.analyze_stability_echo_sample"]
	var result := runtime.advance_for_interaction(
		world_state,
		character_state,
		{
			"definition_id": "building.basic_reactor",
			"interaction_type": "process_recipe",
			"recipe_id": "recipe.process_crystal_ore"
		},
		{"success": true, "completed_recipe_id": "recipe.stability_echo_report"}
	)
	host._expect_equal(
		world_state.quest_state.get_objective_progress(
			"quest.analyze_stability_echo_sample",
			"craft_item",
			"item.frontline_action_report"
		),
		1.0,
		"stability echo report completion advances frontline action report objective"
	)
	host._expect_array_has(
		world_state.quest_state.completed_quest_ids,
		"quest.analyze_stability_echo_sample",
		"stability echo report completion completes quest"
	)
	host._expect_array_has(
		world_state.quest_state.active_quest_ids,
		"quest.confirm_supply_frontline_action",
		"stability echo report completion activates supply action"
	)
	host._expect_equal(bool(result.get("accepted", false)), true, "stability echo report completion result accepted")

	var recovery_world := WorldState.create_default()
	var recovery_character := CharacterState.create_default()
	recovery_world.quest_state.active_quest_ids = ["quest.analyze_stability_echo_sample"]
	recovery_character.inventory.add_item("item.frontline_action_report", 1)
	runtime.reconcile_active_objectives(recovery_world, recovery_character)
	host._expect_array_has(
		recovery_world.quest_state.completed_quest_ids,
		"quest.analyze_stability_echo_sample",
		"stability echo report recovers completed objective from inventory"
	)
	var feedback_world := WorldState.create_default()
	var feedback_character := CharacterState.create_default()
	feedback_world.quest_state.active_quest_ids = ["quest.analyze_supply_return_trace"]
	var feedback_result := runtime.advance_for_interaction(
		feedback_world,
		feedback_character,
		{
			"definition_id": "building.basic_reactor",
			"interaction_type": "process_recipe",
			"recipe_id": "recipe.process_crystal_ore"
		},
		{"success": true, "completed_recipe_id": "recipe.short_action_feedback"}
	)
	host._expect_equal(
		feedback_world.quest_state.get_objective_progress(
			"quest.analyze_supply_return_trace",
			"craft_item",
			"item.short_action_feedback"
		),
		1.0,
		"short action feedback completion advances feedback objective"
	)
	host._expect_array_has(
		feedback_world.quest_state.completed_quest_ids,
		"quest.analyze_supply_return_trace",
		"short action feedback completion completes quest"
	)
	host._expect_array_has(
		feedback_world.quest_state.active_quest_ids,
		"quest.confirm_route_frontline_action",
		"short action feedback completion activates route action"
	)
	host._expect_equal(bool(feedback_result.get("accepted", false)), true, "short action feedback completion result accepted")
	var route_feedback_world := WorldState.create_default()
	var route_feedback_character := CharacterState.create_default()
	route_feedback_world.quest_state.active_quest_ids = ["quest.analyze_route_signal_trace"]
	var route_feedback_result := runtime.advance_for_interaction(
		route_feedback_world,
		route_feedback_character,
		{
			"definition_id": "building.basic_reactor",
			"interaction_type": "process_recipe",
			"recipe_id": "recipe.process_crystal_ore"
		},
		{"success": true, "completed_recipe_id": "recipe.route_action_feedback"}
	)
	host._expect_equal(
		route_feedback_world.quest_state.get_objective_progress(
			"quest.analyze_route_signal_trace",
			"craft_item",
			"item.route_action_feedback"
		),
		1.0,
		"route action feedback completion advances feedback objective"
	)
	host._expect_array_has(
		route_feedback_world.quest_state.completed_quest_ids,
		"quest.analyze_route_signal_trace",
		"route action feedback completion completes quest"
	)
	host._expect_equal(
		route_feedback_world.quest_state.active_quest_ids,
		["quest.choose_steady_supply_action", "quest.choose_phase_survey_action"],
		"route action feedback completion activates base action choices"
	)
	host._expect_equal(bool(route_feedback_result.get("accepted", false)), true, "route action feedback completion result accepted")


func _check_stability_window_calibration_runtime() -> void:
	var runtime := PhaseWellFrontierRuntime.new(host.data_registry)
	var world_state := WorldState.create_default()
	world_state.quest_state.completed_quest_ids.append("quest.stabilize_phase_well_anchor_field")
	world_state.quest_state.completed_quest_ids.append("quest.analyze_phase_well_echo_shard")
	var character_state := CharacterState.create_default()
	character_state.inventory.add_item("item.phase_well_stability_readout", 1)
	var out_of_order_result := runtime.inspect_stability_calibration_node(
		"map_object_instance.phase_well_stability_node_core",
		"map_object.phase_well_stability_node_core",
		character_state,
		world_state
	)
	host._expect_equal(bool(out_of_order_result.get("success", true)), false, "stability calibration should reject out-of-order node")
	host._expect_text_contains(String(out_of_order_result.get("message", "")), "相位序", "out-of-order stability calibration explains sequence")
	var west_result := runtime.inspect_stability_calibration_node(
		"map_object_instance.phase_well_stability_node_west",
		"map_object.phase_well_stability_node_west",
		character_state,
		world_state
	)
	host._expect_equal(bool(west_result.get("success", false)), true, "west stability node calibration should succeed")
	var west_state := world_state.get_map_object("map_object_instance.phase_well_stability_node_west")
	host._expect_equal(bool(west_state.get("stability_node_calibrated", false)), true, "west stability node should be marked calibrated")
	var core_result := runtime.inspect_stability_calibration_node(
		"map_object_instance.phase_well_stability_node_core",
		"map_object.phase_well_stability_node_core",
		character_state,
		world_state
	)
	host._expect_equal(bool(core_result.get("success", false)), true, "core stability node calibration should succeed after west")
	var east_result := runtime.inspect_stability_calibration_node(
		"map_object_instance.phase_well_stability_node_east",
		"map_object.phase_well_stability_node_east",
		character_state,
		world_state
	)
	host._expect_equal(bool(east_result.get("success", false)), true, "east stability node calibration should succeed after core")
	host._expect_text_contains(String(east_result.get("message", "")), "三处稳窗校准点", "final stability calibration message summarizes full sequence")


func _check_region_presence_bounds() -> void:
	var map := VerticalSliceMap.new()
	host._expect_equal(map._get_region_id_for_position(Vector2(2282, -18)), "region.phase_well_chamber", "phase well chamber should sit in the eastern chamber region")
	host._expect_equal(map._get_region_id_for_position(Vector2(2562, -18)), "region.phase_well_loom", "phase well loom should sit in the new eastern loom region")
	host._expect_equal(map._get_region_id_for_position(Vector2(2842, -18)), "region.phase_well_frame", "phase well frame should sit in the new eastern frame region")
	host._expect_equal(map._get_region_id_for_position(Vector2(3126, -18)), "region.phase_well_tether", "phase well tether should sit in the new eastern tether region")
	map.free()


func _check_phase_well_chamber_gate() -> void:
	var map := VerticalSliceMap.new()
	map.player = PlayerController.new()
	var chamber_gate_world := WorldState.create_default()
	chamber_gate_world.unlock_region("region.crystal_vein_field")
	chamber_gate_world.unlock_region("region.pollution_edge")
	chamber_gate_world.unlock_region("region.ruin_outer_ring")
	chamber_gate_world.unlock_region("region.deep_ruin_threshold")
	chamber_gate_world.unlock_region("region.inner_phase_well")
	chamber_gate_world.unlock_region("region.phase_well_sink")
	chamber_gate_world.quest_state.completed_quest_ids.append("quest.stabilize_outer_ring_barrier")
	chamber_gate_world.quest_state.completed_quest_ids.append("quest.unlock_deep_ruin_entrance")
	var chamber_gate_character := CharacterState.create_default()
	map.last_reported_region_id = chamber_gate_world.current_region_id
	map.player.position = Vector2(2106, -96)
	map.update_region_presence(chamber_gate_world, chamber_gate_character)
	host._expect_equal(map.player.position.x, 2012.0, "locked phase well chamber should push player before chamber region")
	host._expect_equal(chamber_gate_world.current_region_id, "region.phase_well_sink", "locked phase well chamber should keep sink region")
	var unlocked_chamber_world := WorldState.create_default()
	unlocked_chamber_world.unlock_region("region.crystal_vein_field")
	unlocked_chamber_world.unlock_region("region.pollution_edge")
	unlocked_chamber_world.unlock_region("region.ruin_outer_ring")
	unlocked_chamber_world.unlock_region("region.deep_ruin_threshold")
	unlocked_chamber_world.unlock_region("region.inner_phase_well")
	unlocked_chamber_world.unlock_region("region.phase_well_sink")
	unlocked_chamber_world.unlock_region("region.phase_well_chamber")
	unlocked_chamber_world.quest_state.completed_quest_ids.append("quest.stabilize_outer_ring_barrier")
	unlocked_chamber_world.quest_state.completed_quest_ids.append("quest.unlock_deep_ruin_entrance")
	var unlocked_chamber_character := CharacterState.create_default()
	map.last_reported_region_id = unlocked_chamber_world.current_region_id
	map.player.position = Vector2(2106, -96)
	map.update_region_presence(unlocked_chamber_world, unlocked_chamber_character)
	host._expect_equal(unlocked_chamber_world.current_region_id, "region.phase_well_chamber", "unlocked phase well chamber should update current region")
	map.player.free()
	map.free()


func _check_phase_well_loom_gate() -> void:
	var map := VerticalSliceMap.new()
	map.player = PlayerController.new()
	var loom_gate_world := WorldState.create_default()
	loom_gate_world.unlock_region("region.crystal_vein_field")
	loom_gate_world.unlock_region("region.pollution_edge")
	loom_gate_world.unlock_region("region.ruin_outer_ring")
	loom_gate_world.unlock_region("region.deep_ruin_threshold")
	loom_gate_world.unlock_region("region.inner_phase_well")
	loom_gate_world.unlock_region("region.phase_well_sink")
	loom_gate_world.unlock_region("region.phase_well_chamber")
	loom_gate_world.quest_state.completed_quest_ids.append("quest.stabilize_outer_ring_barrier")
	loom_gate_world.quest_state.completed_quest_ids.append("quest.unlock_deep_ruin_entrance")
	var loom_gate_character := CharacterState.create_default()
	map.last_reported_region_id = loom_gate_world.current_region_id
	map.player.position = Vector2(2386, -96)
	map.update_region_presence(loom_gate_world, loom_gate_character)
	host._expect_equal(map.player.position.x, 2292.0, "locked phase well loom should push player before loom region")
	host._expect_equal(loom_gate_world.current_region_id, "region.phase_well_chamber", "locked phase well loom should keep chamber region")
	var unlocked_loom_world := WorldState.create_default()
	unlocked_loom_world.unlock_region("region.crystal_vein_field")
	unlocked_loom_world.unlock_region("region.pollution_edge")
	unlocked_loom_world.unlock_region("region.ruin_outer_ring")
	unlocked_loom_world.unlock_region("region.deep_ruin_threshold")
	unlocked_loom_world.unlock_region("region.inner_phase_well")
	unlocked_loom_world.unlock_region("region.phase_well_sink")
	unlocked_loom_world.unlock_region("region.phase_well_chamber")
	unlocked_loom_world.unlock_region("region.phase_well_loom")
	unlocked_loom_world.quest_state.completed_quest_ids.append("quest.stabilize_outer_ring_barrier")
	unlocked_loom_world.quest_state.completed_quest_ids.append("quest.unlock_deep_ruin_entrance")
	var unlocked_loom_character := CharacterState.create_default()
	map.last_reported_region_id = unlocked_loom_world.current_region_id
	map.player.position = Vector2(2386, -96)
	map.update_region_presence(unlocked_loom_world, unlocked_loom_character)
	host._expect_equal(unlocked_loom_world.current_region_id, "region.phase_well_loom", "unlocked phase well loom should update current region")
	map.player.free()
	map.free()


func _check_phase_well_frame_gate() -> void:
	var map := VerticalSliceMap.new()
	map.player = PlayerController.new()
	var frame_gate_world := WorldState.create_default()
	frame_gate_world.unlock_region("region.crystal_vein_field")
	frame_gate_world.unlock_region("region.pollution_edge")
	frame_gate_world.unlock_region("region.ruin_outer_ring")
	frame_gate_world.unlock_region("region.deep_ruin_threshold")
	frame_gate_world.unlock_region("region.inner_phase_well")
	frame_gate_world.unlock_region("region.phase_well_sink")
	frame_gate_world.unlock_region("region.phase_well_chamber")
	frame_gate_world.unlock_region("region.phase_well_loom")
	frame_gate_world.quest_state.completed_quest_ids.append("quest.stabilize_outer_ring_barrier")
	frame_gate_world.quest_state.completed_quest_ids.append("quest.unlock_deep_ruin_entrance")
	var frame_gate_character := CharacterState.create_default()
	map.last_reported_region_id = frame_gate_world.current_region_id
	map.player.position = Vector2(2666, -96)
	map.update_region_presence(frame_gate_world, frame_gate_character)
	host._expect_equal(map.player.position.x, 2572.0, "locked phase well frame should push player before frame region")
	host._expect_equal(frame_gate_world.current_region_id, "region.phase_well_loom", "locked phase well frame should keep loom region")
	var unlocked_frame_world := WorldState.create_default()
	unlocked_frame_world.unlock_region("region.crystal_vein_field")
	unlocked_frame_world.unlock_region("region.pollution_edge")
	unlocked_frame_world.unlock_region("region.ruin_outer_ring")
	unlocked_frame_world.unlock_region("region.deep_ruin_threshold")
	unlocked_frame_world.unlock_region("region.inner_phase_well")
	unlocked_frame_world.unlock_region("region.phase_well_sink")
	unlocked_frame_world.unlock_region("region.phase_well_chamber")
	unlocked_frame_world.unlock_region("region.phase_well_loom")
	unlocked_frame_world.unlock_region("region.phase_well_frame")
	unlocked_frame_world.quest_state.completed_quest_ids.append("quest.stabilize_outer_ring_barrier")
	unlocked_frame_world.quest_state.completed_quest_ids.append("quest.unlock_deep_ruin_entrance")
	var unlocked_frame_character := CharacterState.create_default()
	map.last_reported_region_id = unlocked_frame_world.current_region_id
	map.player.position = Vector2(2666, -96)
	map.update_region_presence(unlocked_frame_world, unlocked_frame_character)
	host._expect_equal(unlocked_frame_world.current_region_id, "region.phase_well_frame", "unlocked phase well frame should update current region")
	map.player.free()
	map.free()


func _check_phase_well_tether_gate() -> void:
	var map := VerticalSliceMap.new()
	map.player = PlayerController.new()
	var tether_gate_world := WorldState.create_default()
	tether_gate_world.unlock_region("region.crystal_vein_field")
	tether_gate_world.unlock_region("region.pollution_edge")
	tether_gate_world.unlock_region("region.ruin_outer_ring")
	tether_gate_world.unlock_region("region.deep_ruin_threshold")
	tether_gate_world.unlock_region("region.inner_phase_well")
	tether_gate_world.unlock_region("region.phase_well_sink")
	tether_gate_world.unlock_region("region.phase_well_chamber")
	tether_gate_world.unlock_region("region.phase_well_loom")
	tether_gate_world.unlock_region("region.phase_well_frame")
	tether_gate_world.quest_state.completed_quest_ids.append("quest.stabilize_outer_ring_barrier")
	tether_gate_world.quest_state.completed_quest_ids.append("quest.unlock_deep_ruin_entrance")
	var tether_gate_character := CharacterState.create_default()
	map.last_reported_region_id = tether_gate_world.current_region_id
	map.player.position = Vector2(2946, -96)
	map.update_region_presence(tether_gate_world, tether_gate_character)
	host._expect_equal(map.player.position.x, 2852.0, "locked phase well tether should push player before tether region")
	host._expect_equal(tether_gate_world.current_region_id, "region.phase_well_frame", "locked phase well tether should keep frame region")
	var unlocked_tether_world := WorldState.create_default()
	unlocked_tether_world.unlock_region("region.crystal_vein_field")
	unlocked_tether_world.unlock_region("region.pollution_edge")
	unlocked_tether_world.unlock_region("region.ruin_outer_ring")
	unlocked_tether_world.unlock_region("region.deep_ruin_threshold")
	unlocked_tether_world.unlock_region("region.inner_phase_well")
	unlocked_tether_world.unlock_region("region.phase_well_sink")
	unlocked_tether_world.unlock_region("region.phase_well_chamber")
	unlocked_tether_world.unlock_region("region.phase_well_loom")
	unlocked_tether_world.unlock_region("region.phase_well_frame")
	unlocked_tether_world.unlock_region("region.phase_well_tether")
	unlocked_tether_world.quest_state.completed_quest_ids.append("quest.stabilize_outer_ring_barrier")
	unlocked_tether_world.quest_state.completed_quest_ids.append("quest.unlock_deep_ruin_entrance")
	var unlocked_tether_character := CharacterState.create_default()
	map.last_reported_region_id = unlocked_tether_world.current_region_id
	map.player.position = Vector2(2946, -96)
	map.update_region_presence(unlocked_tether_world, unlocked_tether_character)
	host._expect_equal(unlocked_tether_world.current_region_id, "region.phase_well_tether", "unlocked phase well tether should update current region")
	map.player.free()
	map.free()
