extends RefCounted
class_name QuestRuntime

var event_rules: QuestEventRules
var progress_rules: QuestProgressRules
var completion_rules: QuestCompletionRules
var completion_applier: QuestCompletionApplier


func _init(data_registry: DataRegistry) -> void:
	event_rules = QuestEventRules.new(data_registry)
	progress_rules = QuestProgressRules.new(data_registry)
	completion_rules = QuestCompletionRules.new(data_registry, progress_rules)
	completion_applier = QuestCompletionApplier.new(data_registry)


func advance_for_interaction(
	world_state: WorldState,
	character_state: CharacterState,
	context: Dictionary,
	interaction_result: Dictionary
) -> Dictionary:
	return apply_objective_updates(
		world_state,
		character_state,
		event_rules.get_interaction_objective_updates(context, interaction_result, world_state.quest_state)
	)


func advance_for_region(world_state: WorldState, character_state: CharacterState, region_id: String) -> Dictionary:
	return apply_objective_updates(
		world_state,
		character_state,
		event_rules.get_region_objective_updates(region_id, world_state.quest_state)
	)


func advance_for_defeated_enemy(
	world_state: WorldState,
	character_state: CharacterState,
	enemy_definition_id: String
) -> Dictionary:
	return apply_objective_updates(
		world_state,
		character_state,
		event_rules.get_defeated_enemy_objective_updates(enemy_definition_id)
	)


func advance_pollution_edge_ready(world_state: WorldState, character_state: CharacterState) -> Dictionary:
	if not world_state.quest_state.has_active_quest("quest.enter_pollution_edge") and not world_state.quest_state.has_completed_quest("quest.expand_treatment_point"):
		return _empty_result(false)

	world_state.unlock_region("region.pollution_edge")
	var result := apply_objective_updates(
		world_state,
		character_state,
		event_rules.get_pollution_edge_ready_updates(world_state.quest_state)
	)
	result["accepted"] = true
	return result


