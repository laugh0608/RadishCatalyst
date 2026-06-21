extends RefCounted

const VerticalSliceMapScene := preload("res://scenes/maps/VerticalSliceMap.tscn")

var host


func _init(check_host) -> void:
	host = check_host


func run(root: Node) -> void:
	_check_side_route_layout(root)
	_check_side_route_gather_feedback()
	_check_side_route_guard_feedback(root)
	_check_return_route_layout_and_gate(root)
	_check_return_route_prompts_and_readiness()
	_check_return_route_guard_feedback(root)


func _check_side_route_layout(root: Node) -> void:
	var map := VerticalSliceMapScene.instantiate() as VerticalSliceMap
	root.add_child(map)
	map.setup(host.data_registry)
	var pocket := map.get_node("OpeningSceneLayer/CrystalLogisticsResourcePocket") as ColorRect
	var crystal_marker := map.get_node("OpeningSceneLayer/CrystalLogisticsCrystalMarker") as ColorRect
	var salvage_marker := map.get_node("OpeningSceneLayer/CrystalLogisticsSalvageMarker") as ColorRect
	var guard_marker := map.get_node("OpeningSceneLayer/CrystalLogisticsGuardMarker") as ColorRect
	var crystal := map.get_node("Interactables/CrystalClusterLogisticsPocket") as PrototypeInteractable
	var wreckage := map.get_node("Interactables/FieldWreckageLogisticsPocket") as PrototypeInteractable
	var guard := map.get_node("Enemies/NativeSkitterLogisticsGuard") as PrototypeEnemy
	host._expect_equal(
		crystal.position.x >= VerticalSliceMap.CRYSTAL_REGION_X
			and wreckage.position.x < VerticalSliceMap.POLLUTION_REGION_X
			and guard.position.x < VerticalSliceMap.POLLUTION_REGION_X,
		true,
		"crystal logistics side route stays inside the crystal field"
	)
	host._expect_equal(
		_is_rect_covering_position(pocket, crystal.position)
			and _is_rect_covering_position(pocket, wreckage.position)
			and _is_rect_covering_position(crystal_marker, crystal.position)
			and _is_rect_covering_position(salvage_marker, wreckage.position)
			and _is_rect_covering_position(guard_marker, guard.position),
		true,
		"crystal logistics side route scene markers align with playable objects"
	)
	host._expect_equal(
		guard.position.distance_to(crystal.position) <= VerticalSliceMap.ATTACK_RANGE
			and guard.position.distance_to(wreckage.position) <= VerticalSliceMap.ATTACK_RANGE,
		true,
		"crystal logistics side route ties extra resources to visible low-pressure combat"
	)
	map.free()


func _check_side_route_gather_feedback() -> void:
	var gather_system := GatherSystem.new(host.data_registry)
	var world := WorldState.create_default()
	var character := CharacterState.create_default()
	var crystal_result := gather_system.interact_with_object(
		"map_object_instance.crystal_cluster_logistics_pocket",
		"map_object.crystal_cluster",
		"gather",
		character,
		world
	)
	host._expect_equal(bool(crystal_result.get("success", false)), true, "crystal logistics pocket gather succeeds")
	host._expect_text_contains(
		String(crystal_result.get("message", "")),
		"维护校准过滤模块",
		"crystal logistics pocket points gathered ore back to outfitting calibration"
	)
	host._expect_equal(
		int(character.inventory.items.get("item.crystal_ore", 0)),
		3,
		"crystal logistics pocket grants crystal ore"
	)
	var wreckage_result := gather_system.interact_with_object(
		"map_object_instance.field_wreckage_logistics_pocket",
		"map_object.field_wreckage",
		"gather",
		character,
		world
	)
	host._expect_equal(bool(wreckage_result.get("success", false)), true, "field wreckage logistics pocket gather succeeds")
	host._expect_text_contains(
		String(wreckage_result.get("message", "")),
		"维护校准过滤模块",
		"field wreckage logistics pocket points scrap back to outfitting calibration"
	)
	host._expect_equal(
		int(character.inventory.items.get("item.salvage_scrap", 0)),
		2,
		"field wreckage logistics pocket grants salvage scrap"
	)


