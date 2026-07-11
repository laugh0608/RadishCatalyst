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
	_check_first_minute_runtime_visual_constraints()
	_check_playable_scene_rebuild_layer()
	_check_base_first_screen_scene_layer()
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
	var base_handoff_layer := map.get_node("DemoBaseHandoffAssetArtPass") as DemoBaseHandoffAssetArtPass
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
	_expect_equal(first_path_layer.has_path_shape("first_path.base_handoff_compact_lane"), true, "first industrial path layer compacts the base handoff lane")
	_expect_equal(first_path_layer.has_path_shape("first_path.field_workspots_hidden_during_base_handoff"), true, "first industrial path layer hides field workspots during base handoff")
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
	_expect_equal(first_path_layer.has_path_shape("first_path.assetized_base_handoff_device_group"), true, "first industrial path layer reuses assetized base handoff devices")
	_expect_equal(first_path_layer.has_path_shape("first_path.assetized_receiving_dock"), true, "first industrial path layer draws an assetized receiving dock")
	_expect_equal(first_path_layer.has_path_shape("first_path.assetized_reactor_module"), true, "first industrial path layer draws the reactor as a device asset")
	_expect_equal(first_path_layer.has_path_shape("first_path.assetized_storage_bank"), true, "first industrial path layer draws storage as a device asset")
	_expect_equal(first_path_layer.has_path_shape("first_path.assetized_outfitting_rack"), true, "first industrial path layer draws outfitting as a device asset")
	_expect_equal(first_path_layer.has_path_shape("first_path.assetized_handoff_ports"), true, "first industrial path layer draws local handoff ports")
	_expect_equal(first_path_layer.has_path_shape("first_path.short_material_flow_segments"), true, "first industrial path layer keeps material flow local and short")
	_expect_equal(first_path_layer.has_path_shape("first_path.storage_outfitting_handoff_feedback"), true, "first industrial path layer registers storage to outfitting handoff feedback")
	_expect_equal(first_path_layer.has_path_shape("first_path.handoff_continuity.return_manifest_panel"), true, "first industrial path layer registers returned material manifest feedback")
	_expect_equal(first_path_layer.has_path_shape("first_path.handoff_continuity.return_tray_body"), true, "first industrial path layer registers returned material tray body")
	_expect_equal(first_path_layer.has_path_shape("first_path.handoff_continuity.reactor_hopper_bridge"), true, "first industrial path layer registers receiving to reactor hopper continuity")
	_expect_equal(first_path_layer.has_path_shape("first_path.handoff_continuity.hopper_cradle"), true, "first industrial path layer registers reactor hopper cradle")
	_expect_equal(first_path_layer.has_path_shape("first_path.handoff_continuity.storage_supply_manifest"), true, "first industrial path layer registers storage to outfitting supply manifest")
	_expect_equal(first_path_layer.has_path_shape("first_path.handoff_continuity.single_storage_supply_manifest"), true, "first industrial path layer draws one storage supply manifest")
	_expect_equal(first_path_layer.has_path_shape("first_path.handoff_continuity.supply_tote_lane"), true, "first industrial path layer registers the supply tote lane")
	_expect_equal(first_path_layer.has_path_shape("first_path.handoff_continuity.outfitting_lock_clamps"), true, "first industrial path layer registers outfitting lock clamps")
	_expect_equal(first_path_layer.has_path_shape("default_path.asset_language.base.shared_service_floor"), true, "first industrial path uses shared service floor asset language")
	_expect_equal(first_path_layer.has_path_shape("default_path.asset_language.base.reused_pipe_bundle"), true, "first industrial path reuses pipe bundle asset language")
	_expect_equal(first_path_layer.has_path_shape("default_path.asset_language.base.role_port_tokens"), true, "first industrial path registers shared role port tokens")
	_expect_equal(first_path_layer.has_path_shape("default_path.asset_language.base.short_flow_packets"), true, "first industrial path registers short asset-language flow packets")
	_expect_equal(first_path_layer.has_path_shape("first_path.single_signal_stage"), true, "first industrial path layer uses one active stage signal")
	_expect_equal(first_path_layer.has_path_shape("first_path.operation_relation.compact_base_handoff_tracks"), true, "first path compacts relation tracks during base handoff")
	_expect_equal(first_path_layer.has_path_shape("first_path.operation_relation.long_field_tracks_deemphasized"), true, "first path deemphasizes long field tracks during base handoff")
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
	_expect_equal(first_path_crystal_boundary.color.a <= 0.003, true, "first industrial path layer lowers region boundary frames")
	_expect_equal(first_path_layer.is_first_path_visible_at(Vector2(-250.0, -48.0)), true, "first industrial path layer is visible at base start")
	_expect_equal(first_path_layer.is_first_path_visible_at(Vector2(112.0, -112.0)), false, "first industrial path layer steps back inside the crystal workface")
	_expect_equal(first_path_layer.should_use_compact_guidance_at(Vector2(112.0, -112.0)), true, "first industrial path still supports compact guidance in the crystal workface")
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
	_expect_equal(first_path_layer.has_path_state_shape("first_path.assetized_flow.receiving_packets.ready"), true, "first industrial path layer draws receiving material packets")
	_expect_equal(first_path_layer.has_path_state_shape("first_path.assetized_flow.reactor_feed_packets.ready"), true, "first industrial path layer draws reactor feed packets")
	_expect_equal(first_path_layer.has_path_state_shape("first_path.assetized_feedback.reactor_processing_glow.active"), true, "first industrial path layer draws reactor processing feedback")
	_expect_equal(first_path_layer.has_path_state_shape("first_path.handoff_continuity.return_manifest.loaded"), true, "first industrial path layer lights the returned material manifest")
	_expect_equal(first_path_layer.has_path_state_shape("first_path.handoff_continuity.return_tray.loaded"), true, "first industrial path layer loads the physical return tray")
	_expect_equal(first_path_layer.has_path_state_shape("first_path.handoff_continuity.reactor_hopper.armed"), true, "first industrial path layer arms the reactor hopper bridge")
	_expect_equal(first_path_layer.has_path_state_shape("first_path.handoff_continuity.reactor_hopper.processing"), true, "first industrial path layer keeps the hopper bridge active during processing")
	_expect_equal(first_path_layer.has_path_state_shape("first_path.handoff_continuity.hopper_cradle.processing"), true, "first industrial path layer marks the hopper cradle during processing")
	_expect_equal(first_path_layer.has_path_state_shape("first_path.stage.reactor_processing"), true, "first industrial path layer records reactor operation stage")
	base_handoff_layer.refresh_handoff_state(world, character)
	_expect_equal(base_handoff_layer.is_handoff_available(), true, "base handoff asset layer opens after outpost restoration")
	_expect_equal(base_handoff_layer.is_handoff_visible_at(Vector2(-250.0, -48.0)), true, "base handoff asset layer is visible in the base workface")
	_expect_equal(base_handoff_layer.get_handoff_asset_shape_count() >= 12, true, "base handoff asset layer registers dedicated workface shapes")
	_expect_equal(base_handoff_layer.has_handoff_asset_shape("base_handoff_asset.old_route_suppression"), true, "base handoff asset layer suppresses old route linework")
	_expect_equal(base_handoff_layer.has_handoff_asset_shape("base_handoff_asset.reactor_asset"), true, "base handoff asset layer makes the reactor an asset subject")
	_expect_equal(base_handoff_layer.has_handoff_asset_shape("base_handoff_asset.storage_asset"), true, "base handoff asset layer makes storage an asset subject")
	_expect_equal(base_handoff_layer.has_handoff_asset_shape("base_handoff_asset.outfitting_asset"), true, "base handoff asset layer makes outfitting an asset subject")
	_expect_equal(base_handoff_layer.has_handoff_asset_shape("base_handoff_asset.return_tray_subject"), true, "base handoff asset layer gives returned materials a tray subject")
	_expect_equal(base_handoff_layer.has_handoff_asset_shape("base_handoff_asset.reactor_hopper_subject"), true, "base handoff asset layer gives reactor feed a hopper subject")
	_expect_equal(base_handoff_layer.has_handoff_asset_shape("base_handoff_asset.storage_supply_subject"), true, "base handoff asset layer gives storage output a supply subject")
	_expect_equal(base_handoff_layer.has_handoff_asset_shape("base_handoff_asset.outfitting_latch_subject"), true, "base handoff asset layer gives outfitting receipt a latch subject")
	_expect_equal(base_handoff_layer.get_handoff_asset_count(), 5, "base handoff asset layer reuses five existing device and floor sprites")
	_expect_equal(base_handoff_layer.has_handoff_asset("base_handoff_asset.reactor_module"), true, "base handoff asset manifest includes reactor sprite")
	_expect_equal(base_handoff_layer.get_handoff_asset_role("base_handoff_asset.reactor_module"), "processing_device", "base handoff reactor asset has processing role")
	_expect_equal(base_handoff_layer.get_handoff_asset_render_mode("base_handoff_asset.storage_bank"), "sprite", "base handoff storage asset renders as sprite")
	_expect_equal(base_handoff_layer.is_handoff_asset_available("base_handoff_asset.outfitting_station"), true, "base handoff outfitting asset is loadable")
	_expect_equal(base_handoff_layer.get_handoff_state_shape_count() >= 8, true, "base handoff asset layer registers state shapes")
	_expect_equal(
		base_handoff_layer.get_active_stage(),
		DemoBaseHandoffAssetArtPass.STAGE_REACTOR_PROCESSING,
		"base handoff asset layer marks reactor processing as the current base handoff stage"
	)
	_expect_equal(base_handoff_layer.has_handoff_state_shape("base_handoff_asset.state.reactor_processing.ready"), true, "base handoff asset layer marks reactor processing feedback")
	_expect_equal(base_handoff_layer.has_handoff_state_shape("base_handoff_asset.return_tray.loaded"), true, "base handoff asset layer loads returned material tray")
	_expect_equal(base_handoff_layer.has_handoff_state_shape("base_handoff_asset.reactor_hopper.processing"), true, "base handoff asset layer keeps hopper active during processing")
	_expect_equal(base_handoff_layer.has_handoff_state_shape("base_handoff_asset.stage.reactor_processing"), true, "base handoff asset layer records reactor processing stage")
	_check_first_industrial_path_stage_changes(first_path_layer)
	map.free()


