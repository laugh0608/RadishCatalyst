extends RefCounted
class_name ProcessingSystem

var data_registry: DataRegistry


func _init(registry: DataRegistry) -> void:
	data_registry = registry


func process_recipe(recipe_id: String, character_state: CharacterState, world_state: WorldState) -> Dictionary:
	var recipe := data_registry.get_definition(recipe_id)
	if recipe.is_empty():
		return _failure("未知配方：%s。" % recipe_id, "加工未完成", "切换到已知配方，或检查静态数据定义。")

	var lock_message := _get_recipe_lock_message(recipe, world_state)
	if not lock_message.is_empty():
		return _failure(lock_message, "配方未解锁", "先完成当前任务目标，解锁该配方后再启动加工。")

	var structure_id := _get_required_structure_id(recipe, world_state)
	if structure_id.is_empty():
		return _failure(
			"需要先建造：%s。" % _get_display_name(String(recipe.get("required_building_id", ""))),
			"设备未就绪",
			"先完成建造点或处理点扩建，再回到设备启动加工。"
		)
	var structure: Dictionary = world_state.base_structures.get(structure_id, {})
	if String(structure.get("status", "idle")) == "in_progress":
		var busy_status := _format_in_progress_message(structure)
		var busy_feedback := DemoActionBlockerRecoveryFormatter.format_processing_busy_failure(
			_get_display_name(recipe_id),
			busy_status,
			_get_processing_wait_next_step()
		)
		return _failure_from_feedback(busy_status, busy_feedback)

	var missing_inputs := _get_missing_inputs(recipe, character_state.inventory)
	if not missing_inputs.is_empty():
		var missing_feedback := DemoActionBlockerRecoveryFormatter.format_processing_missing_input_failure(
			_get_display_name(recipe_id),
			missing_inputs,
			_format_missing_input_next_step(recipe, character_state.inventory)
		)
		return _failure(
			_format_missing_input_message(recipe, missing_inputs, character_state.inventory),
			String(missing_feedback.get("title", "原料不足")),
			String(missing_feedback.get("detail", ""))
		)

	_consume_refs(recipe.get("inputs", []), character_state.inventory)
	world_state.set_base_structure_status(structure_id, "in_progress", recipe_id)

	return {
		"success": true,
		"processing_started": true,
		"recipe_id": recipe_id,
		"structure_id": structure_id,
		"message": _format_processing_started_message(recipe, world_state),
		"success_feedback": _format_processing_started_feedback(recipe, world_state, character_state)
	}


func advance_processing(delta_seconds: float, character_state: CharacterState, world_state: WorldState) -> Array[Dictionary]:
	var completed_results: Array[Dictionary] = []
	if delta_seconds <= 0.0:
		return completed_results

	for structure_id in world_state.base_structures:
		var structure = world_state.base_structures[structure_id]
		if not structure is Dictionary:
			continue
		if String(structure.get("status", "idle")) != "in_progress":
			continue

		var recipe_id := String(structure.get("active_recipe_id", ""))
		var recipe := data_registry.get_definition(recipe_id)
		if recipe.is_empty():
			continue

		var duration := _get_recipe_duration(recipe)
		var progress_seconds := minf(float(structure.get("progress_seconds", 0.0)) + delta_seconds, duration)
		world_state.set_base_structure_progress(String(structure_id), progress_seconds)
		if progress_seconds < duration:
			continue

		_grant_refs(recipe.get("outputs", []), character_state.inventory)
		_grant_refs(recipe.get("byproducts", []), character_state.inventory)
		world_state.set_base_structure_status(String(structure_id), "completed", recipe_id)
		_apply_recipe_completion_side_effect(recipe_id, world_state)
		completed_results.append({
			"success": true,
			"completed_recipe_id": recipe_id,
			"structure_id": String(structure_id),
			"destination_text": _format_completion_destination(recipe),
			"next_step_text": _get_completion_next_step(recipe_id, world_state),
			"message": _format_completion_message(recipe, world_state),
			"success_feedback": _format_processing_completion_feedback(recipe, world_state, character_state)
		})

	return completed_results


func get_recipe_status(recipe_id: String, character_state: CharacterState, world_state: WorldState) -> Dictionary:
	var recipe := data_registry.get_definition(recipe_id)
	if recipe.is_empty():
		return {
			"can_process": false,
			"message": "未知配方：%s" % recipe_id,
			"inputs": "无",
			"outputs": "无",
			"byproducts": "",
			"duration": "0",
			"progress": "",
			"progress_ratio": 0.0
		}

	var missing_inputs := _get_missing_inputs(recipe, character_state.inventory)
	var lock_message := _get_recipe_lock_message(recipe, world_state)
	var structure_id := _get_required_structure_id(recipe, world_state)
	var missing_structure := ""
	if structure_id.is_empty():
		missing_structure = "需要先建造：%s。" % _get_display_name(String(recipe.get("required_building_id", "")))
	var required_structure: Dictionary = {}
	if not structure_id.is_empty():
		required_structure = world_state.base_structures.get(structure_id, {})

	var active_structure := _get_active_structure_for_building(String(recipe.get("required_building_id", "")), world_state)
	if not active_structure.is_empty():
		var active_recipe_id := String(active_structure.get("active_recipe_id", ""))
		var active_recipe := data_registry.get_definition(active_recipe_id)
		if active_recipe.is_empty():
			active_recipe = recipe
		return _recipe_status(
			active_recipe,
			false,
			_format_in_progress_message(active_structure),
			[],
			active_structure,
			required_structure,
			"",
			world_state,
			recipe_id
		)

	if not lock_message.is_empty():
		return _recipe_status(recipe, false, lock_message, missing_inputs, {}, required_structure, "", world_state)
	if not missing_structure.is_empty():
		return _recipe_status(recipe, false, missing_structure, missing_inputs, {}, required_structure, "", world_state)
	if not missing_inputs.is_empty():
		return _recipe_status(
			recipe,
			false,
			"缺少原料：%s。" % ", ".join(missing_inputs),
			missing_inputs,
			{},
			required_structure,
			_format_missing_input_supply_hint(recipe, character_state.inventory),
			world_state
		)

	return _recipe_status(recipe, true, "可加工。", [], {}, required_structure, "", world_state)


