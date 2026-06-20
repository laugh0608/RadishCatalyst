extends SceneTree

const VerticalSliceMapScene := preload("res://scenes/maps/VerticalSliceMap.tscn")

var failures: Array[String] = []
var data_registry := DataRegistry.new()


func _init() -> void:
	if not data_registry.load_all():
		failures.append("data registry should load all static data")
	else:
		_run_checks()

	if failures.is_empty():
		print("Demo resource chain state checks passed.")
		_cleanup()
		quit(0)
		return

	for failure in failures:
		push_error(failure)
	_cleanup()
	quit(1)


func _run_checks() -> void:
	_check_core_resource_scope()
	_check_hud_resource_chain_state()
	_check_device_panel_resource_chain_state()
	_check_processing_result_resource_chain()
	_check_first_industrial_chain_hud_and_visual_state()
	_check_pollution_chain_hud_and_visual_state()
	_check_crystal_resource_visual_layer()
	_check_resource_chain_state_roundtrip()


func _check_core_resource_scope() -> void:
	var resource_ids := DemoResourceChainStateFormatter.get_core_resource_ids()
	_expect_equal(resource_ids.size(), 8, "resource chain covers eight core resources")
	_expect_array_has(resource_ids, "item.crystal_ore", "resource scope includes crystal ore")
	_expect_array_has(resource_ids, "item.polluted_residue", "resource scope includes polluted residue")
	_expect_array_has(resource_ids, "fluid.polluted_slurry", "resource scope includes polluted slurry")
	_expect_array_has(resource_ids, "item.core_stabilization_buffer", "resource scope includes core buffer")


func _check_hud_resource_chain_state() -> void:
	var world := _create_resource_chain_world("quest.prepare_demo_stabilization_buffer")
	var character := CharacterState.create_default()
	character.inventory.add_item("item.polluted_residue", 2)
	character.inventory.add_fluid("fluid.basic_solvent", 1.0)

	var hud_text := HudStatusPresenter.new().format_vitals_text(data_registry, world, character)
	_expect_text_contains(hud_text, "资源链状态", "HUD shows resource chain state")
	_expect_text_contains(hud_text, "污染处理待加工", "HUD identifies pollution treatment stage")
	_expect_text_contains(hud_text, "污染沉积物", "HUD names polluted residue in resource snapshot")
	_expect_text_contains(hud_text, "抗污染药剂 + 污染浆液", "HUD explains pollution treatment outputs")


func _check_device_panel_resource_chain_state() -> void:
	var world := _create_resource_chain_world("quest.prepare_demo_stabilization_buffer")
	var character := CharacterState.create_default()
	character.inventory.add_item("item.polluted_residue", 2)
	character.inventory.add_fluid("fluid.basic_solvent", 1.0)
	var filter := _create_processing_interactable("building.pollution_filter", "recipe.cleanse_residue")

	var panel := HudDevicePanelPresenter.new().format_device_panel_texts(
		data_registry,
		ProcessingSystem.new(data_registry),
		filter,
		character,
		world
	)
	var status := String(panel.get("status", ""))
	_expect_text_contains(status, "资源链状态", "device panel shows resource chain state")
	_expect_text_contains(status, "污染处理链", "device panel names pollution processing chain")
	_expect_text_contains(status, "药剂进快捷补给", "device panel explains vial destination")
	_expect_text_contains(status, "副产回收", "device panel explains byproduct recovery")
	filter.free()


func _check_processing_result_resource_chain() -> void:
	var world := _create_resource_chain_world("quest.prepare_demo_stabilization_buffer")
	var character := CharacterState.create_default()
	character.inventory.add_item("item.crystal_ore", 3)
	var processing := ProcessingSystem.new(data_registry)

	var started := processing.process_recipe("recipe.process_crystal_ore", character, world)
	_expect_equal(bool(started.get("success", false)), true, "solid processing starts")
	var completed := processing.advance_processing(20.0, character, world)
	_expect_equal(completed.size(), 1, "solid processing completes")
	if completed.is_empty():
		return

	var result_log := HudLogPresenter.new(data_registry).format_result_log(completed[0])
	_expect_text_contains(result_log, "资源链", "processing result log shows resource chain")
	_expect_text_contains(result_log, "固体加工链完成", "processing result names solid chain completion")
	_expect_text_contains(result_log, "基础零件", "processing result keeps parts destination")
	_expect_equal(int(character.inventory.items.get("item.basic_parts", 0)), 8, "solid processing grants parts")


