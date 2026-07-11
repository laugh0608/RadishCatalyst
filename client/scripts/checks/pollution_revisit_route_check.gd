extends RefCounted

const VerticalSliceMapScene := preload("res://scenes/maps/VerticalSliceMap.tscn")

var host


func _init(check_host) -> void:
	host = check_host


func run(root: Node) -> void:
	_check_revisit_route_layout(root)
	_check_revisit_route_gate(root)
	_check_revisit_residue_feedback()
	_check_revisit_guard_vial_feedback(root)
	_check_slurry_return_route_layout(root)
	_check_slurry_return_route_gate(root)
	_check_slurry_return_residue_feedback()
	_check_slurry_return_guard_vial_feedback(root)
	_check_vial_reserve_route_layout(root)
	_check_vial_reserve_route_gate(root)
	_check_vial_reserve_residue_feedback()
	_check_vial_reserve_guard_vial_feedback(root)
	_check_core_archive_route_layout(root)
	_check_core_archive_route_gate(root)
	_check_core_archive_route_residue_feedback()
	_check_core_archive_route_guard_feedback(root)
	_check_core_archive_departure_guidance()
	_check_core_archive_return_route_layout(root)
	_check_core_archive_return_route_gate(root)
	_check_core_archive_return_residue_feedback()
	_check_core_archive_return_guard_feedback(root)
	_check_core_archive_pressure_retest_layout(root)
	_check_core_archive_pressure_retest_gate(root)
	_check_core_archive_pressure_retest_guard_feedback(root)
	_check_core_archive_pressure_retest_residue_feedback(root)
	_check_core_archive_pressure_retest_processing_feedback()
	preload("res://scripts/checks/pollution_maintenance_pressure_check.gd").new(host).run(root)
	_check_double_vial_pressure_spend_and_restock(root)
	_check_double_vial_core_write_feedback()
	_check_slurry_reclaim_hud_and_device_panel()


func _check_revisit_route_layout(root: Node) -> void:
	var map := VerticalSliceMapScene.instantiate() as VerticalSliceMap
	root.add_child(map)
	map.setup(host.data_registry)
	var pocket := map.get_node("OpeningSceneLayer/PollutionVialReturnPocket") as ColorRect
	var residue_marker := map.get_node("OpeningSceneLayer/PollutionVialReturnResidueMarker") as ColorRect
	var guard_marker := map.get_node("OpeningSceneLayer/PollutionVialReturnGuardMarker") as ColorRect
	var entry_residue := map.get_node("Interactables/PollutionResidue") as PrototypeInteractable
	var revisit_residue := map.get_node("Interactables/PollutionResidueVialReturnCache") as PrototypeInteractable
	var deep_residue := map.get_node("Interactables/PollutionResidueDeep") as PrototypeInteractable
	var guard := map.get_node("Enemies/PollutedSkitterVialReturnGuard") as PrototypeEnemy
	host._expect_equal(
		revisit_residue.position.x >= VerticalSliceMap.POLLUTION_REGION_X
			and revisit_residue.position.y >= VerticalSliceMap.POLLUTION_DEEP_Y,
		true,
		"pollution revisit residue stays inside the pollution danger field"
	)
	host._expect_equal(
		entry_residue.position.x < revisit_residue.position.x and revisit_residue.position.x < deep_residue.position.x,
		true,
		"pollution revisit residue sits between entry and deep residue pressure"
	)
	host._expect_equal(
		_is_rect_covering_position(pocket, revisit_residue.position)
			and _is_rect_covering_position(residue_marker, revisit_residue.position)
			and _is_rect_covering_position(guard_marker, guard.position),
		true,
		"pollution revisit route scene markers align with playable objects"
	)
	host._expect_equal(
		guard.position.distance_to(revisit_residue.position) <= VerticalSliceMap.ATTACK_RANGE,
		true,
		"pollution revisit residue is tied to visible vial-pressure combat"
	)
	map.free()


func _check_revisit_route_gate(root: Node) -> void:
	var map := VerticalSliceMapScene.instantiate() as VerticalSliceMap
	root.add_child(map)
	map.setup(host.data_registry)
	var residue := map.get_node("Interactables/PollutionResidueVialReturnCache") as PrototypeInteractable
	var guard := map.get_node("Enemies/PollutedSkitterVialReturnGuard") as PrototypeEnemy
	var locked_world := WorldState.create_default()
	host._complete_first_minute(locked_world)
	map.sync_enemy_states(locked_world)
	map.refresh_world_interactables(locked_world)
	host._expect_equal(residue.can_interact(), false, "pollution revisit residue is gated before pollution edge quest")
	host._expect_equal(guard.can_be_attacked(), false, "pollution revisit guard is gated before pollution edge quest")
	var pollution_world := WorldState.create_default()
	host._complete_first_minute(pollution_world)
	pollution_world.quest_state.active_quest_ids = ["quest.enter_pollution_edge"]
	map.sync_enemy_states(pollution_world)
	map.refresh_world_interactables(pollution_world)
	host._expect_equal(residue.can_interact(), true, "pollution revisit residue opens during pollution edge quest")
	host._expect_equal(guard.can_be_attacked(), true, "pollution revisit guard opens during pollution edge quest")
	map.free()


func _check_revisit_residue_feedback() -> void:
	var gather_system := GatherSystem.new(host.data_registry)
	var world := WorldState.create_default()
	var character := CharacterState.create_default()
	character.equipment["suit_module"] = "equipment.filter_module_t1"
	character.inventory.add_item("item.resistance_vial_t1", 1)
	var result := gather_system.interact_with_object(
		"map_object_instance.pollution_residue_vial_return_cache",
		"map_object.pollution_residue_patch",
		"gather",
		character,
		world
	)
	host._expect_equal(bool(result.get("success", false)), true, "pollution revisit residue gather succeeds")
	host._expect_text_contains(
		String(result.get("message", "")),
		"过滤模块已降低消耗",
		"pollution revisit residue reads equipped filter module"
	)
	host._expect_text_contains(
		String(result.get("message", "")),
		"回过滤器处理成下一支药剂和污染浆液",
		"pollution revisit residue points back to filter processing"
	)
	host._expect_equal(
		int(character.inventory.items.get("item.polluted_residue", 0)),
		2,
		"pollution revisit residue grants polluted residue"
	)