func get_recommended_recipe_id(
	interactable: PrototypeInteractable,
	character_state: CharacterState,
	world_state: WorldState
) -> String:
	if interactable == null or interactable.interaction_type != "process_recipe":
		return ""

	var active_quest_id := ""
	if not world_state.quest_state.active_quest_ids.is_empty():
		active_quest_id = String(world_state.quest_state.active_quest_ids[0])
	if (
		interactable.definition_id == "building.basic_reactor"
		and FieldOutfittingRuntime.should_process_logistics_materials(character_state, world_state)
	):
		return _select_if_available(interactable, "recipe.process_crystal_ore")
	if (
		interactable.definition_id == "building.pollution_filter"
		and CoreStabilizationPressureFormatter.should_process_logistics_maintenance_retest_residue(
			character_state,
			world_state
		)
	):
		return _select_if_available(interactable, "recipe.cleanse_residue")
	if active_quest_id.is_empty():
		var base_reentry_recipe_id := DemoRouteReturnAndBaseReentryFormatter.get_recommended_recipe_id_for_device(
			interactable.definition_id,
			character_state,
			world_state
		)
		if not base_reentry_recipe_id.is_empty():
			return _select_if_available(interactable, base_reentry_recipe_id)
	match active_quest_id:
		"quest.scout_crystal_field":
			return _select_if_available(interactable, "recipe.process_crystal_ore")
		"quest.calibrate_reactor":
			if world_state.quest_state.get_objective_progress(active_quest_id, "gather_item", "item.salvage_scrap") >= 4.0:
				return _select_if_available(interactable, "recipe.reactor_calibrator")
			return ""
		"quest.analyze_anomaly_sample":
			if world_state.quest_state.get_objective_progress(active_quest_id, "gather_item", "item.anomaly_residue") >= 2.0:
				return _select_if_available(interactable, "recipe.analyze_anomaly_sample")
			return ""
		"quest.make_filter_module":
			if not character_state.inventory.has_ref("item.filter_media", 1):
				return _select_if_available(interactable, "recipe.make_filter_media")
			return _select_if_available(interactable, "recipe.basic_filter_module")
		"quest.prepare_treatment_supplies":
			if world_state.quest_state.get_objective_progress(active_quest_id, "craft_item", "item.repair_gel") < 1.0:
				return _select_if_available(interactable, "recipe.repair_gel")
			return ""
		"quest.expand_treatment_point":
			var pending_foundations := maxi(0, 2 - world_state.count_base_structures("building.foundation_t1"))
			if _get_inventory_ref_amount("item.foundation_material", character_state.inventory) < pending_foundations:
				return _select_if_available(interactable, "recipe.foundation_t1")
			if world_state.has_base_structure_definition("building.pollution_filter"):
				return ""
			if _get_build_cost_shortage("building.pollution_filter", "item.filter_media", character_state.inventory) > 0.0:
				return _select_if_available(interactable, "recipe.make_filter_media")
			if _get_build_cost_shortage("building.pollution_filter", "item.basic_parts", character_state.inventory) > 0.0:
				return _select_if_available(interactable, "recipe.process_crystal_ore")
			return ""
		"quest.enter_pollution_edge":
			if interactable.definition_id == "building.basic_reactor" and character_state.inventory.has_ref("fluid.polluted_slurry", 1.0):
				return _select_if_available(interactable, "recipe.reclaim_basic_parts")
			return _select_if_available(interactable, "recipe.cleanse_residue")
		"quest.unlock_ruin_signal":
			if interactable.definition_id == "building.basic_reactor" and character_state.inventory.has_ref("fluid.polluted_slurry", 1.0):
				return _select_if_available(interactable, "recipe.reclaim_basic_parts")
			return ""
		"quest.assemble_phase_anchor":
			return _select_recipe_with_basic_parts_fallback(interactable, character_state.inventory, "recipe.phase_anchor", world_state)
		"quest.salvage_signal_echo":
			if character_state.inventory.has_ref("item.polluted_residue", 2):
				return _select_if_available(interactable, "recipe.cleanse_residue")
			return ""
		"quest.analyze_deep_signal":
			if _should_filter_echo_residue_before_deep_signal(interactable, character_state.inventory):
				return _select_if_available(interactable, "recipe.cleanse_residue")
			return _select_recipe_with_basic_parts_fallback(interactable, character_state.inventory, "recipe.deep_signal_analysis", world_state)
		"quest.refine_phase_filament":
			return _select_if_available(interactable, "recipe.phase_filament_refining")
		"quest.assemble_deep_override":
			return _select_recipe_with_basic_parts_fallback(interactable, character_state.inventory, "recipe.deep_override_key", world_state)
		"quest.analyze_deep_core":
			return _select_recipe_with_basic_parts_fallback(interactable, character_state.inventory, "recipe.deep_core_imprint", world_state)
		"quest.assemble_deep_signal_matrix":
			return _select_recipe_with_basic_parts_fallback(interactable, character_state.inventory, "recipe.deep_signal_matrix", world_state)
		"quest.refine_phase_splinters":
			if not character_state.inventory.has_ref("item.phase_lens_blank", 1):
				return _select_if_available(interactable, "recipe.phase_splinter_refining")
			if not character_state.inventory.has_ref("item.relay_tuning_lens", 1):
				return _select_recipe_with_basic_parts_fallback(interactable, character_state.inventory, "recipe.relay_tuning_lens", world_state)
			return ""
		"quest.tune_relay_lens":
			return _select_recipe_with_basic_parts_fallback(interactable, character_state.inventory, "recipe.relay_tuning_lens", world_state)
		"quest.analyze_inner_fault_trace":
			return _select_recipe_with_basic_parts_fallback(interactable, character_state.inventory, "recipe.inner_fault_analysis", world_state)
		"quest.refine_fault_residue":
			if not character_state.inventory.has_ref("item.stabilized_fault_core", 1):
				return _select_if_available(interactable, "recipe.fault_residue_stabilization")
			if not character_state.inventory.has_ref("item.phase_well_key", 1):
				return _select_recipe_with_basic_parts_fallback(interactable, character_state.inventory, "recipe.phase_well_key", world_state)
			return ""
		"quest.analyze_phase_well_locator":
			return _select_recipe_with_basic_parts_fallback(interactable, character_state.inventory, "recipe.phase_well_locator_analysis", world_state)
		"quest.refine_well_flux":
			if not character_state.inventory.has_ref("item.phase_well_stabilizer", 1):
				return _select_if_available(interactable, "recipe.well_flux_stabilization")
			if not character_state.inventory.has_ref("item.phase_well_probe", 1):
				return _select_recipe_with_basic_parts_fallback(interactable, character_state.inventory, "recipe.phase_well_probe", world_state)
			return ""
		"quest.assemble_phase_well_probe":
			return _select_recipe_with_basic_parts_fallback(interactable, character_state.inventory, "recipe.phase_well_probe", world_state)
		"quest.analyze_phase_well_core":
			return _select_recipe_with_basic_parts_fallback(interactable, character_state.inventory, "recipe.phase_well_core_analysis", world_state)
		"quest.refine_well_ash":
			if not character_state.inventory.has_ref("item.phase_well_lattice", 1):
				return _select_if_available(interactable, "recipe.well_ash_stabilization")
			if not character_state.inventory.has_ref("item.phase_well_pike", 1):
				return _select_recipe_with_basic_parts_fallback(interactable, character_state.inventory, "recipe.phase_well_pike", world_state)
			return ""
		"quest.assemble_phase_well_pike":
			return _select_recipe_with_basic_parts_fallback(interactable, character_state.inventory, "recipe.phase_well_pike", world_state)
		"quest.analyze_phase_well_heart":
			return _select_recipe_with_basic_parts_fallback(interactable, character_state.inventory, "recipe.phase_well_heart_analysis", world_state)
		"quest.refine_heart_spine":
			if not character_state.inventory.has_ref("item.phase_well_damper", 1):
				return _select_if_available(interactable, "recipe.heart_spine_stabilization")
			if not character_state.inventory.has_ref("item.phase_well_shunt", 1):
				return _select_recipe_with_basic_parts_fallback(interactable, character_state.inventory, "recipe.phase_well_shunt", world_state)
			return ""
		"quest.assemble_phase_well_shunt":
			return _select_recipe_with_basic_parts_fallback(interactable, character_state.inventory, "recipe.phase_well_shunt", world_state)
		"quest.analyze_phase_well_spindle":
			return _select_recipe_with_basic_parts_fallback(interactable, character_state.inventory, "recipe.phase_well_spindle_analysis", world_state)
		"quest.refine_weft_bundle":
			if not character_state.inventory.has_ref("item.phase_well_tension_rib", 1):
				return _select_if_available(interactable, "recipe.weft_bundle_stabilization")
			if not character_state.inventory.has_ref("item.phase_well_shuttle", 1):
				return _select_recipe_with_basic_parts_fallback(interactable, character_state.inventory, "recipe.phase_well_shuttle", world_state)
			return ""
		"quest.assemble_phase_well_shuttle":
			return _select_recipe_with_basic_parts_fallback(interactable, character_state.inventory, "recipe.phase_well_shuttle", world_state)
		"quest.analyze_phase_well_weave_core":
			return _select_recipe_with_basic_parts_fallback(interactable, character_state.inventory, "recipe.phase_well_weave_core_analysis", world_state)
		"quest.refine_selvedge_strip":
			if not character_state.inventory.has_ref("item.phase_well_frame_rib", 1):
				return _select_if_available(interactable, "recipe.selvedge_strip_stabilization")
			if not character_state.inventory.has_ref("item.phase_well_frame_key", 1):
				return _select_recipe_with_basic_parts_fallback(interactable, character_state.inventory, "recipe.phase_well_frame_key", world_state)
			return ""
		"quest.assemble_phase_well_frame_key":
			return _select_recipe_with_basic_parts_fallback(interactable, character_state.inventory, "recipe.phase_well_frame_key", world_state)
		"quest.analyze_phase_well_knot_core":
			return _select_recipe_with_basic_parts_fallback(interactable, character_state.inventory, "recipe.phase_well_knot_core_analysis", world_state)
		"quest.refine_tether_fiber":
			if not character_state.inventory.has_ref("item.phase_well_tether_rib", 1):
				return _select_if_available(interactable, "recipe.tether_fiber_stabilization")
			if not character_state.inventory.has_ref("item.phase_well_tether_spike", 1):
				return _select_recipe_with_basic_parts_fallback(interactable, character_state.inventory, "recipe.phase_well_tether_spike", world_state)
			return ""
		"quest.assemble_phase_well_tether_spike":
			return _select_recipe_with_basic_parts_fallback(interactable, character_state.inventory, "recipe.phase_well_tether_spike", world_state)
		"quest.analyze_phase_well_anchor_core":
			return _select_recipe_with_basic_parts_fallback(interactable, character_state.inventory, "recipe.phase_well_anchor_core_analysis", world_state)
		"quest.refine_anchor_core_dust":
			if not character_state.inventory.has_ref("item.anchor_field_filter", 1):
				return _select_if_available(interactable, "recipe.anchor_core_dust_stabilization")
			if not character_state.inventory.has_ref("item.phase_well_anchor_stake", 1):
				return _select_recipe_with_basic_parts_fallback(interactable, character_state.inventory, "recipe.phase_well_anchor_stake", world_state)
			return ""
		"quest.assemble_phase_well_anchor_stake":
			return _select_recipe_with_basic_parts_fallback(interactable, character_state.inventory, "recipe.phase_well_anchor_stake", world_state)
		"quest.analyze_phase_well_echo_shard":
			return _select_recipe_with_basic_parts_fallback(interactable, character_state.inventory, "recipe.phase_well_echo_shard_analysis", world_state)
		"quest.analyze_stability_echo_sample":
			return _select_recipe_with_basic_parts_fallback(interactable, character_state.inventory, "recipe.stability_echo_report", world_state)
		"quest.analyze_supply_return_trace":
			return _select_recipe_with_basic_parts_fallback(interactable, character_state.inventory, "recipe.short_action_feedback", world_state)
		"quest.analyze_route_signal_trace":
			return _select_recipe_with_basic_parts_fallback(interactable, character_state.inventory, "recipe.route_action_feedback", world_state)
		"quest.analyze_steady_supply_trace":
			return _select_recipe_with_basic_parts_fallback(interactable, character_state.inventory, "recipe.steady_supply_feedback", world_state)
		"quest.analyze_phase_survey_trace":
			return _select_recipe_with_basic_parts_fallback(interactable, character_state.inventory, "recipe.phase_survey_feedback", world_state)
		"quest.analyze_pressure_clearance_trace":
			return _select_recipe_with_basic_parts_fallback(interactable, character_state.inventory, "recipe.pressure_clearance_feedback", world_state)
		"quest.prepare_demo_stabilization_buffer":
			return _select_recipe_with_basic_parts_fallback(interactable, character_state.inventory, "recipe.core_stabilization_buffer", world_state)
		_:
			return ""


