extends SceneTree

const SliceWorldScene := preload("res://scenes/slice/SliceWorld.tscn")

var failures: Array[String] = []
var _assertion_count := 0
var _test_root := ""


func _init() -> void:
	call_deferred("_execute")


func _execute() -> void:
	_test_root = "user://slice-playtest-remediation-package2-%d" % Time.get_ticks_usec()
	_check_candidate_parameters_and_manufacturing_plan()
	_check_collector_buffer_contract()
	await _check_world_equipment_and_schema_ten()
	if failures.is_empty():
		print(
			"Slice playtest remediation package 2 checks passed (%d assertions)."
			% _assertion_count
		)
		_cleanup()
		quit(0)
		return
	for failure in failures:
		push_error(failure)
	_cleanup()
	quit(1)


func _check_candidate_parameters_and_manufacturing_plan() -> void:
	_expect_equal(
		int(SliceRecipes.find("floor")["output_count"]),
		8,
		"one floor batch produces eight kits"
	)
	_expect_equal(
		SlicePowerGrid.RELAY_LINK_RANGE_CELLS,
		8.0,
		"relay link range uses the package-2 candidate"
	)
	_expect_equal(
		SlicePowerGrid.DEVICE_SUPPLY_RANGE_CELLS,
		6.0,
		"device supply range uses the package-2 candidate"
	)

	var inventory := Inventory.new(SliceInventoryProfiles.category_pocket())
	inventory.add(SliceWorld.ITEM_CRYSTAL, 6)
	var collector_recipe := SliceRecipes.find("collector")
	var plan := SliceCraftingPlan.analyze(collector_recipe, inventory)
	_expect_equal(
		plan["direct_cost"],
		{SliceWorld.ITEM_PART: 2},
		"manufacturing plan keeps direct recipe cost"
	)
	_expect_equal(
		plan["raw_cost"],
		{SliceWorld.ITEM_CRYSTAL: 6},
		"manufacturing plan expands parts to raw crystals"
	)
	_expect_equal(
		int(plan["current_craftable"]),
		0,
		"collector is not directly craftable without parts"
	)
	_expect_equal(
		int(plan["dependency_supported"]),
		1,
		"six crystals support one collector through part dependencies"
	)
	_expect_equal(
		int(plan["support_floor_maximum"]),
		0,
		"crystal-ground collector needs no industrial support floor"
	)
	var summary := SliceCraftingPlan.summary_text(plan)
	_expect(
		summary.contains("完整依赖可支撑 ×1")
		and summary.contains("基础折算 晶体 ×6"),
		"manufacturing summary exposes dependency evidence"
	)
	var reactor_inventory := Inventory.new(
		SliceInventoryProfiles.category_pocket()
	)
	reactor_inventory.add(SliceWorld.ITEM_CRYSTAL, 12)
	var reactor_plan := SliceCraftingPlan.analyze(
		SliceRecipes.find("reactor"), reactor_inventory
	)
	_expect_equal(
		int(reactor_plan["support_floor_maximum"]),
		9,
		"reactor diagnostic exposes its nine-cell support maximum"
	)
	_expect(
		SliceCraftingPlan.summary_text(reactor_plan).contains(
			"补板最多 9 格"
		),
		"manufacturing summary renders the support-floor maximum"
	)

	var part_crystal_cost := int(
		SliceRecipes.find("part")["cost"][SliceWorld.ITEM_CRYSTAL]
	)
	var candidate_bootstrap_cost := (
		CoreRepairSite.REPAIR_PART_COST * part_crystal_cost
		+ 2 * int(SliceRecipes.find("power_relay")["cost"][SliceWorld.ITEM_PART])
		* part_crystal_cost
		+ int(collector_recipe["cost"][SliceWorld.ITEM_PART]) * part_crystal_cost
		+ int(SliceRecipes.find("floor")["cost"][SliceWorld.ITEM_CRYSTAL])
	)
	_expect_equal(
		candidate_bootstrap_cost,
		22,
		"two-relay candidate reaches the first powered collector for 22 crystals"
	)
	_expect_equal(
		25 - candidate_bootstrap_cost,
		3,
		"current bootstrap field leaves three crystals after the candidate route"
	)


