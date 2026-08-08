class_name SliceSaveSchemaEightContract
extends RefCounted

## Exact schema-8 persistence contract. Runtime profiles, derived topology,
## ports, power and UI read models must remain outside this payload.

const ROOT_KEYS := [
	"buildings", "core_energy", "core_repaired", "core_storage",
	"field_encounter", "game_version", "harvested_clusters",
	"next_building_serial", "player_health", "player_x", "player_y",
	"pocket", "save_schema_version", "updated_at",
]
const FIXED_BUILDING_IDS := [
	SliceBuildingCatalog.FLOOR_ID,
	SliceBuildingCatalog.COLLECTOR_ID,
	SliceBuildingCatalog.REACTOR_ID,
	SliceBuildingCatalog.POWER_RELAY_ID,
	SliceBuildingCatalog.STORAGE_ID,
]
const KNOWN_ITEM_IDS := [
	"crystal", "catalyst", "part",
	SliceBuildingCatalog.FLOOR_ID,
	SliceBuildingCatalog.COLLECTOR_ID,
	SliceBuildingCatalog.REACTOR_ID,
	SliceBuildingCatalog.POWER_RELAY_ID,
	SliceBuildingCatalog.CONVEYOR_ID,
	SliceBuildingCatalog.STORAGE_ID,
]
const FORBIDDEN_KEYS := [
	"accepted_item_ids", "capacity", "category", "connection_cell",
	"connections", "container_profile", "display_name", "endpoints",
	"graph_edges", "icon_path", "icon_region", "inventory_profile",
	"item_definitions", "logic_power_probe_cell",
	"logic_power_probe_policy", "logistics_ports", "neighbors",
	"orientation_mode", "orientation_policy", "outward_direction",
	"output_item_order", "port_cell", "power_parent_id",
	"power_visual_anchor_offset", "power_visual_anchor_policy", "powered",
	"profile_id", "read_model", "short_name", "slots", "sort_order",
	"source_phase", "transportable", "visual_mode",
]


static func validate(data: Dictionary) -> Array[String]:
	var failures: Array[String] = []
	_expect_exact_keys(data, ROOT_KEYS, "root", failures)
	_expect_equal(
		int(data.get("save_schema_version", 0)), 8, "schema version", failures
	)
	_expect_equal(
		String(data.get("game_version", "")),
		"prototype-slice-08",
		"game version",
		failures
	)
	_validate_inventory(data.get("pocket", null), 200, [], "pocket", failures)
	_validate_inventory(
		data.get("core_storage", null), 99999, [], "core storage", failures
	)
	_expect_exact_keys(
		data.get("field_encounter", null),
		["enemy_health", "state"],
		"field encounter",
		failures
	)
	_validate_buildings(data.get("buildings", null), failures)
	var forbidden_paths := _forbidden_paths(data, "$")
	if not forbidden_paths.is_empty():
		failures.append(
			"contains runtime/capacity fields: %s"
			% ", ".join(forbidden_paths)
		)
	return failures


static func _validate_buildings(value, failures: Array[String]) -> void:
	if not (value is Array):
		failures.append("buildings must be an array")
		return
	for index in range(value.size()):
		var raw_entry = value[index]
		var label := "buildings[%d]" % index
		if not (raw_entry is Dictionary):
			failures.append("%s must be an object" % label)
			continue
		var entry: Dictionary = raw_entry
		_expect_exact_keys(
			entry,
			["building_id", "instance_id", "origin_cell", "rotation", "state"],
			label,
			failures
		)
		var building_id := String(entry.get("building_id", ""))
		if FIXED_BUILDING_IDS.has(building_id):
			_expect_equal(
				int(entry.get("rotation", -1)), 0, "%s rotation" % label, failures
			)
		elif building_id == SliceBuildingCatalog.CONVEYOR_ID:
			var rotation := int(entry.get("rotation", -1))
			if rotation < 0 or rotation > 3:
				failures.append("%s conveyor rotation is outside 0..3" % label)
		else:
			failures.append("%s has unknown building id %s" % [label, building_id])
		_validate_state(
			building_id, entry.get("state", null), "%s state" % label, failures
		)