func _check_revisit_guard_vial_feedback(root: Node) -> void:
	var map := VerticalSliceMapScene.instantiate() as VerticalSliceMap
	root.add_child(map)
	map.setup(host.data_registry)
	var world := WorldState.create_default()
	world.quest_state.active_quest_ids = ["quest.enter_pollution_edge"]
	var character := CharacterState.create_default()
	character.inventory.add_item("item.resistance_vial_t1", 1)
	map.sync_enemy_states(world)
	var guard := map.get_node("Enemies/PollutedSkitterVialReturnGuard") as PrototypeEnemy
	map.player.position = guard.position
	var pressure_result := map.try_attack(character, world)
	host._expect_equal(bool(pressure_result.get("enemy_defeated", true)), false, "pollution revisit guard first hit keeps combat active")
	host._expect_text_contains(
		String(pressure_result.get("message", "")),
		"抗污染药剂已自动接入侧翼排压",
		"pollution revisit guard consumes vial for pressure venting"
	)
	host._expect_equal(
		int(character.inventory.items.get("item.resistance_vial_t1", 0)),
		0,
		"pollution revisit guard consumes one resistance vial"
	)
	host._expect_equal(
		bool(world.get_enemy("enemy_instance.polluted_skitter_vial_return_guard").get("pressure_vial_used", false)),
		true,
		"pollution revisit guard records vial usage"
	)
	map.try_attack(character, world)
	var defeated_result := map.try_attack(character, world)
	host._expect_equal(bool(defeated_result.get("enemy_defeated", false)), true, "pollution revisit guard can be defeated")
	host._expect_text_contains(
		String(defeated_result.get("message", "")),
		"污染侧翼压力减弱",
		"pollution revisit guard defeat points back to residue and filter work"
	)
	host._expect_equal(
		bool(world.get_enemy("enemy_instance.polluted_skitter_vial_return_guard").get("is_defeated", false)),
		true,
		"pollution revisit guard defeat is stored in world state"
	)
	host._expect_equal(
		world.has_enemy_drops_granted("enemy_instance.polluted_skitter_vial_return_guard"),
		true,
		"pollution revisit guard drop grant is stored"
	)
	map.free()


func _check_slurry_return_route_layout(root: Node) -> void:
	var map := VerticalSliceMapScene.instantiate() as VerticalSliceMap
	root.add_child(map)
	map.setup(host.data_registry)
	var pocket := map.get_node("OpeningSceneLayer/PollutionSlurryReturnPocket") as ColorRect
	var residue_marker := map.get_node("OpeningSceneLayer/PollutionSlurryReturnResidueMarker") as ColorRect
	var guard_marker := map.get_node("OpeningSceneLayer/PollutionSlurryReturnGuardMarker") as ColorRect
	var residue := map.get_node("Interactables/PollutionResidueSlurryReturnCache") as PrototypeInteractable
	var guard := map.get_node("Enemies/PollutedSkitterSlurryReturnGuard") as PrototypeEnemy
	host._expect_equal(
		residue.position.x >= VerticalSliceMap.POLLUTION_REGION_X
			and residue.position.x < VerticalSliceMap.RUIN_OUTER_RING_X
			and residue.position.y >= VerticalSliceMap.POLLUTION_DEEP_Y,
		true,
		"pollution slurry return residue stays inside pollution edge"
	)
	host._expect_equal(
		_is_rect_covering_position(pocket, residue.position)
			and _is_rect_covering_position(residue_marker, residue.position)
			and _is_rect_covering_position(guard_marker, guard.position),
		true,
		"pollution slurry return scene markers align with playable objects"
	)
	host._expect_equal(
		guard.position.distance_to(residue.position) <= VerticalSliceMap.ATTACK_RANGE,
		true,
		"pollution slurry return residue is tied to visible byproduct combat"
	)
	map.free()


func _check_slurry_return_route_gate(root: Node) -> void:
	var map := VerticalSliceMapScene.instantiate() as VerticalSliceMap
	root.add_child(map)
	map.setup(host.data_registry)
	var residue := map.get_node("Interactables/PollutionResidueSlurryReturnCache") as PrototypeInteractable
	var guard := map.get_node("Enemies/PollutedSkitterSlurryReturnGuard") as PrototypeEnemy
	var locked_world := WorldState.create_default()
	host._complete_first_minute(locked_world)
	locked_world.quest_state.active_quest_ids = ["quest.enter_pollution_edge"]
	locked_world.quest_state.set_objective_progress("quest.enter_pollution_edge", "craft_item", "item.resistance_vial_t1", 1.0)
	map.sync_enemy_states(locked_world)
	map.refresh_world_interactables(locked_world)
	host._expect_equal(residue.can_interact(), false, "slurry return residue requires operational pollution filter")
	host._expect_equal(guard.can_be_attacked(), false, "slurry return guard requires operational pollution filter")
	var opened_world := WorldState.create_default()
	host._complete_first_minute(opened_world)
	opened_world.quest_state.active_quest_ids = ["quest.enter_pollution_edge"]
	opened_world.quest_state.set_objective_progress("quest.enter_pollution_edge", "craft_item", "item.resistance_vial_t1", 1.0)
	opened_world.add_base_structure("structure.pollution_filter_build_site", "building.pollution_filter", "region.pollution_edge")
	map.sync_enemy_states(opened_world)
	map.refresh_world_interactables(opened_world)
	host._expect_equal(residue.can_interact(), true, "slurry return residue opens after first vial processing line")
	host._expect_equal(guard.can_be_attacked(), true, "slurry return guard opens after first vial processing line")
	map.free()


func _check_slurry_return_residue_feedback() -> void:
	var gather_system := GatherSystem.new(host.data_registry)
	var world := WorldState.create_default()
	var character := CharacterState.create_default()
	character.equipment["suit_module"] = "equipment.filter_module_t1"
	var result := gather_system.interact_with_object(
		"map_object_instance.pollution_residue_slurry_return_cache",
		"map_object.pollution_residue_patch",
		"gather",
		character,
		world
	)
	host._expect_equal(bool(result.get("success", false)), true, "pollution slurry return residue gather succeeds")
	host._expect_text_contains(
		String(result.get("message", "")),
		"基础反应器把多余浆液回收成基础零件",
		"pollution slurry return residue points to byproduct reclaim"
	)
	host._expect_equal(
		int(character.inventory.items.get("item.polluted_residue", 0)),
		2,
		"pollution slurry return residue grants polluted residue"
	)


