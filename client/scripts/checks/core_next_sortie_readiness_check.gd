extends RefCounted

var host


func _init(check_host) -> void:
	host = check_host


func run() -> void:
	_check_completed_core_write_returns_to_departure_readiness()


func _check_completed_core_write_returns_to_departure_readiness() -> void:
	var world_state := WorldState.create_default()
	world_state.current_region_id = "region.outpost_platform"
	world_state.quest_state.completed_quest_ids = [
		"quest.restore_outpost",
		"quest.enter_pollution_edge",
		"quest.write_demo_stabilization_core"
	]
	world_state.add_base_structure(
		"structure.basic_storage_build_site",
		"building.basic_storage",
		"region.outpost_platform",
		"map_object_instance.basic_storage_build_site"
	)
	world_state.add_base_structure(
		"structure.pollution_filter_build_site",
		"building.pollution_filter",
		"region.outpost_platform",
		"map_object_instance.pollution_filter_build_site"
	)
	world_state.add_base_structure(
		"structure.field_outfitting_station_build_site",
		"building.field_outfitting_station",
		"region.outpost_platform",
		"map_object_instance.field_outfitting_station_build_site"
	)
	world_state.ensure_enemy("enemy_instance.demo_stabilization_guard", "enemy.demo_stabilization_guard", "region.demo_stabilization_core", 156.0)
	world_state.get_enemy("enemy_instance.demo_stabilization_guard")["core_buffer_used"] = true
	world_state.get_enemy("enemy_instance.demo_stabilization_guard")["core_side_supply_used"] = true
	world_state.get_enemy("enemy_instance.demo_stabilization_guard")["pressure_vial_used"] = true
	world_state.ensure_map_object(
		"map_object_instance.demo_stabilization_guard_cache",
		"map_object.demo_stabilization_guard_cache",
		"region.demo_stabilization_core"
	)
	world_state.set_map_object_flag("map_object_instance.demo_stabilization_guard_cache", "is_gathered", true)

	var character_state := CharacterState.create_default()
	character_state.current_region_id = "region.outpost_platform"
	character_state.health = 71.0
	character_state.protection = 62.0
	character_state.inventory.consume_ref("item.repair_gel", 1)
	character_state.inventory.items.erase("item.resistance_vial_t1")

	var status_text := HudStatusPresenter.new().format_status_text(host.data_registry, world_state, character_state)
	_expect_text_contains(status_text, "下一趟出发", "post-write HUD shows next sortie readiness")
	_expect_text_contains(status_text, "回前哨核心补修复凝胶 / 回前哨核心补抗污染药剂", "post-write HUD shows refill needs")

	var formatter := InteractionPromptFormatter.new(
		host.data_registry,
		ProcessingSystem.new(host.data_registry),
		BuildSystem.new(host.data_registry)
	)
	var outpost_prompt := formatter.format_outpost_core_prompt(world_state, character_state)
	_expect_text_contains(outpost_prompt, "核心写入已归档", "post-write outpost prompt shows archived write")
	_expect_text_contains(outpost_prompt, "操作：E 补修复凝胶 / 抗污染药剂并恢复生命 / 防护", "post-write outpost prompt exposes refill action")

	var reactor := PrototypeInteractable.new()
	reactor.definition_id = "building.basic_reactor"
	reactor.interaction_type = "process_recipe"
	reactor.recipe_id = "recipe.process_crystal_ore"
	var panel := HudDevicePanelPresenter.new().format_device_panel_texts(
		host.data_registry,
		ProcessingSystem.new(host.data_registry),
		reactor,
		character_state,
		world_state
	)
	_expect_text_contains(String(panel.get("status", "")), "核心写入归档", "post-write device panel shows next sortie context")
	_expect_text_contains(String(panel.get("status", "")), "先在前哨核心恢复生命 / 防护", "post-write device panel points to outpost recovery")
	reactor.free()

	var outpost_result := GatherSystem.new(host.data_registry).interact_with_object(
		"map_object_instance.outpost_core",
		"building.outpost_core",
		"outpost_core",
		character_state,
		world_state
	)
	host._expect_equal(bool(outpost_result.get("success", false)), true, "post-write outpost core refit succeeds")
	_expect_text_contains(String(outpost_result.get("message", "")), "核心写入已归档", "post-write outpost feedback keeps next sortie context")
	host._expect_equal(character_state.are_vitals_full(), true, "post-write outpost refit restores vitals")
	host._expect_equal(int(character_state.inventory.items.get("item.repair_gel", 0)), 1, "post-write outpost refills repair gel")
	host._expect_equal(int(character_state.inventory.items.get("item.resistance_vial_t1", 0)), 1, "post-write outpost refills resistance vial")


func _expect_text_contains(text: String, expected_text: String, label: String) -> void:
	if text.find(expected_text) < 0:
		host.failures.append("%s should contain %s, got %s" % [label, expected_text, text])
