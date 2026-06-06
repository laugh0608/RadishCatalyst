extends RefCounted
class_name InteractableVisualRefresher


func refresh_visual_state(
	interactable: PrototypeInteractable,
	world_state: WorldState,
	phase_well_frontier_runtime: PhaseWellFrontierRuntime
) -> Dictionary:
	var object_state := world_state.get_map_object(interactable.instance_id)
	var is_processed := _is_processed(interactable, object_state)
	if interactable.interaction_type == "build" and is_processed:
		interactable.set_built_visual(String(object_state.get("built_definition_id", interactable.definition_id)))
		return _result(true, true)
	if BaseActionDispatchPlan.is_plan_candidate_console_ready(interactable.definition_id, world_state):
		is_processed = false
	if interactable.single_use:
		interactable.consumed = is_processed

	var special_result := _apply_special_visual(interactable, world_state, phase_well_frontier_runtime)
	if not special_result.is_empty():
		return special_result

	if is_processed and interactable.set_processed_visual():
		return _result(true, true)
	if not is_processed:
		interactable.set_default_visual()
	return {}


func _is_processed(interactable: PrototypeInteractable, object_state: Dictionary) -> bool:
	if interactable.interaction_type == "gather":
		return bool(object_state.get("is_gathered", false))
	if interactable.interaction_type == "sample":
		return bool(object_state.get("is_sampled", false))
	if interactable.interaction_type == "inspect":
		return bool(object_state.get("is_sampled", false))
	if interactable.interaction_type == "clear":
		return bool(object_state.get("is_cleared", false))
	if interactable.interaction_type == "build":
		return bool(object_state.get("is_built", false))
	return false


func _apply_special_visual(
	interactable: PrototypeInteractable,
	world_state: WorldState,
	phase_well_frontier_runtime: PhaseWellFrontierRuntime
) -> Dictionary:
	if interactable.interaction_type == "outpost_core":
		if world_state.quest_state.has_completed_quest("quest.restore_outpost"):
			interactable.set_restored_outpost_core_visual()
			return _result(true, false)
		interactable.set_default_visual()
		return {}
	if interactable.definition_id == "map_object.ruin_gate":
		return _apply_completed_visual(
			interactable,
			world_state,
			"quest.unlock_ruin_signal",
			"set_confirmed_ruin_signal_visual"
		)
	if interactable.definition_id == "map_object.outer_ring_barrier":
		return _apply_completed_visual(
			interactable,
			world_state,
			"quest.stabilize_outer_ring_barrier",
			"set_stabilized_barrier_visual"
		)
	if interactable.definition_id == "map_object.outer_ring_console":
		return _apply_completed_visual(
			interactable,
			world_state,
			"quest.secure_outer_ring_signal",
			"set_secured_console_visual"
		)
	if interactable.definition_id == "map_object.signal_echo_cache":
		return _apply_completed_visual(
			interactable,
			world_state,
			"quest.salvage_signal_echo",
			"set_recovered_signal_echo_visual"
		)
	if interactable.definition_id == "map_object.deep_ruin_door":
		return _apply_completed_visual(
			interactable,
			world_state,
			"quest.unlock_deep_ruin_entrance",
			"set_opened_deep_ruin_door_visual"
		)
	if interactable.definition_id == "map_object.deep_ruin_latch":
		return _apply_completed_visual(
			interactable,
			world_state,
			"quest.unlock_deep_ruin_cache",
			"set_overridden_deep_ruin_latch_visual"
		)
	if interactable.definition_id == "map_object.deep_signal_array":
		return _apply_completed_visual(
			interactable,
			world_state,
			"quest.activate_deep_array",
			"set_activated_deep_signal_array_visual"
		)
	if interactable.definition_id == "map_object.phase_return_anchor":
		if world_state.is_active_phase_relay_anchor(interactable.instance_id):
			interactable.set_deployed_phase_return_anchor_visual(true)
			return _result(true, false)
		if world_state.has_deployed_phase_relay_anchor(interactable.instance_id):
			interactable.set_deployed_phase_return_anchor_visual(false)
			return _result(true, false)
		interactable.set_default_visual()
		return {}
	if interactable.definition_id == "map_object.phase_relay_pad":
		if world_state.has_active_phase_relay_anchor():
			interactable.set_ready_phase_relay_pad_visual(
				world_state.get_deployed_phase_relay_anchor_count() > 1
			)
			return _result(true, false)
		interactable.set_default_visual()
		return {}
	if interactable.definition_id == "map_object.phase_fault_spire":
		return _apply_completed_visual(
			interactable,
			world_state,
			"quest.inspect_phase_fault_spire",
			"set_tuned_phase_fault_spire_visual"
		)
	if interactable.definition_id == "map_object.phase_well_lock":
		return _apply_completed_visual(
			interactable,
			world_state,
			"quest.unlock_phase_well",
			"set_stabilized_phase_well_lock_visual"
		)
	if interactable.definition_id == "map_object.inner_phase_well":
		return _apply_completed_visual(
			interactable,
			world_state,
			"quest.inspect_inner_phase_well",
			"set_stabilized_inner_phase_well_visual"
		)
	if interactable.definition_id == "map_object.phase_well_sink":
		return _apply_completed_visual(
			interactable,
			world_state,
			"quest.inspect_phase_well_sink",
			"set_stabilized_phase_well_sink_visual"
		)
	if interactable.definition_id == "map_object.phase_well_chamber":
		return _apply_completed_visual(
			interactable,
			world_state,
			"quest.inspect_phase_well_chamber",
			"set_stabilized_phase_well_chamber_visual"
		)
	if interactable.definition_id == "map_object.phase_well_loom":
		return _apply_completed_visual(
			interactable,
			world_state,
			"quest.inspect_phase_well_loom",
			"set_stabilized_phase_well_loom_visual"
		)
	if interactable.definition_id == "map_object.phase_well_frame":
		return _apply_completed_visual(
			interactable,
			world_state,
			"quest.inspect_phase_well_frame",
			"set_stabilized_phase_well_frame_visual"
		)
	if interactable.definition_id == "map_object.phase_well_tether":
		return _apply_completed_visual(
			interactable,
			world_state,
			"quest.inspect_phase_well_tether",
			"set_stabilized_phase_well_tether_visual"
		)
	if interactable.definition_id == "map_object.phase_well_anchor_field":
		_apply_anchor_field_visual(interactable, world_state, phase_well_frontier_runtime)
		return {}
	if (
		phase_well_frontier_runtime != null
		and phase_well_frontier_runtime.is_stability_calibration_node(interactable.definition_id)
	):
		_apply_stability_calibration_visual(interactable, world_state, phase_well_frontier_runtime)
		return {}
	if (
		interactable.definition_id == BaseActionDispatchPlan.FRONTLINE_ACTION_CONSOLE_ID
		and BaseActionDispatchPlan.is_frontline_action_console_ready(world_state)
	):
		interactable.set_default_visual()
		return {}
	return {}


