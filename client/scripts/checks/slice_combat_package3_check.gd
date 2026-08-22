extends SceneTree

const SliceWorldScene := preload("res://scenes/slice/SliceWorld.tscn")

var failures: Array[String] = []
var assertion_count := 0
var _test_root := ""


func _init() -> void:
	call_deferred("_execute")


func _execute() -> void:
	_test_root = SliceCheckPaths.check_run("combat-package3")
	_check_schema_seven_contract()
	await _check_restart_and_delivery_matrix()
	if failures.is_empty():
		print(
			"Slice combat package 3 checks passed (%d assertions)."
			% assertion_count
		)
		_remove_tree(_test_root)
		quit(0)
		return
	for failure in failures:
		push_error(failure)
	_remove_tree(_test_root)
	quit(1)


func _check_schema_seven_contract() -> void:
	var contract_dir := _test_root.path_join("contract")
	var service := SliceSaveService.new(contract_dir)
	for encounter_state in SliceSaveService.ENCOUNTER_STATES:
		var state := _base_state(2)
		state["player_health"] = 120 if encounter_state == "delivered" else 100
		state["field_encounter"] = {
			"state": encounter_state,
			"enemy_health": (
				SliceFieldEnemy.MAX_HEALTH
				if encounter_state in ["locked", "hostile"]
				else 0
			),
		}
		if encounter_state == "locked":
			state["core_energy"] = 0
		_expect_success(
			service.save_state(state),
			"schema 7 accepts %s" % encounter_state
		)

	var invalid_health := _base_state(2)
	invalid_health["player_health"] = 101
	_expect_failure(
		service.save_state(invalid_health),
		"1–100",
		"undelivered health cannot exceed one hundred"
	)
	var invalid_enemy := _base_state(2)
	invalid_enemy["field_encounter"]["enemy_health"] = 0
	_expect_failure(
		service.save_state(invalid_enemy),
		"1–60",
		"hostile encounter requires a living enemy"
	)
	var invalid_carried := _base_state(2)
	invalid_carried["field_encounter"] = {
		"state": "carried",
		"enemy_health": 1,
	}
	_expect_failure(
		service.save_state(invalid_carried),
		"必须为 0",
		"carried encounter rejects a living enemy"
	)
	var invalid_fields := _base_state(2)
	invalid_fields["field_encounter"]["sample_carried"] = true
	_expect_failure(
		service.save_state(invalid_fields),
		"必须且只能包含",
		"encounter rejects parallel boolean truth"
	)
	var invalid_locked := _base_state(2)
	invalid_locked["field_encounter"] = {
		"state": "locked",
		"enemy_health": SliceFieldEnemy.MAX_HEALTH,
	}
	_expect_failure(
		service.save_state(invalid_locked),
		"已充能核心不能",
		"charged core rejects locked encounter"
	)

	var migration_dir := _test_root.path_join("schema6")
	var migration_service := SliceSaveService.new(migration_dir)
	_expect_success(
		migration_service.save_state(_base_state(2)),
		"schema 7 migration fixture writes"
	)
	var migration_path := migration_service.save_file_path()
	var schema_six := _read_json(migration_path)
	schema_six["save_schema_version"] = 6
	schema_six["game_version"] = "prototype-slice-06"
	schema_six.erase("player_health")
	schema_six.erase("field_encounter")
	_write_json(migration_path, schema_six)
	var migrated := migration_service.load_state()
	_expect_success(migrated, "schema 6 migrates to combat defaults")
	if bool(migrated.get("success", false)):
		var data: Dictionary = migrated["data"]
		_expect_equal(data["player_health"], 100, "schema 6 defaults health")
		_expect_equal(
			data["field_encounter"],
			{
				"state": "hostile",
				"enemy_health": SliceFieldEnemy.MAX_HEALTH,
			},
			"charged schema 6 defaults to a fresh hostile encounter"
		)


