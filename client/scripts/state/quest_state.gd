extends RefCounted
class_name QuestState

var active_quest_ids: Array[String] = ["quest.restore_outpost"]
var completed_quest_ids: Array[String] = []
var objective_progress: Dictionary = {}
var unlocked_effects: Array[String] = ["region.outpost_platform"]


static func create_default() -> QuestState:
	return QuestState.new()


func activate_quest(quest_id: String) -> void:
	if active_quest_ids.has(quest_id) or completed_quest_ids.has(quest_id):
		return
	active_quest_ids.append(quest_id)


func complete_quest(quest_id: String) -> void:
	active_quest_ids.erase(quest_id)
	if not completed_quest_ids.has(quest_id):
		completed_quest_ids.append(quest_id)


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
