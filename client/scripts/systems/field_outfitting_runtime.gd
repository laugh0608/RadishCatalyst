extends RefCounted
class_name FieldOutfittingRuntime

const FIELD_OUTFITTING_STATION_ID := "building.field_outfitting_station"
const FIELD_OUTFITTING_STATION_INSTANCE_ID := "map_object_instance.field_outfitting_station"
const FIELD_OUTFITTING_STATION_REGION_ID := "region.outpost_platform"
const LOGISTICS_MAINTENANCE_POLLUTION_RETEST_RESIDUE_INSTANCE_ID := "map_object_instance.pollution_residue_logistics_maintenance_pressure_cache"
const LOGISTICS_MAINTENANCE_POLLUTION_RETEST_GUARD_INSTANCE_ID := "enemy_instance.polluted_skitter_logistics_maintenance_pressure_guard"
const BASIC_FILTER_MODULE_ID := "equipment.filter_module_t1"
const MODULE_CALIBRATED_FLAG := "module_calibrated"
const CORE_ARCHIVE_MAINTAINED_FLAG := "core_archive_maintained"
const LOGISTICS_MATERIAL_PROCESSED_FLAG := "logistics_material_processed"
const LOGISTICS_MAINTENANCE_CONFIRMED_FLAG := "logistics_maintenance_confirmed"
const LOGISTICS_MAINTENANCE_POLLUTION_RETEST_PROCESSED_FLAG := "logistics_maintenance_pollution_retest_processed"
const PROTECTIVE_RESPONSE_READY_FLAG := "protective_response_ready"
const PROTECTIVE_RESPONSE_TRIGGERED_FLAG := "protective_response_triggered"
const MODULE_CALIBRATION_CRYSTAL_COST := 2
const MODULE_CALIBRATION_SCRAP_COST := 1
const MODULE_CALIBRATION_DRAIN_MULT := 0.9
const MODULE_CALIBRATION_COUNTER_MULT := 0.9
const CORE_ARCHIVE_MAINTENANCE_DRAIN_MULT := 0.95
const CORE_ARCHIVE_MAINTENANCE_COUNTER_MULT := 0.95
const LOGISTICS_MAINTENANCE_DRAIN_MULT := 0.85
const LOGISTICS_MAINTENANCE_COUNTER_MULT := 0.85
const PROTECTIVE_RESPONSE_COUNTER_MULT := 0.72


static func has_station_built(world_state: WorldState) -> bool:
	return (
		world_state != null
		and world_state.has_base_structure_definition(FIELD_OUTFITTING_STATION_ID)
	)


static func has_filter_module_equipped(character_state: CharacterState) -> bool:
	return (
		character_state != null
		and String(character_state.equipment.get("suit_module", "")) == BASIC_FILTER_MODULE_ID
	)


static func has_basic_suit_equipped(character_state: CharacterState) -> bool:
	return (
		character_state != null
		and String(character_state.equipment.get("suit", "")) == "equipment.basic_suit"
	)


static func has_calibration_materials(character_state: CharacterState) -> bool:
	if character_state == null:
		return false
	return (
		character_state.inventory.has_ref("item.crystal_ore", MODULE_CALIBRATION_CRYSTAL_COST)
		and character_state.inventory.has_ref("item.salvage_scrap", MODULE_CALIBRATION_SCRAP_COST)
	)


static func consume_calibration_materials(character_state: CharacterState) -> bool:
	if not has_calibration_materials(character_state):
		return false
	character_state.inventory.consume_ref("item.crystal_ore", MODULE_CALIBRATION_CRYSTAL_COST)
	character_state.inventory.consume_ref("item.salvage_scrap", MODULE_CALIBRATION_SCRAP_COST)
	return true


static func ensure_station_state(world_state: WorldState) -> Dictionary:
	if world_state == null:
		return {}
	return world_state.ensure_map_object(
		FIELD_OUTFITTING_STATION_INSTANCE_ID,
		FIELD_OUTFITTING_STATION_ID,
		FIELD_OUTFITTING_STATION_REGION_ID
	)


static func is_module_calibrated(world_state: WorldState) -> bool:
	if world_state == null:
		return false
	return bool(
		world_state.get_map_object(FIELD_OUTFITTING_STATION_INSTANCE_ID).get(
			MODULE_CALIBRATED_FLAG,
			false
		)
	)


static func mark_module_calibrated(world_state: WorldState) -> void:
	var station_state := ensure_station_state(world_state)
	if station_state.is_empty():
		return
	station_state[MODULE_CALIBRATED_FLAG] = true


