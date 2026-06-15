extends RefCounted
class_name CoreStabilizationPressureFormatter

const CORE_QUEST_IDS: Array[String] = [
	"quest.enter_demo_stabilization_core",
	"quest.prepare_demo_stabilization_buffer",
	"quest.defeat_demo_stabilization_guard",
	"quest.write_demo_stabilization_core"
]
const RETEST_READOUT_INSTANCE_ID := "map_object_instance.demo_stabilization_retest_readout_cache"
const RETEST_READOUT_DEFINITION_ID := "map_object.demo_stabilization_retest_readout_cache"
const PRESSURE_RETEST_RESIDUE_INSTANCE_ID := "map_object_instance.pollution_residue_core_archive_pressure_retest_cache"
const LOGISTICS_MAINTENANCE_RETEST_RESIDUE_INSTANCE_ID := "map_object_instance.pollution_residue_logistics_maintenance_retest_cache"
const LOGISTICS_MAINTENANCE_RETEST_RESIDUE_DEFINITION_ID := "map_object.demo_stabilization_logistics_retest_residue"
const LOGISTICS_MAINTENANCE_RETEST_PROCESSED_FLAG := "logistics_maintenance_retest_processed"


static func format_hud_summary(
	world_state: WorldState,
	character_state: CharacterState,
	active_quest_id: String
) -> Array[String]:
	if should_show_core_revisit(world_state):
		var revisit_lines: Array[String] = [
			"核心站复测：核心设备已接管；%s" % format_core_revisit_completion_parts(world_state, character_state),
			format_core_revisit_pressure_line(world_state)
		]
		var readout_line := format_retest_readout_status_line(world_state)
		if not readout_line.is_empty():
			revisit_lines.append(readout_line)
		var logistics_retest_line := format_logistics_maintenance_retest_status_line(world_state)
		if not logistics_retest_line.is_empty():
			revisit_lines.append(logistics_retest_line)
		return revisit_lines
	if not is_core_stabilization_context(world_state, active_quest_id):
		return []
	var ready_line := "准备项：%s" % format_ready_parts(world_state, character_state)
	match active_quest_id:
		"quest.enter_demo_stabilization_core":
			return [
				"核心站承压：先进入终点读侧边补给、守卫和核心设备",
				ready_line
			]
		"quest.prepare_demo_stabilization_buffer":
			return [
				"核心站整备：过滤沉积物取得药剂 / 浆液，再组装缓冲包",
				ready_line
			]
		"quest.defeat_demo_stabilization_guard":
			return [
				"核心站战斗：缓冲包、侧边补给和药剂会削弱守卫第一段压力",
				"守卫战准备：%s" % format_guard_pressure_parts(world_state, character_state)
			]
		"quest.write_demo_stabilization_core":
			var write_lines: Array[String] = [
				"核心写入承压：侧边补给、缓冲回写、药剂和守卫缓存共同降反冲",
				ready_line
			]
			var aftermath_line := CoreGuardAftermathFormatter.format_hud_line(world_state, character_state)
			if not aftermath_line.is_empty():
				write_lines.insert(1, aftermath_line)
			return write_lines
	if world_state.current_region_id == "region.demo_stabilization_core":
		return [
			"核心站承压：先确认补给、守卫和核心设备",
			ready_line
		]
	return []


static func format_interaction_status(
	character_state: CharacterState,
	world_state: WorldState,
	object_state: Dictionary
) -> String:
	if is_core_processed(world_state, object_state):
		return "已接管，第一条稳定通道已打开；复测完成态：%s；%s。" % [
			format_core_revisit_completion_parts(world_state, character_state),
			format_core_revisit_pressure_line(world_state)
		]
	if not world_state.quest_state.has_active_quest("quest.write_demo_stabilization_core"):
		if not bool(world_state.get_enemy("enemy_instance.demo_stabilization_guard").get("is_defeated", false)):
			return "守卫仍压制写入平台；先完成缓冲包整备并击败核心阶段守卫。"
		return "写入任务尚未归档到核心设备；先回收守卫后的回写缓存。"
	if world_state.quest_state.get_objective_progress("quest.write_demo_stabilization_core", "gather_item", "item.core_write_charge") < 1.0:
		return "缺核心写入校验片；守卫回写缓存还没有回收。"
	var ready_count := get_ready_count(world_state, character_state)
	if ready_count >= 3:
		return "可写入，终点准备 %d/4，核心设备反冲已明显降低。" % ready_count
	if ready_count > 0:
		return "可写入，终点准备 %d/4，反冲低于仓促写入。" % ready_count
	return "可写入，终点准备 0/4，核心写入反冲会完整命中。"


