extends RefCounted
class_name FieldOutfittingRuntime

const FIELD_OUTFITTING_STATION_ID := "building.field_outfitting_station"
const FIELD_OUTFITTING_STATION_INSTANCE_ID := "map_object_instance.field_outfitting_station"
const FIELD_OUTFITTING_STATION_REGION_ID := "region.outpost_platform"
const BASIC_FILTER_MODULE_ID := "equipment.filter_module_t1"
const MODULE_CALIBRATED_FLAG := "module_calibrated"
const MODULE_CALIBRATION_CRYSTAL_COST := 2
const MODULE_CALIBRATION_SCRAP_COST := 1
const MODULE_CALIBRATION_DRAIN_MULT := 0.9
const MODULE_CALIBRATION_COUNTER_MULT := 0.9


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


static func has_active_module_calibration(
	character_state: CharacterState,
	world_state: WorldState
) -> bool:
	return (
		has_filter_module_equipped(character_state)
		and has_station_built(world_state)
		and is_module_calibrated(world_state)
	)


static func get_pollution_drain_multiplier(
	character_state: CharacterState,
	world_state: WorldState
) -> float:
	if has_active_module_calibration(character_state, world_state):
		return MODULE_CALIBRATION_DRAIN_MULT
	return 1.0


static func get_pollution_counter_damage_multiplier(
	character_state: CharacterState,
	world_state: WorldState
) -> float:
	if has_active_module_calibration(character_state, world_state):
		return MODULE_CALIBRATION_COUNTER_MULT
	return 1.0
