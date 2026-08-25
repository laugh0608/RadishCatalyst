class_name SliceBuildingSaveCodec
extends RefCounted

## Versioned building serialization, migration and validation. Schema 2–7
## validation is deliberately frozen here instead of consulting the live
## building catalog: package-level direction, port and state changes must not
## retroactively redefine an old save. Runtime power / logistics adjacency is
## absent from every schema.

const MAP_SIZE_CELLS := Vector2i(80, 24)
const INSTANCE_ID_PREFIX := "building-"
# Schema 4–7 saves may contain elapsed collector progress from the former
# ten-second cycle. Keep accepting that range; SliceWorld clamps it to the
# current cycle and settles completed progress on the next production tick.
const MAX_COMPATIBLE_COLLECTOR_PROGRESS := 10.0
const STORAGE_TRANSFER_INTERVAL := 5.0
const LEGACY_STORAGE_CAPACITY := 20
const REACTOR_INPUT_CAPACITY := 2
const REACTOR_OUTPUT_CAPACITY := 1
const REACTOR_PROCESS_DURATION := 10.0
const REACTOR_INPUT_ITEM_ID := "crystal"
const REACTOR_OUTPUT_ITEM_ID := "catalyst"
const TRANSPORT_ITEM_IDS := ["crystal", "catalyst"]
const STORAGE_ITEM_IDS := [
	"crystal",
	"catalyst",
	"part",
	SliceBuildingCatalog.FLOOR_ID,
	SliceBuildingCatalog.COLLECTOR_ID,
	SliceBuildingCatalog.REACTOR_ID,
	SliceBuildingCatalog.POWER_RELAY_ID,
	SliceBuildingCatalog.CONVEYOR_ID,
	SliceBuildingCatalog.STORAGE_ID,
]
const LEGACY_STATE_KEYS := {
	SliceBuildingCatalog.FLOOR_ID: [],
	SliceBuildingCatalog.COLLECTOR_ID: ["buffer", "production_progress"],
	SliceBuildingCatalog.REACTOR_ID: [
		"input_inventory", "output_inventory", "processing",
		"production_progress",
	],
	SliceBuildingCatalog.POWER_RELAY_ID: [],
	SliceBuildingCatalog.CONVEYOR_ID: ["cargo", "merge_cursor"],
	SliceBuildingCatalog.STORAGE_ID: ["inventory"],
}
const SCHEMA_EIGHT_STATE_KEYS := {
	SliceBuildingCatalog.FLOOR_ID: [],
	SliceBuildingCatalog.COLLECTOR_ID: ["buffer", "production_progress"],
	SliceBuildingCatalog.REACTOR_ID: [
		"input_inventory", "output_inventory", "processing",
		"production_progress",
	],
	SliceBuildingCatalog.POWER_RELAY_ID: [],
	SliceBuildingCatalog.CONVEYOR_ID: ["cargo", "merge_cursor"],
	SliceBuildingCatalog.STORAGE_ID: [
		"inventory", "mode", "output_item_id", "transfer_cursor",
		"transfer_progress",
	],
}
const FROZEN_FOOTPRINTS := {
	SliceBuildingCatalog.FLOOR_ID: Vector2i.ONE,
	SliceBuildingCatalog.COLLECTOR_ID: Vector2i(2, 2),
	SliceBuildingCatalog.REACTOR_ID: Vector2i(3, 3),
	SliceBuildingCatalog.POWER_RELAY_ID: Vector2i.ONE,
	SliceBuildingCatalog.CONVEYOR_ID: Vector2i.ONE,
	SliceBuildingCatalog.STORAGE_ID: Vector2i(2, 2),
}
const FROZEN_SURFACE_RULES := {
	SliceBuildingCatalog.FLOOR_ID:
		SliceBuildingDefinition.SURFACE_BUILDABLE_ROCK,
	SliceBuildingCatalog.COLLECTOR_ID:
		SliceBuildingDefinition.SURFACE_CRYSTAL,
	SliceBuildingCatalog.REACTOR_ID:
		SliceBuildingDefinition.SURFACE_INDUSTRIAL_FLOOR,
	SliceBuildingCatalog.POWER_RELAY_ID:
		SliceBuildingDefinition.SURFACE_INDUSTRIAL_FLOOR,
	SliceBuildingCatalog.CONVEYOR_ID:
		SliceBuildingDefinition.SURFACE_INDUSTRIAL_FLOOR,
	SliceBuildingCatalog.STORAGE_ID:
		SliceBuildingDefinition.SURFACE_INDUSTRIAL_FLOOR,
}
const FIXED_SCHEMA_EIGHT_BUILDING_IDS := [
	SliceBuildingCatalog.FLOOR_ID,
	SliceBuildingCatalog.COLLECTOR_ID,
	SliceBuildingCatalog.REACTOR_ID,
	SliceBuildingCatalog.POWER_RELAY_ID,
	SliceBuildingCatalog.STORAGE_ID,
]