func _format_processing_started_message(recipe: Dictionary, world_state: WorldState) -> String:
	var recipe_id := String(recipe.get("id", ""))
	var message := "已启动加工：%s；预计 %s 秒完成。" % [
		_get_display_name(recipe_id),
		_format_amount(_get_recipe_duration(recipe))
	]
	var started_appendix := ProcessingRecipeHintFormatter.get_processing_started_appendix(recipe_id, world_state)
	if not started_appendix.is_empty():
		message += " %s" % started_appendix
	return message


func _format_processing_started_feedback(recipe: Dictionary, world_state: WorldState, character_state: CharacterState) -> Dictionary:
	var recipe_id := String(recipe.get("id", ""))
	return {
		"title": "加工已启动：%s" % _get_display_name(recipe_id),
		"status": "加工中，预计 %s 秒完成。" % _format_amount(_get_recipe_duration(recipe)),
		"destination": _format_completion_destination(recipe),
		"next_step": _get_processing_wait_next_step(),
		"completion_next_step": _get_completion_next_step(recipe_id, world_state),
		"industrial_spine": IndustrialTechSpineFormatter.format_result_feedback_line(recipe_id, world_state),
		"device_operation": DemoDevicePanelOperationFormatter.format_result_feedback_line(recipe_id, world_state),
		"module_task": DemoIndustrialModuleTaskRhythmFormatter.format_result_feedback_line(recipe_id, world_state, character_state),
		"resource_chain": DemoResourceChainStateFormatter.format_result_feedback_line(recipe_id),
		"core_loop": DemoCoreLoopRhythmFormatter.format_result_feedback_line(recipe_id, world_state, character_state),
		"field_task": DemoFieldTaskDifferentiationFormatter.format_result_feedback_line(recipe_id, world_state, character_state),
		"base_reentry": DemoRouteReturnAndBaseReentryFormatter.format_result_feedback_line(recipe_id, world_state),
		"show_module_task": _should_show_module_task_result_line(recipe_id),
		"show_resource_chain": _should_show_resource_chain_result_line(recipe_id),
		"show_core_loop": DemoCoreLoopRhythmFormatter.should_show_result_line(recipe_id),
		"show_field_task": DemoFieldTaskDifferentiationFormatter.should_show_result_line(recipe_id)
	}


