extends SceneTree

var failures: Array[String] = []
var _assertion_count := 0


func _init() -> void:
	call_deferred("_execute")


func _execute() -> void:
	_check_manual_access_and_supply_power()
	_check_grandfathered_type_recovery()
	_check_transfer_input_ignores_power()
	_check_wireless_timing_and_fairness()
	_check_wireless_pause_and_partial_capacity()
	_check_mode_and_state_contract()
	_check_transfer_state_roundtrip()
	if failures.is_empty():
		print(
			"Slice powered storage checks passed (%d assertions)."
			% _assertion_count
		)
		quit(0)
		return
	for failure in failures:
		push_error(failure)
	quit(1)


func _check_manual_access_and_supply_power() -> void:
	var storage := _make_storage("storage-supply")
	var pocket := Inventory.new(SliceInventoryProfiles.category_pocket())
	pocket.add(SliceItemCatalog.CRYSTAL_ID, 80)
	_expect_equal(
		storage.manual_deposit(pocket, SliceItemCatalog.CRYSTAL_ID),
		80,
		"manual deposit works while storage is unpowered"
	)
	_expect_equal(
		storage.output_item_id,
		SliceItemCatalog.CRYSTAL_ID,
		"first transportable deposit selects supply output"
	)
	var endpoints := storage.logistics_endpoints()
	_expect_equal(endpoints.size(), 1, "supply mode exposes one endpoint")
	_expect_equal(endpoints[0].port_id, "output", "supply exposes fixed OUT")
	_expect_equal(
		endpoints[0].peek_output_item(),
		"",
		"unpowered supply does not expose cargo"
	)
	storage.set_powered(true)
	endpoints = storage.logistics_endpoints()
	_expect_equal(
		endpoints[0].peek_output_item(),
		SliceItemCatalog.CRYSTAL_ID,
		"powered supply exposes only selected cargo"
	)
	_expect_equal(
		endpoints[0].take_output_item(SliceItemCatalog.CRYSTAL_ID),
		true,
		"powered supply removes exactly one selected item"
	)
	_expect_equal(
		storage.inventory.count(SliceItemCatalog.CRYSTAL_ID),
		79,
		"supply removal is conserved"
	)
	storage.set_powered(false)
	_expect_equal(
		storage.manual_withdraw(pocket, SliceItemCatalog.CRYSTAL_ID),
		79,
		"manual withdrawal remains available without power"
	)
	_expect_equal(
		storage.output_item_id,
		SliceItemCatalog.CRYSTAL_ID,
		"depleted supply keeps its selected output filter"
	)
	storage.set_powered(true)
	_expect_equal(
		endpoints[0].peek_output_item(),
		"",
		"depleted selected output waits for matching replenishment"
	)
	storage.free()


func _check_grandfathered_type_recovery() -> void:
	var storage := _make_storage("storage-grandfathered")
	var grandfathered_ids: Array[String] = [
		SliceItemCatalog.CRYSTAL_ID,
		SliceItemCatalog.CATALYST_ID,
		SliceItemCatalog.PART_ID,
		SliceBuildingCatalog.FLOOR_ID,
		SliceBuildingCatalog.COLLECTOR_ID,
	]
	for item_id in grandfathered_ids:
		storage.inventory.restore_existing(item_id, 1)
	var pocket := Inventory.new(SliceInventoryProfiles.category_pocket())
	pocket.add(SliceItemCatalog.CRYSTAL_ID, 199)
	pocket.add(SliceBuildingCatalog.REACTOR_ID, 1)
	_expect_equal(
		storage.type_count(),
		5,
		"schema-7 storage may restore five grandfathered item types"
	)
	_expect_equal(
		storage.manual_deposit(pocket, SliceItemCatalog.CRYSTAL_ID),
		199,
		"grandfathered storage can replenish an existing type"
	)
	_expect_equal(
		storage.inventory.count(SliceItemCatalog.CRYSTAL_ID),
		200,
		"grandfathered existing type still respects its per-item cap"
	)
	_expect_equal(
		storage.manual_deposit(pocket, SliceBuildingCatalog.REACTOR_ID),
		0,
		"grandfathered storage rejects a new sixth type"
	)
	_expect_equal(
		pocket.count(SliceBuildingCatalog.REACTOR_ID),
		1,
		"rejected new type remains in the source inventory"
	)
	_expect_equal(
		storage.manual_withdraw(pocket, SliceBuildingCatalog.FLOOR_ID),
		1,
		"grandfathered property remains manually recoverable"
	)
	_expect_equal(
		storage.type_count(),
		4,
		"withdrawing one grandfathered type restores the four-type limit"
	)
	_expect_equal(
		storage.inventory.count(SliceBuildingCatalog.FLOOR_ID),
		0,
		"recovered grandfathered type leaves no duplicate in storage"
	)
	storage.free()


