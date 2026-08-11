extends SceneTree

const SliceWorldScene := preload("res://scenes/slice/SliceWorld.tscn")

var failures: Array[String] = []
var _assertion_count := 0
var _save_dir := ""
var _core_change_count := 0


func _init() -> void:
	call_deferred("_execute")


func _execute() -> void:
	_save_dir = OS.get_user_data_dir().path_join("slice-core-logistics-check")
	_cleanup_save_dir()
	_check_provider_contract()
	_check_grid_transfer_contract()
	await _check_world_repair_and_restart()
	if failures.is_empty():
		print(
			"Slice core logistics checks passed (%d assertions)."
			% _assertion_count
		)
		_cleanup_save_dir()
		quit(0)
		return
	for failure in failures:
		push_error(failure)
	_cleanup_save_dir()
	quit(1)


func _check_provider_contract() -> void:
	var core := Sprite2D.new()
	core.position = Vector2(640, 320)
	var inventory := Inventory.new(
		SliceInventoryProfiles.category_core_storage()
	)
	var provider := SliceCoreLogistics.new()
	provider.setup(core, inventory, false, 32.0)
	_expect_equal(provider.endpoints().is_empty(), true, "damaged core has no endpoints")
	_expect_equal(provider.approach_cells().is_empty(), true, "damaged core reserves no active approach")

	provider.setup(core, inventory, true, 32.0)
	var endpoints := provider.endpoints()
	_expect_equal(provider.origin_cell(), Vector2i(19, 9), "core derives its fixed two-by-two origin")
	_expect_equal(endpoints.size(), 2, "repaired core exposes two endpoints")
	var input := endpoints[0]
	var output := endpoints[1]
	_expect_equal(input.endpoint_id, "%s:input" % SliceCoreLogistics.INSTANCE_ID, "core input identity is stable")
	_expect_equal(output.endpoint_id, "%s:output" % SliceCoreLogistics.INSTANCE_ID, "core output identity is stable")
	_expect_equal(input.port_cell, Vector2i(19, 10), "core input stays on the left footprint cell")
	_expect_equal(input.connection_cell, Vector2i(18, 10), "core input uses the immediately adjacent belt cell")
	_expect_equal(output.port_cell, Vector2i(20, 10), "core output stays on the right footprint cell")
	_expect_equal(output.connection_cell, Vector2i(21, 10), "core output uses the immediately adjacent belt cell")
	_expect_equal(output.source_phase, 2, "core output follows existing storage and reactor sources")
	_expect_equal(
		provider.approach_cells(),
		[],
		"core does not create an invisible transfer gap"
	)
	_expect_equal(input.try_accept_one(SliceWorld.ITEM_PART), 0, "core input rejects non-transportable parts")
	_expect_equal(input.try_accept_one(SliceWorld.ITEM_CRYSTAL), 1, "core input accepts one crystal")
	_expect_equal(input.try_accept_one(SliceWorld.ITEM_CATALYST), 1, "core input accepts one catalyst")
	_expect_equal(output.peek_output_item(), SliceWorld.ITEM_CRYSTAL, "core output uses stable crystal-first order")
	_expect_equal(output.take_output_item(SliceWorld.ITEM_CRYSTAL), true, "core output removes the authoritative crystal")
	_expect_equal(output.peek_output_item(), SliceWorld.ITEM_CATALYST, "core output advances to catalyst")
	_expect_equal(inventory.count(SliceWorld.ITEM_CRYSTAL), 0, "automatic output updates the shared core inventory")
	_expect_equal(inventory.count(SliceWorld.ITEM_CATALYST), 1, "unselected core inventory remains intact")
	core.free()


