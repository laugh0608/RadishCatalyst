extends RefCounted
class_name DemoFieldLoopPayoffFormatter

const FIELD_LOOP_PAYOFF_CONFIRMED_FLAG := "field_loop_payoff_confirmed"
const FIELD_LOOP_PAYOFF_PRESSURE_MULT := 0.92
const FIELD_OUTFITTING_STATION_ID := "building.field_outfitting_station"
const FIELD_OUTFITTING_STATION_INSTANCE_ID := "map_object_instance.field_outfitting_station"
const BASIC_FILTER_MODULE_ID := "equipment.filter_module_t1"
const SIGNAL_ECHO_CACHE_INSTANCE_ID := "map_object_instance.signal_echo_cache"
const OUTER_RING_ECHO_RESIDUE_INSTANCE_ID := "map_object_instance.outer_ring_echo_residue_cache"


static func has_field_loop_return(world_state: WorldState) -> bool:
	if world_state == null:
		return false
	return (
		world_state.quest_state.has_completed_quest("quest.salvage_signal_echo")
		or bool(world_state.get_map_object(SIGNAL_ECHO_CACHE_INSTANCE_ID).get("is_sampled", false))
	)


static func has_base_analysis_completed(world_state: WorldState) -> bool:
	if world_state == null:
		return false
	if world_state.quest_state.has_completed_quest("quest.analyze_deep_signal"):
		return true
	var reactor: Dictionary = world_state.base_structures.get("structure.basic_reactor", {})
	return String(reactor.get("last_recipe_id", "")) == "recipe.deep_signal_analysis"


static func can_confirm_payoff(world_state: WorldState, character_state: CharacterState) -> bool:
	return (
		_has_station_built(world_state)
		and _has_filter_module_equipped(character_state)
		and has_base_analysis_completed(world_state)
		and not is_payoff_confirmed(world_state)
	)


static func is_payoff_confirmed(world_state: WorldState) -> bool:
	if world_state == null:
		return false
	return bool(
		world_state.get_map_object(FIELD_OUTFITTING_STATION_INSTANCE_ID).get(
			FIELD_LOOP_PAYOFF_CONFIRMED_FLAG,
			false
		)
	)


static func mark_payoff_confirmed(world_state: WorldState) -> void:
	if world_state == null:
		return
	var station_state := world_state.ensure_map_object(
		FIELD_OUTFITTING_STATION_INSTANCE_ID,
		FIELD_OUTFITTING_STATION_ID,
		"region.outpost_platform"
	)
	station_state[FIELD_LOOP_PAYOFF_CONFIRMED_FLAG] = true


static func has_active_payoff(world_state: WorldState, character_state: CharacterState) -> bool:
	return (
		is_payoff_confirmed(world_state)
		and _has_station_built(world_state)
		and _has_filter_module_equipped(character_state)
	)


static func format_compact_state(world_state: WorldState, character_state: CharacterState) -> String:
	if is_payoff_confirmed(world_state):
		return "外勤收益已兑现"
	if can_confirm_payoff(world_state, character_state):
		return "外勤收益可确认"
	if has_field_loop_return(world_state) and not has_base_analysis_completed(world_state):
		return "外勤回收待解析"
	return ""


static func format_hud_summary(world_state: WorldState, character_state: CharacterState) -> Array[String]:
	if world_state == null or character_state == null:
		return []
	if world_state.current_region_id != "region.outpost_platform":
		return []
	if is_payoff_confirmed(world_state):
		return [
			"外勤收益：回波匣解析已接入整备台",
			"下一趟：污染 / 遗迹承压会读取外勤收益整备"
		]
	if can_confirm_payoff(world_state, character_state):
		return [
			"外勤收益兑现：回波匣与污染回波沉积已完成基地解析",
			"下一步：出发整备台确认收益整备，再从外勤出发口回遗迹 / 裂相脊"
		]
	if has_field_loop_return(world_state) and not has_base_analysis_completed(world_state):
		return [
			"外勤回收：回波匣和污染回波沉积已带回",
			"基地处理：过滤沉积保留污染浆液，再用基础反应器解析深段回波"
		]
	return []


static func format_outfitting_prompt_line(
	world_state: WorldState,
	character_state: CharacterState
) -> String:
	if is_payoff_confirmed(world_state):
		return "外勤收益兑现：已确认，回波匣解析接入整备台，下一趟污染 / 遗迹承压会读取收益。"
	if can_confirm_payoff(world_state, character_state):
		return "外勤收益兑现：深段回波已由基础反应器解析，可把回波匣和污染回波沉积的结果登记为下一趟外勤整备。"
	if has_base_analysis_completed(world_state) and not _has_filter_module_equipped(character_state):
		return "外勤收益兑现：深段回波已解析；先装入基础过滤模块，整备台才能把结果接入防护承压。"
	if has_field_loop_return(world_state) and not has_base_analysis_completed(world_state):
		return "外勤回收：回波匣已带回；先完成污染过滤和基础反应器解析，再回整备台兑现收益。"
	return ""


static func format_departure_next_step(world_state: WorldState, character_state: CharacterState) -> String:
	if can_confirm_payoff(world_state, character_state):
		return "先到出发整备台确认外勤收益整备，再从外勤出发口准备下一趟路线"
	if is_payoff_confirmed(world_state):
		return "外勤收益整备已确认；从外勤出发口回遗迹外圈或裂相脊观察承压和路线收益"
	if has_field_loop_return(world_state) and not has_base_analysis_completed(world_state):
		return "先用污染过滤器处理沉积物，再用基础反应器解析深段回波"
	return ""


static func format_pressure_payoff_line(world_state: WorldState) -> String:
	if is_payoff_confirmed(world_state):
		return "回波匣解析已兑现到整备台，下一趟污染采集、污染反击和遗迹承压会继续下降"
	return ""


static func format_confirmation_message() -> String:
	return "出发整备台完成外勤收益兑现：回波匣解析、污染回波沉积处理和基础过滤模块已串成下一趟外勤整备，污染采集、污染反击和遗迹承压会读取这次回基地收益。"


static func format_confirmation_status() -> String:
	return "回波匣解析 / 污染回波沉积 / 过滤模块已接入"


static func format_confirmation_next_step() -> String:
	return "回前哨核心补给并恢复生命 / 防护，然后从外勤出发口回遗迹外圈或裂相脊复测承压。"


static func format_pressure_feedback() -> String:
	return "外勤收益整备已接入，回波匣解析和污染回波沉积处理降低本次承压。"


static func _has_station_built(world_state: WorldState) -> bool:
	return (
		world_state != null
		and world_state.has_base_structure_definition(FIELD_OUTFITTING_STATION_ID)
	)


static func _has_filter_module_equipped(character_state: CharacterState) -> bool:
	return (
		character_state != null
		and String(character_state.equipment.get("suit_module", "")) == BASIC_FILTER_MODULE_ID
	)
