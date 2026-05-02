extends SceneTree

var failures: Array[String] = []
var data_registry := DataRegistry.new()
var world_state := WorldState.create_default()
var character_state := CharacterState.create_default()


func _init() -> void:
	_run_checks()
	if failures.is_empty():
		print("Vertical slice flow checks passed.")
		_cleanup()
		quit(0)
		return

	for failure in failures:
		push_error(failure)
	_cleanup()
	quit(1)


func _run_checks() -> void:
	if not data_registry.load_all():
		failures.append("data registry should load all static data")
		return

	_expect_equal(world_state.quest_state.active_quest_ids, ["quest.restore_outpost"], "initial active quest")

	_complete_active_quest("quest.restore_outpost", [
		{"type": "interact", "target_id": "building.outpost_core", "amount": 1}
	])
	_expect_active_quest("quest.scout_crystal_field", "after restore outpost")
	_expect_array_has(world_state.unlocked_region_ids, "region.crystal_vein_field", "restore unlocks crystal region")
	_expect_array_has(world_state.quest_state.unlocked_effects, "recipe.process_crystal_ore", "restore unlocks crystal recipe")

	_complete_active_quest("quest.scout_crystal_field", [
		{"type": "visit_region", "target_id": "region.crystal_vein_field", "amount": 1},
		{"type": "gather_item", "target_id": "item.crystal_ore", "amount": 6}
	])
	_expect_active_quest("quest.bring_back_sample", "after scout crystal field")

	_complete_active_quest("quest.bring_back_sample", [
		{"type": "sample_object", "target_id": "map_object.anomaly_crystal", "amount": 1},
		{"type": "return_region", "target_id": "region.outpost_platform", "amount": 1}
	])
	_expect_active_quest("quest.make_filter_module", "after bring back sample")
	_expect_array_has(world_state.quest_state.unlocked_effects, "recipe.make_filter_media", "sample unlocks filter media recipe")

	_complete_active_quest("quest.make_filter_module", [
		{"type": "craft_item", "target_id": "equipment.filter_module_t1", "amount": 1}
	])
	_expect_active_quest("quest.expand_treatment_point", "after make filter module")
	_expect_array_has(world_state.quest_state.unlocked_effects, "recipe.foundation_t1", "filter module unlocks foundation recipe")

	_complete_active_quest("quest.expand_treatment_point", [
		{"type": "build", "target_id": "building.foundation_t1", "amount": 2},
		{"type": "build", "target_id": "building.pollution_filter", "amount": 1}
	])
	_expect_active_quest("quest.enter_pollution_edge", "after expand treatment point")
	_expect_array_has(world_state.unlocked_region_ids, "region.pollution_edge", "treatment point unlocks pollution edge region")
	_expect_array_has(world_state.quest_state.unlocked_effects, "recipe.cleanse_residue", "treatment point unlocks residue recipe")

	_complete_active_quest("quest.enter_pollution_edge", [
		{"type": "visit_region", "target_id": "region.pollution_edge", "amount": 1},
		{"type": "gather_item", "target_id": "item.polluted_residue", "amount": 2},
		{"type": "craft_item", "target_id": "item.resistance_vial_t1", "amount": 1},
		{"type": "defeat_enemy", "target_id": "enemy.polluted_skitter", "amount": 1}
	])
	_expect_active_quest("quest.unlock_ruin_signal", "after enter pollution edge")
	_expect_array_has(world_state.unlocked_region_ids, "region.locked_ruin_gate", "pollution edge unlocks ruin gate region")
	_expect_array_has(world_state.quest_state.completed_quest_ids, "quest.enter_pollution_edge", "pollution edge completed")
	_expect_array_missing(world_state.quest_state.active_quest_ids, "quest.defeat_elite_node", "prototype should not activate unimplemented elite node")

	_complete_active_quest("quest.unlock_ruin_signal", [
		{"type": "inspect", "target_id": "map_object.ruin_gate", "amount": 1}
	])
	_expect_equal(world_state.quest_state.active_quest_ids, [], "after ruin signal has no active quest")
	_expect_array_has(world_state.quest_state.completed_quest_ids, "quest.unlock_ruin_signal", "ruin signal completed")
	_expect_array_has(world_state.quest_state.unlocked_effects, "slice_01_complete", "slice completion unlock")

	_check_evacuation_feedback()


