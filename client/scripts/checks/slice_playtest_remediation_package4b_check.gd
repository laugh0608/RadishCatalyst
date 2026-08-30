extends SceneTree

const SliceMapScene := preload("res://scenes/slice/SliceMap.tscn")
const SliceReactorScene := preload("res://scenes/slice/SliceReactor.tscn")
const SliceWorldScene := preload("res://scenes/slice/SliceWorld.tscn")

var failures: Array[String] = []
var _assertion_count := 0
var _test_root := ""


func _init() -> void:
	call_deferred("_execute")


func _execute() -> void:
	_test_root = "user://slice-playtest-remediation-package4b-%d" % Time.get_ticks_usec()
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(_test_root))
	_check_state_predicates_and_audio_profiles()
	await _check_core_feedback()
	await _check_reactor_feedback()
	await _check_loaded_world_starts_silent()
	_check_ownership_boundaries()
	if failures.is_empty():
		print(
			"Slice playtest remediation package 4B checks passed (%d assertions)."
			% _assertion_count
		)
		_cleanup()
		quit(0)
		return
	for failure in failures:
		push_error(failure)
	_cleanup()
	quit(1)


func _check_state_predicates_and_audio_profiles() -> void:
	_expect_equal(
		SliceDeviceFeedbackState.core_state(false, false, false),
		SliceDeviceFeedbackState.CORE_DAMAGED,
		"unrepaired core resolves to damaged"
	)
	_expect_equal(
		SliceDeviceFeedbackState.core_state(true, false, false),
		SliceDeviceFeedbackState.CORE_REPAIRED,
		"repaired uncharged core resolves to ready"
	)
	_expect_equal(
		SliceDeviceFeedbackState.core_state(true, true, false),
		SliceDeviceFeedbackState.CORE_CHARGED,
		"charged core resolves to running"
	)
	_expect_equal(
		SliceDeviceFeedbackState.core_state(false, false, true),
		SliceDeviceFeedbackState.CORE_SAMPLE_INSTALLED,
		"delivered sample has highest presentation precedence"
	)
	_expect_equal(
		SliceDeviceFeedbackState.reactor_state(false, true, true),
		SliceDeviceFeedbackState.REACTOR_UNPOWERED,
		"power loss has highest reactor presentation precedence"
	)
	_expect_equal(
		SliceDeviceFeedbackState.reactor_state(true, true, true),
		SliceDeviceFeedbackState.REACTOR_PROCESSING,
		"active batch takes precedence over occupied output"
	)
	_expect_equal(
		SliceDeviceFeedbackState.reactor_state(true, false, true),
		SliceDeviceFeedbackState.REACTOR_BLOCKED,
		"occupied output resolves to blocked"
	)
	_expect_equal(
		SliceDeviceFeedbackState.reactor_state(true, false, false),
		SliceDeviceFeedbackState.REACTOR_IDLE,
		"powered reactor without a batch remains idle"
	)
	_expect_equal(
		SliceDeviceFeedbackState.core_edge_event(
			&"", SliceDeviceFeedbackState.CORE_SAMPLE_INSTALLED
		),
		&"",
		"first core observation restores silently"
	)
	_expect_equal(
		SliceDeviceFeedbackState.reactor_edge_event(
			&"", SliceDeviceFeedbackState.REACTOR_PROCESSING
		),
		&"",
		"first reactor observation restores silently"
	)
	_expect_equal(
		SliceDeviceFeedbackState.core_edge_event(
			SliceDeviceFeedbackState.CORE_REPAIRED,
			SliceDeviceFeedbackState.CORE_CHARGED
		),
		SliceDeviceFeedbackState.EVENT_CORE_CHARGED,
		"core charge edge maps to one cue"
	)
	_expect_equal(
		SliceDeviceFeedbackState.reactor_edge_event(
			SliceDeviceFeedbackState.REACTOR_PROCESSING,
			SliceDeviceFeedbackState.REACTOR_BLOCKED
		),
		SliceDeviceFeedbackState.EVENT_REACTOR_BLOCKED,
		"reactor blocked edge maps to one cue"
	)
	for event_id in [
		SliceDeviceFeedbackState.EVENT_CORE_REPAIRED,
		SliceDeviceFeedbackState.EVENT_CORE_CHARGED,
		SliceDeviceFeedbackState.EVENT_CORE_SAMPLE_INSTALLED,
		SliceDeviceFeedbackState.EVENT_REACTOR_POWER_LOST,
		SliceDeviceFeedbackState.EVENT_REACTOR_STARTED,
		SliceDeviceFeedbackState.EVENT_REACTOR_BLOCKED,
	]:
		var stream := SliceFeedbackAudio.stream_for(event_id)
		_expect(stream != null, "%s has a project-authored WAV" % event_id)
		if stream != null:
			_expect_equal(stream.mix_rate, SliceFeedbackAudio.MIX_RATE, "%s uses the frozen mix rate" % event_id)
			_expect(stream.data.size() > 0, "%s contains PCM samples" % event_id)