func _check_first_minute_runtime_visual_constraints() -> void:
	var world := _create_resource_chain_world("quest.scout_crystal_field")
	var opening_world := WorldState.create_default()
	var character := CharacterState.create_default()
	character.position = Vector2(-250.0, -48.0)

	var map := VerticalSliceMapScene.instantiate() as VerticalSliceMap
	root.add_child(map)
	var first_path_layer := map.get_node("DemoFirstIndustrialPathVisualLayer") as DemoFirstIndustrialPathVisualLayer
	var crystal_layer := map.get_node("DemoCrystalResourceVisualLayer") as DemoCrystalResourceVisualLayer
	var route_spine := map.get_node("MainRouteSpine") as ColorRect
	var opening_layer := map.get_node("OpeningSceneLayer") as Node2D
	var crystal_approach_node_paths := [
		"DemoPresentationFieldZones/CrystalApproachPipeWest",
		"DemoPresentationFieldZones/CrystalApproachPipeMid",
		"DemoPresentationFieldZones/CrystalApproachPipeEast",
		"DemoPresentationFieldZones/CrystalApproachSignalLightWest",
		"DemoPresentationFieldZones/CrystalApproachSignalLightMid",
		"DemoPresentationFieldZones/CrystalApproachCableSpoolWest",
		"DemoPresentationFieldZones/CrystalApproachSurveyCrate",
		"DemoPresentationFieldZones/CrystalApproachToolbox",
	]
	for node_path in crystal_approach_node_paths:
		_expect_equal(
			map.get_node_or_null(String(node_path)) is CanvasItem,
			true,
			"first-minute scene includes assetized crystal approach node %s" % String(node_path)
		)
	var approach_pipe := map.get_node_or_null("DemoPresentationFieldZones/CrystalApproachPipeMid") as CanvasItem
	var approach_light := map.get_node_or_null("DemoPresentationFieldZones/CrystalApproachSignalLightMid") as CanvasItem
	var approach_toolbox := map.get_node_or_null("DemoPresentationFieldZones/CrystalApproachToolbox") as CanvasItem
	if approach_pipe != null and approach_light != null and approach_toolbox != null:
		map.refresh_world_interactables(opening_world)
		_expect_equal(approach_pipe.visible, false, "first-minute crystal path stays hidden before outpost restoration")
		_expect_equal(approach_light.visible, false, "first-minute crystal signal light stays hidden before outpost restoration")
		_expect_equal(approach_toolbox.visible, false, "first-minute crystal toolbox stays hidden before outpost restoration")
		map.refresh_world_interactables(world)
		_expect_equal(approach_pipe.visible, true, "first-minute crystal path appears after outpost restoration")
		_expect_equal(approach_light.visible, true, "first-minute crystal signal light appears after outpost restoration")
		_expect_equal(approach_toolbox.visible, true, "first-minute crystal toolbox appears after outpost restoration")

	first_path_layer.refresh_path_state(world, character)
	_expect_equal(first_path_layer.visible, false, "legacy first industrial path stays disabled after its own refresh")
	map.first_minute_baseline.disable_legacy_presentation_nodes(map)
	_expect_equal(first_path_layer.visible, false, "first-minute baseline suppresses refreshed first industrial path overlay")
	_expect_equal(first_path_layer.is_processing(), false, "first-minute baseline keeps first industrial path processing disabled")
	_expect_equal(route_spine.visible, false, "first-minute baseline suppresses refreshed global route spine")
	_expect_equal(opening_layer.visible, false, "first-minute baseline suppresses refreshed opening planning layer")

	character.position = Vector2(112.0, -112.0)
	crystal_layer.refresh_focus_visibility(character.position)
	_expect_equal(crystal_layer.visible, true, "legacy crystal resource layer can still be enabled by its own refresh")
	map.first_minute_baseline.disable_legacy_presentation_nodes(map)
	_expect_equal(crystal_layer.visible, false, "first-minute baseline suppresses refreshed crystal resource overlay")
	_expect_equal(crystal_layer.is_processing(), false, "first-minute baseline keeps crystal resource layer processing disabled")
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
	_expect_equal(first_path_layer.has_path_shape("first_path.assetized_base_handoff_device_group"), true, "first path gives the base handoff segment assetized devices")
	_expect_equal(first_path_layer.has_path_shape("first_path.assetized_handoff_ports"), true, "first path uses device ports instead of long route arrows")
	_expect_equal(first_path_layer.has_path_shape("first_path.short_material_flow_segments"), true, "first path expresses handoff with short material flows")
	map.free()


