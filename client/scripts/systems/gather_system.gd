extends RefCounted
class_name GatherSystem

const PROTOTYPE_POLLUTION_PRESSURE_MULT := 15.0
const DEMO_STABILIZATION_WRITE_HEALTH_PRESSURE := 12.0
const DEMO_STABILIZATION_WRITE_PROTECTION_PRESSURE := 18.0
const DEMO_STABILIZATION_WRITE_VIAL_MULT := 0.35
const DEMO_STABILIZATION_WRITE_CORE_BUFFER_MULT := 0.75
const DEMO_STABILIZATION_WRITE_RECOVERY_CACHE_MULT := 0.85
const DEMO_STABILIZATION_WRITE_GUARD_CACHE_MULT := 0.9
const BASIC_STORAGE_REPAIR_GEL_TARGET := 1
const BASIC_STORAGE_RESISTANCE_VIAL_TARGET := 1
const SLURRY_BUFFER_RESISTANCE_VIAL_TARGET := 2
const FIELD_OUTFITTING_STATION_ID := FieldOutfittingRuntime.FIELD_OUTFITTING_STATION_ID
const BASIC_FILTER_MODULE_ID := FieldOutfittingRuntime.BASIC_FILTER_MODULE_ID
const OUTPOST_DEPARTURE_GATE_ID := "map_object.outpost_departure_gate"
const POLLUTION_RESIDUE_PRESSURE_BY_INSTANCE := {
	"map_object_instance.pollution_residue": 1.0,
	"map_object_instance.pollution_residue_outer_pocket": 1.15,
	"map_object_instance.pollution_residue_vial_return_cache": 1.25,
	"map_object_instance.pollution_residue_slurry_return_cache": 1.3,
	"map_object_instance.pollution_residue_vial_reserve_cache": 1.45,
	"map_object_instance.pollution_residue_deep": 1.35,
	"map_object_instance.pollution_residue_ridge_cache": 1.6,
	"map_object_instance.outer_ring_echo_residue_cache": 1.7,
	"map_object_instance.core_buffer_residue_cache": 1.6
}

var data_registry: DataRegistry
var processing_system: ProcessingSystem
var build_system: BuildSystem

const FIELD_READING_RESULTS := {
	"map_object.phase_splinter_resonance_node": {
		"quest_id": "quest.trace_phase_splinters",
		"objective_type": "inspect",
		"target_id": "map_object.phase_splinter_resonance_node",
		"required": 2.0,
		"step": "裂相共振读数",
		"partial": "继续检查另一处裂相共振点，再处理猎手和碎屑。",
		"complete": "两点共振已定位，裂相碎屑回收线已经稳定。"
	},
	"map_object.fault_residue_pulse_node": {
		"quest_id": "quest.collect_fault_residue",
		"objective_type": "inspect",
		"target_id": "map_object.fault_residue_pulse_node",
		"required": 2.0,
		"step": "故障脉冲读数",
		"partial": "继续读另一处脉冲，再压制潜猎体。",
		"complete": "两处故障脉冲已读出，故障残渣回收线已经显形。"
	},
	"map_object.well_flux_pressure_vent": {
		"quest_id": "quest.collect_well_flux",
		"objective_type": "inspect",
		"target_id": "map_object.well_flux_pressure_vent",
		"required": 2.0,
		"step": "回声泄压",
		"partial": "继续处理另一处泄压阀，再压制回声哨戒体。",
		"complete": "两处回声压力已卸掉，回声碎屑回收线已经稳定。"
	},
	"map_object.phase_well_chamber_shunt_node": {
		"quest_id": "quest.collect_heart_spine",
		"objective_type": "inspect",
		"target_id": "map_object.phase_well_chamber_shunt_node",
		"required": 2.0,
		"step": "碎晶分流读数",
		"partial": "继续写入另一处分流读数，心棘残片还没有完全露出。",
		"complete": "两处分流读数已写入，心棘残片从脉冲里露出。"
	},
	"map_object.phase_well_loom_tension_spool": {
		"quest_id": "quest.collect_weft_bundle",
		"objective_type": "inspect",
		"target_id": "map_object.phase_well_loom_tension_spool",
		"required": 2.0,
		"step": "风蚀张力绕轮",
		"partial": "继续检查另一处张力绕轮，纬束残团还不稳定。",
		"complete": "两处张力绕轮已确认，纬束残团回收线已经稳定。"
	},
	"map_object.phase_well_tether_knot_node": {
		"quest_id": "quest.collect_tether_fiber",
		"objective_type": "inspect",
		"target_id": "map_object.phase_well_tether_knot_node",
		"required": 2.0,
		"step": "锚定桥结点",
		"partial": "继续检查另一端结点，锚索残股还没有完全松开。",
		"complete": "两端桥结点已确认，锚索残股从桥体边缘松开。"
	}
}


func _init(registry: DataRegistry) -> void:
	data_registry = registry
	processing_system = ProcessingSystem.new(data_registry)
	build_system = BuildSystem.new(data_registry)


