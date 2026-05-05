extends RefCounted
class_name SaveContentValidator

const PROTOTYPE_MAP_OBJECT_SOURCES := {
	"map_object_instance.outpost_core": "building.outpost_core",
	"map_object_instance.basic_reactor": "building.basic_reactor",
	"map_object_instance.crystal_cluster": "map_object.crystal_cluster",
	"map_object_instance.crystal_cluster_east": "map_object.crystal_cluster",
	"map_object_instance.crystal_cluster_south": "map_object.crystal_cluster",
	"map_object_instance.field_wreckage_north": "map_object.field_wreckage",
	"map_object_instance.field_wreckage_east": "map_object.field_wreckage",
	"map_object_instance.anomaly_crystal": "map_object.anomaly_crystal",
	"map_object_instance.pollution_residue": "map_object.pollution_residue_patch",
	"map_object_instance.rough_ground_north": "map_object.rough_ground",
	"map_object_instance.rough_ground_south": "map_object.rough_ground",
	"map_object_instance.foundation_site_north": "building.foundation_t1",
	"map_object_instance.foundation_site_south": "building.foundation_t1",
	"map_object_instance.pollution_filter_build_site": "building.pollution_filter",
	"map_object_instance.pollution_filter": "building.pollution_filter",
	"map_object_instance.ruin_gate": "map_object.ruin_gate"
}

const PROTOTYPE_ENEMY_SOURCES := {
	"enemy_instance.native_skitter": {
		"definition_id": "enemy.native_skitter",
		"region_id": "region.crystal_vein_field"
	},
	"enemy_instance.treatment_skitter": {
		"definition_id": "enemy.native_skitter",
		"region_id": "region.crystal_vein_field"
	},
	"enemy_instance.polluted_skitter": {
		"definition_id": "enemy.polluted_skitter",
		"region_id": "region.pollution_edge"
	}
}

const PROTOTYPE_BASE_STRUCTURE_SOURCES := {
	"structure.outpost_core": {
		"definition_id": "building.outpost_core",
		"site_instance_id": ""
	},
	"structure.basic_reactor": {
		"definition_id": "building.basic_reactor",
		"site_instance_id": ""
	},
	"structure.foundation_site_north": {
		"definition_id": "building.foundation_t1",
		"site_instance_id": "map_object_instance.foundation_site_north"
	},
	"structure.foundation_site_south": {
		"definition_id": "building.foundation_t1",
		"site_instance_id": "map_object_instance.foundation_site_south"
	},
	"structure.pollution_filter_build_site": {
		"definition_id": "building.pollution_filter",
		"site_instance_id": "map_object_instance.pollution_filter_build_site"
	}
}

const MAP_OBJECT_ALLOWED_FIELDS := [
	"definition_id",
	"region_id",
	"is_gathered",
	"is_sampled",
	"is_cleared",
	"is_built",
	"built_definition_id"
]

const ENEMY_ALLOWED_FIELDS := [
	"definition_id",
	"region_id",
	"health",
	"max_health",
	"is_defeated",
	"drops_granted"
]

const BASE_STRUCTURE_ALLOWED_FIELDS := [
	"definition_id",
	"region_id",
	"status",
	"site_instance_id",
	"last_recipe_id",
	"completed_runs",
	"active_recipe_id",
	"progress_seconds",
	"input_buffer",
	"output_buffer"
]

const BASE_STRUCTURE_ALLOWED_STATUSES := [
	"idle",
	"in_progress",
	"completed"
]

const STRUCTURE_BUFFER_ALLOWED_FIELDS := [
	"items",
	"fluids",
	"capacity_slots"
]

const DEFAULT_ACTIVE_QUEST_IDS: Array[String] = ["quest.restore_outpost"]
const DEFAULT_UNLOCKED_REGION_IDS: Array[String] = ["region.outpost_platform"]

var data_registry: DataRegistry


func _init(registry: DataRegistry) -> void:
	data_registry = registry


func validate_save_content(save_data: Dictionary) -> String:
	if data_registry == null:
		return ""

	var world_data: Dictionary = save_data.get("world", {})
	var character_data: Dictionary = save_data.get("character", {})
	var world_error := _validate_world_content(world_data)
	if not world_error.is_empty():
		return world_error
	var character_error := _validate_character_content(character_data)
	if not character_error.is_empty():
		return character_error
	var cross_block_error := _validate_cross_block_content(world_data, character_data)
	if not cross_block_error.is_empty():
		return cross_block_error
	return ""


