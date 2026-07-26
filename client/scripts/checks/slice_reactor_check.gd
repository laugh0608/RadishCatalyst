extends SceneTree

var failures: Array[String] = []
var _assertion_count := 0


func _init() -> void:
	call_deferred("_execute")


func _execute() -> void:
	_check_port_rotation()
	_check_start_guards_and_atomic_consumption()
	_check_power_pause_resume_and_completion()
	_check_next_batch_backpressure()
	_check_step_size_independence()
	_check_state_and_content_gate()
	_check_machine_logistics_chain()
	_check_machine_logistics_backpressure()
	_check_atomic_recovery()
	if failures.is_empty():
		print(
			"Slice reactor checks passed (%d assertions)."
			% _assertion_count
		)
		quit(0)
		return
	for failure in failures:
		push_error(failure)
	quit(1)


func _check_port_rotation() -> void:
	var definition := SliceBuildingCatalog.find(
		SliceBuildingCatalog.REACTOR_ID
	)
	var origin := Vector2i(10, 10)
	var expected_inputs := [
		Vector2i(11, 12),
		Vector2i(10, 11),
		Vector2i(11, 10),
		Vector2i(12, 11),
	]
	var expected_input_connections := [
		Vector2i(11, 13),
		Vector2i(9, 11),
		Vector2i(11, 9),
		Vector2i(13, 11),
	]
	var expected_outputs := [
		Vector2i(11, 10),
		Vector2i(12, 11),
		Vector2i(11, 12),
		Vector2i(10, 11),
	]
	var expected_output_connections := [
		Vector2i(11, 9),
		Vector2i(13, 11),
		Vector2i(11, 13),
		Vector2i(9, 11),
	]
	for rotation in range(4):
		_expect_equal(
			definition.machine_input_port_world_cell(origin, rotation),
			expected_inputs[rotation],
			"rotation %d input port" % rotation
		)
		_expect_equal(
			definition.machine_input_connection_world_cell(origin, rotation),
			expected_input_connections[rotation],
			"rotation %d input connection" % rotation
		)
		_expect_equal(
			definition.machine_output_port_world_cell(origin, rotation),
			expected_outputs[rotation],
			"rotation %d output port" % rotation
		)
		_expect_equal(
			definition.machine_output_connection_world_cell(origin, rotation),
			expected_output_connections[rotation],
			"rotation %d output connection" % rotation
		)


func _check_start_guards_and_atomic_consumption() -> void:
	var reactor := _make_reactor()
	reactor.input_inventory.add(SliceReactor.INPUT_ITEM_ID, 2)
	reactor.tick(1.0)
	_expect_equal(reactor.processing, false, "unpowered reactor stays idle")
	_expect_equal(
		reactor.input_inventory.count(SliceReactor.INPUT_ITEM_ID),
		2,
		"unpowered reactor preserves input"
	)

	reactor.powered = true
	reactor.input_inventory.remove(SliceReactor.INPUT_ITEM_ID, 1)
	reactor.tick(1.0)
	_expect_equal(reactor.processing, false, "one crystal cannot start")
	_expect_equal(
		reactor.input_inventory.count(SliceReactor.INPUT_ITEM_ID),
		1,
		"failed start consumes nothing"
	)
	reactor.input_inventory.add(SliceReactor.INPUT_ITEM_ID, 1)
	var started := reactor.tick(0.5)
	_expect_equal(bool(started["started"]), true, "valid batch starts")
	_expect_equal(reactor.processing, true, "started batch is processing")
	_expect_equal(
		reactor.input_inventory.count(SliceReactor.INPUT_ITEM_ID),
		0,
		"batch atomically consumes two crystals"
	)
	_expect_near(reactor.production_progress, 0.5, "start tick advances")
	reactor.free()


func _check_power_pause_resume_and_completion() -> void:
	var reactor := _ready_reactor()
	reactor.tick(2.0)
	reactor.powered = false
	reactor.tick(5.0)
	_expect_near(reactor.production_progress, 2.0, "power loss pauses progress")
	_expect_equal(reactor.processing, true, "power loss retains batch")
	reactor.powered = true
	var completed := reactor.tick(8.0)
	_expect_equal(bool(completed["completed"]), true, "resumed batch completes")
	_expect_equal(reactor.processing, false, "completed reactor becomes idle")
	_expect_near(reactor.production_progress, 0.0, "completion clears progress")
	_expect_equal(
		reactor.output_inventory.count(SliceReactor.OUTPUT_ITEM_ID),
		1,
		"completion creates one catalyst"
	)
	reactor.free()


