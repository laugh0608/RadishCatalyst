extends RefCounted
class_name FieldOutfittingRuntime

const FIELD_OUTFITTING_STATION_ID := "building.field_outfitting_station"
const FIELD_OUTFITTING_STATION_INSTANCE_ID := "map_object_instance.field_outfitting_station"
const FIELD_OUTFITTING_STATION_REGION_ID := "region.outpost_platform"
const BASIC_FILTER_MODULE_ID := "equipment.filter_module_t1"
const MODULE_CALIBRATED_FLAG := "module_calibrated"
const CORE_ARCHIVE_MAINTAINED_FLAG := "core_archive_maintained"
const LOGISTICS_MATERIAL_PROCESSED_FLAG := "logistics_material_processed"
const LOGISTICS_MAINTENANCE_CONFIRMED_FLAG := "logistics_maintenance_confirmed"
const MODULE_CALIBRATION_CRYSTAL_COST := 2
const MODULE_CALIBRATION_SCRAP_COST := 1
const MODULE_CALIBRATION_DRAIN_MULT := 0.9
const MODULE_CALIBRATION_COUNTER_MULT := 0.9
const CORE_ARCHIVE_MAINTENANCE_DRAIN_MULT := 0.95
const CORE_ARCHIVE_MAINTENANCE_COUNTER_MULT := 0.95


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


static func get_pollution_drain_multiplier(
	character_state: CharacterState,
	world_state: WorldState
) -> float:
	var multiplier := 1.0
	if has_active_module_calibration(character_state, world_state):
		multiplier *= MODULE_CALIBRATION_DRAIN_MULT
	if has_active_core_archive_maintenance(character_state, world_state):
		multiplier *= CORE_ARCHIVE_MAINTENANCE_DRAIN_MULT
	return multiplier


static func get_pollution_counter_damage_multiplier(
	character_state: CharacterState,
	world_state: WorldState
) -> float:
	var multiplier := 1.0
	if has_active_module_calibration(character_state, world_state):
		multiplier *= MODULE_CALIBRATION_COUNTER_MULT
	if has_active_core_archive_maintenance(character_state, world_state):
		multiplier *= CORE_ARCHIVE_MAINTENANCE_COUNTER_MULT
	return multiplier


static func format_pollution_pressure_feedback(
	character_state: CharacterState,
	world_state: WorldState
) -> String:
	var has_calibration := has_active_module_calibration(character_state, world_state)
	var has_archive_maintenance := has_active_core_archive_maintenance(character_state, world_state)
	if has_calibration and has_archive_maintenance:
		return "出发整备台校准和核心归档维护已接入，污染承压继续下降。"
	if has_archive_maintenance:
		return "核心归档维护已接入，污染承压继续下降。"
	if has_calibration:
		return "出发整备台校准已接入，污染承压继续下降。"
	return ""