func reconcile_active_objectives(world_state: WorldState, character_state: CharacterState) -> Dictionary:
	var updates: Array[Dictionary] = []
	var log_messages: Array[String] = []
	var progression_sync := CharacterProgressionStats.sync_character_state(
		character_state,
		world_state.quest_state,
		"preserve_ratio"
	)
	if bool(progression_sync.get("changed", false)):
		log_messages.append(CharacterProgressionStats.LEGACY_SYNC_LOG_MESSAGE)
	if _restore_missing_phase_well_heart_analysis_unlock(world_state):
		log_messages.append("旧进度已接入：相位井心核解析配方已补齐。")
	if _restore_missing_phase_well_spindle_analysis_unlock(world_state):
		log_messages.append("旧进度已接入：相位井纺核解析配方已补齐。")
	if _restore_missing_phase_well_weave_core_analysis_unlock(world_state):
		log_messages.append("旧进度已接入：相位井织核解析配方已补齐。")
	if _restore_missing_phase_well_knot_core_analysis_unlock(world_state):
		log_messages.append("旧进度已接入：相位井结核解析配方已补齐。")
	if _restore_missing_phase_well_anchor_core_analysis_unlock(world_state):
		log_messages.append("旧进度已接入：相位井锚核解析配方已补齐。")
	if _restore_missing_phase_well_weave_core_reward(character_state, world_state):
		log_messages.append("旧进度已接入：井纺室勘验奖励的相位井织核已补回背包。")
	if _restore_missing_phase_well_knot_core_reward(character_state, world_state):
		log_messages.append("旧进度已接入：井纹架勘验奖励的相位井结核已补回背包。")
	if _restore_missing_phase_well_anchor_core_reward(character_state, world_state):
		log_messages.append("旧进度已接入：井系桥勘验奖励的相位井锚核已补回背包。")
	if _restore_missing_phase_well_core_analysis_unlock(world_state):
		log_messages.append("旧进度已接入：相位井芯样本解析配方已补齐。")
	if _restore_missing_phase_well_locator_analysis_unlock(world_state):
		log_messages.append("旧进度已接入：相位井定位器解析配方已补齐。")
	if _restore_missing_inner_fault_analysis_unlock(world_state):
		log_messages.append("旧进度已接入：内层故障轨迹分析配方已补齐。")
	if _restore_missing_phase_relay_anchor(world_state):
		log_messages.append("旧进度已接入：前线回传锚点已按固定深段落点恢复在线。")
	if _restore_missing_deployed_phase_relay_anchors(world_state):
		log_messages.append("旧进度已接入：已部署前线锚点列表已按现有回投进度补齐。")
	if _activate_missing_post_phase_well_loom_followup(world_state):
		log_messages.append("旧进度已接入：井纺室后的井纹架后续任务已补入当前目标。")
	if _activate_missing_post_phase_well_frame_followup(world_state):
		log_messages.append("旧进度已接入：井纹架后的井系桥后续任务已补入当前目标。")
	if _activate_missing_post_phase_well_tether_followup(world_state):
		log_messages.append("旧进度已接入：井系桥后的锚场回稳后续任务已补入当前目标。")
	if _activate_missing_post_phase_well_readout_followup(world_state):
		log_messages.append("旧进度已接入：稳窗读数后的现场校准任务已补入当前目标。")
	if _activate_missing_post_phase_well_chamber_followup(world_state):
		log_messages.append("旧进度已接入：井心室后的井纺后续任务已补入当前目标。")
	if _activate_missing_post_phase_well_sink_followup(world_state):
		log_messages.append("旧进度已接入：井底裂口后的心核后续任务已补入当前目标。")
	if _activate_missing_post_phase_relay_followup(world_state):
		log_messages.append("旧进度已接入：回传后的深段后续任务已补入当前目标。")
	if _activate_missing_second_deep_followup(world_state):
		log_messages.append("旧进度已接入：深段样块后的第二轮任务已补入当前目标。")
	if _activate_missing_deep_ruin_followup(world_state):
		log_messages.append("旧进度已接入：更深遗迹入口门禁写入任务已补入当前目标。")
	if _activate_missing_outer_ring_followup(world_state):
		log_messages.append("旧进度已接入：外圈中继后的深段回波回收任务已补入当前目标。")
	if world_state.quest_state.has_active_quest("quest.bring_back_sample"):
		updates.append_array(_get_bring_back_sample_recovery_updates(world_state, character_state))
	updates.append_array(_get_active_region_progress_recovery_updates(world_state))
	updates.append_array(_get_active_inventory_gather_recovery_updates(world_state, character_state))
	updates.append_array(_get_phase_well_field_reading_recovery_updates(world_state, character_state))
	updates.append_array(_get_phase_well_frame_route_recovery_updates(world_state, character_state))
	updates.append_array(_get_anchor_field_pressure_pin_recovery_updates(world_state))
	var late_craft_recovery_updates := _get_late_craft_progress_recovery_updates(world_state, character_state)
	if not late_craft_recovery_updates.is_empty():
		updates.append_array(late_craft_recovery_updates)
		log_messages.append("旧进度已接入：背包里已完成的后段加工产物已补记到当前任务。")
	if updates.is_empty():
		if log_messages.is_empty():
			return _empty_result(false)
		var activation_only_result := _empty_result(true)
		for message in log_messages:
			activation_only_result["log_messages"].append(message)
		return activation_only_result
	var result := apply_objective_updates(world_state, character_state, updates)
	result["accepted"] = true
	for message in log_messages:
		result["log_messages"].append(message)
	return result


func apply_objective_updates(
	world_state: WorldState,
	character_state: CharacterState,
	updates: Array[Dictionary]
) -> Dictionary:
	var result := _empty_result(true)
	var changed_quest_ids: Array[String] = []
	for update in updates:
		var quest_id := String(update.get("quest_id", ""))
		var objective_type := String(update.get("objective_type", ""))
		var target_id := String(update.get("target_id", ""))
		var amount := float(update.get("amount", 0.0))
		if String(update.get("mode", "set")) == "add":
			progress_rules.add_active_objective_progress(world_state.quest_state, quest_id, objective_type, target_id, amount)
		else:
			progress_rules.set_active_objective_progress(world_state.quest_state, quest_id, objective_type, target_id, amount)
		if not changed_quest_ids.has(quest_id):
			changed_quest_ids.append(quest_id)

	for quest_id in changed_quest_ids:
		var feedback := _try_complete_quest(world_state, character_state, quest_id)
		if feedback.is_empty():
			continue

		result["completion_feedbacks"].append(feedback)
		result["log_messages"].append(String(feedback.get("log_message", "")))
	return result


func _try_complete_quest(world_state: WorldState, character_state: CharacterState, quest_id: String) -> Dictionary:
	var completion_result := completion_rules.try_complete_quest(world_state.quest_state, quest_id)
	if not bool(completion_result.get("completed", false)):
		return {}

	return completion_applier.apply_completion(world_state, character_state, completion_result)