func _format_completion_message(recipe: Dictionary, world_state: WorldState = null) -> String:
	var recipe_id := String(recipe.get("id", ""))
	var parts: Array[String] = ["加工完成：%s。" % _get_display_name(recipe_id)]
	var destination := _format_completion_destination(recipe)
	if not destination.is_empty():
		parts.append(destination)
	var next_step := _get_completion_next_step(recipe_id, world_state)
	if not next_step.is_empty():
		parts.append("下一步：%s" % next_step)
	return " ".join(parts)


func _format_processing_completion_feedback(recipe: Dictionary, world_state: WorldState, character_state: CharacterState) -> Dictionary:
	var recipe_id := String(recipe.get("id", ""))
	return {
		"title": "加工完成：%s" % _get_display_name(recipe_id),
		"status": "已完成。",
		"destination": _format_completion_destination(recipe),
		"next_step": _get_completion_next_step(recipe_id, world_state),
		"industrial_spine": IndustrialTechSpineFormatter.format_result_feedback_line(recipe_id, world_state),
		"device_operation": DemoDevicePanelOperationFormatter.format_result_feedback_line(recipe_id, world_state),
		"module_task": DemoIndustrialModuleTaskRhythmFormatter.format_result_feedback_line(recipe_id, world_state, character_state),
		"resource_chain": DemoResourceChainStateFormatter.format_result_feedback_line(recipe_id),
		"core_loop": DemoCoreLoopRhythmFormatter.format_result_feedback_line(recipe_id, world_state, character_state),
		"field_task": DemoFieldTaskDifferentiationFormatter.format_result_feedback_line(recipe_id, world_state, character_state),
		"base_reentry": DemoRouteReturnAndBaseReentryFormatter.format_result_feedback_line(recipe_id, world_state),
		"show_module_task": _should_show_module_task_result_line(recipe_id),
		"show_resource_chain": _should_show_resource_chain_result_line(recipe_id),
		"show_core_loop": DemoCoreLoopRhythmFormatter.should_show_result_line(recipe_id),
		"show_field_task": DemoFieldTaskDifferentiationFormatter.should_show_result_line(recipe_id)
	}


func _should_show_resource_chain_result_line(recipe_id: String) -> bool:
	return recipe_id == "recipe.process_crystal_ore"


func _should_show_module_task_result_line(recipe_id: String) -> bool:
	return [
		"recipe.basic_filter_module",
		"recipe.core_stabilization_buffer"
	].has(recipe_id)


func _format_completion_destination(recipe: Dictionary) -> String:
	var parts: Array[String] = []
	var outputs := _format_refs(recipe.get("outputs", []), "")
	if not outputs.is_empty():
		parts.append("产物已放入背包：%s。" % outputs)
	var byproducts := _format_refs(recipe.get("byproducts", []), "")
	if not byproducts.is_empty():
		parts.append("副产已放入背包：%s。" % byproducts)
	if parts.is_empty():
		return "本次无新增产物。"
	return " ".join(parts)


func _format_last_completion_status(structure: Dictionary) -> String:
	var last_recipe_id := String(structure.get("last_recipe_id", ""))
	if last_recipe_id.is_empty():
		return ""
	var completed_runs := int(structure.get("completed_runs", 0))
	if completed_runs > 0:
		return "刚完成：%s（累计 %d 次）。" % [_get_display_name(last_recipe_id), completed_runs]
	return "刚完成：%s。" % _get_display_name(last_recipe_id)


func _get_completion_next_step(recipe_id: String, world_state: WorldState = null) -> String:
	return ProcessingRecipeHintFormatter.get_completion_next_step(recipe_id, world_state)


func _format_in_progress_message(structure: Dictionary) -> String:
	var active_recipe_id := String(structure.get("active_recipe_id", ""))
	var recipe := data_registry.get_definition(active_recipe_id)
	var duration := _get_recipe_duration(recipe)
	var progress_seconds := float(structure.get("progress_seconds", 0.0))
	return "加工中：%s（%s / %s 秒）。" % [
		_get_display_name(active_recipe_id),
		_format_amount(progress_seconds),
		_format_amount(duration)
	]


func _get_processing_wait_next_step() -> String:
	return "等待设备完成；靠近设备查看进度，按 Q 打开设备面板。"


func _format_missing_input_message(recipe: Dictionary, missing_inputs: Array[String], inventory: InventoryState) -> String:
	var message := "缺少原料：%s。" % ", ".join(missing_inputs)
	var supply_hint := _format_missing_input_supply_hint(recipe, inventory)
	if not supply_hint.is_empty():
		message += " 补给方向：%s" % supply_hint
	return message


func _format_missing_input_next_step(recipe: Dictionary, inventory: InventoryState) -> String:
	var supply_hint := _format_missing_input_supply_hint(recipe, inventory)
	if not supply_hint.is_empty():
		return "补给方向：%s" % supply_hint
	return "先采集资源或切换到输入已满足的配方。"