func interact_with_object(
	instance_id: String,
	definition_id: String,
	interaction_type: String,
	character_state: CharacterState,
	world_state: WorldState,
	recipe_id: String = ""
) -> Dictionary:
	if interaction_type == "outpost_core":
		return _interact_with_outpost_core(character_state, world_state)
	if interaction_type == "inspect" and definition_id == FIELD_OUTFITTING_STATION_ID:
		return _interact_with_field_outfitting_station(character_state, world_state)
	if interaction_type == "process_recipe":
		return processing_system.process_recipe(recipe_id, character_state, world_state)
	if interaction_type == "build":
		return build_system.build_structure(
			instance_id,
			definition_id,
			character_state,
			world_state,
			recipe_id
		)

	var definition := data_registry.get_definition(definition_id)
	if definition.is_empty():
		return _failure("未知交互对象：%s。" % definition_id, "交互未完成", "换一个可交互目标，或检查地图对象定义。")

	if interaction_type == "inspect" and definition_id == OUTPOST_DEPARTURE_GATE_ID:
		return _inspect_outpost_departure_gate(character_state, world_state)

	if (
		interaction_type == "inspect"
		and definition_id == "map_object.demo_stabilization_core"
		and world_state.quest_state.has_completed_quest("quest.write_demo_stabilization_core")
	):
		return _inspect_completed_demo_stabilization_core(instance_id, definition_id, character_state, world_state)

	if interaction_type == "inspect" and definition_id == BaseActionDispatchPlan.FRONTLINE_ACTION_CONSOLE_ID:
		var review_messages := BaseActionDispatchPlan.acknowledge_frontline_window_feedback(world_state)
		if not review_messages.is_empty():
			return _success(" ".join(review_messages))
		var departure_messages := BaseActionDispatchPlan.confirm_departure_preparation(world_state)
		if not departure_messages.is_empty():
			return _success(" ".join(departure_messages))
		var frontline_quest_id := BaseActionDispatchPlan.get_frontline_action_console_quest_id(world_state.quest_state)
		if not frontline_quest_id.is_empty():
			_set_map_object_flag(world_state, instance_id, definition_id, "is_sampled", true)
			return _success(_format_frontline_action_console_result(frontline_quest_id))
		return _failure(
			"前线行动台当前没有可确认计划。",
			"行动台未开放",
			"先处理当前前线窗口、归档反馈，或等待基地行动反馈进入当前计划槽。"
		)
	if interaction_type == "inspect" and BaseActionDispatchPlan.is_plan_candidate_console_ready(definition_id, world_state):
		var candidate_messages := BaseActionDispatchPlan.select_next_plan_candidate_for_console(definition_id, world_state)
		if not candidate_messages.is_empty():
			return _success(" ".join(candidate_messages))
	if (
		interaction_type == "inspect"
		and BaseActionDispatchPlan.is_plan_candidate_console(definition_id)
		and not BaseActionDispatchPlan.is_plan_choice_console_ready(definition_id, world_state)
	):
		return _failure(
			"方案终端暂不可替换下一候选。",
			"候选替换未开放",
			"先处理本趟前线异常窗口并回基地归档反馈，再查看或替换下一计划候选。"
		)

	var object_state := world_state.ensure_map_object(instance_id, definition_id, character_state.current_region_id)
	if _is_already_processed(object_state, interaction_type):
		return _failure(
			_format_already_processed_message(definition_id, interaction_type, character_state, world_state),
			"目标已处理",
			"现场完成态颜色和标签表示该对象已处理；前往下一个未处理目标。"
		)
	var quest_gate_error := _get_quest_gate_error(definition_id, interaction_type, world_state)
	if not quest_gate_error.is_empty():
		return _failure(quest_gate_error, "交互前置不足", _get_quest_gate_detail(definition_id, interaction_type))

	if not _supports_interaction(definition, interaction_type):
		return _failure("当前目标不支持该交互。", "交互不可用", "换一个可交互目标，或查看附近提示。")

	var tool_error := _get_tool_requirement_error(definition, character_state)
	if not tool_error.is_empty():
		return _failure(tool_error, "工具能力不足", "检查当前工具能力，或先推进任务解锁合适工具。")

	match interaction_type:
		"gather":
			return _gather(instance_id, definition, character_state, world_state)
		"sample":
			return _sample(instance_id, definition, character_state, world_state)
		"clear":
			_set_map_object_flag(world_state, instance_id, definition_id, "is_cleared", true)
			if definition_id == "map_object.phase_well_anchor_pressure_pin":
				return _success("锚场压力钉已清理：继续清掉剩余压力钉，稳场守脉体会完全暴露。")
			if definition_id == "map_object.phase_well_frame_route_blocker":
				return _success("锁相框架侧路已清理：边缕残条回收线打开，另一侧路可以保留为未选路线。")
			if definition_id == "map_object.well_ash_crust_blocker":
				return _success("盐壳硬壳已清理：盐壳余烬回收线打开。")
			if definition_id == "map_object.pressure_clearance_node":
				return _success("前线压力扰点已清除：带回压力清障回执，回基地用基础反应器解析防护收益。")
			return _success("%s已清理：现场保留已清理标记；现在可以铺设基础地基。" % _get_display_name(definition_id))
		"inspect":
			if BaseActionDispatchPlan.is_frontline_window_object(definition_id):
				if not BaseActionDispatchPlan.is_frontline_window_active(world_state):
					return _failure(
						"前线异常窗口还没有载入出发整备计划。",
						"窗口未激活",
						"先在基地前线行动台确认整备槽，再从相位回投台出发。"
					)
				var window_blocker := BaseActionDispatchPlan.get_frontline_window_blocker(world_state)
				if not window_blocker.is_empty():
					return _failure(window_blocker, "窗口被守卫压制", "先击退清障扰动守卫，再回来处理异常窗口。")
				_set_map_object_flag(world_state, instance_id, definition_id, "is_sampled", true)
				var window_messages := BaseActionDispatchPlan.resolve_frontline_window(world_state)
				if window_messages.is_empty():
					return _failure(
						"前线异常窗口缺少可处理的计划快照。",
						"窗口状态异常",
						"回基地重新确认出发整备槽，再从相位回投台出发。"
					)
				return _success(" ".join(window_messages))
			if _is_persistent_field_reading(definition_id):
				_set_map_object_flag(world_state, instance_id, definition_id, "is_sampled", true)
				return _success(_format_field_reading_result(definition_id, world_state))
			if definition_id == "map_object.steady_supply_drop_marker":
				_set_map_object_flag(world_state, instance_id, definition_id, "is_sampled", true)
				return _success("稳场补给回执已读取：回基地用基础反应器解析补给收益。")
			if definition_id == "map_object.phase_survey_node_west":
				_set_map_object_flag(world_state, instance_id, definition_id, "is_sampled", true)
				return _success("西侧相位测绘读数已写入：继续读取东侧测绘点，再回基地解析路线提示。")
			if definition_id == "map_object.phase_survey_node_east":
				_set_map_object_flag(world_state, instance_id, definition_id, "is_sampled", true)
				return _success("东侧相位测绘读数已写入：两处读数完成后回基地解析路线提示。")
			if _is_frontline_single_use_reading(definition_id):
				_set_map_object_flag(world_state, instance_id, definition_id, "is_sampled", true)
				return _success(_format_frontline_single_use_reading_result(definition_id))
			if definition_id == "map_object.demo_stabilization_core":
				_set_map_object_flag(world_state, instance_id, definition_id, "is_sampled", true)
				return _success("核心稳定数据已写入：锚定桥稳窗和高压窗口归档数据接入核心设备，第一条稳定通道已打开。%s" % _apply_demo_stabilization_write_pressure(character_state, world_state))
			return _success("交互完成。")
		_:
			return _success("交互完成。")


