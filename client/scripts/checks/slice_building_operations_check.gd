extends SceneTree

const SliceWorldScene := preload("res://scenes/slice/SliceWorld.tscn")

var failures: Array[String] = []
var _save_dir := ""
var _assertion_count := 0


func _init() -> void:
	call_deferred("_execute")


func _execute() -> void:
	await _run_checks()
	if failures.is_empty():
		print(
			"Slice building operations checks passed (%d assertions)."
			% _assertion_count
		)
		_cleanup_save_dir()
		quit(0)
		return
	for failure in failures:
		push_error(failure)
	_cleanup_save_dir()
	quit(1)


func _run_checks() -> void:
	_check_catalog_and_recipes()
	await _check_world_operations()


func _check_catalog_and_recipes() -> void:
	var expected := {
		SliceBuildingCatalog.FLOOR_ID: Vector2i.ONE,
		SliceBuildingCatalog.COLLECTOR_ID: Vector2i(2, 2),
		SliceBuildingCatalog.REACTOR_ID: Vector2i(3, 3),
		SliceBuildingCatalog.POWER_RELAY_ID: Vector2i.ONE,
		SliceBuildingCatalog.CONVEYOR_ID: Vector2i.ONE,
		SliceBuildingCatalog.STORAGE_ID: Vector2i(2, 2),
	}
	_expect_equal(SliceBuildingCatalog.all().size(), 6, "six definitions registered")
	for building_id in expected:
		var definition := SliceBuildingCatalog.find(String(building_id))
		_expect_equal(definition != null, true, "%s definition exists" % building_id)
		_expect_equal(
			definition.footprint,
			expected[building_id],
			"%s footprint" % building_id
		)

	var reactor := SliceBuildingCatalog.find(SliceBuildingCatalog.REACTOR_ID)
	var conveyor := SliceBuildingCatalog.find(SliceBuildingCatalog.CONVEYOR_ID)
	var storage := SliceBuildingCatalog.find(SliceBuildingCatalog.STORAGE_ID)
	_expect_equal(
		reactor.texture_path_for_rotation(1).ends_with("reactor_right.png"),
		true,
		"reactor rotation selects fixed right frame"
	)
	_expect_equal(
		conveyor.texture_path_for_rotation(2).ends_with("conveyor_down.png"),
		true,
		"conveyor rotation selects fixed down frame"
	)
	_expect_equal(
		storage.texture_path_for_rotation(3).ends_with("storage_left.png"),
		true,
		"storage rotation selects fixed left frame"
	)

	var recipe_expectations := {
		"reactor": [SliceBuildingCatalog.REACTOR_ID, 1, {"part": 4}],
		"power_relay": [SliceBuildingCatalog.POWER_RELAY_ID, 1, {"part": 1}],
		"conveyor": [
			SliceBuildingCatalog.CONVEYOR_ID,
			4,
			{"crystal": 1, "part": 1},
		],
		"storage": [SliceBuildingCatalog.STORAGE_ID, 1, {"part": 2}],
	}
	for recipe_id in recipe_expectations:
		var recipe := SliceRecipes.find(String(recipe_id))
		var expectation: Array = recipe_expectations[recipe_id]
		_expect_equal(recipe["output"], expectation[0], "%s output id" % recipe_id)
		_expect_equal(
			int(recipe["output_count"]), expectation[1], "%s output count" % recipe_id
		)
		_expect_equal(recipe["cost"], expectation[2], "%s cost" % recipe_id)