func _check_playable_scene_rebuild_layer() -> void:
	var world := _create_resource_chain_world("quest.prepare_treatment_supplies")
	world.add_base_structure("structure.basic_storage", "building.basic_storage", "region.outpost_platform")
	world.add_base_structure("structure.field_outfitting_station", "building.field_outfitting_station", "region.outpost_platform")
	var character := CharacterState.create_default()
	character.position = Vector2(-250.0, -48.0)

	var map := VerticalSliceMapScene.instantiate() as VerticalSliceMap
	root.add_child(map)
	var playable_scene_layer := map.get_node("DemoPlayableSceneRebuildLayer") as DemoPlayableSceneRebuildLayer
	var startup_layer := map.get_node("DemoBaseStartupPresentationLayer") as DemoBaseStartupPresentationLayer
	playable_scene_layer.refresh_scene_state(world, character)

	_expect_equal(playable_scene_layer.get_scene_asset_count(), 9, "playable scene rebuild layer registers nine real scene sprites")
	_expect_equal(playable_scene_layer.get_scene_sprite_node_count(), 9, "playable scene rebuild layer builds sprite nodes instead of debug rectangles")
	_expect_equal(playable_scene_layer.has_scene_asset("playable_scene.terrain_floor"), true, "playable scene rebuild layer includes a walkable floor sprite")
	_expect_equal(
		playable_scene_layer.get_scene_asset_path("playable_scene.terrain_floor"),
		"res://assets/sprites/demo_first_screen/playable_scene_compact_floor.svg",
		"playable scene rebuild layer uses a compact floor sprite instead of the old fullscreen platform overlay"
	)
	_expect_equal(playable_scene_layer.get_scene_asset_role("playable_scene.terrain_floor"), "compact_walkable_floor", "playable scene rebuild layer gives the floor a compact walkable role")
	_expect_equal(playable_scene_layer.has_scene_asset("playable_scene.outpost_core_machine"), true, "playable scene rebuild layer makes the damaged outpost core the subject")
	_expect_equal(playable_scene_layer.has_scene_asset("playable_scene.basic_reactor_module"), true, "playable scene rebuild layer includes the reactor as a scene object")
	_expect_equal(playable_scene_layer.has_scene_asset("playable_scene.crystal_ecology_cluster"), true, "playable scene rebuild layer includes resource ecology at the edge")
	_expect_equal(playable_scene_layer.has_scene_asset("playable_scene.pollution_edge_pool"), true, "playable scene rebuild layer includes hazard ecology at the edge")
	_expect_equal(playable_scene_layer.get_scene_asset_role("playable_scene.outpost_core_machine"), "first_objective_subject", "playable scene rebuild layer gives the core a first-objective role")
	_expect_equal(playable_scene_layer.get_scene_asset_render_mode("playable_scene.terrain_floor"), "sprite", "playable scene rebuild floor renders as a sprite")
	_expect_equal(playable_scene_layer.is_scene_asset_available("playable_scene.player_repair_pose"), true, "playable scene rebuild player action sprite is loadable")
	_expect_equal(playable_scene_layer.get_scene_shape_count() >= 10, true, "playable scene rebuild layer registers scene composition shapes")
	_expect_equal(playable_scene_layer.has_scene_shape("playable_scene.old_planning_layers_muted"), true, "playable scene rebuild layer explicitly demotes old planning layers")
	_expect_equal(playable_scene_layer.has_scene_shape("playable_scene.startup_presentation_suppressed"), true, "playable scene rebuild layer suppresses the old startup presentation layer")
	_expect_equal(playable_scene_layer.has_scene_shape("playable_scene.compact_floor_not_fullscreen_overlay"), true, "playable scene rebuild layer records that the floor is no longer a fullscreen overlay")
	_expect_equal(playable_scene_layer.has_scene_shape("playable_scene.no_fullscreen_backdrop"), true, "playable scene rebuild layer removes the fullscreen backdrop board")
	_expect_equal(playable_scene_layer.has_scene_shape("playable_scene.floor_islands_not_planning_grid"), true, "playable scene rebuild layer uses floor islands instead of a planning grid")
	_expect_equal(playable_scene_layer.has_scene_shape("playable_scene.floor_edges_matte_not_ui_frames"), true, "playable scene rebuild layer keeps floor edges matte instead of UI-framed")
	_expect_equal(playable_scene_layer.has_scene_shape("playable_scene.far_core_station_excluded"), true, "playable scene rebuild layer records far core station exclusion")
	_expect_equal(playable_scene_layer.has_scene_state_shape("playable_scene.state.outpost.restored"), true, "playable scene rebuild layer follows restored outpost state")
	_expect_equal(playable_scene_layer.has_scene_state_shape("playable_scene.state.devices.online"), true, "playable scene rebuild layer follows device availability state")
	_expect_equal(playable_scene_layer.is_scene_active_at(Vector2(-250.0, -48.0)), true, "playable scene rebuild layer is active at the first playable base screen")
	_expect_equal(playable_scene_layer.visible, true, "playable scene rebuild layer is visible at the base start")
	_expect_equal(playable_scene_layer.get_muted_planning_layer_count() >= 10, true, "playable scene rebuild layer pushes old visual overlays behind the scene")
	_expect_equal(playable_scene_layer.get_muted_context_rect_count() >= 8, true, "playable scene rebuild layer suppresses old color-block planning context")
	_expect_equal(startup_layer.modulate.a <= 0.001, true, "playable scene rebuild layer hides the old startup presentation stack in the same first screen")
	_expect_equal(playable_scene_layer.is_scene_active_at(Vector2(3744.0, 112.0)), false, "playable scene rebuild layer does not cover the far core station")
	playable_scene_layer.refresh_focus_visibility(Vector2(3744.0, 112.0))
	_expect_equal(playable_scene_layer.visible, false, "playable scene rebuild layer hides outside the first playable scene")
	_expect_equal(playable_scene_layer.get_muted_planning_layer_count(), 0, "playable scene rebuild layer restores planning overlays outside its scope")
	_expect_equal(playable_scene_layer.get_muted_context_rect_count(), 0, "playable scene rebuild layer restores color-block context outside its scope")
	_expect_equal(startup_layer.modulate.a >= 0.999, true, "playable scene rebuild layer restores the startup presentation stack outside its scope")
	map.free()