static func format_interaction_next_step(
	character_state: CharacterState,
	world_state: WorldState,
	object_state: Dictionary
) -> String:
	if is_core_processed(world_state, object_state):
		return format_core_revisit_next_step(world_state, character_state)
	if not world_state.quest_state.has_active_quest("quest.write_demo_stabilization_core"):
		return "按任务顺序先处理侧边补给、缓冲包和守卫战，再回收回写缓存。"
	if world_state.quest_state.get_objective_progress("quest.write_demo_stabilization_core", "gather_item", "item.core_write_charge") < 1.0:
		return "击败守卫后先回收守卫回写缓存；校验片和补给会一起入包。"
	return "按 E 写入前确认：%s。" % format_ready_parts(world_state, character_state)


static func is_core_stabilization_context(world_state: WorldState, active_quest_id: String) -> bool:
	if world_state == null or world_state.quest_state.has_completed_quest("quest.write_demo_stabilization_core"):
		return false
	if CORE_QUEST_IDS.has(active_quest_id):
		return true
	return world_state.current_region_id == "region.demo_stabilization_core"


static func should_show_core_revisit(world_state: WorldState) -> bool:
	return (
		world_state != null
		and world_state.current_region_id == "region.demo_stabilization_core"
		and world_state.quest_state.has_completed_quest("quest.write_demo_stabilization_core")
	)


static func is_core_processed(world_state: WorldState, object_state: Dictionary) -> bool:
	return bool(object_state.get("is_sampled", false)) or world_state.quest_state.has_completed_quest("quest.write_demo_stabilization_core")


static func get_ready_count(world_state: WorldState, character_state: CharacterState) -> int:
	var ready_count := 0
	if has_recovery_cache(world_state):
		ready_count += 1
	if has_guard_buffer_sync(world_state):
		ready_count += 1
	if character_state.inventory.has_ref("item.resistance_vial_t1", 1):
		ready_count += 1
	if has_guard_cache(world_state):
		ready_count += 1
	return ready_count


static func format_ready_parts(world_state: WorldState, character_state: CharacterState) -> String:
	var parts: Array[String] = []
	parts.append("侧边补给已取" if has_recovery_cache(world_state) else "侧边补给待取")
	parts.append("缓冲回写已接入" if has_guard_buffer_sync(world_state) else "缓冲包未回写")
	var current_vial := DepartureSupplyRuntime.get_resistance_vial_count(character_state)
	var target_vial := DepartureSupplyRuntime.get_resistance_vial_target(world_state)
	if current_vial >= target_vial and target_vial > 1:
		parts.append("药剂 %d/%d已备" % [current_vial, target_vial])
	elif current_vial >= 1 and target_vial > 1:
		parts.append("药剂 %d/%d，建议补满" % [current_vial, target_vial])
	elif current_vial >= 1:
		parts.append("药剂在身")
	else:
		parts.append("药剂不足")
	parts.append("守卫缓存已取" if has_guard_cache(world_state) else "守卫缓存待取")
	return "；".join(parts)


