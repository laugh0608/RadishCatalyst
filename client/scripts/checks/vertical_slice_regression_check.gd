extends RefCounted

const GameRootScript := preload("res://scripts/game/game_root.gd")
const VerticalSliceMapScene := preload("res://scenes/maps/VerticalSliceMap.tscn")

var host


func _init(check_host) -> void:
	host = check_host


func run_ui_and_recipe_checks() -> void:
	_check_hud_log_presenter()
	_check_first_hour_guidance_copy()
	_check_first_hour_content_density()
	_check_pollution_gate_pressure_spawn_and_combat()
	_check_first_hour_objective_milestones()
	_check_first_hour_base_return_manufacturing_readability()
	_check_mid_demo_handoff_readability()
	_check_development_baseline_presenter()
	_check_demo_stabilization_baseline_status_panel()
	_check_game_root_development_baseline_factory()
	_check_game_root_gm_tools()
	_check_game_root_recipe_cycle_input_events()
	_check_resource_interaction_logs()
	_check_completed_recipe_followup_auto_selection()


func _check_first_hour_guidance_copy() -> void:
	var presenter := HudHintPresenter.new()
	presenter.configure(host.data_registry, null)
	var world := WorldState.create_default()
	var character := CharacterState.create_default()
	host._expect_text_contains(
		presenter.format_onboarding_hint(world, character, "quest.make_filter_module"),
		"降低污染防护消耗",
		"filter module onboarding explains field value"
	)
	character.inventory.add_item("item.filter_media", 1)
	host._expect_text_contains(
		presenter.format_direction_hint(world, character, "quest.make_filter_module"),
		"降低污染防护消耗",
		"filter module direction explains why crafting matters"
	)
	var processing := ProcessingSystem.new(host.data_registry)
	host._expect_text_contains(
		processing._get_completion_next_step("recipe.process_crystal_ore"),
		"反应器校准、过滤模块和地基",
		"crystal processing completion explains base use"
	)
	host._expect_text_contains(
		processing._get_completion_next_step("recipe.basic_filter_module"),
		"处理点北缘清障",
		"filter module completion points to field survivability"
	)
	host._expect_text_contains(
		processing._get_completion_next_step("recipe.repair_gel"),
		"处理点北缘清障",
		"repair gel completion points back to the next field fight"
	)
	host._expect_text_contains(
		processing._get_completion_next_step("recipe.cleanse_residue"),
		"快捷栏 2",
		"residue cleansing completion points to anti-pollution quick slot"
	)
	var pollution_world := WorldState.create_default()
	var pollution_character := CharacterState.create_default()
	pollution_character.equipment["suit_module"] = "equipment.filter_module_t1"
	pollution_world.unlock_region("region.pollution_edge")
	pollution_world.quest_state.active_quest_ids = ["quest.enter_pollution_edge"]
	pollution_world.quest_state.set_objective_progress("quest.enter_pollution_edge", "gather_item", "item.polluted_residue", 2)
	host._expect_text_contains(
		presenter.format_direction_hint(pollution_world, pollution_character, "quest.enter_pollution_edge"),
		"处理点过滤器",
		"pollution direction tells player to process gathered residue"
	)
	host._expect_text_contains(
		processing._get_completion_next_step("recipe.cleanse_residue", pollution_world),
		"第二批沉积物",
		"first residue cleansing completion points to the stocked return route"
	)
	pollution_world.quest_state.set_objective_progress("quest.enter_pollution_edge", "craft_item", "item.resistance_vial_t1", 1)
	host._expect_text_contains(
		presenter.format_onboarding_hint(pollution_world, pollution_character, "quest.enter_pollution_edge"),
		"第二批沉积物",
		"pollution onboarding returns to residue route after first vial"
	)
	pollution_world.quest_state.set_objective_progress("quest.enter_pollution_edge", "gather_item", "item.polluted_residue", 4)
	host._expect_text_contains(
		presenter.format_onboarding_hint(pollution_world, pollution_character, "quest.enter_pollution_edge"),
		"遗迹门前压力点",
		"pollution onboarding ties stocked vial to the next pressure point"
	)


func _check_first_hour_base_return_manufacturing_readability() -> void:
	var processing := ProcessingSystem.new(host.data_registry)
	var device_panel_presenter := HudDevicePanelPresenter.new()
	var status_presenter := HudStatusPresenter.new()
	var reactor := PrototypeInteractable.new()
	reactor.definition_id = "building.basic_reactor"
	reactor.interaction_type = "process_recipe"
	reactor.recipe_id = "recipe.process_crystal_ore"
	reactor.set_recipe_cycle([
		"recipe.process_crystal_ore",
		"recipe.analyze_anomaly_sample",
		"recipe.make_filter_media",
		"recipe.basic_filter_module"
	])
	var analysis_world := WorldState.create_default()
	analysis_world.quest_state.active_quest_ids = ["quest.analyze_anomaly_sample"]
	analysis_world.quest_state.unlock_effect("recipe.analyze_anomaly_sample")
	analysis_world.quest_state.set_objective_progress("quest.analyze_anomaly_sample", "gather_item", "item.anomaly_residue", 2)
	var analysis_character := CharacterState.create_default()
	var panel_texts := device_panel_presenter.format_device_panel_texts(
		host.data_registry,
		processing,
		reactor,
		analysis_character,
		analysis_world
	)
	host._expect_text_contains(
		String(panel_texts.get("status", "")),
		"过滤参数",
		"device panel explains why recommended sample analysis matters"
	)

	var module_world := WorldState.create_default()
	module_world.quest_state.active_quest_ids = ["quest.make_filter_module"]
	module_world.quest_state.unlock_effect("recipe.make_filter_media")
	var module_character := CharacterState.create_default()
	module_character.inventory.add_item("item.crystal_ore", 2)
	var module_text := status_presenter.format_vitals_text(host.data_registry, module_world, module_character)
	host._expect_text_contains(module_text, "建议配方：制备过滤介质", "base summary points to intermediate filter media")
	host._expect_text_contains(module_text, "继续组装基础过滤模块", "base summary explains filter media purpose")

	var supply_world := WorldState.create_default()
	supply_world.quest_state.active_quest_ids = ["quest.prepare_treatment_supplies"]
	supply_world.quest_state.set_objective_progress("quest.prepare_treatment_supplies", "craft_item", "item.repair_gel", 1)
	var supply_text := status_presenter.format_vitals_text(host.data_registry, supply_world, CharacterState.create_default())
	host._expect_text_missing(supply_text, "待制造：修复凝胶", "base summary stops repeating completed repair gel craft")
	host._expect_text_contains(supply_text, "当前目标先外出推进", "base summary returns to field after repair gel is ready")
	reactor.free()


