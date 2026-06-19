extends RefCounted


var host


func _init(check_host) -> void:
	host = check_host


func run() -> void:
	_check_ready_prompt_reads_gate_preparation()
	_check_ruin_gate_confirmation_reads_preparation()
	_check_reactor_reclaim_guidance_before_gate_confirmation()
	_check_ruin_gate_save_source_reused()


func _check_ready_prompt_reads_gate_preparation() -> void:
	var formatter := InteractionPromptFormatter.new(
		host.data_registry,
		ProcessingSystem.new(host.data_registry),
		BuildSystem.new(host.data_registry)
	)
	var world := _make_gate_ready_world()
	var prepared_character := _make_gate_prepared_character()
	host._expect_text_contains(
		formatter.format_ruin_gate_prompt(world, prepared_character),
		"污染浆液可先回基础反应器回收基础零件",
		"ruin gate prompt points slurry back to reactor before entry"
	)
	var no_vial_character := CharacterState.create_default()
	host._expect_text_contains(
		formatter.format_ruin_gate_prompt(world, no_vial_character),
		"回过滤器补药剂",
		"ruin gate prompt keeps vial preparation visible"
	)
	no_vial_character.inventory.add_item("item.resistance_vial_t1", 1)
	host._expect_text_contains(
		formatter.format_ruin_gate_prompt(world, no_vial_character),
		"基础过滤模块未装入",
		"ruin gate prompt reads missing filter module"
	)


func _check_ruin_gate_confirmation_reads_preparation() -> void:
	var map := VerticalSliceMap.new()
	map.data_registry = host.data_registry
	var result := map._inspect_ruin_gate(_make_gate_ready_world(), _make_gate_prepared_character())
	host._expect_equal(bool(result.get("success", false)), true, "ruin gate confirmation succeeds after pressure is clear")
	host._expect_text_contains(
		String(result.get("message", "")),
		"门前准备记录：基础过滤模块已装配",
		"ruin gate confirmation records equipped filter module"
	)
	host._expect_text_contains(
		String(result.get("message", "")),
		"污染浆液 x1 可回基础反应器回收基础零件",
		"ruin gate confirmation records slurry reclaim reason"
	)
	map.free()


func _check_reactor_reclaim_guidance_before_gate_confirmation() -> void:
	var world := _make_gate_ready_world()
	world.quest_state.unlock_effect("recipe.reclaim_basic_parts")
	var character := _make_gate_prepared_character()
	var status_text := HudStatusPresenter.new().format_vitals_text(host.data_registry, world, character)
	host._expect_text_contains(status_text, "门前整备：基础反应器可回收污染浆液", "HUD base summary keeps gatefront reclaim visible")
	var direction_hint := HudHintPresenter.new().format_direction_hint(world, character, "quest.unlock_ruin_signal")
	host._expect_text_contains(direction_hint, "回基础反应器回收污染浆液", "direction hint points slurry back to reactor")
	var reactor := PrototypeInteractable.new()
	reactor.definition_id = "building.basic_reactor"
	reactor.interaction_type = "process_recipe"
	reactor.recipe_id = "recipe.process_crystal_ore"
	reactor.set_recipe_cycle(["recipe.process_crystal_ore", "recipe.reclaim_basic_parts"])
	var panel := HudDevicePanelPresenter.new().format_device_panel_texts(
		host.data_registry,
		ProcessingSystem.new(host.data_registry),
		reactor,
		character,
		world
	)
	host._expect_text_contains(
		String(panel.get("recipes", "")),
		"回收基础零件（当前目标）：可加工",
		"reactor panel recommends slurry reclaim before gate confirmation"
	)
	reactor.free()


func _check_ruin_gate_save_source_reused() -> void:
	host._expect_equal(
		String(SaveContentValidator.PROTOTYPE_MAP_OBJECT_SOURCES.get("map_object_instance.ruin_gate", "")),
		"map_object.ruin_gate",
		"gate preparation reuses the existing ruin gate save source"
	)


func _make_gate_ready_world() -> WorldState:
	var world := WorldState.create_default()
	world.quest_state.completed_quest_ids.append("quest.enter_pollution_edge")
	world.quest_state.completed_quest_ids.append("quest.defeat_elite_node")
	world.quest_state.active_quest_ids = ["quest.unlock_ruin_signal"]
	world.ensure_enemy("enemy_instance.polluted_skitter_gate_pressure", "enemy.polluted_skitter", "region.pollution_edge", 30.0)
	world.update_enemy_health("enemy_instance.polluted_skitter_gate_pressure", 0.0, true)
	return world


func _make_gate_prepared_character() -> CharacterState:
	var character := CharacterState.create_default()
	character.equipment["suit_module"] = "equipment.filter_module_t1"
	character.inventory.add_item("item.resistance_vial_t1", 1)
	character.inventory.add_fluid("fluid.polluted_slurry", 1.0)
	return character