static func format_core_revisit_completion_parts(world_state: WorldState, character_state: CharacterState) -> String:
	var parts: Array[String] = []
	parts.append("侧边补给已回收" if has_recovery_cache(world_state) else "侧边补给未回收")
	parts.append("稳压缓冲包已回写" if has_guard_buffer_sync(world_state) else "稳压缓冲包未回写")
	var current_vial := DepartureSupplyRuntime.get_resistance_vial_count(character_state)
	var target_vial := DepartureSupplyRuntime.get_resistance_vial_target(world_state)
	if current_vial >= target_vial and target_vial > 1:
		parts.append("抗污染药剂 %d/%d已备" % [current_vial, target_vial])
	elif current_vial >= 1 and target_vial > 1:
		parts.append("抗污染药剂 %d/%d，建议回前哨补满" % [current_vial, target_vial])
	elif current_vial >= 1:
		parts.append("抗污染药剂已备")
	elif has_guard_vial_pressure(world_state):
		parts.append("抗污染药剂已用于守卫排压，当前 %s" % DepartureSupplyRuntime.format_resistance_vial_count(world_state, character_state))
	else:
		parts.append("抗污染药剂待补")
	if FieldOutfittingRuntime.has_active_core_archive_maintenance(character_state, world_state):
		parts.append("基地核心归档维护已接入")
	elif FieldOutfittingRuntime.is_core_archive_maintenance_available(character_state, world_state):
		parts.append("基地核心归档维护待接入")
	parts.append("守卫回写缓存已归档" if has_guard_cache(world_state) else "守卫回写缓存未回收")
	if has_retest_readout(world_state):
		parts.append("复测读数已回收")
	elif is_retest_readout_available(world_state):
		parts.append("复测读数待回收")
	if FieldOutfittingRuntime.is_logistics_maintenance_confirmed(world_state):
		if is_logistics_maintenance_retest_processed(world_state):
			parts.append("后勤维护复测沉积已处理")
		elif has_logistics_maintenance_retest_residue(world_state):
			parts.append("后勤维护复测沉积待过滤")
		elif is_logistics_maintenance_retest_available(world_state):
			parts.append("后勤维护复测压力待清理")
	return "；".join(parts)


static func format_core_revisit_pressure_line(world_state: WorldState) -> String:
	return "压力回看：%s；复测不会重复消耗补给" % CoreGuardAftermathFormatter.format_battle_spend(world_state)


static func format_core_revisit_next_step(world_state: WorldState, character_state: CharacterState) -> String:
	if is_retest_readout_available(world_state) and not has_retest_readout(world_state):
		return "核心复测读数缓存已显形；先回收读数和补给，再沿外勤出发口回前哨整理"
	if is_logistics_maintenance_retest_available(world_state):
		if is_logistics_maintenance_retest_processed(world_state):
			return "后勤维护复测沉积已处理；沿外勤出发口回前哨核心补给，并确认下一趟外勤准备"
		if has_logistics_maintenance_retest_residue(world_state):
			return "后勤维护复测沉积已回收；沿外勤出发口回过滤器处理成药剂和污染浆液，再回前哨整理"
		return "后勤维护复测压力点已开放；先清掉守卫并回收沉积物，验证整备台维护后的承压收益"
	if not character_state.are_vitals_full():
		return "生命 / 防护未满；沿外勤出发口回前哨核心恢复后再复测或出发"
	if not character_state.inventory.has_ref("item.repair_gel", 1):
		return "修复凝胶不足；沿外勤出发口回前哨核心补给"
	if DepartureSupplyRuntime.get_resistance_vial_count(character_state) < DepartureSupplyRuntime.get_resistance_vial_target(world_state):
		return "抗污染药剂未补满；沿外勤出发口回前哨核心补到 %s 后再打守卫或写入" % _format_full_vial_target(world_state)
	if (
		FieldOutfittingRuntime.is_core_archive_maintenance_available(character_state, world_state)
		and not FieldOutfittingRuntime.is_core_archive_maintained(world_state)
	):
		return "核心归档维护未接入；沿外勤出发口回出发整备台完成维护后再复测"
	if has_retest_readout(world_state):
		return "复测读数已带回；沿外勤出发口回前哨核心补给，并在出发整备台确认下一趟路线"
	return "完成态已确认；可沿外勤出发口回前哨整理下一趟外勤"


static func format_core_revisit_feedback_message(world_state: WorldState, character_state: CharacterState) -> String:
	return "核心稳定站复测：核心设备已接管；%s；%s；下一步：%s。" % [
		format_core_revisit_completion_parts(world_state, character_state),
		format_core_revisit_pressure_line(world_state),
		format_core_revisit_next_step(world_state, character_state)
	]


