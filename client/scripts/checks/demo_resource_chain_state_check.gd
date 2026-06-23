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
	_check_operation_relation_visual_shapes()
	_check_crystal_collector_runtime_chain()
	_check_visual_review_checkpoint_path_states()
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
	var first_path_layer := map.get_node("DemoFirstIndustrialPathVisualLayer") as DemoFirstIndustrialPathVisualLayer
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

	first_path_layer.apply_visuals()
	_expect_equal(first_path_layer.get_path_shape_count() >= 18, true, "first industrial path layer registers the playable path slice")
	_expect_equal(first_path_layer.has_path_shape("first_path.primary_player_lane"), true, "first industrial path layer marks the player route")
	_expect_equal(first_path_layer.has_path_shape("first_path.context_side_falloff"), true, "first industrial path layer dims adjacent planning context")
	_expect_equal(first_path_layer.has_path_shape("first_path.local_material_patches"), true, "first industrial path layer adds local ground and material patches")
	_expect_equal(first_path_layer.has_path_shape("first_path.crystal_cut_workface"), true, "first industrial path layer marks the crystal cut workface")
	_expect_equal(first_path_layer.has_path_shape("first_path.hand_sample_point"), true, "first industrial path layer marks the player hand sampling point")
	_expect_equal(first_path_layer.has_path_shape("first_path.auto_miner_workface"), true, "first industrial path layer marks the automatic mining workface")
	_expect_equal(first_path_layer.has_path_shape("first_path.auto_miner_output_tray"), true, "first industrial path layer marks the miner output tray")
	_expect_equal(first_path_layer.has_path_shape("first_path.salvage_sorting_workface"), true, "first industrial path layer marks the salvage sorting workface")
	_expect_equal(first_path_layer.has_path_shape("first_path.crystal_pickup_pad"), true, "first industrial path layer marks crystal pickup")
	_expect_equal(first_path_layer.has_path_shape("first_path.salvage_pickup_pad"), true, "first industrial path layer marks salvage pickup")
	_expect_equal(first_path_layer.has_path_shape("first_path.base_receiving_bay"), true, "first industrial path layer marks base receiving bay")
	_expect_equal(first_path_layer.has_path_shape("first_path.base_receiving_logistics_port"), true, "first industrial path layer marks the base receiving port")
	_expect_equal(first_path_layer.has_path_shape("first_path.reactor_input_workbench"), true, "first industrial path layer marks the reactor input workbench")
	_expect_equal(first_path_layer.has_path_shape("first_path.reactor_feed_hopper"), true, "first industrial path layer marks reactor feed")
	_expect_equal(first_path_layer.has_path_shape("first_path.storage_output_bins"), true, "first industrial path layer marks storage output bins")
	_expect_equal(first_path_layer.has_path_shape("first_path.storage_output_shelf"), true, "first industrial path layer marks storage output")
	_expect_equal(first_path_layer.has_path_shape("first_path.outfitting_departure_port"), true, "first industrial path layer marks the outfitting departure port")
	_expect_equal(first_path_layer.has_path_shape("first_path.outfitting_handoff_rack"), true, "first industrial path layer marks outfitting handoff")
	_expect_equal(first_path_layer.has_path_shape("first_path.context_clarity_mask"), true, "first industrial path layer applies a local clarity mask")
	_expect_equal(first_path_layer.has_path_shape("first_path.collector_output_local_signal"), true, "first industrial path layer keeps collector output signal local")
	_expect_equal(first_path_layer.has_path_shape("first_path.handoff_port_chain"), true, "first industrial path layer registers base handoff ports")
	_expect_equal(first_path_layer.has_path_shape("first_path.single_signal_stage"), true, "first industrial path layer uses one active stage signal")
	_expect_equal(first_path_layer.has_path_shape("first_path.device_status_lights"), true, "first industrial path layer registers device status lights")
	_expect_equal(first_path_layer.has_path_shape("first_path.resource_flow_packets"), true, "first industrial path layer registers resource flow packets")
	_expect_equal(first_path_layer.has_path_shape("first_path.material_state_slots"), true, "first industrial path layer registers material state slots")
	first_path_layer.refresh_path_state(WorldState.create_default(), CharacterState.create_default())
	_expect_equal(first_path_layer.is_first_path_available(), false, "first industrial path layer waits for outpost restoration")
	_expect_equal(first_path_layer.is_first_path_visible_at(Vector2(-250.0, -48.0)), false, "first industrial path layer does not preempt the first outpost core interaction")
	_expect_equal(first_path_layer.visible, false, "first industrial path layer starts hidden before the core is restored")
	first_path_layer.refresh_path_state(world, character)
	first_path_layer.refresh_focus_visibility(Vector2(-250.0, -48.0))
	var first_path_main_route := map.get_node("MainRouteSpine") as ColorRect
	var first_path_crystal_boundary := map.get_node("RegionBoundaryCrystal") as ColorRect
	_expect_equal(first_path_layer.is_first_path_available(), true, "first industrial path layer opens after outpost restoration")
	_expect_equal(first_path_layer.get_muted_planning_layer_count() >= 6, true, "first industrial path layer pushes overlapping visual layers into the background")
	_expect_equal(first_path_layer.get_muted_context_rect_count() >= 10, true, "first industrial path layer suppresses cross-region route rectangles")
	_expect_equal(first_path_main_route.color.a <= 0.001, true, "first industrial path layer lowers the global route spine")
	_expect_equal(first_path_crystal_boundary.color.a <= 0.006, true, "first industrial path layer lowers region boundary frames")
	_expect_equal(first_path_layer.is_first_path_visible_at(Vector2(-250.0, -48.0)), true, "first industrial path layer is visible at base start")
	_expect_equal(first_path_layer.is_first_path_visible_at(Vector2(112.0, -112.0)), true, "first industrial path layer is visible at crystal pickup")
	_expect_equal(first_path_layer.is_first_path_visible_at(Vector2(168.0, 34.0)), false, "first industrial path layer steps back before pollution treatment boundary")
	_expect_equal(first_path_layer.is_first_path_visible_at(Vector2(3744.0, 112.0)), false, "first industrial path layer does not cover the core station")
	first_path_layer.refresh_focus_visibility(Vector2(3744.0, 112.0))
	_expect_equal(first_path_layer.visible, false, "first industrial path layer hides at core station")
	_expect_equal(first_path_layer.get_muted_planning_layer_count(), 0, "first industrial path layer restores background layers outside its scope")
	first_path_layer.refresh_focus_visibility(Vector2(-250.0, -48.0))
	_expect_equal(first_path_layer.get_path_state_shape_count() >= 8, true, "first industrial path layer creates state shapes")
	_expect_equal(
		first_path_layer.get_active_stage(),
		DemoFirstIndustrialPathVisualLayer.STAGE_REACTOR_PROCESSING,
		"first industrial path layer marks the current reactor operation stage"
	)
	_expect_equal(first_path_layer.has_path_state_shape("first_path.crystal_pickup.ready"), true, "first industrial path layer marks crystal state")
	_expect_equal(first_path_layer.has_path_state_shape("first_path.hand_sample.ready"), true, "first industrial path layer marks hand sample state")
	_expect_equal(first_path_layer.has_path_state_shape("first_path.auto_miner_output.ready"), true, "first industrial path layer marks auto miner output state")
	_expect_equal(first_path_layer.has_path_state_shape("first_path.salvage_pickup.ready"), true, "first industrial path layer marks salvage state")
	_expect_equal(first_path_layer.has_path_state_shape("first_path.base_receiving_bay.ready"), true, "first industrial path layer marks base receiving state")
	_expect_equal(first_path_layer.has_path_state_shape("first_path.reactor_work_window.ready"), true, "first industrial path layer marks reactor state")
	_expect_equal(first_path_layer.has_path_state_shape("first_path.storage_output.idle"), true, "first industrial path layer waits for completed output before storage")
	_expect_equal(first_path_layer.has_path_state_shape("first_path.outfitting_handoff.idle"), true, "first industrial path layer waits for crafted supply before outfitting")
	_expect_equal(first_path_layer.has_path_state_shape("first_path.device.receiving.loaded"), true, "first industrial path layer marks receiving bay loaded")
	_expect_equal(first_path_layer.has_path_state_shape("first_path.device.reactor.processing"), true, "first industrial path layer marks reactor processing status")
	_expect_equal(first_path_layer.has_path_state_shape("first_path.flow.field_to_receiving.ready"), true, "first industrial path layer marks resource return flow")
	_expect_equal(first_path_layer.has_path_state_shape("first_path.flow.receiving_to_reactor.ready"), true, "first industrial path layer marks receiving to reactor flow")
	_expect_equal(first_path_layer.has_path_state_shape("first_path.flow.reactor_processing.active"), true, "first industrial path layer marks active reactor flow")
	_expect_equal(first_path_layer.has_path_state_shape("first_path.stage.reactor_processing"), true, "first industrial path layer records reactor operation stage")
	_check_first_industrial_path_stage_changes(first_path_layer)
	map.free()


