extends SceneTree

var failures: Array[String] = []
var _assertion_count := 0


func _init() -> void:
	call_deferred("_execute")


func _execute() -> void:
	_check_storage_port_rotation()
	_check_collector_output_transfer()
	_check_placement_port_feedback()
	_check_straight_storage_transfer()
	_check_double_turn_route_and_visuals()
	_check_loop_backpressure()
	_check_two_way_merge_round_robin()
	_check_three_way_merge_fairness()
	_check_merge_step_and_order_independence()
	_check_backpressure_and_content_gate()
	_check_step_size_independence()
	if failures.is_empty():
		print(
			"Slice logistics checks passed (%d assertions)."
			% _assertion_count
		)
		quit(0)
		return
	for failure in failures:
		push_error(failure)
	quit(1)


func _check_storage_port_rotation() -> void:
	var definition := SliceBuildingCatalog.find(
		SliceBuildingCatalog.STORAGE_ID
	)
	var origin := Vector2i(10, 10)
	for rotation in range(4):
		var storage := _make_storage(
			"building-rotation-%d" % rotation, origin, rotation
		)
		var endpoints := storage.logistics_endpoints()
		_expect_equal(
			endpoints.size(),
			1,
			"storage rotation %d binds one runtime endpoint" % rotation
		)
		var endpoint := endpoints[0]
		_expect_equal(
			endpoint.endpoint_id,
			"%s:output" % storage.instance_id,
			"storage rotation %d supply endpoint identity" % rotation
		)
		_expect_equal(
			endpoint.source_phase,
			0,
			"storage rotation %d keeps source phase" % rotation
		)
		var descriptors := definition.resolved_logistics_port_descriptors(
			origin, rotation
		)
		_expect_equal(
			descriptors.size(),
			2,
			"storage rotation %d resolves fixed IN and OUT" % rotation
		)
		var input_descriptor: Dictionary = descriptors[0]
		var output_descriptor: Dictionary = descriptors[1]
		_expect_equal(
			String(input_descriptor["id"]),
			"input",
			"storage rotation %d keeps stable input id" % rotation
		)
		_expect_equal(
			String(output_descriptor["id"]),
			"output",
			"storage rotation %d keeps stable output id" % rotation
		)
		_expect_equal(
			input_descriptor["port_cell"],
			Vector2i(10, 11),
			"storage rotation %d keeps fixed left input cell" % rotation
		)
		_expect_equal(
			input_descriptor["connection_cell"],
			Vector2i(9, 11),
			"storage rotation %d keeps fixed left connection" % rotation
		)
		_expect_equal(
			output_descriptor["port_cell"],
			Vector2i(11, 11),
			"storage rotation %d keeps fixed right output cell" % rotation
		)
		_expect_equal(
			output_descriptor["connection_cell"],
			Vector2i(12, 11),
			"storage rotation %d keeps fixed right connection" % rotation
		)
		_expect_equal(
			endpoint.port_cell,
			Vector2i(11, 11),
			"storage rotation %d runtime supply port" % rotation
		)
		_expect_equal(
			endpoint.connection_cell,
			Vector2i(12, 11),
			"storage rotation %d runtime supply connection" % rotation
		)
		storage.set_powered(false)
		storage.inventory.add(SliceWorld.ITEM_CRYSTAL, 1)
		_expect_equal(
			endpoint.peek_output_item(),
			"",
			"storage rotation %d unpowered supply stays closed" % rotation
		)
		_expect_equal(
			storage.set_mode(SliceStorage.MODE_TRANSFER),
			true,
			"storage rotation %d switches to transfer mode" % rotation
		)
		var input_endpoint := storage.logistics_endpoints()[0]
		_expect_equal(
			input_endpoint.endpoint_id,
			"%s:input" % storage.instance_id,
			"storage rotation %d activates only fixed input" % rotation
		)
		_expect_equal(
			input_endpoint.connection_cell,
			Vector2i(9, 11),
			"storage rotation %d transfer input remains fixed" % rotation
		)
		_expect_equal(
			input_endpoint.try_accept_one(SliceWorld.ITEM_CATALYST),
			1,
			"storage rotation %d transfer input works without power" % rotation
		)
		storage.free()