static func serialize_instances(
	instances: Array[SliceBuildingInstance]
) -> Array:
	var result: Array = []
	for instance in instances:
		result.append({
			"instance_id": instance.instance_id,
			"building_id": instance.building_id,
			"origin_cell": [instance.origin_cell.x, instance.origin_cell.y],
			"rotation": instance.building_rotation,
			"state": instance.state_dict(instance.definition.state_keys),
		})
	return result


static func validate_schema_five(raw_buildings, raw_next_serial) -> Dictionary:
	return _validate_buildings(raw_buildings, raw_next_serial, false, false)


static func _validate_buildings(
	raw_buildings,
	raw_next_serial,
	schema_eight: bool,
	require_schema_six_reactor_state: bool
) -> Dictionary:
	if not (raw_buildings is Array):
		return _failure("buildings 必须是数组")
	if not _is_integer(raw_next_serial) or int(raw_next_serial) < 1:
		return _failure("next_building_serial 必须是正整数")

	var buildings: Array = []
	var ids := {}
	var floor_cells := {}
	var blocking_cells := {}
	var max_serial := 0
	for index in range(raw_buildings.size()):
		if require_schema_six_reactor_state:
			var raw_entry = raw_buildings[index]
			if (
				raw_entry is Dictionary
				and raw_entry.get("building_id", "")
				== SliceBuildingCatalog.REACTOR_ID
			):
				var raw_state = raw_entry.get("state", null)
				if raw_state is Dictionary:
					for key in LEGACY_STATE_KEYS[
						SliceBuildingCatalog.REACTOR_ID
					]:
						if not raw_state.has(key):
							return _failure(
								"buildings[%d].state 缺少字段 %s"
								% [index, key]
							)
		var entry_result := _validate_entry(
			raw_buildings[index], index, schema_eight
		)
		if not bool(entry_result.get("success", false)):
			return entry_result
		var entry: Dictionary = entry_result["data"]
		var instance_id := String(entry["instance_id"])
		if ids.has(instance_id):
			return _failure("buildings 存在重复实例 ID：%s" % instance_id)
		ids[instance_id] = true
		max_serial = maxi(max_serial, _serial_from_instance_id(instance_id))

		var building_id := String(entry["building_id"])
		var origin_raw: Array = entry["origin_cell"]
		var origin := Vector2i(int(origin_raw[0]), int(origin_raw[1]))
		var rotation := int(entry["rotation"])
		var target_cells := (
			floor_cells if _is_floor(building_id) else blocking_cells
		)
		for cell in _occupied_cells(
			building_id, origin, rotation, schema_eight
		):
			if not _cell_in_bounds(cell):
				return _failure("%s 的占用格越出地图边界" % instance_id)
			var key := _cell_key(cell)
			if target_cells.has(key):
				return _failure(
					"%s 与 %s 的建筑占用重叠"
					% [instance_id, String(target_cells[key])]
				)
			target_cells[key] = instance_id
		buildings.append(entry)

	for entry in buildings:
		var building_id := String(entry["building_id"])
		if (
			String(FROZEN_SURFACE_RULES[building_id])
			!= SliceBuildingDefinition.SURFACE_INDUSTRIAL_FLOOR
		):
			continue
		var origin_raw: Array = entry["origin_cell"]
		var origin := Vector2i(int(origin_raw[0]), int(origin_raw[1]))
		for cell in _occupied_cells(
			building_id, origin, int(entry["rotation"]), schema_eight
		):
			if not floor_cells.has(_cell_key(cell)):
				return _failure(
					"%s 缺少完整工业地板支撑" % String(entry["instance_id"])
				)
	var next_serial := int(raw_next_serial)
	if next_serial <= max_serial:
		return _failure(
			"next_building_serial 必须大于现有最大实例序号 %d" % max_serial
		)
	return _success({
		"buildings": buildings,
		"next_building_serial": next_serial,
	})