func _get_bring_back_sample_recovery_updates(world_state: WorldState, character_state: CharacterState) -> Array[Dictionary]:
	var updates: Array[Dictionary] = []
	var quest_id := "quest.bring_back_sample"
	var sample_progress := world_state.quest_state.get_objective_progress(quest_id, "sample_object", "map_object.anomaly_crystal")
	var anomaly_state := world_state.get_map_object("map_object_instance.anomaly_crystal")
	var has_sample := bool(anomaly_state.get("is_sampled", false)) or character_state.inventory.has_ref("item.anomaly_sample", 1)
	if sample_progress < 1.0 and has_sample:
		updates.append(_objective_set_update(quest_id, "sample_object", "map_object.anomaly_crystal", 1))
	return updates


func _get_active_region_progress_recovery_updates(world_state: WorldState) -> Array[Dictionary]:
	var updates: Array[Dictionary] = []
	var current_region_id := world_state.current_region_id
	if current_region_id.is_empty():
		return updates

	for quest_id in world_state.quest_state.active_quest_ids:
		var quest := completion_rules.data_registry.get_definition(String(quest_id))
		if quest.is_empty():
			continue
		for objective in quest.get("objectives", []):
			if not objective is Dictionary:
				continue
			if String(objective.get("type", "")) != "visit_region":
				continue
			if String(objective.get("target_id", "")) != current_region_id:
				continue
			if world_state.quest_state.get_objective_progress(String(quest_id), "visit_region", current_region_id) >= 1.0:
				continue
			updates.append(_objective_set_update(String(quest_id), "visit_region", current_region_id, 1))
	return updates


func _get_active_inventory_gather_recovery_updates(world_state: WorldState, character_state: CharacterState) -> Array[Dictionary]:
	var updates: Array[Dictionary] = []
	for quest_id in world_state.quest_state.active_quest_ids:
		var quest := completion_rules.data_registry.get_definition(String(quest_id))
		if quest.is_empty():
			continue
		for objective in quest.get("objectives", []):
			if not objective is Dictionary:
				continue
			if String(objective.get("type", "")) != "gather_item":
				continue
			var item_id := String(objective.get("target_id", ""))
			var required_amount := float(objective.get("amount", 1.0))
			if item_id.is_empty() or required_amount <= 0.0:
				continue
			var current_amount := world_state.quest_state.get_objective_progress(String(quest_id), "gather_item", item_id)
			if current_amount >= required_amount:
				continue
			if not character_state.inventory.has_ref(item_id, required_amount):
				continue
			updates.append(_objective_set_update(String(quest_id), "gather_item", item_id, required_amount))
	return updates


func _get_phase_well_field_reading_recovery_updates(world_state: WorldState, character_state: CharacterState) -> Array[Dictionary]:
	var updates: Array[Dictionary] = []
	for recovery in [
		{
			"quest_id": "quest.collect_heart_spine",
			"objective_target_id": "map_object.phase_well_chamber_shunt_node",
			"instance_ids": [
				"map_object_instance.phase_well_chamber_shunt_west",
				"map_object_instance.phase_well_chamber_shunt_east"
			],
			"item_id": "item.heart_spine",
			"enemy_id": "enemy.phase_well_reaver"
		},
		{
			"quest_id": "quest.collect_weft_bundle",
			"objective_target_id": "map_object.phase_well_loom_tension_spool",
			"instance_ids": [
				"map_object_instance.phase_well_loom_tension_north",
				"map_object_instance.phase_well_loom_tension_south"
			],
			"item_id": "item.weft_bundle",
			"enemy_id": "enemy.phase_well_tangler"
		},
		{
			"quest_id": "quest.collect_tether_fiber",
			"objective_target_id": "map_object.phase_well_tether_knot_node",
			"instance_ids": [
				"map_object_instance.phase_well_tether_knot_west",
				"map_object_instance.phase_well_tether_knot_east"
			],
			"item_id": "item.tether_fiber",
			"enemy_id": "enemy.phase_well_binder"
		}
	]:
		var quest_id := String(recovery.get("quest_id", ""))
		var objective_target_id := String(recovery.get("objective_target_id", ""))
		if not world_state.quest_state.has_active_quest(quest_id):
			continue
		if world_state.quest_state.get_objective_progress(quest_id, "inspect", objective_target_id) >= 2.0:
			continue

		var reading_count := 0
		for instance_id in recovery.get("instance_ids", []):
			if bool(world_state.get_map_object(String(instance_id)).get("is_sampled", false)):
				reading_count += 1
		if reading_count >= 2:
			updates.append(_objective_set_update(quest_id, "inspect", objective_target_id, 2))
			continue

		var item_id := String(recovery.get("item_id", ""))
		var enemy_id := String(recovery.get("enemy_id", ""))
		if (
			world_state.quest_state.get_objective_progress(quest_id, "gather_item", item_id) > 0.0
			or world_state.quest_state.get_objective_progress(quest_id, "defeat_enemy", enemy_id) > 0.0
			or character_state.inventory.has_ref(item_id, 1)
		):
			updates.append(_objective_set_update(quest_id, "inspect", objective_target_id, 2))
	return updates