func _validate_world_content(world_data: Dictionary) -> String:
	var current_region_id := String(world_data.get("current_region_id", "region.outpost_platform"))
	var region_error := _validate_definition_ref(current_region_id, "region.", "world.current_region_id")
	if not region_error.is_empty():
		return region_error

	var weather_error := _validate_definition_ref(String(world_data.get("current_weather_id", "weather.clear")), "weather.", "world.current_weather_id")
	if not weather_error.is_empty():
		return weather_error

	var time_minutes = world_data.get("time_minutes", 480)
	if not _is_number(time_minutes) or int(time_minutes) < 0:
		return "读取存档失败：world.time_minutes 必须是非负数字，当前运行状态已保留。"

	var unlocked_region_ids = world_data.get("unlocked_region_ids", [])
	if unlocked_region_ids is Array:
		for region_id in unlocked_region_ids:
			region_error = _validate_definition_ref(String(region_id), "region.", "world.unlocked_region_ids")
			if not region_error.is_empty():
				return region_error

	var pollution_levels = world_data.get("pollution_levels", {})
	if pollution_levels is Dictionary:
		for region_id in pollution_levels:
			region_error = _validate_definition_ref(String(region_id), "region.", "world.pollution_levels")
			if not region_error.is_empty():
				return region_error
			var pollution_value = pollution_levels[region_id]
			if not _is_number(pollution_value) or float(pollution_value) < 0.0:
				return "读取存档失败：world.pollution_levels 中存在无效污染值，当前运行状态已保留。"

	var map_objects_error := _validate_runtime_object_map(world_data.get("map_objects", {}), ["map_object.", "building."], "map_object_instance.", "world.map_objects")
	if not map_objects_error.is_empty():
		return map_objects_error
	var map_object_fields_error := _validate_runtime_object_fields(world_data.get("map_objects", {}), MAP_OBJECT_ALLOWED_FIELDS, "world.map_objects")
	if not map_object_fields_error.is_empty():
		return map_object_fields_error
	var map_object_source_error := _validate_map_object_sources(world_data.get("map_objects", {}))
	if not map_object_source_error.is_empty():
		return map_object_source_error
	var enemies_error := _validate_runtime_object_map(world_data.get("enemies", {}), ["enemy."], "enemy_instance.", "world.enemies")
	if not enemies_error.is_empty():
		return enemies_error
	var enemy_fields_error := _validate_runtime_object_fields(world_data.get("enemies", {}), ENEMY_ALLOWED_FIELDS, "world.enemies")
	if not enemy_fields_error.is_empty():
		return enemy_fields_error
	var enemy_source_error := _validate_enemy_sources(world_data.get("enemies", {}))
	if not enemy_source_error.is_empty():
		return enemy_source_error
	var structures_error := _validate_runtime_object_map(world_data.get("base_structures", {}), ["building."], "structure.", "world.base_structures")
	if not structures_error.is_empty():
		return structures_error
	var structure_fields_error := _validate_runtime_object_fields(world_data.get("base_structures", {}), BASE_STRUCTURE_ALLOWED_FIELDS, "world.base_structures")
	if not structure_fields_error.is_empty():
		return structure_fields_error
	var structure_source_error := _validate_base_structure_sources(world_data.get("base_structures", {}))
	if not structure_source_error.is_empty():
		return structure_source_error
	var structure_state_error := _validate_base_structure_runtime_state(world_data.get("base_structures", {}), world_data.get("quest_state", {}))
	if not structure_state_error.is_empty():
		return structure_state_error

	var quest_state = world_data.get("quest_state", {})
	if quest_state is Dictionary:
		var quest_error := _validate_quest_content(quest_state)
		if not quest_error.is_empty():
			return quest_error

	return ""


func _validate_character_content(character_data: Dictionary) -> String:
	var region_error := _validate_definition_ref(String(character_data.get("current_region_id", "region.outpost_platform")), "region.", "character.current_region_id")
	if not region_error.is_empty():
		return region_error

	var max_health_value = character_data.get("max_health", 100.0)
	var health_value = character_data.get("health", 100.0)
	if not _is_number(max_health_value) or not _is_number(health_value):
		return "读取存档失败：character.health 必须是数字，当前运行状态已保留。"
	var max_health := float(max_health_value)
	var health := float(health_value)
	if max_health <= 0.0 or health < 0.0 or health > max_health:
		return "读取存档失败：character.health 超出有效范围，当前运行状态已保留。"

	var max_protection_value = character_data.get("max_protection", 100.0)
	var protection_value = character_data.get("protection", 100.0)
	if not _is_number(max_protection_value) or not _is_number(protection_value):
		return "读取存档失败：character.protection 必须是数字，当前运行状态已保留。"
	var max_protection := float(max_protection_value)
	var protection := float(protection_value)
	if max_protection <= 0.0 or protection < 0.0 or protection > max_protection:
		return "读取存档失败：character.protection 超出有效范围，当前运行状态已保留。"

	var position = character_data.get("position", {})
	if position is Dictionary:
		if not _is_number(position.get("x", 0.0)) or not _is_number(position.get("y", 0.0)):
			return "读取存档失败：character.position 坐标必须是数字，当前运行状态已保留。"

	var equipment = character_data.get("equipment", {})
	if equipment is Dictionary:
		for slot_name in equipment:
			var equipment_id := String(equipment[slot_name])
			if equipment_id.is_empty():
				continue
			var equipment_error := _validate_definition_ref(equipment_id, "equipment.", "character.equipment.%s" % String(slot_name))
			if not equipment_error.is_empty():
				return equipment_error

	var quick_slots = character_data.get("quick_slots", [])
	if quick_slots is Array:
		for quick_slot_id in quick_slots:
			var item_id := String(quick_slot_id)
			if item_id.is_empty():
				continue
			var quick_slot_error := _validate_definition_ref(item_id, "item.", "character.quick_slots")
			if not quick_slot_error.is_empty():
				return quick_slot_error

	var inventory_error := _validate_inventory_content(character_data.get("inventory", {}), "character.inventory")
	if not inventory_error.is_empty():
		return inventory_error

	return ""


