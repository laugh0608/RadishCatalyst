extends RefCounted
class_name DepartureReadinessFormatter


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
	if String(character_state.equipment.get("suit_module", "")) == "equipment.filter_module_t1":
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
	if world_state.quest_state.has_completed_quest("quest.write_demo_stabilization_core"):
		return "核心写入已归档，前哨补给和模块整备用于下一趟外勤复测"
	if _is_core_stabilization_available(world_state):
		return "污染承压下降，药剂可参与核心写入排压"
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
		names.append("抗污染药剂")
	return names


static func get_ready_supply_names(world_state: WorldState, character_state: CharacterState) -> Array[String]:
	var names: Array[String] = []
	if character_state.inventory.has_ref("item.repair_gel", 1):
		names.append("修复凝胶")
	if _is_vial_supply_available(world_state) and character_state.inventory.has_ref("item.resistance_vial_t1", 1):
		names.append("抗污染药剂")
	return names


static func _can_restock_vial(world_state: WorldState, character_state: CharacterState) -> bool:
	return _is_vial_supply_available(world_state) and not character_state.inventory.has_ref("item.resistance_vial_t1", 1)


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
	)


static func _can_build_outfitting_station(character_state: CharacterState) -> bool:
	return (
		character_state.inventory.has_ref("item.basic_parts", 2)
		and character_state.inventory.has_ref("item.salvage_scrap", 1)
	)