func _check_slurry_return_guard_vial_feedback(root: Node) -> void:
	var map := VerticalSliceMapScene.instantiate() as VerticalSliceMap
	root.add_child(map)
	map.setup(host.data_registry)
	var world := WorldState.create_default()
	world.quest_state.active_quest_ids = ["quest.enter_pollution_edge"]
	world.quest_state.set_objective_progress("quest.enter_pollution_edge", "craft_item", "item.resistance_vial_t1", 1.0)
	world.add_base_structure("structure.pollution_filter_build_site", "building.pollution_filter", "region.pollution_edge")
	var character := CharacterState.create_default()
	character.inventory.add_item("item.resistance_vial_t1", 1)
	map.sync_enemy_states(world)
	var guard := map.get_node("Enemies/PollutedSkitterSlurryReturnGuard") as PrototypeEnemy
	map.player.position = guard.position
	var pressure_result := map.try_attack(character, world)
	host._expect_equal(bool(pressure_result.get("enemy_defeated", true)), false, "slurry return guard first hit keeps combat active")
	host._expect_text_contains(
		String(pressure_result.get("message", "")),
		"抗污染药剂已自动接入副产口袋排压",
		"slurry return guard consumes vial for byproduct pressure"
	)
	host._expect_equal(
		int(character.inventory.items.get("item.resistance_vial_t1", 0)),
		0,
		"slurry return guard consumes one resistance vial"
	)
	host._expect_equal(
		bool(world.get_enemy("enemy_instance.polluted_skitter_slurry_return_guard").get("pressure_vial_used", false)),
		true,
		"slurry return guard records vial usage"
	)
	map.try_attack(character, world)
	var defeated_result := map.try_attack(character, world)
	host._expect_equal(bool(defeated_result.get("enemy_defeated", false)), true, "slurry return guard can be defeated")
	host._expect_text_contains(
		String(defeated_result.get("message", "")),
		"基础反应器回收基础零件",
		"slurry return guard defeat points back to reactor reclaim"
	)
	host._expect_equal(
		bool(world.get_enemy("enemy_instance.polluted_skitter_slurry_return_guard").get("is_defeated", false)),
		true,
		"slurry return guard defeat is stored in world state"
	)
	map.free()


func _check_vial_reserve_route_layout(root: Node) -> void:
	var map := VerticalSliceMapScene.instantiate() as VerticalSliceMap
	root.add_child(map)
	map.setup(host.data_registry)
	var pocket := map.get_node("OpeningSceneLayer/PollutionVialReservePocket") as ColorRect
	var residue_marker := map.get_node("OpeningSceneLayer/PollutionVialReserveResidueMarker") as ColorRect
	var guard_marker := map.get_node("OpeningSceneLayer/PollutionVialReserveGuardMarker") as ColorRect
	var residue := map.get_node("Interactables/PollutionResidueVialReserveCache") as PrototypeInteractable
	var guard := map.get_node("Enemies/PollutedSkitterVialReserveGuard") as PrototypeEnemy
	host._expect_equal(
		residue.position.x >= VerticalSliceMap.POLLUTION_REGION_X
			and residue.position.x < VerticalSliceMap.RUIN_OUTER_RING_X
			and residue.position.y >= VerticalSliceMap.POLLUTION_DEEP_Y,
		true,
		"vial reserve residue stays inside pollution edge"
	)
	host._expect_equal(
		_is_rect_covering_position(pocket, residue.position)
			and _is_rect_covering_position(residue_marker, residue.position)
			and _is_rect_covering_position(guard_marker, guard.position),
		true,
		"vial reserve scene markers align with playable objects"
	)
	host._expect_equal(
		guard.position.distance_to(residue.position) <= VerticalSliceMap.ATTACK_RANGE,
		true,
		"vial reserve residue is tied to visible combat"
	)
	map.free()


func _check_vial_reserve_route_gate(root: Node) -> void:
	var map := VerticalSliceMapScene.instantiate() as VerticalSliceMap
	root.add_child(map)
	map.setup(host.data_registry)
	var residue := map.get_node("Interactables/PollutionResidueVialReserveCache") as PrototypeInteractable
	var guard := map.get_node("Enemies/PollutedSkitterVialReserveGuard") as PrototypeEnemy
	var locked_world := WorldState.create_default()
	host._complete_first_minute(locked_world)
	locked_world.quest_state.active_quest_ids = ["quest.enter_pollution_edge"]
	locked_world.quest_state.set_objective_progress("quest.enter_pollution_edge", "craft_item", "item.resistance_vial_t1", 1.0)
	map.sync_enemy_states(locked_world)
	map.refresh_world_interactables(locked_world)
	host._expect_equal(residue.can_interact(), false, "vial reserve residue requires operational pollution filter")
	host._expect_equal(guard.can_be_attacked(), false, "vial reserve guard requires operational pollution filter")
	var opened_world := WorldState.create_default()
	host._complete_first_minute(opened_world)
	opened_world.quest_state.active_quest_ids = ["quest.enter_pollution_edge"]
	opened_world.quest_state.set_objective_progress("quest.enter_pollution_edge", "craft_item", "item.resistance_vial_t1", 1.0)
	opened_world.add_base_structure("structure.pollution_filter_build_site", "building.pollution_filter", "region.pollution_edge")
	map.sync_enemy_states(opened_world)
	map.refresh_world_interactables(opened_world)
	host._expect_equal(residue.can_interact(), true, "vial reserve residue opens after first vial processing line")
	host._expect_equal(guard.can_be_attacked(), true, "vial reserve guard opens after first vial processing line")
	map.free()


func _check_vial_reserve_residue_feedback() -> void:
	var gather_system := GatherSystem.new(host.data_registry)
	var world := WorldState.create_default()
	var character := CharacterState.create_default()
	character.equipment["suit_module"] = "equipment.filter_module_t1"
	var result := gather_system.interact_with_object(
		"map_object_instance.pollution_residue_vial_reserve_cache",
		"map_object.pollution_residue_patch",
		"gather",
		character,
		world
	)
	host._expect_equal(bool(result.get("success", false)), true, "vial reserve residue gather succeeds")
	host._expect_text_contains(
		String(result.get("message", "")),
		"药剂储备口袋沉积已回收",
		"vial reserve residue names the reserve pocket"
	)
	host._expect_text_contains(
		String(result.get("message", "")),
		"回过滤器补抗污染药剂",
		"vial reserve residue points back to filter processing"
	)
	host._expect_equal(
		int(character.inventory.items.get("item.polluted_residue", 0)),
		2,
		"vial reserve residue grants polluted residue"
	)