func _check_transfer_input_ignores_power() -> void:
	var storage := _make_storage("storage-input")
	storage.set_mode(SliceStorage.MODE_TRANSFER)
	var endpoints := storage.logistics_endpoints()
	_expect_equal(endpoints.size(), 1, "transfer mode exposes one endpoint")
	_expect_equal(endpoints[0].port_id, "input", "transfer exposes fixed IN")
	_expect_equal(storage.powered, false, "test storage starts unpowered")
	_expect_equal(
		endpoints[0].try_accept_one(SliceItemCatalog.CATALYST_ID),
		1,
		"transfer IN accepts transportable cargo without power"
	)
	_expect_equal(
		endpoints[0].try_accept_one(SliceItemCatalog.PART_ID),
		0,
		"transfer IN rejects non-transportable cargo"
	)
	storage.free()


func _check_wireless_timing_and_fairness() -> void:
	var storage := _make_storage("storage-wireless")
	storage.inventory.restore_existing(SliceItemCatalog.CRYSTAL_ID, 100)
	storage.inventory.restore_existing(SliceItemCatalog.CATALYST_ID, 100)
	storage.set_mode(SliceStorage.MODE_TRANSFER)
	storage.set_powered(true)
	var core := Inventory.new(
		SliceInventoryProfiles.category_core_storage()
	)
	var before := storage.tick_wireless_transfer(4.999, true, core)
	_expect_equal(int(before["moved"]), 0, "4.999 seconds does not pulse")
	_expect_near(
		storage.transfer_progress, 4.999, 0.00001,
		"eligible transfer time is retained"
	)
	var first := storage.tick_wireless_transfer(0.001, true, core)
	_expect_equal(int(first["moved"]), 50, "five seconds moves at most 50")
	_expect_equal(
		core.count(SliceItemCatalog.CRYSTAL_ID),
		50,
		"first pulse starts from crystal"
	)
	_expect_equal(storage.transfer_cursor, 1, "cursor advances across pulses")
	var second := storage.tick_wireless_transfer(5.0, true, core)
	_expect_equal(int(second["moved"]), 50, "second pulse also caps at 50")
	_expect_equal(
		core.count(SliceItemCatalog.CATALYST_ID),
		50,
		"second pulse continues from catalyst"
	)
	_expect_equal(storage.transfer_cursor, 0, "cursor wraps deterministically")
	var conserved_total := storage.inventory.total() + core.total()
	var large_delta := storage.tick_wireless_transfer(10.0, true, core)
	_expect_equal(
		int(large_delta["moved"]),
		100,
		"large delta processes two complete wireless pulses"
	)
	_expect_equal(
		storage.inventory.is_empty(),
		true,
		"large-delta pulses remove only the transferred source contents"
	)
	_expect_equal(
		core.count(SliceItemCatalog.CRYSTAL_ID),
		100,
		"large-delta pulses preserve the complete crystal amount"
	)
	_expect_equal(
		core.count(SliceItemCatalog.CATALYST_ID),
		100,
		"large-delta pulses preserve the complete catalyst amount"
	)
	_expect_equal(
		storage.inventory.total() + core.total(),
		conserved_total,
		"large-delta multi-pulse transfer conserves all property"
	)
	_expect_equal(
		storage.transfer_cursor,
		0,
		"large-delta multi-pulse cursor remains deterministic"
	)
	_expect_near(
		storage.transfer_progress,
		0.0,
		0.00001,
		"large-delta exact pulses leave no phantom progress"
	)
	storage.free()


func _check_wireless_pause_and_partial_capacity() -> void:
	var storage := _make_storage("storage-pauses")
	storage.inventory.restore_existing(SliceItemCatalog.CRYSTAL_ID, 60)
	storage.set_mode(SliceStorage.MODE_TRANSFER)
	storage.set_powered(true)
	var core := Inventory.new(
		SliceInventoryProfiles.category_core_storage()
	)
	storage.transfer_progress = 2.0
	storage.tick_wireless_transfer(1.0, false, core)
	_expect_near(
		storage.transfer_progress, 2.0, 0.00001,
		"unrepaired core pauses progress"
	)
	storage.set_powered(false)
	storage.tick_wireless_transfer(1.0, true, core)
	_expect_near(
		storage.transfer_progress, 2.0, 0.00001,
		"power loss pauses progress"
	)
	storage.set_powered(true)
	core.restore_existing(SliceItemCatalog.CRYSTAL_ID, 99990)
	core.restore_existing(SliceItemCatalog.CATALYST_ID, 99999)
	var partial := storage.tick_wireless_transfer(3.0, true, core)
	_expect_equal(int(partial["moved"]), 9, "pulse respects partial core space")
	_expect_equal(
		storage.inventory.count(SliceItemCatalog.CRYSTAL_ID),
		51,
		"unmoved wireless contents stay in storage"
	)
	var paused_progress := storage.transfer_progress
	storage.tick_wireless_transfer(2.0, true, core)
	_expect_near(
		storage.transfer_progress, paused_progress, 0.00001,
		"full transportable core categories pause progress"
	)
	storage.free()


