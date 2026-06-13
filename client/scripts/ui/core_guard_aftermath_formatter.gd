extends RefCounted
class_name CoreGuardAftermathFormatter


static func format_guard_cache_gather_followup(world_state: WorldState, character_state: CharacterState) -> String:
	if not has_guard_cache_recovered(world_state):
		return ""
	return "%s；缓存补回：核心写入校验片 / 基础零件 / 修复凝胶 / 抗污染药剂；%s" % [
		format_battle_spend(world_state),
		format_next_preparation(world_state, character_state)
	]


static func format_hud_line(world_state: WorldState, character_state: CharacterState) -> String:
	if not should_show_pre_write_aftermath(world_state):
		return ""
	return "战后回收：守卫缓存已取；%s；%s" % [
		format_battle_spend(world_state),
		format_cache_ready_state(character_state)
	]


static func format_outpost_line(world_state: WorldState, character_state: CharacterState) -> String:
	if not should_show_pre_write_aftermath(world_state):
		return ""
	return "核心站战后：%s；%s" % [
		format_battle_spend(world_state),
		format_next_preparation(world_state, character_state)
	]


static func format_device_line(world_state: WorldState, character_state: CharacterState) -> String:
	if not should_show_pre_write_aftermath(world_state):
		return ""
	return "核心站战后：守卫缓存已补校验片和补给；%s" % format_next_preparation(world_state, character_state)


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


static func format_cache_ready_state(character_state: CharacterState) -> String:
	var ready_parts: Array[String] = []
	ready_parts.append("校验片在身" if character_state.inventory.has_ref("item.core_write_charge", 1) else "校验片待确认")
	ready_parts.append("修复凝胶在身" if character_state.inventory.has_ref("item.repair_gel", 1) else "修复凝胶不足")
	ready_parts.append("药剂在身" if character_state.inventory.has_ref("item.resistance_vial_t1", 1) else "药剂不足")
	return "写入准备：%s" % "；".join(ready_parts)


static func format_next_preparation(world_state: WorldState, character_state: CharacterState) -> String:
	if not character_state.inventory.has_ref("item.core_write_charge", 1):
		return "下一步：确认守卫缓存校验片，再靠近核心稳定设备写入"
	if not character_state.are_vitals_full():
		return "下一步：回前哨核心恢复生命 / 防护，再带校验片写入核心稳定设备"
	if not character_state.inventory.has_ref("item.resistance_vial_t1", 1):
		return "下一步：若要降低写入反冲，回前哨核心补抗污染药剂后再写入"
	if world_state.quest_state.has_active_quest("quest.write_demo_stabilization_core"):
		return "下一步：带校验片和补给写入核心稳定设备"
	return "下一步：整理补给后继续推进核心稳定站"


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
