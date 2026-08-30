extends SceneTree

const SliceCollectorScene := preload("res://scenes/slice/SliceCollector.tscn")
const SlicePowerRelayScene := preload("res://scenes/slice/SlicePowerRelay.tscn")
const SliceStorageScene := preload("res://scenes/slice/SliceStorage.tscn")

var failures: Array[String] = []
var _assertion_count := 0


func _init() -> void:
	call_deferred("_execute")


func _execute() -> void:
	_check_state_predicates_and_audio_profiles()
	await _check_collector_feedback()
	await _check_storage_feedback()
	await _check_relay_feedback()
	await _check_restored_devices_start_silent()
	_check_ownership_boundaries()
	if failures.is_empty():
		print(
			"Slice playtest remediation package 4C checks passed (%d assertions)."
			% _assertion_count
		)
		quit(0)
		return
	for failure in failures:
		push_error(failure)
	quit(1)


func _check_state_predicates_and_audio_profiles() -> void:
	_expect_equal(
		SliceDeviceFeedbackState.collector_state(false, 50, 50),
		SliceDeviceFeedbackState.COLLECTOR_UNPOWERED,
		"collector power loss overrides a retained full buffer"
	)
	_expect_equal(
		SliceDeviceFeedbackState.collector_state(true, 49, 50),
		SliceDeviceFeedbackState.COLLECTOR_COLLECTING,
		"powered collector with space keeps collecting"
	)
	_expect_equal(
		SliceDeviceFeedbackState.collector_state(true, 50, 50),
		SliceDeviceFeedbackState.COLLECTOR_FULL,
		"collector reports full only at authoritative capacity"
	)
	_expect_equal(
		SliceDeviceFeedbackState.storage_state(false, true, true, true),
		SliceDeviceFeedbackState.STORAGE_UNPOWERED,
		"storage power loss overrides transfer context"
	)
	_expect_equal(
		SliceDeviceFeedbackState.storage_state(true, false, true, false),
		SliceDeviceFeedbackState.STORAGE_SUPPLY,
		"supply mode does not guess downstream belt activity"
	)
	_expect_equal(
		SliceDeviceFeedbackState.storage_state(true, true, false, false),
		SliceDeviceFeedbackState.STORAGE_TRANSFER_IDLE,
		"empty transfer storage remains idle"
	)
	_expect_equal(
		SliceDeviceFeedbackState.storage_state(true, true, true, true),
		SliceDeviceFeedbackState.STORAGE_TRANSFER_RUNNING,
		"transfer storage runs only with a real candidate"
	)
	_expect_equal(
		SliceDeviceFeedbackState.storage_state(true, true, true, false),
		SliceDeviceFeedbackState.STORAGE_BLOCKED,
		"occupied transfer storage without a candidate is blocked"
	)
	_expect_equal(
		SliceDeviceFeedbackState.relay_state(false),
		SliceDeviceFeedbackState.RELAY_UNPOWERED,
		"relay follows the derived power result"
	)
	_expect_equal(
		SliceDeviceFeedbackState.relay_state(true),
		SliceDeviceFeedbackState.RELAY_ONLINE,
		"powered relay exposes an online presentation"
	)
	_expect_equal(
		SliceDeviceFeedbackState.common_device_edge_event(
			&"", SliceDeviceFeedbackState.COLLECTOR_FULL
		),
		&"",
		"first device observation restores silently"
	)
	_expect_equal(
		SliceDeviceFeedbackState.common_device_edge_event(
			SliceDeviceFeedbackState.COLLECTOR_FULL,
			SliceDeviceFeedbackState.COLLECTOR_FULL
		),
		&"",
		"stable device state does not replay"
	)
	_expect_equal(
		SliceDeviceFeedbackState.common_device_edge_event(
			SliceDeviceFeedbackState.COLLECTOR_COLLECTING,
			SliceDeviceFeedbackState.COLLECTOR_FULL
		),
		SliceDeviceFeedbackState.EVENT_DEVICE_BLOCKED,
		"collector full edge uses the shared blocked cue"
	)
	_expect_equal(
		SliceDeviceFeedbackState.common_device_edge_event(
			SliceDeviceFeedbackState.STORAGE_BLOCKED,
			SliceDeviceFeedbackState.STORAGE_TRANSFER_RUNNING
		),
		SliceDeviceFeedbackState.EVENT_DEVICE_RUNNING,
		"recovered storage uses the shared running cue"
	)
	_expect_equal(
		SliceDeviceFeedbackState.common_device_edge_event(
			SliceDeviceFeedbackState.RELAY_ONLINE,
			SliceDeviceFeedbackState.RELAY_UNPOWERED
		),
		SliceDeviceFeedbackState.EVENT_DEVICE_POWER_LOST,
		"relay disconnect uses the shared power-loss cue"
	)
	for event_id in [
		SliceDeviceFeedbackState.EVENT_DEVICE_POWER_LOST,
		SliceDeviceFeedbackState.EVENT_DEVICE_RUNNING,
		SliceDeviceFeedbackState.EVENT_DEVICE_BLOCKED,
	]:
		var stream := SliceFeedbackAudio.stream_for(event_id)
		_expect(stream != null, "%s has project-authored PCM" % event_id)
		if stream != null:
			_expect_equal(
				stream.mix_rate,
				SliceFeedbackAudio.MIX_RATE,
				"%s uses the frozen mix rate" % event_id
			)
			_expect(stream.data.size() > 0, "%s contains PCM samples" % event_id)


