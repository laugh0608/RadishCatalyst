extends SceneTree

const SliceWorldScene := preload("res://scenes/slice/SliceWorld.tscn")

var failures: Array[String] = []
var _assertion_count := 0
var _save_dirs: Array[String] = []


func _init() -> void:
	call_deferred("_execute")


func _execute() -> void:
	await _run_checks()
	if failures.is_empty():
		print("Slice save schema checks passed (%d assertions)." % _assertion_count)
		_cleanup()
		quit(0)
		return
	for failure in failures:
		push_error(failure)
	_cleanup()
	quit(1)


func _run_checks() -> void:
	_check_bootstrap_resource_budget()
	_check_codec_rejects_invalid_topology()
	_check_schema_two_to_five_migration()
	_check_invalid_primary_falls_back_to_backup()
	await _check_schema_seven_world_restart()


func _check_bootstrap_resource_budget() -> void:
	var map_scene := load(SliceWorld.MAP_SCENE) as PackedScene
	var map := map_scene.instantiate()
	var world_node := map.get_node("World")
	var total_yield := 0
	var cluster_count := 0
	for cluster in world_node.get_children():
		var harvest := cluster.get_node_or_null("Harvest")
		if harvest == null:
			continue
		var yield_value = harvest.get("yield_amount")
		if yield_value == null:
			continue
		total_yield += int(yield_value)
		cluster_count += 1
		if String(cluster.name).begins_with("CrystalLarge"):
			_expect_equal(int(yield_value), 8, "%s yields eight" % cluster.name)
	_expect_equal(cluster_count, 8, "map keeps eight crystal clusters")
	_expect_equal(total_yield, 25, "map provides the exact L3 bootstrap budget")

	var part_recipe := SliceRecipes.find("part")
	var floor_recipe := SliceRecipes.find("floor")
	var relay_recipe := SliceRecipes.find("power_relay")
	var collector_recipe := SliceRecipes.find("collector")
	var crystal_per_part := int(part_recipe["cost"][SliceWorld.ITEM_CRYSTAL])
	var bootstrap_cost := (
		CoreRepairSite.REPAIR_PART_COST * crystal_per_part
		+ (
			int(relay_recipe["cost"][SliceWorld.ITEM_PART]) * 3
			+ int(collector_recipe["cost"][SliceWorld.ITEM_PART])
		) * crystal_per_part
		+ int(floor_recipe["cost"][SliceWorld.ITEM_CRYSTAL])
	)
	_expect_equal(bootstrap_cost, 25, "documented three-hop bootstrap costs 25")
	_expect_equal(
		total_yield >= bootstrap_cost,
		true,
		"fresh map can bootstrap its first powered collector"
	)
	map.free()


