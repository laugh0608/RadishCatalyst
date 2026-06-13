extends RefCounted
class_name DepartureReadinessFormatter

const BASIC_STORAGE_RESISTANCE_VIAL_TARGET := 1
const SLURRY_BUFFER_RESISTANCE_VIAL_TARGET := 2


static func format_hud_summary(world_state: WorldState, character_state: CharacterState) -> Array[String]:
	if world_state.current_region_id != "region.outpost_platform":
		return []
	if not _has_any_departure_facility(world_state) and not _can_build_outfitting_station(character_state):
		return []
	var lines: Array[String] = [
		"出发准备：%s；%s" % [
			format_module_state(world_state, character_state),
			format_supply_state(world_state, character_state)
		],
		"收益：%s" % format_pressure_payoff(world_state)
	]
	var next_sortie_line := CoreGuardAftermathFormatter.format_next_sortie_hud_line(world_state, character_state)
	if not next_sortie_line.is_empty():
		lines.append(next_sortie_line)
	return lines


static func format_outpost_core_prompt(world_state: WorldState, character_state: CharacterState) -> String:
	var restock_names := get_restock_supply_names(world_state, character_state)
	var parts: Array[String] = ["前哨核心：出发准备检查"]
	parts.append("状态：%s；%s。" % [
		format_module_state(world_state, character_state),
		format_supply_state(world_state, character_state)
	])
	parts.append("收益：%s。" % format_pressure_payoff(world_state))
	var aftermath_line := CoreGuardAftermathFormatter.format_outpost_line(world_state, character_state)
	if not aftermath_line.is_empty():
		parts.append("%s。" % aftermath_line)
	var next_sortie_line := CoreGuardAftermathFormatter.format_next_sortie_outpost_line(world_state, character_state)
	if not next_sortie_line.is_empty():
		parts.append("%s。" % next_sortie_line)
	if not restock_names.is_empty():
		parts.append("操作：E 补%s并恢复生命 / 防护。" % " / ".join(restock_names))
	elif not character_state.are_vitals_full():
		parts.append("操作：E 恢复生命 / 防护。")
	else:
		parts.append("操作：E 检查整备状态。")
	return "\n".join(parts)


static func format_outfitting_station_prompt(world_state: WorldState, character_state: CharacterState) -> String:
	var parts: Array[String] = ["设施：出发整备台"]
	parts.append("状态：%s；%s。" % [
		format_module_state(world_state, character_state),
		format_supply_state(world_state, character_state)
	])
	parts.append("收益：%s。" % format_pressure_payoff(world_state))
	return "\n".join(parts)


static func format_departure_gate_status(world_state: WorldState, character_state: CharacterState) -> String:
	if not world_state.quest_state.has_completed_quest("quest.restore_outpost"):
		return "前哨未恢复；先检查前哨核心"
	var parts: Array[String] = [
		"%s；%s" % [
			format_module_state(world_state, character_state),
			format_supply_state(world_state, character_state)
		],
		"收益：%s" % format_pressure_payoff(world_state)
	]
	var next_sortie_line := CoreGuardAftermathFormatter.format_next_sortie_outpost_line(world_state, character_state)
	if not next_sortie_line.is_empty():
		parts.append(next_sortie_line)
	return "；".join(parts)


static func format_departure_gate_next_step(world_state: WorldState, character_state: CharacterState) -> String:
	if not world_state.quest_state.has_completed_quest("quest.restore_outpost"):
		return "先按 E 恢复前哨核心，解锁基地出发路线"
	if not get_restock_supply_names(world_state, character_state).is_empty() or not character_state.are_vitals_full():
		return "先在前哨核心补给并恢复生命 / 防护"
	if String(character_state.equipment.get("suit_module", "")) != "equipment.filter_module_t1":
		if world_state.has_base_structure_definition("building.field_outfitting_station"):
			return "先到出发整备台确认基础过滤模块"
		return "先补建出发整备台，或按当前目标外出"
	if (
		world_state.has_base_structure_definition("building.field_outfitting_station")
		and not FieldOutfittingRuntime.is_module_calibrated(world_state)
		and FieldOutfittingRuntime.has_calibration_materials(character_state)
	):
		return "先到出发整备台校准基础过滤模块"
	var next_sortie_route := CoreGuardAftermathFormatter.format_next_sortie_route_line(world_state)
	if not next_sortie_route.is_empty():
		return next_sortie_route
	return "沿外勤出发口前往地图目标；若地图目标为空，按当前任务追踪推进"