func _check_side_route_guard_feedback(root: Node) -> void:
	var map := VerticalSliceMapScene.instantiate() as VerticalSliceMap
	root.add_child(map)
	map.setup(host.data_registry)
	var world := WorldState.create_default()
	var character := CharacterState.create_default()
	var guard := map.get_node("Enemies/NativeSkitterLogisticsGuard") as PrototypeEnemy
	map.player.position = guard.position
	map.sync_enemy_states(world)
	map.try_attack(character, world)
	var defeated_result := map.try_attack(character, world)
	host._expect_equal(bool(defeated_result.get("enemy_defeated", false)), true, "crystal logistics guard can be defeated")
	host._expect_text_contains(
		String(defeated_result.get("message", "")),
		"晶体侧路暂时安全",
		"crystal logistics guard defeat points back to the side route"
	)
	host._expect_equal(
		bool(world.get_enemy("enemy_instance.native_skitter_logistics_guard").get("is_defeated", false)),
		true,
		"crystal logistics guard defeat is stored in world state"
	)
	host._expect_equal(
		world.has_enemy_drops_granted("enemy_instance.native_skitter_logistics_guard"),
		true,
		"crystal logistics guard drop grant is stored"
	)
	map.free()


func _check_return_route_layout_and_gate(root: Node) -> void:
	var blocked_map := VerticalSliceMapScene.instantiate() as VerticalSliceMap
	root.add_child(blocked_map)
	blocked_map.setup(host.data_registry)
	var character := CharacterState.create_default()
	blocked_map.apply_runtime_state(_create_crystal_logistics_return_world(false), character)
	var blocked_crystal := blocked_map.get_node("Interactables/CrystalClusterLogisticsReturn") as PrototypeInteractable
	var blocked_wreckage := blocked_map.get_node("Interactables/FieldWreckageLogisticsReturn") as PrototypeInteractable
	var blocked_guard := blocked_map.get_node("Enemies/NativeSkitterLogisticsReturnGuard") as PrototypeEnemy
	host._expect_equal(
		not blocked_crystal.visible
			and not blocked_crystal.monitoring
			and not blocked_wreckage.visible
			and not blocked_guard.visible,
		true,
		"crystal logistics return route stays hidden before core retest readout returns"
	)
	blocked_map.free()

	var ready_map := VerticalSliceMapScene.instantiate() as VerticalSliceMap
	root.add_child(ready_map)
	ready_map.setup(host.data_registry)
	ready_map.apply_runtime_state(_create_crystal_logistics_return_world(true), character)
	var pocket := ready_map.get_node("OpeningSceneLayer/CrystalLogisticsReturnPocket") as ColorRect
	var crystal_marker := ready_map.get_node("OpeningSceneLayer/CrystalLogisticsReturnCrystalMarker") as ColorRect
	var salvage_marker := ready_map.get_node("OpeningSceneLayer/CrystalLogisticsReturnSalvageMarker") as ColorRect
	var guard_marker := ready_map.get_node("OpeningSceneLayer/CrystalLogisticsReturnGuardMarker") as ColorRect
	var crystal := ready_map.get_node("Interactables/CrystalClusterLogisticsReturn") as PrototypeInteractable
	var wreckage := ready_map.get_node("Interactables/FieldWreckageLogisticsReturn") as PrototypeInteractable
	var guard := ready_map.get_node("Enemies/NativeSkitterLogisticsReturnGuard") as PrototypeEnemy
	host._expect_equal(
		crystal.visible
			and wreckage.visible
			and guard.visible
			and crystal.position.x >= VerticalSliceMap.CRYSTAL_REGION_X
			and wreckage.position.x < VerticalSliceMap.POLLUTION_REGION_X
			and guard.position.x < VerticalSliceMap.POLLUTION_REGION_X,
		true,
		"crystal logistics return route opens inside the existing crystal field"
	)
	host._expect_equal(
		_is_rect_covering_position(pocket, crystal.position)
			and _is_rect_covering_position(pocket, wreckage.position)
			and _is_rect_covering_position(crystal_marker, crystal.position)
			and _is_rect_covering_position(salvage_marker, wreckage.position)
			and _is_rect_covering_position(guard_marker, guard.position),
		true,
		"crystal logistics return route scene markers align with playable objects"
	)
	host._expect_equal(
		guard.position.distance_to(crystal.position) <= VerticalSliceMap.ATTACK_RANGE
			and guard.position.distance_to(wreckage.position) <= VerticalSliceMap.ATTACK_RANGE,
		true,
		"crystal logistics return route ties restock resources to low-pressure combat"
	)
	ready_map.free()


