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
	if _restore_missing_phase_well_heart_analysis_unlock(world_state):
		log_messages.append("旧进度已接入：相位井心核解析配方已补齐。")
	if _restore_missing_phase_well_core_analysis_unlock(world_state):
		log_messages.append("旧进度已接入：相位井芯样本解析配方已补齐。")
	if _restore_missing_phase_well_locator_analysis_unlock(world_state):
		log_messages.append("旧进度已接入：相位井定位器解析配方已补齐。")
	if _restore_missing_inner_fault_analysis_unlock(world_state):
		log_messages.append("旧进度已接入：内层故障轨迹分析配方已补齐。")
	if _restore_missing_phase_relay_anchor(world_state):
		log_messages.append("旧进度已接入：前线回传锚点已按固定深段落点恢复在线。")
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
	world_state.set_active_phase_relay_anchor("map_object_instance.phase_return_anchor")
	return true


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


func _activate_missing_post_phase_well_sink_followup(world_state: WorldState) -> bool:
	if not world_state.quest_state.active_quest_ids.is_empty():
		return false
	if not world_state.quest_state.has_completed_quest("quest.inspect_phase_well_sink"):
		return false
	for quest_id in [
		"quest.analyze_phase_well_heart",
		"quest.collect_heart_spine",
		"quest.refine_heart_spine",
		"quest.assemble_phase_well_shunt",
		"quest.inspect_phase_well_chamber"
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
		"quest.tune_relay_lens",
		"quest.inspect_phase_fault_spire",
		"quest.analyze_inner_fault_trace",
		"quest.collect_fault_residue",
		"quest.refine_fault_residue",
		"quest.assemble_phase_well_key",
		"quest.unlock_phase_well",
		"quest.analyze_phase_well_locator",
		"quest.collect_well_flux",
		"quest.refine_well_flux",
		"quest.assemble_phase_well_probe",
		"quest.inspect_inner_phase_well",
		"quest.analyze_phase_well_core",
		"quest.collect_well_ash",
		"quest.refine_well_ash",
		"quest.assemble_phase_well_pike",
		"quest.inspect_phase_well_sink",
		"quest.analyze_phase_well_heart",
		"quest.collect_heart_spine",
		"quest.refine_heart_spine",
		"quest.assemble_phase_well_shunt",
		"quest.inspect_phase_well_chamber"
	]:
		if world_state.quest_state.has_completed_quest(quest_id):
			continue
		if world_state.quest_state.has_active_quest(quest_id):
			return false
		world_state.quest_state.activate_quest(quest_id)
		return true
	return false


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