func _interact_with_outpost_core(character_state: CharacterState, world_state: WorldState) -> Dictionary:
	if not world_state.quest_state.has_completed_quest("quest.restore_outpost"):
		return _success("前哨核心已恢复，晶体矿脉区已标记。")

	var supply_detail := _restock_basic_storage_supply(character_state, world_state)
	var restoration := character_state.restore_vitals_to_full()
	var restored_health := float(restoration.get("restored_health", 0.0))
	var restored_protection := float(restoration.get("restored_protection", 0.0))
	var readiness_detail := DepartureReadinessFormatter.format_feedback_detail(world_state, character_state)
	if restored_health <= 0.0 and restored_protection <= 0.0 and supply_detail.is_empty():
		return {
			"success": true,
			"message": "前哨核心出发检查：%s。" % readiness_detail,
			"supply_feedback": {
				"title": "出发准备检查",
				"detail": readiness_detail
			}
		}

	var detail_parts: Array[String] = []
	var vitals_detail := _format_outpost_core_refit_detail(character_state, restored_health, restored_protection)
	if not vitals_detail.is_empty():
		detail_parts.append(vitals_detail)
	if not supply_detail.is_empty():
		detail_parts.append(supply_detail)
	detail_parts.append("出发检查：%s" % readiness_detail)
	var detail := "；".join(detail_parts)
	return {
		"success": true,
		"message": "前哨核心整备完成：%s。" % detail,
		"supply_feedback": {
			"title": "前哨整备完成",
			"detail": detail
		}
	}


func _inspect_outpost_departure_gate(character_state: CharacterState, world_state: WorldState) -> Dictionary:
	var status := DepartureReadinessFormatter.format_departure_gate_status(world_state, character_state)
	var next_step := DepartureReadinessFormatter.format_departure_gate_next_step(world_state, character_state)
	return _success_feedback(
		"外勤出发口检查：%s；下一步：%s。" % [status, next_step],
		"外勤出发口检查",
		status,
		next_step
	)


func _inspect_completed_demo_stabilization_core(
	instance_id: String,
	definition_id: String,
	character_state: CharacterState,
	world_state: WorldState
) -> Dictionary:
	_set_map_object_flag(world_state, instance_id, definition_id, "is_sampled", true)
	var status := CoreStabilizationPressureFormatter.format_core_revisit_completion_parts(world_state, character_state)
	var next_step := CoreStabilizationPressureFormatter.format_core_revisit_next_step(world_state, character_state)
	return _success_feedback(
		CoreStabilizationPressureFormatter.format_core_revisit_feedback_message(world_state, character_state),
		"核心稳定站复测",
		status,
		next_step
	)