func _check_mid_demo_handoff_readability() -> void:
	var processing := ProcessingSystem.new(host.data_registry)
	var device_panel_presenter := HudDevicePanelPresenter.new()
	var reactor := PrototypeInteractable.new()
	reactor.definition_id = "building.basic_reactor"
	reactor.interaction_type = "process_recipe"
	reactor.recipe_id = "recipe.deep_core_imprint"
	reactor.set_recipe_cycle([
		"recipe.process_crystal_ore",
		"recipe.deep_core_imprint",
		"recipe.deep_signal_matrix"
	])

	var core_world := WorldState.create_default()
	core_world.quest_state.active_quest_ids = ["quest.analyze_deep_core"]
	core_world.quest_state.unlock_effect("recipe.deep_core_imprint")
	core_world.add_base_structure("structure.basic_reactor", "building.basic_reactor", "region.outpost_platform")
	var core_character := CharacterState.create_default()
	core_character.inventory.add_item("item.deep_ruin_core", 1)
	var core_texts := device_panel_presenter.format_device_panel_texts(
		host.data_registry,
		processing,
		reactor,
		core_character,
		core_world
	)
	host._expect_text_contains(
		String(core_texts.get("status", "")),
		"裂相阵列台",
		"deep core device purpose points to array activation"
	)

	var matrix_world := WorldState.create_default()
	matrix_world.quest_state.active_quest_ids = ["quest.assemble_deep_signal_matrix"]
	matrix_world.quest_state.unlock_effect("recipe.deep_signal_matrix")
	matrix_world.add_base_structure("structure.basic_reactor", "building.basic_reactor", "region.outpost_platform")
	var matrix_character := CharacterState.create_default()
	matrix_character.inventory.add_item("item.phase_conduit", 2)
	matrix_character.inventory.add_fluid("fluid.polluted_slurry", 1.0)
	reactor.recipe_id = "recipe.deep_signal_matrix"
	var matrix_texts := device_panel_presenter.format_device_panel_texts(
		host.data_registry,
		processing,
		reactor,
		matrix_character,
		matrix_world
	)
	host._expect_text_contains(
		String(matrix_texts.get("status", "")),
		"前线回传锚点",
		"deep matrix device purpose points to relay anchor deployment"
	)

	var filter := PrototypeInteractable.new()
	filter.definition_id = "building.pollution_filter"
	filter.interaction_type = "process_recipe"
	filter.recipe_id = "recipe.phase_splinter_refining"
	filter.set_recipe_cycle(["recipe.phase_splinter_refining"])
	var splinter_world := WorldState.create_default()
	splinter_world.quest_state.active_quest_ids = ["quest.refine_phase_splinters"]
	splinter_world.quest_state.unlock_effect("recipe.phase_splinter_refining")
	splinter_world.add_base_structure("structure.pollution_filter_build_site", "building.pollution_filter", "region.pollution_edge")
	var splinter_character := CharacterState.create_default()
	splinter_character.inventory.add_item("item.phase_splinter", 2)
	var splinter_texts := device_panel_presenter.format_device_panel_texts(
		host.data_registry,
		processing,
		filter,
		splinter_character,
		splinter_world
	)
	host._expect_text_contains(
		String(splinter_texts.get("status", "")),
		"中继调谐镜",
		"phase splinter filter purpose points to relay lens tuning"
	)

	var lens_world := WorldState.create_default()
	lens_world.quest_state.active_quest_ids = ["quest.refine_phase_splinters"]
	lens_world.quest_state.unlock_effect("recipe.relay_tuning_lens")
	lens_world.add_base_structure("structure.basic_reactor", "building.basic_reactor", "region.outpost_platform")
	var lens_character := CharacterState.create_default()
	lens_character.inventory.add_item("item.phase_lens_blank", 1)
	lens_character.inventory.add_fluid("fluid.polluted_slurry", 1.0)
	lens_character.inventory.items["item.basic_parts"] = 2
	var lens_reactor := PrototypeInteractable.new()
	lens_reactor.definition_id = "building.basic_reactor"
	lens_reactor.interaction_type = "process_recipe"
	lens_reactor.recipe_id = "recipe.relay_tuning_lens"
	lens_reactor.set_recipe_cycle(["recipe.relay_tuning_lens"])
	var lens_texts := device_panel_presenter.format_device_panel_texts(
		host.data_registry,
		processing,
		lens_reactor,
		lens_character,
		lens_world
	)
	host._expect_text_contains(
		String(lens_texts.get("status", "")),
		"裂相尖塔",
		"relay lens device purpose points to phase fault spire"
	)
	reactor.free()
	filter.free()
	lens_reactor.free()


func _check_pollution_gate_pressure_spawn_and_combat() -> void:
	var map := VerticalSliceMap.new()
	map.data_registry = host.data_registry
	var gate_enemy := PrototypeEnemy.new()
	gate_enemy.definition_id = "enemy.polluted_skitter"
	gate_enemy.name = "PollutedSkitterGatePressure"
	gate_enemy.instance_id = "enemy_instance.polluted_skitter_gate_pressure"
	var gate_world := WorldState.create_default()
	gate_world.quest_state.active_quest_ids = ["quest.enter_pollution_edge"]
	host._expect_equal(map._should_enemy_spawn(gate_enemy, gate_world), false, "gate pressure enemy waits for residue vial stage to complete")
	gate_world.quest_state.active_quest_ids = ["quest.defeat_elite_node"]
	host._expect_equal(map._should_enemy_spawn(gate_enemy, gate_world), true, "gate pressure enemy appears with elite residue node")

	var combat_character := CharacterState.create_default()
	combat_character.equipment["suit_module"] = "equipment.filter_module_t1"
	var counter_message := map._apply_enemy_counterattack(gate_enemy, combat_character)
	host._expect_equal(int(roundf(combat_character.health * 10.0)), 919, "gate pressure enemy counterattack health pressure")
	host._expect_equal(combat_character.protection < 100.0, true, "gate pressure enemy counterattack protection pressure")
	host._expect_text_contains(counter_message, "防护 -2.6", "gate pressure enemy counterattack protection hint")
	gate_enemy.free()
	map.free()


func _check_first_hour_content_density() -> void:
	var map := VerticalSliceMapScene.instantiate() as VerticalSliceMap
	host.root.add_child(map)
	map.setup(host.data_registry)
	var interactable_expectations := {
		"Interactables/CrystalClusterSidePocket": "map_object.crystal_cluster",
		"Interactables/CrystalClusterTreatmentApproach": "map_object.crystal_cluster",
		"Interactables/FieldWreckageSouthPocket": "map_object.field_wreckage",
		"Interactables/FieldWreckageGateCache": "map_object.field_wreckage",
		"Interactables/FieldWreckageTreatmentApproach": "map_object.field_wreckage",
		"Interactables/PollutionResidueOuterPocket": "map_object.pollution_residue_patch",
		"Interactables/PollutionResidueDeep": "map_object.pollution_residue_patch",
		"Interactables/PollutionResidueRidgeCache": "map_object.pollution_residue_patch"
	}
	for node_path in interactable_expectations:
		var interactable := map.get_node_or_null(String(node_path)) as PrototypeInteractable
		host._expect_equal(interactable != null, true, "%s exists" % node_path)
		if interactable == null:
			continue
		host._expect_equal(
			interactable.definition_id,
			String(interactable_expectations[node_path]),
			"%s definition" % node_path
		)
	var enemy_expectations := {
		"Enemies/NativeSkitterPatrol": "enemy.native_skitter",
		"Enemies/PollutedSkitterDeep": "enemy.polluted_skitter",
		"Enemies/PollutedSkitterRidge": "enemy.polluted_skitter"
	}
	for node_path in enemy_expectations:
		var enemy := map.get_node_or_null(String(node_path)) as PrototypeEnemy
		host._expect_equal(enemy != null, true, "%s exists" % node_path)
		if enemy == null:
			continue
		host._expect_equal(
			enemy.definition_id,
			String(enemy_expectations[node_path]),
			"%s definition" % node_path
		)
	map.free()


func _check_first_hour_objective_milestones() -> void:
	var runtime := QuestRuntime.new(host.data_registry)
	var character := CharacterState.create_default()
	var calibrate_world := WorldState.create_default()
	calibrate_world.quest_state.active_quest_ids = ["quest.calibrate_reactor"]
	var calibrate_result := runtime.apply_objective_updates(calibrate_world, character, [
		{"quest_id": "quest.calibrate_reactor", "objective_type": "gather_item", "target_id": "item.salvage_scrap", "amount": 4.0, "mode": "add"}
	])
	host._expect_text_contains(
		" ".join(calibrate_result.get("log_messages", [])),
		"回基地使用基础反应器",
		"salvage milestone tells player to return to base"
	)
	var supply_world := WorldState.create_default()
	supply_world.quest_state.active_quest_ids = ["quest.prepare_treatment_supplies"]
	var supply_result := runtime.apply_objective_updates(supply_world, character, [
		{"quest_id": "quest.prepare_treatment_supplies", "objective_type": "craft_item", "target_id": "item.repair_gel", "amount": 1.0, "mode": "add"}
	])
	host._expect_text_contains(
		" ".join(supply_result.get("log_messages", [])),
		"处理点北缘",
		"repair gel milestone points back to field threat"
	)
	var pollution_world := WorldState.create_default()
	pollution_world.quest_state.active_quest_ids = ["quest.enter_pollution_edge"]
	var pollution_result := runtime.apply_objective_updates(pollution_world, character, [
		{"quest_id": "quest.enter_pollution_edge", "objective_type": "gather_item", "target_id": "item.polluted_residue", "amount": 4.0, "mode": "add"}
	])
	host._expect_text_contains(
		" ".join(pollution_result.get("log_messages", [])),
		"回处理点过滤器",
		"pollution residue milestone explains treatment reason"
	)
	var vial_result := runtime.apply_objective_updates(pollution_world, character, [
		{"quest_id": "quest.enter_pollution_edge", "objective_type": "craft_item", "target_id": "item.resistance_vial_t1", "amount": 1.0, "mode": "add"}
	])
	host._expect_text_contains(
		" ".join(vial_result.get("log_messages", [])),
		"第二批沉积物",
		"resistance vial milestone explains stocked return route"
	)