func _check_mode_and_state_contract() -> void:
	var storage := _make_storage("storage-state")
	storage.inventory.restore_existing(SliceItemCatalog.CRYSTAL_ID, 3)
	storage.set_output_item(SliceItemCatalog.CRYSTAL_ID)
	storage.set_mode(SliceStorage.MODE_TRANSFER)
	storage.transfer_cursor = 1
	storage.transfer_progress = 4.5
	_expect_equal(
		storage.set_mode(SliceStorage.MODE_SUPPLY),
		true,
		"mode switch succeeds without power"
	)
	_expect_near(
		storage.transfer_progress, 0.0, 0.00001,
		"leaving transfer mode clears progress"
	)
	var state := storage.state_dict([
		"inventory",
		"mode",
		"output_item_id",
		"transfer_cursor",
		"transfer_progress",
	])
	_expect_equal(
		(state["inventory"] as Dictionary).keys(),
		["contents"],
		"schema-8 storage inventory omits runtime profile capacity"
	)
	var restored := _make_storage("storage-restored")
	restored.restore_state(state)
	_expect_equal(restored.mode, SliceStorage.MODE_SUPPLY, "mode restores")
	_expect_equal(
		restored.output_item_id,
		SliceItemCatalog.CRYSTAL_ID,
		"supply selection restores"
	)
	_expect_equal(
		restored.inventory.count(SliceItemCatalog.CRYSTAL_ID),
		3,
		"stored property restores"
	)
	storage.free()
	restored.free()


func _check_transfer_state_roundtrip() -> void:
	var storage := _make_storage("storage-transfer-state")
	storage.inventory.restore_existing(SliceItemCatalog.CRYSTAL_ID, 3)
	storage.set_output_item(SliceItemCatalog.CRYSTAL_ID)
	storage.set_mode(SliceStorage.MODE_TRANSFER)
	storage.transfer_cursor = 1
	storage.transfer_progress = 4.5
	var state_keys: Array[String] = [
		"inventory",
		"mode",
		"output_item_id",
		"transfer_cursor",
		"transfer_progress",
	]
	var state := storage.state_dict(state_keys)
	var restored := _make_storage("storage-transfer-state-restored")
	restored.restore_state(state)
	_expect_equal(
		restored.mode,
		SliceStorage.MODE_TRANSFER,
		"transfer mode survives state roundtrip"
	)
	_expect_equal(
		restored.output_item_id,
		SliceItemCatalog.CRYSTAL_ID,
		"transfer-mode output preference survives state roundtrip"
	)
	_expect_equal(
		restored.transfer_cursor,
		1,
		"wireless cursor survives state roundtrip"
	)
	_expect_near(
		restored.transfer_progress,
		4.5,
		0.00001,
		"wireless progress survives state roundtrip"
	)
	_expect_equal(
		restored.state_dict(state_keys),
		state,
		"transfer storage state roundtrip is exact"
	)
	storage.free()
	restored.free()


func _make_storage(instance_id: String) -> SliceStorage:
	var storage := SliceStorage.new()
	storage.configure_building(
		instance_id,
		SliceBuildingCatalog.STORAGE_ID,
		Vector2i(10, 10),
		0
	)
	storage.apply_definition(
		SliceBuildingCatalog.find(SliceBuildingCatalog.STORAGE_ID),
		32.0
	)
	return storage


func _expect_equal(actual, expected, message: String) -> void:
	_assertion_count += 1
	if actual != expected:
		failures.append("%s: expected %s, got %s" % [
			message, str(expected), str(actual)
		])


func _expect_near(
	actual: float,
	expected: float,
	tolerance: float,
	message: String
) -> void:
	_assertion_count += 1
	if absf(actual - expected) > tolerance:
		failures.append("%s: expected %.6f, got %.6f" % [
			message, expected, actual
		])