func _get_phase_well_frame_route_recovery_updates(world_state: WorldState, character_state: CharacterState) -> Array[Dictionary]:
	var updates: Array[Dictionary] = []
	var quest_id := "quest.collect_selvedge_strip"
	if not world_state.quest_state.has_active_quest(quest_id):
		return updates
	if world_state.quest_state.get_objective_progress(quest_id, "clear", "map_object.phase_well_frame_route_blocker") >= 1.0:
		return updates

	var has_route_evidence := false
	for route_instance_id in [
		"map_object_instance.phase_well_frame_route_north",
		"map_object_instance.phase_well_frame_route_south"
	]:
		if bool(world_state.get_map_object(route_instance_id).get("is_cleared", false)):
			has_route_evidence = true
	if world_state.quest_state.get_objective_progress(quest_id, "gather_item", "item.selvedge_strip") > 0.0:
		has_route_evidence = true
	if world_state.quest_state.get_objective_progress(quest_id, "defeat_enemy", "enemy.phase_well_raker") > 0.0:
		has_route_evidence = true
	if character_state.inventory.has_ref("item.selvedge_strip", 1):
		has_route_evidence = true
	if not has_route_evidence:
		return updates
	updates.append(_objective_set_update(quest_id, "clear", "map_object.phase_well_frame_route_blocker", 1))
	return updates


func _get_anchor_field_pressure_pin_recovery_updates(world_state: WorldState) -> Array[Dictionary]:
	var updates: Array[Dictionary] = []
	var quest_id := "quest.stabilize_phase_well_anchor_field"
	var objective_target_id := "map_object.phase_well_anchor_pressure_pin"
	if not world_state.quest_state.has_active_quest(quest_id):
		return updates
	if world_state.quest_state.get_objective_progress(quest_id, "clear", objective_target_id) >= 2.0:
		return updates

	var pin_count := 0
	for pressure_pin_instance_id in [
		"map_object_instance.phase_well_anchor_pressure_pin_west",
		"map_object_instance.phase_well_anchor_pressure_pin_east"
	]:
		if bool(world_state.get_map_object(pressure_pin_instance_id).get("is_cleared", false)):
			pin_count += 1
	if pin_count >= 2 or world_state.quest_state.get_objective_progress(quest_id, "defeat_enemy", "enemy.phase_well_warden") > 0.0:
		updates.append(_objective_set_update(quest_id, "clear", objective_target_id, 2))
	return updates


func _get_late_craft_progress_recovery_updates(world_state: WorldState, character_state: CharacterState) -> Array[Dictionary]:
	var updates: Array[Dictionary] = []
	for recovery in [
		{
			"quest_id": "quest.analyze_phase_well_spindle",
			"item_id": "item.phase_well_warp_sheet"
		},
		{
			"quest_id": "quest.refine_weft_bundle",
			"item_id": "item.phase_well_tension_rib"
		},
		{
			"quest_id": "quest.refine_weft_bundle",
			"item_id": "item.phase_well_shuttle"
		},
		{
			"quest_id": "quest.analyze_phase_well_weave_core",
			"item_id": "item.phase_well_pattern_sheet"
		},
		{
			"quest_id": "quest.refine_selvedge_strip",
			"item_id": "item.phase_well_frame_rib"
		},
		{
			"quest_id": "quest.refine_selvedge_strip",
			"item_id": "item.phase_well_frame_key"
		},
		{
			"quest_id": "quest.analyze_phase_well_knot_core",
			"item_id": "item.phase_well_tether_sheet"
		},
		{
			"quest_id": "quest.refine_tether_fiber",
			"item_id": "item.phase_well_tether_rib"
		},
		{
			"quest_id": "quest.refine_tether_fiber",
			"item_id": "item.phase_well_tether_spike"
		},
		{
			"quest_id": "quest.analyze_phase_well_anchor_core",
			"item_id": "item.phase_well_return_sheet"
		},
		{
			"quest_id": "quest.refine_anchor_core_dust",
			"item_id": "item.anchor_field_filter"
		},
		{
			"quest_id": "quest.refine_anchor_core_dust",
			"item_id": "item.phase_well_anchor_stake"
		},
		{
			"quest_id": "quest.analyze_phase_well_echo_shard",
			"item_id": "item.phase_well_stability_readout"
		}
	]:
		var quest_id := String(recovery.get("quest_id", ""))
		var item_id := String(recovery.get("item_id", ""))
		if not world_state.quest_state.has_active_quest(quest_id):
			continue
		if world_state.quest_state.get_objective_progress(quest_id, "craft_item", item_id) >= 1.0:
			continue
		if not character_state.inventory.has_ref(item_id, 1):
			continue
		updates.append(_objective_set_update(quest_id, "craft_item", item_id, 1))
	return updates


