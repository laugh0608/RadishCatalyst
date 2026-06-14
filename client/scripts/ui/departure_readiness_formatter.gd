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
	var return_processing_line := format_core_archive_return_processing_line(world_state, character_state)
	if not return_processing_line.is_empty():
		lines.append(return_processing_line)
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
	var return_processing_line := format_core_archive_return_processing_line(world_state, character_state)
	if not return_processing_line.is_empty():
		parts.append("%s。" % return_processing_line)
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
	var return_processing_line := format_core_archive_return_processing_line(world_state, character_state)
	if not return_processing_line.is_empty():
		parts.append("%s。" % return_processing_line)
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
	var return_processing_line := format_core_archive_return_processing_line(world_state, character_state)
	if not return_processing_line.is_empty():
		parts.append(return_processing_line)
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
	if _should_maintain_core_archive(world_state, character_state):
		return "先到出发整备台接入核心归档维护"
	if (
		world_state.has_base_structure_definition("building.field_outfitting_station")
		and not FieldOutfittingRuntime.is_module_calibrated(world_state)
		and FieldOutfittingRuntime.has_calibration_materials(character_state)
	):
		return "先到出发整备台校准基础过滤模块"
	var core_archive_return_step := format_core_archive_return_next_step(world_state, character_state)
	if not core_archive_return_step.is_empty():
		return core_archive_return_step
	var next_sortie_route := CoreGuardAftermathFormatter.format_next_sortie_route_line(world_state)
	if not next_sortie_route.is_empty():
		return next_sortie_route
	return "沿外勤出发口前往地图目标；若地图目标为空，按当前任务追踪推进"


static func format_departure_gate_feedback_detail(world_state: WorldState, character_state: CharacterState) -> String:
	return "%s；下一步：%s" % [
		format_departure_gate_status(world_state, character_state),
		format_departure_gate_next_step(world_state, character_state)
	]


static func format_logistics_route_status(world_state: WorldState, character_state: CharacterState) -> String:
	var parts: Array[String] = [
		"前哨核心：%s" % _format_logistics_core_state(world_state, character_state),
		"储存箱：%s" % _format_logistics_storage_state(world_state),
		"浆液缓冲罐：%s" % _format_logistics_slurry_buffer_state(world_state),
		"出发整备台：%s" % format_module_state(world_state, character_state),
		"外勤出发口：%s" % _format_logistics_exit_state(world_state, character_state)
	]
	return "；".join(parts)


static func format_logistics_route_next_step(world_state: WorldState, character_state: CharacterState) -> String:
	if not world_state.quest_state.has_completed_quest("quest.restore_outpost"):
		return "先恢复前哨核心，后勤路线才会串起补给、整备和出发口"
	if not world_state.has_base_structure_definition("building.basic_storage"):
		return "先补建储存箱，让前哨核心能补修复凝胶和抗污染药剂"
	if not world_state.has_base_structure_definition("building.field_outfitting_station"):
		if _can_build_outfitting_station(character_state):
			return "先补建出发整备台，把基础过滤模块纳入出发检查"
		return format_departure_gate_next_step(world_state, character_state)

	var departure_step := format_departure_gate_next_step(world_state, character_state)
	if not departure_step.begins_with("沿外勤出发口"):
		return departure_step
	if not _has_slurry_buffer_tank(world_state) and _is_vial_supply_available(world_state):
		return "当前可按出发口推进；下一次回基地用污染浆液补建浆液缓冲罐，把药剂补给提升到 2 份"
	return departure_step


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
	var return_processing_line := format_core_archive_return_processing_line(world_state, character_state)
	if not return_processing_line.is_empty():
		parts.append(return_processing_line)
	return "；".join(parts)


static func format_module_state(world_state: WorldState, character_state: CharacterState) -> String:
	if FieldOutfittingRuntime.has_filter_module_equipped(character_state):
		if FieldOutfittingRuntime.has_active_core_archive_maintenance(character_state, world_state):
			if FieldOutfittingRuntime.has_active_module_calibration(character_state, world_state):
				return "模块校准 / 归档维护"
			return "模块归档维护"
		if _should_maintain_core_archive(world_state, character_state):
			return "模块待归档维护"
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
	if CoreStabilizationPressureFormatter.has_retest_readout(world_state):
		return "核心复测读数已带回，核心归档维护、模块校准和补给路线可继续服务下一趟外勤"
	if FieldOutfittingRuntime.is_core_archive_maintained(world_state):
		if FieldOutfittingRuntime.is_module_calibrated(world_state):
			return "核心归档维护和模块校准已接入，下一趟污染采集、污染战斗和核心站复测承压继续下降"
		return "核心归档维护已接入，下一趟污染采集和污染战斗承压继续下降"
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