func _check_codec_rejects_invalid_topology() -> void:
	var floor := _building_entry(
		"building-000001",
		SliceBuildingCatalog.FLOOR_ID,
		Vector2i(25, 10),
		0,
		{}
	)
	var relay := _building_entry(
		"building-000002",
		SliceBuildingCatalog.POWER_RELAY_ID,
		Vector2i(25, 10),
		0,
		{}
	)
	_expect_codec_success([floor, relay], 3, "valid floor-supported relay topology")

	var duplicate_id := relay.duplicate(true)
	duplicate_id["instance_id"] = "building-000001"
	_expect_codec_failure([floor, duplicate_id], 2, "重复实例 ID", "duplicate id")

	var unknown := relay.duplicate(true)
	unknown["building_id"] = "building.unknown"
	_expect_codec_failure([floor, unknown], 3, "未知建筑", "unknown building")

	var bad_rotation := relay.duplicate(true)
	bad_rotation["rotation"] = 4
	_expect_codec_failure([floor, bad_rotation], 3, "rotation", "invalid rotation")

	var overlap := relay.duplicate(true)
	overlap["instance_id"] = "building-000003"
	_expect_codec_failure(
		[floor, relay, overlap], 4, "占用重叠", "blocking overlap"
	)

	var unknown_state := relay.duplicate(true)
	unknown_state["state"] = {"powered": true}
	_expect_codec_failure(
		[floor, unknown_state], 3, "不允许的字段", "derived power state"
	)

	_expect_codec_failure(
		[relay], 3, "缺少完整工业地板支撑", "missing floor support"
	)
	_expect_codec_failure(
		[floor, relay], 2, "必须大于", "next serial collision"
	)

	var storage_floor_entries: Array = []
	var serial := 1
	for y in range(2):
		for x in range(2):
			storage_floor_entries.append(_building_entry(
				"building-%06d" % serial,
				SliceBuildingCatalog.FLOOR_ID,
				Vector2i(30 + x, 5 + y),
				0,
				{}
			))
			serial += 1
	var storage := _building_entry(
		"building-000005",
		SliceBuildingCatalog.STORAGE_ID,
		Vector2i(30, 5),
		0,
		{
			"inventory": {
				"capacity": SliceStorage.CAPACITY,
				"contents": {"item.unknown": 1},
			},
		}
	)
	_expect_codec_failure(
		storage_floor_entries + [storage],
		6,
		"未知物品",
		"storage item whitelist"
	)

	var conveyor_floor := _building_entry(
		"building-000006",
		SliceBuildingCatalog.FLOOR_ID,
		Vector2i(24, 5),
		0,
		{}
	)
	var conveyor := _building_entry(
		"building-000007",
		SliceBuildingCatalog.CONVEYOR_ID,
		Vector2i(24, 5),
		1,
		{
			"cargo": {
				"item_id": SliceWorld.ITEM_CRYSTAL,
				"progress": 0.5,
			},
			"merge_cursor": 2,
		}
	)
	_expect_codec_success(
		[conveyor_floor, conveyor], 8, "valid conveyor cargo state"
	)
	var catalyst_cargo := conveyor.duplicate(true)
	catalyst_cargo["state"]["cargo"]["item_id"] = SliceWorld.ITEM_CATALYST
	_expect_codec_success(
		[conveyor_floor, catalyst_cargo],
		8,
		"schema 6 accepts catalyst conveyor cargo"
	)
	var bad_cargo := conveyor.duplicate(true)
	bad_cargo["state"]["cargo"]["progress"] = 1.5
	_expect_codec_failure(
		[conveyor_floor, bad_cargo],
		8,
		"progress",
		"conveyor cargo progress"
	)

	var reactor_entries := _reactor_floor_entries(Vector2i(50, 5), 8)
	var reactor := _building_entry(
		"building-000017",
		SliceBuildingCatalog.REACTOR_ID,
		Vector2i(50, 5),
		0,
		{
			"input_inventory": {
				"capacity": SliceReactor.INPUT_CAPACITY,
				"contents": {SliceWorld.ITEM_CRYSTAL: 2},
			},
			"output_inventory": {
				"capacity": SliceReactor.OUTPUT_CAPACITY,
				"contents": {},
			},
			"processing": true,
			"production_progress": 5.0,
		}
	)
	_expect_codec_success(
		reactor_entries + [reactor], 18, "valid reactor retained state"
	)
	var idle_progress := reactor.duplicate(true)
	idle_progress["state"]["processing"] = false
	_expect_codec_failure(
		reactor_entries + [idle_progress],
		18,
		"空闲反应器",
		"idle reactor cannot retain progress"
	)
	var occupied_output := reactor.duplicate(true)
	occupied_output["state"]["output_inventory"]["contents"] = {
		SliceWorld.ITEM_CATALYST: 1,
	}
	_expect_codec_failure(
		reactor_entries + [occupied_output],
		18,
		"输出必须为空",
		"processing reactor output invariant"
	)
	var missing_processing := reactor.duplicate(true)
	missing_processing["state"].erase("processing")
	_expect_codec_failure(
		reactor_entries + [missing_processing],
		18,
		"缺少字段 processing",
		"schema 6 requires exact reactor fields"
	)


