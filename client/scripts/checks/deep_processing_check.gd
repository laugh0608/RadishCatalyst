extends RefCounted

var host


func _init(check_host) -> void:
	host = check_host


func run() -> void:
	var processing := ProcessingSystem.new(host.data_registry)
	_check_phase_filament_refining(processing)
	_check_phase_splinter_refining(processing)
	_check_relay_tuning_lens(processing)


func _check_phase_filament_refining(processing: ProcessingSystem) -> void:
	var world := _create_filter_world("recipe.phase_filament_refining")
	var character := CharacterState.create_default()
	character.inventory.add_item("item.phase_filament", 2)
	var start := processing.process_recipe("recipe.phase_filament_refining", character, world)
	host._expect_equal(bool(start.get("success", false)), true, "phase filament refining should start")
	var completed := processing.advance_processing(20.0, character, world)
	host._expect_equal(completed.size(), 1, "phase filament refining should complete")
	if not completed.is_empty():
		host._expect_text_contains(String(completed[0].get("message", "")), "谐振滤芯 x1", "phase filament refining completion log output destination")
		host._expect_text_contains(String(completed[0].get("message", "")), "污染浆液 x2", "phase filament refining completion log byproduct destination")
	host._expect_equal(int(character.inventory.items.get("item.resonance_filter", 0)), 1, "phase filament refining grants resonance filter")
	host._expect_equal(float(character.inventory.fluids.get("fluid.polluted_slurry", 0.0)), 2.0, "phase filament refining grants enough polluted slurry for deep chain")


func _check_phase_splinter_refining(processing: ProcessingSystem) -> void:
	var world := _create_filter_world("recipe.phase_splinter_refining")
	var character := CharacterState.create_default()
	character.inventory.add_item("item.phase_splinter", 2)
	var start := processing.process_recipe("recipe.phase_splinter_refining", character, world)
	host._expect_equal(bool(start.get("success", false)), true, "phase splinter refining should start")
	var completed := processing.advance_processing(20.0, character, world)
	host._expect_equal(completed.size(), 1, "phase splinter refining should complete")
	if not completed.is_empty():
		host._expect_text_contains(String(completed[0].get("message", "")), "透镜胚片 x1", "phase splinter refining completion log output destination")
		host._expect_text_contains(String(completed[0].get("message", "")), "污染浆液 x1", "phase splinter refining completion log byproduct destination")
		host._expect_text_contains(String(completed[0].get("message", "")), "中继调谐镜", "phase splinter refining completion log next step")
	host._expect_equal(int(character.inventory.items.get("item.phase_lens_blank", 0)), 1, "phase splinter refining grants lens blank")
	host._expect_equal(float(character.inventory.fluids.get("fluid.polluted_slurry", 0.0)), 1.0, "phase splinter refining grants polluted slurry byproduct")
	var status := processing.get_recipe_status("recipe.phase_splinter_refining", character, world)
	host._expect_text_contains(String(status.get("last_next_step", "")), "中继调谐镜", "phase splinter refining panel next step")


func _check_relay_tuning_lens(processing: ProcessingSystem) -> void:
	var world := WorldState.create_default()
	var character := CharacterState.create_default()
	world.quest_state.unlock_effect("recipe.relay_tuning_lens")
	character.inventory.add_item("item.phase_lens_blank", 1)
	character.inventory.add_fluid("fluid.polluted_slurry", 1.0)
	character.inventory.items["item.basic_parts"] = 2
	var start := processing.process_recipe("recipe.relay_tuning_lens", character, world)
	host._expect_equal(bool(start.get("success", false)), true, "relay tuning lens processing should start")
	var completed := processing.advance_processing(20.0, character, world)
	host._expect_equal(completed.size(), 1, "relay tuning lens processing should complete")
	if not completed.is_empty():
		host._expect_text_contains(String(completed[0].get("message", "")), "中继调谐镜 x1", "relay tuning lens completion log output destination")
		host._expect_text_contains(String(completed[0].get("message", "")), "裂相尖塔", "relay tuning lens completion log next step")
	host._expect_equal(int(character.inventory.items.get("item.relay_tuning_lens", 0)), 1, "relay tuning lens grants calibration item")
	var status := processing.get_recipe_status("recipe.relay_tuning_lens", character, world)
	host._expect_text_contains(String(status.get("last_next_step", "")), "裂相尖塔", "relay tuning lens panel next step")


func _create_filter_world(recipe_id: String) -> WorldState:
	var world := WorldState.create_default()
	world.quest_state.unlock_effect(recipe_id)
	world.add_base_structure(
		"structure.pollution_filter_build_site",
		"building.pollution_filter",
		"region.pollution_edge",
		"map_object_instance.pollution_filter_build_site"
	)
	return world