func _check_operation_relation_visual_shapes() -> void:
	var map := VerticalSliceMapScene.instantiate() as VerticalSliceMap
	root.add_child(map)
	var base_layer := map.get_node("DemoIndustrialBaseVisualLayer") as DemoIndustrialBaseVisualLayer
	var first_path_layer := map.get_node("DemoFirstIndustrialPathVisualLayer") as DemoFirstIndustrialPathVisualLayer
	base_layer.apply_visuals()
	first_path_layer.apply_visuals()

	_expect_equal(base_layer.get_detail_shape_count() >= 16, true, "industrial base registers operation relation details")
	_expect_equal(base_layer.has_detail_shape("operation_relation.core_restore_to_reactor"), true, "base visual links restored core to reactor")
	_expect_equal(base_layer.has_detail_shape("operation_relation.reactor_to_storage"), true, "base visual links reactor output to storage")
	_expect_equal(base_layer.has_detail_shape("operation_relation.storage_to_outfitting"), true, "base visual links storage to outfitting")
	_expect_equal(base_layer.has_detail_shape("operation_relation.filter_to_outfitting"), true, "base visual links filter vial output to outfitting")
	_expect_equal(base_layer.has_detail_shape("operation_relation.slurry_to_reactor_reclaim"), true, "base visual links slurry return to reactor reclaim")
	_expect_equal(base_layer.has_detail_shape("operation_relation.slurry_to_core_prep"), true, "base visual links slurry return to core prep")
	_expect_equal(base_layer.has_detail_shape("operation_relation.device_role_ports"), true, "base visual marks relation ports on devices")

	_expect_equal(first_path_layer.has_path_shape("first_path.operation_relation.collector_to_receiving"), true, "first path links collector output to receiving")
	_expect_equal(first_path_layer.has_path_shape("first_path.operation_relation.salvage_to_receiving"), true, "first path links salvage pickup to receiving")
	_expect_equal(first_path_layer.has_path_shape("first_path.operation_relation.receiving_to_reactor"), true, "first path links receiving bay to reactor")
	_expect_equal(first_path_layer.has_path_shape("first_path.operation_relation.reactor_to_storage"), true, "first path links reactor to storage")
	_expect_equal(first_path_layer.has_path_shape("first_path.operation_relation.storage_to_outfitting"), true, "first path links storage to outfitting")
	_expect_equal(first_path_layer.has_path_shape("first_path.operation_relation.device_role_ports"), true, "first path marks operation relation ports")
	map.free()