static func is_core_archive_maintenance_available(
	character_state: CharacterState,
	world_state: WorldState
) -> bool:
	return (
		has_station_built(world_state)
		and has_filter_module_equipped(character_state)
		and world_state.quest_state.has_completed_quest("quest.write_demo_stabilization_core")
	)


static func is_core_archive_maintained(world_state: WorldState) -> bool:
	if world_state == null:
		return false
	return bool(
		world_state.get_map_object(FIELD_OUTFITTING_STATION_INSTANCE_ID).get(
			CORE_ARCHIVE_MAINTAINED_FLAG,
			false
		)
	)


static func mark_core_archive_maintained(world_state: WorldState) -> void:
	var station_state := ensure_station_state(world_state)
	if station_state.is_empty():
		return
	station_state[CORE_ARCHIVE_MAINTAINED_FLAG] = true


static func is_crystal_logistics_return_available(world_state: WorldState) -> bool:
	return (
		world_state != null
		and world_state.quest_state.has_completed_quest("quest.write_demo_stabilization_core")
		and is_core_archive_maintained(world_state)
		and CoreStabilizationPressureFormatter.has_retest_readout(world_state)
	)


static func has_crystal_logistics_return_crystal(world_state: WorldState) -> bool:
	if world_state == null:
		return false
	return bool(
		world_state.get_map_object(
			CoreGuardAftermathFormatter.CRYSTAL_LOGISTICS_RETURN_CRYSTAL_INSTANCE_ID
		).get("is_gathered", false)
	)


static func has_crystal_logistics_return_wreckage(world_state: WorldState) -> bool:
	if world_state == null:
		return false
	return bool(
		world_state.get_map_object(
			CoreGuardAftermathFormatter.CRYSTAL_LOGISTICS_RETURN_WRECKAGE_INSTANCE_ID
		).get("is_gathered", false)
	)


static func has_crystal_logistics_return_materials(world_state: WorldState) -> bool:
	return (
		has_crystal_logistics_return_crystal(world_state)
		and has_crystal_logistics_return_wreckage(world_state)
	)


static func is_logistics_material_processed(world_state: WorldState) -> bool:
	if world_state == null:
		return false
	return bool(
		world_state.get_map_object(FIELD_OUTFITTING_STATION_INSTANCE_ID).get(
			LOGISTICS_MATERIAL_PROCESSED_FLAG,
			false
		)
	)


static func mark_logistics_material_processed(world_state: WorldState) -> void:
	var station_state := ensure_station_state(world_state)
	if station_state.is_empty():
		return
	station_state[LOGISTICS_MATERIAL_PROCESSED_FLAG] = true


static func is_logistics_maintenance_confirmed(world_state: WorldState) -> bool:
	if world_state == null:
		return false
	return bool(
		world_state.get_map_object(FIELD_OUTFITTING_STATION_INSTANCE_ID).get(
			LOGISTICS_MAINTENANCE_CONFIRMED_FLAG,
			false
		)
	)


static func mark_logistics_maintenance_confirmed(world_state: WorldState) -> void:
	var station_state := ensure_station_state(world_state)
	if station_state.is_empty():
		return
	station_state[LOGISTICS_MAINTENANCE_CONFIRMED_FLAG] = true


static func is_logistics_maintenance_pollution_retest_available(world_state: WorldState) -> bool:
	return is_logistics_maintenance_confirmed(world_state)


static func has_logistics_maintenance_pollution_retest_residue(world_state: WorldState) -> bool:
	if world_state == null:
		return false
	return bool(
		world_state.get_map_object(LOGISTICS_MAINTENANCE_POLLUTION_RETEST_RESIDUE_INSTANCE_ID).get(
			"is_gathered",
			false
		)
	)


static func is_logistics_maintenance_pollution_retest_processed(world_state: WorldState) -> bool:
	if world_state == null:
		return false
	return bool(
		world_state.get_map_object(LOGISTICS_MAINTENANCE_POLLUTION_RETEST_RESIDUE_INSTANCE_ID).get(
			LOGISTICS_MAINTENANCE_POLLUTION_RETEST_PROCESSED_FLAG,
			false
		)
	)


static func mark_logistics_maintenance_pollution_retest_processed(world_state: WorldState) -> void:
	if world_state == null:
		return
	var residue_state := world_state.ensure_map_object(
		LOGISTICS_MAINTENANCE_POLLUTION_RETEST_RESIDUE_INSTANCE_ID,
		"map_object.pollution_residue_patch",
		"region.pollution_edge"
	)
	residue_state["is_gathered"] = true
	residue_state[LOGISTICS_MAINTENANCE_POLLUTION_RETEST_PROCESSED_FLAG] = true