func _check_schema_two_to_five_migration() -> void:
	var schema_four_dir := _new_save_dir("schema4")
	var schema_four_service := SliceSaveService.new(schema_four_dir)
	var schema_four_state := _empty_runtime_state(4)
	schema_four_state["buildings"] = [
		_building_entry(
			"building-000001",
			SliceBuildingCatalog.FLOOR_ID,
			Vector2i(20, 5),
			0,
			{}
		),
		_building_entry(
			"building-000002",
			SliceBuildingCatalog.CONVEYOR_ID,
			Vector2i(20, 5),
			1,
			{}
		),
	]
	schema_four_state["next_building_serial"] = 3
	_expect_success(
		schema_four_service.save_state(schema_four_state),
		"schema 4 fixture writes through current validator"
	)
	var schema_four_path := schema_four_dir.path_join("slice_world.json")
	var schema_four := _read_json(schema_four_path)
	schema_four["save_schema_version"] = 4
	schema_four["game_version"] = "prototype-slice-04"
	_write_json(schema_four_path, schema_four)
	var schema_four_result := schema_four_service.load_state()
	_expect_success(schema_four_result, "schema 4 topology remains readable")
	if bool(schema_four_result.get("success", false)):
		var buildings: Array = schema_four_result["data"]["buildings"]
		_expect_equal(buildings.size(), 2, "schema 4 building count")
		_expect_equal(
			(buildings[1]["state"] as Dictionary).is_empty(),
			true,
			"schema 4 conveyor migrates as an empty belt"
		)

	var schema_five_dir := _new_save_dir("schema5")
	var schema_five_service := SliceSaveService.new(schema_five_dir)
	var schema_five_state := _empty_runtime_state(0)
	schema_five_state["core_storage"]["contents"] = {
		SliceWorld.ITEM_CATALYST: 1,
	}
	schema_five_state["buildings"] = _reactor_floor_entries(
		Vector2i(50, 5), 1
	)
	schema_five_state["buildings"].append(_building_entry(
		"building-000010",
		SliceBuildingCatalog.REACTOR_ID,
		Vector2i(50, 5),
		0,
		_empty_reactor_state()
	))
	schema_five_state["next_building_serial"] = 11
	_expect_success(
		schema_five_service.save_state(schema_five_state),
		"schema 5 fixture writes through current validator"
	)
	var schema_five_path := schema_five_dir.path_join("slice_world.json")
	var schema_five := _read_json(schema_five_path)
	schema_five["save_schema_version"] = 5
	schema_five["game_version"] = "prototype-slice-05"
	schema_five["catalyst_count"] = 4
	schema_five["reactor_active"] = true
	for entry in schema_five["buildings"]:
		if entry["building_id"] == SliceBuildingCatalog.REACTOR_ID:
			entry["state"] = {}
	_write_json(schema_five_path, schema_five)
	var schema_five_result := schema_five_service.load_state()
	_expect_success(schema_five_result, "schema 5 reactor state migrates")
	if bool(schema_five_result.get("success", false)):
		var data: Dictionary = schema_five_result["data"]
		_expect_equal(
			int(data["core_storage"]["contents"][SliceWorld.ITEM_CATALYST]),
			5,
			"legacy catalyst migrates losslessly into core storage"
		)
		_expect_equal(
			bool(data["reactor_active"]),
			false,
			"legacy reactor activation is ignored"
		)
		var migrated_reactor: Dictionary = data["buildings"][9]
		_expect_equal(
			migrated_reactor["state"],
			_empty_reactor_state(),
			"schema 5 reactor becomes empty and idle"
		)

	var schema_three_dir := _new_save_dir("schema3")
	var schema_three := _legacy_save_data(3)
	schema_three["core_storage"] = {
		"capacity": SliceWorld.CORE_STORAGE_CAPACITY,
		"contents": {SliceWorld.ITEM_PART: 2},
	}
	schema_three["carrying_collector"] = true
	_write_json(schema_three_dir.path_join("slice_world.json"), schema_three)
	var schema_three_result := SliceSaveService.new(schema_three_dir).load_state()
	_expect_success(schema_three_result, "schema 3 migrates")
	if bool(schema_three_result.get("success", false)):
		var data: Dictionary = schema_three_result["data"]
		var buildings: Array = data["buildings"]
		_expect_equal(buildings.size(), 2, "schema 3 collector count")
		_expect_equal(
			String(buildings[0]["instance_id"]),
			"building-000001",
			"schema 3 first stable id"
		)
		_expect_equal(
			int(buildings[1]["state"]["buffer"]),
			3,
			"schema 3 collector buffer"
		)
		_expect_equal(
			float(buildings[1]["state"]["production_progress"]),
			0.0,
			"schema 3 collector progress starts at zero"
		)
		_expect_equal(
			int(data["next_building_serial"]),
			3,
			"schema 3 next serial"
		)
		_expect_equal(
			int(data["pocket"]["contents"][SliceBuildingCatalog.COLLECTOR_ID]),
			1,
			"schema 3 carried collector becomes a kit"
		)
		_expect_equal(
			int(data["core_storage"]["contents"][SliceWorld.ITEM_PART]),
			2,
			"schema 3 core storage survives migration"
		)
		_expect_equal(
			int(data["core_storage"]["contents"][SliceWorld.ITEM_CATALYST]),
			1,
			"schema 3 global catalyst migrates into core storage"
		)

	var schema_two_dir := _new_save_dir("schema2")
	_write_json(
		schema_two_dir.path_join("slice_world.json"),
		_legacy_save_data(2)
	)
	var schema_two_result := SliceSaveService.new(schema_two_dir).load_state()
	_expect_success(schema_two_result, "schema 2 migrates")
	if bool(schema_two_result.get("success", false)):
		var data: Dictionary = schema_two_result["data"]
		_expect_equal(
			int(data["core_storage"]["capacity"]),
			SliceWorld.CORE_STORAGE_CAPACITY,
			"schema 2 receives current core storage capacity"
		)
		_expect_equal(
			int(data["core_storage"]["contents"][SliceWorld.ITEM_CATALYST]),
			1,
			"schema 2 global catalyst migrates into new core storage"
		)

	var schema_one_dir := _new_save_dir("schema1")
	var schema_one := _legacy_save_data(1)
	_write_json(schema_one_dir.path_join("slice_world.json"), schema_one)
	_expect_failure(
		SliceSaveService.new(schema_one_dir).load_state(),
		"版本不兼容",
		"schema 1 remains unsupported"
	)

	var malformed_dir := _new_save_dir("schema3-malformed")
	var malformed := _legacy_save_data(3)
	malformed["collectors"] = [{"cell": [40], "buffer": 1}]
	_write_json(malformed_dir.path_join("slice_world.json"), malformed)
	_expect_failure(
		SliceSaveService.new(malformed_dir).load_state(),
		"cell 必须是两个整数",
		"malformed legacy collector is not silently dropped"
	)