func _check_vial_reserve_guard_vial_feedback(root: Node) -> void:
	var map := VerticalSliceMapScene.instantiate() as VerticalSliceMap
	root.add_child(map)
	map.setup(host.data_registry)
	var world := WorldState.create_default()
	world.quest_state.active_quest_ids = ["quest.enter_pollution_edge"]
	world.quest_state.set_objective_progress("quest.enter_pollution_edge", "craft_item", "item.resistance_vial_t1", 1.0)
	world.add_base_structure("structure.pollution_filter_build_site", "building.pollution_filter", "region.pollution_edge")
	var character := CharacterState.create_default()
	character.inventory.add_item("item.resistance_vial_t1", 1)
	map.sync_enemy_states(world)
	var guard := map.get_node("Enemies/PollutedSkitterVialReserveGuard") as PrototypeEnemy
	map.player.position = guard.position
	var pressure_result := map.try_attack(character, world)
	host._expect_equal(bool(pressure_result.get("enemy_defeated", true)), false, "vial reserve guard first hit keeps combat active")
	host._expect_text_contains(
		String(pressure_result.get("message", "")),
		"抗污染药剂已自动接入药剂储备口袋排压",
		"vial reserve guard consumes vial for reserve pressure"
	)
	host._expect_equal(
		int(character.inventory.items.get("item.resistance_vial_t1", 0)),
		0,
		"vial reserve guard consumes one resistance vial"
	)
	host._expect_equal(
		bool(world.get_enemy("enemy_instance.polluted_skitter_vial_reserve_guard").get("pressure_vial_used", false)),
		true,
		"vial reserve guard records vial usage"
	)
	map.try_attack(character, world)
	var defeated_result := map.try_attack(character, world)
	host._expect_equal(bool(defeated_result.get("enemy_defeated", false)), true, "vial reserve guard can be defeated")
	host._expect_text_contains(
		String(defeated_result.get("message", "")),
		"药剂储备口袋暂时安全",
		"vial reserve guard defeat points back to reserve pocket"
	)
	host._expect_equal(
		bool(world.get_enemy("enemy_instance.polluted_skitter_vial_reserve_guard").get("is_defeated", false)),
		true,
		"vial reserve guard defeat is stored in world state"
	)
	host._expect_equal(
		world.has_enemy_drops_granted("enemy_instance.polluted_skitter_vial_reserve_guard"),
		true,
		"vial reserve guard drop grant is stored"
	)
	map.free()


func _check_core_archive_route_layout(root: Node) -> void:
	var map := VerticalSliceMapScene.instantiate() as VerticalSliceMap
	root.add_child(map)
	map.setup(host.data_registry)
	var pocket := map.get_node("OpeningSceneLayer/PollutionCoreArchiveRoutePocket") as ColorRect
	var residue_marker := map.get_node("OpeningSceneLayer/PollutionCoreArchiveRouteResidueMarker") as ColorRect
	var guard_marker := map.get_node("OpeningSceneLayer/PollutionCoreArchiveRouteGuardMarker") as ColorRect
	var route_residue := map.get_node("Interactables/PollutionResidueCoreArchiveRouteCache") as PrototypeInteractable
	var return_residue := map.get_node("Interactables/PollutionResidueCoreArchiveReturnCache") as PrototypeInteractable
	var guard := map.get_node("Enemies/PollutedSkitterCoreArchiveRouteGuard") as PrototypeEnemy
	host._expect_equal(
		route_residue.position.x >= VerticalSliceMap.POLLUTION_REGION_X
			and route_residue.position.x < return_residue.position.x
			and route_residue.position.y >= VerticalSliceMap.POLLUTION_DEEP_Y,
		true,
		"core archive route residue sits before the deeper archive return pocket"
	)
	host._expect_equal(
		_is_rect_covering_position(pocket, route_residue.position)
			and _is_rect_covering_position(residue_marker, route_residue.position)
			and _is_rect_covering_position(guard_marker, guard.position),
		true,
		"core archive route scene markers align with playable objects"
	)
	host._expect_equal(
		guard.position.distance_to(route_residue.position) <= VerticalSliceMap.ATTACK_RANGE,
		true,
		"core archive route residue is tied to visible pressure combat"
	)
	map.free()


func _check_core_archive_route_gate(root: Node) -> void:
	var map := VerticalSliceMapScene.instantiate() as VerticalSliceMap
	root.add_child(map)
	map.setup(host.data_registry)
	var residue := map.get_node("Interactables/PollutionResidueCoreArchiveRouteCache") as PrototypeInteractable
	var guard := map.get_node("Enemies/PollutedSkitterCoreArchiveRouteGuard") as PrototypeEnemy
	var locked_world := _create_core_archive_return_world(false)
	map.sync_enemy_states(locked_world)
	map.refresh_world_interactables(locked_world)
	host._expect_equal(residue.can_interact(), false, "core archive route residue is gated before archive maintenance")
	host._expect_equal(guard.can_be_attacked(), false, "core archive route guard is gated before archive maintenance")

	var maintained_world := _create_core_archive_return_world(true)
	map.sync_enemy_states(maintained_world)
	map.refresh_world_interactables(maintained_world)
	host._expect_equal(residue.can_interact(), true, "core archive route residue opens after archive maintenance")
	host._expect_equal(guard.can_be_attacked(), true, "core archive route guard opens after archive maintenance")
	map.free()


func _check_core_archive_route_residue_feedback() -> void:
	var gather_system := GatherSystem.new(host.data_registry)
	var world := _create_core_archive_return_world(true)
	var character := CharacterState.create_default()
	character.equipment["suit_module"] = FieldOutfittingRuntime.BASIC_FILTER_MODULE_ID
	var result := gather_system.interact_with_object(
		"map_object_instance.pollution_residue_core_archive_route_cache",
		"map_object.pollution_residue_patch",
		"gather",
		character,
		world
	)
	host._expect_equal(bool(result.get("success", false)), true, "core archive route residue gather succeeds")
	host._expect_text_contains(
		String(result.get("message", "")),
		"出发路线回访沉积已回收",
		"core archive route residue names the departure route pocket"
	)
	host._expect_text_contains(
		String(result.get("message", "")),
		"回过滤器补满双药剂",
		"core archive route residue points to filtering and double vial restock"
	)
	host._expect_equal(
		int(character.inventory.items.get("item.polluted_residue", 0)),
		2,
		"core archive route residue grants polluted residue"
	)


func _check_core_archive_route_guard_feedback(root: Node) -> void:
	var map := VerticalSliceMapScene.instantiate() as VerticalSliceMap
	root.add_child(map)
	map.setup(host.data_registry)
	var world := _create_core_archive_return_world(true)
	var character := CharacterState.create_default()
	character.equipment["suit_module"] = FieldOutfittingRuntime.BASIC_FILTER_MODULE_ID
	character.inventory.add_item("item.resistance_vial_t1", 2)
	map.sync_enemy_states(world)
	map.refresh_world_interactables(world)
	var guard := map.get_node("Enemies/PollutedSkitterCoreArchiveRouteGuard") as PrototypeEnemy
	map.player.position = guard.position
	var result := map.try_attack(character, world)
	host._expect_text_contains(
		String(result.get("message", "")),
		"第 1 份抗污染药剂已自动接入出发路线回访排压",
		"core archive route guard consumes first vial for route pressure"
	)
	host._expect_text_contains(
		String(result.get("message", "")),
		"核心归档维护会继续降低这段出发路线承压",
		"core archive route guard explains archive maintenance payoff"
	)
	host._expect_equal(
		int(character.inventory.items.get("item.resistance_vial_t1", 0)),
		1,
		"core archive route guard spends one vial"
	)
	map.free()