func _format_missing_input_supply_hint(recipe: Dictionary, inventory: InventoryState) -> String:
	var specific_hint := _format_mid_demo_missing_input_supply_hint(recipe, inventory)
	if not specific_hint.is_empty():
		return specific_hint
	if _get_recipe_input_shortage(recipe, "item.basic_parts", inventory) <= 0.0:
		return ""
	if data_registry.get_definition("recipe.process_crystal_ore").is_empty():
		return "先检查前哨核心回收和阶段补给批次。"
	if _get_inventory_ref_amount("fluid.polluted_slurry", inventory) >= 1.0:
		return "先检查前哨核心回收和阶段补给批次；处理点扩建后，可切换到回收基础零件，把污染浆液回收成基础零件；若仍不足，去晶体矿脉区北侧富晶残脉采集晶体矿物。"
	if _get_inventory_ref_amount("item.crystal_ore", inventory) >= 3.0:
		return "先检查前哨核心回收和阶段补给批次；当前也可切换到处理晶体矿物，把晶体矿物加工成基础零件。"
	return "先检查前哨核心回收和阶段补给批次；若仍不足，去晶体矿脉区北侧富晶残脉或处理点入口前的回访矿点采集晶体矿物后加工成基础零件。"


func _format_mid_demo_missing_input_supply_hint(recipe: Dictionary, inventory: InventoryState) -> String:
	match String(recipe.get("id", "")):
		"recipe.phase_anchor":
			if _get_recipe_input_shortage(recipe, "item.relay_shard", inventory) > 0.0:
				return "先进入封锁遗迹外圈，回收两处继电残片；外圈前污染脊还会补一份沉积物和受扰守卫。"
			if _get_recipe_input_shortage(recipe, "fluid.polluted_slurry", inventory) > 0.0:
				return "污染浆液来自污染过滤器处理沉积物；外圈污染脊会补沉积物，先回处理点过滤器处理。"
			if _get_recipe_input_shortage(recipe, "item.basic_parts", inventory) > 0.0:
				return "基础零件不足：先把一份污染浆液回收成基础零件；若缺组装用浆液，回污染脊补沉积物再处理。"
		"recipe.deep_signal_analysis":
			if _get_recipe_input_shortage(recipe, "item.signal_echo_trace", inventory) > 0.0:
				return "先在封锁遗迹深处清理相位守卫，并回收外圈回波匣。"
			if _get_recipe_input_shortage(recipe, "fluid.polluted_slurry", inventory) > 0.0:
				return "污染浆液不足：先处理守卫后暴露的污染回波沉积，保留过滤副产后再解析裂相坐标。"
		"recipe.core_stabilization_buffer":
			if _get_recipe_input_shortage(recipe, "item.repair_gel", inventory) > 0.0:
				return "修复凝胶不足：先在基础反应器调制修复凝胶，或检查核心稳定站侧边补给缓存。"
			if _get_recipe_input_shortage(recipe, "item.resistance_vial_t1", inventory) > 0.0:
				return "抗污染药剂不足：回处理点过滤器处理污染沉积物，再整备核心稳压缓冲包。"
			if _get_recipe_input_shortage(recipe, "fluid.polluted_slurry", inventory) > 0.0:
				return "污染浆液不足：回污染边界末端补沉积物并用过滤器处理，保留副产浆液后再整备缓冲包。"
			if _get_recipe_input_shortage(recipe, "item.basic_parts", inventory) > 0.0:
				return "基础零件不足：处理晶体矿物；若有多余污染浆液，再回收成基础零件后整备缓冲包。"
		"recipe.phase_filament_refining":
			if _get_recipe_input_shortage(recipe, "item.phase_filament", inventory) > 0.0:
				return "先进入裂相脊入口，清理裂相守卫并回收两处相位纤丝。"
		"recipe.deep_override_key":
			if _get_recipe_input_shortage(recipe, "item.resonance_filter", inventory) > 0.0:
				return "先回处理点污染过滤器精炼相位纤丝，得到谐振滤芯。"
			if _get_recipe_input_shortage(recipe, "fluid.polluted_slurry", inventory) > 0.0:
				return "污染浆液来自相位纤丝精炼副产；先回处理点过滤器完成精炼，再组装裂相覆写栓。"
		"recipe.deep_core_imprint":
			if _get_recipe_input_shortage(recipe, "item.deep_ruin_core", inventory) > 0.0:
				return "先带着裂相覆写栓返回裂相脊入口，覆写裂相锁扣并取出裂相样块。"
		"recipe.deep_signal_matrix":
			if _get_recipe_input_shortage(recipe, "item.phase_conduit", inventory) > 0.0:
				return "先带裂相路由印片返回裂相阵列台，点亮阵列后清理追袭体并回收两束相位导管。"
			if _get_recipe_input_shortage(recipe, "fluid.polluted_slurry", inventory) > 0.0:
				return "污染浆液可从相位纤丝精炼副产或污染过滤器处理沉积物获得；补足后再整理深段读数矩阵。"
		"recipe.phase_splinter_refining":
			if _get_recipe_input_shortage(recipe, "item.phase_splinter", inventory) > 0.0:
				return "先用相位回投台返回前线锚点，写入两处裂相共振读数，击退裂相猎手后回收两处裂相碎屑。"
		"recipe.relay_tuning_lens":
			if _get_recipe_input_shortage(recipe, "item.phase_lens_blank", inventory) > 0.0:
				return "先回处理点污染过滤器，把裂相碎屑筛成透镜胚片。"
			if _get_recipe_input_shortage(recipe, "fluid.polluted_slurry", inventory) > 0.0:
				return "污染浆液来自裂相碎屑筛分副产；先完成过滤器筛分，再调准中继调谐镜。"
		"recipe.inner_fault_analysis":
			if _get_recipe_input_shortage(recipe, "item.inner_fault_trace", inventory) > 0.0:
				return "先带中继调谐镜返回更东侧裂相尖塔，校准后带回内层故障轨迹。"
		"recipe.fault_residue_stabilization":
			if _get_recipe_input_shortage(recipe, "item.fault_residue", inventory) > 0.0:
				return "先返回裂相尖塔更东侧，读出两处故障脉冲，击退内层潜猎体并回收两处故障残渣。"
		"recipe.phase_well_key":
			if _get_recipe_input_shortage(recipe, "item.phase_well_coordinate", inventory) > 0.0:
				return "先回基地基础反应器解析内层故障轨迹，整理出裂相坐标印片。"
			if _get_recipe_input_shortage(recipe, "item.stabilized_fault_core", inventory) > 0.0:
				return "先回处理点污染过滤器稳定故障残渣，筛出稳定故障芯。"
		"recipe.phase_well_locator_analysis":
			if _get_recipe_input_shortage(recipe, "item.phase_well_locator", inventory) > 0.0:
				return "先带裂相锁钥返回裂相锁位，钉住锁位并带回第一份回声定位器。"
		"recipe.well_flux_stabilization":
			if _get_recipe_input_shortage(recipe, "item.well_flux_shard", inventory) > 0.0:
				return "先沿回声路由进入回声台地边缘，处理两处回声泄压阀，击退回声哨戒体并回收两处回声碎屑。"
		"recipe.phase_well_probe":
			if _get_recipe_input_shortage(recipe, "item.phase_well_route", inventory) > 0.0:
				return "先回基地基础反应器解析回声定位器，整理出回声路由片。"
			if _get_recipe_input_shortage(recipe, "item.phase_well_stabilizer", inventory) > 0.0:
				return "先回处理点污染过滤器稳定回声碎屑，筛出回声稳流芯。"
		"recipe.phase_well_core_analysis":
			if _get_recipe_input_shortage(recipe, "item.phase_well_core", inventory) > 0.0:
				return "先带回声探针返回更东侧回声台地，读取第一份回声芯样本。"
		"recipe.well_ash_stabilization":
			if _get_recipe_input_shortage(recipe, "item.well_ash", inventory) > 0.0:
				return "先沿盐壳频谱进入盐壳浅滩边缘，清理两处盐壳硬壳，击退盐壳潜伏体并回收两处盐壳余烬。"
		"recipe.phase_well_pike":
			if _get_recipe_input_shortage(recipe, "item.phase_well_spectrum", inventory) > 0.0:
				return "先回基地基础反应器解析回声芯样本，整理出盐壳频谱片。"
			if _get_recipe_input_shortage(recipe, "item.phase_well_lattice", inventory) > 0.0:
				return "先回处理点污染过滤器稳定盐壳余烬，筛出盐壳稳相格。"
		"recipe.phase_well_heart_analysis":
			if _get_recipe_input_shortage(recipe, "item.phase_well_heart", inventory) > 0.0:
				return "先带盐壳穿钉返回盐壳浅滩，凿开后带回第一份碎晶心核。"
		"recipe.heart_spine_stabilization":
			if _get_recipe_input_shortage(recipe, "item.heart_spine", inventory) > 0.0:
				return "先沿碎晶脉搏进入碎晶沟谷边缘，写入两处碎晶分流读数，击退碎晶撕裂体并回收两处心棘残片。"
		"recipe.phase_well_shunt":
			if _get_recipe_input_shortage(recipe, "item.phase_well_pulse_sheet", inventory) > 0.0:
				return "先回基地基础反应器解析碎晶心核，整理出碎晶脉搏片。"
			if _get_recipe_input_shortage(recipe, "item.phase_well_damper", inventory) > 0.0:
				return "先回处理点污染过滤器稳定心棘残片，筛出碎晶抑振骨。"
		"recipe.phase_well_spindle_analysis":
			if _get_recipe_input_shortage(recipe, "item.phase_well_spindle", inventory) > 0.0:
				return "先带碎晶分流栓返回碎晶沟谷，勘验后带回第一份风蚀张力核。"
		"recipe.weft_bundle_stabilization":
			if _get_recipe_input_shortage(recipe, "item.weft_bundle", inventory) > 0.0:
				return "先沿风蚀经片进入风蚀管廊边缘，检查两处风蚀张力绕轮，击退风蚀纠缠体并回收两处纬束残团。"
		"recipe.phase_well_shuttle":
			if _get_recipe_input_shortage(recipe, "item.phase_well_warp_sheet", inventory) > 0.0:
				return "先回基地基础反应器解析风蚀张力核，整理出风蚀经片。"
			if _get_recipe_input_shortage(recipe, "item.phase_well_tension_rib", inventory) > 0.0:
				return "先回处理点污染过滤器稳定纬束残团，筛出风蚀张力肋。"
		"recipe.phase_well_weave_core_analysis":
			if _get_recipe_input_shortage(recipe, "item.phase_well_weave_core", inventory) > 0.0:
				return "先带风蚀梭栓返回风蚀管廊，勘验后带回第一份锁相织构核。"
		"recipe.selvedge_strip_stabilization":
			if _get_recipe_input_shortage(recipe, "item.selvedge_strip", inventory) > 0.0:
				return "先沿锁相纹谱进入锁相框架边缘，清理一条锁相侧路障，击退锁相刮裂体并回收两处边缕残条。"
		"recipe.phase_well_frame_key":
			if _get_recipe_input_shortage(recipe, "item.phase_well_pattern_sheet", inventory) > 0.0:
				return "先回基地基础反应器解析锁相织构核，整理出锁相纹谱片。"
			if _get_recipe_input_shortage(recipe, "item.phase_well_frame_rib", inventory) > 0.0:
				return "先回处理点污染过滤器稳定边缕残条，筛出锁相框架肋。"
		"recipe.phase_well_knot_core_analysis":
			if _get_recipe_input_shortage(recipe, "item.phase_well_knot_core", inventory) > 0.0:
				return "先带锁相键栓返回锁相框架，勘验后带回第一份锚定结核。"
		"recipe.tether_fiber_stabilization":
			if _get_recipe_input_shortage(recipe, "item.tether_fiber", inventory) > 0.0:
				return "先沿锚定系谱进入锚定桥边缘，检查两处锚定桥结点，击退锚定缚结体并回收两处锚索残股。"
		"recipe.phase_well_tether_spike":
			if _get_recipe_input_shortage(recipe, "item.phase_well_tether_sheet", inventory) > 0.0:
				return "先回基地基础反应器解析锚定结核，整理出锚定系谱片。"
			if _get_recipe_input_shortage(recipe, "item.phase_well_tether_rib", inventory) > 0.0:
				return "先回处理点污染过滤器稳定锚索残股，筛出锚定系固肋。"
		"recipe.phase_well_anchor_core_analysis":
			if _get_recipe_input_shortage(recipe, "item.phase_well_anchor_core", inventory) > 0.0:
				return "先带锚定桩返回锚定桥断面，勘验后带回第一份稳场锚核。"
		"recipe.anchor_core_dust_stabilization":
			if _get_recipe_input_shortage(recipe, "item.anchor_core_dust", inventory) > 0.0:
				return "先回基地基础反应器解析稳场锚核，沉降出锚核落尘。"
		"recipe.phase_well_anchor_stake":
			if _get_recipe_input_shortage(recipe, "item.phase_well_return_sheet", inventory) > 0.0:
				return "先回基地基础反应器解析稳场锚核，整理出归谱片。"
			if _get_recipe_input_shortage(recipe, "item.anchor_field_filter", inventory) > 0.0:
				return "先回处理点污染过滤器稳定锚核落尘，筛出稳场滤囊。"
		"recipe.phase_well_echo_shard_analysis":
			if _get_recipe_input_shortage(recipe, "item.phase_well_echo_shard", inventory) > 0.0:
				return "先带稳场校锚桩返回锚定桥东侧，完成锚场回稳窗部署并收束第一份稳窗余响片。"
		"recipe.stability_echo_report":
			if _get_recipe_input_shortage(recipe, "item.stability_echo_sample", inventory) > 0.0:
				return "先从前线行动台确认稳窗回访，再用相位回投返回锚定桥东侧读取稳窗回波探点。"
		"recipe.short_action_feedback":
			if _get_recipe_input_shortage(recipe, "item.supply_return_trace", inventory) > 0.0:
				return "先从前线行动台确认补给短行动，再用相位回投返回锚定桥前线读取补给回执标记。"
		"recipe.route_action_feedback":
			if _get_recipe_input_shortage(recipe, "item.route_signal_trace", inventory) > 0.0:
				return "先从前线行动台确认巡线短行动，再用相位回投返回锚定桥前线读取巡线信标。"
		"recipe.phase_survey_feedback":
			if _get_recipe_input_shortage(recipe, "item.phase_survey_trace", inventory) > 0.0:
				return "先选择相位测绘行动，再用相位回投返回锚定桥前线读取西侧和东侧两处相位测绘点。"
	return ""


