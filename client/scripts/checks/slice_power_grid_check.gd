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
		print("Slice power grid checks passed (%d assertions)." % _assertion_count)
		_cleanup_save_dir()
		quit(0)
		return
	for failure in failures:
		push_error(failure)
	_cleanup_save_dir()
	quit(1)


func _run_checks() -> void:
	_check_definition_power_contract()
	await _check_multihop_world_grid()


func _check_definition_power_contract() -> void:
	var collector := SliceBuildingCatalog.find(SliceBuildingCatalog.COLLECTOR_ID)
	var reactor := SliceBuildingCatalog.find(SliceBuildingCatalog.REACTOR_ID)
	var relay := SliceBuildingCatalog.find(SliceBuildingCatalog.POWER_RELAY_ID)
	var conveyor := SliceBuildingCatalog.find(SliceBuildingCatalog.CONVEYOR_ID)
	_expect_equal(
		collector.power_role,
		SliceBuildingDefinition.POWER_CONSUMER,
		"collector is a power consumer"
	)
	_expect_equal(
		reactor.power_role,
		SliceBuildingDefinition.POWER_CONSUMER,
		"reactor is a power consumer"
	)
	_expect_equal(
		relay.power_role,
		SliceBuildingDefinition.POWER_RELAY,
		"relay is a graph node"
	)
	_expect_equal(
		conveyor.power_role,
		SliceBuildingDefinition.POWER_PASSIVE,
		"conveyor stays passive"
	)
	_expect_equal(
		collector.rotated_power_port_cell(0),
		Vector2i(0, 1),
		"collector base power port"
	)
	_expect_equal(
		collector.rotated_power_port_cell(1),
		Vector2i(0, 0),
		"collector power port rotates clockwise"
	)
	_expect_equal(
		reactor.rotated_power_port_cell(2),
		Vector2i(1, 0),
		"reactor power port rotates to opposite edge"
	)
	_expect_equal(
		relay.powered_texture_path.ends_with("power_relay_powered.png"),
		true,
		"relay definition references approved powered sprite"
	)