func _check_return_route_prompts_and_readiness() -> void:
	var world := _create_crystal_logistics_return_world(true)
	var character := CharacterState.create_default()
	character.equipment["suit_module"] = FieldOutfittingRuntime.BASIC_FILTER_MODULE_ID
	character.inventory.items.clear()
	var prompt_formatter := InteractionPromptFormatter.new(
		host.data_registry,
		ProcessingSystem.new(host.data_registry),
		BuildSystem.new(host.data_registry)
	)
	var crystal := PrototypeInteractable.new()
	crystal.instance_id = CoreGuardAftermathFormatter.CRYSTAL_LOGISTICS_RETURN_CRYSTAL_INSTANCE_ID
	crystal.definition_id = "map_object.crystal_cluster"
	crystal.interaction_type = "gather"
	var prompt := prompt_formatter.format_general_interaction_prompt(crystal, character, world)
	host._expect_text_contains(prompt, "后勤补料", "crystal logistics return prompt names restock route")
	host._expect_text_contains(prompt, "基础零件", "crystal logistics return prompt points to base parts")
	host._expect_text_contains(prompt, "出发整备台", "crystal logistics return prompt points to outfitting station")

	var departure_step := DepartureReadinessFormatter.format_departure_gate_next_step(world, character)
	host._expect_text_contains(departure_step, "晶体侧路补晶体矿和残骸废件", "departure gate points to crystal logistics return")
	var hud_lines := DepartureReadinessFormatter.format_hud_summary(world, character)
	host._expect_text_contains("\n".join(hud_lines), "后勤补料", "departure HUD includes crystal logistics return line")
	host._expect_equal(
		CoreGuardAftermathFormatter.get_next_sortie_target_region_id(world),
		"region.crystal_vein_field",
		"map target moves next sortie from core station to crystal field return route"
	)

	var gather_system := GatherSystem.new(host.data_registry)
	var crystal_result := gather_system.interact_with_object(
		CoreGuardAftermathFormatter.CRYSTAL_LOGISTICS_RETURN_CRYSTAL_INSTANCE_ID,
		"map_object.crystal_cluster",
		"gather",
		character,
		world
	)
	var wreckage_result := gather_system.interact_with_object(
		CoreGuardAftermathFormatter.CRYSTAL_LOGISTICS_RETURN_WRECKAGE_INSTANCE_ID,
		"map_object.field_wreckage",
		"gather",
		character,
		world
	)
	host._expect_equal(bool(crystal_result.get("success", false)), true, "crystal logistics return ore gather succeeds")
	host._expect_equal(bool(wreckage_result.get("success", false)), true, "crystal logistics return wreckage gather succeeds")
	host._expect_equal(int(character.inventory.items.get("item.crystal_ore", 0)), 3, "crystal logistics return grants crystal ore")
	host._expect_equal(int(character.inventory.items.get("item.salvage_scrap", 0)), 2, "crystal logistics return grants salvage scrap")
	host._expect_text_contains(
		DepartureReadinessFormatter.format_crystal_logistics_return_line(world, character),
		"晶体和残骸已回收",
		"departure readiness shows completed crystal logistics return payoff"
	)
	var completed_prompt := prompt_formatter.format_general_interaction_prompt(crystal, character, world)
	host._expect_text_contains(completed_prompt, "后勤补料已回收", "completed crystal logistics prompt reads gathered state")

	var reactor := PrototypeInteractable.new()
	reactor.definition_id = "building.basic_reactor"
	reactor.interaction_type = "process_recipe"
	reactor.recipe_id = "recipe.process_crystal_ore"
	reactor.set_recipe_cycle(["recipe.process_crystal_ore", "recipe.reclaim_basic_parts"])
	var processing := ProcessingSystem.new(host.data_registry)
	var reactor_prompt := prompt_formatter.format_processing_prompt(reactor, character, world)
	host._expect_text_contains(reactor_prompt, "后勤补料：晶体和残骸已回收", "basic reactor prompt reads returned logistics materials")
	host._expect_text_contains(reactor_prompt, "E 启动加工", "basic reactor prompt exposes logistics material processing action")
	var reactor_panel := HudDevicePanelPresenter.new().format_device_panel_texts(
		host.data_registry,
		processing,
		reactor,
		character,
		world
	)
	host._expect_text_contains(
		String(reactor_panel.get("status", "")),
		"把晶体侧路带回的补料晶体转成基础零件",
		"basic reactor panel explains logistics material processing purpose"
	)
	host._expect_text_contains(
		String(reactor_panel.get("recipes", "")),
		"处理晶体矿物（当前目标）",
		"basic reactor recommends crystal processing for logistics return"
	)
	var start_result := processing.process_recipe("recipe.process_crystal_ore", character, world)
	host._expect_equal(bool(start_result.get("success", false)), true, "logistics return crystal processing starts")
	var completed_processing := processing.advance_processing(6.0, character, world)
	host._expect_equal(completed_processing.size(), 1, "logistics return crystal processing completes")
	host._expect_equal(
		FieldOutfittingRuntime.is_logistics_material_processed(world),
		true,
		"logistics return crystal processing writes outfitting station state"
	)
	host._expect_equal(
		int(character.inventory.items.get("item.basic_parts", 0)),
		4,
		"logistics return crystal processing grants basic parts"
	)
	if not completed_processing.is_empty():
		host._expect_text_contains(
			String(completed_processing[0].get("next_step_text", "")),
			"出发整备台确认维护材料",
			"logistics return processing completion points to outfitting station"
		)
	host._expect_text_contains(
		DepartureReadinessFormatter.format_crystal_logistics_return_line(world, character),
		"晶体已加工成基础零件",
		"departure readiness shows processed logistics materials"
	)
	host._expect_equal(
		CoreGuardAftermathFormatter.get_next_sortie_target_region_id(world),
		"region.outpost_platform",
		"map target stays on base while logistics maintenance awaits confirmation"
	)

	var outfitting_prompt := prompt_formatter.format_outfitting_station_prompt(character, world)
	host._expect_text_contains(outfitting_prompt, "E 确认后勤维护", "outfitting station prompt exposes logistics maintenance confirmation")
	var maintenance_result := gather_system.interact_with_object(
		"map_object_instance.field_outfitting_station",
		"building.field_outfitting_station",
		"inspect",
		character,
		world
	)
	host._expect_equal(bool(maintenance_result.get("success", false)), true, "logistics maintenance confirmation succeeds")
	host._expect_equal(
		bool(maintenance_result.get("logistics_maintenance_confirmed", false)),
		true,
		"logistics maintenance confirmation returns state marker"
	)
	host._expect_equal(
		FieldOutfittingRuntime.is_logistics_maintenance_confirmed(world),
		true,
		"logistics maintenance confirmation persists on outfitting station"
	)
	host._expect_text_contains(
		String(maintenance_result.get("message", "")),
		"维护材料已登记到整备台",
		"logistics maintenance feedback names outfitting station state"
	)
	var confirmed_hud := HudStatusPresenter.new().format_status_text(host.data_registry, world, character)
	host._expect_text_contains(
		confirmed_hud,
		"模块归档 / 后勤维护",
		"HUD module state shows logistics maintenance payoff"
	)
	host._expect_text_contains(confirmed_hud, "整备台维护已确认", "HUD shows logistics maintenance confirmation")
	var confirmed_outfitting_prompt := prompt_formatter.format_outfitting_station_prompt(character, world)
	host._expect_text_contains(
		confirmed_outfitting_prompt,
		"后勤维护：已确认",
		"outfitting station prompt keeps confirmed logistics maintenance visible"
	)
	host._expect_text_contains(
		confirmed_outfitting_prompt,
		"污染反击 x0.69",
		"outfitting station prompt shows lowered logistics maintenance counter multiplier"
	)
	var restored_world := WorldState.from_dict(world.to_dict())
	var restored_character := CharacterState.from_dict(character.to_dict())
	host._expect_equal(
		FieldOutfittingRuntime.is_logistics_maintenance_confirmed(restored_world),
		true,
		"logistics maintenance confirmation survives world state roundtrip"
	)
	host._expect_text_contains(
		DepartureReadinessFormatter.format_departure_gate_status(restored_world, restored_character),
		"后勤维护",
		"departure readiness reads saved logistics maintenance state"
	)
	var departure_gate := PrototypeInteractable.new()
	departure_gate.definition_id = "map_object.outpost_departure_gate"
	departure_gate.interaction_type = "inspect"
	departure_gate.single_use = false
	var departure_prompt := prompt_formatter.format_general_interaction_prompt(departure_gate, character, world)
	host._expect_text_contains(departure_prompt, "整备台维护已确认", "departure gate prompt shows logistics maintenance confirmation")
	host._expect_text_contains(departure_prompt, "污染边界压力点", "departure gate prompt points to pollution maintenance retest pressure")
	host._expect_equal(
		CoreGuardAftermathFormatter.get_next_sortie_target_region_id(world),
		"region.pollution_edge",
		"map target routes logistics maintenance confirmation to pollution edge first"
	)
	departure_gate.free()
	reactor.free()
	crystal.free()