func _get_missing_inputs(recipe: Dictionary, inventory: InventoryState) -> Array[String]:
	var missing_inputs: Array[String] = []
	for input_ref in recipe.get("inputs", []):
		if not input_ref is Dictionary:
			continue

		var definition_id := String(input_ref.get("id", ""))
		var amount := float(input_ref.get("amount", 0.0))
		if definition_id.is_empty() or amount <= 0.0:
			continue
		var current_amount := _get_inventory_ref_amount(definition_id, inventory)
		if current_amount < amount:
			missing_inputs.append("%s x%s" % [_get_display_name(definition_id), _format_amount(amount - current_amount)])

	return missing_inputs


func _get_required_structure_id(recipe: Dictionary, world_state: WorldState) -> String:
	var building_id := String(recipe.get("required_building_id", ""))
	if building_id.is_empty():
		return ""
	return world_state.get_base_structure_id_for_definition(building_id)


func _select_if_available(interactable: PrototypeInteractable, recipe_id: String) -> String:
	if interactable.has_recipe(recipe_id):
		return recipe_id
	return ""


func _should_filter_echo_residue_before_deep_signal(
	interactable: PrototypeInteractable,
	inventory: InventoryState
) -> bool:
	if interactable.definition_id != "building.pollution_filter":
		return false
	if inventory.has_ref("fluid.polluted_slurry", 1.0):
		return false
	return inventory.has_ref("item.polluted_residue", 2)