func _check_world_operations() -> void:
	_save_dir = "/private/tmp/radishcatalyst-l3-package2-%d" % Time.get_ticks_usec()
	var world := SliceWorldScene.instantiate() as SliceWorld
	world.save_service = SliceSaveService.new(_save_dir)
	root.add_child(world)
	await process_frame
	await physics_frame
	world.core_repaired = true
	world._rebuild_power_grid()

	var floor_definition := SliceBuildingCatalog.find(SliceBuildingCatalog.FLOOR_ID)
	_spawn_floor_rect(world, Vector2i(25, 3), Vector2i(3, 3))
	_spawn_floor_rect(world, Vector2i(25, 7), Vector2i(3, 3))
	_spawn_floor_rect(world, Vector2i(22, 7), Vector2i.ONE)
	_spawn_floor_rect(world, Vector2i(31, 3), Vector2i.ONE)
	_spawn_floor_rect(world, Vector2i(33, 3), Vector2i(2, 2))
	var standalone_floor := world._spawn_building(
		floor_definition, "", Vector2i(36, 3), 0, {}
	)

	var missing_floor := world._validate_placement(
		SliceBuildingCatalog.find(SliceBuildingCatalog.REACTOR_ID),
		Vector2i(38, 3),
		0
	)
	_expect_equal(
		String(missing_floor.get("reason", "")),
		"需工业地板",
		"device without complete floor support reports short reason"
	)

	var reactor := _place_device(
		world, SliceBuildingCatalog.REACTOR_ID, Vector2i(25, 3), 1
	)
	var relay := _place_device(
		world, SliceBuildingCatalog.POWER_RELAY_ID, Vector2i(22, 7), 3
	)
	var conveyor := _place_device(
		world, SliceBuildingCatalog.CONVEYOR_ID, Vector2i(31, 3), 1
	)
	var storage := _place_device(
		world, SliceBuildingCatalog.STORAGE_ID, Vector2i(33, 3), 3
	) as SliceStorage
	await physics_frame

	_expect_equal(
		(reactor.get_node("Sprite") as Sprite2D).texture.resource_path.ends_with(
			"reactor_right.png"
		),
		true,
		"placed reactor uses approved right frame"
	)
	_expect_equal(
		(conveyor.get_node("Sprite") as Sprite2D).texture.resource_path.ends_with(
			"conveyor_right.png"
		),
		true,
		"placed conveyor uses approved right frame"
	)
	_expect_equal(
		storage.get_node_or_null("InteractionSite") != null,
		true,
		"generic storage receives shared interaction area"
	)

	var reactor_id := reactor.instance_id
	_expect_equal(
		world.begin_building_adjustment(reactor),
		true,
		"reactor enters adjustment"
	)
	_expect_equal(reactor.visible, false, "adjustment temporarily hides original")
	world.cancel_building_placement()
	await process_frame
	_expect_equal(reactor.visible, true, "Esc restores adjusted building")
	_expect_equal(reactor.origin_cell, Vector2i(25, 3), "cancel restores origin")
	_expect_equal(reactor.instance_id, reactor_id, "cancel preserves stable id")

	_expect_equal(
		world.begin_building_adjustment(reactor),
		true,
		"reactor re-enters adjustment"
	)
	world.rotate_building_placement()
	await process_frame
	await physics_frame
	var moved_validation := world._validate_placement(
		reactor.definition, Vector2i(25, 7), world.selected_building_rotation()
	)
	world._placement.update_target(
		Vector2i(25, 7),
		reactor.definition.block_center(
			Vector2i(25, 7),
			SliceWorld.TILE_SIZE,
			world.selected_building_rotation()
		),
		moved_validation
	)
	_expect_equal(
		bool(moved_validation.get("valid", false)),
		true,
		"adjusted reactor validates on complete floor support"
	)
	_expect_equal(world.try_place_building(), true, "adjustment commits")
	_expect_equal(reactor.origin_cell, Vector2i(25, 7), "adjustment moves origin")
	_expect_equal(reactor.building_rotation, 2, "adjustment commits rotation")
	_expect_equal(reactor.instance_id, reactor_id, "adjustment preserves stable id")
	_expect_equal(
		(reactor.get_node("Sprite") as Sprite2D).texture.resource_path.ends_with(
			"reactor_down.png"
		),
		true,
		"adjustment switches to approved down frame"
	)

	var supporting_floor := _find_building(
		world, SliceBuildingCatalog.FLOOR_ID, Vector2i(25, 7)
	)
	_expect_equal(
		world.adjustment_block_reason(supporting_floor),
		"地板上有设施",
		"supporting floor cannot move"
	)
	_expect_equal(
		world.demolition_block_reason(supporting_floor),
		"地板上有设施",
		"supporting floor cannot be demolished"
	)

	_expect_equal(
		world.begin_building_adjustment(standalone_floor),
		true,
		"unused floor enters adjustment"
	)
	await process_frame
	var floor_move := world._validate_placement(
		floor_definition, Vector2i(37, 3), 0
	)
	world._placement.update_target(
		Vector2i(37, 3),
		floor_definition.block_center(Vector2i(37, 3), SliceWorld.TILE_SIZE, 0),
		floor_move
	)
	_expect_equal(world.try_place_building(), true, "unused floor adjustment commits")
	_expect_equal(
		world._industrial_floor.get_cell_source_id(Vector2i(36, 3)),
		-1,
		"floor adjustment clears old tile"
	)
	_expect_equal(
		world._industrial_floor.get_cell_source_id(Vector2i(37, 3)),
		0,
		"floor adjustment writes new tile"
	)

	storage.inventory.add(SliceWorld.ITEM_CRYSTAL, 1)
	_expect_equal(
		world.demolition_block_reason(storage),
		"先清空储物箱",
		"non-empty storage is demolition-gated"
	)
	storage.inventory.remove(SliceWorld.ITEM_CRYSTAL, 1)
	var storage_kits_before := world.pocket.count(SliceWorld.ITEM_STORAGE_KIT)
	_expect_equal(world.demolish_building(storage), true, "empty storage demolishes")
	_expect_equal(
		world.pocket.count(SliceWorld.ITEM_STORAGE_KIT),
		storage_kits_before + 1,
		"storage demolition returns one kit"
	)

	world.pocket.add(SliceWorld.ITEM_CRYSTAL, world.pocket.free_space())
	_expect_equal(
		world.demolition_block_reason(relay),
		"背包空间不足",
		"full backpack blocks demolition"
	)
	world.pocket.remove(SliceWorld.ITEM_CRYSTAL, world.pocket.count(SliceWorld.ITEM_CRYSTAL))
	_expect_equal(world.demolish_building(relay), true, "relay demolishes with space")
	_expect_equal(
		world.pocket.count(SliceWorld.ITEM_POWER_RELAY_KIT),
		1,
		"relay demolition returns one kit"
	)

	world.open_building_actions(conveyor)
	_expect_equal(world.is_building_actions_open(), true, "E target opens action panel")
	_send_panel_key(world._building_action_panel, KEY_2)
	_expect_equal(
		world._building_instances.has(conveyor),
		true,
		"first demolition press only asks for confirmation"
	)
	_send_panel_key(world._building_action_panel, KEY_2)
	_expect_equal(
		world._building_instances.has(conveyor),
		false,
		"second demolition press removes building"
	)
	_expect_equal(
		world.pocket.count(SliceWorld.ITEM_CONVEYOR_KIT),
		1,
		"confirmed demolition returns one conveyor kit"
	)

	var collector := world._spawn_building(
		SliceBuildingCatalog.find(SliceBuildingCatalog.COLLECTOR_ID),
		"",
		Vector2i(45, 10),
		0,
		{"buffer": 1}
	) as SliceCollector
	_expect_equal(
		world.demolition_block_reason(collector),
		"先取空采集器",
		"non-empty collector is demolition-gated"
	)

	world.core_repaired = true
	for definition in SliceBuildingCatalog.all():
		if world.pocket.count(definition.kit_item_id) <= 0:
			world.pocket.add(definition.kit_item_id, 1)
	var moved_to_core := world.transfer_all_building_kits_to_core()
	_expect_equal(moved_to_core >= 6, true, "central storage accepts all kit types")
	for definition in SliceBuildingCatalog.all():
		_expect_equal(
			world.core_storage.count(definition.kit_item_id) > 0,
			true,
			"core stores %s" % definition.kit_item_id
		)
	var moved_to_pocket := world.transfer_all_building_kits_to_pocket()
	_expect_equal(
		moved_to_pocket, moved_to_core, "central storage returns all kit types"
	)
	world.free()


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