func _check_first_industrial_chain_hud_and_visual_state() -> void:
	var world := _create_resource_chain_world("quest.prepare_treatment_supplies")
	world.add_base_structure("structure.basic_storage", "building.basic_storage", "region.outpost_platform")
	world.add_base_structure("structure.field_outfitting_station", "building.field_outfitting_station", "region.outpost_platform")
	world.set_base_structure_status("structure.basic_reactor", "in_progress", "recipe.process_crystal_ore")
	var character := CharacterState.create_default()
	character.inventory.add_item("item.crystal_ore", 3)
	character.inventory.add_item("item.salvage_scrap", 1)

	var hud_text := HudStatusPresenter.new().format_vitals_text(data_registry, world, character)
	_expect_text_contains(hud_text, "固体链加工中", "HUD shows first industrial chain state")
	_expect_text_contains(hud_text, "晶体矿物 -> 基础反应器 -> 基础零件", "HUD names the first industrial chain route")

	var map := VerticalSliceMapScene.instantiate() as VerticalSliceMap
	root.add_child(map)
	var layer := map.get_node("DemoIndustrialBaseVisualLayer") as DemoIndustrialBaseVisualLayer
	layer.apply_visuals()
	_expect_equal(layer.get_detail_shape_count() >= 9, true, "industrial base visual layer registers device and floor detail shapes")
	_expect_equal(layer.has_detail_shape("floor.service_grates"), true, "industrial base visual layer marks floor service grates")
	_expect_equal(layer.has_detail_shape("device.basic_reactor.reaction_chamber"), true, "industrial base visual layer marks reactor chamber detail")
	_expect_equal(layer.has_detail_shape("device.basic_storage.shelf_bins"), true, "industrial base visual layer marks storage shelf detail")
	_expect_equal(layer.has_detail_shape("device.field_outfitting_station.module_rack"), true, "industrial base visual layer marks outfitting rack detail")
	_expect_equal(layer.has_detail_shape("device.departure_gate.pressure_door"), true, "industrial base visual layer marks departure gate detail")
	layer.refresh_chain_state(world, character)
	_expect_equal(layer.get_chain_state_shape_count() >= 13, true, "industrial visual layer creates first chain state shapes")
	_expect_equal(layer.has_chain_shape("chain.crystal_input.ready"), true, "industrial visual layer marks crystal input ready")
	_expect_equal(layer.has_chain_shape("chain.reactor_work_window.ready"), true, "industrial visual layer marks reactor working")
	_expect_equal(layer.has_chain_shape("chain.storage_repair_gel_slot.ready"), true, "industrial visual layer marks repair gel storage")
	_expect_equal(layer.has_chain_shape("chain.outfitting_supply_state.ready"), true, "industrial visual layer marks outfitting supply ready")
	_expect_equal(layer.has_chain_shape("chain.input_crystal_bin.ready"), true, "industrial visual layer marks crystal input bin ready")
	_expect_equal(layer.has_chain_shape("chain.input_salvage_bin.ready"), true, "industrial visual layer marks salvage input bin ready")
	_expect_equal(layer.has_chain_shape("chain.reactor_feed_lane.ready"), true, "industrial visual layer marks active feed lane")
	_expect_equal(layer.has_chain_shape("chain.reactor_process_core.ready"), true, "industrial visual layer marks active reactor core")
	_expect_equal(layer.has_chain_shape("chain.parts_output_tray.ready"), true, "industrial visual layer marks parts output tray")
	_expect_equal(layer.has_chain_shape("chain.repair_gel_cylinder.ready"), true, "industrial visual layer marks repair gel cylinder")
	_expect_equal(layer.has_chain_shape("chain.outfitting_launch_bus.ready"), true, "industrial visual layer marks outfitting launch bus")
	map.free()