func _check_invalid_primary_falls_back_to_backup() -> void:
	var save_dir := _new_save_dir("backup")
	var service := SliceSaveService.new(save_dir)
	_expect_success(service.save_state(_empty_runtime_state(3)), "first valid save")
	_expect_success(service.save_state(_empty_runtime_state(7)), "second valid save")

	var primary_path := save_dir.path_join("slice_world.json")
	var invalid_primary := _read_json(primary_path)
	invalid_primary["buildings"] = [
		_building_entry(
			"building-000001",
			SliceBuildingCatalog.FLOOR_ID,
			Vector2i(4, 4),
			0,
			{}
		),
		_building_entry(
			"building-000001",
			SliceBuildingCatalog.FLOOR_ID,
			Vector2i(5, 4),
			0,
			{}
		),
	]
	invalid_primary["next_building_serial"] = 2
	_write_json(primary_path, invalid_primary)

	var fallback_result := service.load_state()
	_expect_success(fallback_result, "invalid topology primary falls back")
	if bool(fallback_result.get("success", false)):
		_expect_equal(
			String(fallback_result.get("source_path", "")),
			save_dir.path_join("slice_world.bak.json"),
			"backup candidate selected"
		)
		_expect_equal(
			int(fallback_result["data"]["pocket"]["contents"][SliceWorld.ITEM_CRYSTAL]),
			3,
			"backup state remains intact"
		)

	_write_text(save_dir.path_join("slice_world.bak.json"), "{")
	_expect_failure(
		service.load_state(),
		"JSON 解析失败",
		"all invalid candidates fail without partial state"
	)


