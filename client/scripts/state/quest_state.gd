extends RefCounted
class_name QuestState

var active_quest_ids: Array[String] = ["quest.restore_outpost"]
var completed_quest_ids: Array[String] = []
var objective_progress: Dictionary = {}
var unlocked_effects: Array[String] = ["region.outpost_platform"]


static func create_default() -> QuestState:
	return QuestState.new()


func has_active_quest(quest_id: String) -> bool:
	return active_quest_ids.has(quest_id)


func has_completed_quest(quest_id: String) -> bool:
	return completed_quest_ids.has(quest_id)


func activate_quest(quest_id: String) -> void:
	if active_quest_ids.has(quest_id) or completed_quest_ids.has(quest_id):
		return
	active_quest_ids.append(quest_id)


func complete_quest(quest_id: String) -> void:
	active_quest_ids.erase(quest_id)
	if not completed_quest_ids.has(quest_id):
		completed_quest_ids.append(quest_id)


func unlock_effect(effect_id: String) -> void:
	if not unlocked_effects.has(effect_id):
		unlocked_effects.append(effect_id)


func set_objective_progress(quest_id: String, objective_type: String, target_id: String, amount: float) -> void:
	objective_progress[_get_objective_key(quest_id, objective_type, target_id)] = amount


func add_objective_progress(quest_id: String, objective_type: String, target_id: String, amount: float) -> void:
	var current_amount := get_objective_progress(quest_id, objective_type, target_id)
	set_objective_progress(quest_id, objective_type, target_id, current_amount + amount)


func get_objective_progress(quest_id: String, objective_type: String, target_id: String) -> float:
	return float(objective_progress.get(_get_objective_key(quest_id, objective_type, target_id), 0.0))


func to_dict() -> Dictionary:
	return {
		"active_quest_ids": active_quest_ids.duplicate(true),
		"completed_quest_ids": completed_quest_ids.duplicate(true),
		"objective_progress": objective_progress.duplicate(true),
		"unlocked_effects": unlocked_effects.duplicate(true)
	}


static func from_dict(data: Dictionary) -> QuestState:
	var state := QuestState.new()
	state.active_quest_ids.assign(data.get("active_quest_ids", ["quest.restore_outpost"]))
	state.completed_quest_ids.assign(data.get("completed_quest_ids", []))
	state.objective_progress = data.get("objective_progress", {}).duplicate(true)
	state.unlocked_effects.assign(data.get("unlocked_effects", ["region.outpost_platform"]))
	return state


func _get_objective_key(quest_id: String, objective_type: String, target_id: String) -> String:
	return "%s|%s|%s" % [quest_id, objective_type, target_id]