func _select_recipe_with_basic_parts_fallback(
	interactable: PrototypeInteractable,
	inventory: InventoryState,
	target_recipe_id: String,
	world_state: WorldState
) -> String:
	var target_recipe := data_registry.get_definition(target_recipe_id)
	if _should_refill_basic_parts_before_recipe(target_recipe_id, inventory):
		var reserved_slurry := _get_recipe_input_amount(target_recipe, "fluid.polluted_slurry")
		var refill_recipe_id := _select_basic_parts_refill_recipe(interactable, inventory, world_state, reserved_slurry)
		if not refill_recipe_id.is_empty():
			return refill_recipe_id
	return _select_if_available(interactable, target_recipe_id)


func _select_basic_parts_refill_recipe(
	interactable: PrototypeInteractable,
	inventory: InventoryState,
	world_state: WorldState,
	reserved_polluted_slurry: float = 0.0
) -> String:
	if _get_inventory_ref_amount("fluid.polluted_slurry", inventory) > reserved_polluted_slurry:
		var reclaim_recipe_id := _select_if_available(interactable, "recipe.reclaim_basic_parts")
		if not reclaim_recipe_id.is_empty():
			var reclaim_recipe := data_registry.get_definition(reclaim_recipe_id)
			if _get_recipe_lock_message(reclaim_recipe, world_state).is_empty():
				return reclaim_recipe_id
	return _select_if_available(interactable, "recipe.process_crystal_ore")


func _should_refill_basic_parts_before_recipe(target_recipe_id: String, inventory: InventoryState) -> bool:
	var recipe := data_registry.get_definition(target_recipe_id)
	if recipe.is_empty():
		return false
	if _get_recipe_input_shortage(recipe, "item.basic_parts", inventory) <= 0.0:
		return false
	return _has_required_inputs_except(recipe, inventory, "item.basic_parts")


func _get_recipe_input_shortage(recipe: Dictionary, definition_id: String, inventory: InventoryState) -> float:
	return maxf(0.0, _get_recipe_input_amount(recipe, definition_id) - _get_inventory_ref_amount(definition_id, inventory))


func _get_recipe_input_amount(recipe: Dictionary, definition_id: String) -> float:
	for input_ref in recipe.get("inputs", []):
		if not input_ref is Dictionary:
			continue
		if String(input_ref.get("id", "")) != definition_id:
			continue
		return float(input_ref.get("amount", 0.0))
	return 0.0


func _has_required_inputs_except(recipe: Dictionary, inventory: InventoryState, skipped_definition_id: String) -> bool:
	for input_ref in recipe.get("inputs", []):
		if not input_ref is Dictionary:
			continue
		var definition_id := String(input_ref.get("id", ""))
		var amount := float(input_ref.get("amount", 0.0))
		if definition_id.is_empty() or amount <= 0.0 or definition_id == skipped_definition_id:
			continue
		if _get_inventory_ref_amount(definition_id, inventory) < amount:
			return false
	return true


func _get_build_cost_shortage(building_id: String, definition_id: String, inventory: InventoryState) -> float:
	if building_id.is_empty() or definition_id.is_empty():
		return 0.0

	var building := data_registry.get_definition(building_id)
	if building.is_empty():
		return 0.0

	for cost in building.get("build_cost", []):
		if not cost is Dictionary:
			continue
		if String(cost.get("id", "")) != definition_id:
			continue
		return maxf(0.0, float(cost.get("amount", 0.0)) - _get_inventory_ref_amount(definition_id, inventory))
	return 0.0


func _get_active_structure_for_building(building_id: String, world_state: WorldState) -> Dictionary:
	if building_id.is_empty():
		return {}

	for structure in world_state.base_structures.values():
		if not structure is Dictionary:
			continue
		if String(structure.get("definition_id", "")) != building_id:
			continue
		if String(structure.get("status", "idle")) == "in_progress":
			return structure
	return {}


func _consume_refs(refs: Array, inventory: InventoryState) -> void:
	for ref in refs:
		if not ref is Dictionary:
			continue

		var definition_id := String(ref.get("id", ""))
		var amount := float(ref.get("amount", 0.0))
		if definition_id.is_empty() or amount <= 0.0:
			continue

		inventory.consume_ref(definition_id, amount)