func _restock_basic_storage_supply(character_state: CharacterState, world_state: WorldState) -> String:
	if not world_state.has_base_structure_definition("building.basic_storage"):
		return ""

	var detail_parts: Array[String] = []
	var current_repair_gel := int(character_state.inventory.items.get("item.repair_gel", 0))
	if current_repair_gel < BASIC_STORAGE_REPAIR_GEL_TARGET:
		var granted_gel_amount := BASIC_STORAGE_REPAIR_GEL_TARGET - current_repair_gel
		character_state.inventory.add_item("item.repair_gel", granted_gel_amount)
		detail_parts.append("基础储存箱补修复凝胶 x%d，当前 %d" % [
			granted_gel_amount,
			int(character_state.inventory.items.get("item.repair_gel", 0))
		])

	if _can_restock_basic_storage_vial(character_state, world_state):
		var target_vial := _get_basic_storage_vial_target(world_state)
		var current_vial := int(character_state.inventory.items.get("item.resistance_vial_t1", 0))
		var granted_vial_amount := target_vial - current_vial
		character_state.inventory.add_item("item.resistance_vial_t1", granted_vial_amount)
		if target_vial > BASIC_STORAGE_RESISTANCE_VIAL_TARGET:
			detail_parts.append("基础储存箱经污染浆液缓冲罐补抗污染药剂 x%d，当前 %d / %d" % [
				granted_vial_amount,
				int(character_state.inventory.items.get("item.resistance_vial_t1", 0)),
				target_vial
			])
		else:
			detail_parts.append("基础储存箱补抗污染药剂 x%d，当前 %d" % [
				granted_vial_amount,
				int(character_state.inventory.items.get("item.resistance_vial_t1", 0))
			])

	return "；".join(detail_parts)


func _can_restock_basic_storage_vial(character_state: CharacterState, world_state: WorldState) -> bool:
	if not world_state.has_base_structure_definition("building.pollution_filter"):
		return false
	if not _has_basic_storage_vial_supply_unlocked(world_state):
		return false
	return int(character_state.inventory.items.get("item.resistance_vial_t1", 0)) < _get_basic_storage_vial_target(world_state)


func _has_basic_storage_vial_supply_unlocked(world_state: WorldState) -> bool:
	return (
		world_state.quest_state.has_completed_quest("quest.enter_pollution_edge")
		or world_state.quest_state.get_objective_progress("quest.enter_pollution_edge", "craft_item", "item.resistance_vial_t1") >= 1.0
	)


func _get_basic_storage_vial_target(world_state: WorldState) -> int:
	if world_state.has_base_structure_definition("building.slurry_buffer_tank"):
		return SLURRY_BUFFER_RESISTANCE_VIAL_TARGET
	return BASIC_STORAGE_RESISTANCE_VIAL_TARGET


func _interact_with_field_outfitting_station(character_state: CharacterState, world_state: WorldState) -> Dictionary:
	if not world_state.has_base_structure_definition(FIELD_OUTFITTING_STATION_ID):
		return _failure(
			"出发整备台尚未建成。",
			"整备台未上线",
			"先在基地平台完成出发整备台建造点。"
		)

	if FieldOutfittingRuntime.has_filter_module_equipped(character_state):
		if FieldOutfittingRuntime.is_module_calibrated(world_state):
			return _success_feedback(
				"出发整备台复查完成：基础过滤模块已完成晶体校准，污染采集和污染反击承压继续下降。",
				"模块校准已生效",
				"基础过滤模块已校准",
				"沿外勤出发口回污染边界或更深区域复测，HUD 和战斗读数会读取这项整备收益。"
			)
		if not FieldOutfittingRuntime.has_calibration_materials(character_state):
			return _failure(
				"基础过滤模块已装入防护服，但缺少晶体侧路维护材料。",
				"维护材料不足",
				"回晶体侧路补晶体矿 x%d 和残骸废件 x%d，再回出发整备台校准模块。"
					% [
						FieldOutfittingRuntime.MODULE_CALIBRATION_CRYSTAL_COST,
						FieldOutfittingRuntime.MODULE_CALIBRATION_SCRAP_COST
					]
			)
		if not FieldOutfittingRuntime.consume_calibration_materials(character_state):
			return _failure(
				"基础过滤模块校准失败。",
				"维护未完成",
				"确认晶体矿和残骸废件都已放入背包，再重新尝试。"
			)
		FieldOutfittingRuntime.mark_module_calibrated(world_state)
		var calibration_result := _success_feedback(
			"出发整备台完成维护校准：晶体侧路材料已写入基础过滤模块，污染采集和污染反击承压继续下降。",
			"模块校准完成",
			"基础过滤模块已校准",
			"污染采集、污染敌人反击和出发口 HUD 已读取校准收益。"
		)
		calibration_result["outfitting_module_calibrated"] = true
		return calibration_result

	if not character_state.inventory.has_ref(BASIC_FILTER_MODULE_ID, 1):
		return _failure(
			"缺少基础过滤模块。",
			"整备材料不足",
			"先用基础反应器组装基础过滤模块；若缺晶体和废件，走晶体侧路补料。"
		)

	if not character_state.equip_suit_module(BASIC_FILTER_MODULE_ID):
		return _failure(
			"基础过滤模块装配失败。",
			"整备未完成",
			"检查防护服模块槽和装备库存，再重新尝试。"
		)

	if FieldOutfittingRuntime.has_calibration_materials(character_state):
		var equipped_and_ready := _success_feedback(
			"出发整备完成：基础过滤模块已装入防护服，晶体侧路材料足够继续校准模块。",
			"出发整备完成",
			"基础过滤模块已装入防护服",
			"再次操作出发整备台可消耗晶体矿和残骸废件完成维护校准。"
		)
		equipped_and_ready["outfitting_module_enabled"] = true
		return equipped_and_ready

	var result := _success_feedback(
		"出发整备完成：基础过滤模块已装入防护服，污染消耗和污染反击压力降低。",
		"出发整备完成",
		"基础过滤模块已装入防护服",
		"带模块返回污染边界；晶体侧路余料可回整备台维护校准。"
	)
	result["outfitting_module_enabled"] = true
	return result