func _check_restart_and_delivery_matrix() -> void:
	var world_dir := _test_root.path_join("world_package3")
	var service := SliceSaveService.for_world(
		world_dir,
		"world_package3"
	)
	var world := await _new_world(service, false)
	world.core_repaired = true
	world.core_energy = SliceWorld.CORE_CHARGE_TARGET
	world.combat_controller.restore_durable_state(
		80,
		{"state": "hostile", "enemy_health": 40}
	)
	_expect_equal(world._autosave(), true, "hostile checkpoint saves")
	_free_world(world)

	world = await _new_world(service, true)
	var controller := world.combat_controller
	_expect_equal(controller.health, 80, "hostile restart restores player health")
	_expect_equal(
		controller.field_enemy.health,
		40,
		"hostile restart restores enemy health"
	)
	_expect_equal(
		controller.field_enemy.state,
		"alert",
		"hostile restart clears partial AI phase"
	)
	_expect_equal(
		controller.receive_damage(20),
		true,
		"nonlethal player damage is accepted"
	)
	_expect_equal(
		int(_read_json(service.save_file_path()).get("player_health", 0)),
		60,
		"nonlethal player damage autosaves"
	)

	controller.restore_durable_state(
		20,
		{"state": "hostile", "enemy_health": 20}
	)
	_expect_equal(controller.receive_damage(20), true, "lethal damage evacuates")
	var evacuated := _read_json(service.save_file_path())
	var evacuated_encounter: Dictionary = evacuated.get("field_encounter", {})
	_expect_equal(
		String(evacuated_encounter.get("state", "")),
		"hostile",
		"evacuation keeps the hostile encounter"
	)
	_expect_equal(
		int(evacuated_encounter.get("enemy_health", 0)),
		SliceFieldEnemy.MAX_HEALTH,
		"evacuation autosaves a reset live enemy"
	)
	_expect_equal(
		int(evacuated.get("player_health", 0)),
		50,
		"evacuation autosaves half health"
	)
	_expect_equal(
		Vector2(
			float(evacuated.get("player_x", 0.0)),
			float(evacuated.get("player_y", 0.0))
		),
		SliceCombatController.EVACUATION_POSITION,
		"evacuation autosaves the core-side position"
	)
	_free_world(world)

	world = await _new_world(service, true)
	controller = world.combat_controller
	_expect_equal(controller.health, 50, "evacuated health survives restart")
	_expect_equal(
		controller.field_enemy.health,
		SliceFieldEnemy.MAX_HEALTH,
		"evacuated enemy remains full after restart"
	)
	controller.field_enemy.take_damage(SliceFieldEnemy.MAX_HEALTH)
	var dropped := _read_json(service.save_file_path())
	_expect_equal(
		String(dropped.get("field_encounter", {}).get("state", "")),
		"dropped",
		"defeat autosaves dropped state"
	)
	_expect_equal(controller.critical_sample != null, true, "defeat spawns sample")
	_free_world(world)

	world = await _new_world(service, true)
	controller = world.combat_controller
	_expect_equal(controller.encounter_state, "dropped", "dropped state restarts")
	_expect_equal(controller.critical_sample != null, true, "dropped sample restarts")
	if controller.critical_sample != null:
		_expect_equal(
			controller.critical_sample.position,
			SliceCombatController.FIELD_ENEMY_ANCHOR + Vector2(22, 2),
			"dropped sample uses its fixed durable position"
		)
		_expect_equal(
			controller.collect_critical_sample(controller.critical_sample),
			true,
			"sample pickup enters carried state"
		)
	await process_frame
	_expect_equal(
		String(
			_read_json(service.save_file_path())
			.get("field_encounter", {})
			.get("state", "")
		),
		"carried",
		"sample pickup autosaves carried state"
	)

	controller.health = 20
	_expect_equal(
		controller.receive_damage(20),
		true,
		"carried state can still evacuate"
	)
	_expect_equal(controller.encounter_state, "carried", "evacuation keeps sample")
	_free_world(world)

	world = await _new_world(service, true)
	controller = world.combat_controller
	_expect_equal(controller.encounter_state, "carried", "carried state restarts")
	_expect_equal(controller.health, 50, "carried evacuation health restarts")
	_expect_equal(controller.critical_sample, null, "carried sample does not respawn")
	var repair_site := world.get_node(
		"SliceMap/World/OutpostCoreDamaged/RepairSite"
	) as CoreRepairSite
	_expect_equal(
		repair_site.get_prompt(world),
		"按 E 交付晶腺样本（安装抗蚀内衬）",
		"core interaction prioritizes sample delivery"
	)
	repair_site.try_interact(world)
	_expect_equal(controller.encounter_state, "delivered", "core accepts sample")
	_expect_equal(controller.max_health, 120, "lining raises maximum health")
	_expect_equal(controller.health, 120, "delivery restores full health")
	_expect_equal(
		controller.encounter_goal_text(),
		"抗蚀内衬已安装｜最大生命 120",
		"HUD exposes the permanent reward"
	)
	var delivered := _read_json(service.save_file_path())
	var delivered_encounter: Dictionary = delivered.get("field_encounter", {})
	_expect_equal(
		String(delivered_encounter.get("state", "")),
		"delivered",
		"delivery autosaves terminal encounter state"
	)
	_expect_equal(
		int(delivered_encounter.get("enemy_health", -1)),
		0,
		"delivered encounter has no live enemy"
	)
	var metadata := _read_json(world_dir.path_join("metadata.json"))
	_expect_equal(
		String(metadata.get("field_encounter_state", "")),
		"delivered",
		"world metadata exposes delivered progress"
	)
	_expect_equal(
		int(metadata.get("player_health", 0)),
		120,
		"world metadata exposes delivered health"
	)
	_free_world(world)

	world = await _new_world(service, true)
	controller = world.combat_controller
	_expect_equal(controller.encounter_state, "delivered", "delivered state restarts")
	_expect_equal(controller.max_health, 120, "delivered max health restarts")
	_expect_equal(controller.health, 120, "delivered health restarts")
	_expect_equal(controller.critical_sample, null, "delivered sample stays absent")
	_expect_equal(
		controller.field_enemy.state,
		"defeated",
		"delivered enemy cannot respawn"
	)
	_expect_equal(
		service.get_summary().get("details", "").contains("外勤内衬已安装"),
		true,
		"save summary exposes the completed field loop"
	)
	_free_world(world)