func _check_next_batch_backpressure() -> void:
	var reactor := _ready_reactor()
	reactor.tick(1.0)
	reactor.input_inventory.add(SliceReactor.INPUT_ITEM_ID, 2)
	reactor.tick(9.0)
	reactor.tick(10.0)
	_expect_equal(reactor.processing, false, "full output blocks next batch")
	_expect_equal(
		reactor.input_inventory.count(SliceReactor.INPUT_ITEM_ID),
		2,
		"backpressure preserves queued input"
	)
	reactor.output_inventory.remove(SliceReactor.OUTPUT_ITEM_ID, 1)
	reactor.tick(0.25)
	_expect_equal(reactor.processing, true, "empty output allows next batch")
	_expect_equal(
		reactor.input_inventory.count(SliceReactor.INPUT_ITEM_ID),
		0,
		"next batch consumes queued input only after unblock"
	)
	reactor.free()


func _check_step_size_independence() -> void:
	var fine := _ready_reactor()
	var coarse := _ready_reactor()
	for _step in range(100):
		fine.tick(0.1)
	for _step in range(40):
		coarse.tick(0.25)
	_expect_equal(
		fine.output_inventory.to_dict(),
		coarse.output_inventory.to_dict(),
		"0.1 and 0.25 second steps produce identical output"
	)
	_expect_equal(fine.processing, coarse.processing, "step sizes match state")
	_expect_near(
		fine.production_progress,
		coarse.production_progress,
		"step sizes match retained progress"
	)
	fine.free()
	coarse.free()


func _check_state_and_content_gate() -> void:
	var reactor := _ready_reactor()
	_expect_equal(
		reactor.content_block_reason(),
		"先取空反应器",
		"loaded input blocks demolition"
	)
	reactor.tick(1.0)
	_expect_equal(
		reactor.content_block_reason(),
		"反应器正在生产",
		"active batch blocks demolition"
	)
	var state := reactor.state_dict(reactor.definition.state_keys)
	_expect_equal(
		state.keys().size(),
		4,
		"reactor serializes exactly four state fields"
	)
	_expect_equal(bool(state["processing"]), true, "processing is serialized")
	_expect_near(
		float(state["production_progress"]),
		1.0,
		"retained progress is serialized"
	)
	reactor._refresh_processing_visual()
	var overlay := reactor.get_node_or_null("ProcessingOverlay") as Sprite2D
	_expect_equal(
		overlay != null and overlay.visible,
		true,
		"processing reactor shows fixed pixel overlay"
	)
	_expect_equal(
		overlay.texture.resource_path.contains(
			"reactor_processing_pulse_"
		),
		true,
		"processing overlay selects a derived fixed frame"
	)
	reactor.free()


func _check_machine_logistics_chain() -> void:
	var source := _make_storage(
		"building-000010", Vector2i(10, 16), 0
	)
	var input_source_belt := _make_conveyor(
		"building-000011", Vector2i(11, 15), 0
	)
	var input_middle_belt := _make_conveyor(
		"building-000012", Vector2i(11, 14), 0
	)
	var input_sink_belt := _make_conveyor(
		"building-000013", Vector2i(11, 13), 0
	)
	var reactor := _make_reactor_at(
		"building-000014", Vector2i(10, 10), 0
	)
	var output_belt := _make_conveyor(
		"building-000015", Vector2i(11, 9), 0
	)
	var target := _make_storage(
		"building-000016", Vector2i(11, 7), 2
	)
	var instances: Array[SliceBuildingInstance] = [
		source,
		input_source_belt,
		input_middle_belt,
		input_sink_belt,
		reactor,
		output_belt,
		target,
	]
	var grid := SliceLogisticsGrid.new()
	grid.rebuild(instances)
	source.inventory.add(SliceReactor.INPUT_ITEM_ID, 4)
	reactor.powered = true
	var catalyst_sprite_seen := false
	for _step in range(300):
		grid.tick(0.1)
		reactor.tick(0.1)
		if (
			output_belt.cargo_item_id == SliceReactor.OUTPUT_ITEM_ID
			and _cargo_texture_path(output_belt).ends_with(
				"cargo_catalyst.png"
			)
		):
			catalyst_sprite_seen = true

	_expect_equal(
		input_sink_belt.topology_kind(),
		SliceConveyor.TOPOLOGY_SINK_ENDPOINT,
		"reactor input belt selects sink endpoint"
	)
	_expect_equal(
		output_belt.topology_kind(),
		SliceConveyor.TOPOLOGY_SOURCE_ENDPOINT,
		"reactor output belt selects source endpoint"
	)
	_expect_equal(
		target.inventory.count(SliceReactor.OUTPUT_ITEM_ID),
		2,
		"four crystals become two stored catalysts"
	)
	_expect_equal(
		source.inventory.count(SliceReactor.INPUT_ITEM_ID),
		0,
		"source crystals are fully consumed"
	)
	_expect_equal(
		reactor.input_inventory.is_empty(),
		true,
		"reactor input drains after two batches"
	)
	_expect_equal(
		reactor.output_inventory.is_empty(),
		true,
		"reactor output drains to belt"
	)
	_expect_equal(
		catalyst_sprite_seen,
		true,
		"catalyst uses its reviewed cargo sprite"
	)
	_free_instances(instances)