func _gather(instance_id: String, definition: Dictionary, character_state: CharacterState, world_state: WorldState) -> Dictionary:
	var rewards := _grant_refs(definition.get("drops", []), character_state)
	var protection_drain := _apply_pollution_pressure(instance_id, definition, character_state, world_state)
	_set_map_object_flag(world_state, instance_id, String(definition.get("id", "")), "is_gathered", true)

	var result_parts: Array[String] = []
	var completion_label := _get_gather_completion_label(definition)
	var object_name := _get_display_name(String(definition.get("id", "")))
	if rewards.is_empty():
		result_parts.append("%s%s" % [object_name, completion_label])
	else:
		result_parts.append("%s%s：%s" % [object_name, completion_label, ", ".join(rewards)])
	result_parts.append("现场保留%s标记" % completion_label)
	if protection_drain > 0.0:
		result_parts.append("污染压力消耗防护 %s%s" % [
			_format_amount(protection_drain),
			_get_pollution_protection_hint(character_state, world_state)
		])
		var pressure_hint := _get_pollution_pressure_step_hint(instance_id, character_state)
		if not pressure_hint.is_empty():
			result_parts.append(pressure_hint)
	var first_hour_hint := _get_first_hour_gather_step_hint(instance_id, world_state, character_state)
	if not first_hour_hint.is_empty():
		result_parts.append(first_hour_hint)

	return _success("%s。" % "；".join(result_parts))


func _sample(instance_id: String, definition: Dictionary, character_state: CharacterState, world_state: WorldState) -> Dictionary:
	var sample_refs: Array = definition.get("sample_result_refs", [])
	var rewards: Array[String] = []
	for sample_id in sample_refs:
		var definition_id := String(sample_id)
		if definition_id.is_empty():
			continue
		character_state.inventory.add_ref(definition_id, 1)
		rewards.append("%s x1" % _get_display_name(definition_id))

	_set_map_object_flag(world_state, instance_id, String(definition.get("id", "")), "is_sampled", true)
	if rewards.is_empty():
		return _success("%s已采样：现场保留已采样标记。" % _get_display_name(String(definition.get("id", ""))))
	return _success("%s已采样：%s；现场保留已采样标记；回基地解析样本。" % [
		_get_display_name(String(definition.get("id", ""))),
		", ".join(rewards)
	])


func _apply_demo_stabilization_write_pressure(character_state: CharacterState, world_state: WorldState) -> String:
	var used_vial := character_state.inventory.has_ref("item.resistance_vial_t1", 1)
	var used_core_buffer := _has_core_stabilization_guard_buffer_sync(world_state)
	var used_recovery_cache := _has_demo_stabilization_recovery_cache(world_state)
	var used_guard_cache := _has_demo_stabilization_guard_cache(world_state)
	var pressure_mult := 1.0
	if used_vial:
		character_state.inventory.consume_ref("item.resistance_vial_t1", 1)
		pressure_mult *= DEMO_STABILIZATION_WRITE_VIAL_MULT
	if used_core_buffer:
		pressure_mult *= DEMO_STABILIZATION_WRITE_CORE_BUFFER_MULT
	if used_recovery_cache:
		pressure_mult *= DEMO_STABILIZATION_WRITE_RECOVERY_CACHE_MULT
	if used_guard_cache:
		pressure_mult *= DEMO_STABILIZATION_WRITE_GUARD_CACHE_MULT

	var health_pressure := DEMO_STABILIZATION_WRITE_HEALTH_PRESSURE * pressure_mult * character_state.get_pollution_counter_damage_multiplier(data_registry)
	var protection_pressure := DEMO_STABILIZATION_WRITE_PROTECTION_PRESSURE * pressure_mult * character_state.get_pollution_drain_multiplier(data_registry)
	var health_damage := character_state.apply_health_damage(health_pressure)
	var protection_damage := character_state.apply_protection_damage(protection_pressure)
	return _format_demo_stabilization_write_pressure(
		used_vial,
		used_core_buffer,
		used_recovery_cache,
		used_guard_cache,
		health_damage,
		protection_damage
	)


func _format_demo_stabilization_write_pressure(
	used_vial: bool,
	used_core_buffer: bool,
	used_recovery_cache: bool,
	used_guard_cache: bool,
	health_damage: float,
	protection_damage: float
) -> String:
	var health_text := _format_amount(health_damage)
	var protection_text := _format_amount(protection_damage)
	var pressure_text := "抗污染药剂已自动接入写入排压" if used_vial else "没有抗污染药剂参与排压"
	var prepared_parts: Array[String] = []
	if used_recovery_cache:
		prepared_parts.append("核心站侧边补给")
	if used_guard_cache:
		prepared_parts.append("守卫回写缓存")
	if used_core_buffer:
		prepared_parts.append("稳压缓冲包")
	var ready_count := prepared_parts.size()
	if used_vial:
		ready_count += 1

	if not prepared_parts.is_empty():
		var payoff := "核心设备承压低于无准备写入"
		if used_core_buffer:
			payoff = "终点前整备同时降低守卫和核心设备承压，核心设备承压低于无准备写入"
		return " 终点准备 %d/4：%s已串入写入校准，%s，生命 -%s，防护 -%s；%s。" % [
			ready_count,
			"、".join(prepared_parts),
			pressure_text,
			health_text,
			protection_text,
			payoff
		]

	if used_vial:
		return " 终点准备 1/4：%s，生命 -%s，防护 -%s；药剂让核心设备承压低于无准备写入。" % [
			pressure_text,
			health_text,
			protection_text
		]
	return " 终点准备 0/4：没有抗污染药剂参与排压，核心写入反冲完整命中，生命 -%s，防护 -%s；下次终点写入前应确认守卫缓存补给。" % [
		health_text,
		protection_text
	]