func _activate_missing_outer_ring_followup(world_state: WorldState) -> bool:
	if not world_state.quest_state.active_quest_ids.is_empty():
		return false
	if not world_state.quest_state.has_completed_quest("quest.secure_outer_ring_signal"):
		return false
	if world_state.quest_state.has_completed_quest("quest.salvage_signal_echo"):
		return false
	if world_state.quest_state.has_active_quest("quest.salvage_signal_echo"):
		return false
	world_state.quest_state.activate_quest("quest.salvage_signal_echo")
	return true


func _activate_missing_deep_ruin_followup(world_state: WorldState) -> bool:
	if not world_state.quest_state.active_quest_ids.is_empty():
		return false
	if not world_state.quest_state.has_completed_quest("quest.analyze_deep_signal"):
		return false
	if world_state.quest_state.has_completed_quest("quest.unlock_deep_ruin_entrance"):
		return false
	if world_state.quest_state.has_active_quest("quest.unlock_deep_ruin_entrance"):
		return false
	world_state.quest_state.activate_quest("quest.unlock_deep_ruin_entrance")
	return true


func _activate_missing_second_deep_followup(world_state: WorldState) -> bool:
	if not world_state.quest_state.active_quest_ids.is_empty():
		return false
	if not world_state.quest_state.has_completed_quest("quest.unlock_deep_ruin_cache"):
		return false
	if not world_state.quest_state.has_completed_quest("quest.analyze_deep_core"):
		if world_state.quest_state.has_active_quest("quest.analyze_deep_core"):
			return false
		world_state.quest_state.activate_quest("quest.analyze_deep_core")
		return true
	if not world_state.quest_state.has_completed_quest("quest.activate_deep_array"):
		if world_state.quest_state.has_active_quest("quest.activate_deep_array"):
			return false
		world_state.quest_state.activate_quest("quest.activate_deep_array")
		return true
	if world_state.quest_state.has_completed_quest("quest.assemble_deep_signal_matrix"):
		if world_state.quest_state.has_completed_quest("quest.deploy_phase_relay_anchor"):
			return false
		if world_state.quest_state.has_active_quest("quest.deploy_phase_relay_anchor"):
			return false
		world_state.quest_state.activate_quest("quest.deploy_phase_relay_anchor")
		return true
	if world_state.quest_state.has_active_quest("quest.assemble_deep_signal_matrix"):
		return false
	world_state.quest_state.activate_quest("quest.assemble_deep_signal_matrix")
	return true


func _restore_missing_phase_relay_anchor(world_state: WorldState) -> bool:
	if not world_state.quest_state.has_completed_quest("quest.deploy_phase_relay_anchor"):
		return false
	if world_state.has_active_phase_relay_anchor():
		return false
	world_state.set_active_phase_relay_anchor(_get_default_phase_relay_anchor_id(world_state))
	return true


func _restore_missing_deployed_phase_relay_anchors(world_state: WorldState) -> bool:
	if not world_state.quest_state.has_completed_quest("quest.deploy_phase_relay_anchor"):
		return false
	var changed := false
	if world_state.has_active_phase_relay_anchor():
		var active_anchor_id := world_state.active_phase_relay_anchor_id
		if not world_state.has_deployed_phase_relay_anchor(active_anchor_id):
			world_state.add_deployed_phase_relay_anchor(active_anchor_id)
			changed = true
	if not world_state.has_deployed_phase_relay_anchor("map_object_instance.phase_return_anchor"):
		world_state.add_deployed_phase_relay_anchor("map_object_instance.phase_return_anchor")
		changed = true
	if world_state.active_phase_relay_anchor_id == "map_object_instance.phase_return_anchor_chamber":
		if not world_state.has_deployed_phase_relay_anchor("map_object_instance.phase_return_anchor_chamber"):
			world_state.add_deployed_phase_relay_anchor("map_object_instance.phase_return_anchor_chamber")
			changed = true
	return changed


