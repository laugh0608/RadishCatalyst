class_name SliceSaveSchemaSevenContract
extends RefCounted

## Exact schema-7 payload contract shared by save checks. Runtime-only item,
## inventory, endpoint and power descriptors must never cross this boundary.

const POCKET_CAPACITY := 30
const CORE_STORAGE_CAPACITY := 120
const STORAGE_CAPACITY := 20
const REACTOR_INPUT_CAPACITY := 2
const REACTOR_OUTPUT_CAPACITY := 1

const ROOT_KEYS := [
	"buildings", "core_energy", "core_repaired", "core_storage",
	"field_encounter", "game_version", "harvested_clusters",
	"next_building_serial", "player_health", "player_x", "player_y",
	"pocket", "save_schema_version", "updated_at",
]
const BUILDING_IDS := [
	SliceBuildingCatalog.FLOOR_ID, SliceBuildingCatalog.COLLECTOR_ID,
	SliceBuildingCatalog.REACTOR_ID, SliceBuildingCatalog.POWER_RELAY_ID,
	SliceBuildingCatalog.CONVEYOR_ID, SliceBuildingCatalog.STORAGE_ID,
]
const FORBIDDEN_KEYS := [
	"accepted_item_ids", "category", "connection_cell", "connections",
	"container_profile", "display_name", "endpoints", "graph_edges",
	"icon_path", "icon_region", "inventory_profile", "item_definitions",
	"logic_power_probe_cell", "logic_power_probe_policy", "logistics_ports",
	"mode", "neighbors", "orientation_mode", "orientation_policy",
	"outward_direction", "output_item_id", "output_item_order", "port_cell",
	"power_parent_id", "power_visual_anchor_offset",
	"power_visual_anchor_policy", "powered", "profile_id", "read_model",
	"short_name", "slots", "sort_order", "source_phase", "transfer_cursor",
	"transfer_progress", "transportable", "visual_mode",
]


static func validate(data: Dictionary) -> Array[String]:
	var failures: Array[String] = []
	_expect_exact_keys(data, ROOT_KEYS, "root keys", failures)
	_expect_equal(
		int(data.get("save_schema_version", 0)), 7, "schema version", failures
	)
	_expect_equal(
		String(data.get("game_version", "")),
		"prototype-slice-07",
		"game version",
		failures
	)
	_expect_inventory(
		data.get("pocket", null),
		POCKET_CAPACITY,
		"pocket",
		failures
	)
	_expect_inventory(
		data.get("core_storage", null),
		CORE_STORAGE_CAPACITY,
		"core storage",
		failures
	)
	_expect_exact_keys(
		data.get("field_encounter", null),
		["enemy_health", "state"],
		"field encounter",
		failures
	)
	var forbidden_paths := _forbidden_paths(data, "$")
	if not forbidden_paths.is_empty():
		failures.append(
			"contains schema 8/runtime-only fields: %s"
			% ", ".join(forbidden_paths)
		)
	_validate_buildings(data.get("buildings", null), failures)
	return failures


static func _validate_buildings(
	value,
	failures: Array[String]
) -> void:
	if not (value is Array):
		failures.append("buildings: expected an array, got %s" % value)
		return
	var buildings: Array = value
	var seen_building_ids := {}
	for index in range(buildings.size()):
		var raw_entry = buildings[index]
		var entry_label := "buildings[%d]" % index
		if not (raw_entry is Dictionary):
			failures.append("%s: expected an object, got %s" % [entry_label, raw_entry])
			continue
		var entry: Dictionary = raw_entry
		_expect_exact_keys(
			entry,
			["building_id", "instance_id", "origin_cell", "rotation", "state"],
			entry_label,
			failures
		)
		var building_id := String(entry.get("building_id", ""))
		seen_building_ids[building_id] = true
		_validate_building_state(
			building_id,
			entry.get("state", null),
			"%s state" % entry_label,
			failures
		)
	_expect_equal(
		_sorted_strings(seen_building_ids.keys()),
		_sorted_strings(BUILDING_IDS),
		"building state coverage",
		failures
	)


static func _validate_building_state(
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
				_expect_inventory(
					value.get("input_inventory", null),
					REACTOR_INPUT_CAPACITY,
					"%s input inventory" % label,
					failures
				)
				_expect_inventory(
					value.get("output_inventory", null),
					REACTOR_OUTPUT_CAPACITY,
					"%s output inventory" % label,
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
			_expect_exact_keys(value, ["inventory"], label, failures)
			if value is Dictionary:
				_expect_inventory(
					value.get("inventory", null),
					STORAGE_CAPACITY,
					"%s inventory" % label,
					failures
				)


static func _expect_inventory(
	value,
	expected_capacity: int,
	label: String,
	failures: Array[String]
) -> void:
	_expect_exact_keys(value, ["capacity", "contents"], "%s keys" % label, failures)
	if not (value is Dictionary):
		return
	_expect_equal(
		int(value.get("capacity", -1)),
		expected_capacity,
		"%s capacity" % label,
		failures
	)
	_expect_equal(
		value.get("contents", null) is Dictionary,
		true,
		"%s contents" % label,
		failures
	)


static func _expect_exact_keys(
	value,
	expected_keys: Array,
	label: String,
	failures: Array[String]
) -> void:
	if not (value is Dictionary):
		failures.append("%s: expected an object, got %s" % [label, value])
		return
	var actual := _sorted_strings(value.keys())
	var expected := _sorted_strings(expected_keys)
	if actual != expected:
		failures.append(
			"%s: expected keys %s, got %s" % [label, expected, actual]
		)


static func _expect_equal(
	actual,
	expected,
	label: String,
	failures: Array[String]
) -> void:
	if actual != expected:
		failures.append("%s: expected %s, got %s" % [label, expected, actual])


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