func _check_base_first_screen_scene_layer() -> void:
	var world := WorldState.create_default()
	var character := CharacterState.create_default()
	character.position = Vector2(-250.0, -48.0)

	var map := VerticalSliceMapScene.instantiate() as VerticalSliceMap
	root.add_child(map)
	map.setup(data_registry)
	map.player.position = character.position
	map.refresh_world_interactables(world)
	var scene_layer := map.get_node("DemoBaseFirstScreenSceneLayer") as DemoBaseFirstScreenSceneLayer
	var playable_scene_layer := map.get_node("DemoPlayableSceneRebuildLayer") as DemoPlayableSceneRebuildLayer
	var startup_layer := map.get_node("DemoBaseStartupPresentationLayer") as DemoBaseStartupPresentationLayer
	var player := map.get_node("Player") as PlayerController
	var guidance := map.get_node("CurrentObjectiveGuidanceLayer") as CurrentObjectiveGuidanceLayer
	var outpost_core := map.get_node("Interactables/OutpostCore") as PrototypeInteractable
	var reactor := map.get_node("Interactables/BasicReactor") as PrototypeInteractable
	var storage := map.get_node("Interactables/BasicStorageBuildSite") as PrototypeInteractable
	var outfitting := map.get_node("Interactables/FieldOutfittingStationBuildSite") as PrototypeInteractable

	scene_layer.refresh_scene_state(world, character)
	map.update_current_interactable()

	_expect_equal(scene_layer != null, true, "base first screen scene layer exists")
	_expect_equal(scene_layer.visible, true, "base first screen scene layer is visible at the default new-game spawn")
	_expect_equal(scene_layer.is_scene_active_at(Vector2(-250.0, -48.0)), true, "base first screen scene layer covers the playable first screen")
	_expect_equal(scene_layer.get_scene_shape_count() >= 15, true, "base first screen scene layer registers V2 composition shapes")
	_expect_equal(scene_layer.has_scene_shape("base_first_screen_scene.independent_scene_layer"), true, "base first screen scene layer is an independent scene carrier")
	_expect_equal(scene_layer.has_scene_shape("base_first_screen_scene.authored_scene_assets"), true, "base first screen scene uses authored assets instead of a full concept image")
	_expect_equal(scene_layer.has_scene_shape("base_first_screen_scene.generated_scene_textures"), true, "base first screen scene uses generated scene textures instead of a screenshot")
	_expect_equal(scene_layer.has_scene_shape("base_first_screen_scene.raster_sprite_pack"), true, "base first screen scene uses raster sprites as the main visual medium")
	_expect_equal(scene_layer.has_scene_shape("base_first_screen_scene.outpost_region_scoped"), true, "base first screen scene is scoped to the outpost region")
	_expect_equal(scene_layer.has_scene_shape("base_first_screen_scene.crystal_region_suppressed"), true, "base first screen scene suppresses itself in crystal region context")
	_expect_equal(scene_layer.has_scene_shape("base_first_screen_scene.rocky_ground_material"), true, "base first screen scene reads as rocky alien ground")
	_expect_equal(scene_layer.has_scene_shape("base_first_screen_scene.foundation_pad_asset"), true, "base first screen scene gives devices generated foundation pads")
	_expect_equal(scene_layer.has_scene_shape("base_first_screen_scene.cliff_edge_asset"), true, "base first screen scene uses a generated cliff edge asset")
	_expect_equal(scene_layer.has_scene_shape("base_first_screen_scene.pipe_network_asset"), true, "base first screen scene includes a pipe network asset")
	_expect_equal(scene_layer.has_scene_shape("base_first_screen_scene.pollution_seep_asset"), true, "base first screen scene includes a generated pollution seep asset")
	_expect_equal(scene_layer.has_scene_shape("base_first_screen_scene.pollution_edge_context"), true, "base first screen scene includes pollution edge context")
	_expect_equal(scene_layer.has_scene_shape("base_first_screen_scene.solid_floor_mass"), true, "base first screen scene uses solid floor mass")
	_expect_equal(scene_layer.has_scene_shape("base_first_screen_scene.platform_edge_boundaries"), true, "base first screen scene has platform boundaries")
	_expect_equal(scene_layer.has_scene_shape("base_first_screen_scene.low_profile_boundaries"), true, "base first screen scene keeps boundaries low profile")
	_expect_equal(scene_layer.has_scene_shape("base_first_screen_scene.segmented_wall_edges"), true, "base first screen scene breaks wall edges into short segments")
	_expect_equal(scene_layer.has_scene_shape("base_first_screen_scene.outpost_core_volume"), true, "base first screen scene gives the core a solid volume")
	_expect_equal(scene_layer.has_scene_shape("base_first_screen_scene.reactor_volume"), true, "base first screen scene gives the reactor a solid volume")
	_expect_equal(scene_layer.has_scene_shape("base_first_screen_scene.storage_volume"), true, "base first screen scene gives storage a solid volume")
	_expect_equal(scene_layer.has_scene_shape("base_first_screen_scene.outfitting_volume"), true, "base first screen scene gives outfitting a solid volume")
	_expect_equal(scene_layer.has_scene_shape("base_first_screen_scene.device_silhouette_language"), true, "base first screen scene adds device-specific silhouette language")
	_expect_equal(scene_layer.has_scene_shape("base_first_screen_scene.right_crystal_edge_context"), true, "base first screen scene keeps crystal context to the right edge")
	_expect_equal(scene_layer.has_scene_shape("base_first_screen_scene.right_crystal_edge_deemphasized"), true, "base first screen scene keeps right crystal edge secondary")
	_expect_equal(scene_layer.has_scene_shape("base_first_screen_scene.old_rebuild_layer_deemphasized"), true, "base first screen scene demotes the old rebuild layer")
	_expect_equal(scene_layer.has_scene_shape("base_first_screen_scene.core_focus_compact"), true, "base first screen scene compacts the core focus readout")
	_expect_equal(scene_layer.has_scene_shape("base_first_screen_scene.existing_interactions_preserved"), true, "base first screen scene records that interactions stay on existing objects")
	_expect_equal(scene_layer.get_scene_asset_count() >= 8, true, "base first screen scene registers visual scene assets")
	_expect_equal(scene_layer.get_scene_sprite_node_count() >= 8, true, "base first screen scene instantiates visual scene sprites")
	_expect_equal(scene_layer.has_scene_asset("base_first_screen_scene.asset.rocky_ground"), true, "base first screen scene has a generated rocky ground asset")
	_expect_equal(scene_layer.get_scene_asset_path("base_first_screen_scene.asset.rocky_ground"), "res://assets/sprites/demo_first_screen/base_first_screen_rocky_ground.png", "base first screen rocky ground raster path is registered")
	_expect_equal(scene_layer.has_scene_asset("base_first_screen_scene.asset.foundation_pads"), true, "base first screen scene has generated foundation pad assets")
	_expect_equal(scene_layer.get_scene_asset_path("base_first_screen_scene.asset.foundation_pads").ends_with(".png"), true, "base first screen foundation pads use raster art")
	_expect_equal(scene_layer.has_scene_asset("base_first_screen_scene.asset.pipe_network"), true, "base first screen scene has a generated pipe network asset")
	_expect_equal(scene_layer.get_scene_asset_path("base_first_screen_scene.asset.pipe_network").ends_with(".png"), true, "base first screen pipe network uses raster art")
	_expect_equal(scene_layer.get_scene_part_count() >= 30, true, "base first screen scene builds many solid parts instead of one overlay board")
	_expect_equal(scene_layer.get_device_volume_count(), 4, "base first screen scene has four key device volumes")
	_expect_equal(scene_layer.get_device_silhouette_part_count() >= 10, true, "base first screen scene has device-specific silhouette parts")
	_expect_equal(scene_layer.get_material_block_count() >= 8, true, "base first screen scene separates material blocks across floor and devices")
	_expect_equal(scene_layer.get_service_port_count(), 4, "base first screen scene exposes short service ports")
	_expect_equal(scene_layer.has_scene_part("base_first_screen_scene.part.floor_mass"), true, "base first screen scene has a floor mass part")
	_expect_equal(scene_layer.get_scene_part_role("base_first_screen_scene.part.floor_mass"), "solid_floor", "base first screen floor part is a solid floor")
	_expect_equal(scene_layer.has_scene_part("base_first_screen_scene.part.outpost_core_hull"), true, "base first screen scene has core hull part")
	_expect_equal(scene_layer.get_scene_part_role("base_first_screen_scene.part.basic_reactor_body"), "solid_device_volume", "base first screen reactor reads as a device volume")
	_expect_equal(scene_layer.get_scene_part_role("base_first_screen_scene.part.right_crystal_spire_a"), "right_crystal_edge_context", "base first screen crystal spire is only edge context")
	_expect_equal(scene_layer.has_scene_state_shape("base_first_screen_scene.state.outpost.damaged"), true, "base first screen scene follows damaged startup state")
	_expect_equal(scene_layer.has_scene_state_shape("base_first_screen_scene.state.devices.online"), true, "base first screen scene reflects the default reactor context")
	_expect_equal(scene_layer.get_muted_context_layer_count() >= 12, true, "base first screen scene suppresses old visual layers")
	_expect_equal(scene_layer.get_muted_context_rect_count() >= 8, true, "base first screen scene suppresses old region color blocks")
	_expect_equal(playable_scene_layer.modulate.a <= 0.001, true, "base first screen scene hides the old playable rebuild stack in its first-screen scope")
	_expect_equal(startup_layer.modulate.a <= 0.001, true, "base first screen scene hides the old startup presentation stack in its first-screen scope")
	_expect_equal(guidance.modulate.a <= 0.181, true, "base first screen scene lowers the current objective overlay")
	_expect_equal(scene_layer.z_index < player.z_index, true, "base first screen scene stays below the playable actor")
	_expect_equal(outpost_core.definition_id, "building.outpost_core", "base first screen keeps the existing outpost core interactable")
	_expect_equal(reactor.definition_id, "building.basic_reactor", "base first screen keeps the existing reactor interactable")
	_expect_equal(storage.definition_id, "building.basic_storage", "base first screen keeps the existing storage interactable")
	_expect_equal(outfitting.definition_id, "building.field_outfitting_station", "base first screen keeps the existing outfitting interactable")
	_expect_equal(map.current_interactable, outpost_core, "base first screen keeps the default first interaction on the outpost core")
	scene_layer.refresh_focus_visibility(character.position)
	_expect_equal(outpost_core.label.visible, false, "base first screen hides the core scene label near the player")
	_expect_equal(outpost_core.focus_ring.modulate.a <= 0.281, true, "base first screen lowers the core focus ring")
	_expect_equal(outpost_core.marker.modulate.a <= 0.581, true, "base first screen lowers the core marker")

	world.quest_state.complete_quest("quest.restore_outpost")
	world.add_base_structure("structure.basic_storage", "building.basic_storage", "region.outpost_platform")
	world.add_base_structure("structure.field_outfitting_station", "building.field_outfitting_station", "region.outpost_platform")
	scene_layer.refresh_scene_state(world, character)
	_expect_equal(scene_layer.has_scene_state_shape("base_first_screen_scene.state.outpost.restored"), true, "base first screen scene follows restored outpost state")
	_expect_equal(scene_layer.has_scene_state_shape("base_first_screen_scene.state.devices.online"), true, "base first screen scene follows online base device state")

	world.current_region_id = "region.crystal_vein_field"
	character.current_region_id = "region.crystal_vein_field"
	character.position = Vector2(86.0, -118.0)
	scene_layer.refresh_scene_state(world, character)
	_expect_equal(scene_layer.is_scene_context_active(), false, "base first screen scene disables itself after entering the crystal region")
	_expect_equal(scene_layer.visible, false, "base first screen scene does not cover the crystal workface")

	scene_layer.refresh_focus_visibility(Vector2(3744.0, 112.0))
	_expect_equal(scene_layer.visible, false, "base first screen scene does not cover the far core station")
	_expect_equal(scene_layer.get_muted_context_layer_count(), 0, "base first screen scene restores old layers outside first-screen scope")
	_expect_equal(scene_layer.get_muted_context_rect_count(), 0, "base first screen scene restores old region context outside first-screen scope")
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
	_expect_equal(build_site.visible, false, "crystal collector build site waits until the first crystal scout is complete")
	_expect_equal(output.visible, false, "crystal collector output waits for built collector")
	world.quest_state.complete_quest("quest.scout_crystal_field")
	map.refresh_world_interactables(world)
	_expect_equal(build_site.visible, true, "crystal collector build site appears after the first crystal scout")

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
	var crystal_layer := map.get_node("DemoCrystalResourceVisualLayer") as DemoCrystalResourceVisualLayer
	var base_handoff_layer := map.get_node("DemoBaseHandoffAssetArtPass") as DemoBaseHandoffAssetArtPass
	first_path_layer.apply_visuals()

	var collector_result := builder.create_visual_review_checkpoint_state("visual_review.crystal_collector_output")
	_expect_equal(bool(collector_result.get("success", false)), true, "collector output visual checkpoint builds")
	if bool(collector_result.get("success", false)):
		var collector_character_state := collector_result["character_state"] as CharacterState
		first_path_layer.refresh_path_state(collector_result["world_state"], collector_character_state)
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
		first_path_layer.refresh_focus_visibility(collector_character_state.position)
		crystal_layer.refresh_focus_visibility(collector_character_state.position)
		_expect_equal(
			first_path_layer.visible,
			false,
			"collector output checkpoint keeps the full first industrial path out of the crystal workface"
		)
		_expect_equal(
			first_path_layer.should_use_compact_guidance_at(collector_character_state.position),
			true,
			"collector output checkpoint still allows compact objective guidance"
		)
		_expect_equal(
			crystal_layer.get_muted_crystal_focus_context_marker_count() >= 10,
			true,
			"crystal resource checkpoint suppresses non-local interactable markers"
		)

	var handoff_result := builder.create_visual_review_checkpoint_state("visual_review.base_handoff")
	_expect_equal(bool(handoff_result.get("success", false)), true, "base handoff visual checkpoint builds")
	if bool(handoff_result.get("success", false)):
		first_path_layer.refresh_path_state(handoff_result["world_state"], handoff_result["character_state"])
		base_handoff_layer.refresh_handoff_state(handoff_result["world_state"], handoff_result["character_state"])
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
		_expect_equal(
			first_path_layer.has_path_state_shape("first_path.assetized_flow.storage_output_packets.ready"),
			true,
			"base handoff visual checkpoint marks assetized storage output packets"
		)
		_expect_equal(
			first_path_layer.has_path_state_shape("first_path.assetized_feedback.outfitting_handoff.ready"),
			true,
			"base handoff visual checkpoint marks outfitting handoff feedback"
		)
		_expect_equal(
			first_path_layer.has_path_state_shape("first_path.handoff_continuity.storage_supply_manifest.ready"),
			true,
			"base handoff visual checkpoint marks storage supply manifest ready"
		)
		_expect_equal(
			first_path_layer.has_path_state_shape("first_path.handoff_continuity.supply_tote_lane.ready"),
			true,
			"base handoff visual checkpoint marks storage supply totes ready"
		)
		_expect_equal(
			first_path_layer.has_path_state_shape("first_path.handoff_continuity.outfitting_supply.latched"),
			true,
			"base handoff visual checkpoint latches storage output into outfitting"
		)
		_expect_equal(
			first_path_layer.has_path_state_shape("first_path.handoff_continuity.outfitting_lock_clamps.latched"),
			true,
			"base handoff visual checkpoint locks outfitting clamps around received supply"
		)
		_expect_equal(
			base_handoff_layer.get_active_stage(),
			DemoBaseHandoffAssetArtPass.STAGE_OUTFITTING_READY,
			"base handoff asset checkpoint lands on outfitting handoff stage"
		)
		_expect_equal(
			base_handoff_layer.has_handoff_state_shape("base_handoff_asset.storage_supply.ready"),
			true,
			"base handoff asset checkpoint marks storage supply subject ready"
		)
		_expect_equal(
			base_handoff_layer.has_handoff_state_shape("base_handoff_asset.outfitting_latch.locked"),
			true,
			"base handoff asset checkpoint locks the outfitting receipt subject"
		)
		_expect_equal(
			base_handoff_layer.has_handoff_state_shape("base_handoff_asset.short_stage_packets.ready"),
			true,
			"base handoff asset checkpoint uses short material packets inside the workface"
		)
		_expect_equal(
			base_handoff_layer.visible,
			true,
			"base handoff asset checkpoint keeps the dedicated device workface visible"
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
	_expect_equal(layer.get_workface_asset_count() >= 4, true, "crystal workface registers dedicated sprite assets")
	_expect_equal(layer.has_workface_asset("crystal_workface_asset.workface_floor"), true, "crystal workface has an assetized local floor sprite")
	_expect_equal(layer.has_workface_asset("crystal_workface_asset.current_vein"), true, "crystal workface has an assetized current vein sprite")
	_expect_equal(layer.has_workface_asset("crystal_workface_asset.collector_machine"), true, "crystal workface has an assetized collector machine sprite")
	_expect_equal(layer.has_workface_asset("crystal_workface_asset.output_tray_loaded"), true, "crystal workface has an assetized loaded output tray sprite")
	_expect_equal(layer.is_workface_asset_available("crystal_workface_asset.workface_floor"), true, "crystal workface floor asset is loadable")
	_expect_equal(layer.is_workface_asset_available("crystal_workface_asset.current_vein"), true, "crystal current vein asset is loadable")
	_expect_equal(layer.is_workface_asset_available("crystal_workface_asset.collector_machine"), true, "crystal collector machine asset is loadable")
	_expect_equal(layer.is_workface_asset_available("crystal_workface_asset.output_tray_loaded"), true, "crystal output tray asset is loadable")
	_expect_equal(
		layer.get_workface_asset_path("crystal_workface_asset.current_vein").begins_with("res://assets/sprites/demo_crystal_workface/"),
		true,
		"crystal workface assets use the dedicated crystal workface sprite directory"
	)
	_expect_equal(layer.get_workface_asset_role("crystal_workface_asset.current_vein"), "harvestable_resource", "crystal current vein asset has a harvestable resource role")
	_expect_equal(layer.get_workface_asset_role("crystal_workface_asset.collector_machine"), "collector_device", "crystal collector machine asset has a collector device role")
	_expect_equal(layer.get_workface_asset_role("crystal_workface_asset.output_tray_loaded"), "pickup_output", "crystal output tray asset has a pickup output role")
	_expect_equal(layer.get_workface_asset_render_mode("crystal_workface_asset.output_tray_loaded"), "sprite", "crystal output tray renders as a sprite")
	layer.refresh_focus_visibility(Vector2(-250, -48))
	_expect_equal(layer.visible, false, "crystal visual layer stays hidden at startup objective")
	layer.refresh_focus_visibility(Vector2(-38, -104))
	var crystal_focus_route := map.get_node("MainRouteSpine") as ColorRect
	var crystal_focus_boundary := map.get_node("RegionBoundaryPollution") as ColorRect
	var crystal_focus_depth_layer := map.get_node("DemoSceneFocusDepthLayer") as CanvasItem
	var crystal_focus_region_value_layer := map.get_node("DemoRegionIndustrialValueLayer") as CanvasItem
	_expect_equal(layer.visible, true, "crystal visual layer appears when player reaches field departure")
	_expect_equal(layer.get_muted_departure_focus_count() >= 1, true, "crystal visual layer suppresses departure gate focus label in field view")
	_expect_equal(layer.get_muted_crystal_focus_context_layer_count() >= 11, true, "crystal visual layer mutes neighboring visual context layers")
	_expect_equal(layer.get_muted_crystal_focus_context_rect_count() >= 10, true, "crystal visual layer suppresses cross-region route rectangles")
	_expect_equal(layer.get_muted_crystal_focus_context_marker_count() >= 10, true, "crystal visual layer suppresses non-local interactable markers")
	_expect_equal(layer.get_shaped_local_focus_marker_count() >= 4, true, "crystal visual layer reshapes local focus markers into secondary cues")
	_expect_equal(crystal_focus_route.color.a <= 0.001, true, "crystal visual layer lowers the global route spine")
	_expect_equal(crystal_focus_boundary.color.a <= 0.003, true, "crystal visual layer lowers neighboring region boundary frames")
	_expect_equal(crystal_focus_depth_layer.modulate.a <= 0.007, true, "crystal visual layer lowers scene depth frames")
	_expect_equal(crystal_focus_region_value_layer.modulate.a <= 0.005, true, "crystal visual layer lowers region value blocks")
	var output_interactable := map.get_node("Interactables/CrystalCollectorOutput") as PrototypeInteractable
	output_interactable.set_focus_visual(true)
	layer.refresh_focus_visibility(output_interactable.position)
	var output_focus_ring := output_interactable.get_node_or_null("FocusRing") as ColorRect
	var output_label := output_interactable.get_node_or_null("Label") as Label
	_expect_equal(output_focus_ring != null and output_focus_ring.color.a <= DemoCrystalResourceVisualLayer.CRYSTAL_FOCUS_LOCAL_RING_ALPHA + 0.001, true, "crystal visual layer keeps local focus ring from becoming the subject")
	_expect_equal(layer.get_repositioned_output_label_count() >= 1, true, "crystal visual layer repositions the output tray label away from the device body")
	_expect_equal(output_label != null and output_label.offset_top >= 28.0, true, "crystal output tray label sits below the pickup tray")
	_expect_equal(output_label != null and output_label.modulate.a <= DemoCrystalResourceVisualLayer.CRYSTAL_FOCUS_PICKUP_LABEL_ALPHA + 0.001, true, "crystal output tray label is a secondary confirmation cue")
	layer.refresh_focus_visibility(Vector2(168, 34))
	_expect_equal(layer.visible, false, "crystal visual layer steps back after entering pollution treatment boundary")
	_expect_equal(layer.has_resource_shape("crystal.main_vein"), true, "crystal visual layer marks main vein")
	_expect_equal(layer.has_resource_shape("crystal.rich_vein"), true, "crystal visual layer marks rich vein")
	_expect_equal(layer.has_resource_shape("crystal.current_mining_vein.subject"), true, "crystal visual layer makes the current vein the foreground subject")
	_expect_equal(layer.has_resource_shape("crystal.local_focus_marker_deemphasized"), true, "crystal visual layer keeps local labels and focus markers subordinate")
	_expect_equal(layer.has_resource_shape("crystal.hand_sample_probe"), true, "crystal visual layer marks player hand sampling")
	_expect_equal(layer.has_resource_shape("crystal.auto_miner.primary"), true, "crystal visual layer marks the primary automatic miner")
	_expect_equal(layer.has_resource_shape("crystal.auto_miner.output_tray"), true, "crystal visual layer marks the miner output tray")
	_expect_equal(layer.has_resource_shape("crystal.current_collector_head.subject"), true, "crystal visual layer gives the current collector head foreground mass")
	_expect_equal(layer.has_resource_shape("crystal.current_output_tray.subject"), true, "crystal visual layer makes the real collector output tray a subject")
	_expect_equal(layer.has_resource_shape("crystal.workface.asset.current_vein_sprite"), true, "crystal visual layer draws the current vein as a sprite subject")
	_expect_equal(layer.has_resource_shape("crystal.workface.asset.collector_machine_sprite"), true, "crystal visual layer draws the collector machine as a sprite subject")
	_expect_equal(layer.has_resource_shape("crystal.workface.asset.output_tray_sprite"), true, "crystal visual layer draws the output tray as a sprite subject")
	_expect_equal(layer.has_resource_shape("crystal.workface.asset.enlarged_output_tray_subject"), true, "crystal visual layer enlarges the output tray as the pickup subject")
	_expect_equal(layer.has_resource_shape("salvage.south_pocket"), true, "crystal visual layer marks salvage pocket")
	_expect_equal(layer.has_flow_shape("flow.crystal_to_base"), true, "crystal visual layer marks return flow")
	_expect_equal(layer.has_flow_shape("flow.auto_miner_to_loading_tray"), true, "crystal visual layer marks miner output flow")
	_expect_equal(layer.has_flow_shape("flow.current_vein_to_output_tray.short_subject"), true, "crystal visual layer keeps current vein to tray flow short and local")
	_expect_equal(layer.has_flow_shape("flow.current_collector_pickup.loop_subject"), true, "crystal visual layer marks the local collector pickup loop")
	_expect_equal(layer.has_flow_shape("flow.crystal_workface.asset.short_material_packets"), true, "crystal visual layer draws assetized short material packets")
	_expect_equal(layer.has_flow_shape("flow.crystal_workface.asset.tray_pickup_port"), true, "crystal visual layer draws an assetized tray pickup port")
	_expect_equal(layer.has_flow_shape("flow.crystal_workface.asset.pickup_ready_signal"), true, "crystal visual layer draws a pickup-ready signal below the output tray")
	_expect_equal(layer.has_terrain_material_shape("terrain.crystal.harvest_face"), true, "crystal visual layer marks harvestable mine face")
	_expect_equal(layer.has_terrain_material_shape("terrain.crystal.current_harvest_workface_subject"), true, "crystal visual layer gives the current harvest workface a foreground floor")
	_expect_equal(layer.has_terrain_material_shape("terrain.crystal.current_workface_noise_cutout"), true, "crystal visual layer cuts line noise directly behind the current workface")
	_expect_equal(layer.has_terrain_material_shape("terrain.crystal.current_machine_deck_subject"), true, "crystal visual layer turns current collector and tray into one machine deck")
	_expect_equal(layer.has_terrain_material_shape("terrain.crystal.current_workface_shadow_anchor"), true, "crystal visual layer anchors current crystal devices to local ground")
	_expect_equal(layer.has_terrain_material_shape("terrain.crystal.broken_mine_shadow_patches"), true, "crystal visual layer breaks the old blue ore field with irregular mine patches")
	_expect_equal(layer.has_terrain_material_shape("terrain.crystal.mine_cutout_baffles"), true, "crystal visual layer cuts dark baffles through the old blue ore field")
	_expect_equal(layer.has_terrain_material_shape("terrain.crystal.old_field_voids"), true, "crystal visual layer cuts old blue field into dark local voids")
	_expect_equal(layer.has_terrain_material_shape("terrain.crystal.non_current_crystal_backdrop_muted"), true, "crystal visual layer pushes non-current crystal linework behind the subject")
	_expect_equal(layer.has_terrain_material_shape("terrain.crystal.legacy_planning_frame_deemphasized"), true, "crystal visual layer de-emphasizes old planning rectangles inside the field")
	_expect_equal(layer.has_terrain_material_shape("terrain.crystal.mine_face_islands"), true, "crystal visual layer splits harvest face into mine islands")
	_expect_equal(layer.has_terrain_material_shape("terrain.crystal.dark_cut_channels"), true, "crystal visual layer cuts dark channels through old ore block")
	_expect_equal(layer.has_terrain_material_shape("terrain.crystal.fractured_ore_tiles"), true, "crystal visual layer breaks old ore block into fractured tiles")
	_expect_equal(layer.has_terrain_material_shape("terrain.crystal.local_harvest_work_pads"), true, "crystal visual layer marks local harvest work pads")
	_expect_equal(layer.has_terrain_material_shape("terrain.crystal.current_resource_foreground_anchors"), true, "crystal visual layer adds foreground anchors behind current resource objects")
	_expect_equal(layer.has_terrain_material_shape("terrain.crystal.rich_seam_ridges"), true, "crystal visual layer marks rich seam ridges")
	_expect_equal(layer.has_terrain_material_shape("terrain.crystal.mine_bench_steps"), true, "crystal visual layer marks cut bench steps")
	_expect_equal(layer.has_terrain_material_shape("terrain.crystal.scrap_recovery_yard"), true, "crystal visual layer marks salvage recovery yard")
	_expect_equal(layer.has_terrain_material_shape("terrain.crystal.salvage_sorting_lanes"), true, "crystal visual layer marks salvage sorting lanes")
	_expect_equal(layer.has_terrain_material_shape("terrain.crystal.return_cart_lane"), true, "crystal visual layer marks return cart lane")
	_expect_equal(layer.has_terrain_material_shape("terrain.crystal.loading_sleepers"), true, "crystal visual layer marks loading sleepers")
	_expect_equal(layer.has_terrain_material_shape("terrain.crystal.base_loading_mouth"), true, "crystal visual layer marks base loading mouth")
	_expect_equal(layer.has_terrain_material_shape("terrain.crystal.assetized_service_floor"), true, "crystal visual layer reuses the shared service floor language")
	_expect_equal(layer.has_terrain_material_shape("terrain.crystal.assetized_ecology_sprite"), true, "crystal visual layer uses assetized crystal ecology")
	_expect_equal(layer.has_terrain_material_shape("terrain.crystal.assetized_loading_pipe"), true, "crystal visual layer reuses pipe bundle language near loading")
	_expect_equal(layer.has_terrain_material_shape("terrain.crystal.current_workface_clarity_plate"), true, "crystal visual layer gives the current resource workface a readable local ground")
	_expect_equal(layer.has_terrain_material_shape("terrain.crystal.shared_role_port_tokens"), true, "crystal visual layer registers shared role port tokens")
	_expect_equal(layer.has_terrain_material_shape("terrain.crystal.player_harvest_action_feedback"), true, "crystal visual layer registers player harvest action feedback")
	_expect_equal(layer.has_terrain_material_shape("terrain.crystal.workface.asset.floor_sprite"), true, "crystal visual layer draws the workface floor as a sprite")
	_expect_equal(layer.has_terrain_material_shape("terrain.crystal.workface.asset.local_ground_shadow"), true, "crystal visual layer anchors workface sprites with local ground shadow")
	_expect_equal(layer.has_terrain_material_shape("terrain.crystal.workface.asset.legacy_geometry_backgrounded"), true, "crystal visual layer records legacy linework as background under workface sprites")
	_expect_equal(layer.has_terrain_material_shape("terrain.crystal.workface.asset.expanded_linework_suppression"), true, "crystal visual layer expands the local mask over legacy linework")
	_expect_equal(layer.has_terrain_material_shape("terrain.crystal.workface.asset.forward_pickup_tray"), true, "crystal visual layer places the pickup tray in the foreground")
	_expect_equal(layer.has_terrain_material_shape("terrain.crystal.workface.asset.sprite_manifest"), true, "crystal visual layer registers the workface sprite manifest")
	_expect_equal(DemoCrystalResourceVisualLayer.CRYSTAL_FOCUS_LOCAL_MARKER_DISTANCE <= 180.0, true, "crystal visual layer keeps local interactable markers tightly scoped")
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
