extends RefCounted

var host


func _init(check_host) -> void:
	host = check_host


func run() -> void:
	_check_deep_field_interaction_updates()


func _check_deep_field_interaction_updates() -> void:
	var quest_state := QuestState.create_default()
	host._mark_restore_outpost_completed(quest_state)
	for spec in [
		["map_object.phase_splinter_resonance_node", "inspect", "quest.trace_phase_splinters", "inspect", "map_object.phase_splinter_resonance_node", "phase splinter resonance inspect update"],
		["map_object.fault_residue_pulse_node", "inspect", "quest.collect_fault_residue", "inspect", "map_object.fault_residue_pulse_node", "fault residue pulse inspect update"],
		["map_object.well_flux_pressure_vent", "inspect", "quest.collect_well_flux", "inspect", "map_object.well_flux_pressure_vent", "well flux pressure vent inspect update"],
		["map_object.well_ash_crust_blocker", "clear", "quest.collect_well_ash", "clear", "map_object.well_ash_crust_blocker", "well ash crust clear update"]
	]:
		var updates: Array[Dictionary] = host.event_rules.get_interaction_objective_updates(
			{
				"definition_id": String(spec[0]),
				"interaction_type": String(spec[1])
			},
			{},
			quest_state
		)
		host._expect_update(updates, "add", String(spec[2]), String(spec[3]), String(spec[4]), 1.0, String(spec[5]))
