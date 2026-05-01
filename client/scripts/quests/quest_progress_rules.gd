extends RefCounted
class_name QuestProgressRules

var data_registry: DataRegistry


func _init(registry: DataRegistry) -> void:
	data_registry = registry


func set_active_objective_progress(
	quest_state: QuestState,
	quest_id: String,
	objective_type: String,
	target_id: String,
	amount: float
) -> void:
	if not quest_state.has_active_quest(quest_id):
		return
	var required_amount := get_objective_required_amount(quest_id, objective_type, target_id)
	if required_amount < 0.0:
		return
	quest_state.set_objective_progress(quest_id, objective_type, target_id, min(amount, required_amount))


func add_active_objective_progress(
	quest_state: QuestState,
	quest_id: String,
	objective_type: String,
	target_id: String,
	amount: float
) -> void:
	if not quest_state.has_active_quest(quest_id):
		return
	var required_amount := get_objective_required_amount(quest_id, objective_type, target_id)
	if required_amount < 0.0:
		return
	var current_amount := quest_state.get_objective_progress(quest_id, objective_type, target_id)
	quest_state.set_objective_progress(quest_id, objective_type, target_id, min(current_amount + amount, required_amount))


func are_objectives_complete(quest_state: QuestState, quest_id: String) -> bool:
	var quest := data_registry.get_definition(quest_id)
	for objective in quest.get("objectives", []):
		if not (objective is Dictionary):
			continue

		var objective_type := String(objective.get("type", ""))
		var target_id := String(objective.get("target_id", ""))
		var required_amount := float(objective.get("amount", 1.0))
		var current_amount := quest_state.get_objective_progress(quest_id, objective_type, target_id)
		if current_amount < required_amount:
			return false

	return true


func get_objective_required_amount(quest_id: String, objective_type: String, target_id: String) -> float:
	var quest := data_registry.get_definition(quest_id)
	for objective in quest.get("objectives", []):
		if not (objective is Dictionary):
			continue
		if String(objective.get("type", "")) == objective_type and String(objective.get("target_id", "")) == target_id:
			return float(objective.get("amount", 1.0))
	return -1.0