func _check_collector_output_transfer() -> void:
	var collector := SliceCollector.new()
	var definition := SliceBuildingCatalog.find(
		SliceBuildingCatalog.COLLECTOR_ID
	)
	collector.configure_building(
		"building-collector-output", definition.building_id, Vector2i.ZERO, 3
	)
	collector.apply_definition(definition, 32.0)
	collector.buffer = 2
	var belt := _make_conveyor(
		"building-collector-belt", Vector2i(2, 1), 1
	)
	var target := _make_storage(
		"building-collector-target",
		Vector2i(3, 0),
		2,
		SliceStorage.MODE_TRANSFER
	)
	var instances: Array[SliceBuildingInstance] = [collector, belt, target]
	var grid := SliceLogisticsGrid.new()
	grid.rebuild(instances)
	var endpoint := collector.logistics_endpoints()[0]
	_expect_equal(
		endpoint.port_cell,
		Vector2i(1, 1),
		"collector output stays on locked local cell for legacy rotation"
	)
	_expect_equal(
		endpoint.connection_cell,
		Vector2i(2, 1),
		"collector output stays fixed to the right connection"
	)
	grid.tick(0.1)
	_expect_equal(collector.buffer, 1, "collector injects exactly one crystal")
	_expect_equal(belt.has_cargo(), true, "collector feeds its right-hand belt")
	for _step in range(3):
		grid.tick(1.0)
	_expect_equal(
		target.inventory.count(SliceWorld.ITEM_CRYSTAL),
		2,
		"collector buffer reaches an unpowered transfer input"
	)
	_expect_equal(
		_network_crystals(instances),
		2,
		"collector logistics conserves its authoritative buffer"
	)
	_free_instances(instances)