func _check_collector_buffer_contract() -> void:
	_expect_equal(
		SliceCollector.BUFFER_CAP,
		50,
		"collector buffer capacity is unified at fifty"
	)
	var collector := SliceCollector.new()
	collector.produce(80)
	_expect_equal(collector.buffer, 50, "collector runtime clamps at fifty")
	collector.free()

	var entry := {
		"instance_id": "building-000001",
		"building_id": SliceBuildingCatalog.COLLECTOR_ID,
		"origin_cell": [60, 10],
		"rotation": 0,
		"state": {"buffer": 50, "production_progress": 0.0},
	}
	_expect_success(
		SliceBuildingSaveCodec.validate_schema_eight([entry], 2),
		"schema accepts a full fifty-crystal collector"
	)
	var overflow := entry.duplicate(true)
	overflow["state"]["buffer"] = 51
	_expect_failure(
		SliceBuildingSaveCodec.validate_schema_eight([overflow], 2),
		"buffer",
		"schema rejects collector overflow above fifty"
	)


func _check_world_equipment_and_schema_ten() -> void:
	var world_dir := _test_root.path_join("world")
	var service := SliceSaveService.new(world_dir)
	var world := SliceWorldScene.instantiate() as SliceWorld
	world.save_service = service
	root.add_child(world)
	await process_frame

	world.pocket.add(SliceWorld.ITEM_CRYSTAL, 1)
	world.inventory_changed.emit()
	var toggle := InputEventAction.new()
	toggle.action = "craft_menu"
	toggle.pressed = true
	world._craft_panel._unhandled_input(toggle)
	world._craft_panel.select_recipe("floor")
	world._craft_panel._on_detail_craft_pressed()
	_expect_equal(
		world._craft_panel.is_open(),
		true,
		"crafting keeps the manufacturing panel open"
	)
	_expect_equal(
		world.selected_building_id(),
		"",
		"crafting does not implicitly enter placement"
	)
	_expect_equal(
		world.pocket.count(SliceWorld.ITEM_FLOOR_KIT),
		8,
		"world crafting grants the eight-kit floor batch"
	)
	_expect(
		world._craft_panel._detail_state.text.contains("当前可制作"),
		"selected recipe renders the manufacturing diagnostic"
	)
	world._craft_panel.close()

	var hud := world.get_node("SliceHud") as SliceHud
	var character := hud.character_panel
	_expect_equal(
		character.get_node("OpenButton").visible,
		true,
		"HUD exposes the minimal character-page entry"
	)
	_expect_equal(
		world.combat_controller.equip_weapon(
			SliceCombatController.WEAPON_PULSE_RIFLE
		),
		false,
		"rifle cannot be equipped when it is absent from the pocket"
	)
	world.pocket.add(SliceWorld.ITEM_PULSE_RIFLE, 1)
	world.inventory_changed.emit()
	character.open()
	_expect_equal(character.is_open(), true, "character page opens")
	_expect_equal(paused, true, "character page pauses the world")
	character._rifle_button.emit_signal("pressed")
	_expect_equal(
		world.combat_controller.current_weapon,
		SliceCombatController.WEAPON_PULSE_RIFLE,
		"character-page click equips the owned rifle"
	)
	_expect_equal(
		character._can_drop_weapon(
			Vector2.ZERO,
			{"weapon_id": SliceCombatController.WEAPON_CUTTER}
		),
		true,
		"weapon slot accepts the supported drag payload"
	)
	character._drop_weapon(
		Vector2.ZERO,
		{"weapon_id": SliceCombatController.WEAPON_PULSE_RIFLE}
	)
	character.close()
	_expect_equal(paused, false, "closing the character page resumes the world")

	var saved_rifle := _read_json(service.save_file_path())
	_expect_equal(
		int(saved_rifle.get("save_schema_version", 0)),
		10,
		"equipment selection publishes schema ten"
	)
	_expect_equal(
		String(saved_rifle.get("equipped_weapon_id", "")),
		SliceCombatController.WEAPON_PULSE_RIFLE,
		"schema ten persists the selected rifle"
	)
	_expect_schema_ten(saved_rifle, "persisted rifle save")

	world.pocket.remove(SliceWorld.ITEM_PULSE_RIFLE, 1)
	world.inventory_changed.emit()
	_expect_equal(
		world.combat_controller.current_weapon,
		SliceCombatController.WEAPON_CUTTER,
		"moving the rifle out of the pocket falls back to the cutter"
	)
	var saved_fallback := _read_json(service.save_file_path())
	_expect_equal(
		String(saved_fallback.get("equipped_weapon_id", "")),
		SliceCombatController.WEAPON_CUTTER,
		"automatic cutter fallback is persisted immediately"
	)

	var legacy := saved_rifle.duplicate(true)
	legacy.erase("equipped_weapon_id")
	legacy["save_schema_version"] = 9
	legacy["game_version"] = "prototype-slice-09"
	var legacy_service := SliceSaveService.new(_test_root.path_join("schema-nine"))
	_write_json(legacy_service.save_file_path(), legacy)
	var load_result := legacy_service.load_state()
	_expect_success(load_result, "schema nine equipment migration loads")
	if bool(load_result.get("success", false)):
		var migrated: Dictionary = load_result["data"]
		_expect_equal(
			migrated["equipped_weapon_id"],
			SliceCombatController.WEAPON_CUTTER,
			"schema nine migration defaults to the cutter"
		)
		_expect_equal(
			migrated["first_journey_flags"],
			saved_rifle["first_journey_flags"],
			"schema nine migration preserves first-journey flags"
		)
		_expect_equal(
			migrated["explored_map_bits"],
			saved_rifle["explored_map_bits"],
			"schema nine migration preserves exploration bits"
		)
		_expect_success(
			legacy_service.commit_loaded_state(
				migrated, load_result["load_context"]
			),
			"schema nine migration publishes schema ten"
		)
		_expect_schema_ten(
			_read_json(legacy_service.save_file_path()),
			"schema nine publication"
		)
		var invalid_rifle := migrated.duplicate(true)
		invalid_rifle["equipped_weapon_id"] = (
			SliceCombatController.WEAPON_PULSE_RIFLE
		)
		invalid_rifle["pocket"]["contents"].erase(
			SliceWorld.ITEM_PULSE_RIFLE
		)
		_expect_failure(
			legacy_service.save_state(invalid_rifle),
			"步枪必须位于随身背包",
			"schema ten rejects an equipped rifle outside the pocket"
		)

	world.free()


func _expect_schema_ten(data: Dictionary, label: String) -> void:
	_assertion_count += 1
	for failure in SliceSaveSchemaTenContract.validate(data):
		failures.append("%s: %s" % [label, failure])


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
	DirAccess.make_dir_recursive_absolute(
		ProjectSettings.globalize_path(path.get_base_dir())
	)
	var file := FileAccess.open(path, FileAccess.WRITE)
	if file == null:
		failures.append("could not write %s" % path)
		return
	file.store_string(JSON.stringify(data, "\t"))
	file.close()


func _cleanup() -> void:
	_remove_tree(ProjectSettings.globalize_path(_test_root))


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
	expected_message: String,
	label: String
) -> void:
	_expect_equal(bool(result.get("success", false)), false, label)
	_expect(
		String(result.get("message", "")).contains(expected_message),
		"%s reports %s" % [label, expected_message]
	)


func _expect(condition: bool, label: String) -> void:
	_assertion_count += 1
	if not condition:
		failures.append(label)


func _expect_equal(actual, expected, label: String) -> void:
	_assertion_count += 1
	if actual != expected:
		failures.append(
			"%s: expected %s, got %s" % [label, expected, actual]
		)