func _check_core_archive_departure_guidance() -> void:
	var world := _create_core_archive_return_world(true)
	var character := CharacterState.create_default()
	character.current_region_id = "region.outpost_platform"
	character.equipment["suit_module"] = FieldOutfittingRuntime.BASIC_FILTER_MODULE_ID
	character.inventory.add_item("item.repair_gel", 1)
	character.inventory.add_item("item.resistance_vial_t1", 2)
	var status_text := HudStatusPresenter.new().format_status_text(host.data_registry, world, character)
	host._expect_text_contains(
		status_text,
		"回访路线：核心归档维护已接入",
		"HUD points maintained archive to pollution revisit route"
	)
	host._expect_text_contains(
		status_text,
		"出发路线 / 归档维护口袋",
		"HUD names both archive return route pockets"
	)
	var gather_system := GatherSystem.new(host.data_registry)
	var gate_result := gather_system.interact_with_object(
		"map_object_instance.outpost_departure_gate",
		"map_object.outpost_departure_gate",
		"inspect",
		character,
		world
	)
	host._expect_text_contains(
		String(gate_result.get("message", "")),
		"先从外勤出发口回污染边界",
		"departure gate sends maintained archive through pollution revisit first"
	)


func _check_double_vial_pressure_spend_and_restock(root: Node) -> void:
	var map := VerticalSliceMapScene.instantiate() as VerticalSliceMap
	root.add_child(map)
	map.setup(host.data_registry)
	var world := _create_double_vial_world()
	var character := CharacterState.create_default()
	character.inventory.add_item("item.resistance_vial_t1", 2)
	map.sync_enemy_states(world)

	var first_guard := map.get_node("Enemies/PollutedSkitterVialReturnGuard") as PrototypeEnemy
	map.player.position = first_guard.position
	var first_pressure_result := map.try_attack(character, world)
	host._expect_text_contains(
		String(first_pressure_result.get("message", "")),
		"第 1 份抗污染药剂已自动接入侧翼排压",
		"double vial first combat spend names first vial"
	)
	host._expect_text_contains(
		String(first_pressure_result.get("message", "")),
		"药剂 2/2 -> 1/2",
		"double vial first combat spend shows remaining reserve"
	)
	host._expect_equal(
		int(character.inventory.items.get("item.resistance_vial_t1", 0)),
		1,
		"double vial first combat leaves one vial"
	)
	var partial_hud := HudStatusPresenter.new().format_vitals_text(host.data_registry, world, character)
	host._expect_text_contains(
		partial_hud,
		"抗污染药剂到 2（当前 1/2）",
		"double vial partial HUD points back to outpost restock"
	)

	var second_guard := map.get_node("Enemies/PollutedSkitterVialReserveGuard") as PrototypeEnemy
	map.player.position = second_guard.position
	var second_pressure_result := map.try_attack(character, world)
	host._expect_text_contains(
		String(second_pressure_result.get("message", "")),
		"第 2 份抗污染药剂已自动接入药剂储备口袋排压",
		"double vial second combat spend names second vial"
	)
	host._expect_text_contains(
		String(second_pressure_result.get("message", "")),
		"药剂 1/2 -> 0/2",
		"double vial second combat spend shows empty reserve"
	)
	host._expect_text_contains(
		String(second_pressure_result.get("message", "")),
		"回前哨核心可补回 2/2",
		"double vial empty reserve points back to outpost core"
	)
	host._expect_equal(
		int(character.inventory.items.get("item.resistance_vial_t1", 0)),
		0,
		"double vial second combat consumes remaining vial"
	)

	var gather_system := GatherSystem.new(host.data_registry)
	var gate_result := gather_system.interact_with_object(
		"map_object_instance.outpost_departure_gate",
		"map_object.outpost_departure_gate",
		"inspect",
		character,
		world
	)
	host._expect_text_contains(
		String(gate_result.get("message", "")),
		"抗污染药剂到 2",
		"departure gate prompts double vial restock after pressure spend"
	)
	var outpost_result := gather_system.interact_with_object(
		"map_object_instance.outpost_core",
		"building.outpost_core",
		"outpost_core",
		character,
		world
	)
	host._expect_text_contains(
		String(outpost_result.get("message", "")),
		"药剂 0/2 -> 2/2",
		"outpost core restores spent double vial reserve"
	)
	host._expect_equal(
		int(character.inventory.items.get("item.resistance_vial_t1", 0)),
		2,
		"outpost core restores double vial reserve to target"
	)
	map.free()


func _check_core_archive_return_route_layout(root: Node) -> void:
	var map := VerticalSliceMapScene.instantiate() as VerticalSliceMap
	root.add_child(map)
	map.setup(host.data_registry)
	var pocket := map.get_node("OpeningSceneLayer/PollutionCoreArchiveReturnPocket") as ColorRect
	var residue_marker := map.get_node("OpeningSceneLayer/PollutionCoreArchiveResidueMarker") as ColorRect
	var guard_marker := map.get_node("OpeningSceneLayer/PollutionCoreArchiveGuardMarker") as ColorRect
	var residue := map.get_node("Interactables/PollutionResidueCoreArchiveReturnCache") as PrototypeInteractable
	var guard := map.get_node("Enemies/PollutedSkitterCoreArchiveReturnGuard") as PrototypeEnemy
	host._expect_equal(
		_is_rect_covering_position(pocket, residue.position)
			and _is_rect_covering_position(residue_marker, residue.position)
			and _is_rect_covering_position(guard_marker, guard.position),
		true,
		"core archive return route scene markers align with playable objects"
	)
	host._expect_equal(
		guard.position.distance_to(residue.position) <= VerticalSliceMap.ATTACK_RANGE,
		true,
		"core archive return residue is tied to nearby pressure combat"
	)
	map.free()