func _validate_runtime_object_map(value, expected_definition_prefixes: Array, expected_instance_prefix: String, label: String) -> String:
	if not (value is Dictionary):
		return ""

	for instance_id in value:
		var instance_id_string := String(instance_id)
		if instance_id_string.is_empty() or not instance_id_string.begins_with(expected_instance_prefix):
			return "读取存档失败：%s 中存在无效实例 ID：%s，当前运行状态已保留。" % [label, instance_id_string]

		var entry = value[instance_id]
		if not (entry is Dictionary):
			return "读取存档失败：%s 中存在无效对象状态，当前运行状态已保留。" % label

		var definition_error := _validate_definition_ref_any(String(entry.get("definition_id", "")), expected_definition_prefixes, "%s.%s.definition_id" % [label, String(instance_id)])
		if not definition_error.is_empty():
			return definition_error

		var region_id := String(entry.get("region_id", ""))
		if not region_id.is_empty():
			var region_error := _validate_definition_ref(region_id, "region.", "%s.%s.region_id" % [label, String(instance_id)])
			if not region_error.is_empty():
				return region_error

		if expected_definition_prefixes.has("enemy."):
			var max_health = entry.get("max_health", 1.0)
			var health = entry.get("health", max_health)
			if not _is_number(max_health) or not _is_number(health):
				return "读取存档失败：%s 中存在无效敌人生命值，当前运行状态已保留。" % label
			if float(max_health) <= 0.0 or float(health) < 0.0 or float(health) > float(max_health):
				return "读取存档失败：%s 中敌人生命值超出有效范围，当前运行状态已保留。" % label

	return ""


func _validate_runtime_object_fields(value, allowed_fields: Array, label: String) -> String:
	if not (value is Dictionary):
		return ""

	for instance_id in value:
		var entry = value[instance_id]
		if not (entry is Dictionary):
			continue
		for field_name in entry:
			var field_name_string := String(field_name)
			if not allowed_fields.has(field_name_string):
				return "读取存档失败：%s.%s 包含不允许的字段：%s，当前运行状态已保留。" % [
					label,
					String(instance_id),
					field_name_string
				]
	return ""


func _validate_map_object_sources(value) -> String:
	if not (value is Dictionary):
		return ""

	for instance_id in value:
		var instance_id_string := String(instance_id)
		if not PROTOTYPE_MAP_OBJECT_SOURCES.has(instance_id_string):
			return "读取存档失败：world.map_objects.%s 没有匹配的原型地图对象来源，当前运行状态已保留。" % instance_id_string

		var entry = value[instance_id]
		if not (entry is Dictionary):
			continue

		var expected_definition_id := String(PROTOTYPE_MAP_OBJECT_SOURCES[instance_id_string])
		var definition_id := String(entry.get("definition_id", ""))
		if definition_id != expected_definition_id:
			return "读取存档失败：world.map_objects.%s 与原型地图对象定义不一致，当前运行状态已保留。" % instance_id_string

		var built_definition_id := String(entry.get("built_definition_id", ""))
		if expected_definition_id.begins_with("building.") and not built_definition_id.is_empty() and built_definition_id != expected_definition_id:
			return "读取存档失败：world.map_objects.%s 的建成定义与原型地图对象定义不一致，当前运行状态已保留。" % instance_id_string

	return ""