func _has_core_stabilization_guard_buffer_sync(world_state: WorldState) -> bool:
	if world_state == null:
		return false
	return bool(world_state.get_enemy("enemy_instance.demo_stabilization_guard").get("core_buffer_used", false))


func _has_demo_stabilization_recovery_cache(world_state: WorldState) -> bool:
	if world_state == null:
		return false
	return (
		bool(world_state.get_map_object("map_object_instance.demo_stabilization_recovery_cache").get("is_gathered", false))
		or bool(world_state.get_map_object("map_object_instance.demo_stabilization_recovery_wreckage").get("is_gathered", false))
	)


func _has_demo_stabilization_guard_cache(world_state: WorldState) -> bool:
	if world_state == null:
		return false
	return bool(world_state.get_map_object("map_object_instance.demo_stabilization_guard_cache").get("is_gathered", false))


func _grant_refs(refs: Array, character_state: CharacterState) -> Array[String]:
	var rewards: Array[String] = []
	for ref in refs:
		if not ref is Dictionary:
			continue

		var reward_id := String(ref.get("id", ""))
		var amount := float(ref.get("amount", 0.0))
		if reward_id.is_empty() or amount <= 0.0:
			continue

		if not reward_id.begins_with("item.") and not reward_id.begins_with("fluid.") and not reward_id.begins_with("equipment."):
			continue

		character_state.inventory.add_ref(reward_id, amount)
		rewards.append("%s x%s" % [_get_display_name(reward_id), _format_amount(amount)])
	return rewards


func _apply_pollution_pressure(
	instance_id: String,
	definition: Dictionary,
	character_state: CharacterState,
	world_state: WorldState
) -> float:
	var pollution_id := String(definition.get("pollution_effect", ""))
	if pollution_id.is_empty():
		return 0.0

	var pollution_definition := data_registry.get_definition(pollution_id)
	var base_drain := 0.0
	for hazard_effect in pollution_definition.get("hazard_effects", []):
		if not hazard_effect is Dictionary:
			continue
		if String(hazard_effect.get("effect", "")) != "protection_drain":
			continue
		base_drain += float(hazard_effect.get("amount", 0.0)) * PROTOTYPE_POLLUTION_PRESSURE_MULT

	if base_drain <= 0.0:
		return 0.0

	var pressure_multiplier := float(POLLUTION_RESIDUE_PRESSURE_BY_INSTANCE.get(instance_id, 1.0))
	var actual_drain := (
		base_drain
		* pressure_multiplier
		* character_state.get_pollution_drain_multiplier(data_registry)
		* FieldOutfittingRuntime.get_pollution_drain_multiplier(character_state, world_state)
	)
	character_state.protection = maxf(0.0, character_state.protection - actual_drain)
	return actual_drain


func _get_pollution_protection_hint(character_state: CharacterState, world_state: WorldState) -> String:
	var module_id := String(character_state.equipment.get("suit_module", ""))
	if module_id.is_empty():
		return "，未启用过滤模块"
	if FieldOutfittingRuntime.has_active_module_calibration(character_state, world_state):
		return "，过滤模块校准已降低消耗"
	return "，过滤模块已降低消耗"


func _get_pollution_pressure_step_hint(instance_id: String, character_state: CharacterState) -> String:
	if instance_id == "map_object_instance.core_buffer_residue_cache":
		return "核心缓冲包补料沉积已回收；回过滤器处理成抗污染药剂和污染浆液，再回基础反应器整备缓冲包"
	if instance_id == "map_object_instance.pollution_residue_ridge_cache":
		if character_state.inventory.has_ref("item.resistance_vial_t1", 1):
			return "污染脊沉积已回收；回过滤器处理成药剂和污染浆液，浆液可回收成信标所需基础零件"
		return "污染脊沉积已回收；建议回过滤器处理沉积物，补药剂并留下浆液支撑稳相信标"
	if instance_id == "map_object_instance.pollution_residue_vial_return_cache":
		if character_state.inventory.has_ref("item.resistance_vial_t1", 1):
			return "侧翼沉积已回收；回过滤器处理成下一支药剂和污染浆液，再回污染边界处理门前压力"
		return "侧翼沉积已回收；建议回过滤器补抗污染药剂，污染浆液也能继续服务后续基建和解析"
	if instance_id == "map_object_instance.pollution_residue_slurry_return_cache":
		return "副产回收口袋沉积已回收；回过滤器补一份药剂和污染浆液，再到基础反应器把多余浆液回收成基础零件"
	if instance_id == "map_object_instance.pollution_residue_vial_reserve_cache":
		if character_state.inventory.has_ref("item.resistance_vial_t1", 1):
			return "药剂储备口袋沉积已回收；回过滤器补下一支抗污染药剂和污染浆液，继续支撑污染边界回访"
		return "药剂储备口袋沉积已回收；建议回过滤器补抗污染药剂，再把多余污染浆液带回基础反应器回收基础零件"
	if instance_id == "map_object_instance.outer_ring_echo_residue_cache":
		return "污染回波沉积已回收；回过滤器处理成抗污染药剂和污染浆液，再带回波匣回基地解析裂相坐标"
	if instance_id == "map_object_instance.pollution_residue_deep":
		return "深处压力已显著抬升；后续门前点更适合带药剂再处理"
	return ""