func _check_machine_logistics_backpressure() -> void:
	var reactor := _make_reactor_at(
		"building-000020", Vector2i(10, 10), 0
	)
	var input_belt := _make_conveyor(
		"building-000021", Vector2i(11, 13), 0
	)
	var output_belt := _make_conveyor(
		"building-000022", Vector2i(11, 9), 0
	)
	var instances: Array[SliceBuildingInstance] = [
		reactor, input_belt, output_belt,
	]
	var grid := SliceLogisticsGrid.new()
	grid.rebuild(instances)

	input_belt.set_cargo(SliceReactor.OUTPUT_ITEM_ID, 1.0)
	grid.tick(0.1)
	_expect_equal(input_belt.has_cargo(), true, "catalyst cannot enter input")
	_expect_equal(
		reactor.input_inventory.is_empty(),
		true,
		"rejected catalyst never reaches input buffer"
	)
	_expect_equal(
		input_belt.cargo_progress < 1.0,
		true,
		"rejected catalyst remains belt-owned under backpressure"
	)

	input_belt.clear_cargo()
	reactor.input_inventory.add(SliceReactor.INPUT_ITEM_ID, 2)
	input_belt.set_cargo(SliceReactor.INPUT_ITEM_ID, 1.0)
	grid.tick(0.1)
	_expect_equal(input_belt.has_cargo(), true, "full input backs crystal up")
	_expect_equal(
		reactor.input_inventory.count(SliceReactor.INPUT_ITEM_ID),
		2,
		"full input does not overflow"
	)

	reactor.input_inventory.remove(SliceReactor.INPUT_ITEM_ID, 2)
	input_belt.clear_cargo()
	input_belt.building_rotation = 2
	input_belt.set_cargo(SliceReactor.INPUT_ITEM_ID, 1.0)
	grid.rebuild(instances)
	grid.tick(0.1)
	_expect_equal(
		input_belt.has_cargo(),
		true,
		"wrong-way input belt preserves crystal ownership"
	)
	_expect_equal(
		reactor.input_inventory.is_empty(),
		true,
		"wrong-way input never reaches reactor"
	)
	input_belt.clear_cargo()
	input_belt.building_rotation = 0

	reactor.output_inventory.add(SliceReactor.OUTPUT_ITEM_ID, 1)
	output_belt.set_cargo(SliceReactor.INPUT_ITEM_ID, 0.5)
	grid.rebuild(instances)
	grid.tick(0.1)
	_expect_equal(
		reactor.output_inventory.count(SliceReactor.OUTPUT_ITEM_ID),
		1,
		"occupied output belt preserves reactor catalyst"
	)
	output_belt.clear_cargo()
	output_belt.building_rotation = 2
	grid.rebuild(instances)
	grid.tick(0.1)
	_expect_equal(
		reactor.output_inventory.count(SliceReactor.OUTPUT_ITEM_ID),
		1,
		"wrong-way output belt preserves catalyst"
	)
	output_belt.building_rotation = 0
	grid.rebuild(instances)
	grid.tick(0.1)
	_expect_equal(
		output_belt.cargo_item_id,
		SliceReactor.OUTPUT_ITEM_ID,
		"empty outward belt withdraws catalyst"
	)
	_expect_equal(
		reactor.output_inventory.is_empty(),
		true,
		"successful withdrawal clears output buffer"
	)
	_free_instances(instances)