func _check_collector_feedback() -> void:
	var collector := _new_collector("package4c-collector")
	root.add_child(collector)
	await process_frame
	var events: Array[StringName] = []
	collector.feedback_event_played.connect(
		func(event_id: StringName): events.append(event_id)
	)
	collector.refresh_feedback()
	_expect_equal(
		collector.feedback_state(),
		SliceDeviceFeedbackState.COLLECTOR_UNPOWERED,
		"new collector establishes an unpowered baseline"
	)
	_expect_equal(collector.feedback_audio_play_count(), 0, "collector baseline is silent")
	_expect(
		collector.get_node("FeedbackVisual/DisconnectMark").visible,
		"unpowered collector exposes a disconnect shape"
	)
	collector.set_powered(true)
	collector.refresh_feedback()
	_expect_equal(
		collector.feedback_state(),
		SliceDeviceFeedbackState.COLLECTOR_COLLECTING,
		"powered collector reports collecting"
	)
	_expect_equal(collector.feedback_active_segment_count(), 3, "collecting uses three cycling segments")
	collector.buffer = SliceCollector.BUFFER_CAP
	collector.refresh_feedback()
	_expect_equal(
		collector.feedback_state(),
		SliceDeviceFeedbackState.COLLECTOR_FULL,
		"full collector reports blocked"
	)
	_expect(
		collector.get_node("FeedbackVisual/FullMark").visible,
		"full collector exposes a non-color capacity shape"
	)
	_expect_equal(collector.feedback_audio_play_count(), 2, "running and full edges each play once")
	collector.buffer -= 1
	collector.refresh_feedback()
	collector.buffer += 1
	collector.refresh_feedback()
	_expect_equal(
		collector.feedback_audio_play_count(),
		3,
		"running recovery plays but immediate full flapping respects cooldown"
	)
	collector.set_powered(false)
	collector.refresh_feedback()
	_expect_equal(collector.feedback_audio_play_count(), 4, "collector power loss warns once")
	_expect_equal(
		events,
		[
			SliceDeviceFeedbackState.EVENT_DEVICE_RUNNING,
			SliceDeviceFeedbackState.EVENT_DEVICE_BLOCKED,
			SliceDeviceFeedbackState.EVENT_DEVICE_RUNNING,
			SliceDeviceFeedbackState.EVENT_DEVICE_POWER_LOST,
		],
		"collector emits only shared meaningful edge cues"
	)
	_expect_equal(
		(collector.get_node("FeedbackAudio") as AudioStreamPlayer2D).bus,
		&"SFX",
		"collector cues use the SFX bus"
	)
	collector.free()