static func validate_schema_six(raw_buildings, raw_next_serial) -> Dictionary:
	return validate_schema_seven(raw_buildings, raw_next_serial)


static func validate_schema_seven(
	raw_buildings,
	raw_next_serial
) -> Dictionary:
	return _validate_buildings(raw_buildings, raw_next_serial, false, true)


static func validate_schema_eight(
	raw_buildings,
	raw_next_serial
) -> Dictionary:
	return _validate_buildings(raw_buildings, raw_next_serial, true, true)


static func migrate_schema_five(raw_buildings, raw_next_serial) -> Dictionary:
	if raw_buildings is Array:
		for index in range(raw_buildings.size()):
			var raw_entry = raw_buildings[index]
			if (
				raw_entry is Dictionary
				and raw_entry.get("building_id", "")
				== SliceBuildingCatalog.REACTOR_ID
			):
				var state = raw_entry.get("state", null)
				if not (state is Dictionary) or not state.is_empty():
					return _failure(
						"schema 5 buildings[%d].state 反应器状态必须为空"
						% index
					)
	var old_result := validate_schema_five(raw_buildings, raw_next_serial)
	if not bool(old_result.get("success", false)):
		return old_result
	var migrated: Dictionary = (old_result["data"] as Dictionary).duplicate(true)
	for entry in migrated["buildings"]:
		if entry["building_id"] == SliceBuildingCatalog.REACTOR_ID:
			entry["state"] = {
				"input_inventory": {
					"capacity": REACTOR_INPUT_CAPACITY,
					"contents": {},
				},
				"output_inventory": {
					"capacity": REACTOR_OUTPUT_CAPACITY,
					"contents": {},
				},
				"processing": false,
				"production_progress": 0.0,
			}
	return validate_schema_six(
		migrated["buildings"], migrated["next_building_serial"]
	)


## Kept as a source-compatible alias for the L3 checks. Schema-4 payloads use
## the same topology and simply omit the new conveyor state.
static func validate_schema_four(raw_buildings, raw_next_serial) -> Dictionary:
	return validate_schema_five(raw_buildings, raw_next_serial)


static func migrate_schema_seven_to_eight(
	raw_buildings,
	raw_next_serial
) -> Dictionary:
	var legacy_result := validate_schema_seven(
		raw_buildings, raw_next_serial
	)
	if not bool(legacy_result.get("success", false)):
		return legacy_result
	var migrated: Dictionary = (
		legacy_result["data"] as Dictionary
	).duplicate(true)
	for entry in migrated["buildings"]:
		var building_id := String(entry["building_id"])
		if FIXED_SCHEMA_EIGHT_BUILDING_IDS.has(building_id):
			entry["rotation"] = 0
		var state: Dictionary = entry["state"]
		if building_id == SliceBuildingCatalog.STORAGE_ID:
			var inventory := _without_legacy_capacity(
				state.get("inventory", {})
			)
			state = {
				"inventory": inventory,
				"mode": "supply",
				"output_item_id": _first_transportable_item(
					inventory["contents"]
				),
				"transfer_cursor": 0,
				"transfer_progress": 0.0,
			}
		elif building_id == SliceBuildingCatalog.REACTOR_ID:
			state["input_inventory"] = _without_legacy_capacity(
				state["input_inventory"]
			)
			state["output_inventory"] = _without_legacy_capacity(
				state["output_inventory"]
			)
		elif building_id == SliceBuildingCatalog.COLLECTOR_ID:
			state = {
				"buffer": int(state.get("buffer", 0)),
				"production_progress": float(
					state.get("production_progress", 0.0)
				),
			}
		elif building_id == SliceBuildingCatalog.CONVEYOR_ID:
			var cargo = state.get("cargo", {})
			state = {
				"cargo": (
					cargo.duplicate(true) if cargo is Dictionary else {}
				),
				"merge_cursor": int(state.get("merge_cursor", 0)),
			}
		else:
			state = {}
		entry["state"] = state
	return validate_schema_eight(
		migrated["buildings"], migrated["next_building_serial"]
	)