func _get_first_hour_gather_step_hint(
	instance_id: String,
	world_state: WorldState,
	character_state: CharacterState
) -> String:
	match instance_id:
		"map_object_instance.crystal_cluster_treatment_approach":
			return "这些晶体可回基地加工成过滤模块或地基材料"
		"map_object_instance.crystal_cluster_logistics_pocket":
			return "侧路晶体可回基地加工基础零件，也可配合废件在出发整备台维护校准过滤模块"
		"map_object_instance.field_wreckage_treatment_approach":
			return "残骸废件可补反应器校准；继续向处理点入口前确认补给余量"
		"map_object_instance.field_wreckage_logistics_pocket":
			return "侧路废件可补反应器校准，也可配合晶体在出发整备台维护校准过滤模块"
		"map_object_instance.crystal_cluster_foundation_return":
			return "处理点入口前的回访晶体已补足；回基地加工基础零件或地基材料"
		"map_object_instance.field_wreckage_foundation_return":
			return "处理点入口前的残骸缓存已回收；若地基或过滤器缺料，先回基地整理制造"
		"map_object_instance.demo_stabilization_recovery_cache":
			return "核心站侧边补给已回收；修复凝胶和抗污染药剂可支撑阶段守卫战，并在核心写入时降低反冲"
		"map_object_instance.demo_stabilization_guard_cache":
			return CoreGuardAftermathFormatter.format_guard_cache_gather_followup(world_state, character_state)
	return ""


func _get_gather_completion_label(definition: Dictionary) -> String:
	match String(definition.get("object_type", "")):
		"resource_node":
			return "已采集"
		_:
			return "已回收"


func _format_already_processed_message(
	definition_id: String,
	interaction_type: String,
	character_state: CharacterState,
	world_state: WorldState
) -> String:
	var object_name := _get_display_name(definition_id)
	match interaction_type:
		"gather":
			var core_cache_status := CoreStabilizationPressureFormatter.format_completed_cache_status(
				definition_id,
				world_state,
				character_state
			)
			if not core_cache_status.is_empty():
				return "%s：%s" % [object_name, core_cache_status]
			if definition_id == "map_object.crystal_cluster" or definition_id == "map_object.rich_crystal_vein":
				return "%s已采集，现场保留已采集标记。" % object_name
			return "%s已回收，现场保留已回收标记。" % object_name
		"sample":
			return "%s已采样，现场保留已采样标记。" % object_name
		"clear":
			return "%s已清理，现场保留已清理标记。" % object_name
		"inspect":
			return "%s已确认，现场保留完成态标记。" % object_name
		_:
			return "%s已处理，现场保留完成态标记。" % object_name


func _format_outpost_core_refit_detail(
	character_state: CharacterState,
	restored_health: float,
	restored_protection: float
) -> String:
	var parts: Array[String] = []
	if restored_health > 0.0:
		parts.append("生命 +%s，当前 %s / %s" % [
			_format_amount(restored_health),
			_format_amount(character_state.health),
			_format_amount(character_state.max_health)
		])
	if restored_protection > 0.0:
		parts.append("防护 +%s，当前 %s / %s" % [
			_format_amount(restored_protection),
			_format_amount(character_state.protection),
			_format_amount(character_state.max_protection)
		])
	return "；".join(parts)


func _format_amount(amount: float) -> String:
	if is_equal_approx(amount, roundf(amount)):
		return str(int(amount))
	return "%.1f" % amount


func _get_display_name(definition_id: String) -> String:
	var definition := data_registry.get_definition(definition_id)
	if definition.is_empty():
		return definition_id
	return data_registry.get_text(String(definition.get("display_name_key", definition_id)))


func _format_frontline_action_console_result(quest_id: String) -> String:
	match quest_id:
		"quest.plan_stability_frontline_action":
			return "前线行动台已确认：本趟只派发稳窗回波探点；用相位回投返回锚定桥东侧读取样本。"
		"quest.confirm_supply_frontline_action":
			return "补给短行动已确认：本趟只派发补给回执标记；用相位回投返回锚定桥前线读取回执。"
		"quest.confirm_route_frontline_action":
			return "巡线短行动已确认：本趟只派发巡线信标；用相位回投返回锚定桥前线读取信标。"
		_:
			return "前线行动台已确认。"


func _supports_interaction(definition: Dictionary, interaction_type: String) -> bool:
	var interaction_types: Array = definition.get("interaction_types", [])
	return interaction_types.has(interaction_type)


func _get_tool_requirement_error(definition: Dictionary, character_state: CharacterState) -> String:
	var required_tool_tags: Array = definition.get("required_tool_tags", [])
	if required_tool_tags.is_empty():
		return ""

	var tool_id := String(character_state.equipment.get("tool", ""))
	var tool_definition := data_registry.get_definition(tool_id)
	var tool_effects: Array = tool_definition.get("effects", [])
	var missing_tags: Array[String] = []

	for required_tool_tag in required_tool_tags:
		var tag := String(required_tool_tag)
		if tool_effects.has("effect.%s" % tag) or tool_effects.has(tag):
			continue
		missing_tags.append(tag)

	if missing_tags.is_empty():
		return ""
	return "当前工具缺少能力：%s。" % ", ".join(missing_tags)