static func format_departure_gate_feedback_detail(world_state: WorldState, character_state: CharacterState) -> String:
	return "%s；下一步：%s" % [
		format_departure_gate_status(world_state, character_state),
		format_departure_gate_next_step(world_state, character_state)
	]


static func format_feedback_detail(world_state: WorldState, character_state: CharacterState) -> String:
	var parts: Array[String] = [
		format_module_state(world_state, character_state),
		format_supply_state(world_state, character_state),
		format_pressure_payoff(world_state)
	]
	var aftermath_line := CoreGuardAftermathFormatter.format_outpost_line(world_state, character_state)
	if not aftermath_line.is_empty():
		parts.append(aftermath_line)
	var next_sortie_line := CoreGuardAftermathFormatter.format_next_sortie_outpost_line(world_state, character_state)
	if not next_sortie_line.is_empty():
		parts.append(next_sortie_line)
	return "；".join(parts)


static func format_module_state(world_state: WorldState, character_state: CharacterState) -> String:
	if FieldOutfittingRuntime.has_filter_module_equipped(character_state):
		if FieldOutfittingRuntime.has_active_module_calibration(character_state, world_state):
			return "模块已校准"
		if world_state.has_base_structure_definition("building.field_outfitting_station"):
			if FieldOutfittingRuntime.has_calibration_materials(character_state):
				return "模块可校准"
			return "模块待校准"
		return "模块已装"
	if world_state.has_base_structure_definition("building.field_outfitting_station"):
		if character_state.inventory.has_ref("equipment.filter_module_t1", 1):
			return "模块待装"
		return "缺基础过滤模块"
	if _can_build_outfitting_station(character_state):
		return "可建整备台"
	return "整备台未上线"


static func format_supply_state(world_state: WorldState, character_state: CharacterState) -> String:
	if not world_state.has_base_structure_definition("building.basic_storage"):
		return "补给未接前哨"
	var restock_names := get_restock_supply_names(world_state, character_state)
	if not restock_names.is_empty():
		return "回前哨核心补%s" % " / ".join(restock_names)
	var ready_names := get_ready_supply_names(world_state, character_state)
	if ready_names.is_empty():
		return "补给待处理"
	return "%s已备" % " / ".join(ready_names)


static func format_pressure_payoff(world_state: WorldState) -> String:
	if (
		FieldOutfittingRuntime.has_station_built(world_state)
		and FieldOutfittingRuntime.is_module_calibrated(world_state)
	):
		if world_state.quest_state.has_completed_quest("quest.write_demo_stabilization_core"):
			return "核心写入已归档，模块校准、补给和整备台用于下一趟外勤复测"
		if _is_core_stabilization_available(world_state):
			return "模块校准让污染采集和污染战斗承压继续下降，补给可参与守卫战和核心写入排压"
		if _has_slurry_buffer_tank(world_state):
			return "模块校准让污染采集和污染战斗承压继续下降，前哨可补双药剂"
		return "模块校准让污染采集和污染战斗承压继续下降"
	if world_state.quest_state.has_completed_quest("quest.write_demo_stabilization_core"):
		if _has_slurry_buffer_tank(world_state):
			return "核心写入已归档，双药剂补给和模块整备用于下一趟外勤复测"
		return "核心写入已归档，前哨补给和模块整备用于下一趟外勤复测"
	if _is_core_stabilization_available(world_state):
		if _has_slurry_buffer_tank(world_state):
			return "污染承压下降，双药剂补给可连续参与守卫战和核心写入排压"
		return "污染承压下降，药剂可参与核心写入排压"
	if _has_slurry_buffer_tank(world_state):
		return "污染采集和污染战斗承压下降，前哨可补双药剂"
	if _is_vial_supply_available(world_state):
		return "污染采集和污染战斗承压下降"
	return "模块装配后会降低污染采集和反击压力"