static func format_completed_cache_status(
	definition_id: String,
	world_state: WorldState,
	character_state: CharacterState
) -> String:
	if definition_id == "map_object.demo_stabilization_recovery_cache":
		var usage := "已接入守卫战稳压" if has_guard_side_supply_sync(world_state) else "已作为核心写入准备项保留"
		if world_state.quest_state.has_completed_quest("quest.write_demo_stabilization_core"):
			return "侧边补给已回收；%s；核心设备复测时会显示为完成态。" % usage
		return "侧边补给已回收；%s；继续确认守卫和核心设备。" % usage
	if definition_id == "map_object.demo_stabilization_guard_cache":
		var charge_state := "校验片在身" if character_state.inventory.has_ref("item.core_write_charge", 1) else "校验片已用于写入或待确认"
		if world_state.quest_state.has_completed_quest("quest.write_demo_stabilization_core"):
			return "守卫回写缓存已归档；%s；核心设备复测时会显示守卫缓存完成态。" % charge_state
		return "守卫回写缓存已回收；%s；写入核心设备前确认药剂和生命 / 防护。" % charge_state
	if definition_id == RETEST_READOUT_DEFINITION_ID:
		if has_retest_readout(world_state):
			return "核心复测读数已回收；基础零件和修复凝胶已带回，回前哨核心补给后再确认出发整备。"
		if is_retest_readout_available(world_state):
			return "核心复测读数缓存已显形；回收后带基础零件和修复凝胶回前哨整理下一趟外勤。"
		return "核心复测读数尚未稳定；先完成核心归档维护和污染边界复测压力处理。"
	return ""


static func format_retest_readout_status_line(world_state: WorldState) -> String:
	if has_retest_readout(world_state):
		return "复测读数：已回收核心复测读数缓存，基础零件和修复凝胶可带回前哨整理"
	if is_retest_readout_available(world_state):
		return "复测读数：核心设备东侧缓存已显形，可回收读数、基础零件和修复凝胶"
	return ""


static func format_logistics_maintenance_retest_status_line(world_state: WorldState) -> String:
	if not is_logistics_maintenance_retest_available(world_state):
		return ""
	if is_logistics_maintenance_retest_processed(world_state):
		return "后勤维护复测：沉积已过滤成药剂和污染浆液，回前哨核心补给后可继续准备下一趟外勤"
	if has_logistics_maintenance_retest_residue(world_state):
		return "后勤维护复测：压力沉积已回收，先回过滤器处理，再把多余污染浆液带回基地反应器"
	return "后勤维护复测：核心站维护压力点已开放，清守卫后回收沉积物验证整备收益"


static func format_retest_readout_next_step(world_state: WorldState, character_state: CharacterState) -> String:
	if has_retest_readout(world_state):
		if not character_state.are_vitals_full():
			return "读数已回收；先回前哨核心恢复生命 / 防护，再整理下一趟外勤"
		return "读数已回收；回前哨核心补给并在出发整备台确认下一趟路线"
	if is_retest_readout_available(world_state):
		return "回收后带基础零件和修复凝胶回前哨核心，整理下一趟外勤"
	return "先完成核心归档维护和污染边界复测压力处理，再回来读取核心复测缓存"


static func format_guard_pressure_parts(world_state: WorldState, character_state: CharacterState) -> String:
	var parts: Array[String] = []
	parts.append("侧边补给已接入" if has_guard_side_supply_sync(world_state) else ("侧边补给已取" if has_recovery_cache(world_state) else "侧边补给待取"))
	if has_guard_buffer_sync(world_state):
		parts.append("缓冲包已护住守卫战")
	elif character_state.inventory.has_ref("item.core_stabilization_buffer", 1):
		parts.append("缓冲包在身")
	else:
		parts.append("缓冲包不足")
	if has_guard_vial_pressure(world_state):
		parts.append("药剂已守卫排压")
	elif DepartureSupplyRuntime.get_resistance_vial_count(character_state) >= DepartureSupplyRuntime.get_resistance_vial_target(world_state):
		parts.append("药剂 %s已备" % DepartureSupplyRuntime.format_resistance_vial_count(world_state, character_state))
	elif character_state.inventory.has_ref("item.resistance_vial_t1", 1):
		parts.append("药剂 %s，建议补满" % DepartureSupplyRuntime.format_resistance_vial_count(world_state, character_state))
	else:
		parts.append("药剂不足")
	return "；".join(parts)


static func has_guard_buffer_sync(world_state: WorldState) -> bool:
	return bool(world_state.get_enemy("enemy_instance.demo_stabilization_guard").get("core_buffer_used", false))