func _validate_enemy_sources(value) -> String:
	if not (value is Dictionary):
		return ""

	for instance_id in value:
		var instance_id_string := String(instance_id)
		if not PROTOTYPE_ENEMY_SOURCES.has(instance_id_string):
			return "读取存档失败：world.enemies.%s 没有匹配的原型敌人来源，当前运行状态已保留。" % instance_id_string

		var entry = value[instance_id]
		if not (entry is Dictionary):
			continue

		var source: Dictionary = PROTOTYPE_ENEMY_SOURCES[instance_id_string]
		var expected_definition_id := String(source.get("definition_id", ""))
		if String(entry.get("definition_id", "")) != expected_definition_id:
			return "读取存档失败：world.enemies.%s 与原型敌人定义不一致，当前运行状态已保留。" % instance_id_string

		var expected_region_id := String(source.get("region_id", ""))
		var region_id := String(entry.get("region_id", ""))
		if not region_id.is_empty() and region_id != expected_region_id:
			return "读取存档失败：world.enemies.%s 与原型敌人区域不一致，当前运行状态已保留。" % instance_id_string

	return ""


func _validate_base_structure_sources(value) -> String:
	if not (value is Dictionary):
		return ""

	for structure_id in value:
		var structure_id_string := String(structure_id)
		if not PROTOTYPE_BASE_STRUCTURE_SOURCES.has(structure_id_string):
			return "读取存档失败：world.base_structures.%s 没有匹配的原型建筑来源，当前运行状态已保留。" % structure_id_string

		var entry = value[structure_id]
		if not (entry is Dictionary):
			continue

		var source: Dictionary = PROTOTYPE_BASE_STRUCTURE_SOURCES[structure_id_string]
		var expected_definition_id := String(source.get("definition_id", ""))
		if String(entry.get("definition_id", "")) != expected_definition_id:
			return "读取存档失败：world.base_structures.%s 与原型建筑定义不一致，当前运行状态已保留。" % structure_id_string

		var expected_site_id := String(source.get("site_instance_id", ""))
		var site_id := String(entry.get("site_instance_id", ""))
		if expected_site_id.is_empty():
			if not site_id.is_empty():
				return "读取存档失败：world.base_structures.%s 记录了不应存在的建造点来源，当前运行状态已保留。" % structure_id_string
			continue
		if site_id != expected_site_id:
			return "读取存档失败：world.base_structures.%s 与原型建筑建造点来源不一致，当前运行状态已保留。" % structure_id_string

	return ""


func _validate_base_structure_runtime_state(value, quest_state) -> String:
	if not (value is Dictionary):
		return ""

	var unlocked_effects := _get_unlocked_effects(quest_state)
	for structure_id in value:
		var entry = value[structure_id]
		if not (entry is Dictionary):
			continue

		var status := String(entry.get("status", "idle"))
		if not BASE_STRUCTURE_ALLOWED_STATUSES.has(status):
			return "读取存档失败：world.base_structures.%s 使用了无效建筑状态，当前运行状态已保留。" % String(structure_id)

		var buffer_error := _validate_structure_buffers(String(structure_id), entry)
		if not buffer_error.is_empty():
			return buffer_error

		var completed_runs = entry.get("completed_runs", 0)
		if not _is_whole_number(completed_runs) or int(completed_runs) < 0:
			return "读取存档失败：world.base_structures.%s.completed_runs 必须是非负整数，当前运行状态已保留。" % String(structure_id)

		var last_recipe_id := String(entry.get("last_recipe_id", ""))
		if not last_recipe_id.is_empty():
			var last_recipe_error := _validate_structure_recipe_ref(last_recipe_id, String(structure_id), entry, "last_recipe_id", unlocked_effects)
			if not last_recipe_error.is_empty():
				return last_recipe_error

		var active_recipe_id := String(entry.get("active_recipe_id", ""))
		var has_progress_seconds: bool = entry.has("progress_seconds")
		if status != "in_progress":
			if not active_recipe_id.is_empty():
				return "读取存档失败：world.base_structures.%s 非加工中状态不应记录 active_recipe_id，当前运行状态已保留。" % String(structure_id)
			if has_progress_seconds:
				return "读取存档失败：world.base_structures.%s 非加工中状态不应记录 progress_seconds，当前运行状态已保留。" % String(structure_id)
			continue

		if active_recipe_id.is_empty():
			return "读取存档失败：world.base_structures.%s 加工中状态缺少 active_recipe_id，当前运行状态已保留。" % String(structure_id)
		if not has_progress_seconds:
			return "读取存档失败：world.base_structures.%s 加工中状态缺少 progress_seconds，当前运行状态已保留。" % String(structure_id)
		var active_recipe_error := _validate_structure_recipe_ref(active_recipe_id, String(structure_id), entry, "active_recipe_id", unlocked_effects)
		if not active_recipe_error.is_empty():
			return active_recipe_error

		var progress_seconds = entry.get("progress_seconds", 0.0)
		if not _is_number(progress_seconds) or float(progress_seconds) < 0.0:
			return "读取存档失败：world.base_structures.%s.progress_seconds 必须是非负数字，当前运行状态已保留。" % String(structure_id)
		var active_recipe := data_registry.get_definition(active_recipe_id)
		var duration = active_recipe.get("duration", 0.0)
		if _is_number(duration) and float(duration) > 0.0 and float(progress_seconds) > float(duration):
			return "读取存档失败：world.base_structures.%s.progress_seconds 超出配方时长，当前运行状态已保留。" % String(structure_id)

	return ""


