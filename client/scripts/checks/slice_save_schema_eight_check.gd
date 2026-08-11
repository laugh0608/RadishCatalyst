extends SceneTree

var TEST_ROOT := SliceCheckPaths.check_run("save-schema-eight", false)

var failures: Array[String] = []
var assertion_count := 0


func _init() -> void:
	call_deferred("_execute")


func _execute() -> void:
	_remove_tree(TEST_ROOT)
	_check_strict_contract_rejections()
	_check_schema_seven_rotation_and_idempotence()
	_remove_tree(TEST_ROOT)
	if failures.is_empty():
		print(
			"Slice save schema 8 checks passed (%d assertions)."
			% assertion_count
		)
		quit(0)
		return
	for failure in failures:
		push_error(failure)
	quit(1)


func _check_strict_contract_rejections() -> void:
	var fixed_floor := _building_entry(
		"building-000001", SliceBuildingCatalog.FLOOR_ID,
		Vector2i(4, 4), 1, {}
	)
	_expect_failure(
		SliceBuildingSaveCodec.validate_schema_eight([fixed_floor], 2),
		"固定设施必须为 0",
		"schema 8 rejects nonzero fixed rotation"
	)
	var storage := _building_entry(
		"building-000002", SliceBuildingCatalog.STORAGE_ID,
		Vector2i(8, 8), 0,
		{
			"inventory": {"contents": {}},
			"mode": "supply",
			"output_item_id": "",
			"transfer_cursor": 0,
			"transfer_progress": 1.0,
		}
	)
	_expect_failure(
		SliceBuildingSaveCodec.validate_schema_eight([storage], 3),
		"供给模式不能保留传输进度",
		"schema 8 rejects supply transfer progress"
	)


func _check_schema_seven_rotation_and_idempotence() -> void:
	var fixture := _schema_seven_rotation_fixture()
	var state: Dictionary = fixture["state"]
	var legacy_rotations: Dictionary = fixture["rotations"]
	var save_dir := TEST_ROOT.path_join("rotation")
	DirAccess.make_dir_recursive_absolute(save_dir)
	var service := SliceSaveService.new(save_dir)
	var save_path := service.save_file_path()
	var schema_seven := _schema_seven_payload_from_state(state)
	_expect_schema_seven_contract(schema_seven, "schema 7 fixture")
	_write_json(save_path, schema_seven)
	_expect_rotation_map(
		schema_seven["buildings"], legacy_rotations, "schema 7 source"
	)

	var load_result := service.load_state()
	_expect_success(load_result, "schema 7 migrates in memory")
	if not bool(load_result.get("success", false)):
		return
	_expect_equal(
		bool(load_result.get("migration_required", false)),
		true,
		"schema 7 reports migration context"
	)
	_expect_equal(
		int(_read_json(save_path).get("save_schema_version", 0)),
		7,
		"load is read only before world reconstruction"
	)
	var loaded_data: Dictionary = load_result["data"]
	var migrated_rotations := legacy_rotations.duplicate()
	for entry in state["buildings"]:
		if entry["building_id"] != SliceBuildingCatalog.CONVEYOR_ID:
			migrated_rotations[entry["instance_id"]] = 0
	_expect_rotation_map(
		loaded_data["buildings"], migrated_rotations, "schema 8 migration"
	)

	var grandfathered_storage := _find_five_type_storage_state(
		loaded_data["buildings"]
	)
	_expect(
		not grandfathered_storage.is_empty(),
		"five-type schema 7 storage migrates without loss"
	)
	if not grandfathered_storage.is_empty():
		_expect(
			not grandfathered_storage["inventory"].has("capacity"),
			"grandfathered storage drops capacity"
		)
		_expect_equal(
			String(grandfathered_storage["mode"]),
			"supply",
			"legacy storage defaults to supply"
		)
		_expect_equal(
			String(grandfathered_storage["output_item_id"]),
			SliceWorld.ITEM_CRYSTAL,
			"legacy output uses stable item order"
		)

	var invalid_state := loaded_data.duplicate(true)
	invalid_state["pocket"]["contents"][SliceWorld.ITEM_CRYSTAL] = 201
	_expect_failure(
		service.commit_loaded_state(
			invalid_state, load_result["load_context"]
		),
		"profile",
		"failed publication remains retryable"
	)
	_expect(
		service.has_pending_loaded_state(),
		"failed publication keeps pending context"
	)
	_expect_success(
		service.commit_loaded_state(
			loaded_data, load_result["load_context"]
		),
		"rebuilt state publishes as schema 8"
	)

	var first_save := _read_json(save_path)
	_expect_schema_eight_contract(first_save, "schema 8 migrated save")
	_expect_equal(
		int(_read_json(service.backup_file_paths()[0]).get(
			"save_schema_version", 0
		)),
		7,
		"main-source migration preserves schema 7 backup"
	)
	var current_result := service.load_state()
	_expect_success(current_result, "schema 8 reloads")
	if not bool(current_result.get("success", false)):
		return
	_expect(
		not _find_five_type_storage_state(
			current_result["data"]["buildings"]
		).is_empty(),
		"five-type storage survives schema 8 restart"
	)
	_expect_success(
		service.save_state(current_result["data"]),
		"schema 8 saves again"
	)
	var second_save := _read_json(save_path)
	_expect_equal(
		_semantic_payload(second_save),
		_semantic_payload(first_save),
		"schema 8 save-load-save is idempotent"
	)