func _check_storage_feedback() -> void:
	var storage := _new_storage("package4c-storage")
	root.add_child(storage)
	await process_frame
	var events: Array[StringName] = []
	storage.feedback_event_played.connect(
		func(event_id: StringName): events.append(event_id)
	)
	var open_core := Inventory.new(10)
	storage.refresh_feedback(false, open_core)
	_expect_equal(
		storage.feedback_state(),
		SliceDeviceFeedbackState.STORAGE_UNPOWERED,
		"storage establishes an unpowered baseline"
	)
	_expect_equal(storage.feedback_audio_play_count(), 0, "storage baseline is silent")
	storage.set_powered(true)
	storage.refresh_feedback(true, open_core)
	_expect_equal(storage.feedback_state(), SliceDeviceFeedbackState.STORAGE_SUPPLY, "powered default mode is supply")
	_expect_equal(storage.feedback_active_segment_count(), 1, "supply mode uses one stable segment")
	_expect(
		storage.get_node("FeedbackVisual/SupplyMark").visible,
		"supply mode exposes an outward shape"
	)
	storage.set_mode(SliceStorage.MODE_TRANSFER)
	storage.refresh_feedback(true, open_core)
	_expect_equal(
		storage.feedback_state(),
		SliceDeviceFeedbackState.STORAGE_TRANSFER_IDLE,
		"empty transfer mode remains idle"
	)
	_expect_equal(storage.feedback_active_segment_count(), 2, "transfer idle uses two dim segments")
	storage.inventory.add(SliceItemCatalog.CRYSTAL_ID, 1)
	storage.refresh_feedback(true, open_core)
	_expect_equal(
		storage.feedback_state(),
		SliceDeviceFeedbackState.STORAGE_TRANSFER_RUNNING,
		"real core capacity starts transfer feedback"
	)
	_expect_equal(storage.feedback_active_segment_count(), 3, "running transfer uses three cycling segments")
	_expect_equal(storage.feedback_audio_play_count(), 1, "transfer start plays once")
	var full_core := Inventory.new(1)
	full_core.add(SliceItemCatalog.CRYSTAL_ID, 1)
	storage.refresh_feedback(true, full_core)
	_expect_equal(
		storage.feedback_state(),
		SliceDeviceFeedbackState.STORAGE_BLOCKED,
		"full core target blocks wireless transfer"
	)
	_expect(
		storage.get_node("FeedbackVisual/BlockedMark").visible,
		"blocked transfer exposes a stop shape"
	)
	_expect_equal(storage.feedback_audio_play_count(), 2, "first storage blockage warns once")
	storage.refresh_feedback(true, open_core)
	storage.refresh_feedback(true, full_core)
	_expect_equal(
		storage.feedback_audio_play_count(),
		3,
		"storage recovery plays but immediate blocked flapping respects cooldown"
	)
	storage.set_powered(false)
	storage.refresh_feedback(true, full_core)
	_expect_equal(storage.feedback_audio_play_count(), 4, "storage power loss warns once")
	_expect_equal(
		events,
		[
			SliceDeviceFeedbackState.EVENT_DEVICE_RUNNING,
			SliceDeviceFeedbackState.EVENT_DEVICE_BLOCKED,
			SliceDeviceFeedbackState.EVENT_DEVICE_RUNNING,
			SliceDeviceFeedbackState.EVENT_DEVICE_POWER_LOST,
		],
		"storage emits only shared meaningful edge cues"
	)
	_expect_equal(
		(storage.get_node("FeedbackAudio") as AudioStreamPlayer2D).bus,
		&"SFX",
		"storage cues use the SFX bus"
	)
	storage.free()


func _check_relay_feedback() -> void:
	var relay := _new_relay("package4c-relay")
	root.add_child(relay)
	await process_frame
	var events: Array[StringName] = []
	relay.feedback_event_played.connect(
		func(event_id: StringName): events.append(event_id)
	)
	_expect_equal(
		relay.feedback_state(),
		SliceDeviceFeedbackState.RELAY_UNPOWERED,
		"new relay establishes an unpowered baseline"
	)
	_expect(
		relay.get_node("FeedbackVisual/DisconnectMark").visible,
		"unpowered relay exposes a broken-contact shape"
	)
	relay.set_powered(true)
	relay.refresh_feedback()
	_expect_equal(relay.feedback_state(), SliceDeviceFeedbackState.RELAY_ONLINE, "powered relay reports online")
	_expect_equal(relay.feedback_active_segment_count(), 3, "online relay uses three cycling contacts")
	_expect(
		relay.get_node("FeedbackVisual/OnlineRing").visible,
		"online relay closes its visible ring"
	)
	_expect_equal(relay.feedback_audio_play_count(), 1, "relay connection plays once")
	relay.refresh_feedback()
	_expect_equal(relay.feedback_audio_play_count(), 1, "stable relay does not replay")
	relay.set_powered(false)
	relay.refresh_feedback()
	_expect_equal(relay.feedback_audio_play_count(), 2, "relay disconnect plays once")
	_expect_equal(
		events,
		[
			SliceDeviceFeedbackState.EVENT_DEVICE_RUNNING,
			SliceDeviceFeedbackState.EVENT_DEVICE_POWER_LOST,
		],
		"relay emits only connect and disconnect cues"
	)
	_expect_equal(
		(relay.get_node("FeedbackAudio") as AudioStreamPlayer2D).bus,
		&"SFX",
		"relay cues use the SFX bus"
	)
	relay.free()


