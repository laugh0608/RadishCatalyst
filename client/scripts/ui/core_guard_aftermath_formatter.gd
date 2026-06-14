extends RefCounted
class_name CoreGuardAftermathFormatter

const CRYSTAL_LOGISTICS_RETURN_CRYSTAL_INSTANCE_ID := "map_object_instance.crystal_cluster_logistics_return"
const CRYSTAL_LOGISTICS_RETURN_WRECKAGE_INSTANCE_ID := "map_object_instance.field_wreckage_logistics_return"


static func format_guard_cache_gather_followup(world_state: WorldState, character_state: CharacterState) -> String:
	if not has_guard_cache_recovered(world_state):
		return ""
	return "核心写入校验片已回收；%s；缓存补回：核心写入校验片 / 基础零件 / 修复凝胶 / 抗污染药剂；%s" % [
		format_battle_spend(world_state),
		format_next_preparation(world_state, character_state)
	]


static func format_hud_line(world_state: WorldState, character_state: CharacterState) -> String:
	if not should_show_pre_write_aftermath(world_state):
		return ""
	return "战后回收：守卫缓存已取；%s；%s" % [
		format_battle_spend(world_state),
		format_cache_ready_state(world_state, character_state)
	]


static func format_outpost_line(world_state: WorldState, character_state: CharacterState) -> String:
	if not should_show_pre_write_aftermath(world_state):
		return ""
	return "核心站战后：%s；%s" % [
		format_battle_spend(world_state),
		format_next_preparation(world_state, character_state)
	]


static func format_device_line(world_state: WorldState, character_state: CharacterState) -> String:
	if should_show_pre_write_aftermath(world_state):
		return "核心站战后：守卫缓存已补校验片和补给；%s" % format_next_preparation(world_state, character_state)
	if should_show_next_sortie(world_state):
		return "核心写入归档：%s；%s" % [
			format_next_sortie_supply_state(world_state, character_state),
			format_next_sortie_action(world_state, character_state)
		]
	return ""


static func format_next_sortie_hud_line(world_state: WorldState, character_state: CharacterState) -> String:
	if not should_show_next_sortie(world_state):
		return ""
	return "下一趟出发：%s；%s" % [
		format_next_sortie_supply_state(world_state, character_state),
		format_next_sortie_action(world_state, character_state)
	]


static func format_next_sortie_outpost_line(world_state: WorldState, character_state: CharacterState) -> String:
	if not should_show_next_sortie(world_state):
		return ""
	return "核心写入已归档：%s；%s" % [
		format_next_sortie_supply_state(world_state, character_state),
		format_next_sortie_action(world_state, character_state)
	]


static func format_next_sortie_goal_name(world_state: WorldState) -> String:
	if not should_show_next_sortie(world_state):
		return ""
	if world_state.current_region_id != "region.outpost_platform":
		return "核心写入归档待回前哨"
	if FieldOutfittingRuntime.is_crystal_logistics_return_available(world_state):
		if not FieldOutfittingRuntime.has_crystal_logistics_return_materials(world_state):
			return "晶体侧路后勤补料待回收"
		if not FieldOutfittingRuntime.is_logistics_material_processed(world_state):
			return "基地后勤补料待加工"
		if not FieldOutfittingRuntime.is_logistics_maintenance_confirmed(world_state):
			return "出发整备台维护待确认"
		return "下一趟外勤准备"
	return "核心写入归档后出发准备"


static func format_next_sortie_route_line(world_state: WorldState) -> String:
	if not should_show_next_sortie(world_state):
		return ""
	if world_state.current_region_id != "region.outpost_platform":
		return "核心写入已归档；返回前哨核心补给并整理下一趟外勤"
	if _has_core_retest_readout(world_state):
		if _is_crystal_logistics_return_available(world_state):
			if not FieldOutfittingRuntime.has_crystal_logistics_return_materials(world_state):
				return "核心复测读数已带回；从外勤出发口回晶体侧路补后勤材料"
			if not FieldOutfittingRuntime.is_logistics_material_processed(world_state):
				return "晶体侧路补料已带回；回基础反应器加工基础零件，再确认整备台维护"
			if not FieldOutfittingRuntime.is_logistics_maintenance_confirmed(world_state):
				return "后勤补料已加工；到出发整备台确认维护材料，再回前哨核心补给"
			return "后勤补料已处理，整备台维护已确认；回前哨核心补给后准备下一趟外勤"
		return "核心复测读数已带回；回前哨核心补给并确认出发整备"
	if _is_core_retest_readout_available(world_state):
		return "核心写入已归档；从外勤出发口复测核心稳定站并回收复测读数缓存"
	return "核心写入已归档；补给和模块确认后，从外勤出发口复测核心稳定站"


static func get_next_sortie_target_region_id(world_state: WorldState) -> String:
	if not should_show_next_sortie(world_state):
		return ""
	if world_state.current_region_id == "region.outpost_platform":
		if _is_crystal_logistics_return_available(world_state):
			if not FieldOutfittingRuntime.has_crystal_logistics_return_materials(world_state):
				return "region.crystal_vein_field"
			if not FieldOutfittingRuntime.is_logistics_maintenance_confirmed(world_state):
				return "region.outpost_platform"
		return "region.demo_stabilization_core"
	return "region.outpost_platform"