func check_task_recipe_selection(reactor: PrototypeInteractable, processing: ProcessingSystem) -> void:
	var recipe_world := WorldState.create_default()
	var recipe_character := CharacterState.create_default()
	var filter := PrototypeInteractable.new()
	filter.definition_id = "building.pollution_filter"
	filter.interaction_type = "process_recipe"
	filter.recipe_id = "recipe.cleanse_residue"
	filter.set_recipe_cycle([
		"recipe.cleanse_residue",
		"recipe.phase_filament_refining",
		"recipe.phase_splinter_refining",
		"recipe.fault_residue_stabilization",
		"recipe.well_flux_stabilization",
		"recipe.well_ash_stabilization",
		"recipe.heart_spine_stabilization",
		"recipe.weft_bundle_stabilization",
		"recipe.selvedge_strip_stabilization",
		"recipe.tether_fiber_stabilization",
		"recipe.anchor_core_dust_stabilization"
	])
	recipe_world.quest_state.active_quest_ids = ["quest.analyze_anomaly_sample"]
	recipe_world.quest_state.set_objective_progress("quest.analyze_anomaly_sample", "gather_item", "item.anomaly_residue", 2)
	host._expect_equal(
		processing.get_recommended_recipe_id(reactor, recipe_character, recipe_world),
		"recipe.analyze_anomaly_sample",
		"sample analysis task recipe selection"
	)
	recipe_world.quest_state.active_quest_ids = ["quest.make_filter_module"]
	host._expect_equal(
		processing.get_recommended_recipe_id(reactor, recipe_character, recipe_world),
		"recipe.make_filter_media",
		"filter module task first selects media recipe"
	)
	recipe_character.inventory.add_item("item.filter_media", 1)
	host._expect_equal(
		processing.get_recommended_recipe_id(reactor, recipe_character, recipe_world),
		"recipe.basic_filter_module",
		"filter module task selects module recipe after media"
	)
	recipe_character.inventory.items.erase("item.filter_media")
	recipe_character.inventory.items.erase("item.foundation_material")
	recipe_character.inventory.items["item.basic_parts"] = 4
	recipe_world.quest_state.active_quest_ids = ["quest.expand_treatment_point"]
	host._expect_equal(
		processing.get_recommended_recipe_id(reactor, recipe_character, recipe_world),
		"recipe.foundation_t1",
		"expand treatment point first selects foundation recipe"
	)
	recipe_world.add_base_structure(
		"structure.foundation_site_north",
		"building.foundation_t1",
		"region.pollution_edge",
		"map_object_instance.foundation_site_north"
	)
	recipe_world.add_base_structure(
		"structure.foundation_site_south",
		"building.foundation_t1",
		"region.pollution_edge",
		"map_object_instance.foundation_site_south"
	)
	host._expect_equal(
		processing.get_recommended_recipe_id(reactor, recipe_character, recipe_world),
		"recipe.make_filter_media",
		"expand treatment point selects filter media after foundations"
	)
	recipe_character.inventory.add_item("item.filter_media", 1)
	recipe_character.inventory.items["item.basic_parts"] = 2
	host._expect_equal(
		processing.get_recommended_recipe_id(reactor, recipe_character, recipe_world),
		"recipe.process_crystal_ore",
		"expand treatment point falls back to basic parts after filter media"
	)
	recipe_world.quest_state.active_quest_ids = ["quest.refine_phase_filament"]
	host._expect_equal(
		processing.get_recommended_recipe_id(filter, recipe_character, recipe_world),
		"recipe.phase_filament_refining",
		"phase filament refinement selects pollution filter recipe"
	)
	var deep_reactor := PrototypeInteractable.new()
	deep_reactor.definition_id = "building.basic_reactor"
	deep_reactor.interaction_type = "process_recipe"
	deep_reactor.recipe_id = "recipe.process_crystal_ore"
	deep_reactor.set_recipe_cycle([
		"recipe.process_crystal_ore",
		"recipe.reclaim_basic_parts",
		"recipe.deep_signal_analysis",
		"recipe.deep_override_key",
		"recipe.deep_core_imprint",
		"recipe.deep_signal_matrix",
		"recipe.relay_tuning_lens",
		"recipe.inner_fault_analysis",
		"recipe.phase_well_key",
		"recipe.phase_well_locator_analysis",
		"recipe.phase_well_probe",
		"recipe.phase_well_core_analysis",
		"recipe.phase_well_pike",
		"recipe.phase_well_heart_analysis",
		"recipe.phase_well_shunt",
		"recipe.phase_well_spindle_analysis",
		"recipe.phase_well_shuttle",
		"recipe.phase_well_weave_core_analysis",
		"recipe.phase_well_frame_key",
		"recipe.phase_well_knot_core_analysis",
		"recipe.phase_well_tether_spike",
		"recipe.phase_well_anchor_core_analysis",
		"recipe.phase_well_anchor_stake",
		"recipe.phase_well_echo_shard_analysis",
		"recipe.stability_echo_report",
		"recipe.short_action_feedback",
		"recipe.route_action_feedback",
		"recipe.steady_supply_feedback",
		"recipe.phase_survey_feedback",
		"recipe.pressure_clearance_feedback"
	])
	recipe_character.inventory.items["item.basic_parts"] = 1
	recipe_character.inventory.add_item("item.signal_echo_trace", 1)
	recipe_world.quest_state.active_quest_ids = ["quest.analyze_deep_signal"]
	host._expect_equal(
		processing.get_recommended_recipe_id(deep_reactor, recipe_character, recipe_world),
		"recipe.deep_signal_analysis",
		"deep signal analysis no longer falls back when basic parts are low"
	)
	recipe_character.inventory.items["item.basic_parts"] = 2
	host._expect_equal(
		processing.get_recommended_recipe_id(deep_reactor, recipe_character, recipe_world),
		"recipe.deep_signal_analysis",
		"deep signal analysis returns to reactor analysis recipe after basic parts are restored"
	)
	recipe_world.quest_state.active_quest_ids = ["quest.analyze_deep_core"]
	host._expect_equal(processing.get_recommended_recipe_id(deep_reactor, recipe_character, recipe_world), "recipe.deep_core_imprint", "deep core analysis selects reactor recipe")
	recipe_world.quest_state.active_quest_ids = ["quest.assemble_deep_override"]
	host._expect_equal(processing.get_recommended_recipe_id(deep_reactor, recipe_character, recipe_world), "recipe.deep_override_key", "deep override assembly selects reactor recipe")
	_check_mid_demo_missing_input_hints(processing)
	recipe_character.inventory.add_item("item.phase_conduit", 2)
	recipe_character.inventory.add_fluid("fluid.polluted_slurry", 1.0)
	recipe_character.inventory.items["item.basic_parts"] = 1
	recipe_world.quest_state.active_quest_ids = ["quest.assemble_deep_signal_matrix"]
	host._expect_equal(
		processing.get_recommended_recipe_id(deep_reactor, recipe_character, recipe_world),
		"recipe.deep_signal_matrix",
		"deep signal matrix no longer falls back when basic parts are low"
	)
	recipe_character.inventory.items["item.basic_parts"] = 2
	host._expect_equal(
		processing.get_recommended_recipe_id(deep_reactor, recipe_character, recipe_world),
		"recipe.deep_signal_matrix",
		"deep signal matrix assembly returns to reactor recipe after basic parts are restored"
	)
	recipe_world.quest_state.active_quest_ids = ["quest.refine_phase_splinters"]
	host._expect_equal(
		processing.get_recommended_recipe_id(filter, recipe_character, recipe_world),
		"recipe.phase_splinter_refining",
		"phase splinter refining selects pollution filter recipe"
	)
	recipe_character.inventory.add_item("item.phase_lens_blank", 1)
	recipe_character.inventory.add_fluid("fluid.polluted_slurry", 1.0)
	recipe_character.inventory.items["item.basic_parts"] = 1
	host._expect_equal(
		processing.get_recommended_recipe_id(deep_reactor, recipe_character, recipe_world),
		"recipe.process_crystal_ore",
		"relay lens expedition prep falls back to basic parts recipe when only parts are missing"
	)
	recipe_world.quest_state.unlock_effect("recipe.reclaim_basic_parts")
	host._expect_equal(
		processing.get_recommended_recipe_id(deep_reactor, recipe_character, recipe_world),
		"recipe.reclaim_basic_parts",
		"relay lens expedition prep prefers slurry reclaim after phase relay unlock"
	)
	recipe_world.quest_state.unlocked_effects.erase("recipe.reclaim_basic_parts")
	recipe_character.inventory.items["item.basic_parts"] = 2
	host._expect_equal(
		processing.get_recommended_recipe_id(deep_reactor, recipe_character, recipe_world),
		"recipe.relay_tuning_lens",
		"relay lens expedition prep returns to reactor recipe after basic parts are restored"
	)
	recipe_character.inventory.add_item("item.inner_fault_trace", 1)
	recipe_character.inventory.items["item.basic_parts"] = 1
	recipe_world.quest_state.active_quest_ids = ["quest.analyze_inner_fault_trace"]
	host._expect_equal(
		processing.get_recommended_recipe_id(deep_reactor, recipe_character, recipe_world),
		"recipe.inner_fault_analysis",
		"inner fault analysis no longer falls back when basic parts are low"
	)
	recipe_character.inventory.items["item.basic_parts"] = 2
	host._expect_equal(
		processing.get_recommended_recipe_id(deep_reactor, recipe_character, recipe_world),
		"recipe.inner_fault_analysis",
		"inner fault analysis returns to reactor recipe after basic parts are restored"
	)
	recipe_world.quest_state.active_quest_ids = ["quest.refine_fault_residue"]
	host._expect_equal(
		processing.get_recommended_recipe_id(filter, recipe_character, recipe_world),
		"recipe.fault_residue_stabilization",
		"fault residue refinement selects pollution filter recipe"
	)
	recipe_character.inventory.add_item("item.phase_well_coordinate", 1)
	recipe_character.inventory.add_item("item.stabilized_fault_core", 1)
	recipe_character.inventory.items["item.basic_parts"] = 1
	host._expect_equal(
		processing.get_recommended_recipe_id(deep_reactor, recipe_character, recipe_world),
		"recipe.process_crystal_ore",
		"phase well key prep falls back to basic parts recipe when only parts are missing"
	)
	recipe_character.inventory.items["item.basic_parts"] = 2
	host._expect_equal(
		processing.get_recommended_recipe_id(deep_reactor, recipe_character, recipe_world),
		"recipe.phase_well_key",
		"phase well key prep returns to reactor recipe after basic parts are restored"
	)
	recipe_character.inventory.add_item("item.phase_well_locator", 1)
	recipe_character.inventory.items["item.basic_parts"] = 1
	recipe_world.quest_state.active_quest_ids = ["quest.analyze_phase_well_locator"]
	host._expect_equal(
		processing.get_recommended_recipe_id(deep_reactor, recipe_character, recipe_world),
		"recipe.phase_well_locator_analysis",
		"phase well locator analysis no longer falls back when basic parts are low"
	)
	recipe_character.inventory.items["item.basic_parts"] = 2
	host._expect_equal(
		processing.get_recommended_recipe_id(deep_reactor, recipe_character, recipe_world),
		"recipe.phase_well_locator_analysis",
		"phase well locator analysis returns to reactor recipe after basic parts are restored"
	)
	recipe_world.quest_state.active_quest_ids = ["quest.refine_well_flux"]
	host._expect_equal(
		processing.get_recommended_recipe_id(filter, recipe_character, recipe_world),
		"recipe.well_flux_stabilization",
		"phase well probe prep selects pollution filter recipe first"
	)
	recipe_character.inventory.add_item("item.phase_well_route", 1)
	recipe_character.inventory.add_item("item.phase_well_stabilizer", 1)
	recipe_character.inventory.items["item.basic_parts"] = 1
	recipe_world.quest_state.active_quest_ids = ["quest.refine_well_flux"]
	host._expect_equal(
		processing.get_recommended_recipe_id(deep_reactor, recipe_character, recipe_world),
		"recipe.process_crystal_ore",
		"phase well probe prep falls back to basic parts recipe when only parts are missing"
	)
	recipe_character.inventory.items["item.basic_parts"] = 2
	host._expect_equal(
		processing.get_recommended_recipe_id(deep_reactor, recipe_character, recipe_world),
		"recipe.phase_well_probe",
		"phase well probe prep returns to reactor recipe after basic parts are restored"
	)
	recipe_character.inventory.add_item("item.phase_well_core", 1)
	recipe_character.inventory.items["item.basic_parts"] = 1
	recipe_world.quest_state.active_quest_ids = ["quest.analyze_phase_well_core"]
	host._expect_equal(
		processing.get_recommended_recipe_id(deep_reactor, recipe_character, recipe_world),
		"recipe.phase_well_core_analysis",
		"phase well core analysis no longer falls back when basic parts are low"
	)
	recipe_character.inventory.items["item.basic_parts"] = 2
	host._expect_equal(
		processing.get_recommended_recipe_id(deep_reactor, recipe_character, recipe_world),
		"recipe.phase_well_core_analysis",
		"phase well core analysis returns to reactor recipe after basic parts are restored"
	)
	recipe_world.quest_state.active_quest_ids = ["quest.refine_well_ash"]
	host._expect_equal(
		processing.get_recommended_recipe_id(filter, recipe_character, recipe_world),
		"recipe.well_ash_stabilization",
		"well ash refinement selects pollution filter recipe"
	)
	recipe_character.inventory.add_item("item.phase_well_spectrum", 1)
	recipe_character.inventory.add_item("item.phase_well_lattice", 1)
	recipe_character.inventory.items["item.basic_parts"] = 1
	recipe_world.quest_state.active_quest_ids = ["quest.assemble_phase_well_pike"]
	host._expect_equal(
		processing.get_recommended_recipe_id(deep_reactor, recipe_character, recipe_world),
		"recipe.process_crystal_ore",
		"phase well pike assembly falls back to basic parts recipe when only parts are missing"
	)
	recipe_character.inventory.items["item.basic_parts"] = 2
	host._expect_equal(
		processing.get_recommended_recipe_id(deep_reactor, recipe_character, recipe_world),
		"recipe.phase_well_pike",
		"phase well pike assembly returns to reactor recipe after basic parts are restored"
	)
	recipe_character.inventory.add_item("item.phase_well_heart", 1)
	recipe_character.inventory.items["item.basic_parts"] = 1
	recipe_world.quest_state.active_quest_ids = ["quest.analyze_phase_well_heart"]
	host._expect_equal(
		processing.get_recommended_recipe_id(deep_reactor, recipe_character, recipe_world),
		"recipe.phase_well_heart_analysis",
		"phase well heart analysis no longer falls back when basic parts are low"
	)
	recipe_character.inventory.items["item.basic_parts"] = 2
	host._expect_equal(
		processing.get_recommended_recipe_id(deep_reactor, recipe_character, recipe_world),
		"recipe.phase_well_heart_analysis",
		"phase well heart analysis returns to reactor recipe after basic parts are restored"
	)
	recipe_world.quest_state.active_quest_ids = ["quest.refine_heart_spine"]
	host._expect_equal(
		processing.get_recommended_recipe_id(filter, recipe_character, recipe_world),
		"recipe.heart_spine_stabilization",
		"heart spine refinement selects pollution filter recipe"
	)
	recipe_character.inventory.add_item("item.phase_well_pulse_sheet", 1)
	recipe_character.inventory.add_item("item.phase_well_damper", 1)
	recipe_character.inventory.items["item.basic_parts"] = 1
	recipe_world.quest_state.active_quest_ids = ["quest.assemble_phase_well_shunt"]
	host._expect_equal(
		processing.get_recommended_recipe_id(deep_reactor, recipe_character, recipe_world),
		"recipe.process_crystal_ore",
		"phase well shunt assembly falls back to basic parts recipe when only parts are missing"
	)
	recipe_character.inventory.items["item.basic_parts"] = 2
	host._expect_equal(
		processing.get_recommended_recipe_id(deep_reactor, recipe_character, recipe_world),
		"recipe.phase_well_shunt",
		"phase well shunt assembly returns to reactor recipe after basic parts are restored"
	)
	recipe_character.inventory.add_item("item.phase_well_spindle", 1)
	recipe_character.inventory.items["item.basic_parts"] = 1
	recipe_world.quest_state.active_quest_ids = ["quest.analyze_phase_well_spindle"]
	host._expect_equal(
		processing.get_recommended_recipe_id(deep_reactor, recipe_character, recipe_world),
		"recipe.phase_well_spindle_analysis",
		"phase well spindle analysis no longer falls back when basic parts are low"
	)
	recipe_character.inventory.items["item.basic_parts"] = 2
	host._expect_equal(
		processing.get_recommended_recipe_id(deep_reactor, recipe_character, recipe_world),
		"recipe.phase_well_spindle_analysis",
		"phase well spindle analysis returns to reactor recipe after basic parts are restored"
	)
	recipe_world.quest_state.active_quest_ids = ["quest.refine_weft_bundle"]
	host._expect_equal(
		processing.get_recommended_recipe_id(filter, recipe_character, recipe_world),
		"recipe.weft_bundle_stabilization",
		"weft bundle refinement selects pollution filter recipe"
	)
	recipe_character.inventory.add_item("item.phase_well_warp_sheet", 1)
	recipe_character.inventory.add_item("item.phase_well_tension_rib", 1)
	recipe_character.inventory.items["item.basic_parts"] = 1
	recipe_world.quest_state.active_quest_ids = ["quest.assemble_phase_well_shuttle"]
	host._expect_equal(
		processing.get_recommended_recipe_id(deep_reactor, recipe_character, recipe_world),
		"recipe.process_crystal_ore",
		"phase well shuttle assembly falls back to basic parts recipe when only parts are missing"
	)
	recipe_character.inventory.items["item.basic_parts"] = 2
	host._expect_equal(
		processing.get_recommended_recipe_id(deep_reactor, recipe_character, recipe_world),
		"recipe.phase_well_shuttle",
		"phase well shuttle assembly returns to reactor recipe after basic parts are restored"
	)
	recipe_character.inventory.add_item("item.phase_well_weave_core", 1)
	recipe_character.inventory.items["item.basic_parts"] = 1
	recipe_world.quest_state.active_quest_ids = ["quest.analyze_phase_well_weave_core"]
	host._expect_equal(
		processing.get_recommended_recipe_id(deep_reactor, recipe_character, recipe_world),
		"recipe.phase_well_weave_core_analysis",
		"phase well weave core analysis no longer falls back when basic parts are low"
	)
	recipe_character.inventory.items["item.basic_parts"] = 2
	host._expect_equal(
		processing.get_recommended_recipe_id(deep_reactor, recipe_character, recipe_world),
		"recipe.phase_well_weave_core_analysis",
		"phase well weave core analysis returns to reactor recipe after basic parts are restored"
	)
	recipe_world.quest_state.active_quest_ids = ["quest.refine_selvedge_strip"]
	host._expect_equal(
		processing.get_recommended_recipe_id(filter, recipe_character, recipe_world),
		"recipe.selvedge_strip_stabilization",
		"selvedge strip refinement selects pollution filter recipe"
	)
	recipe_character.inventory.add_item("item.phase_well_pattern_sheet", 1)
	recipe_character.inventory.add_item("item.phase_well_frame_rib", 1)
	recipe_character.inventory.items["item.basic_parts"] = 1
	recipe_world.quest_state.active_quest_ids = ["quest.assemble_phase_well_frame_key"]
	host._expect_equal(
		processing.get_recommended_recipe_id(deep_reactor, recipe_character, recipe_world),
		"recipe.process_crystal_ore",
		"phase well frame key assembly falls back to basic parts recipe when only parts are missing"
	)
	recipe_character.inventory.items["item.basic_parts"] = 2
	host._expect_equal(
		processing.get_recommended_recipe_id(deep_reactor, recipe_character, recipe_world),
		"recipe.phase_well_frame_key",
		"phase well frame key assembly returns to reactor recipe after basic parts are restored"
	)
	recipe_character.inventory.add_item("item.phase_well_knot_core", 1)
	recipe_character.inventory.items["item.basic_parts"] = 1
	recipe_world.quest_state.active_quest_ids = ["quest.analyze_phase_well_knot_core"]
	host._expect_equal(
		processing.get_recommended_recipe_id(deep_reactor, recipe_character, recipe_world),
		"recipe.phase_well_knot_core_analysis",
		"phase well knot core analysis no longer falls back when basic parts are low"
	)
	recipe_character.inventory.items["item.basic_parts"] = 2
	host._expect_equal(
		processing.get_recommended_recipe_id(deep_reactor, recipe_character, recipe_world),
		"recipe.phase_well_knot_core_analysis",
		"phase well knot core analysis returns to reactor recipe after basic parts are restored"
	)
	recipe_world.quest_state.active_quest_ids = ["quest.refine_tether_fiber"]
	host._expect_equal(
		processing.get_recommended_recipe_id(filter, recipe_character, recipe_world),
		"recipe.tether_fiber_stabilization",
		"tether fiber refinement selects pollution filter recipe"
	)
	recipe_character.inventory.add_item("item.phase_well_tether_sheet", 1)
	recipe_character.inventory.add_item("item.phase_well_tether_rib", 1)
	recipe_character.inventory.items["item.basic_parts"] = 1
	recipe_world.quest_state.active_quest_ids = ["quest.assemble_phase_well_tether_spike"]
	host._expect_equal(
		processing.get_recommended_recipe_id(deep_reactor, recipe_character, recipe_world),
		"recipe.process_crystal_ore",
		"phase well tether spike assembly falls back to basic parts recipe when only parts are missing"
	)
	recipe_character.inventory.items["item.basic_parts"] = 2
	host._expect_equal(
		processing.get_recommended_recipe_id(deep_reactor, recipe_character, recipe_world),
		"recipe.phase_well_tether_spike",
		"phase well tether spike assembly returns to reactor recipe after basic parts are restored"
	)
	recipe_character.inventory.add_item("item.phase_well_anchor_core", 1)
	recipe_character.inventory.items["item.basic_parts"] = 1
	recipe_world.quest_state.active_quest_ids = ["quest.analyze_phase_well_anchor_core"]
	host._expect_equal(
		processing.get_recommended_recipe_id(deep_reactor, recipe_character, recipe_world),
		"recipe.phase_well_anchor_core_analysis",
		"phase well anchor core analysis no longer falls back when basic parts are low"
	)
	recipe_character.inventory.items["item.basic_parts"] = 2
	host._expect_equal(
		processing.get_recommended_recipe_id(deep_reactor, recipe_character, recipe_world),
		"recipe.phase_well_anchor_core_analysis",
		"phase well anchor core analysis returns to reactor recipe after basic parts are restored"
	)
	recipe_world.quest_state.active_quest_ids = ["quest.refine_anchor_core_dust"]
	host._expect_equal(
		processing.get_recommended_recipe_id(filter, recipe_character, recipe_world),
		"recipe.anchor_core_dust_stabilization",
		"anchor core dust refinement selects pollution filter recipe"
	)
	recipe_character.inventory.add_item("item.phase_well_return_sheet", 1)
	recipe_character.inventory.add_item("item.anchor_field_filter", 1)
	recipe_character.inventory.items["item.basic_parts"] = 1
	recipe_world.quest_state.active_quest_ids = ["quest.assemble_phase_well_anchor_stake"]
	host._expect_equal(
		processing.get_recommended_recipe_id(deep_reactor, recipe_character, recipe_world),
		"recipe.process_crystal_ore",
		"phase well anchor stake assembly falls back to basic parts recipe when only parts are missing"
	)
	recipe_character.inventory.items["item.basic_parts"] = 2
	host._expect_equal(
		processing.get_recommended_recipe_id(deep_reactor, recipe_character, recipe_world),
		"recipe.phase_well_anchor_stake",
		"phase well anchor stake assembly returns to reactor recipe after basic parts are restored"
	)
	recipe_character.inventory.add_item("item.phase_well_echo_shard", 1)
	recipe_character.inventory.items["item.basic_parts"] = 1
	recipe_world.quest_state.active_quest_ids = ["quest.analyze_phase_well_echo_shard"]
	host._expect_equal(
		processing.get_recommended_recipe_id(deep_reactor, recipe_character, recipe_world),
		"recipe.phase_well_echo_shard_analysis",
		"phase well echo shard analysis no longer falls back when basic parts are low"
	)
	recipe_character.inventory.items["item.basic_parts"] = 2
	host._expect_equal(
		processing.get_recommended_recipe_id(deep_reactor, recipe_character, recipe_world),
		"recipe.phase_well_echo_shard_analysis",
		"phase well echo shard analysis returns to reactor recipe after basic parts are restored"
	)
	recipe_character.inventory.add_item("item.stability_echo_sample", 1)
	recipe_world.quest_state.active_quest_ids = ["quest.analyze_stability_echo_sample"]
	host._expect_equal(
		processing.get_recommended_recipe_id(deep_reactor, recipe_character, recipe_world),
		"recipe.stability_echo_report",
		"stability echo report analysis selects reactor recipe"
	)
	recipe_character.inventory.add_item("item.supply_return_trace", 1)
	recipe_world.quest_state.active_quest_ids = ["quest.analyze_supply_return_trace"]
	host._expect_equal(
		processing.get_recommended_recipe_id(deep_reactor, recipe_character, recipe_world),
		"recipe.short_action_feedback",
		"short action feedback analysis selects reactor recipe"
	)
	recipe_character.inventory.add_item("item.route_signal_trace", 1)
	recipe_world.quest_state.active_quest_ids = ["quest.analyze_route_signal_trace"]
	host._expect_equal(
		processing.get_recommended_recipe_id(deep_reactor, recipe_character, recipe_world),
		"recipe.route_action_feedback",
		"route action feedback analysis selects reactor recipe"
	)
	recipe_character.inventory.add_item("item.steady_supply_trace", 1)
	recipe_world.quest_state.active_quest_ids = ["quest.analyze_steady_supply_trace"]
	host._expect_equal(
		processing.get_recommended_recipe_id(deep_reactor, recipe_character, recipe_world),
		"recipe.steady_supply_feedback",
		"steady supply feedback analysis selects reactor recipe"
	)
	recipe_character.inventory.add_item("item.phase_survey_trace", 1)
	recipe_world.quest_state.active_quest_ids = ["quest.analyze_phase_survey_trace"]
	host._expect_equal(
		processing.get_recommended_recipe_id(deep_reactor, recipe_character, recipe_world),
		"recipe.phase_survey_feedback",
		"phase survey feedback analysis selects reactor recipe"
	)
	recipe_character.inventory.add_item("item.pressure_clearance_trace", 1)
	recipe_world.quest_state.active_quest_ids = ["quest.analyze_pressure_clearance_trace"]
	host._expect_equal(
		processing.get_recommended_recipe_id(deep_reactor, recipe_character, recipe_world),
		"recipe.pressure_clearance_feedback",
		"pressure clearance feedback analysis selects reactor recipe"
	)
	deep_reactor.free()
	filter.free()