func _check_schema_seven_world_restart() -> void:
	var save_dir := _new_save_dir("restart")
	var service := SliceSaveService.new(save_dir)
	var world := SliceWorldScene.instantiate() as SliceWorld
	world.save_service = service
	root.add_child(world)
	world.set_process(false)
	world.set_physics_process(false)
	await process_frame
	await physics_frame

	world.core_repaired = true
	world.core_energy = 6
	world.combat_controller.restore_durable_state(
		73,
		{"state": "hostile", "enemy_health": 40}
	)
	world.catalyst_count = 4
	world.pocket.add(SliceWorld.ITEM_PART, 5)
	world.core_storage.add(SliceWorld.ITEM_CRYSTAL, 8)
	world.core_storage.add(SliceWorld.ITEM_CATALYST, 2)

	_spawn_floor_rect(world, Vector2i(34, 7), Vector2i(3, 3))
	_spawn_floor_rect(world, Vector2i(28, 7), Vector2i(2, 2))
	for cell in [Vector2i(25, 10), Vector2i(31, 10), Vector2i(37, 10)]:
		world._spawn_building(
			SliceBuildingCatalog.find(SliceBuildingCatalog.FLOOR_ID),
			"",
			cell,
			0,
			{}
		)
	var relay_one := world._spawn_building(
		SliceBuildingCatalog.find(SliceBuildingCatalog.POWER_RELAY_ID),
		"",
		Vector2i(25, 10),
		0,
		{}
	)
	var relay_two := world._spawn_building(
		SliceBuildingCatalog.find(SliceBuildingCatalog.POWER_RELAY_ID),
		"",
		Vector2i(31, 10),
		0,
		{}
	)
	var relay_three := world._spawn_building(
		SliceBuildingCatalog.find(SliceBuildingCatalog.POWER_RELAY_ID),
		"",
		Vector2i(37, 10),
		0,
		{}
	)
	var reactor := world._spawn_building(
		SliceBuildingCatalog.find(SliceBuildingCatalog.REACTOR_ID),
		"",
		Vector2i(34, 7),
		2,
		{
			"input_inventory": {
				"capacity": SliceReactor.INPUT_CAPACITY,
				"contents": {SliceWorld.ITEM_CRYSTAL: 2},
			},
			"output_inventory": {
				"capacity": SliceReactor.OUTPUT_CAPACITY,
				"contents": {},
			},
			"processing": true,
			"production_progress": 6.25,
		}
	) as SliceReactor
	var storage := world._spawn_building(
		SliceBuildingCatalog.find(SliceBuildingCatalog.STORAGE_ID),
		"",
		Vector2i(28, 7),
		3,
		{}
	) as SliceStorage
	var collector := world._spawn_building(
		SliceBuildingCatalog.find(SliceBuildingCatalog.COLLECTOR_ID),
		"",
		Vector2i(40, 10),
		0,
		{"buffer": 4, "production_progress": 5.5}
	) as SliceCollector
	world._spawn_building(
		SliceBuildingCatalog.find(SliceBuildingCatalog.FLOOR_ID),
		"",
		Vector2i(20, 5),
		0,
		{}
	)
	var conveyor := world._spawn_building(
		SliceBuildingCatalog.find(SliceBuildingCatalog.CONVEYOR_ID),
		"",
		Vector2i(20, 5),
		1,
		{
			"cargo": {
				"item_id": SliceWorld.ITEM_CRYSTAL,
				"progress": 0.375,
			},
			"merge_cursor": 2,
		}
	) as SliceConveyor
	storage.inventory.add(SliceWorld.ITEM_PART, 3)
	world._rebuild_power_grid()
	var saved_next_serial := world._next_building_serial
	var relay_ids := [
		relay_one.instance_id,
		relay_two.instance_id,
		relay_three.instance_id,
	]
	var reactor_id := reactor.instance_id
	var storage_id := storage.instance_id
	var collector_id := collector.instance_id
	var conveyor_id := conveyor.instance_id
	_expect_equal(collector.powered, true, "pre-save collector is powered")
	world._autosave()

	var raw_save := _read_json(save_dir.path_join("slice_world.json"))
	_expect_equal(
		int(raw_save.get("save_schema_version", 0)),
		SliceSaveService.SAVE_SCHEMA_VERSION,
		"schema 7 is written"
	)
	_expect_equal(raw_save.has("collectors"), false, "legacy collectors key is absent")
	_expect_equal(
		raw_save.has("catalyst_count"),
		false,
		"schema 7 omits legacy catalyst truth"
	)
	_expect_equal(
		raw_save.has("reactor_active"),
		false,
		"schema 7 omits legacy reactor activation"
	)
	_expect_equal(
		int(raw_save.get("player_health", 0)),
		73,
		"schema 7 writes player health"
	)
	var saved_encounter: Dictionary = raw_save.get("field_encounter", {})
	_expect_equal(
		String(saved_encounter.get("state", "")),
		"hostile",
		"schema 7 writes encounter state"
	)
	_expect_equal(
		int(saved_encounter.get("enemy_health", 0)),
		40,
		"schema 7 writes enemy health"
	)
	_expect_equal(
		int(raw_save.get("next_building_serial", 0)),
		saved_next_serial,
		"next serial is written"
	)
	for entry in raw_save.get("buildings", []):
		_expect_equal(entry.has("powered"), false, "powered state is not serialized")
		_expect_equal(entry.has("neighbors"), false, "graph edges are not serialized")
		if String(entry.get("instance_id", "")) == collector_id:
			_expect_equal(
				float(entry["state"]["production_progress"]),
				5.5,
				"collector partial tick is written exactly"
			)
			entry["state"]["production_progress"] = 6.5
		if String(entry.get("instance_id", "")) == reactor_id:
			_expect_equal(
				(entry["state"] as Dictionary).keys().size(),
				4,
				"reactor writes exactly four state fields"
			)
			_expect_equal(
				bool(entry["state"]["processing"]),
				true,
				"reactor processing state is written"
			)
			_expect_equal(
				float(entry["state"]["production_progress"]),
				6.25,
				"reactor retained progress is written exactly"
			)
		if String(entry.get("instance_id", "")) == conveyor_id:
			_expect_equal(
				float(entry["state"]["cargo"]["progress"]),
				0.375,
				"conveyor cargo progress is written exactly"
			)
			_expect_equal(
				int(entry["state"]["merge_cursor"]),
				2,
				"conveyor merge cursor is written exactly"
			)
	_write_json(save_dir.path_join("slice_world.json"), raw_save)

	world.free()
	await process_frame
	var loaded_world := SliceWorldScene.instantiate() as SliceWorld
	loaded_world.save_service = service
	loaded_world.startup_load = true
	loaded_world.set_process(false)
	loaded_world.set_physics_process(false)
	root.add_child(loaded_world)
	loaded_world.set_process(false)
	loaded_world.set_physics_process(false)
	await process_frame
	await physics_frame

	_expect_equal(
		loaded_world._building_instances.size(),
		24,
		"all floors and facilities restore"
	)
	_expect_equal(
		loaded_world._next_building_serial,
		saved_next_serial,
		"next serial restores exactly"
	)
	_expect_equal(loaded_world.core_energy, 6, "core energy restores")
	_expect_equal(
		loaded_world.catalyst_count,
		0,
		"legacy global catalyst is not restored"
	)
	_expect_equal(
		loaded_world.pocket.count(SliceWorld.ITEM_PART),
		5,
		"pocket inventory restores"
	)
	_expect_equal(
		loaded_world.core_storage.count(SliceWorld.ITEM_CRYSTAL),
		8,
		"core storage restores"
	)
	_expect_equal(
		loaded_world.core_storage.count(SliceWorld.ITEM_CATALYST),
		2,
		"core storage is the schema 7 catalyst truth"
	)
	_expect_equal(
		loaded_world.combat_controller.health,
		73,
		"player health restores"
	)
	_expect_equal(
		loaded_world.combat_controller.encounter_state,
		"hostile",
		"hostile encounter restores"
	)
	_expect_equal(
		loaded_world.combat_controller.field_enemy.health,
		40,
		"enemy health restores"
	)
	for relay_id in relay_ids:
		var loaded_relay := _find_by_id(loaded_world, String(relay_id))
		_expect_equal(loaded_relay != null, true, "%s restores" % relay_id)
		if loaded_relay != null:
			_expect_equal(loaded_relay.powered, true, "%s power is re-derived" % relay_id)
	var loaded_reactor := _find_by_id(
		loaded_world, reactor_id
	) as SliceReactor
	_expect_equal(loaded_reactor.building_rotation, 2, "reactor rotation restores")
	_expect_equal(loaded_reactor.powered, true, "reactor power is re-derived")
	_expect_equal(loaded_reactor.processing, true, "reactor processing restores")
	_expect_equal(
		loaded_reactor.input_inventory.count(SliceWorld.ITEM_CRYSTAL),
		2,
		"reactor queued input restores"
	)
	_expect_equal(
		loaded_reactor.output_inventory.is_empty(),
		true,
		"reactor empty output restores"
	)
	_expect_equal(
		loaded_reactor.production_progress,
		6.25,
		"reactor retained progress restores"
	)
	var loaded_storage := _find_by_id(loaded_world, storage_id) as SliceStorage
	_expect_equal(
		loaded_storage.inventory.count(SliceWorld.ITEM_PART),
		3,
		"storage inventory restores"
	)
	var loaded_collector := _find_by_id(
		loaded_world, collector_id
	) as SliceCollector
	_expect_equal(loaded_collector.buffer, 4, "collector buffer restores")
	_expect_equal(
		loaded_collector.production_progress,
		SliceWorld.COLLECTOR_PRODUCE_INTERVAL,
		"legacy collector progress clamps to the shorter current cycle"
	)
	_expect_equal(loaded_collector.powered, true, "collector power is re-derived")
	loaded_world._tick_production(0.1)
	_expect_equal(
		loaded_collector.buffer,
		5,
		"legacy collector progress settles one completed current cycle"
	)
	_expect_equal(
		is_equal_approx(loaded_collector.production_progress, 0.1),
		true,
		"legacy collector progress continues inside the current cycle"
	)
	var loaded_conveyor := _find_by_id(
		loaded_world, conveyor_id
	) as SliceConveyor
	_expect_equal(
		loaded_conveyor.cargo_item_id,
		SliceWorld.ITEM_CRYSTAL,
		"conveyor cargo item restores"
	)
	_expect_equal(
		loaded_conveyor.cargo_progress,
		0.375,
		"conveyor cargo progress restores"
	)
	_expect_equal(
		loaded_conveyor.merge_cursor,
		2,
		"conveyor merge cursor restores"
	)

	var next_instance := loaded_world._spawn_building(
		SliceBuildingCatalog.find(SliceBuildingCatalog.FLOOR_ID),
		"",
		Vector2i(5, 5),
		0,
		{}
	)
	_expect_equal(
		next_instance.instance_id,
		"building-%06d" % saved_next_serial,
		"post-load allocation continues without id collision"
	)
	loaded_world.free()