func _check_core_feedback() -> void:
	var map := SliceMapScene.instantiate()
	root.add_child(map)
	await process_frame
	var visual := map.get_node(
		"World/OutpostCoreVisualSortShell"
	) as SliceCoreVisual
	var events: Array[StringName] = []
	visual.feedback_event_played.connect(
		func(event_id: StringName): events.append(event_id)
	)
	visual.apply_feedback_state(SliceDeviceFeedbackState.CORE_DAMAGED)
	_expect_equal(visual.feedback_audio_play_count(), 0, "damaged baseline is silent")
	_expect_equal(visual.feedback_active_segment_count(), 2, "damaged core uses a split warning pattern")
	_expect(
		visual.get_node("FeedbackVisual/FaultMark").visible,
		"damaged core exposes a non-color fault shape"
	)
	visual.apply_feedback_state(SliceDeviceFeedbackState.CORE_REPAIRED)
	_expect_equal(visual.feedback_audio_play_count(), 1, "repair edge plays once")
	_expect_equal(visual.feedback_active_segment_count(), 1, "ready core uses one breathing segment")
	visual.apply_feedback_state(SliceDeviceFeedbackState.CORE_REPAIRED)
	_expect_equal(visual.feedback_audio_play_count(), 1, "stable repaired state does not replay")
	visual.apply_feedback_state(SliceDeviceFeedbackState.CORE_CHARGED)
	_expect_equal(visual.feedback_audio_play_count(), 2, "charge edge plays once")
	_expect_equal(visual.feedback_active_segment_count(), 3, "charged core uses a three-segment cycle")
	visual.apply_feedback_state(SliceDeviceFeedbackState.CORE_SAMPLE_INSTALLED)
	_expect_equal(visual.feedback_audio_play_count(), 3, "sample installation edge plays once")
	_expect(
		visual.get_node("FeedbackVisual/LockMark").visible,
		"sample-installed core exposes a stable lock shape"
	)
	_expect_equal(
		events,
		[
			SliceDeviceFeedbackState.EVENT_CORE_REPAIRED,
			SliceDeviceFeedbackState.EVENT_CORE_CHARGED,
			SliceDeviceFeedbackState.EVENT_CORE_SAMPLE_INSTALLED,
		],
		"core cue order follows authoritative milestone edges"
	)
	_expect_equal(
		(visual.get_node("FeedbackAudio") as AudioStreamPlayer2D).bus,
		&"SFX",
		"core cues use the SFX bus"
	)
	map.free()


func _check_reactor_feedback() -> void:
	var reactor := _new_reactor("package4b-reactor")
	root.add_child(reactor)
	await process_frame
	var events: Array[StringName] = []
	reactor.feedback_event_played.connect(
		func(event_id: StringName): events.append(event_id)
	)
	_expect_equal(
		reactor.feedback_state(),
		SliceDeviceFeedbackState.REACTOR_UNPOWERED,
		"new unpowered reactor establishes a silent baseline"
	)
	_expect_equal(reactor.feedback_audio_play_count(), 0, "reactor baseline is silent")
	reactor.set_powered(true)
	reactor.refresh_feedback()
	_expect_equal(reactor.feedback_state(), SliceDeviceFeedbackState.REACTOR_IDLE, "powered empty reactor is idle")
	_expect_equal(reactor.feedback_active_segment_count(), 1, "idle reactor uses one stable segment")
	_expect_equal(reactor.feedback_audio_play_count(), 0, "entering idle does not chirp")

	reactor.processing = true
	reactor.refresh_feedback()
	await process_frame
	_expect_equal(reactor.feedback_state(), SliceDeviceFeedbackState.REACTOR_PROCESSING, "active batch is visible")
	_expect_equal(reactor.feedback_active_segment_count(), 3, "processing uses a three-segment cycle")
	_expect(
		(reactor.get_node("ProcessingOverlay") as Sprite2D).visible,
		"powered processing reuses the existing overlay"
	)
	_expect_equal(reactor.feedback_audio_play_count(), 1, "batch start plays once")

	reactor.set_powered(false)
	reactor.refresh_feedback()
	await process_frame
	_expect_equal(reactor.feedback_state(), SliceDeviceFeedbackState.REACTOR_UNPOWERED, "lost power overrides retained progress")
	_expect(
		not (reactor.get_node("ProcessingOverlay") as Sprite2D).visible,
		"unpowered reactor hides the processing overlay"
	)
	_expect_equal(reactor.feedback_audio_play_count(), 2, "power loss plays one warning")

	reactor.processing = false
	reactor.set_powered(true)
	reactor.refresh_feedback()
	reactor.output_inventory.add(SliceReactor.OUTPUT_ITEM_ID, 1)
	reactor.refresh_feedback()
	_expect_equal(reactor.feedback_state(), SliceDeviceFeedbackState.REACTOR_BLOCKED, "occupied output shows blocked")
	_expect_equal(reactor.feedback_active_segment_count(), 2, "blocked reactor uses a two-part warning")
	_expect(
		reactor.get_node("FeedbackVisual/BlockedMark").visible,
		"blocked reactor exposes a non-color stop shape"
	)
	_expect_equal(reactor.feedback_audio_play_count(), 3, "first blocked edge warns once")
	reactor.output_inventory.remove(SliceReactor.OUTPUT_ITEM_ID, 1)
	reactor.refresh_feedback()
	reactor.output_inventory.add(SliceReactor.OUTPUT_ITEM_ID, 1)
	reactor.refresh_feedback()
	_expect_equal(
		reactor.feedback_audio_play_count(),
		3,
		"blocked warning cooldown suppresses immediate flapping"
	)
	_expect_equal(
		events,
		[
			SliceDeviceFeedbackState.EVENT_REACTOR_STARTED,
			SliceDeviceFeedbackState.EVENT_REACTOR_POWER_LOST,
			SliceDeviceFeedbackState.EVENT_REACTOR_BLOCKED,
		],
		"reactor emits only meaningful edge cues"
	)
	_expect_equal(
		(reactor.get_node("FeedbackAudio") as AudioStreamPlayer2D).bus,
		&"SFX",
		"reactor cues use the SFX bus"
	)
	reactor.free()

	var restored_processing := _new_reactor("package4b-restored-reactor")
	restored_processing.processing = true
	restored_processing.production_progress = 4.0
	restored_processing.set_powered(true)
	root.add_child(restored_processing)
	await process_frame
	_expect_equal(
		restored_processing.feedback_state(),
		SliceDeviceFeedbackState.REACTOR_PROCESSING,
		"restored processing state establishes directly"
	)
	_expect_equal(
		restored_processing.feedback_audio_play_count(),
		0,
		"restored processing state does not replay batch start"
	)
	restored_processing.free()