func _check_mid_demo_missing_input_hints(processing: ProcessingSystem) -> void:
	var phase_anchor_world := WorldState.create_default()
	phase_anchor_world.quest_state.unlock_effect("recipe.phase_anchor")
	var phase_anchor_character := CharacterState.create_default()
	var phase_anchor_status := processing.get_recipe_status("recipe.phase_anchor", phase_anchor_character, phase_anchor_world)
	host._expect_text_contains(
		String(phase_anchor_status.get("supply_hint", "")),
		"回收两处继电残片",
		"phase anchor missing relay shard points to outer ring"
	)
	phase_anchor_character.inventory.add_item("item.relay_shard", 2)
	phase_anchor_status = processing.get_recipe_status("recipe.phase_anchor", phase_anchor_character, phase_anchor_world)
	host._expect_text_contains(
		String(phase_anchor_status.get("supply_hint", "")),
		"污染浆液来自污染过滤器处理沉积物",
		"phase anchor missing slurry points to pollution filter"
	)

	var deep_signal_world := WorldState.create_default()
	deep_signal_world.quest_state.unlock_effect("recipe.deep_signal_analysis")
	var deep_signal_status := processing.get_recipe_status("recipe.deep_signal_analysis", CharacterState.create_default(), deep_signal_world)
	host._expect_text_contains(
		String(deep_signal_status.get("supply_hint", "")),
		"回收外圈回波匣",
		"deep signal analysis missing echo points to outer ring cache"
	)

	var filter_world := WorldState.create_default()
	filter_world.quest_state.unlock_effect("recipe.phase_filament_refining")
	filter_world.add_base_structure(
		"structure.pollution_filter_build_site",
		"building.pollution_filter",
		"region.pollution_edge",
		"map_object_instance.pollution_filter_build_site"
	)
	var filament_status := processing.get_recipe_status("recipe.phase_filament_refining", CharacterState.create_default(), filter_world)
	host._expect_text_contains(
		String(filament_status.get("supply_hint", "")),
		"回收两处相位纤丝",
		"phase filament refining missing input points to fracture ridge"
	)

	var override_world := WorldState.create_default()
	override_world.quest_state.unlock_effect("recipe.deep_override_key")
	var override_character := CharacterState.create_default()
	override_character.inventory.items["item.basic_parts"] = 2
	var override_status := processing.get_recipe_status("recipe.deep_override_key", override_character, override_world)
	host._expect_text_contains(
		String(override_status.get("supply_hint", "")),
		"精炼相位纤丝",
		"deep override missing resonance filter points to filter"
	)
	override_character.inventory.add_item("item.resonance_filter", 1)
	override_status = processing.get_recipe_status("recipe.deep_override_key", override_character, override_world)
	host._expect_text_contains(
		String(override_status.get("supply_hint", "")),
		"相位纤丝精炼副产",
		"deep override missing slurry points to filter byproduct"
	)
	var deep_core_world := WorldState.create_default()
	deep_core_world.quest_state.unlock_effect("recipe.deep_core_imprint")
	var deep_core_status := processing.get_recipe_status("recipe.deep_core_imprint", CharacterState.create_default(), deep_core_world)
	host._expect_text_contains(
		String(deep_core_status.get("supply_hint", "")),
		"取出裂相样块",
		"deep core missing sample points back to fracture latch"
	)

	var matrix_world := WorldState.create_default()
	matrix_world.quest_state.unlock_effect("recipe.deep_signal_matrix")
	var matrix_status := processing.get_recipe_status("recipe.deep_signal_matrix", CharacterState.create_default(), matrix_world)
	host._expect_text_contains(
		String(matrix_status.get("supply_hint", "")),
		"回收两束相位导管",
		"deep signal matrix missing conduit points back to array line"
	)
	var matrix_character := CharacterState.create_default()
	matrix_character.inventory.add_item("item.phase_conduit", 2)
	matrix_status = processing.get_recipe_status("recipe.deep_signal_matrix", matrix_character, matrix_world)
	host._expect_text_contains(
		String(matrix_status.get("supply_hint", "")),
		"整理深段读数矩阵",
		"deep signal matrix missing slurry points back to refinery source"
	)
	var splinter_world := WorldState.create_default()
	splinter_world.quest_state.unlock_effect("recipe.phase_splinter_refining")
	splinter_world.add_base_structure("structure.pollution_filter_build_site", "building.pollution_filter", "region.pollution_edge")
	var splinter_status := processing.get_recipe_status("recipe.phase_splinter_refining", CharacterState.create_default(), splinter_world)
	host._expect_text_contains(
		String(splinter_status.get("supply_hint", "")),
		"两处裂相共振读数",
		"phase splinter refining missing input points back to resonance and hunter route"
	)

	var lens_world := WorldState.create_default()
	lens_world.quest_state.unlock_effect("recipe.relay_tuning_lens")
	var lens_status := processing.get_recipe_status("recipe.relay_tuning_lens", CharacterState.create_default(), lens_world)
	host._expect_text_contains(
		String(lens_status.get("supply_hint", "")),
		"筛成透镜胚片",
		"relay lens missing blank points back to filter"
	)
	var lens_character := CharacterState.create_default()
	lens_character.inventory.add_item("item.phase_lens_blank", 1)
	lens_status = processing.get_recipe_status("recipe.relay_tuning_lens", lens_character, lens_world)
	host._expect_text_contains(
		String(lens_status.get("supply_hint", "")),
		"裂相碎屑筛分副产",
		"relay lens missing slurry points back to splinter filtering byproduct"
	)

	var inner_trace_world := WorldState.create_default()
	inner_trace_world.quest_state.unlock_effect("recipe.inner_fault_analysis")
	var inner_trace_status := processing.get_recipe_status("recipe.inner_fault_analysis", CharacterState.create_default(), inner_trace_world)
	host._expect_text_contains(
		String(inner_trace_status.get("supply_hint", "")),
		"带回内层故障轨迹",
		"inner fault analysis missing trace points back to spire calibration"
	)