func _complete_active_quest(quest_id: String, progress_refs: Array) -> void:
	if not world_state.quest_state.has_active_quest(quest_id):
		failures.append("%s should be active before completion" % quest_id)
		return

	for progress_ref in progress_refs:
		if not progress_ref is Dictionary:
			continue
		world_state.quest_state.set_objective_progress(
			quest_id,
			String(progress_ref.get("type", "")),
			String(progress_ref.get("target_id", "")),
			float(progress_ref.get("amount", 1.0))
		)

	if not _are_objectives_complete(quest_id):
		failures.append("%s objectives should be complete before applying rewards" % quest_id)
		return

	var quest := data_registry.get_definition(quest_id)
	world_state.quest_state.complete_quest(quest_id)
	_grant_refs(quest.get("rewards", []))
	for effect_id in quest.get("unlock_effects", []):
		_apply_unlock(String(effect_id))
	for next_quest_id in quest.get("next_quest_ids", []):
		world_state.quest_state.activate_quest(String(next_quest_id))


func _are_objectives_complete(quest_id: String) -> bool:
	var quest := data_registry.get_definition(quest_id)
	if quest.is_empty():
		failures.append("missing quest definition: %s" % quest_id)
		return false

	for objective in quest.get("objectives", []):
		if not objective is Dictionary:
			continue
		var objective_type := String(objective.get("type", ""))
		var target_id := String(objective.get("target_id", ""))
		var required_amount := float(objective.get("amount", 1.0))
		var current_amount := world_state.quest_state.get_objective_progress(quest_id, objective_type, target_id)
		if current_amount < required_amount:
			return false
	return true


func _grant_refs(refs: Array) -> void:
	for ref in refs:
		if not ref is Dictionary:
			continue

		var definition_id := String(ref.get("id", ""))
		var amount := float(ref.get("amount", 0.0))
		if definition_id.is_empty() or amount <= 0.0:
			continue
		character_state.inventory.add_ref(definition_id, amount)


func _apply_unlock(effect_id: String) -> void:
	if effect_id.begins_with("region."):
		world_state.unlock_region(effect_id)
	world_state.quest_state.unlock_effect(effect_id)


func _check_evacuation_feedback() -> void:
	var map := VerticalSliceMap.new()
	map.player = PlayerController.new()
	var evacuation_world := WorldState.create_default()
	var evacuation_character := CharacterState.create_default()
	evacuation_character.health = 0.0
	evacuation_character.protection = 80.0
	evacuation_character.current_region_id = "region.pollution_edge"
	evacuation_world.current_region_id = "region.pollution_edge"

	var feedback := map._evacuate_if_needed(evacuation_character, evacuation_world, "combat")
	_expect_equal(String(feedback.get("title", "")), "撤离前哨", "evacuation feedback title")
	_expect_equal(String(feedback.get("reason_text", "")), "生命耗尽", "evacuation reason")
	_expect_equal(evacuation_world.current_region_id, "region.outpost_platform", "evacuation world region")
	_expect_equal(evacuation_character.current_region_id, "region.outpost_platform", "evacuation character region")
	_expect_equal(evacuation_character.health, 60.0, "evacuation health recovery")
	if String(feedback.get("retry_text", "")).find("修复凝胶") < 0:
		failures.append("evacuation retry text should mention repair gel, got %s" % var_to_str(feedback))
	map.player.free()
	map.free()


func _expect_active_quest(quest_id: String, label: String) -> void:
	_expect_array_has(world_state.quest_state.active_quest_ids, quest_id, label)


func _expect_equal(actual, expected, label: String) -> void:
	if actual != expected:
		failures.append("%s expected %s, got %s" % [label, var_to_str(expected), var_to_str(actual)])


func _expect_array_has(values: Array, expected_value: String, label: String) -> void:
	if not values.has(expected_value):
		failures.append("%s should contain %s, got %s" % [label, expected_value, var_to_str(values)])


func _expect_array_missing(values: Array, unexpected_value: String, label: String) -> void:
	if values.has(unexpected_value):
		failures.append("%s should not contain %s, got %s" % [label, unexpected_value, var_to_str(values)])


func _cleanup() -> void:
	data_registry.free()