static func _validate_state(
	building_id: String,
	value,
	label: String,
	failures: Array[String]
) -> void:
	match building_id:
		SliceBuildingCatalog.FLOOR_ID, SliceBuildingCatalog.POWER_RELAY_ID:
			_expect_exact_keys(value, [], label, failures)
		SliceBuildingCatalog.COLLECTOR_ID:
			_expect_exact_keys(
				value, ["buffer", "production_progress"], label, failures
			)
		SliceBuildingCatalog.REACTOR_ID:
			_expect_exact_keys(
				value,
				[
					"input_inventory", "output_inventory", "processing",
					"production_progress",
				],
				label,
				failures
			)
			if value is Dictionary:
				_validate_inventory(
					value.get("input_inventory", null),
					2,
					["crystal"],
					"%s input" % label,
					failures
				)
				_validate_inventory(
					value.get("output_inventory", null),
					1,
					["catalyst"],
					"%s output" % label,
					failures
				)
		SliceBuildingCatalog.CONVEYOR_ID:
			_expect_exact_keys(value, ["cargo", "merge_cursor"], label, failures)
			if value is Dictionary:
				var cargo = value.get("cargo", null)
				if cargo is Dictionary and not cargo.is_empty():
					_expect_exact_keys(
						cargo, ["item_id", "progress"], "%s cargo" % label, failures
					)
		SliceBuildingCatalog.STORAGE_ID:
			_expect_exact_keys(
				value,
				[
					"inventory", "mode", "output_item_id", "transfer_cursor",
					"transfer_progress",
				],
				label,
				failures
			)
			if value is Dictionary:
				_validate_inventory(
					value.get("inventory", null),
					200,
					KNOWN_ITEM_IDS,
					"%s inventory" % label,
					failures
				)


static func _validate_inventory(
	value,
	per_item_capacity: int,
	allowed_item_ids: Array,
	label: String,
	failures: Array[String]
) -> void:
	_expect_exact_keys(value, ["contents"], label, failures)
	if not (value is Dictionary):
		return
	var contents = value.get("contents", null)
	if not (contents is Dictionary):
		failures.append("%s contents must be an object" % label)
		return
	for item_id in contents:
		if not (item_id is String) or String(item_id).is_empty():
			failures.append("%s has an invalid item id" % label)
			continue
		if not allowed_item_ids.is_empty() and not allowed_item_ids.has(item_id):
			failures.append("%s has unknown item %s" % [label, item_id])
		var amount = contents[item_id]
		if (
			not (amount is int or amount is float)
			or not is_equal_approx(float(amount), float(int(amount)))
			or int(amount) <= 0
			or int(amount) > per_item_capacity
		):
			failures.append("%s has invalid amount for %s" % [label, item_id])


static func _expect_exact_keys(
	value,
	expected_keys: Array,
	label: String,
	failures: Array[String]
) -> void:
	if not (value is Dictionary):
		failures.append("%s must be an object" % label)
		return
	var actual := _sorted_strings(value.keys())
	var expected := _sorted_strings(expected_keys)
	if actual != expected:
		failures.append("%s expected keys %s, got %s" % [label, expected, actual])


static func _expect_equal(
	actual,
	expected,
	label: String,
	failures: Array[String]
) -> void:
	if actual != expected:
		failures.append("%s expected %s, got %s" % [label, expected, actual])


static func _forbidden_paths(value, path: String) -> Array[String]:
	var result: Array[String] = []
	if value is Dictionary:
		for key in value:
			var key_text := String(key)
			var child_path := "%s.%s" % [path, key_text]
			if FORBIDDEN_KEYS.has(key_text):
				result.append(child_path)
			result.append_array(_forbidden_paths(value[key], child_path))
	elif value is Array:
		for index in range(value.size()):
			result.append_array(
				_forbidden_paths(value[index], "%s[%d]" % [path, index])
			)
	return result


static func _sorted_strings(values: Array) -> Array[String]:
	var result: Array[String] = []
	for value in values:
		result.append(String(value))
	result.sort()
	return result