func _check_placement_port_feedback() -> void:
	var source := _make_storage(
		"building-000100", Vector2i(19, 13), 0
	)
	var disconnected_belt := _make_conveyor(
		"building-000101", Vector2i(21, 13), 1
	)
	var reactor := _make_reactor(
		"building-000102", Vector2i(24, 12), 1
	)
	var grid := SliceLogisticsGrid.new()
	grid.rebuild([source, disconnected_belt, reactor])
	source.inventory.add(SliceWorld.ITEM_CRYSTAL, 1)
	grid.tick(0.1)
	_expect_equal(
		source.inventory.count(SliceWorld.ITEM_CRYSTAL),
		1,
		"a belt beside the body does not silently connect to the fixed port"
	)
	_expect_equal(
		grid.building_status_lines(source)[0].contains("未接传送带"),
		true,
		"storage panel exposes the disconnected logistics port"
	)
	var disconnected_status := grid.building_status_snapshot(source)[0]
	_expect_equal(
		String(disconnected_status["state"]),
		"unconnected",
		"storage exposes a structured disconnected port state"
	)
	_expect_equal(
		String(disconnected_status["detail"]).contains("OUT 标记格"),
		true,
		"structured supply state includes the physical output target"
	)
	var nearby := grid.conveyor_placement_preview(
		Vector2i(21, 13), 1
	)
	_expect_equal(
		String(nearby["status"]),
		"nearby",
		"the misleading body-adjacent belt is identified as only nearby"
	)
	_expect_equal(
		String(nearby["message"]).contains("端口标记格"),
		true,
		"nearby placement tells the player to use the marked cell"
	)

	var storage_output := grid.conveyor_placement_preview(
		Vector2i(21, 14), 1
	)
	_expect_equal(
		String(storage_output["status"]),
		"connected",
		"belt on the storage port cell and outward axis is connected"
	)
	_expect_equal(
		String(storage_output["message"]).contains("OUT"),
		true,
		"storage source preview names its output flow"
	)
	var storage_wrong := grid.conveyor_placement_preview(
		Vector2i(21, 14), 0
	)
	_expect_equal(
		String(storage_wrong["status"]),
		"wrong_direction",
		"perpendicular belt on a storage connection is rejected"
	)
	_expect_equal(
		String(
			grid.conveyor_placement_preview(
				Vector2i(22, 14), 1
			)["message"]
		).contains("IN"),
		true,
		"reactor input connection is named in placement feedback"
	)
	_expect_equal(
		String(
			grid.conveyor_placement_preview(
				Vector2i(28, 14), 1
			)["message"]
		).contains("OUT"),
		true,
		"reactor output connection is named in placement feedback"
	)

	var conveyor_definition := SliceBuildingCatalog.find(
		SliceBuildingCatalog.CONVEYOR_ID
	)
	var overlay_parent := Node2D.new()
	root.add_child(overlay_parent)
	var overlay := SlicePlacementOverlay.new()
	overlay_parent.add_child(overlay)
	overlay.configure(
		conveyor_definition,
		Vector2i(22, 14),
		1,
		32.0,
		{"valid": true},
		[],
		grid.placement_preview_ports()
	)
	_expect_equal(
		overlay.context_logistics_port_marker_count(),
		3,
		"conveyor preview keeps nearby storage and reactor ports visible"
	)
	_expect_equal(
		overlay.matched_context_logistics_port_marker_count(),
		1,
		"matching reactor input marker is highlighted"
	)
	overlay.configure(
		conveyor_definition,
		Vector2i(22, 14),
		3,
		32.0,
		{"valid": true},
		[],
		grid.placement_preview_ports()
	)
	_expect_equal(
		overlay.matched_context_logistics_port_marker_count(),
		0,
		"wrong conveyor direction never receives a success marker"
	)
	overlay_parent.free()

	var connected_belt := _make_conveyor(
		"building-000103", Vector2i(21, 14), 1
	)
	grid.rebuild([source, connected_belt, reactor])
	grid.tick(0.1)
	_expect_equal(
		source.inventory.is_empty(),
		true,
		"corrected storage connection starts shipping immediately"
	)
	_expect_equal(
		connected_belt.has_cargo(),
		true,
		"corrected source belt receives the crystal"
	)
	_expect_equal(
		grid.building_status_lines(source)[0].contains("OUT：已接"),
		true,
		"storage panel confirms the effective output connection"
	)
	var connected_status := grid.building_status_snapshot(source)[0]
	_expect_equal(
		String(connected_status["state"]),
		"connected",
		"storage exposes a structured output connection"
	)
	_expect_equal(
		String(connected_status["label"]),
		"OUT",
		"structured storage connection identifies its flow direction"
	)
	_free_instances([
		source,
		disconnected_belt,
		connected_belt,
		reactor,
	])


func _check_straight_storage_transfer() -> void:
	var source := _make_storage(
		"building-000001", Vector2i(0, 0), 1
	)
	var belt_one := _make_conveyor(
		"building-000002", Vector2i(2, 1), 1
	)
	var belt_two := _make_conveyor(
		"building-000003", Vector2i(3, 1), 1
	)
	var belt_three := _make_conveyor(
		"building-000004", Vector2i(4, 1), 1
	)
	var target := _make_storage(
		"building-000005",
		Vector2i(5, 0),
		3,
		SliceStorage.MODE_TRANSFER
	)
	var instances: Array[SliceBuildingInstance] = [
		source, belt_one, belt_two, belt_three, target,
	]
	var grid := SliceLogisticsGrid.new()
	grid.rebuild(instances)
	source.inventory.add(SliceWorld.ITEM_CRYSTAL, 2)

	grid.tick(0.1)
	_expect_equal(
		source.inventory.count(SliceWorld.ITEM_CRYSTAL),
		1,
		"source injects one crystal"
	)
	_expect_equal(belt_one.has_cargo(), true, "first belt receives cargo")
	_expect_equal(
		belt_one.get_node_or_null("Cargo") != null,
		true,
		"cargo owns a world sprite"
	)

	for _step in range(5):
		grid.tick(1.0)
	_expect_equal(
		target.inventory.count(SliceWorld.ITEM_CRYSTAL),
		2,
		"two crystals arrive at target storage"
	)
	_expect_equal(_network_crystals(instances), 2, "transfer conserves items")
	_expect_equal(
		source.inventory.is_empty(),
		true,
		"source empties after transfer"
	)
	_free_instances(instances)