func _get_quest_gate_error(definition_id: String, interaction_type: String, world_state: WorldState) -> String:
	if definition_id == "map_object.demo_stabilization_core" and interaction_type == "inspect":
		if world_state.quest_state.has_completed_quest("quest.write_demo_stabilization_core"):
			return ""
		if not world_state.quest_state.has_active_quest("quest.write_demo_stabilization_core"):
			return "核心稳定设备尚未开放写入。"
		if not bool(world_state.get_enemy("enemy_instance.demo_stabilization_guard").get("is_defeated", false)):
			return "核心阶段守卫仍在压制写入平台。"
		if world_state.quest_state.get_objective_progress("quest.write_demo_stabilization_core", "gather_item", "item.core_write_charge") < 1.0:
			return "核心写入校验片尚未回收。"
		return ""
	if definition_id != "map_object.anomaly_crystal" or interaction_type != "sample":
		if definition_id != "map_object.anomaly_residue_patch" or interaction_type != "gather":
			return ""
		if world_state.quest_state.has_active_quest("quest.analyze_anomaly_sample"):
			return ""
		if world_state.quest_state.has_completed_quest("quest.analyze_anomaly_sample"):
			return ""
		return "异常残留点尚未纳入分析目标。"
	if world_state.quest_state.has_active_quest("quest.bring_back_sample"):
		return ""
	if world_state.quest_state.has_completed_quest("quest.bring_back_sample"):
		return ""
	return "异常晶体采样通道尚未校准。"


func _get_quest_gate_detail(definition_id: String, interaction_type: String) -> String:
	if definition_id == "map_object.demo_stabilization_core" and interaction_type == "inspect":
		return "先进入核心稳定站，回基地整备核心稳压缓冲包，击败核心阶段守卫后回收回写缓存，再回来写入稳定数据。"
	if definition_id == "map_object.anomaly_crystal" and interaction_type == "sample":
		return "先完成反应器校准件，再按任务目标采样异常晶体。"
	if definition_id == "map_object.anomaly_residue_patch" and interaction_type == "gather":
		return "先带回异常晶体样本，再按分析任务回收周边残留物。"
	return "先完成当前前置目标，再回来处理这个目标。"


func _is_already_processed(object_state: Dictionary, interaction_type: String) -> bool:
	match interaction_type:
		"gather":
			return bool(object_state.get("is_gathered", false))
		"sample":
			return bool(object_state.get("is_sampled", false))
		"inspect":
			return bool(object_state.get("is_sampled", false))
		"clear":
			return bool(object_state.get("is_cleared", false))
		_:
			return false


func _set_map_object_flag(
	world_state: WorldState,
	instance_id: String,
	definition_id: String,
	flag_name: String,
	value: bool
) -> void:
	world_state.ensure_map_object(instance_id, definition_id)
	world_state.set_map_object_flag(instance_id, flag_name, value)


func _is_persistent_field_reading(definition_id: String) -> bool:
	return (
		definition_id == "map_object.phase_splinter_resonance_node"
		or definition_id == "map_object.fault_residue_pulse_node"
		or definition_id == "map_object.well_flux_pressure_vent"
		or definition_id == "map_object.phase_well_chamber_shunt_node"
		or definition_id == "map_object.phase_well_loom_tension_spool"
		or definition_id == "map_object.phase_well_tether_knot_node"
	)


func _is_frontline_single_use_reading(definition_id: String) -> bool:
	return (
		definition_id == "map_object.stability_echo_probe"
		or definition_id == "map_object.supply_return_marker"
		or definition_id == "map_object.route_signal_marker"
	)


func _format_frontline_single_use_reading_result(definition_id: String) -> String:
	match definition_id:
		"map_object.stability_echo_probe":
			return "稳窗回波样本已读取：这趟短回访已完成，回基地用基础反应器解析前线行动回报。"
		"map_object.supply_return_marker":
			return "补给回执标记已读取：第二条短回访已完成，回基地用基础反应器解析短行动反馈。"
		"map_object.route_signal_marker":
			return "巡线信标已读取：回基地用基础反应器解析巡线反馈。"
		_:
			return "前线读点已读取。"


func _format_field_reading_result(definition_id: String, world_state: WorldState) -> String:
	var result: Dictionary = FIELD_READING_RESULTS.get(definition_id, {})
	if result.is_empty():
		return "现场读数已写入。"
	var quest_id := String(result.get("quest_id", ""))
	var objective_type := String(result.get("objective_type", "inspect"))
	var target_id := String(result.get("target_id", definition_id))
	var required := float(result.get("required", 1.0))
	var current := world_state.quest_state.get_objective_progress(quest_id, objective_type, target_id)
	var next_progress := minf(required, current + 1.0)
	var suffix := String(result.get("partial", "继续检查剩余现场读数点。"))
	if next_progress >= required:
		suffix = String(result.get("complete", "现场读数已全部写入。"))
	return "%s已写入：%s/%s；%s" % [
		String(result.get("step", "现场读数")),
		_format_amount(next_progress),
		_format_amount(required),
		suffix
	]


func _success(message: String) -> Dictionary:
	return {
		"success": true,
		"message": message
	}


func _success_feedback(message: String, title: String, status: String, next_step: String) -> Dictionary:
	return {
		"success": true,
		"message": message,
		"success_feedback": {
			"title": title,
			"status": status,
			"next_step": next_step
		}
	}


func _failure(message: String, title: String = "交互未完成", detail: String = "") -> Dictionary:
	return {
		"success": false,
		"message": message,
		"failure_feedback": {
			"title": title,
			"detail": detail
		}
	}