static func is_protective_response_ready(world_state: WorldState) -> bool:
	if world_state == null:
		return false
	return bool(
		world_state.get_map_object(FIELD_OUTFITTING_STATION_INSTANCE_ID).get(
			PROTECTIVE_RESPONSE_READY_FLAG,
			false
		)
	)


static func has_protective_response_triggered(world_state: WorldState) -> bool:
	if world_state == null:
		return false
	return bool(
		world_state.get_map_object(FIELD_OUTFITTING_STATION_INSTANCE_ID).get(
			PROTECTIVE_RESPONSE_TRIGGERED_FLAG,
			false
		)
	)


static func can_confirm_protective_response(
	character_state: CharacterState,
	world_state: WorldState
) -> bool:
	return _get_protective_response_blocker(character_state, world_state).is_empty()


static func mark_protective_response_ready(world_state: WorldState) -> void:
	var station_state := ensure_station_state(world_state)
	if station_state.is_empty():
		return
	station_state[PROTECTIVE_RESPONSE_READY_FLAG] = true
	station_state[PROTECTIVE_RESPONSE_TRIGGERED_FLAG] = false


static func consume_protective_response(
	character_state: CharacterState,
	world_state: WorldState
) -> bool:
	if not is_protective_response_ready(world_state):
		return false
	if not has_station_built(world_state):
		return false
	if not has_basic_suit_equipped(character_state) or not has_filter_module_equipped(character_state):
		return false
	var station_state := ensure_station_state(world_state)
	if station_state.is_empty():
		return false
	station_state[PROTECTIVE_RESPONSE_READY_FLAG] = false
	station_state[PROTECTIVE_RESPONSE_TRIGGERED_FLAG] = true
	return true


static func format_protective_response_compact_state(
	world_state: WorldState,
	character_state: CharacterState
) -> String:
	if is_protective_response_ready(world_state):
		return "防护响应待命"
	if has_protective_response_triggered(world_state):
		if can_confirm_protective_response(character_state, world_state):
			return "防护响应可复位"
		return "防护响应已触发"
	if can_confirm_protective_response(character_state, world_state):
		return "防护响应可确认"
	return ""


static func format_protective_response_prompt_line(
	world_state: WorldState,
	character_state: CharacterState
) -> String:
	if is_protective_response_ready(world_state):
		return "防护响应：已待命，下一次外勤反击会读取防护服、过滤模块和前哨补给。"
	if has_protective_response_triggered(world_state):
		if can_confirm_protective_response(character_state, world_state):
			return "防护响应：已触发，当前补给和防护已恢复，可在整备台重新确认。"
		return "防护响应：已触发；先回前哨核心补给并恢复生命 / 防护，再回整备台复查。"
	if can_confirm_protective_response(character_state, world_state):
		return "防护响应：可确认；基础防护服、过滤模块、修复凝胶和抗污染药剂已齐备。"
	var blocker := _get_protective_response_blocker(character_state, world_state)
	if blocker.is_empty():
		return ""
	return "防护响应：未就绪；%s。" % blocker


static func format_protective_response_next_step(
	world_state: WorldState,
	character_state: CharacterState
) -> String:
	if is_protective_response_ready(world_state):
		return "从外勤出发口进入下一场外勤反击，战斗日志会读出防护响应承压下降。"
	if has_protective_response_triggered(world_state):
		if can_confirm_protective_response(character_state, world_state):
			return "在出发整备台重新确认防护响应，再出发。"
		return "回前哨核心补修复凝胶 / 抗污染药剂并恢复生命 / 防护，再回整备台复查。"
	if can_confirm_protective_response(character_state, world_state):
		return "在出发整备台按 E 确认防护响应。"
	return _get_protective_response_blocker(character_state, world_state)


static func format_protective_response_counter_feedback() -> String:
	return "防护响应已触发：出发整备台把基础防护服、过滤模块和前哨补给接入本次反击，生命 / 防护承压下降。"


static func should_process_logistics_materials(
	character_state: CharacterState,
	world_state: WorldState
) -> bool:
	return (
		is_crystal_logistics_return_available(world_state)
		and has_crystal_logistics_return_materials(world_state)
		and not is_logistics_material_processed(world_state)
		and character_state != null
		and character_state.inventory.has_ref("item.crystal_ore", 3)
	)


static func should_confirm_logistics_maintenance(
	character_state: CharacterState,
	world_state: WorldState
) -> bool:
	return (
		has_station_built(world_state)
		and has_filter_module_equipped(character_state)
		and is_logistics_material_processed(world_state)
		and not is_logistics_maintenance_confirmed(world_state)
	)


static func has_active_module_calibration(
	character_state: CharacterState,
	world_state: WorldState
) -> bool:
	return (
		has_filter_module_equipped(character_state)
		and has_station_built(world_state)
		and is_module_calibrated(world_state)
	)