func _check_first_industrial_path_stage_changes(first_path_layer: DemoFirstIndustrialPathVisualLayer) -> void:
	var stage_world := _create_resource_chain_world("quest.prepare_treatment_supplies")
	var stage_character := CharacterState.create_default()

	first_path_layer.refresh_path_state(stage_world, stage_character)
	_expect_equal(
		first_path_layer.get_active_stage(),
		DemoFirstIndustrialPathVisualLayer.STAGE_FIELD_PICKUP,
		"first industrial path keeps starting supplies from skipping field pickup"
	)

	stage_character.inventory.items.clear()
	stage_character.inventory.fluids.clear()

	first_path_layer.refresh_path_state(stage_world, stage_character)
	_expect_equal(
		first_path_layer.get_active_stage(),
		DemoFirstIndustrialPathVisualLayer.STAGE_FIELD_PICKUP,
		"first industrial path starts by pointing to field pickup"
	)
	_expect_equal(first_path_layer.has_path_state_shape("first_path.stage.field_pickup"), true, "first path records field pickup stage")

	stage_character.current_region_id = "region.crystal_vein_field"
	stage_character.position = Vector2(112.0, -112.0)
	stage_character.inventory.add_item("item.crystal_ore", 3)
	first_path_layer.refresh_path_state(stage_world, stage_character)
	_expect_equal(
		first_path_layer.get_active_stage(),
		DemoFirstIndustrialPathVisualLayer.STAGE_RETURN_TO_BASE,
		"first industrial path points gathered resources back to base"
	)
	_expect_equal(first_path_layer.has_path_state_shape("first_path.stage.return_to_base"), true, "first path records return stage")

	stage_character.current_region_id = "region.outpost_platform"
	stage_character.position = Vector2(-250.0, -48.0)
	first_path_layer.refresh_path_state(stage_world, stage_character)
	_expect_equal(
		first_path_layer.get_active_stage(),
		DemoFirstIndustrialPathVisualLayer.STAGE_BASE_RECEIVING,
		"first industrial path moves returned resources into base receiving"
	)
	_expect_equal(first_path_layer.has_path_state_shape("first_path.stage.base_receiving"), true, "first path records base receiving stage")

	stage_character.position = Vector2(-166.0, -66.0)
	first_path_layer.refresh_path_state(stage_world, stage_character)
	_expect_equal(
		first_path_layer.get_active_stage(),
		DemoFirstIndustrialPathVisualLayer.STAGE_REACTOR_FEED,
		"first industrial path moves returned resources from receiving into reactor feed"
	)
	_expect_equal(first_path_layer.has_path_state_shape("first_path.stage.reactor_feed"), true, "first path records reactor feed stage")

	stage_world.set_base_structure_status("structure.basic_reactor", "in_progress", "recipe.process_crystal_ore")
	first_path_layer.refresh_path_state(stage_world, stage_character)
	_expect_equal(
		first_path_layer.get_active_stage(),
		DemoFirstIndustrialPathVisualLayer.STAGE_REACTOR_PROCESSING,
		"first industrial path moves resources into reactor processing"
	)

	stage_world.set_base_structure_status("structure.basic_reactor", "completed", "recipe.process_crystal_ore")
	stage_character.inventory.items.clear()
	stage_character.inventory.add_item("item.basic_parts", 1)
	first_path_layer.refresh_path_state(stage_world, stage_character)
	_expect_equal(
		first_path_layer.get_active_stage(),
		DemoFirstIndustrialPathVisualLayer.STAGE_STORAGE_OUTPUT,
		"first industrial path moves finished output into storage"
	)
	_expect_equal(first_path_layer.has_path_state_shape("first_path.stage.storage_output"), true, "first path records storage output stage")

	stage_world.add_base_structure("structure.field_outfitting_station", "building.field_outfitting_station", "region.outpost_platform")
	stage_world.set_base_structure_status("structure.basic_reactor", "completed", "recipe.repair_gel")
	stage_character.inventory.add_item("item.repair_gel", 1)
	first_path_layer.refresh_path_state(stage_world, stage_character)
	_expect_equal(
		first_path_layer.get_active_stage(),
		DemoFirstIndustrialPathVisualLayer.STAGE_OUTFITTING_READY,
		"first industrial path moves supplies into outfitting handoff"
	)
	_expect_equal(first_path_layer.has_path_state_shape("first_path.stage.outfitting_ready"), true, "first path records outfitting stage")


