class_name SliceBuildingSaveCodec
extends RefCounted

## Schema-6 building serialization and validation. Runtime power / logistics
## adjacency is deliberately absent: only topology and definition-owned state
## persist. Schema 5 remains readable through an explicit reactor migration.

const MAP_SIZE_CELLS := Vector2i(80, 24)
const INSTANCE_ID_PREFIX := "building-"
const COLLECTOR_PRODUCE_INTERVAL := 10.0
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
		var entry_result := _validate_entry(raw_buildings[index], index)
		if not bool(entry_result.get("success", false)):
			return entry_result
		var entry: Dictionary = entry_result["data"]
		var instance_id := String(entry["instance_id"])
		if ids.has(instance_id):
			return _failure("buildings 存在重复实例 ID：%s" % instance_id)
		ids[instance_id] = true
		max_serial = maxi(max_serial, _serial_from_instance_id(instance_id))

		var definition := SliceBuildingCatalog.find(String(entry["building_id"]))
		var origin_raw: Array = entry["origin_cell"]
		var origin := Vector2i(int(origin_raw[0]), int(origin_raw[1]))
		var rotation := int(entry["rotation"])
		var target_cells := (
			floor_cells if definition.is_floor else blocking_cells
		)
		for cell in definition.occupied_cells(origin, rotation):
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
		var definition := SliceBuildingCatalog.find(String(entry["building_id"]))
		if (
			definition.surface_rule
			!= SliceBuildingDefinition.SURFACE_INDUSTRIAL_FLOOR
		):
			continue
		var origin_raw: Array = entry["origin_cell"]
		var origin := Vector2i(int(origin_raw[0]), int(origin_raw[1]))
		for cell in definition.occupied_cells(origin, int(entry["rotation"])):
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
	if raw_buildings is Array:
		for index in range(raw_buildings.size()):
			var raw_entry = raw_buildings[index]
			if (
				raw_entry is Dictionary
				and raw_entry.get("building_id", "")
				== SliceBuildingCatalog.REACTOR_ID
			):
				var state = raw_entry.get("state", null)
				if not (state is Dictionary):
					return _failure(
						"buildings[%d].state 必须是对象" % index
					)
				var required_keys := [
					"input_inventory",
					"output_inventory",
					"processing",
					"production_progress",
				]
				for key in required_keys:
					if not state.has(key):
						return _failure(
							"buildings[%d].state 缺少字段 %s" % [index, key]
						)
	var result := validate_schema_five(raw_buildings, raw_next_serial)
	if not bool(result.get("success", false)):
		return result
	return result


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
					"capacity": SliceReactor.INPUT_CAPACITY,
					"contents": {},
				},
				"output_inventory": {
					"capacity": SliceReactor.OUTPUT_CAPACITY,
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
		var definition := SliceBuildingCatalog.find(
			SliceBuildingCatalog.COLLECTOR_ID
		)
		for cell in definition.occupied_cells(origin, 0):
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


static func _validate_entry(raw_entry, index: int) -> Dictionary:
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
	var definition := SliceBuildingCatalog.find(building_id)
	if definition == null:
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
	var raw_state = raw_entry["state"]
	if not (raw_state is Dictionary):
		return _failure("buildings[%d].state 必须是对象" % index)
	var state_result := _validate_state(definition, raw_state, index)
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
	definition: SliceBuildingDefinition,
	raw_state: Dictionary,
	index: int
) -> Dictionary:
	for key in raw_state:
		if not definition.state_keys.has(String(key)):
			return _failure(
				"buildings[%d].state 包含 %s 不允许的字段 %s"
				% [index, definition.building_id, key]
			)
	if definition.building_id == SliceBuildingCatalog.COLLECTOR_ID:
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
			or float(progress_value) < 0.0
			or float(progress_value) >= COLLECTOR_PRODUCE_INTERVAL
		):
			return _failure(
				"buildings[%d].state.production_progress 超出有效范围" % index
			)
	elif definition.building_id == SliceBuildingCatalog.STORAGE_ID:
		var inventory_result := _validate_storage_inventory(
			raw_state.get("inventory", {}), index
		)
		if not bool(inventory_result.get("success", false)):
			return inventory_result
	elif definition.building_id == SliceBuildingCatalog.CONVEYOR_ID:
		var conveyor_result := _validate_conveyor_state(raw_state, index)
		if not bool(conveyor_result.get("success", false)):
			return conveyor_result
	elif definition.building_id == SliceBuildingCatalog.REACTOR_ID:
		var reactor_result := _validate_reactor_state(raw_state, index)
		if not bool(reactor_result.get("success", false)):
			return reactor_result
	return _success(raw_state)


static func _validate_reactor_state(
	raw_state: Dictionary,
	index: int
) -> Dictionary:
	var input_result := _validate_reactor_inventory(
		raw_state.get("input_inventory", {
			"capacity": SliceReactor.INPUT_CAPACITY,
			"contents": {},
		}),
		index,
		"input_inventory",
		SliceReactor.INPUT_CAPACITY,
		SliceReactor.INPUT_ITEM_ID
	)
	if not bool(input_result.get("success", false)):
		return input_result
	var output_result := _validate_reactor_inventory(
		raw_state.get("output_inventory", {
			"capacity": SliceReactor.OUTPUT_CAPACITY,
			"contents": {},
		}),
		index,
		"output_inventory",
		SliceReactor.OUTPUT_CAPACITY,
		SliceReactor.OUTPUT_ITEM_ID
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
		or float(progress_value) >= SliceReactor.PROCESS_DURATION
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
	allowed_item_id: String
) -> Dictionary:
	if not (raw_inventory is Dictionary):
		return _failure(
			"buildings[%d].state.%s 必须是对象" % [index, field_name]
		)
	var required_keys := ["capacity", "contents"]
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
	var capacity_value = raw_inventory.get("capacity", SliceStorage.CAPACITY)
	if (
		not _is_integer(capacity_value)
		or int(capacity_value) != SliceStorage.CAPACITY
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
	if total > SliceStorage.CAPACITY:
		return _failure("buildings[%d].state.inventory 超出容量" % index)
	return _success(raw_inventory)


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