func _check_atomic_recovery() -> void:
	var world := SliceWorld.new()
	var save_dir := (
		"/private/tmp/radishcatalyst-l5-package2-recovery-%d"
		% Time.get_ticks_usec()
	)
	world.save_service = SliceSaveService.new(save_dir)
	var instances: Array[SliceBuildingInstance] = []
	var floor_definition := SliceBuildingCatalog.find(
		SliceBuildingCatalog.FLOOR_ID
	)
	var serial := 1
	for y in range(3):
		for x in range(3):
			var floor := SliceBuildingInstance.new()
			floor.configure_building(
				"building-%06d" % serial,
				SliceBuildingCatalog.FLOOR_ID,
				Vector2i(x, y),
				0
			)
			floor.definition = floor_definition
			world._building_instances.append(floor)
			instances.append(floor)
			serial += 1
	var reactor := _make_reactor_at(
		"building-000010", Vector2i.ZERO, 0
	)
	world._building_instances.append(reactor)
	instances.append(reactor)
	world._next_building_serial = 11
	reactor.powered = true
	reactor.processing = true
	reactor.production_progress = 4.0
	reactor.input_inventory.add(SliceReactor.INPUT_ITEM_ID, 2)
	reactor.output_inventory.add(SliceReactor.OUTPUT_ITEM_ID, 1)
	world.pocket.add(SliceWorld.ITEM_PART, 26)

	_expect_equal(
		world.adjustment_block_reason(reactor),
		"反应器正在生产",
		"processing reactor blocks adjustment"
	)
	var rejected := world.recover_reactor_contents(reactor)
	_expect_equal(
		bool(rejected["success"]),
		false,
		"insufficient backpack rejects whole recovery"
	)
	_expect_equal(reactor.processing, true, "failed recovery keeps batch")
	_expect_equal(
		reactor.input_inventory.count(SliceReactor.INPUT_ITEM_ID),
		2,
		"failed recovery keeps queued input"
	)
	_expect_equal(
		reactor.output_inventory.count(SliceReactor.OUTPUT_ITEM_ID),
		1,
		"failed recovery keeps output"
	)

	world.pocket.remove(SliceWorld.ITEM_PART, 26)
	var recovered := world.recover_reactor_contents(reactor)
	_expect_equal(bool(recovered["success"]), true, "recovery succeeds atomically")
	_expect_equal(
		world.pocket.count(SliceWorld.ITEM_CRYSTAL),
		4,
		"recovery returns queued and in-process crystals"
	)
	_expect_equal(
		world.pocket.count(SliceWorld.ITEM_CATALYST),
		1,
		"recovery returns output catalyst"
	)
	_expect_equal(reactor.processing, false, "recovery cancels processing")
	_expect_near(reactor.production_progress, 0.0, "recovery clears progress")
	_expect_equal(
		reactor.content_block_reason(),
		"",
		"recovered reactor becomes adjustable"
	)
	_free_instances(instances)
	world.free()
	for file_name in [
		"slice_world.json",
		"slice_world.bak.json",
		"slice_world.tmp.json",
	]:
		DirAccess.remove_absolute(save_dir.path_join(file_name))
	DirAccess.remove_absolute(save_dir)


func _ready_reactor() -> SliceReactor:
	var reactor := _make_reactor()
	reactor.powered = true
	reactor.input_inventory.add(SliceReactor.INPUT_ITEM_ID, 2)
	return reactor


func _make_reactor() -> SliceReactor:
	return _make_reactor_at(
		"building-000001", Vector2i.ZERO, 0
	)


func _make_reactor_at(
	instance_id: String,
	origin: Vector2i,
	rotation: int
) -> SliceReactor:
	var reactor := SliceReactor.new()
	reactor.configure_building(
		instance_id,
		SliceBuildingCatalog.REACTOR_ID,
		origin,
		rotation
	)
	reactor.apply_definition(SliceBuildingCatalog.find(
		SliceBuildingCatalog.REACTOR_ID
	), 32.0)
	return reactor


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


func _cargo_texture_path(conveyor: SliceConveyor) -> String:
	var sprite := conveyor.get_node_or_null("Cargo") as Sprite2D
	if sprite == null or sprite.texture == null:
		return ""
	return sprite.texture.resource_path


func _free_instances(instances: Array[SliceBuildingInstance]) -> void:
	for instance in instances:
		instance.free()


func _expect_equal(actual, expected, label: String) -> void:
	_assertion_count += 1
	if actual != expected:
		failures.append("%s: expected %s, got %s" % [label, expected, actual])


func _expect_near(actual: float, expected: float, label: String) -> void:
	_assertion_count += 1
	if not is_equal_approx(actual, expected):
		failures.append("%s: expected %.6f, got %.6f" % [label, expected, actual])