static func has_guard_vial_pressure(world_state: WorldState) -> bool:
	return bool(world_state.get_enemy("enemy_instance.demo_stabilization_guard").get("pressure_vial_used", false))


static func has_guard_side_supply_sync(world_state: WorldState) -> bool:
	return bool(world_state.get_enemy("enemy_instance.demo_stabilization_guard").get("core_side_supply_used", false))


static func has_recovery_cache(world_state: WorldState) -> bool:
	return (
		bool(world_state.get_map_object("map_object_instance.demo_stabilization_recovery_cache").get("is_gathered", false))
		or bool(world_state.get_map_object("map_object_instance.demo_stabilization_recovery_wreckage").get("is_gathered", false))
	)


static func has_guard_cache(world_state: WorldState) -> bool:
	return bool(world_state.get_map_object("map_object_instance.demo_stabilization_guard_cache").get("is_gathered", false))


static func has_retest_readout(world_state: WorldState) -> bool:
	if world_state == null:
		return false
	return bool(world_state.get_map_object(RETEST_READOUT_INSTANCE_ID).get("is_gathered", false))


static func is_logistics_maintenance_retest_available(world_state: WorldState) -> bool:
	return (
		world_state != null
		and world_state.quest_state.has_completed_quest("quest.write_demo_stabilization_core")
		and FieldOutfittingRuntime.is_logistics_maintenance_confirmed(world_state)
		and FieldOutfittingRuntime.is_logistics_maintenance_pollution_retest_processed(world_state)
		and has_retest_readout(world_state)
	)


static func has_logistics_maintenance_retest_residue(world_state: WorldState) -> bool:
	if world_state == null:
		return false
	return bool(
		world_state.get_map_object(LOGISTICS_MAINTENANCE_RETEST_RESIDUE_INSTANCE_ID).get(
			"is_gathered",
			false
		)
	)


static func is_logistics_maintenance_retest_processed(world_state: WorldState) -> bool:
	if world_state == null:
		return false
	return bool(
		world_state.get_map_object(LOGISTICS_MAINTENANCE_RETEST_RESIDUE_INSTANCE_ID).get(
			LOGISTICS_MAINTENANCE_RETEST_PROCESSED_FLAG,
			false
		)
	)


static func mark_logistics_maintenance_retest_processed(world_state: WorldState) -> void:
	if world_state == null:
		return
	var residue_state := world_state.ensure_map_object(
		LOGISTICS_MAINTENANCE_RETEST_RESIDUE_INSTANCE_ID,
		LOGISTICS_MAINTENANCE_RETEST_RESIDUE_DEFINITION_ID,
		"region.demo_stabilization_core"
	)
	residue_state[LOGISTICS_MAINTENANCE_RETEST_PROCESSED_FLAG] = true


static func should_process_logistics_maintenance_retest_residue(
	character_state: CharacterState,
	world_state: WorldState
) -> bool:
	return (
		character_state != null
		and is_logistics_maintenance_retest_available(world_state)
		and has_logistics_maintenance_retest_residue(world_state)
		and not is_logistics_maintenance_retest_processed(world_state)
		and character_state.inventory.has_ref("item.polluted_residue", 2)
	)


static func is_retest_readout_available(world_state: WorldState) -> bool:
	return (
		world_state != null
		and world_state.quest_state.has_completed_quest("quest.write_demo_stabilization_core")
		and FieldOutfittingRuntime.is_core_archive_maintained(world_state)
		and bool(world_state.get_map_object(PRESSURE_RETEST_RESIDUE_INSTANCE_ID).get("is_gathered", false))
		and _has_completed_pollution_filter_processing(world_state)
	)


static func _has_completed_pollution_filter_processing(world_state: WorldState) -> bool:
	for structure in world_state.base_structures.values():
		if not structure is Dictionary:
			continue
		if String(structure.get("definition_id", "")) != "building.pollution_filter":
			continue
		if String(structure.get("last_recipe_id", "")) == "recipe.cleanse_residue":
			return true
	return false


static func _format_full_vial_target(world_state: WorldState) -> String:
	var target := DepartureSupplyRuntime.get_resistance_vial_target(world_state)
	return "%d/%d" % [target, target]