func _check_multihop_world_grid() -> void:
	_save_dir = "/private/tmp/radishcatalyst-l3-package3-%d" % Time.get_ticks_usec()
	var world := SliceWorldScene.instantiate() as SliceWorld
	world.save_service = SliceSaveService.new(_save_dir)
	root.add_child(world)
	await process_frame
	await physics_frame

	var floor := SliceBuildingCatalog.find(SliceBuildingCatalog.FLOOR_ID)
	for cell in [
		Vector2i(25, 10),
		Vector2i(31, 10),
		Vector2i(37, 10),
		Vector2i(5, 5),
	]:
		world._spawn_building(floor, "", cell, 0, {})
	_spawn_floor_rect(world, Vector2i(34, 7), Vector2i(3, 3))

	world.core_repaired = true
	world._rebuild_power_grid()
	var relay_one := _place_building(
		world, SliceBuildingCatalog.POWER_RELAY_ID, Vector2i(25, 10), 0
	)
	var relay_two := _place_building(
		world, SliceBuildingCatalog.POWER_RELAY_ID, Vector2i(31, 10), 0
	)
	if relay_two == null:
		world.free()
		return
	var relay_three := _place_building(
		world, SliceBuildingCatalog.POWER_RELAY_ID, Vector2i(37, 10), 0
	)
	if relay_three == null:
		world.free()
		return
	_expect_equal(world.powered_relay_count(), 3, "three-hop relay chain is reachable")
	_expect_equal(relay_one.powered, true, "core-adjacent relay is powered")
	_expect_equal(relay_two.powered, true, "second relay is powered")
	_expect_equal(relay_three.powered, true, "third relay is powered")
	var connections := world._power_grid.powered_connections()
	_expect_equal(connections.size(), 3, "powered relays expose one parent edge each")
	_expect_equal(
		String(connections[0].get("parent_id", "")),
		SlicePowerGrid.CORE_NODE_ID,
		"first relay edge starts at the repaired core"
	)
	_expect_equal(
		String(connections[1].get("parent_id", "")),
		relay_one.instance_id,
		"second relay edge uses the first relay as its parent"
	)
	_expect_equal(
		String(connections[2].get("parent_id", "")),
		relay_two.instance_id,
		"third relay edge uses the bridge relay as its parent"
	)
	_expect_equal(
		world._power_links.link_count(),
		3,
		"power link layer renders the same derived spanning tree"
	)
	_expect_equal(
		relay_one.position,
		relay_one.definition.sort_anchor_world_position(
			relay_one.origin_cell, SliceWorld.TILE_SIZE, relay_one.building_rotation
		),
		"relay y-sorts from its footprint bottom edge"
	)
	_expect_equal(
		relay_one.get_node_or_null("GroundShadow") != null,
		true,
		"relay has a grounded silhouette shadow"
	)
	_expect_equal(
		(relay_three.get_node("Sprite") as Sprite2D).texture.resource_path.ends_with(
			"power_relay_powered.png"
		),
		true,
		"powered relay uses approved cyan sprite"
	)

	var disconnected := world._validate_placement(
		SliceBuildingCatalog.find(SliceBuildingCatalog.POWER_RELAY_ID),
		Vector2i(5, 5),
		0
	)
	_expect_equal(
		String(disconnected.get("reason", "")),
		"超出电网连接距离",
		"isolated relay is rejected"
	)

	var reactor := _place_building(
		world, SliceBuildingCatalog.REACTOR_ID, Vector2i(34, 7), 0
	)
	var collector_definition := SliceBuildingCatalog.find(
		SliceBuildingCatalog.COLLECTOR_ID
	)
	var collector_cell := Vector2i(40, 10)
	for cell in collector_definition.occupied_cells(collector_cell, 0):
		_expect_equal(
			world._ground.get_cell_source_id(cell),
			SliceWorld.CRYSTAL_GROUND_SOURCE_ID,
			"collector footprint is crystal ground"
		)
	var collector := _place_building(
		world, SliceBuildingCatalog.COLLECTOR_ID, collector_cell, 0
	) as SliceCollector
	_expect_equal(reactor.powered, true, "reactor port is within relay coverage")
	_expect_equal(collector.powered, true, "collector port is within relay coverage")
	_expect_equal(
		reactor.get_node_or_null("PowerIndicator") != null,
		true,
		"reactor has a narrow state indicator"
	)
	_expect_equal(
		collector.get_node_or_null("PowerIndicator") != null,
		true,
		"collector has a narrow state indicator"
	)
	var reactor_prompt := (
		reactor.get_node("InteractionSite") as SliceBuildingInteractionSite
	).get_prompt(world)
	_expect_equal(
		reactor_prompt.contains("缺晶体"),
		true,
		"powered reactor exposes its L5 material status"
	)
	_expect_equal(
		world.relay_disconnect_impact_count(relay_two),
		2,
		"bridge relay reports two affected consumers"
	)

	collector.production_progress = 4.0
	world._tick_production(3.0)
	_expect_equal(
		collector.production_progress,
		7.0,
		"powered collector advances independent tick progress"
	)
	_expect_equal(
		world.begin_building_adjustment(relay_two),
		true,
		"bridge relay enters adjustment"
	)
	_expect_equal(relay_three.powered, false, "downstream relay drops same frame")
	_expect_equal(reactor.powered, false, "reactor drops same frame")
	_expect_equal(collector.powered, false, "collector drops same frame")
	_expect_equal(
		world._power_links.link_count(),
		1,
		"adjustment removes disconnected derived links in the same frame"
	)
	_expect_equal(
		(relay_three.get_node("Sprite") as Sprite2D).texture.resource_path.ends_with(
			"power_relay_unpowered.png"
		),
		true,
		"disconnected relay switches to approved fault sprite"
	)
	world._tick_production(10.0)
	_expect_equal(
		collector.production_progress,
		7.0,
		"unpowered collector preserves partial progress"
	)
	_expect_equal(collector.buffer, 0, "unpowered collector produces nothing")
	world.cancel_building_placement()
	_expect_equal(relay_three.powered, true, "cancel restores downstream relay")
	_expect_equal(reactor.powered, true, "cancel restores reactor power")
	_expect_equal(collector.powered, true, "cancel restores collector power")
	_expect_equal(
		world._power_links.link_count(),
		3,
		"cancel restores the three-link visual tree"
	)
	world._tick_production(3.0)
	_expect_equal(collector.buffer, 1, "restored collector completes retained tick")
	_expect_equal(
		collector.production_progress,
		0.0,
		"collector drains exactly one retained interval"
	)

	_expect_equal(world.demolish_building(relay_two), true, "bridge relay demolishes")
	_expect_equal(relay_three.powered, false, "demolition disconnects downstream relay")
	_expect_equal(reactor.powered, false, "demolition disconnects reactor")
	_expect_equal(collector.powered, false, "demolition disconnects collector")
	_expect_equal(
		world._power_links.link_count(),
		1,
		"bridge demolition removes downstream visual links"
	)
	await process_frame
	await physics_frame
	var replacement := _place_building(
		world, SliceBuildingCatalog.POWER_RELAY_ID, Vector2i(31, 10), 0
	)
	if replacement == null:
		world.free()
		return
	_expect_equal(replacement.powered, true, "replacement bridge is powered")
	_expect_equal(relay_three.powered, true, "replacement reconnects downstream relay")
	_expect_equal(reactor.powered, true, "replacement reconnects reactor")
	_expect_equal(collector.powered, true, "replacement reconnects collector")
	_expect_equal(
		world._power_links.link_count(),
		3,
		"replacement rebuilds the visual tree"
	)

	world.core_repaired = false
	world._rebuild_power_grid()
	_expect_equal(world.powered_relay_count(), 0, "offline core clears relay reachability")
	_expect_equal(
		world._power_links.link_count(),
		0,
		"offline core clears all active visual links"
	)
	_expect_equal(reactor.powered, false, "offline core powers down reactor")
	_expect_equal(collector.powered, false, "offline core powers down collector")
	_expect_equal(world.reactor_active, false, "L3 does not activate reactor processing")
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


func _place_building(
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
		"%s validates at %s (reason: %s)" % [
			building_id,
			origin,
			String(validation.get("reason", "")),
		]
	)
	var index := world._building_instances.size()
	var placed := world.try_place_building()
	_expect_equal(placed, true, "%s places" % building_id)
	if not placed:
		return null
	return world._building_instances[index]


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
