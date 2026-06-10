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
	map.sync_enemy_states(locked_world)
	map.refresh_world_interactables(locked_world)
	host._expect_equal(residue.can_interact(), false, "pollution revisit residue is gated before pollution edge quest")
	host._expect_equal(guard.can_be_attacked(), false, "pollution revisit guard is gated before pollution edge quest")
	var pollution_world := WorldState.create_default()
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
	locked_world.quest_state.active_quest_ids = ["quest.enter_pollution_edge"]
	locked_world.quest_state.set_objective_progress("quest.enter_pollution_edge", "craft_item", "item.resistance_vial_t1", 1.0)
	map.sync_enemy_states(locked_world)
	map.refresh_world_interactables(locked_world)
	host._expect_equal(residue.can_interact(), false, "slurry return residue requires operational pollution filter")
	host._expect_equal(guard.can_be_attacked(), false, "slurry return guard requires operational pollution filter")
	var opened_world := WorldState.create_default()
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
		"副产去向：基础反应器可回收污染浆液",
		"HUD base summary points polluted slurry to reactor reclaim"
	)
	host._expect_text_contains(
		status_text,
		"副产口袋补沉积物",
		"HUD base summary points back to slurry return pocket after reclaim"
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
			"副产口袋补沉积物",
			"slurry reclaim completion points back to field byproduct pocket"
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