func _check_core_archive_return_route_gate(root: Node) -> void:
	var map := VerticalSliceMapScene.instantiate() as VerticalSliceMap
	root.add_child(map)
	map.setup(host.data_registry)
	var residue := map.get_node("Interactables/PollutionResidueCoreArchiveReturnCache") as PrototypeInteractable
	var guard := map.get_node("Enemies/PollutedSkitterCoreArchiveReturnGuard") as PrototypeEnemy
	var locked_world := _create_core_archive_return_world(false)
	map.sync_enemy_states(locked_world)
	map.refresh_world_interactables(locked_world)
	host._expect_equal(residue.can_interact(), false, "core archive return residue is gated before archive maintenance")
	host._expect_equal(guard.can_be_attacked(), false, "core archive return guard is gated before archive maintenance")

	var maintained_world := _create_core_archive_return_world(true)
	map.sync_enemy_states(maintained_world)
	map.refresh_world_interactables(maintained_world)
	host._expect_equal(residue.can_interact(), true, "core archive return residue opens after archive maintenance")
	host._expect_equal(guard.can_be_attacked(), true, "core archive return guard opens after archive maintenance")
	map.free()


func _check_core_archive_return_residue_feedback() -> void:
	var gather_system := GatherSystem.new(host.data_registry)
	var world := _create_core_archive_return_world(true)
	var character := CharacterState.create_default()
	character.equipment["suit_module"] = FieldOutfittingRuntime.BASIC_FILTER_MODULE_ID
	var result := gather_system.interact_with_object(
		"map_object_instance.pollution_residue_core_archive_return_cache",
		"map_object.pollution_residue_patch",
		"gather",
		character,
		world
	)
	host._expect_equal(bool(result.get("success", false)), true, "core archive return residue gather succeeds")
	host._expect_text_contains(
		String(result.get("message", "")),
		"核心归档维护已降低消耗",
		"core archive return residue reads maintenance pressure payoff"
	)
	host._expect_text_contains(
		String(result.get("message", "")),
		"归档维护回访沉积已回收",
		"core archive return residue points back to filter processing"
	)


func _check_core_archive_return_guard_feedback(root: Node) -> void:
	var map := VerticalSliceMapScene.instantiate() as VerticalSliceMap
	root.add_child(map)
	map.setup(host.data_registry)
	var world := _create_core_archive_return_world(true)
	var character := CharacterState.create_default()
	character.equipment["suit_module"] = FieldOutfittingRuntime.BASIC_FILTER_MODULE_ID
	character.inventory.add_item("item.resistance_vial_t1", 2)
	map.sync_enemy_states(world)
	map.refresh_world_interactables(world)
	var guard := map.get_node("Enemies/PollutedSkitterCoreArchiveReturnGuard") as PrototypeEnemy
	map.player.position = guard.position
	var result := map.try_attack(character, world)
	host._expect_text_contains(
		String(result.get("message", "")),
		"第 1 份抗污染药剂已自动接入归档维护回访排压",
		"core archive return guard consumes first vial from double reserve"
	)
	host._expect_text_contains(
		String(result.get("message", "")),
		"核心归档维护会继续降低这段回访承压",
		"core archive return guard explains archive maintenance payoff"
	)
	host._expect_text_contains(
		String(result.get("message", "")),
		"核心归档维护已接入",
		"core archive return guard reads outfitting maintenance runtime"
	)
	host._expect_equal(
		int(character.inventory.items.get("item.resistance_vial_t1", 0)),
		1,
		"core archive return guard spends one vial"
	)
	map.free()


func _check_core_archive_pressure_retest_layout(root: Node) -> void:
	var map := VerticalSliceMapScene.instantiate() as VerticalSliceMap
	root.add_child(map)
	map.setup(host.data_registry)
	var pocket := map.get_node("OpeningSceneLayer/PollutionCoreArchivePressureRetestPocket") as ColorRect
	var residue_marker := map.get_node("OpeningSceneLayer/PollutionCoreArchivePressureRetestResidueMarker") as ColorRect
	var guard_marker := map.get_node("OpeningSceneLayer/PollutionCoreArchivePressureRetestGuardMarker") as ColorRect
	var line := map.get_node("OpeningSceneLayer/PollutionCoreArchivePressureRetestLine") as ColorRect
	var return_residue := map.get_node("Interactables/PollutionResidueCoreArchiveReturnCache") as PrototypeInteractable
	var residue := map.get_node("Interactables/PollutionResidueCoreArchivePressureRetestCache") as PrototypeInteractable
	var guard := map.get_node("Enemies/PollutedSkitterCoreArchivePressureRetestGuard") as PrototypeEnemy
	host._expect_equal(
		residue.position.x > return_residue.position.x
			and residue.position.x < VerticalSliceMap.RUIN_OUTER_RING_X
			and residue.position.y >= VerticalSliceMap.POLLUTION_DEEP_Y,
		true,
		"core archive pressure retest residue stays after return pocket inside pollution edge"
	)
	host._expect_equal(
		_is_rect_covering_position(pocket, residue.position)
			and _is_rect_covering_position(residue_marker, residue.position)
			and _is_rect_covering_position(guard_marker, guard.position)
			and line.offset_right <= VerticalSliceMap.RUIN_OUTER_RING_X,
		true,
		"core archive pressure retest scene markers align with playable objects"
	)
	host._expect_equal(
		guard.position.distance_to(residue.position) <= VerticalSliceMap.ATTACK_RANGE,
		true,
		"core archive pressure retest residue is tied to nearby combat"
	)
	map.free()


func _check_core_archive_pressure_retest_gate(root: Node) -> void:
	var map := VerticalSliceMapScene.instantiate() as VerticalSliceMap
	root.add_child(map)
	map.setup(host.data_registry)
	var residue := map.get_node("Interactables/PollutionResidueCoreArchivePressureRetestCache") as PrototypeInteractable
	var guard := map.get_node("Enemies/PollutedSkitterCoreArchivePressureRetestGuard") as PrototypeEnemy
	var maintained_world := _create_core_archive_return_world(true)
	map.sync_enemy_states(maintained_world)
	map.refresh_world_interactables(maintained_world)
	host._expect_equal(residue.can_interact(), false, "pressure retest residue waits for archive return processing")
	host._expect_equal(guard.can_be_attacked(), false, "pressure retest guard waits for archive return processing")

	var gathered_world := _create_core_archive_return_world(true)
	_mark_core_archive_return_residue_gathered(gathered_world)
	map.sync_enemy_states(gathered_world)
	map.refresh_world_interactables(gathered_world)
	host._expect_equal(residue.can_interact(), false, "pressure retest residue waits for filter completion")
	host._expect_equal(guard.can_be_attacked(), false, "pressure retest guard waits for filter completion")

	var ready_world := _create_core_archive_pressure_retest_world()
	map.sync_enemy_states(ready_world)
	map.refresh_world_interactables(ready_world)
	host._expect_equal(residue.can_interact(), true, "pressure retest residue opens after archive return filtering")
	host._expect_equal(guard.can_be_attacked(), true, "pressure retest guard opens after archive return filtering")
	map.free()


