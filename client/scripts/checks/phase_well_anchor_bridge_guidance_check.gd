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
	_check_anchor_field_recipe_guidance(processing)
	_check_s13_baseline_status()


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


func _check_anchor_field_recipe_guidance(processing: ProcessingSystem) -> void:
	host._expect_text_contains(
		RecipePurposeHints.format_recipe_goal_hint("recipe.anchor_core_dust_stabilization"),
		"组装稳场校锚桩",
		"anchor dust stabilization purpose points to anchor stake assembly"
	)
	host._expect_text_contains(
		RecipePurposeHints.format_recipe_goal_hint("recipe.phase_well_anchor_stake"),
		"锚场回稳窗部署",
		"anchor stake purpose points to field deployment"
	)
	host._expect_text_contains(
		processing._get_completion_next_step("recipe.phase_well_anchor_core_analysis"),
		"稳定锚核落尘",
		"anchor core analysis completion points to dust stabilization"
	)
	host._expect_text_contains(
		processing._get_completion_next_step("recipe.anchor_core_dust_stabilization"),
		"组装稳场校锚桩",
		"anchor dust stabilization completion points to anchor stake assembly"
	)
	host._expect_text_contains(
		processing._get_completion_next_step("recipe.phase_well_anchor_stake"),
		"两处压力钉",
		"anchor stake completion points to pressure pins before warden"
	)

	_check_anchor_field_missing_input_hints(processing)
	_check_anchor_field_device_recommendations(processing)


func _check_anchor_field_missing_input_hints(processing: ProcessingSystem) -> void:
	var empty_inventory := CharacterState.create_default().inventory
	var missing_dust_hint := processing._format_mid_demo_missing_input_supply_hint(
		host.data_registry.get_definition("recipe.anchor_core_dust_stabilization"),
		empty_inventory
	)
	host._expect_text_contains(
		missing_dust_hint,
		"解析稳场锚核",
		"anchor dust stabilization missing input points to anchor core analysis"
	)

	var missing_stake_sheet_hint := processing._format_mid_demo_missing_input_supply_hint(
		host.data_registry.get_definition("recipe.phase_well_anchor_stake"),
		empty_inventory
	)
	host._expect_text_contains(
		missing_stake_sheet_hint,
		"解析稳场锚核",
		"anchor stake missing sheet points to anchor core analysis"
	)

	var missing_stake_filter_inventory := CharacterState.create_default().inventory
	missing_stake_filter_inventory.add_item("item.phase_well_return_sheet", 1)
	var missing_stake_filter_hint := processing._format_mid_demo_missing_input_supply_hint(
		host.data_registry.get_definition("recipe.phase_well_anchor_stake"),
		missing_stake_filter_inventory
	)
	host._expect_text_contains(
		missing_stake_filter_hint,
		"稳定锚核落尘",
		"anchor stake missing filter points to dust stabilization"
	)


func _check_anchor_field_device_recommendations(processing: ProcessingSystem) -> void:
	var filter := PrototypeInteractable.new()
	filter.definition_id = "building.pollution_filter"
	filter.interaction_type = "process_recipe"
	filter.recipe_id = "recipe.cleanse_residue"
	filter.set_recipe_cycle([
		"recipe.cleanse_residue",
		"recipe.anchor_core_dust_stabilization"
	])

	var filter_world := WorldState.create_default()
	filter_world.quest_state.active_quest_ids = ["quest.refine_anchor_core_dust"]
	filter_world.quest_state.unlock_effect("recipe.anchor_core_dust_stabilization")
	var filter_character := CharacterState.create_default()
	filter_character.inventory.add_item("item.anchor_core_dust", 1)
	var filter_texts := HudDevicePanelPresenter.new().format_device_panel_texts(
		host.data_registry,
		processing,
		filter,
		filter_character,
		filter_world
	)
	host._expect_text_contains(
		String(filter_texts.get("status", "")),
		"组装稳场校锚桩",
		"filter device panel explains dust stabilization payoff"
	)
	host._expect_text_contains(
		String(filter_texts.get("recipes", "")),
		"当前目标",
		"filter device panel marks dust stabilization as current target"
	)
	filter.free()

	var reactor := PrototypeInteractable.new()
	reactor.definition_id = "building.basic_reactor"
	reactor.interaction_type = "process_recipe"
	reactor.recipe_id = "recipe.process_crystal_ore"
	reactor.set_recipe_cycle([
		"recipe.process_crystal_ore",
		"recipe.phase_well_anchor_stake"
	])

	var reactor_world := WorldState.create_default()
	reactor_world.quest_state.active_quest_ids = ["quest.refine_anchor_core_dust"]
	reactor_world.quest_state.unlock_effect("recipe.phase_well_anchor_stake")
	var reactor_character := CharacterState.create_default()
	reactor_character.inventory.add_item("item.phase_well_return_sheet", 1)
	reactor_character.inventory.add_item("item.anchor_field_filter", 1)
	reactor_character.inventory.add_item("item.basic_parts", 2)
	var reactor_texts := HudDevicePanelPresenter.new().format_device_panel_texts(
		host.data_registry,
		processing,
		reactor,
		reactor_character,
		reactor_world
	)
	host._expect_text_contains(
		String(reactor_texts.get("status", "")),
		"锚场回稳窗部署",
		"reactor device panel explains anchor stake deployment payoff"
	)
	host._expect_text_contains(
		String(reactor_texts.get("recipes", "")),
		"当前目标",
		"reactor device panel marks anchor stake as current target"
	)
	reactor.free()


func _check_s13_baseline_status() -> void:
	var builder := DevelopmentBaselineBuilder.new(host.data_registry)
	var baseline_result := builder.create_baseline_state("baseline.s13_phase_well_anchor_core_ready")
	host._expect_equal(bool(baseline_result.get("success", false)), true, "S13 baseline generation for anchor field guidance")
	if not bool(baseline_result.get("success", false)):
		return

	var baseline_world: WorldState = baseline_result.get("world_state", null)
	var baseline_character: CharacterState = baseline_result.get("character_state", null)
	if baseline_world == null or baseline_character == null:
		host.failures.append("S13 baseline should return world and character states for anchor field guidance")
		return

	host._expect_equal(
		baseline_world.quest_state.active_quest_ids,
		["quest.analyze_phase_well_anchor_core"],
		"S13 baseline starts at anchor core analysis"
	)
	var status_text := HudStatusPresenter.new().format_status_text(host.data_registry, baseline_world, baseline_character)
	host._expect_text_contains(status_text, "目标：解析稳场锚核", "S13 status panel points to anchor core analysis")
	host._expect_text_contains(status_text, "归谱片", "S13 status panel shows return sheet craft target")
	host._expect_text_contains(status_text, "锚核落尘", "S13 status panel keeps anchor dust purpose")