func _legacy_save_data(version: int) -> Dictionary:
	return {
		"save_schema_version": version,
		"game_version": "legacy",
		"updated_at": "2026-07-25T00:00:00",
		"pocket": {
			"capacity": SliceWorld.POCKET_CAPACITY,
			"contents": {SliceWorld.ITEM_CRYSTAL: 2},
		},
		"catalyst_count": 1,
		"core_repaired": true,
		"core_energy": 2,
		"reactor_active": false,
		"harvested_clusters": [],
		"collectors": [
			{"cell": [40, 10], "buffer": 1},
			{"cell": [44, 10], "buffer": 3},
		],
		"carrying_collector": false,
		"player_x": SliceWorld.START_SPAWN.x,
		"player_y": SliceWorld.START_SPAWN.y,
	}


func _empty_runtime_state(crystal_count: int) -> Dictionary:
	return {
		"pocket": {
			"capacity": SliceWorld.POCKET_CAPACITY,
			"contents": {SliceWorld.ITEM_CRYSTAL: crystal_count},
		},
		"core_storage": {
			"capacity": SliceWorld.CORE_STORAGE_CAPACITY,
			"contents": {},
		},
		"buildings": [],
		"next_building_serial": 1,
	}


func _building_entry(
	instance_id: String,
	building_id: String,
	origin_cell: Vector2i,
	rotation: int,
	state: Dictionary
) -> Dictionary:
	return {
		"instance_id": instance_id,
		"building_id": building_id,
		"origin_cell": [origin_cell.x, origin_cell.y],
		"rotation": rotation,
		"state": state,
	}