func _check_backpressure_and_content_gate() -> void:
	var source := _make_storage(
		"building-000010", Vector2i(0, 0), 1
	)
	var belt := _make_conveyor(
		"building-000011", Vector2i(2, 1), 1
	)
	var target := _make_storage(
		"building-000012",
		Vector2i(3, 0),
		3,
		SliceStorage.MODE_TRANSFER
	)
	var instances: Array[SliceBuildingInstance] = [source, belt, target]
	var grid := SliceLogisticsGrid.new()
	grid.rebuild(instances)
	target.inventory.add(SliceWorld.ITEM_CRYSTAL, SliceStorage.CAPACITY)
	source.inventory.add(SliceWorld.ITEM_CRYSTAL, 1)

	grid.tick(0.1)
	grid.tick(2.0)
	_expect_equal(belt.has_cargo(), true, "full target backs cargo up")
	_expect_equal(
		belt.cargo_progress < 1.0,
		true,
		"blocked cargo remains in serializable progress range"
	)
	_expect_equal(
		belt.content_block_reason(),
		"先清空传送带",
		"loaded conveyor blocks adjustment and demolition"
	)
	_expect_equal(
		_network_crystals(instances),
		SliceStorage.CAPACITY + 1,
		"backpressure conserves all crystals"
	)
	var state := belt.state_dict(belt.definition.state_keys)
	_expect_equal(
		String(state["cargo"]["item_id"]),
		SliceWorld.ITEM_CRYSTAL,
		"cargo state carries item id"
	)
	_expect_equal(
		int(state["merge_cursor"]),
		0,
		"package one keeps merge cursor stable"
	)
	_free_instances(instances)