func _check_pollution_chain_hud_and_visual_state() -> void:
	var world := _create_resource_chain_world("quest.prepare_demo_stabilization_buffer")
	world.set_base_structure_status("structure.pollution_filter", "in_progress", "recipe.cleanse_residue")
	var character := CharacterState.create_default()
	character.inventory.add_item("item.polluted_residue", 2)
	character.inventory.add_fluid("fluid.basic_solvent", 1.0)
	character.inventory.add_item("item.resistance_vial_t1", 1)
	character.inventory.add_fluid("fluid.polluted_slurry", 1.0)
	character.inventory.add_item("item.basic_parts", 2)
	character.inventory.add_item("item.repair_gel", 1)

	var hud_character := CharacterState.create_default()
	hud_character.inventory.add_item("item.polluted_residue", 2)
	hud_character.inventory.add_fluid("fluid.basic_solvent", 1.0)
	var hud_text := HudStatusPresenter.new().format_vitals_text(data_registry, world, hud_character)
	_expect_text_contains(hud_text, "污染处理待加工", "HUD keeps pollution chain state visible")
	_expect_text_contains(hud_text, "污染沉积物可进污染过滤器", "HUD names pollution filter route")

	var map := VerticalSliceMapScene.instantiate() as VerticalSliceMap
	root.add_child(map)
	var layer := map.get_node("DemoIndustrialBaseVisualLayer") as DemoIndustrialBaseVisualLayer
	layer.apply_visuals()
	layer.refresh_chain_state(world, character)
	_expect_equal(layer.get_pollution_chain_state_shape_count() >= 9, true, "industrial visual layer creates pollution chain state shapes")
	_expect_equal(layer.has_pollution_chain_shape("pollution_chain.residue_input_slot.ready"), true, "industrial visual layer marks pollution residue input")
	_expect_equal(layer.has_pollution_chain_shape("pollution_chain.solvent_input_slot.ready"), true, "industrial visual layer marks solvent input")
	_expect_equal(layer.has_pollution_chain_shape("pollution_chain.filter_process_window.ready"), true, "industrial visual layer marks pollution filter processing window")
	_expect_equal(layer.has_pollution_chain_shape("pollution_chain.vial_output_slot.ready"), true, "industrial visual layer marks resistance vial output")
	_expect_equal(layer.has_pollution_chain_shape("pollution_chain.slurry_byproduct_slot.ready"), true, "industrial visual layer marks polluted slurry byproduct")
	_expect_equal(layer.has_pollution_chain_shape("pollution_chain.vial_to_outfitting_route.ready"), true, "industrial visual layer marks vial route to outfitting")
	_expect_equal(layer.has_pollution_chain_shape("pollution_chain.slurry_return_route.ready"), true, "industrial visual layer marks slurry return route")
	_expect_equal(layer.has_pollution_chain_shape("pollution_chain.slurry_recycle_route.ready"), true, "industrial visual layer marks slurry recycle route")
	_expect_equal(layer.has_pollution_chain_shape("pollution_chain.core_prep_route.ready"), true, "industrial visual layer marks core preparation route")
	map.free()