static func has_active_core_archive_maintenance(
	character_state: CharacterState,
	world_state: WorldState
) -> bool:
	return (
		is_core_archive_maintenance_available(character_state, world_state)
		and is_core_archive_maintained(world_state)
	)


static func has_active_logistics_maintenance(
	character_state: CharacterState,
	world_state: WorldState
) -> bool:
	return (
		has_station_built(world_state)
		and has_filter_module_equipped(character_state)
		and is_logistics_maintenance_confirmed(world_state)
	)


static func get_pollution_drain_multiplier(
	character_state: CharacterState,
	world_state: WorldState
) -> float:
	var multiplier := 1.0
	if has_active_module_calibration(character_state, world_state):
		multiplier *= MODULE_CALIBRATION_DRAIN_MULT
	if has_active_core_archive_maintenance(character_state, world_state):
		multiplier *= CORE_ARCHIVE_MAINTENANCE_DRAIN_MULT
	if has_active_logistics_maintenance(character_state, world_state):
		multiplier *= LOGISTICS_MAINTENANCE_DRAIN_MULT
	return multiplier


static func _get_protective_response_blocker(
	character_state: CharacterState,
	world_state: WorldState
) -> String:
	if not has_station_built(world_state):
		return "出发整备台尚未上线"
	if not has_basic_suit_equipped(character_state):
		return "需要基础防护服作为响应载体"
	if not has_filter_module_equipped(character_state):
		return "需要基础过滤模块装入防护服"
	if character_state == null or not character_state.inventory.has_ref(DepartureSupplyRuntime.REPAIR_GEL_ID, 1):
		return "缺少修复凝胶"
	if not character_state.inventory.has_ref(DepartureSupplyRuntime.RESISTANCE_VIAL_ID, 1):
		return "缺少抗污染药剂"
	if not character_state.are_vitals_full():
		return "需要前哨核心恢复生命 / 防护"
	return ""


static func get_pollution_counter_damage_multiplier(
	character_state: CharacterState,
	world_state: WorldState
) -> float:
	var multiplier := 1.0
	if has_active_module_calibration(character_state, world_state):
		multiplier *= MODULE_CALIBRATION_COUNTER_MULT
	if has_active_core_archive_maintenance(character_state, world_state):
		multiplier *= CORE_ARCHIVE_MAINTENANCE_COUNTER_MULT
	if has_active_logistics_maintenance(character_state, world_state):
		multiplier *= LOGISTICS_MAINTENANCE_COUNTER_MULT
	return multiplier


static func format_pollution_pressure_feedback(
	character_state: CharacterState,
	world_state: WorldState
) -> String:
	var has_calibration := has_active_module_calibration(character_state, world_state)
	var has_archive_maintenance := has_active_core_archive_maintenance(character_state, world_state)
	var has_logistics_maintenance := has_active_logistics_maintenance(character_state, world_state)
	if has_calibration and has_archive_maintenance and has_logistics_maintenance:
		return "出发整备台校准、核心归档维护和后勤维护已接入，污染承压明显下降。"
	if has_archive_maintenance and has_logistics_maintenance:
		return "核心归档维护和后勤维护已接入，污染承压明显下降。"
	if has_calibration and has_logistics_maintenance:
		return "出发整备台校准和后勤维护已接入，污染承压明显下降。"
	if has_calibration and has_archive_maintenance:
		return "出发整备台校准和核心归档维护已接入，污染承压继续下降。"
	if has_logistics_maintenance:
		return "后勤维护已接入，污染承压明显下降。"
	if has_archive_maintenance:
		return "核心归档维护已接入，污染承压继续下降。"
	if has_calibration:
		return "出发整备台校准已接入，污染承压继续下降。"
	return ""


static func format_ruin_outer_ring_pressure_feedback(
	character_state: CharacterState,
	world_state: WorldState
) -> String:
	if not has_filter_module_equipped(character_state):
		return "基础过滤模块未装入，外圈相位回波会完整命中生命和防护。"
	var outfitting_parts: Array[String] = []
	if has_active_module_calibration(character_state, world_state):
		outfitting_parts.append("模块校准")
	if has_active_core_archive_maintenance(character_state, world_state):
		outfitting_parts.append("核心归档维护")
	if has_active_logistics_maintenance(character_state, world_state):
		outfitting_parts.append("后勤维护")
	if outfitting_parts.is_empty():
		return "基础过滤模块已装入，外圈相位回波反击承压下降。"
	return "%s已接入，遗迹外圈相位反击承压继续下降。" % "、".join(outfitting_parts)