func _grant_refs(refs: Array, inventory: InventoryState) -> void:
	for ref in refs:
		if not ref is Dictionary:
			continue

		var definition_id := String(ref.get("id", ""))
		var amount := float(ref.get("amount", 0.0))
		if definition_id.is_empty() or amount <= 0.0:
			continue

		inventory.add_ref(definition_id, amount)


func _format_refs(refs: Array, empty_text: String = "无") -> String:
	var parts: Array[String] = []
	for ref in refs:
		if not ref is Dictionary:
			continue

		var definition_id := String(ref.get("id", ""))
		var amount := float(ref.get("amount", 0.0))
		if definition_id.is_empty() or amount <= 0.0:
			continue

		parts.append("%s x%s" % [_get_display_name(definition_id), _format_amount(amount)])

	if parts.is_empty():
		return empty_text
	return ", ".join(parts)


func _recipe_status(
	recipe: Dictionary,
	can_process: bool,
	message: String,
	missing_inputs: Array[String],
	active_structure: Dictionary = {},
	required_structure: Dictionary = {},
	supply_hint: String = "",
	world_state: WorldState = null,
	requested_recipe_id: String = ""
) -> Dictionary:
	var active_recipe_id := String(active_structure.get("active_recipe_id", ""))
	var active_recipe := data_registry.get_definition(active_recipe_id)
	var duration := _get_recipe_duration(recipe)
	if not active_recipe.is_empty():
		duration = _get_recipe_duration(active_recipe)
	var progress := ""
	var progress_ratio := 0.0
	if not active_structure.is_empty():
		var progress_seconds := float(active_structure.get("progress_seconds", 0.0))
		progress = "%s / %s 秒" % [_format_amount(progress_seconds), _format_amount(duration)]
		if duration > 0.0:
			progress_ratio = clampf(progress_seconds / duration, 0.0, 1.0)

	var recipe_id := String(recipe.get("id", ""))
	var completion_next_step := _get_completion_next_step(recipe_id, world_state)
	var next_step := completion_next_step
	if not active_structure.is_empty():
		next_step = _get_processing_wait_next_step()
	if requested_recipe_id.is_empty():
		requested_recipe_id = recipe_id

	var result := {
		"can_process": can_process,
		"message": message,
		"recipe_id": recipe_id,
		"requested_recipe_id": requested_recipe_id,
		"active_recipe_id": active_recipe_id,
		"inputs": _format_refs(recipe.get("inputs", [])),
		"outputs": _format_refs(recipe.get("outputs", [])),
		"byproducts": _format_refs(recipe.get("byproducts", []), ""),
		"missing_inputs": missing_inputs,
		"supply_hint": supply_hint,
		"next_step": next_step,
		"completion_next_step": completion_next_step,
		"completion_destination": _format_completion_destination(recipe),
		"duration": _format_amount(duration),
		"progress": progress,
		"progress_ratio": progress_ratio
	}
	if not required_structure.is_empty() and String(required_structure.get("status", "")) == "completed":
		var last_recipe_id := String(required_structure.get("last_recipe_id", ""))
		var last_recipe := data_registry.get_definition(last_recipe_id)
		if not last_recipe.is_empty():
			result["last_completed_recipe_id"] = last_recipe_id
			result["last_completion"] = _format_last_completion_status(required_structure)
			result["last_destination"] = _format_completion_destination(last_recipe)
			result["last_next_step"] = _get_completion_next_step(last_recipe_id, world_state)
	return result


func _get_recipe_lock_message(recipe: Dictionary, world_state: WorldState) -> String:
	var recipe_id := String(recipe.get("id", ""))
	var unlock_conditions = recipe.get("unlock_conditions", [])
	if not (unlock_conditions is Array) or unlock_conditions.is_empty():
		return ""
	if world_state.quest_state.unlocked_effects.has(recipe_id):
		return ""
	return "配方尚未解锁：%s。" % _format_unlock_conditions(unlock_conditions)


func _apply_recipe_completion_side_effect(recipe_id: String, world_state: WorldState) -> void:
	if recipe_id == "recipe.process_crystal_ore":
		if not FieldOutfittingRuntime.is_crystal_logistics_return_available(world_state):
			return
		if not FieldOutfittingRuntime.has_crystal_logistics_return_materials(world_state):
			return
		FieldOutfittingRuntime.mark_logistics_material_processed(world_state)
		return
	if recipe_id == "recipe.cleanse_residue":
		if (
			FieldOutfittingRuntime.is_logistics_maintenance_pollution_retest_available(world_state)
			and FieldOutfittingRuntime.has_logistics_maintenance_pollution_retest_residue(world_state)
			and not FieldOutfittingRuntime.is_logistics_maintenance_pollution_retest_processed(world_state)
		):
			FieldOutfittingRuntime.mark_logistics_maintenance_pollution_retest_processed(world_state)
			return
		if not CoreStabilizationPressureFormatter.is_logistics_maintenance_retest_available(world_state):
			return
		if not CoreStabilizationPressureFormatter.has_logistics_maintenance_retest_residue(world_state):
			return
		CoreStabilizationPressureFormatter.mark_logistics_maintenance_retest_processed(world_state)


func _format_unlock_conditions(unlock_conditions: Array) -> String:
	var parts: Array[String] = []
	for unlock_condition in unlock_conditions:
		parts.append(_get_display_name(String(unlock_condition)))
	if parts.is_empty():
		return "继续推进当前目标"
	return ", ".join(parts)


func _get_recipe_duration(recipe: Dictionary) -> float:
	return maxf(0.1, float(recipe.get("duration", 0.1)))


func _get_inventory_ref_amount(definition_id: String, inventory: InventoryState) -> float:
	if definition_id.begins_with("fluid."):
		return float(inventory.fluids.get(definition_id, 0.0))
	if definition_id.begins_with("equipment."):
		return float(inventory.equipment.get(definition_id, 0))
	return float(inventory.items.get(definition_id, 0))


func _format_amount(amount: float) -> String:
	if is_equal_approx(amount, roundf(amount)):
		return str(int(amount))
	return "%.1f" % amount


func _get_display_name(definition_id: String) -> String:
	var definition := data_registry.get_definition(definition_id)
	if definition.is_empty():
		return definition_id
	return data_registry.get_text(String(definition.get("display_name_key", definition_id)))


func _success(message: String) -> Dictionary:
	return {
		"success": true,
		"message": message
	}


func _failure(message: String, title: String = "加工未完成", detail: String = "") -> Dictionary:
	return {
		"success": false,
		"message": message,
		"failure_feedback": {
			"title": title,
			"detail": detail
		}
	}


func _failure_from_feedback(message: String, feedback: Dictionary) -> Dictionary:
	return {
		"success": false,
		"message": message,
		"failure_feedback": feedback
	}