func _restore_missing_inner_fault_analysis_unlock(world_state: WorldState) -> bool:
	if not world_state.quest_state.has_completed_quest("quest.inspect_phase_fault_spire"):
		return false
	if world_state.quest_state.unlocked_effects.has("recipe.inner_fault_analysis"):
		return false
	world_state.quest_state.unlock_effect("recipe.inner_fault_analysis")
	return true


func _restore_missing_phase_well_locator_analysis_unlock(world_state: WorldState) -> bool:
	if not world_state.quest_state.has_completed_quest("quest.unlock_phase_well"):
		return false
	if world_state.quest_state.unlocked_effects.has("recipe.phase_well_locator_analysis"):
		return false
	world_state.quest_state.unlock_effect("recipe.phase_well_locator_analysis")
	return true


func _restore_missing_phase_well_core_analysis_unlock(world_state: WorldState) -> bool:
	if not world_state.quest_state.has_completed_quest("quest.inspect_inner_phase_well"):
		return false
	if world_state.quest_state.unlocked_effects.has("recipe.phase_well_core_analysis"):
		return false
	world_state.quest_state.unlock_effect("recipe.phase_well_core_analysis")
	return true


func _restore_missing_phase_well_heart_analysis_unlock(world_state: WorldState) -> bool:
	if not world_state.quest_state.has_completed_quest("quest.inspect_phase_well_sink"):
		return false
	if world_state.quest_state.unlocked_effects.has("recipe.phase_well_heart_analysis"):
		return false
	world_state.quest_state.unlock_effect("recipe.phase_well_heart_analysis")
	return true


func _restore_missing_phase_well_spindle_analysis_unlock(world_state: WorldState) -> bool:
	if not world_state.quest_state.has_completed_quest("quest.inspect_phase_well_chamber"):
		return false
	if world_state.quest_state.unlocked_effects.has("recipe.phase_well_spindle_analysis"):
		return false
	world_state.quest_state.unlock_effect("recipe.phase_well_spindle_analysis")
	return true


func _restore_missing_phase_well_weave_core_analysis_unlock(world_state: WorldState) -> bool:
	if not world_state.quest_state.has_completed_quest("quest.inspect_phase_well_loom"):
		return false
	if world_state.quest_state.unlocked_effects.has("recipe.phase_well_weave_core_analysis"):
		return false
	world_state.quest_state.unlock_effect("recipe.phase_well_weave_core_analysis")
	return true


func _restore_missing_phase_well_weave_core_reward(character_state: CharacterState, world_state: WorldState) -> bool:
	if not world_state.quest_state.has_completed_quest("quest.inspect_phase_well_loom"):
		return false
	if world_state.quest_state.has_completed_quest("quest.analyze_phase_well_weave_core"):
		return false
	if character_state.inventory.has_ref("item.phase_well_weave_core", 1):
		return false
	if character_state.inventory.has_ref("item.phase_well_pattern_sheet", 1):
		return false
	character_state.inventory.add_ref("item.phase_well_weave_core", 1)
	return true


func _restore_missing_phase_well_knot_core_analysis_unlock(world_state: WorldState) -> bool:
	if not world_state.quest_state.has_completed_quest("quest.inspect_phase_well_frame"):
		return false
	if world_state.quest_state.unlocked_effects.has("recipe.phase_well_knot_core_analysis"):
		return false
	world_state.quest_state.unlock_effect("recipe.phase_well_knot_core_analysis")
	return true


func _restore_missing_phase_well_anchor_core_analysis_unlock(world_state: WorldState) -> bool:
	if not world_state.quest_state.has_completed_quest("quest.inspect_phase_well_tether"):
		return false
	if world_state.quest_state.unlocked_effects.has("recipe.phase_well_anchor_core_analysis"):
		return false
	world_state.quest_state.unlock_effect("recipe.phase_well_anchor_core_analysis")
	return true


func _restore_missing_phase_well_knot_core_reward(character_state: CharacterState, world_state: WorldState) -> bool:
	if not world_state.quest_state.has_completed_quest("quest.inspect_phase_well_frame"):
		return false
	if world_state.quest_state.has_completed_quest("quest.analyze_phase_well_knot_core"):
		return false
	if character_state.inventory.has_ref("item.phase_well_knot_core", 1):
		return false
	if character_state.inventory.has_ref("item.phase_well_tether_sheet", 1):
		return false
	character_state.inventory.add_ref("item.phase_well_knot_core", 1)
	return true