func _check_crystal_collector_runtime_chain() -> void:
	var map := VerticalSliceMapScene.instantiate() as VerticalSliceMap
	root.add_child(map)
	map.setup(data_registry)
	var build_site := map.get_node("Interactables/CrystalCollectorBuildSite") as PrototypeInteractable
	var output := map.get_node("Interactables/CrystalCollectorOutput") as PrototypeInteractable

	var new_world := WorldState.create_default()
	map.refresh_world_interactables(new_world)
	_expect_equal(build_site.visible, false, "crystal collector build site stays out of new-game core focus")
	_expect_equal(output.visible, false, "crystal collector output stays hidden before the collector is built")

	var world := _create_resource_chain_world("quest.scout_crystal_field")
	var character := CharacterState.create_default()
	character.current_region_id = "region.crystal_vein_field"
	character.position = Vector2(132.0, -126.0)
	character.inventory.add_item("item.basic_parts", 2)
	character.inventory.add_item("item.salvage_scrap", 1)
	map.refresh_world_interactables(world)
	_expect_equal(build_site.visible, true, "crystal collector build site appears after outpost restoration")
	_expect_equal(output.visible, false, "crystal collector output waits for built collector")

	var build_result := BuildSystem.new(data_registry).build_structure(
		"map_object_instance.crystal_collector_build_site",
		"building.crystal_collector_t1",
		character,
		world
	)
	_expect_equal(bool(build_result.get("success", false)), true, "crystal collector can be built from field materials")
	_expect_equal(
		world.has_base_structure_definition("building.crystal_collector_t1"),
		true,
		"crystal collector writes a base structure"
	)
	map.refresh_world_interactables(world)
	_expect_equal(output.visible, true, "crystal collector output appears after the collector is built")

	var ready_line := DemoResourceChainStateFormatter.format_chain_state_line(world, character)
	_expect_text_contains(ready_line, "采集设备待收料", "resource chain notices collector output before pickup")

	var gather_result := GatherSystem.new(data_registry).interact_with_object(
		"map_object_instance.crystal_collector_output",
		"map_object.crystal_collector_output",
		"gather",
		character,
		world
	)
	_expect_equal(bool(gather_result.get("success", false)), true, "collector output can be gathered")
	_expect_text_contains(String(gather_result.get("message", "")), "已收取", "collector output uses pickup completion wording")
	_expect_equal(int(character.inventory.items.get("item.crystal_ore", 0)) >= 3, true, "collector output grants crystal ore")
	_expect_equal(
		bool(world.get_map_object("map_object_instance.crystal_collector_output").get("is_gathered", false)),
		true,
		"collector output writes gathered state"
	)

	var quest_updates := QuestEventRules.new(data_registry).get_interaction_objective_updates(
		{"definition_id": "map_object.crystal_collector_output", "interaction_type": "gather"},
		gather_result,
		world.quest_state
	)
	_expect_equal(_has_update_target(quest_updates, "quest.scout_crystal_field", "item.crystal_ore"), true, "collector output feeds crystal field objective updates")
	var after_line := DemoResourceChainStateFormatter.format_chain_state_line(world, character)
	_expect_text_contains(after_line, "固体链待加工", "resource chain moves gathered collector output to reactor input")
	map.free()