func check_equipment_processing_runtime() -> void:
	var processing := ProcessingSystem.new(host.data_registry)
	var module_world := WorldState.create_default()
	module_world.quest_state.unlock_effect("recipe.basic_filter_module")
	var module_character := CharacterState.create_default()
	module_character.inventory.items["item.basic_parts"] = 2
	module_character.inventory.items["item.filter_media"] = 1
	var start_result := processing.process_recipe("recipe.basic_filter_module", module_character, module_world)
	host._expect_equal(bool(start_result.get("success", false)), true, "filter module processing should start")
	var completed_results := processing.advance_processing(20.0, module_character, module_world)
	host._expect_equal(completed_results.size(), 1, "filter module processing should complete")
	host._expect_equal(
		int(module_character.inventory.equipment.get("equipment.filter_module_t1", 0)),
		1,
		"filter module should be stored in equipment inventory"
	)
	host._expect_equal(
		module_character.inventory.items.has("equipment.filter_module_t1"),
		false,
		"filter module should not leak into item inventory"
	)
	host._expect_equal(
		module_character.equip_suit_module("equipment.filter_module_t1"),
		true,
		"crafted filter module can be equipped"
	)
	host._expect_equal(
		String(module_character.equipment.get("suit_module", "")),
		"equipment.filter_module_t1",
		"equipped filter module persists on character slot"
	)
	host._expect_equal(
		int(module_character.inventory.equipment.get("equipment.filter_module_t1", 0)),
		0,
		"equipped filter module should leave equipment inventory"
	)


