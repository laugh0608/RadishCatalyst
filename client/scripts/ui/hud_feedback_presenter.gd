extends RefCounted
class_name HudFeedbackPresenter


func show_evacuation_feedback(result: Dictionary, hud: PrototypeHud) -> void:
	var feedback := get_evacuation_feedback(result)
	if feedback.is_empty():
		return
	hud.show_evacuation_feedback(feedback)


func show_supply_feedback(result: Dictionary, hud: PrototypeHud) -> void:
	var feedback := get_supply_feedback(result)
	if feedback.is_empty():
		return
	hud.show_supply_feedback(feedback)


func get_evacuation_feedback(result: Dictionary) -> Dictionary:
	var feedback = result.get("evacuation_feedback", {})
	if feedback is Dictionary:
		return feedback
	return {}


func get_supply_feedback(result: Dictionary) -> Dictionary:
	var feedback = result.get("supply_feedback", {})
	if feedback is Dictionary:
		return feedback
	return {}
