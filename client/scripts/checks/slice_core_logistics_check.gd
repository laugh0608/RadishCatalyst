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
	var core := Node2D.new()
	core.position = Vector2(640, 320)
	var visual := _make_core_visual()
	var inventory := Inventory.new(
		SliceInventoryProfiles.category_core_storage()
	)
	var provider := SliceCoreLogistics.new()
	provider.setup(core, visual, inventory, false, 32.0)
	_expect_equal(provider.endpoints().is_empty(), true, "damaged core has no endpoints")
	_expect_equal(provider.approach_cells().is_empty(), true, "damaged core reserves no active approach")
	_expect_equal(
		_core_patch_visible(visual, "InputDockingPatch"),
		false,
		"damaged core has no input docking patch"
	)
	_expect_equal(
		_core_patch_visible(visual, "OutputDockingPatch"),
		false,
		"damaged core has no output docking patch"
	)

	provider.setup(core, visual, inventory, true, 32.0)
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
		input.terminal_belt_overlaps_device,
		false,
		"core input keeps its terminal belt on the ordinary y-sort plane"
	)
	_expect_equal(
		output.terminal_belt_overlaps_device,
		false,
		"core output keeps its terminal belt on the ordinary y-sort plane"
	)
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
	visual.free()


func _check_grid_transfer_contract() -> void:
	var core := Node2D.new()
	core.position = Vector2(640, 320)
	var visual := _make_core_visual()
	var inventory := Inventory.new(
		SliceInventoryProfiles.category_core_storage()
	)
	var provider := SliceCoreLogistics.new()
	provider.setup(core, visual, inventory, true, 32.0)
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
		0,
		"core input terminal belt stays behind the dedicated visual shell"
	)
	_expect_equal(
		_core_patch_visible(visual, "InputDockingPatch"),
		true,
		"correct single input derives the left docking patch"
	)
	_expect_equal(
		_core_patch_visible(visual, "OutputDockingPatch"),
		false,
		"missing output keeps the right docking patch hidden"
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
		0,
		"core output terminal belt stays behind the dedicated visual shell"
	)
	_expect_equal(
		_core_patch_visible(visual, "InputDockingPatch"),
		true,
		"dual connection keeps the input docking patch"
	)
	_expect_equal(
		_core_patch_visible(visual, "OutputDockingPatch"),
		true,
		"dual connection derives the output docking patch"
	)
	_check_core_docking_visual_contract(
		provider,
		grid,
		core,
		visual,
		inventory,
		input_belt,
		output_belt
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
	visual.free()


func _check_core_docking_visual_contract(
	provider: SliceCoreLogistics,
	grid: SliceLogisticsGrid,
	core: Node2D,
	visual: SliceCoreVisual,
	inventory: Inventory,
	input_belt: SliceConveyor,
	output_belt: SliceConveyor
) -> void:
	var input_patch := _core_patch(visual, "InputDockingPatch")
	var output_patch := _core_patch(visual, "OutputDockingPatch")
	_expect_equal(
		input_patch.texture.get_size(),
		SliceCoreVisual.DOCKING_PATCH_SIZE,
		"core input patch keeps the approved 12 by 24 pixel bounds"
	)
	_expect_equal(
		output_patch.texture.get_size(),
		SliceCoreVisual.DOCKING_PATCH_SIZE,
		"core output patch keeps the approved 12 by 24 pixel bounds"
	)
	_expect_equal(
		input_patch.position,
		SliceCoreVisual.INPUT_DOCKING_POSITION,
		"core input patch keeps the approved texture-local anchor"
	)
	_expect_equal(
		output_patch.position,
		SliceCoreVisual.OUTPUT_DOCKING_POSITION,
		"core output patch keeps the approved texture-local anchor"
	)
	_expect_equal(
		SliceCoreVisual.INPUT_DOCKING_TEXTURE_LOCAL_ANCHOR,
		Vector2i(0, 97),
		"core input source region keeps the approved texture anchor"
	)
	_expect_equal(
		SliceCoreVisual.OUTPUT_DOCKING_TEXTURE_LOCAL_ANCHOR,
		Vector2i(132, 97),
		"core output source region keeps the approved texture anchor"
	)
	_expect_equal(
		input_patch.texture.resource_path.ends_with(
			"docking_left_connected_patch.png"
		),
		true,
		"core and reactor share the semantic left docking resource"
	)
	_expect_equal(
		output_patch.texture.resource_path.ends_with(
			"docking_right_connected_patch.png"
		),
		true,
		"core and reactor share the semantic right docking resource"
	)
	_expect_equal(
		input_patch.z_index,
		0,
		"core input patch stays on the natural core y-sort plane"
	)
	_expect_equal(
		output_patch.z_index,
		0,
		"core output patch stays on the natural core y-sort plane"
	)

	input_belt.building_rotation = 3
	grid.rebuild(
		[input_belt, output_belt], "", provider.endpoints()
	)
	_expect_equal(
		_core_patch_visible(visual, "InputDockingPatch"),
		false,
		"wrong-way input clears the left patch in the rebuild frame"
	)
	_expect_equal(
		_core_patch_visible(visual, "OutputDockingPatch"),
		true,
		"wrong-way input does not disturb the valid output patch"
	)
	input_belt.building_rotation = 1

	output_belt.building_rotation = 3
	grid.rebuild(
		[input_belt, output_belt], "", provider.endpoints()
	)
	_expect_equal(
		_core_patch_visible(visual, "InputDockingPatch"),
		true,
		"valid input remains visible while output points the wrong way"
	)
	_expect_equal(
		_core_patch_visible(visual, "OutputDockingPatch"),
		false,
		"wrong-way output clears the right patch in the rebuild frame"
	)
	output_belt.building_rotation = 1

	grid.rebuild([output_belt], "", provider.endpoints())
	_expect_equal(
		_core_patch_visible(visual, "InputDockingPatch"),
		false,
		"removing the input terminal clears the left patch"
	)
	_expect_equal(
		_core_patch_visible(visual, "OutputDockingPatch"),
		true,
		"single output keeps only the right patch"
	)

	grid.rebuild([], "", provider.endpoints())
	_expect_equal(
		_core_patch_visible(visual, "InputDockingPatch"),
		false,
		"repaired empty core keeps its input patch hidden"
	)
	_expect_equal(
		_core_patch_visible(visual, "OutputDockingPatch"),
		false,
		"repaired empty core keeps its output patch hidden"
	)

	provider.setup(
		core,
		visual,
		inventory,
		false,
		32.0
	)
	grid.rebuild([input_belt, output_belt], "", provider.endpoints())
	_expect_equal(
		_core_patch_visible(visual, "InputDockingPatch"),
		false,
		"damaged-state rebuild clears the input patch"
	)
	_expect_equal(
		_core_patch_visible(visual, "OutputDockingPatch"),
		false,
		"damaged-state rebuild clears the output patch"
	)
	provider.setup(
		core,
		visual,
		inventory,
		true,
		32.0
	)
	grid.rebuild([input_belt, output_belt], "", provider.endpoints())
	_expect_equal(
		_core_patch_visible(visual, "InputDockingPatch"),
		true,
		"repair-state rebuild re-derives the input patch"
	)
	_expect_equal(
		_core_patch_visible(visual, "OutputDockingPatch"),
		true,
		"repair-state rebuild re-derives the output patch"
	)


func _check_world_repair_and_restart() -> void:
	var world := SliceWorldScene.instantiate() as SliceWorld
	world.save_service = SliceSaveService.new(_save_dir)
	root.add_child(world)
	await process_frame
	await physics_frame
	var core_anchor := world.get_node(
		"SliceMap/World/OutpostCoreDamaged"
	) as Node2D
	var core_visual := world.get_node(
		"SliceMap/World/OutpostCoreVisualSortShell"
	) as SliceCoreVisual
	var core := core_visual.core_sprite()
	_expect_equal(
		core.texture.get_size(),
		Vector2(144, 128),
		"fresh world uses the V5-family damaged core body"
	)
	_expect_equal(
		core.texture.resource_path.ends_with("outpost_core_damaged.png"),
		true,
		"fresh world uses the formal damaged core path"
	)
	_expect_equal(
		core.offset,
		SliceCoreLogistics.REPAIRED_SPRITE_OFFSET,
		"damaged core shares the repaired body's bottom alignment"
	)
	_expect_equal(
		core_anchor.global_position,
		Vector2(640, 320),
		"core logic anchor keeps its frozen world position"
	)
	_expect_equal(
		core_visual.global_position,
		core_anchor.global_position + SliceCoreVisual.SORT_ANCHOR_OFFSET,
		"core visual shell sorts at the footprint front edge"
	)
	_expect_equal(
		core.position,
		SliceCoreVisual.SPRITE_POSITION,
		"core sprite counter-offset preserves every approved world pixel"
	)
	_expect_equal(
		core_visual.z_index,
		0,
		"core visual shell does not escape natural y-sorting"
	)
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
	_expect_equal(
		input_belt.global_position.y < core_visual.global_position.y,
		true,
		"input terminal belt sorts behind the core shell"
	)
	input_belt.set_cargo(SliceWorld.ITEM_CRYSTAL, 1.0)
	world._tick_logistics(1.0)
	_expect_equal(world.core_storage.count(SliceWorld.ITEM_CRYSTAL), 1, "world core input reaches core_storage")
	_expect_equal(_core_change_count > 0, true, "automatic core input emits the existing warehouse signal")
	_expect_equal(
		_core_patch_visible(core_visual, "InputDockingPatch"),
		true,
		"world input topology displays the left docking patch"
	)

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
	_expect_equal(
		_core_patch_visible(core_visual, "OutputDockingPatch"),
		true,
		"world output topology displays the right docking patch"
	)
	_expect_equal(world._autosave(), true, "core logistics state saves without a new schema field")

	world.queue_free()
	await process_frame
	var loaded := SliceWorldScene.instantiate() as SliceWorld
	loaded.startup_load = true
	loaded.save_service = SliceSaveService.new(_save_dir)
	root.add_child(loaded)
	await process_frame
	await physics_frame
	var loaded_visual := loaded.get_node(
		"SliceMap/World/OutpostCoreVisualSortShell"
	) as SliceCoreVisual
	var loaded_core := loaded_visual.core_sprite()
	_expect_equal(loaded.core_repaired, true, "restart restores repaired core truth")
	_expect_equal(loaded_core.texture.get_size(), Vector2(144, 128), "restart restores the approved short-port core body")
	_expect_equal(loaded_core.offset, SliceCoreLogistics.REPAIRED_SPRITE_OFFSET, "restart restores short-port core alignment")
	_expect_equal(loaded._logistics_grid.placement_preview_ports().size(), 2, "restart re-derives both core endpoints")
	_expect_equal(loaded.core_storage.count(SliceWorld.ITEM_CATALYST), 1, "restart preserves automatic and manual core inventory")
	_expect_equal(_building_with_id(loaded, input_belt_id) != null, true, "restart preserves the core input belt identity")
	var loaded_input := _building_with_id(loaded, input_belt_id) as SliceConveyor
	var loaded_output := _building_with_id(loaded, output_belt_id) as SliceConveyor
	_expect_equal(loaded_output != null and loaded_output.cargo_item_id == SliceWorld.ITEM_CRYSTAL, true, "restart preserves cargo emitted from core_storage")
	_expect_equal(
		_core_patch_visible(loaded_visual, "InputDockingPatch"),
		true,
		"restart re-derives the connected input patch"
	)
	_expect_equal(
		_core_patch_visible(loaded_visual, "OutputDockingPatch"),
		true,
		"restart re-derives the connected output patch"
	)
	_expect_equal(
		(loaded_input.get_node("Sprite") as Sprite2D).z_index,
		0,
		"restart keeps the input terminal belt behind the core shell"
	)
	_expect_equal(
		(loaded_output.get_node("Sprite") as Sprite2D).z_index,
		0,
		"restart keeps the output terminal belt behind the core shell"
	)
	loaded.queue_free()
	await process_frame


func _make_core_visual() -> SliceCoreVisual:
	var visual := SliceCoreVisual.new()
	visual.position = Vector2(640, 320) + SliceCoreVisual.SORT_ANCHOR_OFFSET
	var sprite := Sprite2D.new()
	sprite.name = "Sprite"
	sprite.position = SliceCoreVisual.SPRITE_POSITION
	visual.add_child(sprite)
	return visual


func _core_patch(
	visual: SliceCoreVisual,
	node_name: String
) -> Sprite2D:
	var sprite := visual.core_sprite()
	return sprite.get_node_or_null(node_name) as Sprite2D


func _core_patch_visible(
	visual: SliceCoreVisual,
	node_name: String
) -> bool:
	var patch := _core_patch(visual, node_name)
	return patch != null and patch.visible


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
