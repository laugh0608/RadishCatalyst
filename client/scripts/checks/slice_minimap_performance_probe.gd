extends SceneTree

## Non-headless development probe for A06. It compares the production
## UPDATE_ALWAYS path with a 10 Hz candidate without changing product behavior.

const SliceWorldScene := preload("res://scenes/slice/SliceWorld.tscn")
const SAMPLE_FRAMES := 360
const WARMUP_FRAMES := 90
const THROTTLED_FRAME_INTERVAL := 6
const ROUND_COUNT := 3

var _test_root := ""
var _map_viewport: SubViewport
var _overlay: SliceMinimapOverlay


func _init() -> void:
	call_deferred("_execute")


func _execute() -> void:
	if DisplayServer.get_name() == "headless":
		push_error("Minimap performance probe requires a rendered window.")
		quit(2)
		return
	_test_root = SliceCheckPaths.repository_root().path_join(
		"tools/runtime-intake/2026-08-26-playtest-remediation-package4/performance-probe"
	)
	_remove_tree(_test_root)
	DirAccess.make_dir_recursive_absolute(_test_root)
	DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_WINDOWED)
	DisplayServer.window_set_size(Vector2i(1600, 900))
	DisplayServer.window_set_vsync_mode(DisplayServer.VSYNC_DISABLED)
	Engine.max_fps = 0

	var world := SliceWorldScene.instantiate() as SliceWorld
	world.save_service = SliceSaveService.new(_test_root.path_join("world"))
	root.add_child(world)
	await process_frame
	await physics_frame
	var hud := world.get_node("SliceHud") as SliceHud
	_map_viewport = hud.minimap.get_node(
		"MapViewportContainer/MapViewport"
	) as SubViewport
	_overlay = hud.minimap.get_node("FogOverlay") as SliceMinimapOverlay

	var always_rounds: Array[Dictionary] = []
	var throttled_rounds: Array[Dictionary] = []
	for round_index in range(ROUND_COUNT):
		var always_first := round_index % 2 == 0
		for use_always in [always_first, not always_first]:
			var result := await _measure_mode(use_always)
			result["round"] = round_index + 1
			if use_always:
				always_rounds.append(result)
			else:
				throttled_rounds.append(result)

	var report := {
		"window_size": DisplayServer.window_get_size(),
		"sample_frames": SAMPLE_FRAMES,
		"warmup_frames": WARMUP_FRAMES,
		"throttled_hz": 60 / THROTTLED_FRAME_INTERVAL,
		"always": always_rounds,
		"candidate_10hz": throttled_rounds,
		"always_median_of_medians_ms": _median_of_metric(
			always_rounds, "median_ms"
		),
		"candidate_median_of_medians_ms": _median_of_metric(
			throttled_rounds, "median_ms"
		),
		"always_median_of_p95_ms": _median_of_metric(
			always_rounds, "p95_ms"
		),
		"candidate_median_of_p95_ms": _median_of_metric(
			throttled_rounds, "p95_ms"
		),
	}
	print("MINIMAP_A_B_JSON=%s" % JSON.stringify(report))
	_map_viewport.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	_overlay.set_process(true)
	world.free()
	_cleanup()
	quit(0)


func _measure_mode(use_always: bool) -> Dictionary:
	_configure_mode(use_always)
	for frame_index in range(WARMUP_FRAMES):
		_request_candidate_frame(use_always, frame_index)
		await process_frame
	var samples: Array[float] = []
	for frame_index in range(SAMPLE_FRAMES):
		_request_candidate_frame(use_always, frame_index)
		var started := Time.get_ticks_usec()
		await process_frame
		samples.append(float(Time.get_ticks_usec() - started) / 1000.0)
	samples.sort()
	return {
		"mode": "update_always" if use_always else "candidate_10hz",
		"median_ms": _percentile(samples, 0.50),
		"p95_ms": _percentile(samples, 0.95),
		"minimum_ms": samples[0],
		"maximum_ms": samples[samples.size() - 1],
	}


func _configure_mode(use_always: bool) -> void:
	_overlay.set_process(use_always)
	_map_viewport.render_target_update_mode = (
		SubViewport.UPDATE_ALWAYS
		if use_always
		else SubViewport.UPDATE_DISABLED
	)
	if not use_always:
		_map_viewport.render_target_update_mode = SubViewport.UPDATE_ONCE
		_overlay.queue_redraw()


func _request_candidate_frame(use_always: bool, frame_index: int) -> void:
	if use_always or frame_index % THROTTLED_FRAME_INTERVAL != 0:
		return
	_map_viewport.render_target_update_mode = SubViewport.UPDATE_ONCE
	_overlay.queue_redraw()


func _percentile(sorted_values: Array[float], ratio: float) -> float:
	var index := clampi(
		roundi((sorted_values.size() - 1) * ratio),
		0,
		sorted_values.size() - 1
	)
	return sorted_values[index]


func _median_of_metric(rows: Array[Dictionary], metric: String) -> float:
	var values: Array[float] = []
	for row in rows:
		values.append(float(row[metric]))
	values.sort()
	return _percentile(values, 0.50)


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
