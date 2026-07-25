extends SceneTree

var failures: Array[String] = []
var _assertion_count := 0


func _init() -> void:
	call_deferred("_execute")


func _execute() -> void:
	_check_storage_port_rotation()
	_check_straight_storage_transfer()
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
	var expected_ports := [
		Vector2i(11, 10),
		Vector2i(11, 11),
		Vector2i(10, 11),
		Vector2i(10, 10),
	]
	var expected_connections := [
		Vector2i(11, 9),
		Vector2i(12, 11),
		Vector2i(10, 12),
		Vector2i(9, 10),
	]
	for rotation in range(4):
		_expect_equal(
			definition.logistics_port_world_cell(origin, rotation),
			expected_ports[rotation],
			"storage rotation %d port cell" % rotation
		)
		_expect_equal(
			definition.logistics_connection_world_cell(origin, rotation),
			expected_connections[rotation],
			"storage rotation %d connection cell" % rotation
		)


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
		"building-000005", Vector2i(5, 1), 3
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
		"building-000012", Vector2i(3, 1), 3
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
		"building-000023", Vector2i(4, 1), 3
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
	rotation: int
) -> SliceStorage:
	var storage := SliceStorage.new()
	var definition := SliceBuildingCatalog.find(
		SliceBuildingCatalog.STORAGE_ID
	)
	storage.configure_building(
		instance_id, definition.building_id, origin, rotation
	)
	storage.apply_definition(definition, 32.0)
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


func _network_crystals(
	instances: Array[SliceBuildingInstance]
) -> int:
	var total := 0
	for instance in instances:
		if instance is SliceStorage:
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


func _free_instances(instances: Array[SliceBuildingInstance]) -> void:
	for instance in instances:
		instance.free()


func _expect_equal(actual, expected, label: String) -> void:
	_assertion_count += 1
	if actual != expected:
		failures.append(
			"%s: expected %s, got %s" % [label, expected, actual]
		)
