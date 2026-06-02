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
	_check_stability_readout_guidance(processing)
	_check_s14_s15_baseline_status()


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


func _check_stability_readout_guidance(processing: ProcessingSystem) -> void:
	host._expect_text_contains(
		RecipePurposeHints.format_recipe_goal_hint("recipe.phase_well_echo_shard_analysis"),
		"前线回充",
		"echo shard analysis purpose explains anchor field recovery payoff"
	)
	host._expect_text_contains(
		RecipePurposeHints.format_recipe_goal_hint("recipe.phase_well_echo_shard_analysis"),
		"按序校准稳窗节点",
		"echo shard analysis purpose points to stability node calibration"
	)
	host._expect_text_contains(
		processing._get_completion_next_step("recipe.phase_well_echo_shard_analysis"),
		"先回锚场回稳窗确认前线回充",
		"echo shard analysis completion points to anchor field recovery"
	)
	host._expect_text_contains(
		processing._get_completion_next_step("recipe.phase_well_echo_shard_analysis"),
		"西侧、中央、东侧",
		"echo shard analysis completion preserves stability node order"
	)

	var missing_readout_hint := processing._format_mid_demo_missing_input_supply_hint(
		host.data_registry.get_definition("recipe.phase_well_echo_shard_analysis"),
		CharacterState.create_default().inventory
	)
	host._expect_text_contains(
		missing_readout_hint,
		"锚场回稳窗部署",
		"echo shard analysis missing input points back to anchor field stabilization"
	)

	_check_stability_readout_device_recommendation(processing)
	_check_stability_readout_anchor_field_prompt()


func _check_stability_readout_device_recommendation(processing: ProcessingSystem) -> void:
	var reactor := PrototypeInteractable.new()
	reactor.definition_id = "building.basic_reactor"
	reactor.interaction_type = "process_recipe"
	reactor.recipe_id = "recipe.process_crystal_ore"
	reactor.set_recipe_cycle([
		"recipe.process_crystal_ore",
		"recipe.phase_well_echo_shard_analysis"
	])

	var reactor_world := WorldState.create_default()
	reactor_world.quest_state.active_quest_ids = ["quest.analyze_phase_well_echo_shard"]
	reactor_world.quest_state.unlock_effect("recipe.phase_well_echo_shard_analysis")
	var reactor_character := CharacterState.create_default()
	reactor_character.inventory.add_item("item.phase_well_echo_shard", 1)
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
		"确认前线回充",
		"reactor device panel explains echo shard readout recovery payoff"
	)
	host._expect_text_contains(
		String(reactor_texts.get("recipes", "")),
		"当前目标",
		"reactor device panel marks echo shard analysis as current target"
	)
	reactor.free()


func _check_stability_readout_anchor_field_prompt() -> void:
	var prompt_world := WorldState.create_default()
	prompt_world.quest_state.completed_quest_ids.append("quest.stabilize_phase_well_anchor_field")
	prompt_world.quest_state.completed_quest_ids.append("quest.analyze_phase_well_echo_shard")
	var prompt_character := CharacterState.create_default()
	prompt_character.inventory.add_item("item.phase_well_stability_readout", 1)
	var prompt_formatter := InteractionPromptFormatter.new(
		host.data_registry,
		ProcessingSystem.new(host.data_registry),
		BuildSystem.new(host.data_registry)
	)
	var prompt_text := prompt_formatter.format_phase_well_anchor_field_prompt(prompt_world, prompt_character)
	host._expect_text_contains(prompt_text, "按 E 回充", "anchor field prompt exposes readout recovery interaction")
	host._expect_text_contains(prompt_text, "读数已解析", "anchor field prompt does not imply node calibration is complete")
	host._expect_text_contains(prompt_text, "按序校准三处稳窗节点", "anchor field prompt points from recovery to field calibration")


func _check_s14_s15_baseline_status() -> void:
	var builder := DevelopmentBaselineBuilder.new(host.data_registry)
	var s14_result := builder.create_baseline_state("baseline.s14_phase_well_anchor_field_stabilized")
	host._expect_equal(bool(s14_result.get("success", false)), true, "S14 baseline generation for stability readout guidance")
	if bool(s14_result.get("success", false)):
		var s14_world: WorldState = s14_result.get("world_state", null)
		var s14_character: CharacterState = s14_result.get("character_state", null)
		if s14_world == null or s14_character == null:
			host.failures.append("S14 baseline should return world and character states for stability readout guidance")
		else:
			host._expect_equal(
				s14_world.quest_state.active_quest_ids,
				["quest.analyze_phase_well_echo_shard"],
				"S14 baseline starts at echo shard analysis"
			)
			var s14_status := HudStatusPresenter.new().format_status_text(host.data_registry, s14_world, s14_character)
			host._expect_text_contains(s14_status, "目标：解析稳窗余响片", "S14 status panel points to echo shard analysis")
			host._expect_text_contains(s14_status, "稳窗读数", "S14 status panel shows stability readout craft target")
			host._expect_text_contains(s14_status, "前线回充", "S14 status panel explains readout recovery payoff")

	var s15_result := builder.create_baseline_state("baseline.s15_phase_well_stability_readout_ready")
	host._expect_equal(bool(s15_result.get("success", false)), true, "S15 baseline generation for stability calibration guidance")
	if bool(s15_result.get("success", false)):
		var s15_world: WorldState = s15_result.get("world_state", null)
		var s15_character: CharacterState = s15_result.get("character_state", null)
		if s15_world == null or s15_character == null:
			host.failures.append("S15 baseline should return world and character states for stability calibration guidance")
		else:
			host._expect_equal(
				s15_world.quest_state.active_quest_ids,
				["quest.calibrate_phase_well_stability_window"],
				"S15 baseline starts at stability window calibration"
			)
			var s15_status := HudStatusPresenter.new().format_status_text(host.data_registry, s15_world, s15_character)
			host._expect_text_contains(s15_status, "目标：校准稳窗相位序", "S15 status panel points to field calibration")
			host._expect_text_contains(s15_status, "稳窗读数", "S15 status panel keeps readout visible")