func _validate_structure_buffers(structure_id: String, entry: Dictionary) -> String:
	var definition_id := String(entry.get("definition_id", ""))
	var structure_definition := data_registry.get_definition(definition_id)
	var storage_slots = structure_definition.get("storage_slots", 0)
	for buffer_field in ["input_buffer", "output_buffer"]:
		if not entry.has(buffer_field):
			continue

		var buffer_label := "world.base_structures.%s.%s" % [structure_id, String(buffer_field)]
		var buffer = entry[buffer_field]
		if not (buffer is Dictionary):
			return "读取存档失败：%s 必须是库存缓冲对象，当前运行状态已保留。" % buffer_label
		if _is_number(storage_slots) and int(storage_slots) <= 0:
			return "读取存档失败：%s 所属建筑不应记录库存缓冲，当前运行状态已保留。" % buffer_label

		for field_name in buffer:
			var field_name_string := String(field_name)
			if not STRUCTURE_BUFFER_ALLOWED_FIELDS.has(field_name_string):
				return "读取存档失败：%s 包含不允许的字段：%s，当前运行状态已保留。" % [
					buffer_label,
					field_name_string
				]

		var inventory_error := _validate_inventory_content(buffer, buffer_label)
		if not inventory_error.is_empty():
			return inventory_error

		if buffer.has("capacity_slots") and _is_number(storage_slots) and int(buffer.get("capacity_slots", 0)) > int(storage_slots):
			return "读取存档失败：%s.capacity_slots 超出建筑储存槽位，当前运行状态已保留。" % buffer_label

	return ""


func _validate_structure_recipe_ref(
	recipe_id: String,
	structure_id: String,
	entry: Dictionary,
	field_name: String,
	unlocked_effects: Array[String]
) -> String:
	var recipe_error := _validate_definition_ref(recipe_id, "recipe.", "world.base_structures.%s.%s" % [structure_id, field_name])
	if not recipe_error.is_empty():
		return recipe_error

	var recipe := data_registry.get_definition(recipe_id)
	var required_building_id := String(recipe.get("required_building_id", ""))
	if not required_building_id.is_empty() and required_building_id != String(entry.get("definition_id", "")):
		return "读取存档失败：world.base_structures.%s.%s 与建筑定义不一致，当前运行状态已保留。" % [structure_id, field_name]
	if not _is_recipe_unlocked(recipe_id, recipe, unlocked_effects):
		return "读取存档失败：world.base_structures.%s.%s 引用了尚未解锁的配方，当前运行状态已保留。" % [structure_id, field_name]
	return ""


func _is_recipe_unlocked(recipe_id: String, recipe: Dictionary, unlocked_effects: Array[String]) -> bool:
	if unlocked_effects.has(recipe_id):
		return true

	var unlock_conditions = recipe.get("unlock_conditions", [])
	if not (unlock_conditions is Array) or unlock_conditions.is_empty():
		return true
	return false


func _validate_cross_block_content(world_data: Dictionary, character_data: Dictionary) -> String:
	var unlocked_region_ids := _get_string_array(world_data.get("unlocked_region_ids", DEFAULT_UNLOCKED_REGION_IDS), DEFAULT_UNLOCKED_REGION_IDS)
	var world_region_id := String(world_data.get("current_region_id", "region.outpost_platform"))
	var character_region_id := String(character_data.get("current_region_id", "region.outpost_platform"))
	if not unlocked_region_ids.has(world_region_id):
		return "读取存档失败：世界当前区域尚未解锁，当前运行状态已保留。"
	if not unlocked_region_ids.has(character_region_id):
		return "读取存档失败：角色当前区域尚未解锁，当前运行状态已保留。"
	if world_region_id != character_region_id:
		return "读取存档失败：世界区域与角色区域不一致，当前运行状态已保留。"

	var world_error := _validate_world_region_links(world_data, unlocked_region_ids)
	if not world_error.is_empty():
		return world_error
	var structure_error := _validate_structure_site_links(world_data)
	if not structure_error.is_empty():
		return structure_error
	var quest_error := _validate_quest_relationships(world_data.get("quest_state", {}), unlocked_region_ids)
	if not quest_error.is_empty():
		return quest_error
	return ""