func _restore_missing_phase_well_anchor_core_reward(character_state: CharacterState, world_state: WorldState) -> bool:
	if not world_state.quest_state.has_completed_quest("quest.inspect_phase_well_tether"):
		return false
	if world_state.quest_state.has_completed_quest("quest.analyze_phase_well_anchor_core"):
		return false
	for item_id in [
		"item.phase_well_anchor_core",
		"item.phase_well_return_sheet",
		"item.anchor_core_dust",
		"item.anchor_field_filter",
		"item.phase_well_anchor_stake",
		"item.phase_well_echo_shard"
	]:
		if character_state.inventory.has_ref(item_id, 1):
			return false
	character_state.inventory.add_ref("item.phase_well_anchor_core", 1)
	return true


func _activate_missing_post_phase_well_loom_followup(world_state: WorldState) -> bool:
	if not world_state.quest_state.active_quest_ids.is_empty():
		return false
	if not world_state.quest_state.has_completed_quest("quest.inspect_phase_well_loom"):
		return false
	for quest_id in [
		"quest.analyze_phase_well_weave_core",
		"quest.collect_selvedge_strip",
		"quest.refine_selvedge_strip",
		"quest.inspect_phase_well_frame"
	]:
		if world_state.quest_state.has_completed_quest(quest_id):
			continue
		if world_state.quest_state.has_active_quest(quest_id):
			return false
		world_state.quest_state.activate_quest(quest_id)
		return true
	return false


func _activate_missing_post_phase_well_frame_followup(world_state: WorldState) -> bool:
	if not world_state.quest_state.active_quest_ids.is_empty():
		return false
	if not world_state.quest_state.has_completed_quest("quest.inspect_phase_well_frame"):
		return false
	for quest_id in [
		"quest.analyze_phase_well_knot_core",
		"quest.collect_tether_fiber",
		"quest.refine_tether_fiber",
		"quest.inspect_phase_well_tether"
	]:
		if world_state.quest_state.has_completed_quest(quest_id):
			continue
		if world_state.quest_state.has_active_quest(quest_id):
			return false
		world_state.quest_state.activate_quest(quest_id)
		return true
	return false


func _activate_missing_post_phase_well_tether_followup(world_state: WorldState) -> bool:
	if not world_state.quest_state.active_quest_ids.is_empty():
		return false
	if not world_state.quest_state.has_completed_quest("quest.inspect_phase_well_tether"):
		return false
	for quest_id in [
		"quest.analyze_phase_well_anchor_core",
		"quest.refine_anchor_core_dust",
		"quest.stabilize_phase_well_anchor_field"
	]:
		if world_state.quest_state.has_completed_quest(quest_id):
			continue
		if world_state.quest_state.has_active_quest(quest_id):
			return false
		world_state.quest_state.activate_quest(quest_id)
		return true
	return false


func _activate_missing_post_phase_well_readout_followup(world_state: WorldState) -> bool:
	if not world_state.quest_state.active_quest_ids.is_empty():
		return false
	if not world_state.quest_state.has_completed_quest("quest.analyze_phase_well_echo_shard"):
		return false
	if world_state.quest_state.has_completed_quest("quest.calibrate_phase_well_stability_window"):
		return false
	if world_state.quest_state.has_active_quest("quest.calibrate_phase_well_stability_window"):
		return false
	world_state.quest_state.activate_quest("quest.calibrate_phase_well_stability_window")
	return true


func _activate_missing_post_phase_well_chamber_followup(world_state: WorldState) -> bool:
	if not world_state.quest_state.active_quest_ids.is_empty():
		return false
	if not world_state.quest_state.has_completed_quest("quest.inspect_phase_well_chamber"):
		return false
	for quest_id in [
		"quest.analyze_phase_well_spindle",
		"quest.collect_weft_bundle",
		"quest.refine_weft_bundle",
		"quest.inspect_phase_well_loom"
	]:
		if world_state.quest_state.has_completed_quest(quest_id):
			continue
		if world_state.quest_state.has_active_quest(quest_id):
			return false
		world_state.quest_state.activate_quest(quest_id)
		return true
	return false