func _schema_seven_rotation_fixture() -> Dictionary:
	var buildings: Array = []
	var rotations := {}
	var serial := 1
	for rotation in range(4):
		serial = _append_rotation_building(
			buildings, rotations, serial,
			SliceBuildingCatalog.REACTOR_ID,
			Vector2i(2 + rotation * 6, 2), rotation,
			_empty_schema_seven_reactor_state()
		)
		serial = _append_rotation_building(
			buildings, rotations, serial,
			SliceBuildingCatalog.STORAGE_ID,
			Vector2i(30 + rotation * 4, 2), rotation,
			{
				"inventory": {
					"capacity": 20,
					"contents": (
						{
							SliceWorld.ITEM_CRYSTAL: 1,
							SliceWorld.ITEM_CATALYST: 1,
							SliceWorld.ITEM_PART: 1,
							SliceBuildingCatalog.FLOOR_ID: 1,
							SliceBuildingCatalog.COLLECTOR_ID: 1,
						}
						if rotation == 0
						else {SliceWorld.ITEM_CRYSTAL: rotation + 1}
					),
				},
			}
		)
		serial = _append_rotation_building(
			buildings, rotations, serial,
			SliceBuildingCatalog.POWER_RELAY_ID,
			Vector2i(48 + rotation * 2, 2), rotation, {}
		)
		serial = _append_rotation_building(
			buildings, rotations, serial,
			SliceBuildingCatalog.CONVEYOR_ID,
			Vector2i(58 + rotation * 2, 2), rotation,
			{
				"cargo": {
					"item_id": SliceWorld.ITEM_CRYSTAL,
					"progress": float(rotation) * 0.125,
				},
				"merge_cursor": rotation,
			}
		)
		serial = _append_rotation_building(
			buildings, rotations, serial,
			SliceBuildingCatalog.COLLECTOR_ID,
			Vector2i(2 + rotation * 4, 12), rotation,
			{
				"buffer": rotation,
				"production_progress": float(rotation) * 0.25,
			}
		)
	return {
		"state": {
			"pocket": {"capacity": 30, "contents": {"crystal": 9}},
			"core_storage": {
				"capacity": 120, "contents": {"catalyst": 2},
			},
			"core_repaired": true,
			"core_energy": SliceWorld.CORE_CHARGE_TARGET,
			"harvested_clusters": ["CrystalSmall1"],
			"buildings": buildings,
			"next_building_serial": serial,
			"player_x": 432.0,
			"player_y": 576.0,
			"player_health": 73,
			"field_encounter": {"state": "hostile", "enemy_health": 40},
		},
		"rotations": rotations,
	}


func _append_rotation_building(
	buildings: Array,
	rotations: Dictionary,
	serial: int,
	building_id: String,
	origin: Vector2i,
	rotation: int,
	state: Dictionary
) -> int:
	var definition := SliceBuildingCatalog.find(building_id)
	if (
		definition.surface_rule
		== SliceBuildingDefinition.SURFACE_INDUSTRIAL_FLOOR
	):
		for cell in definition.occupied_cells(origin, rotation):
			buildings.append(_building_entry(
				"building-%06d" % serial,
				SliceBuildingCatalog.FLOOR_ID,
				cell, 0, {}
			))
			serial += 1
	var instance_id := "building-%06d" % serial
	buildings.append(_building_entry(
		instance_id, building_id, origin, rotation, state.duplicate(true)
	))
	rotations[instance_id] = rotation
	return serial + 1


func _schema_seven_payload_from_state(state: Dictionary) -> Dictionary:
	return {
		"save_schema_version": 7,
		"game_version": "prototype-slice-07",
		"updated_at": "2026-08-08T00:00:00",
		"pocket": state["pocket"].duplicate(true),
		"core_storage": state["core_storage"].duplicate(true),
		"core_repaired": state["core_repaired"],
		"core_energy": state["core_energy"],
		"harvested_clusters": state["harvested_clusters"].duplicate(),
		"buildings": state["buildings"].duplicate(true),
		"next_building_serial": state["next_building_serial"],
		"player_x": state["player_x"],
		"player_y": state["player_y"],
		"player_health": state["player_health"],
		"field_encounter": state["field_encounter"].duplicate(true),
	}


