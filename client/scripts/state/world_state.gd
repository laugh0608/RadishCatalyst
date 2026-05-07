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
	"region.pollution_edge": 1.0,
	"region.ruin_outer_ring": 1.15
}
var map_objects: Dictionary = {}
var enemies: Dictionary = {}
var base_structures: Dictionary = {
	"structure.outpost_core": {
		"definition_id": "building.outpost_core",
		"region_id": "region.outpost_platform",
		"status": "idle"
	},
	"structure.basic_reactor": {
		"definition_id": "building.basic_reactor",
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


func ensure_map_object(instance_id: String, definition_id: String, region_id: String = "") -> Dictionary:
	if not map_objects.has(instance_id):
		map_objects[instance_id] = {
			"definition_id": definition_id,
			"region_id": region_id,
			"is_gathered": false,
			"is_sampled": false,
			"is_cleared": false
		}
	return map_objects[instance_id]


func get_map_object(instance_id: String) -> Dictionary:
	return map_objects.get(instance_id, {})


func ensure_enemy(instance_id: String, definition_id: String, region_id: String = "", max_health: float = 1.0) -> Dictionary:
	if not enemies.has(instance_id):
		enemies[instance_id] = {
			"definition_id": definition_id,
			"region_id": region_id,
			"health": max_health,
			"max_health": max_health,
			"is_defeated": false
		}
	return enemies[instance_id]


func get_enemy(instance_id: String) -> Dictionary:
	return enemies.get(instance_id, {})


func update_enemy_health(instance_id: String, health: float, is_defeated: bool) -> void:
	if not enemies.has(instance_id):
		return
	enemies[instance_id]["health"] = health
	enemies[instance_id]["is_defeated"] = is_defeated


func has_enemy_drops_granted(instance_id: String) -> bool:
	if not enemies.has(instance_id):
		return false
	return bool(enemies[instance_id].get("drops_granted", false))


func set_enemy_drops_granted(instance_id: String, drops_granted: bool) -> void:
	if not enemies.has(instance_id):
		return
	enemies[instance_id]["drops_granted"] = drops_granted


func ensure_base_structure(structure_id: String, definition_id: String, region_id: String = "") -> Dictionary:
	if not base_structures.has(structure_id):
		base_structures[structure_id] = {
			"definition_id": definition_id,
			"region_id": region_id,
			"status": "idle"
		}
	return base_structures[structure_id]


func add_base_structure(structure_id: String, definition_id: String, region_id: String = "", site_instance_id: String = "") -> Dictionary:
	var structure := ensure_base_structure(structure_id, definition_id, region_id)
	if not site_instance_id.is_empty():
		structure["site_instance_id"] = site_instance_id
	return structure


func has_base_structure_definition(definition_id: String) -> bool:
	return count_base_structures(definition_id) > 0


func get_base_structure_id_for_definition(definition_id: String) -> String:
	for structure_id in base_structures:
		var structure = base_structures[structure_id]
		if not structure is Dictionary:
			continue
		if String(structure.get("definition_id", "")) == definition_id:
			return String(structure_id)
	return ""


func count_base_structures(definition_id: String) -> int:
	var count := 0
	for structure in base_structures.values():
		if not structure is Dictionary:
			continue
		if String(structure.get("definition_id", "")) == definition_id:
			count += 1
	return count


func set_base_structure_status(structure_id: String, status: String, recipe_id: String = "") -> void:
	if not base_structures.has(structure_id):
		return

	base_structures[structure_id]["status"] = status
	if status == "in_progress":
		base_structures[structure_id]["active_recipe_id"] = recipe_id
		base_structures[structure_id]["progress_seconds"] = 0.0
		return

	base_structures[structure_id].erase("active_recipe_id")
	base_structures[structure_id].erase("progress_seconds")
	if status == "completed" and not recipe_id.is_empty():
		base_structures[structure_id]["last_recipe_id"] = recipe_id
		base_structures[structure_id]["completed_runs"] = int(base_structures[structure_id].get("completed_runs", 0)) + 1


func set_base_structure_progress(structure_id: String, progress_seconds: float) -> void:
	if not base_structures.has(structure_id):
		return
	base_structures[structure_id]["progress_seconds"] = progress_seconds


func set_map_object_flag(instance_id: String, flag_name: String, value: bool) -> void:
	if not map_objects.has(instance_id):
		return
	map_objects[instance_id][flag_name] = value


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
		"enemies": enemies.duplicate(true),
		"base_structures": base_structures.duplicate(true),
		"quest_state": quest_state.to_dict()
	}


static func from_dict(data: Dictionary) -> WorldState:
	var state := WorldState.new()
	state.schema_version = int(data.get("schema_version", 1))
	state.world_id = String(data.get("world_id", "world.slice_01.prototype"))
	state.current_region_id = String(data.get("current_region_id", "region.outpost_platform"))
	var unlocked_region_ids_data = data.get("unlocked_region_ids", state.unlocked_region_ids)
	if unlocked_region_ids_data is Array:
		state.unlocked_region_ids.assign(unlocked_region_ids_data)
	state.time_minutes = int(data.get("time_minutes", 480))
	state.current_weather_id = String(data.get("current_weather_id", "weather.clear"))
	var pollution_levels_data = data.get("pollution_levels", state.pollution_levels)
	if pollution_levels_data is Dictionary:
		state.pollution_levels = pollution_levels_data.duplicate(true)
	var map_objects_data = data.get("map_objects", {})
	if map_objects_data is Dictionary:
		state.map_objects = map_objects_data.duplicate(true)
	var enemies_data = data.get("enemies", {})
	if enemies_data is Dictionary:
		state.enemies = enemies_data.duplicate(true)
	var base_structures_data = data.get("base_structures", state.base_structures)
	if base_structures_data is Dictionary:
		state.base_structures = base_structures_data.duplicate(true)
	var quest_state_data = data.get("quest_state", {})
	if quest_state_data is Dictionary:
		state.quest_state = QuestState.from_dict(quest_state_data)
	return state