func _validate_world_region_links(_world_data: Dictionary, _unlocked_region_ids: Array[String]) -> String:
	# 固定切片地图会提前记录后续区域的对象、敌人和建造点状态。
	# 当前区域仍由 _validate_cross_block_content() 校验必须已解锁。
	return ""


func _validate_structure_site_links(world_data: Dictionary) -> String:
	var map_objects = world_data.get("map_objects", {})
	var base_structures = world_data.get("base_structures", {})
	if not (map_objects is Dictionary) or not (base_structures is Dictionary):
		return ""

	for structure_id in base_structures:
		var structure = base_structures[structure_id]
		if not (structure is Dictionary):
			continue
		var site_instance_id := String(structure.get("site_instance_id", ""))
		if site_instance_id.is_empty():
			continue
		if not map_objects.has(site_instance_id):
			return "读取存档失败：world.base_structures.%s 引用了不存在的建造点，当前运行状态已保留。" % String(structure_id)
		var site = map_objects[site_instance_id]
		if not (site is Dictionary):
			return "读取存档失败：world.base_structures.%s 引用了无效建造点，当前运行状态已保留。" % String(structure_id)
		if not bool(site.get("is_built", false)):
			return "读取存档失败：world.base_structures.%s 引用了未完成建造点，当前运行状态已保留。" % String(structure_id)
		var built_definition_id := String(site.get("built_definition_id", site.get("definition_id", "")))
		if built_definition_id != String(structure.get("definition_id", "")):
			return "读取存档失败：world.base_structures.%s 与建造点定义不一致，当前运行状态已保留。" % String(structure_id)
	return ""


func _validate_quest_relationships(quest_state, unlocked_region_ids: Array[String]) -> String:
	if not (quest_state is Dictionary):
		return ""

	var active_quest_ids := _get_string_array(quest_state.get("active_quest_ids", []))
	var completed_quest_ids := _get_string_array(quest_state.get("completed_quest_ids", []))
	for quest_id in active_quest_ids:
		if completed_quest_ids.has(quest_id):
			return "读取存档失败：任务同时处于进行中和已完成状态，当前运行状态已保留。"

	for quest_id in active_quest_ids + completed_quest_ids:
		var quest := data_registry.get_definition(quest_id)
		for prerequisite_id in quest.get("prerequisites", []):
			if not completed_quest_ids.has(String(prerequisite_id)):
				return "读取存档失败：任务前置关系不完整，当前运行状态已保留。"

	for quest_id in active_quest_ids:
		if (
			not DEFAULT_ACTIVE_QUEST_IDS.has(quest_id)
			and not _is_quest_activated_by_completed_quest(quest_id, completed_quest_ids)
		):
			return "读取存档失败：quest_state.active_quest_ids 中存在未由默认任务或已完成任务链解锁的任务，当前运行状态已保留。"

	for quest_id in completed_quest_ids:
		if (
			not DEFAULT_ACTIVE_QUEST_IDS.has(quest_id)
			and not _is_quest_activated_by_completed_quest(quest_id, completed_quest_ids)
		):
			return "读取存档失败：quest_state.completed_quest_ids 中存在未由默认任务或已完成任务链解锁的任务，当前运行状态已保留。"

	var unlocked_effects := _get_string_array(quest_state.get("unlocked_effects", []))
	for effect_id in unlocked_effects:
		if effect_id.begins_with("region."):
			if not unlocked_region_ids.has(effect_id):
				return "读取存档失败：quest_state.unlocked_effects 中的区域解锁未同步到 world.unlocked_region_ids，当前运行状态已保留。"
			if not _is_default_unlocked_region(effect_id) and not _is_effect_unlocked_by_completed_quest(effect_id, completed_quest_ids):
				return "读取存档失败：quest_state.unlocked_effects 中的区域解锁缺少已完成任务 unlock_effects 来源，当前运行状态已保留。"
		if effect_id.begins_with("recipe.") and not _is_effect_unlocked_by_completed_quest(effect_id, completed_quest_ids):
			return "读取存档失败：quest_state.unlocked_effects 中的配方解锁缺少已完成任务 unlock_effects 来源，当前运行状态已保留。"
		if (
			not effect_id.begins_with("region.")
			and not effect_id.begins_with("recipe.")
			and not _is_effect_unlocked_by_completed_quest(effect_id, completed_quest_ids)
		):
			return "读取存档失败：quest_state.unlocked_effects 中的非区域 / 配方解锁缺少已完成任务 unlock_effects 来源，当前运行状态已保留。"

	for region_id in unlocked_region_ids:
		if not _is_default_unlocked_region(region_id) and not _is_effect_unlocked_by_completed_quest(region_id, completed_quest_ids):
			return "读取存档失败：world.unlocked_region_ids 中的非默认区域缺少已完成任务 unlock_effects 来源，当前运行状态已保留。"

	for quest_id in completed_quest_ids:
		var quest := data_registry.get_definition(quest_id)
		var objective_error := _validate_completed_quest_objectives(quest_id, quest, quest_state)
		if not objective_error.is_empty():
			return objective_error
		for effect_id in quest.get("unlock_effects", []):
			var id := String(effect_id)
			if not unlocked_effects.has(id):
				return "读取存档失败：quest_state.unlocked_effects 缺少已完成任务声明的解锁效果，当前运行状态已保留。"
			if id.begins_with("region.") and not unlocked_region_ids.has(id):
				return "读取存档失败：world.unlocked_region_ids 缺少已完成任务声明的区域解锁结果，当前运行状态已保留。"

	return ""