static func migrate_legacy_collectors(raw_collectors) -> Dictionary:
	if not (raw_collectors is Array):
		return _failure("collectors 必须是数组")
	var buildings: Array = []
	var occupied := {}
	for index in range(raw_collectors.size()):
		var raw_entry = raw_collectors[index]
		if not (raw_entry is Dictionary):
			return _failure("collectors[%d] 必须是对象" % index)
		var raw_cell = raw_entry.get("cell", null)
		if (
			not (raw_cell is Array)
			or raw_cell.size() != 2
			or not _is_integer(raw_cell[0])
			or not _is_integer(raw_cell[1])
		):
			return _failure("collectors[%d].cell 必须是两个整数" % index)
		var buffer_value = raw_entry.get("buffer", 0)
		if (
			not _is_integer(buffer_value)
			or int(buffer_value) < 0
			or int(buffer_value) > SliceCollector.BUFFER_CAP
		):
			return _failure("collectors[%d].buffer 超出有效范围" % index)
		var origin := Vector2i(int(raw_cell[0]), int(raw_cell[1]))
		for cell in _occupied_cells(
			SliceBuildingCatalog.COLLECTOR_ID, origin, 0, false
		):
			if not _cell_in_bounds(cell):
				return _failure("collectors[%d] 越出地图边界" % index)
			var key := _cell_key(cell)
			if occupied.has(key):
				return _failure("collectors 中存在重叠采集器")
			occupied[key] = true
		buildings.append({
			"instance_id": "%s%06d" % [INSTANCE_ID_PREFIX, index + 1],
			"building_id": SliceBuildingCatalog.COLLECTOR_ID,
			"origin_cell": [origin.x, origin.y],
			"rotation": 0,
			"state": {
				"buffer": int(buffer_value),
				"production_progress": 0.0,
			},
		})
	return _success({
		"buildings": buildings,
		"next_building_serial": buildings.size() + 1,
	})


static func add_legacy_carried_collector(pocket: Dictionary) -> Dictionary:
	var migrated := pocket.duplicate(true)
	var contents = migrated.get("contents", {})
	if not (contents is Dictionary):
		contents = {}
	else:
		contents = contents.duplicate()
	contents[SliceBuildingCatalog.COLLECTOR_ID] = (
		int(contents.get(SliceBuildingCatalog.COLLECTOR_ID, 0)) + 1
	)
	migrated["contents"] = contents
	return migrated


static func ordered_for_restore(buildings: Array) -> Array:
	var ordered: Array = []
	for entry in buildings:
		var definition := SliceBuildingCatalog.find(String(entry["building_id"]))
		if definition != null and definition.is_floor:
			ordered.append(entry)
	for entry in buildings:
		var definition := SliceBuildingCatalog.find(String(entry["building_id"]))
		if definition != null and not definition.is_floor:
			ordered.append(entry)
	return ordered