func _empty_schema_seven_reactor_state() -> Dictionary:
	return {
		"input_inventory": {"capacity": 2, "contents": {}},
		"output_inventory": {"capacity": 1, "contents": {}},
		"processing": false,
		"production_progress": 0.0,
	}


func _building_entry(
	instance_id: String,
	building_id: String,
	origin: Vector2i,
	rotation: int,
	state: Dictionary
) -> Dictionary:
	return {
		"instance_id": instance_id,
		"building_id": building_id,
		"origin_cell": [origin.x, origin.y],
		"rotation": rotation,
		"state": state,
	}


func _find_five_type_storage_state(value) -> Dictionary:
	if not (value is Array):
		return {}
	for entry in value:
		if (
			entry is Dictionary
			and entry.get("building_id", "")
			== SliceBuildingCatalog.STORAGE_ID
		):
			var state = entry.get("state", {})
			var inventory = state.get("inventory", {}) if state is Dictionary else {}
			var contents = (
				inventory.get("contents", {})
				if inventory is Dictionary
				else {}
			)
			if contents is Dictionary and contents.size() == 5:
				return state
	return {}


func _expect_rotation_map(
	value,
	expected: Dictionary,
	label: String
) -> void:
	var actual := {}
	if value is Array:
		for entry in value:
			if entry is Dictionary and expected.has(entry.get("instance_id", "")):
				actual[String(entry["instance_id"])] = int(entry.get("rotation", -1))
	_expect_equal(actual.size(), expected.size(), "%s count" % label)
	for instance_id in expected:
		_expect_equal(
			int(actual.get(instance_id, -1)),
			int(expected[instance_id]),
			"%s %s" % [label, instance_id]
		)


func _expect_schema_seven_contract(data: Dictionary, label: String) -> void:
	assertion_count += 1
	for failure in SliceSaveSchemaSevenContract.validate(data):
		failures.append("%s: %s" % [label, failure])


func _expect_schema_eight_contract(data: Dictionary, label: String) -> void:
	assertion_count += 1
	for failure in SliceSaveSchemaEightContract.validate(data):
		failures.append("%s: %s" % [label, failure])


func _semantic_payload(data: Dictionary) -> Dictionary:
	var result := data.duplicate(true)
	result.erase("updated_at")
	return result


func _read_json(path: String) -> Dictionary:
	var file := FileAccess.open(path, FileAccess.READ)
	if file == null:
		failures.append("could not read %s" % path)
		return {}
	var parsed = JSON.parse_string(file.get_as_text())
	file.close()
	if not (parsed is Dictionary):
		failures.append("%s must contain an object" % path)
		return {}
	return parsed


func _write_json(path: String, data: Dictionary) -> void:
	DirAccess.make_dir_recursive_absolute(path.get_base_dir())
	var file := FileAccess.open(path, FileAccess.WRITE)
	if file == null:
		failures.append("could not write %s" % path)
		return
	file.store_string(JSON.stringify(data, "\t"))
	file.close()


func _remove_tree(path: String) -> void:
	if not DirAccess.dir_exists_absolute(path):
		return
	var dir := DirAccess.open(path)
	if dir == null:
		return
	dir.list_dir_begin()
	var entry := dir.get_next()
	while not entry.is_empty():
		var child := path.path_join(entry)
		if dir.current_is_dir():
			_remove_tree(child)
		else:
			DirAccess.remove_absolute(child)
		entry = dir.get_next()
	dir.list_dir_end()
	DirAccess.remove_absolute(path)


func _expect_success(result: Dictionary, label: String) -> void:
	_expect(
		bool(result.get("success", false)),
		"%s: %s" % [label, result.get("message", "")]
	)


func _expect_failure(
	result: Dictionary,
	message_fragment: String,
	label: String
) -> void:
	assertion_count += 1
	if bool(result.get("success", false)):
		failures.append("%s should fail" % label)
	elif not String(result.get("message", "")).contains(message_fragment):
		failures.append("%s returned: %s" % [label, result.get("message", "")])


func _expect_equal(actual, expected, label: String) -> void:
	_expect(actual == expected, "%s: expected %s, got %s" % [label, expected, actual])


func _expect(condition: bool, label: String) -> void:
	assertion_count += 1
	if not condition:
		failures.append(label)