func _check_hud_log_presenter() -> void:
	var presenter := HudLogPresenter.new(host.data_registry)
	var startup_log := presenter.format_startup_log()
	host._expect_text_contains(
		startup_log,
		"Tab 切换调试面板",
		"startup log keeps debug boundary hint"
	)
	if startup_log.length() > 80:
		host.failures.append("startup log should stay compact, got %d chars: %s" % [startup_log.length(), startup_log])
	host._expect_equal(
		presenter.format_slot_result_log("slot_02", {"message": "保存完成。"}),
		"槽位 02：保存完成。",
		"log presenter formats save slot names"
	)
	host._expect_equal(
		presenter.join_messages(["", "已进入：晶体矿脉区。", "  ", "任务完成：恢复前哨。"]),
		"已进入：晶体矿脉区。 任务完成：恢复前哨。",
		"log presenter joins non-empty messages"
	)
	host._expect_text_contains(
		presenter.format_device_panel_opened_log("building.basic_reactor"),
		"基础反应器",
		"log presenter resolves device display names"
	)
	host._expect_text_contains(
		presenter.format_recommended_recipe_selected_log("recipe.analyze_anomaly_sample"),
		"分析异常样本",
		"log presenter resolves recipe display names"
	)


func _check_development_baseline_presenter() -> void:
	var definitions := DevelopmentBaselineCatalog.get_baseline_definitions()
	host._expect_equal(definitions.size(), 22, "development baseline catalog count")
	host._expect_equal(
		String(definitions[0].get("id", "")),
		"baseline.s0_new_game",
		"development baseline catalog starts from S0"
	)
	var presenter := HudDevelopmentBaselinePresenter.new()
	var selected_text := presenter.format_selected_baseline(definitions[3], 3, definitions.size())
	host._expect_text_contains(selected_text, "S3 裂相脊入口已开", "development baseline presenter shows selected baseline name")
	host._expect_text_contains(selected_text, "相位纤丝", "development baseline presenter shows baseline summary")
	host._expect_text_contains(selected_text, "过滤器精炼", "development baseline presenter shows recommended use")
	host._expect_equal(
		String(definitions[21].get("id", "")),
		"baseline.s21_demo_stabilization_core_ready",
		"development baseline catalog ends at S21"
	)