static func format_core_archive_return_processing_line(
	world_state: WorldState,
	character_state: CharacterState
) -> String:
	if not _should_show_core_archive_return_processing(world_state):
		return ""
	if not _has_any_core_archive_return_residue_gathered(world_state):
		return "回访路线：核心归档维护已接入；从外勤出发口先回污染边界清出发路线 / 归档维护口袋，再回过滤器补药剂"
	if not _has_completed_filter_processing(world_state):
		return "回访处理：归档维护沉积已回收，先回污染过滤器处理成药剂和污染浆液"
	if _has_unprocessed_core_archive_pressure_retest_residue(world_state, character_state):
		return "回访处理：复测压力沉积已回收，先回污染过滤器处理成药剂和污染浆液"

	var current_vial := DepartureSupplyRuntime.get_resistance_vial_count(character_state)
	var target_vial := DepartureSupplyRuntime.get_resistance_vial_target(world_state)
	if DepartureSupplyRuntime.can_outpost_restock_resistance_vial(world_state, character_state):
		return "回访处理：沉积已过滤，回前哨核心补抗污染药剂到 %d/%d 后再从出发口复测" % [
			target_vial,
			target_vial
		]
	var readout_line := _format_core_retest_readout_line(world_state)
	if not readout_line.is_empty():
		return readout_line
	if current_vial >= target_vial:
		return "回访处理：沉积已过滤，抗污染药剂 %d/%d已备；从外勤出发口复测核心站或回污染边界验证承压" % [
			current_vial,
			target_vial
		]
	return "回访处理：沉积已过滤，确认药剂余量后再从出发口复测"


static func format_core_archive_return_next_step(
	world_state: WorldState,
	character_state: CharacterState
) -> String:
	if not _should_show_core_archive_return_processing(world_state):
		return ""
	if not _has_any_core_archive_return_residue_gathered(world_state):
		return "先从外勤出发口回污染边界，清出发路线回访口袋和归档维护回访口袋"
	if not _has_completed_filter_processing(world_state):
		return "先回污染过滤器处理归档维护沉积，再补药剂和污染浆液"
	if _has_unprocessed_core_archive_pressure_retest_residue(world_state, character_state):
		return "先回污染过滤器处理复测压力沉积，再补药剂和污染浆液"
	var current_vial := DepartureSupplyRuntime.get_resistance_vial_count(character_state)
	var target_vial := DepartureSupplyRuntime.get_resistance_vial_target(world_state)
	if current_vial < target_vial and DepartureSupplyRuntime.can_outpost_restock_resistance_vial(
		world_state,
		character_state
	):
		return "先在前哨核心补抗污染药剂到 %d/%d，再从出发口复测核心站" % [
			target_vial,
			target_vial
		]
	if (
		CoreStabilizationPressureFormatter.is_retest_readout_available(world_state)
		and not CoreStabilizationPressureFormatter.has_retest_readout(world_state)
	):
		return "从外勤出发口复测核心稳定站，回收核心复测读数缓存"
	if CoreStabilizationPressureFormatter.has_retest_readout(world_state):
		return "核心复测读数已回收；回前哨核心补给并在出发整备台确认下一趟路线"
	return ""


static func get_restock_supply_names(world_state: WorldState, character_state: CharacterState) -> Array[String]:
	var names: Array[String] = []
	if not world_state.has_base_structure_definition("building.basic_storage"):
		return names
	if not character_state.inventory.has_ref("item.repair_gel", 1):
		names.append("修复凝胶")
	if _can_restock_vial(world_state, character_state):
		names.append(DepartureSupplyRuntime.format_restock_resistance_vial_name(world_state, character_state))
	return names


static func get_ready_supply_names(world_state: WorldState, character_state: CharacterState) -> Array[String]:
	var names: Array[String] = []
	if character_state.inventory.has_ref("item.repair_gel", 1):
		names.append("修复凝胶")
	if _is_vial_supply_available(world_state):
		var vial_name := DepartureSupplyRuntime.format_ready_resistance_vial_name(world_state, character_state)
		if not vial_name.is_empty():
			names.append(vial_name)
	return names


static func _format_logistics_core_state(world_state: WorldState, character_state: CharacterState) -> String:
	if not world_state.quest_state.has_completed_quest("quest.restore_outpost"):
		return "待恢复"
	var restock_names := get_restock_supply_names(world_state, character_state)
	if not restock_names.is_empty():
		return "待补%s" % " / ".join(restock_names)
	if not character_state.are_vitals_full():
		return "待恢复生命 / 防护"
	return "已恢复"