func _check_double_turn_route_and_visuals() -> void:
	var source := _make_storage(
		"building-000030", Vector2i(0, 0), 1
	)
	var belt_source := _make_conveyor(
		"building-000031", Vector2i(2, 1), 1
	)
	var belt_turn_down := _make_conveyor(
		"building-000032", Vector2i(3, 1), 2
	)
	var belt_turn_right := _make_conveyor(
		"building-000033", Vector2i(3, 2), 1
	)
	var belt_sink := _make_conveyor(
		"building-000034", Vector2i(4, 2), 1
	)
	var target := _make_storage(
		"building-000035",
		Vector2i(5, 1),
		3,
		SliceStorage.MODE_TRANSFER
	)
	var instances: Array[SliceBuildingInstance] = [
		source,
		belt_source,
		belt_turn_down,
		belt_turn_right,
		belt_sink,
		target,
	]
	var grid := SliceLogisticsGrid.new()
	grid.rebuild(instances)

	_expect_equal(
		belt_source.topology_kind(),
		SliceConveyor.TOPOLOGY_SOURCE_ENDPOINT,
		"source-connected belt selects fixed source endpoint frame"
	)
	_expect_equal(
		belt_turn_down.topology_kind(),
		SliceConveyor.TOPOLOGY_TURN,
		"first perpendicular input selects a turn frame"
	)
	_expect_equal(
		belt_turn_down.entry_direction(),
		Vector2i.LEFT,
		"first turn derives its left entry side"
	)
	_expect_equal(
		belt_turn_right.entry_direction(),
		Vector2i.UP,
		"second turn derives its upper entry side"
	)
	_expect_equal(
		belt_sink.topology_kind(),
		SliceConveyor.TOPOLOGY_SINK_ENDPOINT,
		"target-connected belt selects fixed sink endpoint frame"
	)
	_expect_equal(
		_texture_path(belt_turn_down).ends_with(
			"conveyor_in_left_out_down.png"
		),
		true,
		"first turn uses the reviewed left-to-down fixed frame"
	)
	_expect_equal(
		_texture_path(belt_turn_right).ends_with(
			"conveyor_in_up_out_right.png"
		),
		true,
		"second turn uses the reviewed up-to-right fixed frame"
	)

	var first_leg := belt_turn_down.cargo_local_position_for_progress(
		0.25
	)
	var second_leg := belt_turn_down.cargo_local_position_for_progress(
		0.75
	)
	_expect_equal(
		is_equal_approx(first_leg.y, -16.0),
		true,
		"turn cargo first half remains horizontal"
	)
	_expect_equal(
		is_equal_approx(second_leg.x, 0.0),
		true,
		"turn cargo second half remains vertical"
	)

	source.inventory.add(SliceWorld.ITEM_CRYSTAL, 3)
	for _step in range(10):
		grid.tick(1.0)
	_expect_equal(
		target.inventory.count(SliceWorld.ITEM_CRYSTAL),
		3,
		"three crystals traverse a double-turn route"
	)
	_expect_equal(
		_network_crystals(instances),
		3,
		"double-turn route conserves all crystals"
	)

	grid.rebuild([
		belt_turn_down,
		belt_turn_right,
		belt_sink,
		target,
	])
	_expect_equal(
		belt_turn_down.topology_kind(),
		SliceConveyor.TOPOLOGY_STRAIGHT,
		"topology refresh removes a stale turn in the rebuild frame"
	)
	_free_instances(instances)


func _check_loop_backpressure() -> void:
	var belt_right := _make_conveyor(
		"building-000040", Vector2i(0, 0), 1
	)
	var belt_down := _make_conveyor(
		"building-000041", Vector2i(1, 0), 2
	)
	var belt_left := _make_conveyor(
		"building-000042", Vector2i(1, 1), 3
	)
	var belt_up := _make_conveyor(
		"building-000043", Vector2i(0, 1), 0
	)
	var instances: Array[SliceBuildingInstance] = [
		belt_right, belt_down, belt_left, belt_up,
	]
	var grid := SliceLogisticsGrid.new()
	grid.rebuild(instances)
	for conveyor in [
		belt_right, belt_down, belt_left, belt_up,
	]:
		conveyor.set_cargo(SliceWorld.ITEM_CRYSTAL, 0.95)
		_expect_equal(
			conveyor.topology_kind(),
			SliceConveyor.TOPOLOGY_TURN,
			"each loop corner derives a fixed turn frame"
		)
	grid.tick(4.0)
	_expect_equal(
		_network_crystals(instances),
		4,
		"full loop backpressure conserves all cargo"
	)
	for conveyor in [
		belt_right, belt_down, belt_left, belt_up,
	]:
		_expect_equal(
			conveyor.has_cargo(),
			true,
			"full loop retains each occupied belt slot"
		)
		_expect_equal(
			conveyor.cargo_progress < 1.0,
			true,
			"full loop keeps progress serializable while blocked"
		)
	_free_instances(instances)