func _check_restored_devices_start_silent() -> void:
	var collector := _new_collector("restored-collector")
	collector.buffer = SliceCollector.BUFFER_CAP
	collector.set_powered(true)
	root.add_child(collector)
	await process_frame
	_expect_equal(collector.feedback_state(), SliceDeviceFeedbackState.COLLECTOR_FULL, "restored full collector establishes directly")
	_expect_equal(collector.feedback_audio_play_count(), 0, "restored collector does not replay full warning")
	collector.free()

	var storage := _new_storage("restored-storage")
	storage.set_mode(SliceStorage.MODE_TRANSFER)
	storage.inventory.add(SliceItemCatalog.CRYSTAL_ID, 1)
	storage.set_powered(true)
	root.add_child(storage)
	var full_core := Inventory.new(1)
	full_core.add(SliceItemCatalog.CRYSTAL_ID, 1)
	storage.refresh_feedback(true, full_core)
	_expect_equal(storage.feedback_state(), SliceDeviceFeedbackState.STORAGE_BLOCKED, "restored blocked storage establishes directly")
	_expect_equal(storage.feedback_audio_play_count(), 0, "restored storage does not replay blocked warning")
	storage.free()

	var relay := _new_relay("restored-relay")
	relay.set_powered(true)
	root.add_child(relay)
	await process_frame
	_expect_equal(relay.feedback_state(), SliceDeviceFeedbackState.RELAY_ONLINE, "restored relay establishes online directly")
	_expect_equal(relay.feedback_audio_play_count(), 0, "restored relay does not replay connection")
	relay.free()


func _check_ownership_boundaries() -> void:
	var relay_definition := SliceBuildingCatalog.find(
		SliceBuildingCatalog.POWER_RELAY_ID
	)
	_expect_equal(
		relay_definition.scene_path,
		"res://scenes/slice/SlicePowerRelay.tscn",
		"relay feedback lives in a narrow device subclass"
	)
	var world_file := FileAccess.open(
		"res://scripts/slice/slice_world.gd", FileAccess.READ
	)
	_expect(world_file != null, "slice world source is readable")
	if world_file != null:
		var world_source := world_file.get_as_text()
		world_file.close()
		_expect(
			world_source.strip_edges().split("\n").size() <= 1485,
			"package 4C does not grow SliceWorld"
		)
		_expect(
			not world_source.contains("EVENT_DEVICE_")
			and not world_source.contains("STORAGE_BLOCKED"),
			"world root owns no 4C presentation branches"
		)
	var codec_file := FileAccess.open(
		"res://scripts/slice/slice_building_save_codec.gd", FileAccess.READ
	)
	_expect(codec_file != null, "building save codec source is readable")
	if codec_file != null:
		var codec_source := codec_file.get_as_text()
		codec_file.close()
		_expect(
			not codec_source.contains("collector_collecting")
			and not codec_source.contains("storage_blocked")
			and not codec_source.contains("relay_online"),
			"4C feedback vocabulary does not enter persisted state"
		)


func _new_collector(instance_id: String) -> SliceCollector:
	var collector := SliceCollectorScene.instantiate() as SliceCollector
	var definition := SliceBuildingCatalog.find(SliceBuildingCatalog.COLLECTOR_ID)
	collector.configure_building(instance_id, definition.building_id, Vector2i.ZERO, 0)
	collector.apply_definition(definition, SliceWorld.TILE_SIZE)
	return collector


func _new_storage(instance_id: String) -> SliceStorage:
	var storage := SliceStorageScene.instantiate() as SliceStorage
	var definition := SliceBuildingCatalog.find(SliceBuildingCatalog.STORAGE_ID)
	storage.configure_building(instance_id, definition.building_id, Vector2i.ZERO, 0)
	storage.apply_definition(definition, SliceWorld.TILE_SIZE)
	return storage


func _new_relay(instance_id: String) -> SlicePowerRelay:
	var relay := SlicePowerRelayScene.instantiate() as SlicePowerRelay
	var definition := SliceBuildingCatalog.find(SliceBuildingCatalog.POWER_RELAY_ID)
	relay.configure_building(instance_id, definition.building_id, Vector2i.ZERO, 0)
	relay.apply_definition(definition, SliceWorld.TILE_SIZE)
	return relay


func _expect(condition: bool, message: String) -> void:
	_assertion_count += 1
	if not condition:
		failures.append(message)


func _expect_equal(actual: Variant, expected: Variant, message: String) -> void:
	_expect(actual == expected, "%s (actual=%s expected=%s)" % [message, actual, expected])