static func _validate_entry(
	raw_entry,
	index: int,
	schema_eight: bool
) -> Dictionary:
	if not (raw_entry is Dictionary):
		return _failure("buildings[%d] 必须是对象" % index)
	var required_keys := [
		"instance_id", "building_id", "origin_cell", "rotation", "state",
	]
	for key in required_keys:
		if not raw_entry.has(key):
			return _failure("buildings[%d] 缺少字段 %s" % [index, key])
	for key in raw_entry:
		if not required_keys.has(String(key)):
			return _failure("buildings[%d] 包含未知字段 %s" % [index, key])

	var instance_id_value = raw_entry["instance_id"]
	if not (instance_id_value is String):
		return _failure("buildings[%d].instance_id 必须是字符串" % index)
	var instance_id := String(instance_id_value)
	if _serial_from_instance_id(instance_id) <= 0:
		return _failure("buildings[%d].instance_id 格式无效" % index)

	var building_id_value = raw_entry["building_id"]
	if not (building_id_value is String):
		return _failure("buildings[%d].building_id 必须是字符串" % index)
	var building_id := String(building_id_value)
	if not FROZEN_FOOTPRINTS.has(building_id):
		return _failure("buildings[%d] 使用未知建筑 %s" % [index, building_id])

	var raw_origin = raw_entry["origin_cell"]
	if (
		not (raw_origin is Array)
		or raw_origin.size() != 2
		or not _is_integer(raw_origin[0])
		or not _is_integer(raw_origin[1])
	):
		return _failure("buildings[%d].origin_cell 必须是两个整数" % index)
	var raw_rotation = raw_entry["rotation"]
	if (
		not _is_integer(raw_rotation)
		or int(raw_rotation) < 0
		or int(raw_rotation) > 3
	):
		return _failure("buildings[%d].rotation 必须是 0–3" % index)
	if (
		schema_eight
		and FIXED_SCHEMA_EIGHT_BUILDING_IDS.has(building_id)
		and int(raw_rotation) != 0
	):
		return _failure(
			"buildings[%d].rotation 固定设施必须为 0" % index
		)
	var raw_state = raw_entry["state"]
	if not (raw_state is Dictionary):
		return _failure("buildings[%d].state 必须是对象" % index)
	var state_result := _validate_state(
		building_id, raw_state, index, schema_eight
	)
	if not bool(state_result.get("success", false)):
		return state_result

	return _success({
		"instance_id": instance_id,
		"building_id": building_id,
		"origin_cell": [int(raw_origin[0]), int(raw_origin[1])],
		"rotation": int(raw_rotation),
		"state": (state_result["data"] as Dictionary).duplicate(true),
	})


static func _validate_state(
	building_id: String,
	raw_state: Dictionary,
	index: int,
	schema_eight: bool
) -> Dictionary:
	var allowed_keys: Array = (
		SCHEMA_EIGHT_STATE_KEYS[building_id]
		if schema_eight
		else LEGACY_STATE_KEYS[building_id]
	)
	for key in raw_state:
		if not allowed_keys.has(String(key)):
			return _failure(
				"buildings[%d].state 包含 %s 不允许的字段 %s"
				% [index, building_id, key]
			)
	if schema_eight:
		for key in allowed_keys:
			if not raw_state.has(key):
				return _failure(
					"buildings[%d].state 缺少字段 %s" % [index, key]
				)
	if building_id == SliceBuildingCatalog.COLLECTOR_ID:
		var buffer_value = raw_state.get("buffer", 0)
		if (
			not _is_integer(buffer_value)
			or int(buffer_value) < 0
			or int(buffer_value) > SliceCollector.BUFFER_CAP
		):
			return _failure("buildings[%d].state.buffer 超出有效范围" % index)
		var progress_value = raw_state.get("production_progress", 0.0)
		if (
			not (progress_value is float or progress_value is int)
			or not is_finite(float(progress_value))
			or float(progress_value) < 0.0
			or float(progress_value) >= MAX_COMPATIBLE_COLLECTOR_PROGRESS
		):
			return _failure(
				"buildings[%d].state.production_progress 超出有效范围" % index
			)
	elif building_id == SliceBuildingCatalog.STORAGE_ID:
		var storage_result: Dictionary = (
			_validate_schema_eight_storage_state(raw_state, index)
			if schema_eight
			else _validate_storage_inventory(
				raw_state.get("inventory", {}), index
			)
		)
		if not bool(storage_result.get("success", false)):
			return storage_result
	elif building_id == SliceBuildingCatalog.CONVEYOR_ID:
		var conveyor_result := _validate_conveyor_state(raw_state, index)
		if not bool(conveyor_result.get("success", false)):
			return conveyor_result
	elif building_id == SliceBuildingCatalog.REACTOR_ID:
		var reactor_result := _validate_reactor_state(
			raw_state, index, schema_eight
		)
		if not bool(reactor_result.get("success", false)):
			return reactor_result
	return _success(raw_state)