func _check_crystal_resource_visual_layer() -> void:
	var map := VerticalSliceMapScene.instantiate() as VerticalSliceMap
	root.add_child(map)
	var layer := map.get_node_or_null("DemoCrystalResourceVisualLayer") as DemoCrystalResourceVisualLayer
	_expect_equal(layer != null, true, "crystal resource visual layer exists")
	if layer == null:
		map.free()
		return

	layer.apply_visuals()
	_expect_equal(layer.get_resource_shape_count() >= 9, true, "crystal visual layer registers resource shapes")
	_expect_equal(layer.get_flow_count() >= 4, true, "crystal visual layer registers resource flow lines")
	_expect_equal(layer.get_terrain_material_shape_count() >= 6, true, "crystal visual layer registers mining terrain materials")
	layer.refresh_focus_visibility(Vector2(-250, -48))
	_expect_equal(layer.visible, false, "crystal visual layer stays hidden at startup objective")
	layer.refresh_focus_visibility(Vector2(-38, -104))
	_expect_equal(layer.visible, true, "crystal visual layer appears when player reaches field departure")
	_expect_equal(layer.has_resource_shape("crystal.main_vein"), true, "crystal visual layer marks main vein")
	_expect_equal(layer.has_resource_shape("crystal.rich_vein"), true, "crystal visual layer marks rich vein")
	_expect_equal(layer.has_resource_shape("salvage.south_pocket"), true, "crystal visual layer marks salvage pocket")
	_expect_equal(layer.has_flow_shape("flow.crystal_to_base"), true, "crystal visual layer marks return flow")
	_expect_equal(layer.has_terrain_material_shape("terrain.crystal.harvest_face"), true, "crystal visual layer marks harvestable mine face")
	_expect_equal(layer.has_terrain_material_shape("terrain.crystal.rich_seam_ridges"), true, "crystal visual layer marks rich seam ridges")
	_expect_equal(layer.has_terrain_material_shape("terrain.crystal.scrap_recovery_yard"), true, "crystal visual layer marks salvage recovery yard")
	_expect_equal(layer.has_terrain_material_shape("terrain.crystal.return_cart_lane"), true, "crystal visual layer marks return cart lane")
	_expect_equal(layer.has_terrain_material_shape("terrain.crystal.base_loading_mouth"), true, "crystal visual layer marks base loading mouth")
	_expect_equal(layer.get_muted_resource_marker_count() >= 8, true, "crystal visual layer mutes old resource markers")

	var legacy_track := map.get_node("OpeningSceneLayer/CrystalMainVeinTrack") as ColorRect
	var legacy_pocket := map.get_node("OpeningSceneLayer/CrystalSalvageObjectPocket") as ColorRect
	_expect_equal(legacy_track.color.a <= 0.055, true, "crystal visual layer de-emphasizes old vein block")
	_expect_equal(legacy_pocket.color.a <= 0.055, true, "crystal visual layer de-emphasizes old salvage block")
	map.free()


func _check_resource_chain_state_roundtrip() -> void:
	var world := _create_resource_chain_world("quest.prepare_demo_stabilization_buffer")
	var character := CharacterState.create_default()
	character.inventory.add_item("item.basic_parts", 2)
	character.inventory.add_item("item.repair_gel", 1)
	character.inventory.add_item("item.resistance_vial_t1", 1)
	character.inventory.add_fluid("fluid.polluted_slurry", 1.0)

	var restored_world := WorldState.from_dict(world.to_dict())
	var restored_character := CharacterState.from_dict(character.to_dict())
	var chain_line := DemoResourceChainStateFormatter.format_chain_state_line(restored_world, restored_character)
	_expect_text_contains(chain_line, "核心缓冲包原料齐备", "round-trip keeps core buffer readiness")
	_expect_equal(int(restored_character.inventory.items.get("item.basic_parts", 0)), 6, "round-trip keeps basic parts")
	_expect_equal(float(restored_character.inventory.fluids.get("fluid.polluted_slurry", 0.0)), 1.0, "round-trip keeps polluted slurry")


func _create_resource_chain_world(active_quest_id: String) -> WorldState:
	var world := WorldState.create_default()
	world.current_region_id = "region.outpost_platform"
	world.quest_state.active_quest_ids = [active_quest_id]
	for recipe_id in [
		"recipe.cleanse_residue",
		"recipe.reclaim_basic_parts",
		"recipe.process_crystal_ore",
		"recipe.core_stabilization_buffer"
	]:
		world.quest_state.unlock_effect(recipe_id)
	world.add_base_structure("structure.pollution_filter", "building.pollution_filter", "region.pollution_edge")
	return world


func _create_processing_interactable(building_id: String, recipe_id: String) -> PrototypeInteractable:
	var interactable := PrototypeInteractable.new()
	interactable.definition_id = building_id
	interactable.interaction_type = "process_recipe"
	interactable.recipe_id = recipe_id
	interactable.set_recipe_cycle([recipe_id])
	return interactable


func _expect_equal(actual, expected, context: String) -> void:
	if actual == expected:
		return
	failures.append("%s: expected %s, got %s" % [context, str(expected), str(actual)])


func _expect_array_has(values: Array, expected, context: String) -> void:
	if values.has(expected):
		return
	failures.append("%s: expected array to contain %s, got %s" % [context, str(expected), str(values)])


func _expect_text_contains(text: String, expected: String, context: String) -> void:
	if text.find(expected) >= 0:
		return
	failures.append("%s: expected text to contain '%s', got '%s'" % [context, expected, text])


func _cleanup() -> void:
	data_registry.free()
