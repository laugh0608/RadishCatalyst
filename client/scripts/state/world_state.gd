extends RefCounted
class_name WorldState

var schema_version: int = 1
var world_id: String = "world.slice_01.prototype"
var current_region_id: String = "region.outpost_platform"
var unlocked_region_ids: Array[String] = ["region.outpost_platform"]
var time_minutes: int = 480
var current_weather_id: String = "weather.clear"
var pollution_levels: Dictionary = {
	"region.outpost_platform": 0.0,
	"region.crystal_vein_field": 0.0,
	"region.pollution_edge": 1.0
}
var map_objects: Dictionary = {}
var base_structures: Dictionary = {
	"structure.outpost_core": {
		"definition_id": "building.outpost_core",
		"region_id": "region.outpost_platform",
		"status": "idle"
	}
}
var quest_state: QuestState = QuestState.create_default()


static func create_default() -> WorldState:
	return WorldState.new()


func unlock_region(region_id: String) -> void:
	if not unlocked_region_ids.has(region_id):
		unlocked_region_ids.append(region_id)


func to_dict() -> Dictionary:
	return {
		"schema_version": schema_version,
		"world_id": world_id,
		"current_region_id": current_region_id,
		"unlocked_region_ids": unlocked_region_ids.duplicate(true),
		"time_minutes": time_minutes,
		"current_weather_id": current_weather_id,
		"pollution_levels": pollution_levels.duplicate(true),
		"map_objects": map_objects.duplicate(true),
		"base_structures": base_structures.duplicate(true),
		"quest_state": quest_state.to_dict()
	}


static func from_dict(data: Dictionary) -> WorldState:
	var state := WorldState.new()
	state.schema_version = int(data.get("schema_version", 1))
	state.world_id = String(data.get("world_id", "world.slice_01.prototype"))
	state.current_region_id = String(data.get("current_region_id", "region.outpost_platform"))
	state.unlocked_region_ids.assign(data.get("unlocked_region_ids", ["region.outpost_platform"]))
	state.time_minutes = int(data.get("time_minutes", 480))
	state.current_weather_id = String(data.get("current_weather_id", "weather.clear"))
	state.pollution_levels = data.get("pollution_levels", state.pollution_levels).duplicate(true)
	state.map_objects = data.get("map_objects", {}).duplicate(true)
	state.base_structures = data.get("base_structures", state.base_structures).duplicate(true)
	state.quest_state = QuestState.from_dict(data.get("quest_state", {}))
	return state