func _check_grid_transfer_contract() -> void:
	var core := Sprite2D.new()
	core.position = Vector2(640, 320)
	var inventory := Inventory.new(
		SliceInventoryProfiles.category_core_storage()
	)
	var provider := SliceCoreLogistics.new()
	provider.setup(core, inventory, true, 32.0)
	var input_belt := _make_conveyor("building-900001", Vector2i(18, 10), 1)
	input_belt.set_cargo(SliceWorld.ITEM_CRYSTAL, 1.0)
	var instances: Array[SliceBuildingInstance] = [input_belt]
	var grid := SliceLogisticsGrid.new()
	grid.rebuild(instances, "", provider.endpoints())
	var input_result := grid.tick(SliceLogisticsGrid.SIMULATION_STEP_SECONDS)
	_expect_equal(input_belt.has_cargo(), false, "core input consumes completed belt cargo")
	_expect_equal(inventory.count(SliceWorld.ITEM_CRYSTAL), 1, "core input writes the shared warehouse")
	_expect_equal(
		input_result.get("storage_ids", []).has(SliceCoreLogistics.INSTANCE_ID),
		true,
		"core transfer reports the external inventory identity"
	)
	_expect_equal(input_belt.topology_kind(), SliceConveyor.TOPOLOGY_SINK_ENDPOINT, "core input belt uses the sink terminal frame")
	_expect_equal(
		(input_belt.get_node("Sprite") as Sprite2D).z_index,
		1,
		"core input terminal belt covers the device-owned short dock"
	)

	var output_belt := _make_conveyor("building-900002", Vector2i(21, 10), 1)
	instances.append(output_belt)
	grid.rebuild(instances, "", provider.endpoints())
	grid.tick(SliceLogisticsGrid.SIMULATION_STEP_SECONDS)
	_expect_equal(output_belt.has_cargo(), true, "core output injects one belt cargo")
	_expect_equal(output_belt.cargo_item_id, SliceWorld.ITEM_CRYSTAL, "core output carries the stored crystal")
	_expect_equal(inventory.count(SliceWorld.ITEM_CRYSTAL), 0, "core output removes exactly one stored item")
	_expect_equal(output_belt.topology_kind(), SliceConveyor.TOPOLOGY_SOURCE_ENDPOINT, "core output belt uses the source terminal frame")
	_expect_equal(
		(output_belt.get_node("Sprite") as Sprite2D).z_index,
		1,
		"core output terminal belt covers the device-owned short dock"
	)

	output_belt.clear_cargo()
	inventory.add(SliceWorld.ITEM_CRYSTAL, 99999)
	input_belt.set_cargo(SliceWorld.ITEM_CRYSTAL, 1.0)
	grid.rebuild([input_belt], "", provider.endpoints())
	grid.tick(1.0)
	_expect_equal(input_belt.has_cargo(), true, "full core item stack applies backpressure")
	_expect_equal(input_belt.cargo_progress < 1.0, true, "backpressured core cargo stays serializable")
	_expect_equal(inventory.count(SliceWorld.ITEM_CRYSTAL), 99999, "full core input leaves the warehouse unchanged")
	_free_instances(instances)
	core.free()