static func _validate_reactor_state(
	raw_state: Dictionary,
	index: int,
	schema_eight: bool
) -> Dictionary:
	var input_result := _validate_reactor_inventory(
		raw_state.get(
			"input_inventory",
			({"contents": {}} if schema_eight else {
				"capacity": REACTOR_INPUT_CAPACITY,
				"contents": {},
			})
		),
		index,
		"input_inventory",
		REACTOR_INPUT_CAPACITY,
		REACTOR_INPUT_ITEM_ID,
		schema_eight
	)
	if not bool(input_result.get("success", false)):
		return input_result
	var output_result := _validate_reactor_inventory(
		raw_state.get(
			"output_inventory",
			({"contents": {}} if schema_eight else {
				"capacity": REACTOR_OUTPUT_CAPACITY,
				"contents": {},
			})
		),
		index,
		"output_inventory",
		REACTOR_OUTPUT_CAPACITY,
		REACTOR_OUTPUT_ITEM_ID,
		schema_eight
	)
	if not bool(output_result.get("success", false)):
		return output_result

	var processing_value = raw_state.get("processing", false)
	if not (processing_value is bool):
		return _failure(
			"buildings[%d].state.processing 必须是布尔值" % index
		)
	var progress_value = raw_state.get("production_progress", 0.0)
	if (
		not (progress_value is float or progress_value is int)
		or not is_finite(float(progress_value))
		or float(progress_value) < 0.0
		or float(progress_value) >= REACTOR_PROCESS_DURATION
	):
		return _failure(
			"buildings[%d].state.production_progress 超出有效范围" % index
		)
	if not bool(processing_value) and not is_zero_approx(float(progress_value)):
		return _failure(
			"buildings[%d] 的空闲反应器不能保留生产进度" % index
		)
	var output_inventory: Dictionary = output_result["data"]
	var output_contents: Dictionary = output_inventory["contents"]
	if bool(processing_value) and not output_contents.is_empty():
		return _failure(
			"buildings[%d] 的生产中反应器输出必须为空" % index
		)
	return _success(raw_state)


static func _validate_reactor_inventory(
	raw_inventory,
	index: int,
	field_name: String,
	expected_capacity: int,
	allowed_item_id: String,
	schema_eight: bool
) -> Dictionary:
	if not (raw_inventory is Dictionary):
		return _failure(
			"buildings[%d].state.%s 必须是对象" % [index, field_name]
		)
	var required_keys := (
		["contents"] if schema_eight else ["capacity", "contents"]
	)
	for key in raw_inventory:
		if not required_keys.has(String(key)):
			return _failure(
				"buildings[%d].state.%s 包含未知字段 %s"
				% [index, field_name, key]
			)
	for key in required_keys:
		if not raw_inventory.has(key):
			return _failure(
				"buildings[%d].state.%s 缺少字段 %s"
				% [index, field_name, key]
			)
	if not schema_eight:
		var capacity_value = raw_inventory["capacity"]
		if (
			not _is_integer(capacity_value)
			or int(capacity_value) != expected_capacity
		):
			return _failure(
				"buildings[%d].state.%s.capacity 无效"
				% [index, field_name]
			)
	var contents = raw_inventory["contents"]
	if not (contents is Dictionary):
		return _failure(
			"buildings[%d].state.%s.contents 必须是对象"
			% [index, field_name]
		)
	var total := 0
	for item_id in contents:
		if not (item_id is String) or String(item_id) != allowed_item_id:
			return _failure(
				"buildings[%d].state.%s 包含未知物品 %s"
				% [index, field_name, item_id]
			)
		var amount = contents[item_id]
		if not _is_integer(amount) or int(amount) <= 0:
			return _failure(
				"buildings[%d].state.%s 物品数量无效"
				% [index, field_name]
			)
		total += int(amount)
	if total > expected_capacity:
		return _failure(
			"buildings[%d].state.%s 超出容量" % [index, field_name]
		)
	return _success(raw_inventory)


