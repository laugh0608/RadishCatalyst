extends RefCounted

var host


func _init(check_host) -> void:
	host = check_host


func run() -> void:
	var processing := ProcessingSystem.new(host.data_registry)
	host._expect_text_contains(
		RecipePurposeHints.format_recipe_goal_hint("recipe.phase_well_knot_core_analysis"),
		"锚定桥检查两端结点",
		"knot core analysis purpose points to tether node readings"
	)
	host._expect_text_contains(
		RecipePurposeHints.format_recipe_goal_hint("recipe.tether_fiber_stabilization"),
		"组装锚定桩",
		"tether fiber stabilization purpose points to tether spike assembly"
	)
	host._expect_text_contains(
		RecipePurposeHints.format_recipe_goal_hint("recipe.phase_well_tether_spike"),
		"读取稳场锚核",
		"tether spike purpose points to anchor core read"
	)
	host._expect_text_contains(
		processing._get_completion_next_step("recipe.phase_well_knot_core_analysis"),
		"两处锚定桥结点",
		"knot core analysis completion points to tether nodes before fiber recovery"
	)

	_check_missing_input_hints(processing)
	_check_device_recommendation(processing)
	_check_s12_baseline_status()


func _check_missing_input_hints(processing: ProcessingSystem) -> void:
	var empty_inventory := CharacterState.create_default().inventory
	var missing_knot_hint := processing._format_mid_demo_missing_input_supply_hint(
		host.data_registry.get_definition("recipe.phase_well_knot_core_analysis"),
		empty_inventory
	)
	host._expect_text_contains(
		missing_knot_hint,
		"锁相键栓",
		"knot core analysis missing input points back to phase well frame read"
	)

	var missing_tether_hint := processing._format_mid_demo_missing_input_supply_hint(
		host.data_registry.get_definition("recipe.tether_fiber_stabilization"),
		empty_inventory
	)
	host._expect_text_contains(
		missing_tether_hint,
		"锚定桥结点",
		"tether fiber stabilization missing input points to bridge node readings"
	)

	var missing_spike_inventory := CharacterState.create_default().inventory
	missing_spike_inventory.add_item("item.phase_well_tether_sheet", 1)
	var missing_spike_hint := processing._format_mid_demo_missing_input_supply_hint(
		host.data_registry.get_definition("recipe.phase_well_tether_spike"),
		missing_spike_inventory
	)
	host._expect_text_contains(
		missing_spike_hint,
		"稳定锚索残股",
		"tether spike missing rib points back to filter step"
	)


func _check_device_recommendation(processing: ProcessingSystem) -> void:
	var reactor := PrototypeInteractable.new()
	reactor.definition_id = "building.basic_reactor"
	reactor.interaction_type = "process_recipe"
	reactor.recipe_id = "recipe.process_crystal_ore"
	reactor.set_recipe_cycle([
		"recipe.process_crystal_ore",
		"recipe.phase_well_knot_core_analysis"
	])

	var device_world := WorldState.create_default()
	device_world.quest_state.active_quest_ids = ["quest.analyze_phase_well_knot_core"]
	device_world.quest_state.unlock_effect("recipe.phase_well_knot_core_analysis")
	var device_character := CharacterState.create_default()
	device_character.inventory.add_item("item.phase_well_knot_core", 1)
	var device_texts := HudDevicePanelPresenter.new().format_device_panel_texts(
		host.data_registry,
		processing,
		reactor,
		device_character,
		device_world
	)
	host._expect_text_contains(
		String(device_texts.get("status", "")),
		"锚定桥检查两端结点",
		"device panel recommended recipe explains anchor bridge node sequence"
	)
	host._expect_text_contains(
		String(device_texts.get("recipes", "")),
		"当前目标",
		"device panel marks knot core analysis as current target"
	)
	reactor.free()


func _check_s12_baseline_status() -> void:
	var builder := DevelopmentBaselineBuilder.new(host.data_registry)
	var baseline_result := builder.create_baseline_state("baseline.s12_phase_well_knot_core_ready")
	host._expect_equal(bool(baseline_result.get("success", false)), true, "S12 baseline generation for anchor bridge guidance")
	if not bool(baseline_result.get("success", false)):
		return

	var baseline_world: WorldState = baseline_result.get("world_state", null)
	var baseline_character: CharacterState = baseline_result.get("character_state", null)
	if baseline_world == null or baseline_character == null:
		host.failures.append("S12 baseline should return world and character states for anchor bridge guidance")
		return

	host._expect_equal(
		baseline_world.quest_state.active_quest_ids,
		["quest.analyze_phase_well_knot_core"],
		"S12 baseline starts at knot core analysis"
	)
	var status_text := HudStatusPresenter.new().format_status_text(host.data_registry, baseline_world, baseline_character)
	host._expect_text_contains(status_text, "目标：解析锚定结核", "S12 status panel points to knot core analysis")
	host._expect_text_contains(status_text, "锚定系谱片", "S12 status panel shows tether sheet craft target")
	host._expect_text_contains(status_text, "锚定桥检查两端结点", "S12 status panel keeps anchor bridge recipe purpose")