func _activate_missing_post_phase_well_sink_followup(world_state: WorldState) -> bool:
	if not world_state.quest_state.active_quest_ids.is_empty():
		return false
	if not world_state.quest_state.has_completed_quest("quest.inspect_phase_well_sink"):
		return false
	for quest_id in [
		"quest.analyze_phase_well_heart",
		"quest.collect_heart_spine",
		"quest.refine_heart_spine",
		"quest.inspect_phase_well_chamber",
		"quest.analyze_phase_well_spindle",
		"quest.collect_weft_bundle",
		"quest.refine_weft_bundle",
		"quest.inspect_phase_well_loom",
		"quest.analyze_phase_well_weave_core",
		"quest.collect_selvedge_strip",
		"quest.refine_selvedge_strip",
		"quest.inspect_phase_well_frame",
		"quest.analyze_phase_well_knot_core",
		"quest.collect_tether_fiber",
		"quest.refine_tether_fiber",
		"quest.inspect_phase_well_tether",
		"quest.analyze_phase_well_anchor_core",
		"quest.refine_anchor_core_dust",
		"quest.stabilize_phase_well_anchor_field",
		"quest.analyze_phase_well_echo_shard",
		"quest.calibrate_phase_well_stability_window"
	]:
		if world_state.quest_state.has_completed_quest(quest_id):
			continue
		if world_state.quest_state.has_active_quest(quest_id):
			return false
		world_state.quest_state.activate_quest(quest_id)
		return true
	return false


func _activate_missing_post_phase_relay_followup(world_state: WorldState) -> bool:
	if not world_state.quest_state.active_quest_ids.is_empty():
		return false
	if not world_state.quest_state.has_completed_quest("quest.deploy_phase_relay_anchor"):
		return false
	for quest_id in [
		"quest.reenter_phase_frontline",
		"quest.trace_phase_splinters",
		"quest.refine_phase_splinters",
		"quest.inspect_phase_fault_spire",
		"quest.analyze_inner_fault_trace",
		"quest.collect_fault_residue",
		"quest.refine_fault_residue",
		"quest.unlock_phase_well",
		"quest.analyze_phase_well_locator",
		"quest.collect_well_flux",
		"quest.refine_well_flux",
		"quest.inspect_inner_phase_well",
		"quest.analyze_phase_well_core",
		"quest.collect_well_ash",
		"quest.refine_well_ash",
		"quest.inspect_phase_well_sink",
		"quest.analyze_phase_well_heart",
		"quest.collect_heart_spine",
		"quest.refine_heart_spine",
		"quest.inspect_phase_well_chamber",
		"quest.analyze_phase_well_spindle",
		"quest.collect_weft_bundle",
		"quest.refine_weft_bundle",
		"quest.inspect_phase_well_loom",
		"quest.analyze_phase_well_weave_core",
		"quest.collect_selvedge_strip",
		"quest.refine_selvedge_strip",
		"quest.inspect_phase_well_frame",
		"quest.analyze_phase_well_knot_core",
		"quest.collect_tether_fiber",
		"quest.refine_tether_fiber",
		"quest.inspect_phase_well_tether",
		"quest.analyze_phase_well_anchor_core",
		"quest.refine_anchor_core_dust",
		"quest.stabilize_phase_well_anchor_field",
		"quest.analyze_phase_well_echo_shard",
		"quest.calibrate_phase_well_stability_window"
	]:
		if world_state.quest_state.has_completed_quest(quest_id):
			continue
		if world_state.quest_state.has_active_quest(quest_id):
			return false
		world_state.quest_state.activate_quest(quest_id)
		return true
	return false


func _get_default_phase_relay_anchor_id(world_state: WorldState) -> String:
	for quest_id in [
		"quest.inspect_phase_well_loom",
		"quest.refine_weft_bundle",
		"quest.collect_weft_bundle",
		"quest.analyze_phase_well_spindle",
		"quest.inspect_phase_well_chamber",
		"quest.refine_heart_spine",
		"quest.collect_heart_spine"
	]:
		if world_state.quest_state.has_completed_quest(quest_id) or world_state.quest_state.has_active_quest(quest_id):
			return "map_object_instance.phase_return_anchor_chamber"
	return "map_object_instance.phase_return_anchor"


func _objective_set_update(quest_id: String, objective_type: String, target_id: String, amount: float) -> Dictionary:
	return {
		"mode": "set",
		"quest_id": quest_id,
		"objective_type": objective_type,
		"target_id": target_id,
		"amount": amount
	}


func _empty_result(accepted: bool) -> Dictionary:
	return {
		"accepted": accepted,
		"log_messages": [],
		"completion_feedbacks": []
	}