func _check_two_way_merge_round_robin() -> void:
	var upstream_top := _make_conveyor(
		"building-000050", Vector2i(0, -1), 2
	)
	var upstream_bottom := _make_conveyor(
		"building-000051", Vector2i(0, 1), 0
	)
	var merge := _make_conveyor(
		"building-000052", Vector2i(0, 0), 1
	)
	var instances: Array[SliceBuildingInstance] = [
		merge, upstream_bottom, upstream_top,
	]
	var grid := SliceLogisticsGrid.new()
	grid.rebuild(instances)
	_expect_equal(
		merge.topology_kind(),
		SliceConveyor.TOPOLOGY_MERGE,
		"two upstreams derive a merge topology"
	)
	_expect_equal(
		merge.topology_input_directions(),
		[Vector2i.UP, Vector2i.DOWN],
		"merge inputs use stable screen-direction order"
	)
	_expect_equal(
		_texture_path(merge).ends_with(
			"conveyor_merge_in_up_down_out_right.png"
		),
		true,
		"two-way merge selects its fixed topology frame"
	)

	var winners: Array[String] = []
	for _round in range(6):
		merge.clear_cargo()
		if not upstream_top.has_cargo():
			upstream_top.set_cargo(SliceWorld.ITEM_CRYSTAL, 1.0)
		if not upstream_bottom.has_cargo():
			upstream_bottom.set_cargo(
				SliceWorld.ITEM_CRYSTAL, 1.0
			)
		grid.tick(SliceLogisticsGrid.SIMULATION_STEP_SECONDS)
		_expect_equal(merge.has_cargo(), true, "merge accepts one contender")
		if not upstream_top.has_cargo():
			winners.append(upstream_top.instance_id)
		else:
			winners.append(upstream_bottom.instance_id)
	_expect_equal(
		winners,
		[
			upstream_top.instance_id,
			upstream_bottom.instance_id,
			upstream_top.instance_id,
			upstream_bottom.instance_id,
			upstream_top.instance_id,
			upstream_bottom.instance_id,
		],
		"two ready inputs alternate by persistent round-robin cursor"
	)
	_expect_equal(
		merge.merge_cursor,
		0,
		"six two-way grants wrap the merge cursor"
	)
	_expect_equal(
		merge.cargo_entry_direction(),
		Vector2i.DOWN,
		"winning source controls the visible cargo entry side"
	)
	var first_leg := merge.cargo_local_position_for_progress(0.25)
	_expect_equal(
		is_equal_approx(first_leg.x, 0.0),
		true,
		"merge cargo first half follows its orthogonal input leg"
	)
	_free_instances(instances)


func _check_three_way_merge_fairness() -> void:
	var upstream_left := _make_conveyor(
		"building-000060", Vector2i(-1, 0), 1
	)
	var upstream_top := _make_conveyor(
		"building-000061", Vector2i(0, -1), 2
	)
	var upstream_bottom := _make_conveyor(
		"building-000062", Vector2i(0, 1), 0
	)
	var merge := _make_conveyor(
		"building-000063", Vector2i(0, 0), 1
	)
	var instances: Array[SliceBuildingInstance] = [
		upstream_bottom, merge, upstream_left, upstream_top,
	]
	var grid := SliceLogisticsGrid.new()
	grid.rebuild(instances)
	_expect_equal(
		_texture_path(merge).ends_with(
			"conveyor_merge_in_up_down_left_out_right.png"
		),
		true,
		"three-way merge selects its fixed topology frame"
	)

	var grant_counts := {
		upstream_left.instance_id: 0,
		upstream_top.instance_id: 0,
		upstream_bottom.instance_id: 0,
	}
	var upstreams: Array[SliceConveyor] = [
		upstream_left, upstream_top, upstream_bottom,
	]
	for _round in range(9):
		merge.clear_cargo()
		for upstream in upstreams:
			if not upstream.has_cargo():
				upstream.set_cargo(
					SliceWorld.ITEM_CRYSTAL, 1.0
				)
		grid.tick(SliceLogisticsGrid.SIMULATION_STEP_SECONDS)
		for upstream in upstreams:
			if not upstream.has_cargo():
				grant_counts[upstream.instance_id] += 1
	for upstream in upstreams:
		_expect_equal(
			int(grant_counts[upstream.instance_id]),
			3,
			"three-way round robin grants each source three times"
		)
	_expect_equal(
		merge.merge_cursor,
		0,
		"nine three-way grants wrap the persistent cursor"
	)
	var state := merge.state_dict(merge.definition.state_keys)
	_expect_equal(
		int(state["merge_cursor"]),
		0,
		"merge state serializes the current round-robin cursor"
	)
	_free_instances(instances)