static func get_restock_supply_names(world_state: WorldState, character_state: CharacterState) -> Array[String]:
	var names: Array[String] = []
	if not world_state.has_base_structure_definition("building.basic_storage"):
		return names
	if not character_state.inventory.has_ref("item.repair_gel", 1):
		names.append("修复凝胶")
	if _can_restock_vial(world_state, character_state):
		var target_vial := _get_vial_target(world_state)
		if target_vial > BASIC_STORAGE_RESISTANCE_VIAL_TARGET:
			names.append("抗污染药剂到 %d" % target_vial)
		else:
			names.append("抗污染药剂")
	return names


static func get_ready_supply_names(world_state: WorldState, character_state: CharacterState) -> Array[String]:
	var names: Array[String] = []
	if character_state.inventory.has_ref("item.repair_gel", 1):
		names.append("修复凝胶")
	if _is_vial_supply_available(world_state):
		var current_vial := int(character_state.inventory.items.get("item.resistance_vial_t1", 0))
		var target_vial := _get_vial_target(world_state)
		if current_vial >= target_vial and target_vial > BASIC_STORAGE_RESISTANCE_VIAL_TARGET:
			names.append("抗污染药剂 x%d" % current_vial)
		elif current_vial >= BASIC_STORAGE_RESISTANCE_VIAL_TARGET:
			names.append("抗污染药剂")
	return names


static func _can_restock_vial(world_state: WorldState, character_state: CharacterState) -> bool:
	if not _is_vial_supply_available(world_state):
		return false
	return int(character_state.inventory.items.get("item.resistance_vial_t1", 0)) < _get_vial_target(world_state)


static func _is_vial_supply_available(world_state: WorldState) -> bool:
	return (
		world_state.has_base_structure_definition("building.pollution_filter")
		and (
			world_state.quest_state.has_completed_quest("quest.enter_pollution_edge")
			or world_state.quest_state.get_objective_progress("quest.enter_pollution_edge", "craft_item", "item.resistance_vial_t1") >= 1.0
		)
	)


static func _is_core_stabilization_available(world_state: WorldState) -> bool:
	if world_state.unlocked_region_ids.has("region.demo_stabilization_core"):
		return true
	for quest_id in CoreStabilizationPressureFormatter.CORE_QUEST_IDS:
		if world_state.quest_state.has_active_quest(quest_id) or world_state.quest_state.has_completed_quest(quest_id):
			return true
	return false


static func _has_any_departure_facility(world_state: WorldState) -> bool:
	return (
		world_state.has_base_structure_definition("building.basic_storage")
		or world_state.has_base_structure_definition("building.field_outfitting_station")
		or world_state.has_base_structure_definition("building.slurry_buffer_tank")
	)


static func _can_build_outfitting_station(character_state: CharacterState) -> bool:
	return (
		character_state.inventory.has_ref("item.basic_parts", 2)
		and character_state.inventory.has_ref("item.salvage_scrap", 1)
	)


static func _get_vial_target(world_state: WorldState) -> int:
	if _has_slurry_buffer_tank(world_state):
		return SLURRY_BUFFER_RESISTANCE_VIAL_TARGET
	return BASIC_STORAGE_RESISTANCE_VIAL_TARGET


static func _has_slurry_buffer_tank(world_state: WorldState) -> bool:
	return world_state.has_base_structure_definition("building.slurry_buffer_tank")