func _check_world_repair_and_restart() -> void:
	var world := SliceWorldScene.instantiate() as SliceWorld
	world.save_service = SliceSaveService.new(_save_dir)
	root.add_child(world)
	await process_frame
	await physics_frame
	var core := world.get_node("SliceMap/World/OutpostCoreDamaged") as Sprite2D
	_expect_equal(core.texture.get_size(), Vector2(103, 93), "fresh world retains the damaged core body")
	_expect_equal(core.offset, Vector2.ZERO, "damaged core keeps its existing placement")
	_expect_equal(world._logistics_grid.placement_preview_ports().is_empty(), true, "fresh damaged core has no physical ports")

	_core_change_count = 0
	world.core_storage_changed.connect(_on_core_storage_changed)
	world.pocket.add(SliceWorld.ITEM_PART, CoreRepairSite.REPAIR_PART_COST)
	var site := world.get_node("SliceMap/World/OutpostCoreDamaged/RepairSite") as CoreRepairSite
	site.try_interact(world)
	_expect_equal(world.core_repaired, true, "repair action enables the authoritative core state")
	_expect_equal(core.texture.get_size(), Vector2(144, 128), "repair action uses the approved short-port core body")
	_expect_equal(core.texture.resource_path.ends_with("outpost_core_repaired.png"), true, "repair action uses the formal locked core path")
	_expect_equal(core.offset, SliceCoreLogistics.REPAIRED_SPRITE_OFFSET, "short-port core bottom-aligns to the unchanged footprint")
	_expect_equal(
		SlicePowerVisualResolver.anchor_world_position(
			SlicePowerGrid.CORE_NODE_ID,
			world._core_world_position(),
			world._core_world_position() + Vector2.RIGHT,
			world._building_instances,
			SliceWorld.CORE_LINK_ANCHOR_OFFSET,
			SliceWorld.RELAY_LINK_ANCHOR_OFFSET
		),
		Vector2(648, 240),
		"repaired core power line resolves from its locked upper-ring anchor"
	)
	_expect_equal(world._logistics_grid.placement_preview_ports().size(), 2, "repair action rebuilds both core endpoints in the same frame")
	_expect_equal(
		world._active_logistics_approach_cells().has(Vector2i(18, 10)),
		false,
		"repaired core leaves no invisible approach gap"
	)
	var conveyor_definition := SliceBuildingCatalog.find(SliceBuildingCatalog.CONVEYOR_ID)
	var floor_definition := SliceBuildingCatalog.find(SliceBuildingCatalog.FLOOR_ID)
	world._spawn_building(floor_definition, "", Vector2i(18, 10), 0, {})
	var adjacent := world._validate_placement(
		conveyor_definition, Vector2i(18, 10), 1
	)
	_expect_equal(bool(adjacent.get("valid", false)), true, "world accepts the adjacent core terminal belt")
	var input_belt := world._spawn_building(
		conveyor_definition,
		"",
		Vector2i(18, 10),
		1,
		{}
	) as SliceConveyor
	var input_belt_id := input_belt.instance_id
	input_belt.set_cargo(SliceWorld.ITEM_CRYSTAL, 1.0)
	world._tick_logistics(1.0)
	_expect_equal(world.core_storage.count(SliceWorld.ITEM_CRYSTAL), 1, "world core input reaches core_storage")
	_expect_equal(_core_change_count > 0, true, "automatic core input emits the existing warehouse signal")

	world._spawn_building(floor_definition, "", Vector2i(21, 10), 0, {})
	var output_belt := world._spawn_building(
		conveyor_definition,
		"",
		Vector2i(21, 10),
		1,
		{}
	) as SliceConveyor
	var output_belt_id := output_belt.instance_id
	world.core_storage.add(SliceWorld.ITEM_CATALYST, 1)
	world._tick_logistics(0.1)
	_expect_equal(output_belt.cargo_item_id, SliceWorld.ITEM_CRYSTAL, "world core output preserves stable item priority")
	_expect_equal(world.core_storage.count(SliceWorld.ITEM_CATALYST), 1, "world output leaves the other class untouched")
	_expect_equal(world._autosave(), true, "core logistics state saves without a new schema field")

	world.queue_free()
	await process_frame
	var loaded := SliceWorldScene.instantiate() as SliceWorld
	loaded.startup_load = true
	loaded.save_service = SliceSaveService.new(_save_dir)
	root.add_child(loaded)
	await process_frame
	await physics_frame
	var loaded_core := loaded.get_node("SliceMap/World/OutpostCoreDamaged") as Sprite2D
	_expect_equal(loaded.core_repaired, true, "restart restores repaired core truth")
	_expect_equal(loaded_core.texture.get_size(), Vector2(144, 128), "restart restores the approved short-port core body")
	_expect_equal(loaded_core.offset, SliceCoreLogistics.REPAIRED_SPRITE_OFFSET, "restart restores short-port core alignment")
	_expect_equal(loaded._logistics_grid.placement_preview_ports().size(), 2, "restart re-derives both core endpoints")
	_expect_equal(loaded.core_storage.count(SliceWorld.ITEM_CATALYST), 1, "restart preserves automatic and manual core inventory")
	_expect_equal(_building_with_id(loaded, input_belt_id) != null, true, "restart preserves the core input belt identity")
	var loaded_output := _building_with_id(loaded, output_belt_id) as SliceConveyor
	_expect_equal(loaded_output != null and loaded_output.cargo_item_id == SliceWorld.ITEM_CRYSTAL, true, "restart preserves cargo emitted from core_storage")
	loaded.queue_free()
	await process_frame


func _make_conveyor(
	instance_id: String,
	origin: Vector2i,
	rotation: int
) -> SliceConveyor:
	var conveyor := SliceConveyor.new()
	var definition := SliceBuildingCatalog.find(
		SliceBuildingCatalog.CONVEYOR_ID
	)
	conveyor.configure_building(
		instance_id, definition.building_id, origin, rotation
	)
	conveyor.apply_definition(definition, 32.0)
	return conveyor


func _building_with_id(world: SliceWorld, instance_id: String) -> SliceBuildingInstance:
	for instance in world._building_instances:
		if instance.instance_id == instance_id:
			return instance
	return null


func _free_instances(instances: Array[SliceBuildingInstance]) -> void:
	for instance in instances:
		instance.free()


func _on_core_storage_changed() -> void:
	_core_change_count += 1


func _cleanup_save_dir() -> void:
	if not DirAccess.dir_exists_absolute(_save_dir):
		return
	_remove_tree(_save_dir)


func _remove_tree(path: String) -> void:
	var directory := DirAccess.open(path)
	if directory == null:
		return
	directory.list_dir_begin()
	var entry := directory.get_next()
	while not entry.is_empty():
		var child := path.path_join(entry)
		if directory.current_is_dir():
			_remove_tree(child)
		else:
			DirAccess.remove_absolute(child)
		entry = directory.get_next()
	directory.list_dir_end()
	DirAccess.remove_absolute(path)


func _expect_equal(actual, expected, label: String) -> void:
	_assertion_count += 1
	if actual != expected:
		failures.append(
			"%s: expected %s, got %s" % [label, expected, actual]
		)