func _check_core_archive_pressure_retest_guard_feedback(root: Node) -> void:
	var map := VerticalSliceMapScene.instantiate() as VerticalSliceMap
	root.add_child(map)
	map.setup(host.data_registry)
	var world := _create_core_archive_pressure_retest_world()
	var character := CharacterState.create_default()
	character.equipment["suit_module"] = FieldOutfittingRuntime.BASIC_FILTER_MODULE_ID
	character.inventory.add_item("item.resistance_vial_t1", 2)
	map.sync_enemy_states(world)
	map.refresh_world_interactables(world)
	var guard := map.get_node("Enemies/PollutedSkitterCoreArchivePressureRetestGuard") as PrototypeEnemy
	map.player.position = guard.position
	var result := map.try_attack(character, world)
	host._expect_text_contains(
		String(result.get("message", "")),
		"第 1 份抗污染药剂已自动接入复测压力点排压",
		"pressure retest guard consumes first vial"
	)
	host._expect_text_contains(
		String(result.get("message", "")),
		"核心归档维护和双药剂会继续降低复测压力点承压",
		"pressure retest guard explains archive and double vial payoff"
	)
	host._expect_equal(
		int(character.inventory.items.get("item.resistance_vial_t1", 0)),
		1,
		"pressure retest guard spends one vial"
	)
	map.try_attack(character, world)
	var defeated_result := map.try_attack(character, world)
	host._expect_equal(bool(defeated_result.get("enemy_defeated", false)), true, "pressure retest guard can be defeated")
	host._expect_text_contains(
		String(defeated_result.get("message", "")),
		"复测压力点暂时安全",
		"pressure retest guard defeat points to residue processing"
	)
	host._expect_equal(
		bool(world.get_enemy("enemy_instance.polluted_skitter_core_archive_pressure_retest_guard").get("is_defeated", false)),
		true,
		"pressure retest guard defeat is stored"
	)
	host._expect_equal(
		world.has_enemy_drops_granted("enemy_instance.polluted_skitter_core_archive_pressure_retest_guard"),
		true,
		"pressure retest guard drop grant is stored"
	)
	map.free()


func _check_core_archive_pressure_retest_residue_feedback(root: Node) -> void:
	var map := VerticalSliceMapScene.instantiate() as VerticalSliceMap
	root.add_child(map)
	map.setup(host.data_registry)
	var world := _create_core_archive_pressure_retest_world()
	var character := CharacterState.create_default()
	character.equipment["suit_module"] = FieldOutfittingRuntime.BASIC_FILTER_MODULE_ID
	var residue := map.get_node("Interactables/PollutionResidueCoreArchivePressureRetestCache") as PrototypeInteractable
	var prompt := InteractionPromptFormatter.new(
		host.data_registry,
		ProcessingSystem.new(host.data_registry),
		BuildSystem.new(host.data_registry)
	).format_general_interaction_prompt(residue, character, world)
	host._expect_text_contains(prompt, "复测压力守卫", "pressure retest prompt names combat precondition")
	var result := GatherSystem.new(host.data_registry).interact_with_object(
		"map_object_instance.pollution_residue_core_archive_pressure_retest_cache",
		"map_object.pollution_residue_patch",
		"gather",
		character,
		world
	)
	host._expect_equal(bool(result.get("success", false)), true, "pressure retest residue gather succeeds")
	host._expect_text_contains(
		String(result.get("message", "")),
		"过滤模块校准和核心归档维护已降低消耗",
		"pressure retest residue reads outfitting pressure payoff"
	)
	host._expect_equal(
		int(character.inventory.items.get("item.polluted_residue", 0)),
		2,
		"pressure retest residue grants polluted residue"
	)
	map.free()


func _check_core_archive_pressure_retest_processing_feedback() -> void:
	var world := _create_core_archive_pressure_retest_world()
	world.quest_state.unlock_effect("recipe.cleanse_residue")
	world.ensure_map_object(
		"map_object_instance.pollution_residue_core_archive_pressure_retest_cache",
		"map_object.pollution_residue_patch",
		"region.pollution_edge"
	)
	world.set_map_object_flag("map_object_instance.pollution_residue_core_archive_pressure_retest_cache", "is_gathered", true)
	var character := CharacterState.create_default()
	character.inventory.add_item("item.polluted_residue", 2)
	character.inventory.add_fluid("fluid.basic_solvent", 1.0)
	var before_line := DepartureReadinessFormatter.format_core_archive_return_processing_line(world, character)
	host._expect_text_contains(
		before_line,
		"复测压力沉积已回收",
		"departure readiness points unprocessed pressure retest residue back to filter"
	)
	var processing := ProcessingSystem.new(host.data_registry)
	var start := processing.process_recipe("recipe.cleanse_residue", character, world)
	host._expect_equal(bool(start.get("success", false)), true, "pressure retest residue can start filtering")
	host._expect_text_contains(
		String(start.get("message", "")),
		"复测压力沉积",
		"pressure retest filtering start names residue source"
	)
	var completed := processing.advance_processing(13.0, character, world)
	host._expect_equal(completed.size(), 1, "pressure retest residue filtering completes")
	if not completed.is_empty():
		host._expect_text_contains(
			String(completed[0].get("next_step_text", "")),
			"复测压力沉积已处理",
			"pressure retest filtering completion names processed source"
		)
		host._expect_text_contains(
			String(completed[0].get("next_step_text", "")),
			"污染浆液回基础反应器回收基础零件",
			"pressure retest filtering completion points slurry to reactor reclaim"
		)
	host._expect_equal(
		int(character.inventory.items.get("item.resistance_vial_t1", 0)),
		1,
		"pressure retest filtering grants resistance vial"
	)
	host._expect_equal(
		float(character.inventory.fluids.get("fluid.polluted_slurry", 0.0)),
		1.0,
		"pressure retest filtering grants polluted slurry"
	)