func _check_demo_stabilization_baseline_status_panel() -> void:
	var builder := DevelopmentBaselineBuilder.new(host.data_registry)
	var result := builder.create_baseline_state("baseline.s21_demo_stabilization_core_ready")
	host._expect_equal(bool(result.get("success", false)), true, "S21 baseline status panel generation")
	if not bool(result.get("success", false)):
		return

	var world_state: WorldState = result.get("world_state", null)
	var character_state: CharacterState = result.get("character_state", null)
	if world_state == null or character_state == null:
		host.failures.append("S21 baseline status panel should receive world and character states")
		return

	var presenter := HudStatusPresenter.new()
	var status_text := presenter.format_status_text(host.data_registry, world_state, character_state)
	host._expect_text_contains(status_text, "目标：进入核心稳定站", "S21 status shows demo core entry target")
	host._expect_text_contains(status_text, "进度：进入 核心稳定站 0/1", "S21 status shows demo core region progress")
	host._expect_text_contains(status_text, "关键资源：基础零件x16", "S21 status keeps compact key resources")
	host._expect_text_contains(status_text, "设备：待命；当前目标先外出推进", "S21 status keeps base summary from pulling player back")
	host._expect_text_contains(status_text, "模块：基础多用工具；基础防护服；基础过滤模块", "S21 status keeps combat module visible")
	host._expect_text_missing(status_text, "前线行动台", "S21 status should not point back to action console")
	host._expect_text_missing(status_text, "高压窗口", "S21 status should not reopen overpressure window")