func _is_default_unlocked_region(region_id: String) -> bool:
	return DEFAULT_UNLOCKED_REGION_IDS.has(region_id)


func _is_effect_unlocked_by_completed_quest(effect_id: String, completed_quest_ids: Array[String]) -> bool:
	for quest_id in completed_quest_ids:
		var quest := data_registry.get_definition(quest_id)
		for quest_effect in quest.get("unlock_effects", []):
			if String(quest_effect) == effect_id:
				return true
	return false


func _is_quest_activated_by_completed_quest(active_quest_id: String, completed_quest_ids: Array[String]) -> bool:
	for quest_id in completed_quest_ids:
		var quest := data_registry.get_definition(quest_id)
		for next_quest_id in quest.get("next_quest_ids", []):
			if String(next_quest_id) == active_quest_id:
				return true
		for quest_effect in quest.get("unlock_effects", []):
			if String(quest_effect) == active_quest_id:
				return true
	return false


func _validate_completed_quest_objectives(quest_id: String, quest: Dictionary, quest_state: Dictionary) -> String:
	var objective_progress = quest_state.get("objective_progress", {})
	if not (objective_progress is Dictionary):
		return "读取存档失败：已完成任务缺少目标进度，当前运行状态已保留。"

	for objective in quest.get("objectives", []):
		if not (objective is Dictionary):
			continue

		var objective_type := String(objective.get("type", ""))
		var target_id := String(objective.get("target_id", ""))
		var required_amount := float(objective.get("amount", 1.0))
		var objective_key := "%s|%s|%s" % [quest_id, objective_type, target_id]
		var current_amount := float(objective_progress.get(objective_key, 0.0))
		if current_amount < required_amount:
			return "读取存档失败：已完成任务目标进度不足，当前运行状态已保留。"

	return ""


func _validate_quest_content(quest_state: Dictionary) -> String:
	var active_quest_ids := _get_string_array(quest_state.get("active_quest_ids", []))
	var completed_quest_ids := _get_string_array(quest_state.get("completed_quest_ids", []))
	for field_name in ["active_quest_ids", "completed_quest_ids"]:
		var quest_ids = quest_state.get(field_name, [])
		if not (quest_ids is Array):
			continue
		for quest_id in quest_ids:
			var quest_error := _validate_definition_ref(String(quest_id), "quest.", "quest_state.%s" % field_name)
			if not quest_error.is_empty():
				return quest_error

	var objective_progress = quest_state.get("objective_progress", {})
	if objective_progress is Dictionary:
		for objective_key in objective_progress:
			var progress = objective_progress[objective_key]
			if not _is_number(progress) or float(progress) < 0.0:
				return "读取存档失败：quest_state.objective_progress 中存在无效进度值，当前运行状态已保留。"

			var parts := String(objective_key).split("|", false)
			if parts.size() != 3:
				return "读取存档失败：quest_state.objective_progress 中存在无效目标键，当前运行状态已保留。"
			var quest_error := _validate_definition_ref(parts[0], "quest.", "quest_state.objective_progress")
			if not quest_error.is_empty():
				return quest_error
			if not active_quest_ids.has(parts[0]) and not completed_quest_ids.has(parts[0]):
				return "读取存档失败：quest_state.objective_progress 记录了未处于进行中或已完成状态的任务，当前运行状态已保留。"
			var target_error := _validate_known_or_special_ref(parts[2], "quest_state.objective_progress")
			if not target_error.is_empty():
				return target_error
			var objective_error := _validate_defined_quest_objective(parts[0], parts[1], parts[2])
			if not objective_error.is_empty():
				return objective_error
			var required_amount := _get_defined_quest_objective_amount(parts[0], parts[1], parts[2])
			if required_amount >= 0.0 and float(progress) > required_amount:
				return "读取存档失败：quest_state.objective_progress 中存在超过任务目标上限的进度值，当前运行状态已保留。"

	var unlocked_effects = quest_state.get("unlocked_effects", [])
	if unlocked_effects is Array:
		for effect_id in unlocked_effects:
			var effect_error := _validate_known_or_special_ref(String(effect_id), "quest_state.unlocked_effects")
			if not effect_error.is_empty():
				return effect_error

	return ""