func _check_double_vial_core_write_feedback() -> void:
	var gather_system := GatherSystem.new(host.data_registry)
	var world := _create_double_vial_world()
	world.current_region_id = "region.demo_stabilization_core"
	world.quest_state.active_quest_ids = ["quest.write_demo_stabilization_core"]
	world.quest_state.set_objective_progress("quest.write_demo_stabilization_core", "gather_item", "item.core_write_charge", 1.0)
	world.ensure_enemy(
		"enemy_instance.demo_stabilization_guard",
		"enemy.demo_stabilization_guard",
		"region.demo_stabilization_core",
		60.0
	)["is_defeated"] = true
	var character := CharacterState.create_default()
	character.current_region_id = "region.demo_stabilization_core"
	character.inventory.add_item("item.resistance_vial_t1", 2)
	var write_result := gather_system.interact_with_object(
		"map_object_instance.demo_stabilization_core",
		"map_object.demo_stabilization_core",
		"inspect",
		character,
		world
	)
	host._expect_equal(bool(write_result.get("success", false)), true, "double vial core write succeeds")
	host._expect_text_contains(
		String(write_result.get("message", "")),
		"第 1 份抗污染药剂已自动接入写入排压",
		"core write names first vial spend from double reserve"
	)
	host._expect_text_contains(
		String(write_result.get("message", "")),
		"药剂 2/2 -> 1/2",
		"core write shows remaining double vial reserve"
	)
	host._expect_equal(
		int(character.inventory.items.get("item.resistance_vial_t1", 0)),
		1,
		"core write leaves second vial in reserve"
	)
	host._expect_text_contains(
		CoreStabilizationPressureFormatter.format_ready_parts(world, character),
		"药剂 1/2，建议补满",
		"core readiness treats partial double vial reserve as not fully ready"
	)


func _create_double_vial_world() -> WorldState:
	var world := WorldState.create_default()
	host._complete_first_minute(world)
	world.quest_state.complete_quest("quest.restore_outpost")
	world.quest_state.complete_quest("quest.enter_pollution_edge")
	world.quest_state.set_objective_progress("quest.enter_pollution_edge", "craft_item", "item.resistance_vial_t1", 1.0)
	world.add_base_structure(
		"structure.basic_storage_build_site",
		"building.basic_storage",
		"region.outpost_platform",
		"map_object_instance.basic_storage_build_site"
	)
	world.add_base_structure(
		"structure.pollution_filter_build_site",
		"building.pollution_filter",
		"region.pollution_edge",
		"map_object_instance.pollution_filter_build_site"
	)
	world.add_base_structure(
		"structure.slurry_buffer_tank_build_site",
		"building.slurry_buffer_tank",
		"region.outpost_platform",
		"map_object_instance.slurry_buffer_tank_build_site"
	)
	return world


func _create_core_archive_return_world(maintained: bool) -> WorldState:
	var world := _create_double_vial_world()
	world.quest_state.complete_quest("quest.write_demo_stabilization_core")
	world.add_base_structure(
		"structure.field_outfitting_station_build_site",
		"building.field_outfitting_station",
		"region.outpost_platform",
		"map_object_instance.field_outfitting_station_build_site"
	)
	if maintained:
		FieldOutfittingRuntime.mark_core_archive_maintained(world)
	return world


func _create_core_archive_pressure_retest_world() -> WorldState:
	var world := _create_core_archive_return_world(true)
	FieldOutfittingRuntime.mark_module_calibrated(world)
	_mark_core_archive_return_residue_gathered(world)
	world.set_base_structure_status("structure.pollution_filter_build_site", "completed", "recipe.cleanse_residue")
	return world


func _mark_core_archive_return_residue_gathered(world: WorldState) -> void:
	world.ensure_map_object(
		"map_object_instance.pollution_residue_core_archive_route_cache",
		"map_object.pollution_residue_patch",
		"region.pollution_edge"
	)
	world.ensure_map_object(
		"map_object_instance.pollution_residue_core_archive_return_cache",
		"map_object.pollution_residue_patch",
		"region.pollution_edge"
	)
	world.set_map_object_flag("map_object_instance.pollution_residue_core_archive_route_cache", "is_gathered", true)
	world.set_map_object_flag("map_object_instance.pollution_residue_core_archive_return_cache", "is_gathered", true)


func _check_slurry_reclaim_hud_and_device_panel() -> void:
	var world := WorldState.create_default()
	world.quest_state.active_quest_ids = ["quest.enter_pollution_edge"]
	world.quest_state.unlock_effect("recipe.reclaim_basic_parts")
	var character := CharacterState.create_default()
	character.inventory.add_fluid("fluid.polluted_slurry", 1.0)
	var initial_basic_parts := int(character.inventory.items.get("item.basic_parts", 0))
	var status_text := HudStatusPresenter.new().format_vitals_text(host.data_registry, world, character)
	host._expect_text_contains(
		status_text,
		"二次收益：可用污染浆液",
		"HUD base summary points polluted slurry to slurry buffer payoff"
	)
	host._expect_text_contains(
		status_text,
		"支撑下一趟污染回访",
		"HUD base summary points slurry payoff to next pollution revisit"
	)

	var processing := ProcessingSystem.new(host.data_registry)
	var reactor := PrototypeInteractable.new()
	reactor.definition_id = "building.basic_reactor"
	reactor.interaction_type = "process_recipe"
	reactor.recipe_id = "recipe.process_crystal_ore"
	reactor.set_recipe_cycle(["recipe.process_crystal_ore", "recipe.reclaim_basic_parts"])
	var panel := HudDevicePanelPresenter.new().format_device_panel_texts(
		host.data_registry,
		processing,
		reactor,
		character,
		world
	)
	host._expect_text_contains(
		String(panel.get("recipes", "")),
		"回收基础零件（当前目标）：可加工",
		"reactor panel recommends slurry reclaim when polluted slurry is available"
	)
	var start := processing.process_recipe("recipe.reclaim_basic_parts", character, world)
	host._expect_equal(bool(start.get("success", false)), true, "slurry reclaim starts from polluted slurry")
	var completed := processing.advance_processing(9.0, character, world)
	host._expect_equal(completed.size(), 1, "slurry reclaim completes")
	if not completed.is_empty():
		host._expect_text_contains(
			String(completed[0].get("next_step_text", "")),
			"药剂储备口袋补沉积物",
			"slurry reclaim completion points back to field return pockets"
		)
	host._expect_equal(
		int(character.inventory.items.get("item.basic_parts", 0)),
		initial_basic_parts + 2,
		"slurry reclaim grants basic parts"
	)
	host._expect_equal(
		float(character.inventory.fluids.get("fluid.polluted_slurry", 0.0)),
		0.0,
		"slurry reclaim consumes polluted slurry"
	)
	reactor.free()


func _is_rect_covering_position(rect: ColorRect, position: Vector2) -> bool:
	if rect == null:
		return false
	return (
		rect.offset_left <= position.x
		and rect.offset_right >= position.x
		and rect.offset_top <= position.y
		and rect.offset_bottom >= position.y
	)