static func _validate_conveyor_state(
	raw_state: Dictionary,
	index: int
) -> Dictionary:
	var cargo = raw_state.get("cargo", {})
	if not (cargo is Dictionary):
		return _failure("buildings[%d].state.cargo 必须是对象" % index)
	if not cargo.is_empty():
		var cargo_keys := ["item_id", "progress"]
		for key in cargo:
			if not cargo_keys.has(String(key)):
				return _failure(
					"buildings[%d].state.cargo 包含未知字段 %s"
					% [index, key]
				)
		for key in cargo_keys:
			if not cargo.has(key):
				return _failure(
					"buildings[%d].state.cargo 缺少字段 %s"
					% [index, key]
				)
		var item_id = cargo["item_id"]
		if (
			not (item_id is String)
			or not TRANSPORT_ITEM_IDS.has(String(item_id))
		):
			return _failure(
				"buildings[%d].state.cargo 使用未知货物" % index
			)
		var progress = cargo["progress"]
		if (
			not (progress is float or progress is int)
			or not is_finite(float(progress))
			or float(progress) < 0.0
			or float(progress) > 1.0
		):
			return _failure(
				"buildings[%d].state.cargo.progress 超出有效范围"
				% index
			)
	var merge_cursor = raw_state.get("merge_cursor", 0)
	if not _is_integer(merge_cursor) or int(merge_cursor) < 0:
		return _failure(
			"buildings[%d].state.merge_cursor 必须是非负整数" % index
		)
	return _success(raw_state)


static func _validate_storage_inventory(raw_inventory, index: int) -> Dictionary:
	if not (raw_inventory is Dictionary):
		return _failure("buildings[%d].state.inventory 必须是对象" % index)
	for key in raw_inventory:
		if not ["capacity", "contents"].has(String(key)):
			return _failure(
				"buildings[%d].state.inventory 包含未知字段 %s" % [index, key]
			)
	var capacity_value = raw_inventory.get(
		"capacity", LEGACY_STORAGE_CAPACITY
	)
	if (
		not _is_integer(capacity_value)
		or int(capacity_value) != LEGACY_STORAGE_CAPACITY
	):
		return _failure("buildings[%d].state.inventory.capacity 无效" % index)
	var contents = raw_inventory.get("contents", {})
	if not (contents is Dictionary):
		return _failure("buildings[%d].state.inventory.contents 必须是对象" % index)
	var total := 0
	for item_id in contents:
		if not (item_id is String) or not STORAGE_ITEM_IDS.has(String(item_id)):
			return _failure(
				"buildings[%d].state.inventory 包含未知物品 %s" % [index, item_id]
			)
		var amount = contents[item_id]
		if not _is_integer(amount) or int(amount) <= 0:
			return _failure(
				"buildings[%d].state.inventory 物品数量无效" % index
			)
		total += int(amount)
	if total > LEGACY_STORAGE_CAPACITY:
		return _failure("buildings[%d].state.inventory 超出容量" % index)
	return _success(raw_inventory)


static func _validate_schema_eight_storage_state(
	raw_state: Dictionary,
	index: int
) -> Dictionary:
	var inventory_result := _validate_schema_eight_storage_inventory(
		raw_state.get("inventory", null), index
	)
	if not bool(inventory_result.get("success", false)):
		return inventory_result
	var mode = raw_state.get("mode", null)
	if not (mode is String) or not ["supply", "transfer"].has(String(mode)):
		return _failure(
			"buildings[%d].state.mode 必须是 supply 或 transfer" % index
		)
	var output_item_id = raw_state.get("output_item_id", null)
	if not (output_item_id is String):
		return _failure(
			"buildings[%d].state.output_item_id 必须是字符串" % index
		)
	if (
		not String(output_item_id).is_empty()
		and not TRANSPORT_ITEM_IDS.has(String(output_item_id))
	):
		return _failure(
			"buildings[%d].state.output_item_id 不是可运输物品" % index
		)
	var transfer_cursor = raw_state.get("transfer_cursor", null)
	var transportable_count := TRANSPORT_ITEM_IDS.size()
	if (
		not _is_integer(transfer_cursor)
		or int(transfer_cursor) < 0
		or (
			transportable_count > 0
			and int(transfer_cursor) >= transportable_count
		)
	):
		return _failure(
			"buildings[%d].state.transfer_cursor 超出有效范围" % index
		)
	var transfer_progress = raw_state.get("transfer_progress", null)
	if (
		not (transfer_progress is float or transfer_progress is int)
		or not is_finite(float(transfer_progress))
		or float(transfer_progress) < 0.0
		or float(transfer_progress) >= STORAGE_TRANSFER_INTERVAL
	):
		return _failure(
			"buildings[%d].state.transfer_progress 超出有效范围" % index
		)
	if (
		String(mode) == "supply"
		and not is_zero_approx(float(transfer_progress))
	):
		return _failure(
			"buildings[%d] 的供给模式不能保留传输进度" % index
		)
	return _success(raw_state)