static func format_battle_spend(world_state: WorldState) -> String:
	var spend_parts: Array[String] = []
	if has_guard_buffer_sync(world_state):
		spend_parts.append("缓冲包已护住守卫战")
	if has_guard_side_supply_sync(world_state):
		spend_parts.append("侧边补给已接入守卫战")
	if has_guard_vial_pressure(world_state):
		spend_parts.append("药剂已守卫排压")
	if spend_parts.is_empty():
		return "守卫战消耗：未记录缓冲包或药剂排压"
	return "守卫战消耗：%s" % " / ".join(spend_parts)


static func format_cache_ready_state(world_state: WorldState, character_state: CharacterState) -> String:
	var ready_parts: Array[String] = []
	ready_parts.append("校验片在身" if character_state.inventory.has_ref("item.core_write_charge", 1) else "校验片待确认")
	ready_parts.append("修复凝胶在身" if character_state.inventory.has_ref("item.repair_gel", 1) else "修复凝胶不足")
	var current_vial := DepartureSupplyRuntime.get_resistance_vial_count(character_state)
	var target_vial := DepartureSupplyRuntime.get_resistance_vial_target(world_state)
	if current_vial >= target_vial and target_vial > 1:
		ready_parts.append("药剂 %d/%d已备" % [current_vial, target_vial])
	elif current_vial >= 1 and target_vial > 1:
		ready_parts.append("药剂 %d/%d，建议回前哨补满" % [current_vial, target_vial])
	elif current_vial >= 1:
		ready_parts.append("药剂在身")
	else:
		ready_parts.append("药剂不足")
	return "写入准备：%s" % "；".join(ready_parts)


static func format_next_preparation(world_state: WorldState, character_state: CharacterState) -> String:
	if not character_state.inventory.has_ref("item.core_write_charge", 1):
		return "下一步：确认守卫缓存校验片，再靠近核心稳定设备写入"
	if not character_state.are_vitals_full():
		return "下一步：回前哨核心恢复生命 / 防护，再带校验片写入核心稳定设备"
	if DepartureSupplyRuntime.get_resistance_vial_count(character_state) < DepartureSupplyRuntime.get_resistance_vial_target(world_state):
		if DepartureSupplyRuntime.can_outpost_restock_resistance_vial(world_state, character_state):
			var target_vial := DepartureSupplyRuntime.get_resistance_vial_target(world_state)
			return "下一步：若要降低守卫 / 写入承压，回前哨核心补满抗污染药剂到 %d/%d 后再写入" % [
				target_vial,
				target_vial
			]
		return "下一步：若要降低写入反冲，回过滤器补抗污染药剂后再写入"
	if world_state.quest_state.has_active_quest("quest.write_demo_stabilization_core"):
		return "下一步：带校验片和补给写入核心稳定设备"
	return "下一步：整理补给后继续推进核心稳定站"


static func format_next_sortie_supply_state(world_state: WorldState, character_state: CharacterState) -> String:
	var missing_supplies: Array[String] = []
	var ready_supplies: Array[String] = []
	if character_state.inventory.has_ref("item.repair_gel", 1):
		ready_supplies.append("修复凝胶已备")
	elif world_state.has_base_structure_definition("building.basic_storage"):
		missing_supplies.append("回前哨核心补修复凝胶")
	else:
		missing_supplies.append("修复凝胶需回基础反应器调制")

	var current_vial := DepartureSupplyRuntime.get_resistance_vial_count(character_state)
	var target_vial := DepartureSupplyRuntime.get_resistance_vial_target(world_state)
	if current_vial >= target_vial and target_vial > 1:
		ready_supplies.append("抗污染药剂 x%d已备" % current_vial)
	elif current_vial >= 1 and target_vial > 1 and _can_outpost_restock_vial(world_state):
		missing_supplies.append("抗污染药剂 %d/%d，回前哨核心补到 %d/%d" % [
			current_vial,
			target_vial,
			target_vial,
			target_vial
		])
	elif current_vial >= 1 and target_vial <= 1:
		ready_supplies.append("抗污染药剂已备")
	elif _can_outpost_restock_vial(world_state):
		if target_vial > 1:
			missing_supplies.append("回前哨核心补抗污染药剂到 %d" % target_vial)
		else:
			missing_supplies.append("回前哨核心补抗污染药剂")
	elif world_state.has_base_structure_definition("building.pollution_filter"):
		missing_supplies.append("抗污染药剂需回过滤器处理")

	if not missing_supplies.is_empty():
		return "补给待补：%s" % " / ".join(missing_supplies)
	if ready_supplies.is_empty():
		return "补给待确认"
	return "补给已补回：%s" % " / ".join(ready_supplies)


