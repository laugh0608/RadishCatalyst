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
	_check_pointer_input_state()
	await _check_world_placement_path()


func _check_definitions() -> void:
	var floor := SliceBuildingCatalog.find(SliceBuildingCatalog.FLOOR_ID)
	var collector := SliceBuildingCatalog.find(
		SliceBuildingCatalog.COLLECTOR_ID
	)
	var reactor := SliceBuildingCatalog.find(SliceBuildingCatalog.REACTOR_ID)
	var relay := SliceBuildingCatalog.find(
		SliceBuildingCatalog.POWER_RELAY_ID
	)
	var conveyor := SliceBuildingCatalog.find(
		SliceBuildingCatalog.CONVEYOR_ID
	)
	var storage := SliceBuildingCatalog.find(SliceBuildingCatalog.STORAGE_ID)
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
	_expect_equal(
		oblong.sort_anchor_world_position(Vector2i(4, 5), 32.0, 1),
		Vector2(144, 224),
		"building sort anchor uses rotated footprint bottom edge"
	)
	_expect_equal(
		oblong.local_footprint_center_offset(32.0, 1),
		Vector2(0, -32),
		"building children retain the logical footprint center"
	)
	_expect_equal(
		collector.sprite_offset,
		Vector2(0, -24),
		"collector V1 bottom aligns with its 2x2 footprint"
	)
	_expect_equal(
		collector.power_indicator_offset,
		Vector2(4, -12),
		"collector power indicator aligns with the front-right status window"
	)

	for definition in [floor, collector, reactor, relay, storage]:
		_expect_equal(
			definition.orientation_mode,
			SliceBuildingDefinition.ORIENTATION_FIXED_FRONT,
			"%s uses fixed-front orientation" % definition.building_id
		)
		_expect_equal(
			definition.allows_rotation,
			false,
			"%s rejects R rotation" % definition.building_id
		)
	_expect_equal(
		conveyor.orientation_mode,
		SliceBuildingDefinition.ORIENTATION_CARDINAL,
		"conveyor retains cardinal orientation"
	)
	_expect_equal(conveyor.allows_rotation, true, "conveyor retains R input")
	_expect_equal(
		collector.visual_mode,
		SliceBuildingDefinition.VISUAL_SINGLE_FRAME,
		"collector uses one locked V1 frame"
	)
	_expect_equal(
		reactor.visual_mode,
		SliceBuildingDefinition.VISUAL_SINGLE_FRAME,
		"reactor uses one locked V10-body short-port frame"
	)
	_expect_equal(
		reactor.icon_region,
		Rect2(28, 0, 120, 88),
		"reactor UI framing excludes its world-only approach sections"
	)
	_expect_equal(storage.logistics_ports.size(), 2, "storage has fixed IN and OUT")
	var storage_input := storage.logistics_ports[0]
	var storage_output := storage.logistics_ports[1]
	_expect_equal(storage_input.id, "input", "storage input has a stable id")
	_expect_equal(
		storage_input.role,
		SliceLogisticsPortDefinition.ROLE_INPUT,
		"storage left port is input-only"
	)
	_expect_equal(
		storage_input.accepted_item_ids,
		["crystal", "catalyst"],
		"storage input keeps the transport whitelist"
	)
	_expect_equal(
		storage_output.output_item_order,
		["crystal", "catalyst"],
		"storage output keeps deterministic item order"
	)
	_expect_equal(
		storage_output.source_phase, 0, "storage remains the first source phase"
	)
	_expect_equal(
		storage_input.orientation_policy,
		SliceLogisticsPortDefinition.ORIENTATION_FIXED_LOCAL,
		"storage input geometry is rotation-independent"
	)
	_expect_equal(
		storage_input.local_cell == Vector2i(0, 1)
		and storage_input.outward_direction == Vector2i.LEFT
		and storage_output.local_cell == Vector2i(1, 1)
		and storage_output.outward_direction == Vector2i.RIGHT,
		true,
		"storage fixed ports keep the locked left-IN/right-OUT geometry"
	)
	_expect_equal(reactor.logistics_ports.size(), 2, "reactor has two ports")
	_expect_equal(
		reactor.logistics_ports[0].id, "input", "reactor input stays first"
	)
	_expect_equal(
		reactor.logistics_ports[1].id, "output", "reactor output stays second"
	)
	_expect_equal(
		reactor.logistics_ports[1].source_phase,
		1,
		"reactor output remains after every storage source"
	)
	_expect_equal(
		reactor.logistics_ports[0].connection_distance,
		2,
		"reactor input reserves its built-in approach cell"
	)
	_expect_equal(
		reactor.logistics_ports[1].connection_distance,
		2,
		"reactor output reserves its built-in approach cell"
	)
	_expect_equal(
		reactor.logistics_approach_cells(Vector2i(10, 10), 0),
		[Vector2i(9, 12), Vector2i(13, 12)],
		"reactor exposes both world-only approach cells for placement"
	)
	_expect_equal(
		reactor.logistics_ports[0].local_cell,
		Vector2i(0, 2),
		"reactor input occupies the locked left local cell"
	)
	_expect_equal(
		reactor.logistics_ports[0].outward_direction,
		Vector2i.LEFT,
		"reactor input faces left"
	)
	_expect_equal(
		reactor.logistics_ports[1].local_cell,
		Vector2i(2, 2),
		"reactor output occupies the locked right local cell"
	)
	_expect_equal(
		reactor.logistics_ports[1].outward_direction,
		Vector2i.RIGHT,
		"reactor output faces right"
	)
	_expect_equal(
		collector.logistics_ports.size(),
		1,
		"collector exposes its fixed right output"
	)
	_expect_equal(
		collector.logistics_ports[0].local_cell,
		Vector2i(1, 1),
		"collector output occupies the locked local cell"
	)
	_expect_equal(
		collector.logistics_ports[0].outward_direction,
		Vector2i.RIGHT,
		"collector output faces right"
	)

	var fixed_front := SliceBuildingDefinition.new(
		"test.fixed_front",
		"test.fixed_front",
		"test",
		Vector2i(2, 1),
		false,
		SliceBuildingDefinition.SURFACE_BUILDABLE_ROCK,
		true,
		false
	)
	_expect_equal(
		fixed_front.orientation_mode,
		SliceBuildingDefinition.ORIENTATION_FIXED_FRONT,
		"non-rotating definitions expose fixed-front orientation"
	)
	_expect_equal(
		fixed_front.normalized_rotation(3),
		0,
		"fixed-front orientation normalizes every legacy rotation"
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


func _check_pointer_input_state() -> void:
	var pointer := SlicePlacementPointerInput.new()
	pointer.begin()
	var motion := InputEventMouseMotion.new()
	motion.position = Vector2(320, 240)
	_expect_equal(pointer.track_event(motion), true, "mouse motion is tracked")
	_expect_equal(
		pointer.pointer_target_active,
		true,
		"mouse motion switches placement to pointer targeting"
	)
	var click := InputEventMouseButton.new()
	click.button_index = MOUSE_BUTTON_LEFT
	click.position = motion.position
	click.pressed = true
	pointer.track_event(click)
	_expect_equal(
		pointer.should_confirm(click, Vector2i(4, 5), false, false),
		true,
		"device left click requests one placement"
	)
	_expect_equal(
		pointer.floor_drag_active,
		false,
		"device click never starts continuous placement"
	)

	pointer.begin()
	pointer.track_event(click)
	_expect_equal(
		pointer.should_confirm(click, Vector2i(4, 5), true, true),
		false,
		"blocking UI rejects the floor click"
	)
	pointer.track_event(click)
	_expect_equal(
		pointer.should_confirm(click, Vector2i(4, 5), true, false),
		true,
		"floor left click starts continuous placement"
	)
	_expect_equal(pointer.floor_drag_active, true, "floor drag is active")
	pointer.track_event(motion)
	_expect_equal(
		pointer.should_confirm(motion, Vector2i(4, 5), true, false),
		false,
		"same floor cell is deduplicated while dragging"
	)
	motion.position = Vector2(352, 240)
	pointer.track_event(motion)
	_expect_equal(
		pointer.should_confirm(motion, Vector2i(5, 5), true, false),
		true,
		"crossing into a new floor cell requests one placement"
	)
	_expect_equal(
		pointer.should_confirm(motion, Vector2i(5, 5), true, false),
		false,
		"repeated motion in the new cell stays deduplicated"
	)
	click.pressed = false
	pointer.track_event(click)
	_expect_equal(pointer.floor_drag_active, false, "left release stops drag")


func _check_world_placement_path() -> void:
	var repo_root := (
		ProjectSettings.globalize_path("res://").path_join("..").simplify_path()
	)
	_save_dir = repo_root.path_join(
		"tools/runtime-intake/2026-07-29-placement-check-%d"
		% Time.get_ticks_usec()
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
	var reactor := SliceBuildingCatalog.find(SliceBuildingCatalog.REACTOR_ID)
	var relay := SliceBuildingCatalog.find(
		SliceBuildingCatalog.POWER_RELAY_ID
	)
	var conveyor := SliceBuildingCatalog.find(
		SliceBuildingCatalog.CONVEYOR_ID
	)
	var storage := SliceBuildingCatalog.find(SliceBuildingCatalog.STORAGE_ID)
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

	var reactor_cell := Vector2i(16, 5)
	var reactor_validation := world._validate_placement(
		reactor, reactor_cell, 0
	)
	world._placement.begin(reactor)
	world._placement.update_target(
		reactor_cell,
		reactor.block_center(reactor_cell, SliceWorld.TILE_SIZE, 0),
		reactor_validation,
		SliceWorld.TILE_SIZE,
		world._power_grid.placement_preview_nodes()
	)
	_expect_equal(
		world._placement._overlay.footprint_cell_count(),
		9,
		"reactor preview exposes its full three-by-three footprint"
	)
	_expect_equal(
		world._placement._overlay.missing_floor_cell_count(),
		9,
		"reactor preview marks every missing support floor cell"
	)
	_expect_equal(
		String(reactor_validation.get("reason", "")),
		"工业地板不足：需9，有0",
		"reactor preview explains the exact missing support resource"
	)
	_expect_equal(
		world._placement._overlay.logistics_port_marker_count(),
		2,
		"reactor preview marks input and output conveyor ports"
	)
	var approach_overlap := world._placement_validator.validate(
		conveyor,
		Vector2i(15, 7),
		0,
		0,
		reactor.logistics_approach_cells(reactor_cell, 0)
	)
	_expect_equal(
		bool(approach_overlap.get("valid", true)),
		false,
		"a conveyor cannot occupy the reactor built-in approach cell"
	)
	_expect_equal(
		String(approach_overlap.get("reason", "")),
		"设备接口接驳区需留空",
		"approach overlap reports the dedicated placement reason"
	)
	world._placement.cancel()

	var storage_validation := world._validate_placement(
		storage, Vector2i(16, 8), 0
	)
	world._placement.begin(storage)
	world._placement.update_target(
		Vector2i(16, 8),
		storage.block_center(Vector2i(16, 8), SliceWorld.TILE_SIZE, 0),
		storage_validation,
		SliceWorld.TILE_SIZE,
		world._power_grid.placement_preview_nodes()
	)
	_expect_equal(
		world._placement._overlay.logistics_port_marker_count(),
		2,
		"storage preview marks fixed left IN and right OUT ports"
	)
	world._placement.cancel()

	world.core_repaired = true
	world._rebuild_power_grid()
	var relay_cell := Vector2i(15, 10)
	var relay_validation := world._validate_placement(relay, relay_cell, 0)
	world._placement.begin(relay)
	world._placement.update_target(
		relay_cell,
		relay.block_center(relay_cell, SliceWorld.TILE_SIZE, 0),
		relay_validation,
		SliceWorld.TILE_SIZE,
		world._power_grid.placement_preview_nodes()
	)
	_expect_equal(
		world._power_grid.placement_preview_nodes().size(),
		1,
		"repaired core is exposed as one derived preview power node"
	)
	_expect_equal(
		world._placement._overlay.power_ring_count(),
		2,
		"relay preview shows ranges even before its floor exists"
	)
	_expect_equal(
		bool(relay_validation.get("valid", false)),
		false,
		"relay without a floor kit cannot partially place"
	)
	_expect_equal(
		world._building_instances.is_empty(),
		true,
		"invalid relay preview creates no support floor or device"
	)
	world._placement.cancel()

	world.pocket.add(SliceWorld.ITEM_FLOOR_KIT, 1)
	world.pocket.add(SliceWorld.ITEM_POWER_RELAY_KIT, 1)
	_expect_equal(
		world.begin_building_placement(relay.building_id),
		true,
		"relay kit enters authoritative placement"
	)
	relay_validation = world._validate_placement(relay, relay_cell, 0)
	world._placement.update_target(
		relay_cell,
		relay.block_center(relay_cell, SliceWorld.TILE_SIZE, 0),
		relay_validation,
		SliceWorld.TILE_SIZE,
		world._power_grid.placement_preview_nodes()
	)
	_expect_equal(
		String(relay_validation.get("reason", "")),
		"",
		"one floor kit clears the relay placement blocker"
	)
	_expect_equal(
		bool(relay_validation.get("valid", false)),
		true,
		"one floor kit makes the in-range relay preview valid"
	)
	_expect_equal(
		world.placement_auto_floor_count(),
		1,
		"relay preview exposes one automatic support floor"
	)
	var hud := world.get_node("SliceHud") as SliceHud
	hud._process(0.0)
	_expect_equal(
		hud.prompt_label.text.contains("自动铺地 1 格"),
		true,
		"placement HUD announces the exact automatic floor cost"
	)
	_expect_equal(
		hud.prompt_label.text.contains("R 旋转"),
		false,
		"fixed relay placement omits the rotation hint"
	)
	_expect_equal(
		world.try_place_building(),
		true,
		"one relay confirmation installs its support floor and device"
	)
	_expect_equal(
		world.pocket.count(SliceWorld.ITEM_FLOOR_KIT),
		0,
		"automatic relay support consumes exactly one floor kit"
	)
	_expect_equal(
		world.pocket.count(SliceWorld.ITEM_POWER_RELAY_KIT),
		0,
		"automatic relay placement consumes exactly one device kit"
	)
	_expect_equal(
		world._occupancy.has_floor(relay_cell),
		true,
		"automatic support is registered in floor occupancy"
	)
	_expect_equal(
		world._occupancy.blocking_instance_at(relay_cell).is_empty(),
		false,
		"relay is registered above its automatic support floor"
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
	_expect_equal(
		world.selected_building_rotation(),
		0,
		"fixed industrial floor ignores R rotation"
	)

	var floor_screen := (
		world._placement.get_canvas_transform()
		* floor.block_center(
			floor_cell,
			SliceWorld.TILE_SIZE,
			world.selected_building_rotation()
		)
	)
	var floor_click := InputEventMouseButton.new()
	floor_click.button_index = MOUSE_BUTTON_LEFT
	floor_click.position = floor_screen
	floor_click.pressed = true
	_expect_equal(
		world._handle_placement_pointer_event(floor_click, true),
		true,
		"blocking UI consumes the pointer event"
	)
	_expect_equal(
		world.pocket.count(SliceWorld.ITEM_FLOOR_KIT),
		4,
		"blocking UI prevents pointer placement and material cost"
	)
	_expect_equal(
		world._handle_placement_pointer_event(floor_click, false),
		true,
		"left click enters the authoritative placement path"
	)
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
	var second_floor_cell := floor_cell + Vector2i.RIGHT
	var floor_motion := InputEventMouseMotion.new()
	floor_motion.position = (
		world._placement.get_canvas_transform()
		* floor.block_center(second_floor_cell, SliceWorld.TILE_SIZE, 0)
	)
	world._handle_placement_pointer_event(floor_motion)
	_expect_equal(
		world._industrial_floor.get_cell_source_id(second_floor_cell),
		0,
		"held floor drag places after crossing into a new cell"
	)
	_expect_equal(
		world.pocket.count(SliceWorld.ITEM_FLOOR_KIT),
		2,
		"second drag cell consumes exactly one floor kit"
	)
	world._handle_placement_pointer_event(floor_motion)
	_expect_equal(
		world.pocket.count(SliceWorld.ITEM_FLOOR_KIT),
		2,
		"repeated motion in one floor cell does not double-charge"
	)
	var third_floor_cell := second_floor_cell + Vector2i.RIGHT
	floor_motion.position = (
		world._placement.get_canvas_transform()
		* floor.block_center(third_floor_cell, SliceWorld.TILE_SIZE, 0)
	)
	world._handle_placement_pointer_event(floor_motion)
	_expect_equal(
		world._industrial_floor.get_cell_source_id(third_floor_cell),
		0,
		"continuous floor drag follows the pointer grid"
	)
	floor_click.pressed = false
	floor_click.position = floor_motion.position
	world._handle_placement_pointer_event(floor_click)

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
		1,
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
	var collector_preview := world._placement._preview as Sprite2D
	_expect_equal(
		collector_preview.texture.get_size(),
		Vector2(96, 112),
		"collector ghost uses the locked V1 sprite"
	)
	_expect_equal(
		collector_preview.position,
		Vector2(0, -24),
		"collector ghost bottom-centers on the 2x2 footprint"
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
		6,
		"automatic support, relay, dragged floors and collector share the registry"
	)
	_expect_equal(
		world._collector_nodes.size(), 1, "collector behavior stays registered"
	)
	var placed_collector := world._collector_nodes[0]
	_expect_equal(
		placed_collector.position,
		collector.sort_anchor_world_position(
			collector_cell, SliceWorld.TILE_SIZE, 0
		),
		"placed collector y-sorts from its footprint bottom edge"
	)
	_expect_equal(
		placed_collector.get_node_or_null("GroundShadow") != null,
		true,
		"placed collector receives a grounded silhouette shadow"
	)
	var collector_sprite := placed_collector.get_node("Sprite") as Sprite2D
	_expect_equal(
		collector_sprite.texture.get_size(),
		Vector2(96, 112),
		"placed collector uses the locked V1 runtime sprite"
	)
	_expect_equal(
		collector_sprite.position,
		Vector2(0, -56),
		"placed collector sprite is bottom-centered on the footprint edge"
	)
	_expect_equal(
		(placed_collector.get_node("PowerIndicator") as Polygon2D).position,
		Vector2(36, -12),
		"placed collector status light stays on the front-right machine lamp"
	)
	_expect_equal(
		world.player.get_node_or_null("GroundShadow") != null,
		true,
		"slice player receives a grounded silhouette shadow"
	)
	world._collector_nodes[0].set_powered(true)
	world._tick_production(SliceWorld.COLLECTOR_PRODUCE_INTERVAL)
	_expect_equal(
		world._collector_nodes[0].buffer,
		1,
		"powered collector keeps current deterministic production behavior"
	)
	var collector_site := (
		world._collector_nodes[0].get_node("PickupSite")
		as CollectorPickupSite
	)
	var crystal_before := world.pocket.count(SliceWorld.ITEM_CRYSTAL)
	collector_site.try_interact(world)
	_expect_equal(
		world._building_action_panel.is_open(),
		true,
		"first collector interaction opens the operation panel"
	)
	_expect_equal(
		world._collector_nodes[0].buffer,
		1,
		"opening the collector panel does not take buffered crystal"
	)
	_expect_equal(
		world.pocket.count(SliceWorld.ITEM_CRYSTAL),
		crystal_before,
		"opening the collector panel does not change the backpack"
	)
	var take_button := world._building_action_panel.action_button("collect")
	_expect_equal(
		take_button != null
		and take_button.text.contains("取出全部晶体")
		and not take_button.disabled,
		true,
		"collector panel exposes an enabled mouse take action"
	)
	_expect_equal(
		world._building_action_panel.primary_status_text(),
		"晶体可取",
		"collector panel translates buffer state into a primary status"
	)
	var collector_primary: Dictionary = (
		world._building_action_panel.current_snapshot()["primary"]
	)
	_expect_equal(
		not collector_primary.has("next_step")
		and world._building_action_panel.get_node_or_null(
			"Root/Window/Margin/Layout/Body/Main/Primary/Margin/Text/NextStep"
		) == null,
		true,
		"device panel does not restore descriptive next-step copy"
	)
	take_button.pressed.emit()
	_expect_equal(
		world._collector_nodes[0].buffer,
		0,
		"collector panel mouse action drains the available buffer"
	)
	_expect_equal(
		world.pocket.count(SliceWorld.ITEM_CRYSTAL),
		crystal_before + 1,
		"collector panel mouse action moves crystal into the backpack"
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