static func _validate_schema_eight_storage_inventory(
	raw_inventory,
	index: int
) -> Dictionary:
	if not (raw_inventory is Dictionary):
		return _failure("buildings[%d].state.inventory 必须是对象" % index)
	if (
		raw_inventory.keys().size() != 1
		or not raw_inventory.has("contents")
	):
		return _failure(
			"buildings[%d].state.inventory 必须且只能包含 contents"
			% index
		)
	var contents = raw_inventory["contents"]
	if not (contents is Dictionary):
		return _failure(
			"buildings[%d].state.inventory.contents 必须是对象" % index
		)
	# Schema 7 could legally fit all nine known types under its aggregate cap.
	# Preserve that grandfathered property without a persisted compatibility
	# marker; normal runtime writes remain constrained by category_storage().
	for item_id in contents:
		if (
			not (item_id is String)
			or not STORAGE_ITEM_IDS.has(String(item_id))
		):
			return _failure(
				"buildings[%d].state.inventory 包含未知物品 %s"
				% [index, item_id]
			)
		var amount = contents[item_id]
		if (
			not _is_integer(amount)
			or int(amount) <= 0
			or int(amount) > 200
		):
			return _failure(
				"buildings[%d].state.inventory 物品数量无效" % index
			)
	return _success(raw_inventory)


static func _without_legacy_capacity(raw_inventory) -> Dictionary:
	var contents := {}
	if raw_inventory is Dictionary:
		var raw_contents = raw_inventory.get("contents", {})
		if raw_contents is Dictionary:
			contents = raw_contents.duplicate(true)
	return {"contents": contents}


static func _first_transportable_item(contents: Dictionary) -> String:
	for item_id in TRANSPORT_ITEM_IDS:
		if int(contents.get(item_id, 0)) > 0:
			return item_id
	return ""


static func _is_floor(building_id: String) -> bool:
	return building_id == SliceBuildingCatalog.FLOOR_ID


static func _occupied_cells(
	building_id: String,
	origin: Vector2i,
	rotation: int,
	schema_eight: bool
) -> Array[Vector2i]:
	var size: Vector2i = FROZEN_FOOTPRINTS[building_id]
	if (
		not schema_eight
		and posmod(rotation, 4) % 2 == 1
	):
		size = Vector2i(size.y, size.x)
	var result: Array[Vector2i] = []
	for y in range(size.y):
		for x in range(size.x):
			result.append(origin + Vector2i(x, y))
	return result


static func _serial_from_instance_id(instance_id: String) -> int:
	if not instance_id.begins_with(INSTANCE_ID_PREFIX):
		return -1
	var suffix := instance_id.trim_prefix(INSTANCE_ID_PREFIX)
	if suffix.length() < 6 or not suffix.is_valid_int():
		return -1
	return int(suffix)


static func _is_integer(value) -> bool:
	if value is int:
		return true
	return value is float and is_equal_approx(value, roundf(value))


static func _cell_in_bounds(cell: Vector2i) -> bool:
	return (
		cell.x >= 0
		and cell.y >= 0
		and cell.x < MAP_SIZE_CELLS.x
		and cell.y < MAP_SIZE_CELLS.y
	)


static func _cell_key(cell: Vector2i) -> String:
	return "%d:%d" % [cell.x, cell.y]


static func _success(data: Dictionary) -> Dictionary:
	return {"success": true, "data": data}


static func _failure(reason: String) -> Dictionary:
	return {
		"success": false,
		"message": "切片存档建筑数据无效：%s，当前运行状态已保留。" % reason,
	}