func _apply_completed_visual(
	interactable: PrototypeInteractable,
	world_state: WorldState,
	quest_id: String,
	visual_method: StringName
) -> Dictionary:
	if world_state.quest_state.has_completed_quest(quest_id):
		interactable.call(visual_method)
		return _result(true, true)
	interactable.set_default_visual()
	return {}


func _apply_anchor_field_visual(
	interactable: PrototypeInteractable,
	world_state: WorldState,
	phase_well_frontier_runtime: PhaseWellFrontierRuntime
) -> void:
	if phase_well_frontier_runtime == null:
		interactable.set_default_visual()
	elif phase_well_frontier_runtime.is_anchor_field_stabilized(world_state):
		interactable.set_stabilized_phase_well_anchor_field_visual()
	elif phase_well_frontier_runtime.is_anchor_field_pressure_cleared(world_state):
		interactable.set_ready_phase_well_anchor_field_visual()
	elif phase_well_frontier_runtime.is_anchor_field_deployed(world_state):
		interactable.set_deployed_phase_well_anchor_field_visual()
	else:
		interactable.set_default_visual()


func _apply_stability_calibration_visual(
	interactable: PrototypeInteractable,
	world_state: WorldState,
	phase_well_frontier_runtime: PhaseWellFrontierRuntime
) -> void:
	if phase_well_frontier_runtime.is_stability_node_calibrated(
		world_state,
		interactable.instance_id,
		interactable.definition_id
	):
		interactable.set_calibrated_stability_node_visual()
	elif phase_well_frontier_runtime.is_stability_calibration_ready(world_state, interactable.definition_id):
		interactable.set_ready_stability_calibration_visual()
	else:
		interactable.set_default_visual()


func _result(skip_enable: bool, clear_current: bool) -> Dictionary:
	return {
		"skip_enable": skip_enable,
		"clear_current": clear_current
	}