func _check_merge_step_and_order_independence() -> void:
	var fine := _simulate_merge_for(8.0, 0.1, false)
	var coarse := _simulate_merge_for(8.0, 0.25, false)
	var reversed := _simulate_merge_for(8.0, 0.1, true)
	for key in [
		"source_top",
		"source_bottom",
		"target",
		"cargo_count",
		"merge_cursor",
		"total",
	]:
		_expect_equal(
			fine[key],
			coarse[key],
			"merge result %s is step-size independent" % key
		)
		_expect_equal(
			fine[key],
			reversed[key],
			"merge result %s ignores input node traversal order" % key
		)
	_expect_equal(
		int(fine["total"]),
		12,
		"multi-source simulation conserves all crystals"
	)


func _simulate_merge_for(
	duration: float,
	step: float,
	reverse_instances: bool
) -> Dictionary:
	var source_top := _make_storage(
		"building-000070", Vector2i(-3, -3), 2
	)
	var source_bottom := _make_storage(
		"building-000071", Vector2i(-3, 1), 0
	)
	var top_feed := _make_conveyor(
		"building-000072", Vector2i(-1, -2), 1
	)
	var top_turn := _make_conveyor(
		"building-000073", Vector2i(0, -2), 2
	)
	var upstream_top := _make_conveyor(
		"building-000074", Vector2i(0, -1), 2
	)
	var bottom_feed := _make_conveyor(
		"building-000075", Vector2i(-1, 2), 1
	)
	var bottom_turn := _make_conveyor(
		"building-000076", Vector2i(0, 2), 0
	)
	var upstream_bottom := _make_conveyor(
		"building-000077", Vector2i(0, 1), 0
	)
	var merge := _make_conveyor(
		"building-000078", Vector2i(0, 0), 1
	)
	var sink_belt := _make_conveyor(
		"building-000079", Vector2i(1, 0), 1
	)
	var target := _make_storage(
		"building-000080",
		Vector2i(2, -1),
		3,
		SliceStorage.MODE_TRANSFER
	)
	var instances: Array[SliceBuildingInstance] = [
		source_top,
		source_bottom,
		top_feed,
		top_turn,
		upstream_top,
		bottom_feed,
		bottom_turn,
		upstream_bottom,
		merge,
		sink_belt,
		target,
	]
	if reverse_instances:
		instances.reverse()
	source_top.inventory.add(SliceWorld.ITEM_CRYSTAL, 6)
	source_bottom.inventory.add(SliceWorld.ITEM_CRYSTAL, 6)
	var grid := SliceLogisticsGrid.new()
	grid.rebuild(instances)
	var elapsed := 0.0
	while elapsed < duration:
		var delta := minf(step, duration - elapsed)
		grid.tick(delta)
		elapsed += delta
	var result := {
		"source_top": source_top.inventory.count(
			SliceWorld.ITEM_CRYSTAL
		),
		"source_bottom": source_bottom.inventory.count(
			SliceWorld.ITEM_CRYSTAL
		),
		"target": target.inventory.count(SliceWorld.ITEM_CRYSTAL),
		"cargo_count": _network_crystals(instances)
			- source_top.inventory.count(SliceWorld.ITEM_CRYSTAL)
			- source_bottom.inventory.count(SliceWorld.ITEM_CRYSTAL)
			- target.inventory.count(SliceWorld.ITEM_CRYSTAL),
		"merge_cursor": merge.merge_cursor,
		"total": _network_crystals(instances),
	}
	_free_instances(instances)
	return result


