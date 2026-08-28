extends SceneTree

var failures: Array[String] = []
var _assertion_count := 0
var _state_build_count := 0


class FakeSaveService:
	extends RefCounted

	var save_call_count := 0
	var commit_call_count := 0
	var fail_next := false
	var last_context: Dictionary = {}


	func save_state(_state: Dictionary) -> Dictionary:
		save_call_count += 1
		return _result()


	func commit_loaded_state(
		_state: Dictionary, context: Dictionary
	) -> Dictionary:
		commit_call_count += 1
		last_context = context.duplicate(true)
		return _result()


	func _result() -> Dictionary:
		if fail_next:
			fail_next = false
			return {"success": false, "message": "injected failure"}
		return {"success": true, "message": "saved"}


func _init() -> void:
	call_deferred("_execute")


func _execute() -> void:
	_run_save_scheduler_checks()
	_run_spatial_contract_checks()
	_run_world_boundary_checks()
	if failures.is_empty():
		print(
			"Slice playtest remediation package 0 checks passed (%d assertions)."
			% _assertion_count
		)
		quit(0)
		return
	for failure in failures:
		push_error(failure)
	quit(1)


func _run_save_scheduler_checks() -> void:
	var service := FakeSaveService.new()
	var scheduler := SliceSaveScheduler.new()
	scheduler.setup(service, 2.0)
	_expect_equal(scheduler.request_save(), true, "dirty request is accepted")
	_expect_equal(scheduler.is_dirty(), true, "dirty request remains pending")
	var first_tick := scheduler.advance(
		1.0, Callable(self, "_build_state")
	)
	_expect_equal(
		bool(first_tick["attempted"]), false, "first second does not write"
	)
	_expect_equal(_state_build_count, 0, "state stays lazy before write")
	_expect_equal(
		scheduler.request_save(), true, "repeated dirty request is coalesced"
	)
	var second_tick := scheduler.advance(
		1.0, Callable(self, "_build_state")
	)
	_expect_success(second_tick, "second elapsed second writes once")
	_expect_equal(service.save_call_count, 1, "coalesced changes write once")
	_expect_equal(_state_build_count, 1, "state is built once for one write")
	_expect_equal(scheduler.is_dirty(), false, "successful write clears dirty")

	var forced := scheduler.flush(Callable(self, "_build_state"))
	_expect_success(forced, "forced flush writes even while clean")
	_expect_equal(service.save_call_count, 2, "forced flush reaches service")

	var migration_context := {"source": "backup", "schema": 8}
	scheduler.set_pending_load_context(migration_context)
	service.fail_next = true
	var failed := scheduler.flush(Callable(self, "_build_state"))
	_expect_equal(bool(failed["success"]), false, "injected write fails")
	_expect_equal(scheduler.is_dirty(), true, "failure preserves dirty state")
	_expect_equal(
		scheduler.pending_load_context(),
		migration_context,
		"failure preserves migration publish context"
	)
	_expect_equal(service.commit_call_count, 1, "migration uses commit path")
	var retried := scheduler.flush(Callable(self, "_build_state"))
	_expect_success(retried, "failed migration can retry")
	_expect_equal(service.commit_call_count, 2, "retry reuses commit path")
	_expect_equal(
		scheduler.pending_load_context().is_empty(),
		true,
		"successful retry clears migration context"
	)

	var blocked_service := FakeSaveService.new()
	var blocked := SliceSaveScheduler.new()
	blocked.setup(blocked_service, 2.0)
	blocked.set_write_blocked(true)
	_expect_equal(blocked.request_save(), false, "blocked world rejects queue")
	var blocked_flush := blocked.flush(Callable(self, "_build_state"))
	_expect_equal(
		bool(blocked_flush["success"]), false, "blocked world rejects flush"
	)
	_expect_equal(blocked_service.save_call_count, 0, "blocked flush does no IO")


func _run_spatial_contract_checks() -> void:
	var map := (
		load(SliceWorld.MAP_SCENE) as PackedScene
	).instantiate() as Node2D
	var ground := map.get_node("GroundLayer") as TileMapLayer
	var floor := map.get_node("IndustrialFloorLayer") as TileMapLayer
	var world := map.get_node("World") as Node2D
	_expect_equal(ground.get_parent(), map, "ground stays outside y-sorted world")
	_expect_equal(floor.get_parent(), map, "floor stays outside y-sorted world")
	_expect_equal(world.y_sort_enabled, true, "device and actor world uses y sort")
	map.free()

	var reactor := SliceBuildingCatalog.find(SliceBuildingCatalog.REACTOR_ID)
	_expect_equal(reactor.footprint, Vector2i(3, 3), "reactor base is three by three")
	var collector := SliceBuildingCatalog.find(SliceBuildingCatalog.COLLECTOR_ID)
	_expect_equal(collector.footprint, Vector2i(2, 2), "collector base is two by two")
	for definition in SliceBuildingCatalog.all():
		for port in definition.logistics_ports:
			var descriptor := port.resolved_descriptor(
				Vector2i(10, 10), definition.footprint, 0
			)
			var occupied := definition.occupied_cells(Vector2i(10, 10), 0)
			_expect_equal(
				occupied.has(descriptor["port_cell"]),
				true,
				"%s %s port remains inside base" % [
					definition.building_id, port.id,
				]
			)
			_expect_equal(
				occupied.has(descriptor["connection_cell"]),
				false,
				"%s %s connection remains outside base" % [
					definition.building_id, port.id,
				]
			)


func _run_world_boundary_checks() -> void:
	var file := FileAccess.open(
		"res://scripts/slice/slice_world.gd", FileAccess.READ
	)
	_expect_equal(file != null, true, "slice world source is readable")
	if file == null:
		return
	var source := file.get_as_text()
	file.close()
	_expect_equal(
		source.split("\n").size() < 1500,
		true,
		"slice world remains below hard line limit"
	)
	_expect_equal(
		source.contains("_autosave"), false, "world removes legacy autosave API"
	)
	_expect_equal(
		source.contains("_logistics_save_elapsed"),
		false,
		"world removes logistics save timer"
	)
	_expect_equal(
		source.contains("_production_save_elapsed"),
		false,
		"world removes production save timer"
	)


func _build_state() -> Dictionary:
	_state_build_count += 1
	return {"sequence": _state_build_count}


func _expect_success(result: Dictionary, context: String) -> void:
	_expect_equal(bool(result.get("success", false)), true, context)


func _expect_equal(actual, expected, context: String) -> void:
	_assertion_count += 1
	if actual != expected:
		failures.append(
			"%s: expected %s, got %s" % [context, expected, actual]
		)