static func format_next_sortie_action(world_state: WorldState, character_state: CharacterState) -> String:
	if not character_state.are_vitals_full():
		return "先在前哨核心恢复生命 / 防护"
	if String(character_state.equipment.get("suit_module", "")) != "equipment.filter_module_t1":
		if world_state.has_base_structure_definition("building.field_outfitting_station"):
			return "到出发整备台确认基础过滤模块"
		return "补建出发整备台后再确认模块"
	if (
		FieldOutfittingRuntime.is_core_archive_maintenance_available(character_state, world_state)
		and not FieldOutfittingRuntime.is_core_archive_maintained(world_state)
	):
		return "到出发整备台接入核心归档维护"
	if world_state.current_region_id == "region.demo_stabilization_core":
		return "在核心设备复测完成态后回前哨整理下一趟外勤"
	if FieldOutfittingRuntime.has_active_core_archive_maintenance(character_state, world_state):
		if not _has_core_archive_return_residue_gathered(world_state):
			return "核心归档维护已接入，从外勤出发口先回污染边界处理回访口袋；处理后从外勤出发口复测核心稳定站"
		if not _has_completed_filter_processing(world_state):
			return "核心归档维护沉积已回收，先回污染过滤器处理；处理后从外勤出发口复测核心稳定站"
		if _has_unprocessed_core_archive_pressure_retest_residue(world_state, character_state):
			return "复测压力沉积已回收，先回污染过滤器处理；处理后补药剂并整理污染浆液收益"
		if _is_core_retest_readout_available(world_state) and not _has_core_retest_readout(world_state):
			return "核心归档维护已接入，从外勤出发口复测核心稳定站并回收复测读数缓存"
		if _has_core_retest_readout(world_state):
			if _is_crystal_logistics_return_available(world_state):
				if not FieldOutfittingRuntime.has_crystal_logistics_return_materials(world_state):
					return "核心复测读数已回收，回晶体侧路补晶体矿和残骸废件"
				if not FieldOutfittingRuntime.is_logistics_material_processed(world_state):
					return "晶体侧路补料已带回，回基础反应器加工基础零件，再确认整备台维护"
				if not FieldOutfittingRuntime.is_logistics_maintenance_confirmed(world_state):
					return "基础零件已加工，到出发整备台确认后勤维护"
				return "后勤补料处理和整备台维护已确认，回前哨核心补给后准备下一趟外勤"
			return "核心复测读数已回收，回前哨核心补给并确认出发整备"
		return "核心归档维护已接入，从外勤出发口复测核心稳定站"
	return "从外勤出发口复测核心稳定站"


static func should_show_next_sortie(world_state: WorldState) -> bool:
	return world_state != null and world_state.quest_state.has_completed_quest("quest.write_demo_stabilization_core")


static func should_show_pre_write_aftermath(world_state: WorldState) -> bool:
	if world_state == null:
		return false
	if world_state.quest_state.has_completed_quest("quest.write_demo_stabilization_core"):
		return false
	return has_guard_cache_recovered(world_state)


static func has_guard_cache_recovered(world_state: WorldState) -> bool:
	if world_state == null:
		return false
	return bool(world_state.get_map_object("map_object_instance.demo_stabilization_guard_cache").get("is_gathered", false))


static func has_guard_buffer_sync(world_state: WorldState) -> bool:
	return bool(world_state.get_enemy("enemy_instance.demo_stabilization_guard").get("core_buffer_used", false))


static func has_guard_vial_pressure(world_state: WorldState) -> bool:
	return bool(world_state.get_enemy("enemy_instance.demo_stabilization_guard").get("pressure_vial_used", false))


static func has_guard_side_supply_sync(world_state: WorldState) -> bool:
	return bool(world_state.get_enemy("enemy_instance.demo_stabilization_guard").get("core_side_supply_used", false))


static func _can_outpost_restock_vial(world_state: WorldState) -> bool:
	return DepartureSupplyRuntime.can_outpost_restock_resistance_vial(world_state)


static func _has_core_archive_return_residue_gathered(world_state: WorldState) -> bool:
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


static func _has_core_retest_readout(world_state: WorldState) -> bool:
	if world_state == null:
		return false
	return bool(
		world_state.get_map_object(
			"map_object_instance.demo_stabilization_retest_readout_cache"
		).get("is_gathered", false)
	)


static func _is_core_retest_readout_available(world_state: WorldState) -> bool:
	return (
		world_state != null
		and world_state.quest_state.has_completed_quest("quest.write_demo_stabilization_core")
		and FieldOutfittingRuntime.is_core_archive_maintained(world_state)
		and bool(
			world_state.get_map_object(
				"map_object_instance.pollution_residue_core_archive_pressure_retest_cache"
			).get("is_gathered", false)
		)
		and _has_completed_filter_processing(world_state)
	)


static func _is_crystal_logistics_return_available(world_state: WorldState) -> bool:
	return FieldOutfittingRuntime.is_crystal_logistics_return_available(world_state)


static func _has_crystal_logistics_return_materials(world_state: WorldState) -> bool:
	return FieldOutfittingRuntime.has_crystal_logistics_return_materials(world_state)


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