func _check_visual_review_checkpoint_path_states() -> void:
	var builder := DevelopmentBaselineBuilder.new(data_registry)
	var map := VerticalSliceMapScene.instantiate() as VerticalSliceMap
	root.add_child(map)
	var first_path_layer := map.get_node("DemoFirstIndustrialPathVisualLayer") as DemoFirstIndustrialPathVisualLayer
	first_path_layer.apply_visuals()

	var collector_result := builder.create_visual_review_checkpoint_state("visual_review.crystal_collector_output")
	_expect_equal(bool(collector_result.get("success", false)), true, "collector output visual checkpoint builds")
	if bool(collector_result.get("success", false)):
		first_path_layer.refresh_path_state(collector_result["world_state"], collector_result["character_state"])
		_expect_equal(
			first_path_layer.get_active_stage(),
			DemoFirstIndustrialPathVisualLayer.STAGE_FIELD_PICKUP,
			"collector output visual checkpoint stays in field pickup stage"
		)
		_expect_equal(
			first_path_layer.has_path_state_shape("first_path.auto_miner_output.ready"),
			true,
			"collector output visual checkpoint marks miner tray ready"
		)
		_expect_equal(
			first_path_layer.has_path_state_shape("first_path.auto_miner_output.current_stage"),
			true,
			"collector output visual checkpoint uses local miner tray stage"
		)
		_expect_equal(
			first_path_layer.has_path_state_shape("first_path.device.collector.output_ready"),
			true,
			"collector output visual checkpoint marks collector output status"
		)
		_expect_equal(
			first_path_layer.has_path_state_shape("first_path.flow.auto_miner_to_tray.ready"),
			true,
			"collector output visual checkpoint marks miner-to-tray resource flow"
		)

	var handoff_result := builder.create_visual_review_checkpoint_state("visual_review.base_handoff")
	_expect_equal(bool(handoff_result.get("success", false)), true, "base handoff visual checkpoint builds")
	if bool(handoff_result.get("success", false)):
		first_path_layer.refresh_path_state(handoff_result["world_state"], handoff_result["character_state"])
		_expect_equal(
			first_path_layer.get_active_stage(),
			DemoFirstIndustrialPathVisualLayer.STAGE_OUTFITTING_READY,
			"base handoff visual checkpoint lands on outfitting handoff stage"
		)
		_expect_equal(
			first_path_layer.has_path_state_shape("first_path.outfitting_handoff.ready"),
			true,
			"base handoff visual checkpoint marks outfitting handoff ready"
		)
		_expect_equal(
			first_path_layer.has_path_state_shape("first_path.handoff_ports.ready"),
			true,
			"base handoff visual checkpoint marks port chain ready"
		)
		_expect_equal(
			first_path_layer.has_path_state_shape("first_path.device.storage.product_ready"),
			true,
			"base handoff visual checkpoint marks storage output status"
		)
		_expect_equal(
			first_path_layer.has_path_state_shape("first_path.device.outfitting.supply_ready"),
			true,
			"base handoff visual checkpoint marks outfitting supply status"
		)
		_expect_equal(
			first_path_layer.has_path_state_shape("first_path.flow.storage_to_outfitting.ready"),
			true,
			"base handoff visual checkpoint marks storage-to-outfitting flow"
		)
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
	_expect_equal(layer.get_terrain_material_shape_count() >= 16, true, "crystal visual layer registers mining terrain materials")
	layer.refresh_focus_visibility(Vector2(-250, -48))
	_expect_equal(layer.visible, false, "crystal visual layer stays hidden at startup objective")
	layer.refresh_focus_visibility(Vector2(-38, -104))
	var crystal_focus_route := map.get_node("MainRouteSpine") as ColorRect
	var crystal_focus_boundary := map.get_node("RegionBoundaryPollution") as ColorRect
	_expect_equal(layer.visible, true, "crystal visual layer appears when player reaches field departure")
	_expect_equal(layer.get_muted_departure_focus_count() >= 1, true, "crystal visual layer suppresses departure gate focus label in field view")
	_expect_equal(layer.get_muted_crystal_focus_context_layer_count() >= 10, true, "crystal visual layer mutes neighboring visual context layers")
	_expect_equal(layer.get_muted_crystal_focus_context_rect_count() >= 10, true, "crystal visual layer suppresses cross-region route rectangles")
	_expect_equal(crystal_focus_route.color.a <= 0.001, true, "crystal visual layer lowers the global route spine")
	_expect_equal(crystal_focus_boundary.color.a <= 0.006, true, "crystal visual layer lowers neighboring region boundary frames")
	layer.refresh_focus_visibility(Vector2(168, 34))
	_expect_equal(layer.visible, false, "crystal visual layer steps back after entering pollution treatment boundary")
	_expect_equal(layer.has_resource_shape("crystal.main_vein"), true, "crystal visual layer marks main vein")
	_expect_equal(layer.has_resource_shape("crystal.rich_vein"), true, "crystal visual layer marks rich vein")
	_expect_equal(layer.has_resource_shape("crystal.hand_sample_probe"), true, "crystal visual layer marks player hand sampling")
	_expect_equal(layer.has_resource_shape("crystal.auto_miner.primary"), true, "crystal visual layer marks the primary automatic miner")
	_expect_equal(layer.has_resource_shape("crystal.auto_miner.output_tray"), true, "crystal visual layer marks the miner output tray")
	_expect_equal(layer.has_resource_shape("salvage.south_pocket"), true, "crystal visual layer marks salvage pocket")
	_expect_equal(layer.has_flow_shape("flow.crystal_to_base"), true, "crystal visual layer marks return flow")
	_expect_equal(layer.has_flow_shape("flow.auto_miner_to_loading_tray"), true, "crystal visual layer marks miner output flow")
	_expect_equal(layer.has_terrain_material_shape("terrain.crystal.harvest_face"), true, "crystal visual layer marks harvestable mine face")
	_expect_equal(layer.has_terrain_material_shape("terrain.crystal.broken_mine_shadow_patches"), true, "crystal visual layer breaks the old blue ore field with irregular mine patches")
	_expect_equal(layer.has_terrain_material_shape("terrain.crystal.mine_cutout_baffles"), true, "crystal visual layer cuts dark baffles through the old blue ore field")
	_expect_equal(layer.has_terrain_material_shape("terrain.crystal.old_field_voids"), true, "crystal visual layer cuts old blue field into dark local voids")
	_expect_equal(layer.has_terrain_material_shape("terrain.crystal.mine_face_islands"), true, "crystal visual layer splits harvest face into mine islands")
	_expect_equal(layer.has_terrain_material_shape("terrain.crystal.dark_cut_channels"), true, "crystal visual layer cuts dark channels through old ore block")
	_expect_equal(layer.has_terrain_material_shape("terrain.crystal.fractured_ore_tiles"), true, "crystal visual layer breaks old ore block into fractured tiles")
	_expect_equal(layer.has_terrain_material_shape("terrain.crystal.local_harvest_work_pads"), true, "crystal visual layer marks local harvest work pads")
	_expect_equal(layer.has_terrain_material_shape("terrain.crystal.rich_seam_ridges"), true, "crystal visual layer marks rich seam ridges")
	_expect_equal(layer.has_terrain_material_shape("terrain.crystal.mine_bench_steps"), true, "crystal visual layer marks cut bench steps")
	_expect_equal(layer.has_terrain_material_shape("terrain.crystal.scrap_recovery_yard"), true, "crystal visual layer marks salvage recovery yard")
	_expect_equal(layer.has_terrain_material_shape("terrain.crystal.salvage_sorting_lanes"), true, "crystal visual layer marks salvage sorting lanes")
	_expect_equal(layer.has_terrain_material_shape("terrain.crystal.return_cart_lane"), true, "crystal visual layer marks return cart lane")
	_expect_equal(layer.has_terrain_material_shape("terrain.crystal.loading_sleepers"), true, "crystal visual layer marks loading sleepers")
	_expect_equal(layer.has_terrain_material_shape("terrain.crystal.base_loading_mouth"), true, "crystal visual layer marks base loading mouth")
	_expect_equal(layer.get_muted_resource_marker_count() >= 8, true, "crystal visual layer mutes old resource markers")
	_expect_equal(layer.get_muted_legacy_block_count() >= 20, true, "crystal visual layer hides old rectangular crystal blocks")
	_expect_equal(layer.get_muted_departure_label_count() >= 1, true, "crystal visual layer mutes old base departure label")

	var legacy_track := map.get_node("OpeningSceneLayer/CrystalMainVeinTrack") as ColorRect
	var legacy_pocket := map.get_node("OpeningSceneLayer/CrystalSalvageObjectPocket") as ColorRect
	var route_band := map.get_node("DemoRoutePresentationLayer/DemoRouteCrystalBand") as ColorRect
	var departure_label := map.get_node("OpeningSceneLayer/BaseExitLaneLabel") as Label
	_expect_equal(legacy_track.color.a <= 0.002 and not legacy_track.visible, true, "crystal visual layer hides old vein block")
	_expect_equal(legacy_pocket.color.a <= 0.002 and not legacy_pocket.visible, true, "crystal visual layer hides old salvage block")
	_expect_equal(route_band.color.a <= 0.001 and not route_band.visible, true, "crystal visual layer hides old route block")
	_expect_equal(departure_label.visible, false, "crystal visual layer hides static departure label over the crystal view")
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
	if not world.quest_state.completed_quest_ids.has("quest.restore_outpost"):
		world.quest_state.completed_quest_ids.append("quest.restore_outpost")
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


func _has_update_target(updates: Array, quest_id: String, target_id: String) -> bool:
	for update in updates:
		if not update is Dictionary:
			continue
		if String(update.get("quest_id", "")) == quest_id and String(update.get("target_id", "")) == target_id:
			return true
	return false


func _expect_text_contains(text: String, expected: String, context: String) -> void:
	if text.find(expected) >= 0:
		return
	failures.append("%s: expected text to contain '%s', got '%s'" % [context, expected, text])


func _cleanup() -> void:
	data_registry.free()
