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
	var storage := SliceBuildingCatalog.find(SliceBuildingCatalog.STORAGE_ID)
	_expect_equal(
		SliceWorld.CORE_LINK_ANCHOR_OFFSET,
		Vector2(8, -80),
		"repaired core line starts at the locked V5 upper ring"
	)
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
		storage.power_role,
		SliceBuildingDefinition.POWER_CONSUMER,
		"storage is a real power consumer"
	)
	_expect_equal(
		collector.rotated_power_port_cell(0),
		Vector2i(-1, -1),
		"collector no longer overloads an edge cell as its power probe"
	)
	_expect_equal(
		collector.rotated_power_port_cell(1),
		Vector2i(-1, -1),
		"fixed collector probe is independent of rotation"
	)
	_expect_equal(
		reactor.rotated_power_port_cell(2),
		Vector2i(-1, -1),
		"fixed reactor probe is independent of rotation"
	)
	var origin := Vector2i(10, 10)
	for rotation in range(4):
		_expect_equal(
			collector.logic_power_probe_world_position(origin, 32.0, rotation),
			Vector2(352, 352),
			"collector rotation %d resolves to its footprint center" % rotation
		)
		_expect_equal(
			reactor.logic_power_probe_world_position(origin, 32.0, rotation),
			Vector2(368, 368),
			"reactor rotation %d resolves to its footprint center" % rotation
		)
		_expect_equal(
			storage.logic_power_probe_world_position(origin, 32.0, rotation),
			Vector2(352, 352),
			"storage rotation %d resolves to its footprint center" % rotation
		)
	_expect_equal(
		collector.power_visual_anchor_world_position(origin, 32.0, 0),
		Vector2(352, 274),
		"collector line anchor resolves to locked V1 texture pixel"
	)
	_expect_equal(
		reactor.power_visual_anchor_world_position(origin, 32.0, 0),
		Vector2(368, 350),
		"reactor line anchor resolves to locked V10 texture pixel"
	)
	_expect_equal(
		storage.power_visual_anchor_world_position(origin, 32.0, 0),
		Vector2(352, 322),
		"storage line anchor resolves to locked V1 texture pixel"
	)
	_expect_equal(
		relay.power_visual_terminal_offsets.size(),
		4,
		"locked relay exposes four non-persistent visual terminals"
	)
	var relay_center := relay.block_center(origin, 32.0, 0)
	var terminal_cases := [
		[Vector2.LEFT, SliceBuildingDefinition.POWER_TERMINAL_WEST, Vector2(316, 290)],
		[Vector2.UP, SliceBuildingDefinition.POWER_TERMINAL_NORTH, Vector2(336, 279)],
		[Vector2.RIGHT, SliceBuildingDefinition.POWER_TERMINAL_EAST, Vector2(355, 290)],
		[Vector2.DOWN, SliceBuildingDefinition.POWER_TERMINAL_FRONT, Vector2(336, 299)],
	]
	for terminal_case in terminal_cases:
		var toward := relay_center + Vector2(terminal_case[0]) * 100.0
		_expect_equal(
			relay.power_visual_terminal_toward(origin, 32.0, 0, toward),
			String(terminal_case[1]),
			"relay selects its %s terminal by real relative direction" % terminal_case[1]
		)
		_expect_equal(
			relay.power_visual_anchor_toward_world_position(
				origin, 32.0, 0, toward
			),
			Vector2(terminal_case[2]),
			"relay %s terminal resolves to the locked V2 pixel" % terminal_case[1]
		)
	_expect_equal(
		storage.power_visual_anchor_toward_world_position(
			origin, 32.0, 0, Vector2.ZERO
		),
		Vector2(352, 322),
		"consumer direction never changes its single locked top anchor"
	)
	_expect_equal(SlicePowerLinkLayer.POWER_WIDTH, 1.0, "Gate A line width is 1px")
	_expect_equal(
		relay.powered_texture_path,
		"",
		"relay never swaps the locked V2 body"
	)
	_expect_equal(
		relay.texture_path_for_rotation(3).ends_with("power_relay.png"),
		true,
		"every relay rotation request resolves to the locked V2 body"
	)


