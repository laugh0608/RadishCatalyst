extends RefCounted
class_name QuestCompletionRules

var data_registry: DataRegistry
var progress_rules: QuestProgressRules


func _init(registry: DataRegistry, quest_progress_rules: QuestProgressRules) -> void:
	data_registry = registry
	progress_rules = quest_progress_rules


func try_complete_quest(quest_state: QuestState, quest_id: String) -> Dictionary:
	if not quest_state.has_active_quest(quest_id):
		return _not_completed()
	if not progress_rules.are_objectives_complete(quest_state, quest_id):
		return _not_completed()

	var quest := data_registry.get_definition(quest_id)
	quest_state.complete_quest(quest_id)
	_apply_mutually_exclusive_choice_cleanup(quest_state, quest_id)
	for effect_id in quest.get("unlock_effects", []):
		quest_state.unlock_effect(String(effect_id))
	for next_quest_id in quest.get("next_quest_ids", []):
		quest_state.activate_quest(String(next_quest_id))

	return {
		"completed": true,
		"quest_id": quest_id,
		"rewards": quest.get("rewards", []),
		"unlock_effects": quest.get("unlock_effects", []),
		"next_quest_ids": quest.get("next_quest_ids", [])
	}


func _not_completed() -> Dictionary:
	return {
		"completed": false
	}


func _apply_mutually_exclusive_choice_cleanup(quest_state: QuestState, quest_id: String) -> void:
	match quest_id:
		"quest.choose_steady_supply_action":
			quest_state.active_quest_ids.erase("quest.choose_phase_survey_action")
			quest_state.active_quest_ids.erase("quest.choose_pressure_clearance_action")
		"quest.choose_phase_survey_action":
			quest_state.active_quest_ids.erase("quest.choose_steady_supply_action")
			quest_state.active_quest_ids.erase("quest.choose_pressure_clearance_action")
		"quest.choose_pressure_clearance_action":
			quest_state.active_quest_ids.erase("quest.choose_steady_supply_action")
			quest_state.active_quest_ids.erase("quest.choose_phase_survey_action")