func _new_world(
	service: SliceSaveService,
	startup_load: bool
) -> SliceWorld:
	var world := SliceWorldScene.instantiate() as SliceWorld
	world.save_service = service
	world.startup_load = startup_load
	world.set_process(false)
	world.set_physics_process(false)
	root.add_child(world)
	await process_frame
	await physics_frame
	world.combat_controller.set_physics_process(false)
	world.combat_controller.field_enemy.set_physics_process(false)
	world.player.set_physics_process(false)
	return world


func _free_world(world: SliceWorld) -> void:
	if world != null:
		world.free()


func _base_state(core_energy: int) -> Dictionary:
	return {
		"pocket": {
			"capacity": SliceWorld.POCKET_CAPACITY,
			"contents": {},
		},
		"core_storage": {
			"capacity": SliceWorld.CORE_STORAGE_CAPACITY,
			"contents": {},
		},
		"core_repaired": true,
		"core_energy": core_energy,
		"harvested_clusters": [],
		"buildings": [],
		"next_building_serial": 1,
		"player_x": SliceWorld.START_SPAWN.x,
		"player_y": SliceWorld.START_SPAWN.y,
		"player_health": 100,
		"field_encounter": {
			"state": "hostile" if core_energy >= SliceWorld.CORE_CHARGE_TARGET else "locked",
			"enemy_health": SliceFieldEnemy.MAX_HEALTH,
		},
		"first_journey_flags": {
			"terminal_opened": true,
			"part_recipe_inspected": true,
		},
		"explored_map_bits": SliceExplorationState.default_bits_for_position(
			SliceWorld.START_SPAWN
		),
	}


func _expect_success(result: Dictionary, context: String) -> void:
	assertion_count += 1
	if bool(result.get("success", false)):
		return
	failures.append(
		"%s: %s" % [context, String(result.get("message", ""))]
	)


func _expect_failure(
	result: Dictionary,
	message_fragment: String,
	context: String
) -> void:
	assertion_count += 1
	if bool(result.get("success", false)):
		failures.append("%s should fail" % context)
		return
	if not String(result.get("message", "")).contains(message_fragment):
		failures.append(
			"%s should mention %s, got %s"
			% [context, message_fragment, result.get("message", "")]
		)


func _expect_equal(actual, expected, context: String) -> void:
	assertion_count += 1
	if actual == expected:
		return
	failures.append(
		"%s: expected %s, got %s" % [context, str(expected), str(actual)]
	)


func _read_json(path: String) -> Dictionary:
	var file := FileAccess.open(path, FileAccess.READ)
	if file == null:
		failures.append("could not read %s" % path)
		return {}
	var parsed = JSON.parse_string(file.get_as_text())
	file.close()
	if parsed is Dictionary:
		return parsed
	failures.append("%s should contain a JSON object" % path)
	return {}


func _write_json(path: String, data: Dictionary) -> void:
	var file := FileAccess.open(path, FileAccess.WRITE)
	if file == null:
		failures.append("could not write %s" % path)
		return
	file.store_string(JSON.stringify(data, "\t"))
	file.close()


func _remove_tree(path: String) -> void:
	if not DirAccess.dir_exists_absolute(path):
		return
	var directory := DirAccess.open(path)
	if directory == null:
		return
	directory.list_dir_begin()
	var entry := directory.get_next()
	while not entry.is_empty():
		if entry not in [".", ".."]:
			var child := path.path_join(entry)
			if directory.current_is_dir():
				_remove_tree(child)
			else:
				DirAccess.remove_absolute(child)
		entry = directory.get_next()
	directory.list_dir_end()
	DirAccess.remove_absolute(path)