func _check_multihop_world_grid() -> void:
	_save_dir = SliceCheckPaths.check_run("power-grid")
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
	_spawn_floor_rect(world, Vector2i(34, 12), Vector2i(2, 2))

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
		await process_frame
		return
	var relay_three := _place_building(
		world, SliceBuildingCatalog.POWER_RELAY_ID, Vector2i(37, 10), 0
	)
	if relay_three == null:
		world.free()
		await process_frame
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
	var visual_links := world._power_links.links_snapshot()
	for index in range(mini(connections.size(), visual_links.size())):
		var connection: Dictionary = connections[index]
		var visual_link: Dictionary = visual_links[index]
		var expected_from := SlicePowerVisualResolver.anchor_world_position(
			String(connection["parent_id"]),
			Vector2(connection["from_position"]),
			Vector2(connection["to_position"]),
			world._building_instances,
			SliceWorld.CORE_LINK_ANCHOR_OFFSET,
			SliceWorld.RELAY_LINK_ANCHOR_OFFSET
		)
		var expected_to := SlicePowerVisualResolver.anchor_world_position(
			String(connection["child_id"]),
			Vector2(connection["to_position"]),
			Vector2(connection["from_position"]),
			world._building_instances,
			SliceWorld.CORE_LINK_ANCHOR_OFFSET,
			SliceWorld.RELAY_LINK_ANCHOR_OFFSET
		)
		_expect_equal(
			Vector2(visual_link["from_position"]),
			expected_from,
			"visual link %d uses the locked device start anchor" % index
		)
		_expect_equal(
			Vector2(visual_link["to_position"]),
			expected_to,
			"visual link %d selects the facing relay terminal" % index
		)
	_expect_equal(world._power_links.z_index, 1, "power segments stay visible on device anchors")
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
			"power_relay.png"
		),
		true,
		"powered relay keeps the locked V2 body"
	)
	_expect_equal(
		relay_three.get_node_or_null("PowerIndicator") != null,
		true,
		"relay power state uses a derived runtime lamp"
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
	var storage := _place_building(
		world, SliceBuildingCatalog.STORAGE_ID, Vector2i(34, 12), 0
	) as SliceStorage
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
	_expect_equal(storage.powered, true, "storage probe is within relay coverage")
	_expect_equal(collector.powered, true, "collector port is within relay coverage")
	connections = world._power_grid.powered_connections()
	_expect_equal(connections.size(), 6, "three real consumers add three derived power edges")
	_expect_equal(world._power_links.link_count(), 6, "link layer includes powered consumers")
	for consumer_value in [reactor, storage, collector]:
		var consumer := consumer_value as SliceBuildingInstance
		var consumer_connection := _connection_for_child(
			connections, consumer.instance_id
		)
		_expect_equal(
			String(consumer_connection.get("parent_id", "")),
			relay_three.instance_id,
			"%s line uses its real supplying relay" % consumer.building_id
		)
		_expect_equal(
			String(consumer_connection.get("child_role", "")),
			SliceBuildingDefinition.POWER_CONSUMER,
			"%s edge is marked as a consumer relation" % consumer.building_id
		)
	storage.inventory.add(SliceWorld.ITEM_CRYSTAL, 1)
	storage.set_output_item(SliceWorld.ITEM_CRYSTAL)
	var storage_endpoint: SliceLogisticsEndpoint = (
		storage.logistics_endpoints()[0]
	)
	_expect_equal(
		storage_endpoint.peek_output_item(),
		SliceWorld.ITEM_CRYSTAL,
		"powered supply storage exposes its selected output"
	)
	_expect_equal(world.toggle_storage_mode(storage), true, "storage enters transfer mode")
	_expect_equal(storage.powered, true, "mode does not fabricate a power-state change")
	_expect_equal(world._power_links.link_count(), 6, "transfer mode keeps the real power line")
	_expect_equal(world.toggle_storage_mode(storage), true, "storage returns to supply mode")
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
	_expect_equal(
		(reactor.get_node("PowerIndicator") as Polygon2D).z_index == 0
		and (
			collector.get_node("PowerIndicator") as Polygon2D
		).z_index == 0,
		true,
		"consumer indicators stay on the device y-sort plane"
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
		3,
		"bridge relay reports all three affected consumers"
	)

	collector.production_progress = 0.25
	world._tick_production(0.25)
	_expect_equal(
		collector.production_progress,
		0.5,
		"powered collector advances independent tick progress"
	)
	_expect_equal(
		world.begin_building_adjustment(relay_two),
		true,
		"bridge relay enters adjustment"
	)
	_expect_equal(relay_three.powered, false, "downstream relay drops same frame")
	_expect_equal(reactor.powered, false, "reactor drops same frame")
	_expect_equal(storage.powered, false, "storage drops same frame")
	_expect_equal(collector.powered, false, "collector drops same frame")
	_expect_equal(
		storage_endpoint.peek_output_item(),
		"",
		"unpowered supply storage stops automatic output"
	)
	_expect_equal(
		world._power_links.link_count(),
		1,
		"adjustment removes disconnected derived links in the same frame"
	)
	_expect_equal(
		(relay_three.get_node("Sprite") as Sprite2D).texture.resource_path.ends_with(
			"power_relay.png"
		),
		true,
		"disconnected relay still keeps the locked V2 body"
	)
	world._tick_production(10.0)
	_expect_equal(
		collector.production_progress,
		0.5,
		"unpowered collector preserves partial progress"
	)
	_expect_equal(collector.buffer, 0, "unpowered collector produces nothing")
	world.cancel_building_placement()
	_expect_equal(relay_three.powered, true, "cancel restores downstream relay")
	_expect_equal(reactor.powered, true, "cancel restores reactor power")
	_expect_equal(storage.powered, true, "cancel restores storage power")
	_expect_equal(collector.powered, true, "cancel restores collector power")
	_expect_equal(
		world._power_links.link_count(),
		6,
		"cancel restores relay and consumer visual edges"
	)
	world._tick_production(0.5)
	_expect_equal(collector.buffer, 1, "restored collector completes retained tick")
	_expect_equal(
		collector.production_progress,
		0.0,
		"collector drains exactly one retained interval"
	)

	_expect_equal(world.demolish_building(relay_two), true, "bridge relay demolishes")
	_expect_equal(relay_three.powered, false, "demolition disconnects downstream relay")
	_expect_equal(reactor.powered, false, "demolition disconnects reactor")
	_expect_equal(storage.powered, false, "demolition disconnects storage")
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
		await process_frame
		return
	_expect_equal(replacement.powered, true, "replacement bridge is powered")
	_expect_equal(relay_three.powered, true, "replacement reconnects downstream relay")
	_expect_equal(reactor.powered, true, "replacement reconnects reactor")
	_expect_equal(storage.powered, true, "replacement reconnects storage")
	_expect_equal(collector.powered, true, "replacement reconnects collector")
	_expect_equal(
		world._power_links.link_count(),
		6,
		"replacement rebuilds relay and consumer visual edges"
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
	_expect_equal(storage.powered, false, "offline core powers down storage")
	_expect_equal(collector.powered, false, "offline core powers down collector")
	world.free()
	await process_frame
	await create_timer(0.20).timeout


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


func _connection_for_child(
	connections: Array[Dictionary],
	child_id: String
) -> Dictionary:
	for connection in connections:
		if String(connection.get("child_id", "")) == child_id:
			return connection
	return {}


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