func _check_return_route_guard_feedback(root: Node) -> void:
	var map := VerticalSliceMapScene.instantiate() as VerticalSliceMap
	root.add_child(map)
	map.setup(host.data_registry)
	var world := _create_crystal_logistics_return_world(true)
	var character := CharacterState.create_default()
	map.apply_runtime_state(world, character)
	var guard := map.get_node("Enemies/NativeSkitterLogisticsReturnGuard") as PrototypeEnemy
	map.player.position = guard.position
	map.try_attack(character, world)
	var defeated_result := map.try_attack(character, world)
	host._expect_equal(bool(defeated_result.get("enemy_defeated", false)), true, "crystal logistics return guard can be defeated")
	host._expect_text_contains(
		String(defeated_result.get("message", "")),
		"后勤补料口袋暂时安全",
		"crystal logistics return guard defeat points back to restock pocket"
	)
	host._expect_equal(
		bool(world.get_enemy("enemy_instance.native_skitter_logistics_return_guard").get("is_defeated", false)),
		true,
		"crystal logistics return guard defeat is stored in world state"
	)
	map.free()


func _create_crystal_logistics_return_world(ready: bool) -> WorldState:
	var world := WorldState.create_default()
	world.current_region_id = "region.outpost_platform"
	world.quest_state.complete_quest("quest.restore_outpost")
	world.quest_state.unlock_effect("recipe.process_crystal_ore")
	world.quest_state.complete_quest("quest.write_demo_stabilization_core")
	world.add_base_structure(
		"structure.field_outfitting_station_build_site",
		"building.field_outfitting_station",
		"region.outpost_platform",
		"map_object_instance.field_outfitting_station_build_site"
	)
	FieldOutfittingRuntime.mark_core_archive_maintained(world)
	if ready:
		world.ensure_map_object(
			CoreStabilizationPressureFormatter.RETEST_READOUT_INSTANCE_ID,
			CoreStabilizationPressureFormatter.RETEST_READOUT_DEFINITION_ID,
			"region.demo_stabilization_core"
		)
		world.set_map_object_flag(
			CoreStabilizationPressureFormatter.RETEST_READOUT_INSTANCE_ID,
			"is_gathered",
			true
		)
	return world


func _is_rect_covering_position(rect: ColorRect, position: Vector2) -> bool:
	if rect == null:
		return false
	return (
		rect.offset_left <= position.x
		and rect.offset_right >= position.x
		and rect.offset_top <= position.y
		and rect.offset_bottom >= position.y
	)