func _check_step_size_independence() -> void:
	var fine := _simulate_for(8.0, 0.1)
	var coarse := _simulate_for(8.0, 0.25)
	_expect_equal(
		fine["source"],
		coarse["source"],
		"source inventory is step-size independent"
	)
	_expect_equal(
		fine["target"],
		coarse["target"],
		"target inventory is step-size independent"
	)
	_expect_equal(
		fine["cargo_count"],
		coarse["cargo_count"],
		"belt occupancy is step-size independent"
	)
	_expect_equal(
		int(fine["total"]),
		5,
		"fine-step simulation conserves starting inventory"
	)
	_expect_equal(
		int(coarse["total"]),
		5,
		"coarse-step simulation conserves starting inventory"
	)


func _simulate_for(duration: float, step: float) -> Dictionary:
	var source := _make_storage(
		"building-000020", Vector2i(0, 0), 1
	)
	var belt_one := _make_conveyor(
		"building-000021", Vector2i(2, 1), 1
	)
	var belt_two := _make_conveyor(
		"building-000022", Vector2i(3, 1), 1
	)
	var target := _make_storage(
		"building-000023",
		Vector2i(4, 0),
		3,
		SliceStorage.MODE_TRANSFER
	)
	var instances: Array[SliceBuildingInstance] = [
		source, belt_one, belt_two, target,
	]
	source.inventory.add(SliceWorld.ITEM_CRYSTAL, 5)
	var grid := SliceLogisticsGrid.new()
	grid.rebuild(instances)
	var elapsed := 0.0
	while elapsed < duration:
		var delta := minf(step, duration - elapsed)
		grid.tick(delta)
		elapsed += delta
	var result := {
		"source": source.inventory.count(SliceWorld.ITEM_CRYSTAL),
		"target": target.inventory.count(SliceWorld.ITEM_CRYSTAL),
		"cargo_count": int(belt_one.has_cargo()) + int(belt_two.has_cargo()),
		"total": _network_crystals(instances),
	}
	_free_instances(instances)
	return result


func _make_storage(
	instance_id: String,
	origin: Vector2i,
	rotation: int,
	mode: String = SliceStorage.MODE_SUPPLY
) -> SliceStorage:
	var storage := SliceStorage.new()
	var definition := SliceBuildingCatalog.find(
		SliceBuildingCatalog.STORAGE_ID
	)
	storage.configure_building(
		instance_id, definition.building_id, origin, rotation
	)
	storage.apply_definition(definition, 32.0)
	if mode == SliceStorage.MODE_TRANSFER:
		storage.set_mode(mode)
	else:
		storage.set_output_item(SliceWorld.ITEM_CRYSTAL)
	storage.set_powered(mode == SliceStorage.MODE_SUPPLY)
	return storage


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


func _make_reactor(
	instance_id: String,
	origin: Vector2i,
	rotation: int
) -> SliceReactor:
	var reactor := SliceReactor.new()
	var definition := SliceBuildingCatalog.find(
		SliceBuildingCatalog.REACTOR_ID
	)
	reactor.configure_building(
		instance_id, definition.building_id, origin, rotation
	)
	reactor.apply_definition(definition, 32.0)
	return reactor


func _network_crystals(
	instances: Array[SliceBuildingInstance]
) -> int:
	var total := 0
	for instance in instances:
		if instance is SliceCollector:
			total += (instance as SliceCollector).buffer
		elif instance is SliceStorage:
			total += (instance as SliceStorage).inventory.count(
				SliceWorld.ITEM_CRYSTAL
			)
		elif (
			instance is SliceConveyor
			and (instance as SliceConveyor).cargo_item_id
			== SliceWorld.ITEM_CRYSTAL
		):
			total += 1
	return total


func _texture_path(conveyor: SliceConveyor) -> String:
	var sprite := conveyor.get_node_or_null("Sprite") as Sprite2D
	if sprite == null or sprite.texture == null:
		return ""
	return sprite.texture.resource_path


func _free_instances(instances: Array[SliceBuildingInstance]) -> void:
	for instance in instances:
		instance.free()


func _expect_equal(actual, expected, label: String) -> void:
	_assertion_count += 1
	if actual != expected:
		failures.append(
			"%s: expected %s, got %s" % [label, expected, actual]
		)