func _place_device(
	world: SliceWorld,
	building_id: String,
	origin: Vector2i,
	rotation: int
) -> SliceBuildingInstance:
	var definition := SliceBuildingCatalog.find(building_id)
	world.pocket.add(definition.kit_item_id, 1)
	_expect_equal(world.begin_building_placement(building_id), true, "%s selected" % building_id)
	for _step in range(rotation):
		world.rotate_building_placement()
	var validation := world._validate_placement(definition, origin, rotation)
	world._placement.update_target(
		origin,
		definition.block_center(origin, SliceWorld.TILE_SIZE, rotation),
		validation
	)
	_expect_equal(
		bool(validation.get("valid", false)),
		true,
		"%s validates" % building_id
	)
	var index := world._building_instances.size()
	_expect_equal(world.try_place_building(), true, "%s places" % building_id)
	return world._building_instances[index]


func _find_building(
	world: SliceWorld,
	building_id: String,
	origin: Vector2i
) -> SliceBuildingInstance:
	for instance in world._building_instances:
		if instance.building_id == building_id and instance.origin_cell == origin:
			return instance
	return null


func _send_panel_key(panel: SliceBuildingActionPanel, keycode: Key) -> void:
	var event := InputEventKey.new()
	event.keycode = keycode
	event.pressed = true
	panel._unhandled_input(event)


func _expect_equal(actual, expected, context: String) -> void:
	_assertion_count += 1
	if actual == expected:
		return
	failures.append(
		"%s: expected %s, got %s" % [context, str(expected), str(actual)]
	)


func _cleanup_save_dir() -> void:
	if _save_dir.is_empty():
		return
	for filename in [
		"slice_world.json",
		"slice_world.bak.json",
		"slice_world.tmp.json",
	]:
		var path := _save_dir.path_join(filename)
		if FileAccess.file_exists(path):
			DirAccess.remove_absolute(path)
	if DirAccess.dir_exists_absolute(_save_dir):
		DirAccess.remove_absolute(_save_dir)