func _validate_defined_quest_objective(quest_id: String, objective_type: String, target_id: String) -> String:
	var quest := data_registry.get_definition(quest_id)
	for objective in quest.get("objectives", []):
		if not (objective is Dictionary):
			continue
		if String(objective.get("type", "")) == objective_type and String(objective.get("target_id", "")) == target_id:
			return ""

	return "读取存档失败：quest_state.objective_progress 记录了任务未定义的目标，当前运行状态已保留。"


func _get_defined_quest_objective_amount(quest_id: String, objective_type: String, target_id: String) -> float:
	var quest := data_registry.get_definition(quest_id)
	for objective in quest.get("objectives", []):
		if not (objective is Dictionary):
			continue
		if String(objective.get("type", "")) == objective_type and String(objective.get("target_id", "")) == target_id:
			return float(objective.get("amount", 1.0))
	return -1.0


func _validate_inventory_content(value, label: String) -> String:
	if not (value is Dictionary):
		return ""

	var items = value.get("items", {})
	if items is Dictionary:
		for item_id in items:
			var item_error := _validate_definition_ref(String(item_id), "item.", "%s.items" % label)
			if not item_error.is_empty():
				return item_error
			var item_amount = items[item_id]
			if not _is_whole_number(item_amount) or int(item_amount) < 0:
				return "读取存档失败：%s.items 中存在无效数量，当前运行状态已保留。" % label

	var fluids = value.get("fluids", {})
	if fluids is Dictionary:
		for fluid_id in fluids:
			var fluid_error := _validate_definition_ref(String(fluid_id), "fluid.", "%s.fluids" % label)
			if not fluid_error.is_empty():
				return fluid_error
			var fluid_amount = fluids[fluid_id]
			if not _is_number(fluid_amount) or float(fluid_amount) < 0.0:
				return "读取存档失败：%s.fluids 中存在无效数量，当前运行状态已保留。" % label

	var capacity_slots = value.get("capacity_slots", 24)
	if not _is_whole_number(capacity_slots) or int(capacity_slots) < 0:
		return "读取存档失败：%s.capacity_slots 必须是非负数字，当前运行状态已保留。" % label
	return ""


func _validate_known_or_special_ref(definition_id: String, label: String) -> String:
	if definition_id == "slice_01_complete":
		return ""
	if definition_id.is_empty():
		return "读取存档失败：%s 中存在空 ID，当前运行状态已保留。" % label
	if not data_registry.has_definition(definition_id):
		return "读取存档失败：%s 引用了未知定义 ID：%s，当前运行状态已保留。" % [label, definition_id]
	return ""


func _validate_definition_ref(definition_id: String, expected_prefix: String, label: String) -> String:
	if definition_id.is_empty():
		return "读取存档失败：%s 缺少定义 ID，当前运行状态已保留。" % label
	if not definition_id.begins_with(expected_prefix):
		return "读取存档失败：%s 使用了错误类型的定义 ID：%s，当前运行状态已保留。" % [label, definition_id]
	if not data_registry.has_definition(definition_id):
		return "读取存档失败：%s 引用了未知定义 ID：%s，当前运行状态已保留。" % [label, definition_id]
	return ""


func _validate_definition_ref_any(definition_id: String, expected_prefixes: Array, label: String) -> String:
	if definition_id.is_empty():
		return "读取存档失败：%s 缺少定义 ID，当前运行状态已保留。" % label
	var has_expected_prefix := false
	for prefix in expected_prefixes:
		if definition_id.begins_with(String(prefix)):
			has_expected_prefix = true
			break
	if not has_expected_prefix:
		return "读取存档失败：%s 使用了错误类型的定义 ID：%s，当前运行状态已保留。" % [label, definition_id]
	if not data_registry.has_definition(definition_id):
		return "读取存档失败：%s 引用了未知定义 ID：%s，当前运行状态已保留。" % [label, definition_id]
	return ""


func _get_string_array(value, default_values: Array[String] = []) -> Array[String]:
	var result: Array[String] = []
	if not (value is Array):
		result.assign(default_values)
		return result
	for item in value:
		result.append(String(item))
	return result


func _get_unlocked_effects(quest_state) -> Array[String]:
	if not (quest_state is Dictionary):
		return ["region.outpost_platform"]
	return _get_string_array(quest_state.get("unlocked_effects", ["region.outpost_platform"]))


func _is_number(value) -> bool:
	return typeof(value) == TYPE_INT or typeof(value) == TYPE_FLOAT


func _is_whole_number(value) -> bool:
	return _is_number(value) and is_equal_approx(float(value), roundf(float(value)))