func _check_loaded_world_starts_silent() -> void:
	var save_root := _test_root.path_join("loaded-world")
	var source_world := SliceWorldScene.instantiate() as SliceWorld
	source_world.save_service = SliceSaveService.new(save_root)
	root.add_child(source_world)
	await process_frame
	source_world.core_repaired = true
	source_world.core_energy = SliceWorld.CORE_CHARGE_TARGET
	source_world.combat_controller.encounter_state = "delivered"
	source_world._refresh_core_charge_visual()
	_expect(source_world.save_now(), "delivered world saves for load-silence check")
	source_world.free()

	var loaded_world := SliceWorldScene.instantiate() as SliceWorld
	loaded_world.save_service = SliceSaveService.new(save_root)
	loaded_world.startup_load = true
	root.add_child(loaded_world)
	await process_frame
	await physics_frame
	var visual := loaded_world._core_visual()
	_expect_equal(
		visual.feedback_state(),
		SliceDeviceFeedbackState.CORE_SAMPLE_INSTALLED,
		"load restores the final core presentation directly"
	)
	_expect_equal(
		visual.feedback_audio_play_count(),
		0,
		"load does not replay repair, charge or sample milestones"
	)
	loaded_world.free()


func _check_ownership_boundaries() -> void:
	var world_file := FileAccess.open(
		"res://scripts/slice/slice_world.gd", FileAccess.READ
	)
	_expect(world_file != null, "slice world source is readable")
	if world_file != null:
		var world_source := world_file.get_as_text()
		world_file.close()
		_expect(
			world_source.split("\n").size() <= 1489,
			"package 4B does not grow SliceWorld"
		)
		_expect(
			not world_source.contains("EVENT_REACTOR_")
			and not world_source.contains("FeedbackAudio"),
			"world root owns no device cue branches"
		)
	var codec_file := FileAccess.open(
		"res://scripts/slice/slice_building_save_codec.gd", FileAccess.READ
	)
	_expect(codec_file != null, "building save codec source is readable")
	if codec_file != null:
		var codec_source := codec_file.get_as_text()
		codec_file.close()
		_expect(
			not codec_source.contains("feedback_state")
			and not codec_source.contains("reactor_blocked"),
			"feedback vocabulary does not enter persisted device state"
		)


func _new_reactor(instance_id: String) -> SliceReactor:
	var reactor := SliceReactorScene.instantiate() as SliceReactor
	var definition := SliceBuildingCatalog.find(SliceBuildingCatalog.REACTOR_ID)
	reactor.configure_building(instance_id, definition.building_id, Vector2i.ZERO, 0)
	reactor.apply_definition(definition, SliceWorld.TILE_SIZE)
	return reactor


func _cleanup() -> void:
	_remove_tree(ProjectSettings.globalize_path(_test_root))


func _remove_tree(path: String) -> void:
	if not DirAccess.dir_exists_absolute(path):
		return
	var dir := DirAccess.open(path)
	if dir == null:
		return
	dir.list_dir_begin()
	var entry := dir.get_next()
	while not entry.is_empty():
		var child := path.path_join(entry)
		if dir.current_is_dir():
			_remove_tree(child)
		else:
			DirAccess.remove_absolute(child)
		entry = dir.get_next()
	dir.list_dir_end()
	DirAccess.remove_absolute(path)


func _expect(condition: bool, label: String) -> void:
	_assertion_count += 1
	if not condition:
		failures.append(label)


func _expect_equal(actual, expected, label: String) -> void:
	_assertion_count += 1
	if actual != expected:
		failures.append("%s: expected %s, got %s" % [label, expected, actual])