static func _format_logistics_storage_state(world_state: WorldState) -> String:
	if world_state.has_base_structure_definition("building.basic_storage"):
		return "已接入补给"
	return "待建"


static func _format_logistics_slurry_buffer_state(world_state: WorldState) -> String:
	if _has_slurry_buffer_tank(world_state):
		return "双药剂补给"
	if _is_vial_supply_available(world_state):
		return "可补建"
	return "待污染浆液"


static func _format_logistics_exit_state(world_state: WorldState, character_state: CharacterState) -> String:
	if not world_state.quest_state.has_completed_quest("quest.restore_outpost"):
		return "未开放"
	var core_archive_return_step := format_core_archive_return_next_step(world_state, character_state)
	if not core_archive_return_step.is_empty():
		if core_archive_return_step.find("回收核心复测读数缓存") >= 0:
			return "核心站读数待回收"
		if core_archive_return_step.find("核心复测读数已回收") >= 0:
			return "核心读数已带回"
		return "回访处理待完成"
	if (
		CoreStabilizationPressureFormatter.is_retest_readout_available(world_state)
		and not CoreStabilizationPressureFormatter.has_retest_readout(world_state)
	):
		return "核心站读数待回收"
	if CoreStabilizationPressureFormatter.has_retest_readout(world_state):
		return "核心读数已带回"
	var next_sortie_route := CoreGuardAftermathFormatter.format_next_sortie_route_line(world_state)
	if not next_sortie_route.is_empty():
		return next_sortie_route
	if _is_core_stabilization_available(world_state):
		return "核心站复测方向"
	return "按当前地图目标"


static func _can_restock_vial(world_state: WorldState, character_state: CharacterState) -> bool:
	return DepartureSupplyRuntime.can_outpost_restock_resistance_vial(world_state, character_state)


static func _is_vial_supply_available(world_state: WorldState) -> bool:
	return DepartureSupplyRuntime.is_resistance_vial_supply_available(world_state)


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


static func _should_maintain_core_archive(world_state: WorldState, character_state: CharacterState) -> bool:
	return (
		FieldOutfittingRuntime.is_core_archive_maintenance_available(character_state, world_state)
		and not FieldOutfittingRuntime.is_core_archive_maintained(world_state)
	)


static func _should_show_core_archive_return_processing(world_state: WorldState) -> bool:
	return (
		world_state != null
		and world_state.quest_state.has_completed_quest("quest.write_demo_stabilization_core")
		and FieldOutfittingRuntime.is_core_archive_maintained(world_state)
	)


static func _has_any_core_archive_return_residue_gathered(world_state: WorldState) -> bool:
	if world_state == null:
		return false
	return (
		bool(
			world_state.get_map_object(
				"map_object_instance.pollution_residue_core_archive_route_cache"
			).get("is_gathered", false)
		)
		or bool(
			world_state.get_map_object(
				"map_object_instance.pollution_residue_core_archive_return_cache"
			).get("is_gathered", false)
		)
	)


static func _has_completed_filter_processing(world_state: WorldState) -> bool:
	if world_state == null:
		return false
	for structure in world_state.base_structures.values():
		if not structure is Dictionary:
			continue
		if String(structure.get("definition_id", "")) != "building.pollution_filter":
			continue
		if String(structure.get("last_recipe_id", "")) == "recipe.cleanse_residue":
			return true
	return false


static func _format_core_retest_readout_line(world_state: WorldState) -> String:
	if CoreStabilizationPressureFormatter.has_retest_readout(world_state):
		return "核心复测：读数缓存已回收，基础零件和修复凝胶已带回；回前哨核心补给并确认出发整备"
	if CoreStabilizationPressureFormatter.is_retest_readout_available(world_state):
		return "核心复测：污染回访处理完成，从外勤出发口回核心稳定站回收复测读数缓存"
	return ""


static func _has_unprocessed_core_archive_pressure_retest_residue(
	world_state: WorldState,
	character_state: CharacterState
) -> bool:
	if world_state == null or character_state == null:
		return false
	return (
		bool(
			world_state.get_map_object(
				"map_object_instance.pollution_residue_core_archive_pressure_retest_cache"
			).get("is_gathered", false)
		)
		and character_state.inventory.has_ref("item.polluted_residue", 2)
	)


static func _has_slurry_buffer_tank(world_state: WorldState) -> bool:
	return world_state.has_base_structure_definition("building.slurry_buffer_tank")