func _empty_reactor_state() -> Dictionary:
	return {
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


func _reactor_floor_entries(
	origin: Vector2i,
	start_serial: int
) -> Array:
	var entries: Array = []
	var serial := start_serial
	for y in range(3):
		for x in range(3):
			entries.append(_building_entry(
				"building-%06d" % serial,
				SliceBuildingCatalog.FLOOR_ID,
				origin + Vector2i(x, y),
				0,
				{}
			))
			serial += 1
	return entries


func _spawn_floor_rect(
	world: SliceWorld,
	origin: Vector2i,
	size: Vector2i
) -> void:
	var definition := SliceBuildingCatalog.find(SliceBuildingCatalog.FLOOR_ID)
	for y in range(size.y):
		for x in range(size.x):
			world._spawn_building(
				definition, "", origin + Vector2i(x, y), 0, {}
			)


func _find_by_id(
	world: SliceWorld,
	instance_id: String
) -> SliceBuildingInstance:
	for instance in world._building_instances:
		if instance.instance_id == instance_id:
			return instance
	return null


func _expect_codec_success(buildings: Array, next_serial: int, label: String) -> void:
	_expect_success(
		SliceBuildingSaveCodec.validate_schema_six(buildings, next_serial),
		label
	)


func _expect_codec_failure(
	buildings: Array,
	next_serial: int,
	fragment: String,
	label: String
) -> void:
	_expect_failure(
		SliceBuildingSaveCodec.validate_schema_six(buildings, next_serial),
		fragment,
		label
	)


func _expect_success(result: Dictionary, label: String) -> void:
	_assertion_count += 1
	if not bool(result.get("success", false)):
		failures.append("%s should succeed: %s" % [label, result.get("message", "")])


func _expect_failure(
	result: Dictionary,
	message_fragment: String,
	label: String
) -> void:
	_assertion_count += 1
	if bool(result.get("success", false)):
		failures.append("%s should fail" % label)
		return
	if not String(result.get("message", "")).contains(message_fragment):
		failures.append(
			"%s should mention %s, got %s"
			% [label, message_fragment, result.get("message", "")]
		)


func _expect_equal(actual, expected, label: String) -> void:
	_assertion_count += 1
	if actual != expected:
		failures.append("%s: expected %s, got %s" % [label, expected, actual])


func _new_save_dir(label: String) -> String:
	var save_dir := (
		"/private/tmp/radishcatalyst-l3-package4-%s-%d"
		% [label, Time.get_ticks_usec()]
	)
	_save_dirs.append(save_dir)
	DirAccess.make_dir_recursive_absolute(save_dir)
	return save_dir


func _write_json(path: String, data: Dictionary) -> void:
	_write_text(path, JSON.stringify(data, "\t"))


func _write_text(path: String, content: String) -> void:
	var file := FileAccess.open(path, FileAccess.WRITE)
	if file == null:
		failures.append("could not write %s" % path)
		return
	file.store_string(content)
	file.close()


func _read_json(path: String) -> Dictionary:
	var file := FileAccess.open(path, FileAccess.READ)
	if file == null:
		failures.append("could not read %s" % path)
		return {}
	var parsed = JSON.parse_string(file.get_as_text())
	file.close()
	if not (parsed is Dictionary):
		failures.append("%s should contain a JSON object" % path)
		return {}
	return parsed


func _cleanup() -> void:
	for save_dir in _save_dirs:
		for filename in [
			"slice_world.json",
			"slice_world.bak.json",
			"slice_world.tmp.json",
		]:
			var path := save_dir.path_join(filename)
			if FileAccess.file_exists(path):
				DirAccess.remove_absolute(path)
		if DirAccess.dir_exists_absolute(save_dir):
			DirAccess.remove_absolute(save_dir)
