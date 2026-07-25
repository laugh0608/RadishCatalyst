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
			"Slice building placement checks passed (%d assertions)."
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
	_check_definitions()
	_check_occupancy_layers()
	await _check_world_placement_path()


func _check_definitions() -> void:
	var floor := SliceBuildingCatalog.find(SliceBuildingCatalog.FLOOR_ID)
	var collector := SliceBuildingCatalog.find(
		SliceBuildingCatalog.COLLECTOR_ID
	)
	_expect_equal(floor != null, true, "floor definition exists")
	_expect_equal(collector != null, true, "collector definition exists")
	_expect_equal(floor.kit_item_id, "building.floor", "floor kit id")
	_expect_equal(collector.kit_item_id, "building.collector", "collector kit id")
	_expect_equal(floor.footprint, Vector2i.ONE, "floor footprint")
	_expect_equal(collector.footprint, Vector2i(2, 2), "collector footprint")
	_expect_equal(floor.is_floor, true, "floor uses floor occupancy layer")
	_expect_equal(
		collector.surface_rule,
		SliceBuildingDefinition.SURFACE_CRYSTAL,
		"collector keeps crystal ground rule"
	)

	var oblong := SliceBuildingDefinition.new(
		"test.oblong",
		"test.oblong",
		"test",
		Vector2i(2, 1),
		true,
		SliceBuildingDefinition.SURFACE_BUILDABLE_ROCK,
		true,
		false
	)
	_expect_equal(
		oblong.rotated_footprint(0), Vector2i(2, 1), "base footprint"
	)
	_expect_equal(
		oblong.rotated_footprint(1), Vector2i(1, 2), "rotated footprint"
	)
	_expect_equal(
		oblong.occupied_cells(Vector2i(4, 5), 1),
		[Vector2i(4, 5), Vector2i(4, 6)],
		"rotated occupied cells"
	)


func _check_occupancy_layers() -> void:
	var occupancy := SliceBuildingOccupancy.new()
	var cell: Array[Vector2i] = [Vector2i(3, 4)]
	_expect_equal(
		occupancy.can_occupy(cell, true), true, "empty floor cell is free"
	)
	occupancy.occupy("floor-1", cell, true)
	_expect_equal(occupancy.has_floor(cell[0]), true, "floor claim is indexed")
	_expect_equal(
		occupancy.can_occupy(cell, false),
		true,
		"blocking facility may stand on a floor cell"
	)
	occupancy.occupy("device-1", cell, false)
	_expect_equal(
		occupancy.can_occupy(cell, true),
		false,
		"floor cannot be placed under an existing facility"
	)
	_expect_equal(
		occupancy.can_occupy(cell, false),
		false,
		"blocking facilities cannot overlap"
	)
	occupancy.release("device-1")
	_expect_equal(
		occupancy.can_occupy(cell, false),
		true,
		"releasing a facility preserves its supporting floor"
	)


func _check_world_placement_path() -> void:
	_save_dir = "/private/tmp/radishcatalyst-l3-package1-%d" % (
		Time.get_ticks_usec()
	)
	var world := SliceWorldScene.instantiate() as SliceWorld
	world.save_service = SliceSaveService.new(_save_dir)
	root.add_child(world)
	await process_frame
	await physics_frame

	var floor := SliceBuildingCatalog.find(SliceBuildingCatalog.FLOOR_ID)
	var collector := SliceBuildingCatalog.find(
		SliceBuildingCatalog.COLLECTOR_ID
	)
	var floor_cell := Vector2i(5, 5)
	var collector_cell := Vector2i(45, 10)
	_expect_equal(
		world._ground.get_cell_source_id(floor_cell),
		SliceWorld.ROCK_GROUND_SOURCE_ID,
		"floor test cell is buildable rock"
	)
	for cell in collector.occupied_cells(collector_cell, 0):
		_expect_equal(
			world._ground.get_cell_source_id(cell),
			SliceWorld.CRYSTAL_GROUND_SOURCE_ID,
			"collector test footprint is crystal ground"
		)

	world.pocket.add(SliceWorld.ITEM_CRYSTAL, 1)
	_expect_equal(world.craft("floor"), true, "floor recipe crafts")
	_expect_equal(
		world.pocket.count(SliceWorld.ITEM_FLOOR_KIT),
		4,
		"floor recipe grants all four kits"
	)
	_expect_equal(world.selected_building_id(), floor.building_id, "floor selected")
	world.rotate_building_placement()
	_expect_equal(world.selected_building_rotation(), 1, "R rotation advances")

	var floor_validation := world._validate_placement(
		floor, floor_cell, world.selected_building_rotation()
	)
	world._placement.update_target(
		floor_cell,
		floor.block_center(
			floor_cell, SliceWorld.TILE_SIZE, world.selected_building_rotation()
		),
		floor_validation
	)
	_expect_equal(
		bool(floor_validation.get("valid", false)),
		true,
		"rock floor placement is valid"
	)
	_expect_equal(world.try_place_building(), true, "floor uses common placement")
	_expect_equal(
		world.pocket.count(SliceWorld.ITEM_FLOOR_KIT),
		3,
		"one floor placement consumes one kit"
	)
	_expect_equal(
		world.is_placement_active(),
		true,
		"remaining floor kits keep continuous placement active"
	)
	_expect_equal(
		world._industrial_floor.get_cell_source_id(floor_cell),
		0,
		"placed floor writes the approved TileMapLayer asset"
	)

	var duplicate := world._validate_placement(floor, floor_cell, 0)
	_expect_equal(
		String(duplicate.get("reason", "")),
		"已有占用",
		"duplicate floor reports the first short reason"
	)
	world.cancel_building_placement()
	_expect_equal(world.is_placement_active(), false, "Esc cancellation exits")
	_expect_equal(
		world.pocket.count(SliceWorld.ITEM_FLOOR_KIT),
		3,
		"cancellation preserves remaining floor kits"
	)

	world.pocket.add(SliceWorld.ITEM_PART, 2)
	_expect_equal(world.craft("collector"), true, "collector recipe crafts")
	var collector_validation := world._validate_placement(
		collector, collector_cell, 0
	)
	world._placement.update_target(
		collector_cell,
		collector.block_center(
			collector_cell, SliceWorld.TILE_SIZE, 0
		),
		collector_validation
	)
	_expect_equal(
		bool(collector_validation.get("valid", false)),
		true,
		"crystal collector placement is valid"
	)
	_expect_equal(
		world.try_place_building(), true, "collector uses common placement"
	)
	_expect_equal(
		world.pocket.count(SliceWorld.ITEM_COLLECTOR_KIT),
		0,
		"collector placement consumes its kit"
	)
	_expect_equal(
		world.is_placement_active(),
		false,
		"placement exits when the selected kit is exhausted"
	)
	_expect_equal(
		world._building_instances.size(),
		2,
		"floor and collector share the instance registry"
	)
	_expect_equal(
		world._collector_nodes.size(), 1, "collector behavior stays registered"
	)
	world._collector_nodes[0].set_powered(true)
	world._tick_production(SliceWorld.COLLECTOR_PRODUCE_INTERVAL)
	_expect_equal(
		world._collector_nodes[0].buffer,
		1,
		"powered migrated collector keeps ten-second production behavior"
	)
	world.free()


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
		"slice_world.tmp.json"
	]:
		var path := _save_dir.path_join(filename)
		if FileAccess.file_exists(path):
			DirAccess.remove_absolute(path)
	if DirAccess.dir_exists_absolute(_save_dir):
		DirAccess.remove_absolute(_save_dir)
