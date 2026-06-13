extends RefCounted
class_name CoreStabilizationPressureFormatter

const CORE_QUEST_IDS: Array[String] = [
	"quest.enter_demo_stabilization_core",
	"quest.prepare_demo_stabilization_buffer",
	"quest.defeat_demo_stabilization_guard",
	"quest.write_demo_stabilization_core"
]


static func format_hud_summary(
	world_state: WorldState,
	character_state: CharacterState,
	active_quest_id: String
) -> Array[String]:
	if should_show_core_revisit(world_state):
		return [
			"核心站复测：核心设备已接管；%s" % format_core_revisit_completion_parts(world_state, character_state),
			format_core_revisit_pressure_line(world_state)
		]
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
	return "；".join(parts)


static func format_core_revisit_pressure_line(world_state: WorldState) -> String:
	return "压力回看：%s；复测不会重复消耗补给" % CoreGuardAftermathFormatter.format_battle_spend(world_state)


static func format_core_revisit_next_step(world_state: WorldState, character_state: CharacterState) -> String:
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
	return ""


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


static func _format_full_vial_target(world_state: WorldState) -> String:
	var target := DepartureSupplyRuntime.get_resistance_vial_target(world_state)
	return "%d/%d" % [target, target]