func _check_game_root_development_baseline_factory() -> void:
	var game_root := GameRootScript.new()
	game_root.development_baseline_builder = DevelopmentBaselineBuilder.new(host.data_registry)
	var result := game_root.create_development_baseline_state("baseline.s4_deep_cache_open")
	host._expect_equal(bool(result.get("success", false)), true, "game root development baseline generation")
	if not bool(result.get("success", false)):
		game_root.free()
		return

	var world_state: WorldState = result.get("world_state", null)
	var character_state: CharacterState = result.get("character_state", null)
	if world_state == null or character_state == null:
		host.failures.append("development baseline generation should return world and character states")
		game_root.free()
		return

	host._expect_equal(world_state.current_region_id, "region.outpost_platform", "S4 baseline world region")
	host._expect_equal(character_state.current_region_id, "region.outpost_platform", "S4 baseline character region")
	host._expect_array_has(world_state.quest_state.active_quest_ids, "quest.analyze_deep_core", "S4 baseline active quest")
	host._expect_equal(int(character_state.inventory.items.get("item.basic_parts", 0)), 4, "S4 baseline keeps enough basic parts for the second deep pass")
	host._expect_equal(int(character_state.inventory.items.get("item.deep_ruin_core", 0)), 1, "S4 baseline keeps fracture sample reward")
	host._expect_equal(float(character_state.inventory.fluids.get("fluid.polluted_slurry", 0.0)), 1.0, "S4 baseline keeps polluted slurry for deep signal matrix")
	host._expect_equal(String(character_state.equipment.get("suit_module", "")), "equipment.filter_module_t1", "S4 baseline equips filter module")

	var s5_result := game_root.create_development_baseline_state("baseline.s5_phase_relay_online")
	host._expect_equal(bool(s5_result.get("success", false)), true, "S5 development baseline generation")
	if not bool(s5_result.get("success", false)):
		game_root.free()
		return
	var s5_world: WorldState = s5_result.get("world_state", null)
	var s5_character: CharacterState = s5_result.get("character_state", null)
	host._expect_equal(s5_world.current_region_id, "region.outpost_platform", "S5 baseline world region")
	host._expect_equal(s5_character.current_region_id, "region.outpost_platform", "S5 baseline character region")
	host._expect_array_has(s5_world.quest_state.active_quest_ids, "quest.reenter_phase_frontline", "S5 baseline active quest")
	host._expect_equal(s5_world.active_phase_relay_anchor_id, "map_object_instance.phase_return_anchor", "S5 baseline active relay anchor")
	host._expect_equal(
		s5_world.get_deployed_phase_relay_anchor_ids(),
		["map_object_instance.phase_return_anchor"],
		"S5 baseline deployed relay anchors"
	)
	host._expect_equal(int(s5_character.inventory.items.get("item.repair_gel", 0)), 1, "S5 baseline keeps field repair gel")
	host._expect_equal(int(s5_character.inventory.items.get("item.resistance_vial_t1", 0)), 1, "S5 baseline keeps anti-pollution vial")

	var s6_result := game_root.create_development_baseline_state("baseline.s6_inner_fault_trace_ready")
	host._expect_equal(bool(s6_result.get("success", false)), true, "S6 development baseline generation")
	if not bool(s6_result.get("success", false)):
		game_root.free()
		return
	var s6_world: WorldState = s6_result.get("world_state", null)
	var s6_character: CharacterState = s6_result.get("character_state", null)
	host._expect_array_has(s6_world.quest_state.active_quest_ids, "quest.analyze_inner_fault_trace", "S6 baseline active quest")
	host._expect_equal(int(s6_character.inventory.items.get("item.inner_fault_trace", 0)), 1, "S6 baseline keeps inner fault trace reward")
	host._expect_equal(s6_world.active_phase_relay_anchor_id, "map_object_instance.phase_return_anchor", "S6 baseline active relay anchor")
	host._expect_equal(
		s6_world.get_deployed_phase_relay_anchor_ids(),
		["map_object_instance.phase_return_anchor"],
		"S6 baseline deployed relay anchors"
	)
	game_root.free()


func _check_game_root_gm_tools() -> void:
	var game_root := GameRootScript.new()
	game_root.data_registry = host.data_registry
	game_root.character_state = CharacterState.create_default()
	var add_result := game_root._apply_gm_resource_delta("item.repair_gel", 1.0)
	host._expect_equal(bool(add_result.get("success", false)), true, "GM resource add succeeds")
	host._expect_equal(int(game_root.character_state.inventory.items.get("item.repair_gel", 0)), 2, "GM resource add updates inventory")
	var fluid_result := game_root._apply_gm_resource_delta("fluid.polluted_slurry", 1.0)
	host._expect_equal(bool(fluid_result.get("success", false)), true, "GM fluid add succeeds")
	host._expect_equal(float(game_root.character_state.inventory.fluids.get("fluid.polluted_slurry", 0.0)), 1.0, "GM fluid add updates inventory")
	game_root.character_state.health = 54.0
	game_root.character_state.protection = 16.0
	var refill_result := game_root._apply_gm_vitals_refill()
	host._expect_equal(bool(refill_result.get("success", false)), true, "GM vitals refill succeeds")
	host._expect_equal(game_root.character_state.health, 100.0, "GM vitals refill restores health")
	host._expect_equal(game_root.character_state.protection, 100.0, "GM vitals refill restores protection")
	game_root.free()


func _check_game_root_recipe_cycle_input_events() -> void:
	var game_root := GameRootScript.new()
	var key_event := InputEventKey.new()
	key_event.pressed = true
	key_event.keycode = KEY_R
	host._expect_equal(
		game_root._is_recipe_cycle_key_event(key_event),
		true,
		"game root accepts R keycode for recipe and relay cycling"
	)

	var unicode_event := InputEventKey.new()
	unicode_event.pressed = true
	unicode_event.unicode = 114
	host._expect_equal(
		game_root._is_recipe_cycle_key_event(unicode_event),
		true,
		"game root accepts lowercase R unicode for recipe and relay cycling"
	)

	var echo_event := InputEventKey.new()
	echo_event.pressed = true
	echo_event.echo = true
	echo_event.keycode = KEY_R
	host._expect_equal(
		game_root._is_recipe_cycle_key_event(echo_event),
		false,
		"game root ignores repeated R key echo events"
	)
	game_root.free()


func _check_resource_interaction_logs() -> void:
	var gather_system := GatherSystem.new(host.data_registry)
	var gather_world := WorldState.create_default()
	var gather_character := CharacterState.create_default()
	var salvage_result := gather_system.interact_with_object(
		"map_object_instance.field_wreckage_north",
		"map_object.field_wreckage",
		"gather",
		gather_character,
		gather_world
	)
	host._expect_text_contains(
		String(salvage_result.get("message", "")),
		"导电废件 x2",
		"gather result should use display names"
	)
	host._expect_text_missing(
		String(salvage_result.get("message", "")),
		"item.salvage_scrap",
		"gather result should not leak item ids"
	)

	var sample_world := WorldState.create_default()
	sample_world.quest_state.active_quest_ids = ["quest.bring_back_sample"]
	var sample_character := CharacterState.create_default()
	var sample_result := gather_system.interact_with_object(
		"map_object_instance.anomaly_crystal",
		"map_object.anomaly_crystal",
		"sample",
		sample_character,
		sample_world
	)
	host._expect_text_contains(
		String(sample_result.get("message", "")),
		"异常样本 x1",
		"sample result should use display names"
	)
	host._expect_text_missing(
		String(sample_result.get("message", "")),
		"item.anomaly_sample",
		"sample result should not leak item ids"
	)


func _check_completed_recipe_followup_auto_selection() -> void:
	var game_root = GameRootScript.new()
	var reactor := PrototypeInteractable.new()
	reactor.definition_id = "building.basic_reactor"
	reactor.interaction_type = "process_recipe"
	reactor.recipe_id = "recipe.foundation_t1"
	reactor.set_recipe_cycle([
		"recipe.foundation_t1",
		"recipe.make_filter_media",
		"recipe.process_crystal_ore"
	])
	var recipe_world := WorldState.create_default()
	recipe_world.quest_state.active_quest_ids = ["quest.expand_treatment_point"]
	recipe_world.add_base_structure(
		"structure.foundation_site_north",
		"building.foundation_t1",
		"region.pollution_edge",
		"map_object_instance.foundation_site_north"
	)
	recipe_world.add_base_structure(
		"structure.foundation_site_south",
		"building.foundation_t1",
		"region.pollution_edge",
		"map_object_instance.foundation_site_south"
	)
	recipe_world.base_structures["structure.basic_reactor"]["status"] = "completed"
	recipe_world.base_structures["structure.basic_reactor"]["last_recipe_id"] = "recipe.foundation_t1"
	var recipe_character := CharacterState.create_default()
	recipe_character.inventory.items["item.basic_parts"] = 4
	game_root.processing_system = ProcessingSystem.new(host.data_registry)
	game_root.world_state = recipe_world
	game_root.character_state = recipe_character
	host._expect_equal(
		game_root._maybe_select_followup_recipe(reactor),
		"recipe.make_filter_media",
		"completed recipe follow-up should auto select next recommendation"
	)
	host._expect_equal(
		reactor.get_current_recipe_id(),
		"recipe.make_filter_media",
		"completed recipe follow-up updates current recipe"
	)
	reactor.select_recipe("recipe.process_crystal_ore")
	host._expect_equal(
		game_root._maybe_select_followup_recipe(reactor),
		"",
		"completed recipe follow-up should not override later manual choice"
	)
	reactor.free()
	game_root.free()
