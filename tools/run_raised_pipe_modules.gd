extends SceneTree

## Formal Boot and isolated saves; this verifies presentation, never fluid transport.

const BOOT_SCENE := preload("res://scenes/boot/Boot.tscn")
const STUDY_SCENE := preload("res://scenes/visual_studies/RaisedPipeModuleStudy.tscn")
const ORIGIN := Vector2(1280, 288)
const PLAYER_START := ORIGIN + Vector2(208, 216)

var failures: Array[String] = []
var assertion_count := 0
var verify_mode := false
var save_root := ""
var shot_root := ""
var boot: Node
var world: SliceWorld
var study: RaisedPipeModuleStudy


func _init() -> void:
	verify_mode = "--verify" in OS.get_cmdline_user_args()
	var run_name := "run-%d" % Time.get_unix_time_from_system()
	save_root = SliceCheckPaths.check_run("raised-pipe-modules/" + run_name) if verify_mode else SliceCheckPaths.review_worlds("raised-pipe-modules")
	shot_root = SliceCheckPaths.repository_root().path_join("assets/art-intake/2026-09-06-raised-pipe-modules/runtime-preview").path_join(run_name)
	call_deferred("_execute")


func _execute() -> void:
	if verify_mode:
		create_timer(55.0).timeout.connect(func():
			push_error("Raised pipe visual verification exceeded 55 seconds.")
			quit(1)
		)
	await _open_world(not verify_mode)
	if world == null:
		_finish()
		return
	_prepare_fixture()
	await _settle_camera()
	_expect(world.save_now(), "isolated visual fixture saves through the standard service")
	if not failures.is_empty():
		_finish()
		return
	print("Raised pipe review save root: %s" % save_root)
	print("Raised pipe screenshots: %s" % shot_root)
	if not verify_mode:
		print("Raised pipe module study is open. WASD, build view and specimen controls are available.")
		return
	await _verify_presentation()
	_finish()


func _open_world(load_existing: bool) -> void:
	root.mode = Window.MODE_WINDOWED
	root.size = Vector2i(1440, 810)
	boot = BOOT_SCENE.instantiate()
	boot.slice_save_catalog = SliceSaveCatalog.new(save_root)
	root.add_child(boot)
	await process_frame
	await process_frame
	var menu := boot.get_node_or_null("StartupMenu") as StartupMenu
	_expect(menu != null, "formal Boot opens its startup menu")
	if menu == null:
		return
	var loaded := false
	if load_existing:
		menu.load_game_button.pressed.emit()
		await process_frame
		if menu.world_item_list.item_count > 0:
			menu.world_item_list.select(0)
			menu.world_item_list.item_selected.emit(0)
			menu.load_world_button.pressed.emit()
			loaded = true
	if not loaded:
		menu.new_game_button.pressed.emit()
		await process_frame
		menu.world_name_input.text = "架空管道模块视觉样板"
		menu.create_world_button.pressed.emit()
	await process_frame
	await physics_frame
	await process_frame
	world = boot.get_node_or_null("SliceWorld") as SliceWorld
	_expect(world != null, "formal menu enters the isolated world")
	root.mode = Window.MODE_WINDOWED
	root.size = Vector2i(1440, 810)


func _prepare_fixture() -> void:
	var floor_definition := SliceBuildingCatalog.find(SliceBuildingCatalog.FLOOR_ID)
	for y in range(8, 17):
		for x in range(39, 52):
			var cell := Vector2i(x, y)
			if world._industrial_floor.get_cell_source_id(cell) < 0:
				world._spawn_building(floor_definition, "", cell, 0, {})
	_mount_study()
	world.player.position = PLAYER_START


func _mount_study() -> void:
	study = STUDY_SCENE.instantiate() as RaisedPipeModuleStudy
	study.position = ORIGIN
	world._map.get_node("World").add_child(study)
	study.configure_build_view(world)


func _settle_camera() -> void:
	(world.player.get_node("Camera") as Camera2D).reset_smoothing()
	await process_frame
	await physics_frame
	await process_frame


func _verify_presentation() -> void:
	var camera := world.player.get_node("Camera") as Camera2D
	var initial_count := world._building_instances.size()
	var pipe := study.pipe
	_expect(camera.zoom == Vector2(2, 2), "normal camera retains its existing zoom")
	_expect(study.scale == Vector2.ONE and pipe.scale == Vector2.ONE and world.player.scale == Vector2.ONE, "all specimens and player retain world-pixel scale")
	_expect(study.y_sort_enabled and pipe.y_sort_enabled and study.get_parent().y_sort_enabled, "segments participate in the real world contact-depth sort")
	_expect(pipe.segment_roots.size() == 9, "finite L route assembles the four module kinds into nine segments")
	var offsets := pipe.segment_offsets()
	var expected_offset := -13.0
	for index in offsets.size():
		_expect(is_equal_approx(offsets[index], expected_offset), "path metric remains continuous at segment %d" % index)
		expected_offset = (0.0 if index == 0 else expected_offset) + float(PipeVisualPath.SEGMENTS[index][3])
	var corner_entry := 19.0 + 4.0 * 32.0
	for distance in [corner_entry, corner_entry + PipeVisualPath.CORNER_LENGTH]:
		var before: Vector2 = pipe.sample_path(distance - 0.01)["position"]
		var after: Vector2 = pipe.sample_path(distance + 0.01)["position"]
		_expect(before.distance_to(after) < 0.03, "the rounded bend joins its straight neighbors without a path jump")
	var previous_phase := pipe.phase
	await process_frame
	await process_frame
	_expect(not is_equal_approx(previous_phase, pipe.phase), "live process frames advance flow markers")
	await _click(study.pause_button)
	previous_phase = pipe.phase
	await process_frame
	await process_frame
	_expect(is_equal_approx(previous_phase, pipe.phase), "pause keeps the rendered flow phase fixed")
	pipe.set_preview_phase(8.0)
	await _screenshot("01-normal-flow.png")
	root.size = Vector2i(960, 540)
	await _screenshot("02-native-flow.png")
	root.size = Vector2i(1440, 810)
	for index in 7:
		pipe.set_preview_phase(index * 4.0)
		await _screenshot("motion-%02d.png" % index)
	await _click(study.idle_button)
	_expect(pipe.content_state == PipeVisualPath.ContentState.IDLE, "mouse input selects stopped content")
	await _click(study.pause_button)
	previous_phase = pipe.phase
	pipe.advance_preview(1.0)
	_expect(is_equal_approx(previous_phase, pipe.phase), "stopped content does not advance even with the clock running")
	await _screenshot("03-idle.png")
	await _click(study.empty_button)
	_expect(pipe.content_state == PipeVisualPath.ContentState.EMPTY, "mouse input selects an empty pipe")
	_expect(not bool(pipe._materials[5].get_shader_parameter("has_content")), "empty bend hides content and markers while retaining its glass body")
	await _screenshot("04-empty.png")
	await _click(study.color_button)
	await _click(study.reverse_button)
	await _click(study.flow_button)
	_expect(pipe.fluid_color == PipeVisualPath.MATERIAL_B and pipe.flow_direction == -1, "amber content and reverse direction use the existing material semantics")
	await _click(study.pause_button)
	pipe.set_preview_phase(12.0)
	await _screenshot("05-amber-reverse.png")
	await _click(study.shadow_button)
	_expect(not study.shadows.visible, "shadow control hides ground projections only")
	await _screenshot("06-without-shadows.png")
	await _click(study.shadow_button)
	await _click(study.floor_button)
	await _screenshot("07-current-floor.png")
	await _click(study.floor_button)
	world.player.position = ORIGIN + Vector2(208, 76)
	await _settle_camera()
	_expect(world.player.position.y < pipe.segment_roots[3].global_position.y, "real player begins behind a supported horizontal segment")
	await _screenshot("08-player-behind.png")
	Input.action_press("move_down")
	var frames := 0
	while world.player.position.y < ORIGIN.y + 132 and frames < 120:
		await physics_frame
		frames += 1
	Input.action_release("move_down")
	_expect(world.player.position.y >= ORIGIN.y + 132, "real movement crosses to the front of the elevated pipe")
	await _settle_camera()
	await _screenshot("09-player-front.png")
	world.player.position = PLAYER_START
	await _settle_camera()
	var hud := world.get_node("SliceHud") as SliceHud
	await _click(hud.build_mode_button)
	_expect(world.is_build_mode_active() and camera.zoom == Vector2(1.5, 1.5), "real HUD enters the existing construction zoom")
	_expect(study.modulate == Color.WHITE and study.ground.modulate == Color.WHITE, "construction keeps compound ground and root opaque")
	_expect(pipe.segment_roots[5].get_node("Body").self_modulate == SliceBuildModeController.BODY_COLOR, "construction dims the registered bend body independently")
	await _screenshot("10-build-flow.png")
	root.size = Vector2i(960, 540)
	await _screenshot("11-build-native.png")
	root.size = Vector2i(1440, 810)
	await _click(study.idle_button)
	_expect(is_equal_approx(float(pipe._materials[5].get_shader_parameter("marker_opacity")), 0.26), "construction stopped state dims markers without clearing content")
	await _screenshot("13-build-idle.png")
	await _click(study.empty_button)
	_expect(not bool(pipe._materials[5].get_shader_parameter("has_content")), "construction empty state clears the live material layer")
	await _screenshot("14-build-empty.png")
	await _click(study.flow_button)
	await _click(hud.build_mode_button)
	_expect(pipe.segment_roots[5].get_node("Body").self_modulate == Color.WHITE, "normal view restores pipe opacity")
	_expect(world._building_instances.size() == initial_count, "visual controls create no gameplay pipe or building state")
	_expect(world.save_now(), "normal save succeeds without visual pipe schema data")
	boot.free()
	world = null
	await process_frame
	await _open_world(true)
	if world == null:
		return
	_expect(world._building_instances.size() == initial_count, "formal reload preserves only the actual floor fixture")
	_mount_study()
	await _settle_camera()
	_expect(world.player.position.distance_to(PLAYER_START) < 1.0, "formal reload restores the review position")
	await _screenshot("12-reloaded.png")


func _click(control: Control) -> void:
	await process_frame
	var point := control.get_global_rect().get_center()
	_expect(control.is_visible_in_tree() and root.get_visible_rect().has_point(point), "clicked control is visible in the viewport")
	var window_point := root.get_final_transform() * point
	root.warp_mouse(point)
	for pressed in [true, false]:
		var event := InputEventMouseButton.new()
		event.button_index = MOUSE_BUTTON_LEFT
		event.position = window_point
		event.global_position = window_point
		event.pressed = pressed
		Input.parse_input_event(event)
		await process_frame
	await physics_frame
	await process_frame


func _screenshot(file_name: String) -> void:
	await process_frame
	await process_frame
	DirAccess.make_dir_recursive_absolute(shot_root)
	var picture := root.get_texture().get_image()
	_expect(not picture.is_empty() and picture.save_png(shot_root.path_join(file_name)) == OK, "rendered screenshot saved: " + file_name)


func _expect(condition: bool, context: String) -> void:
	assertion_count += 1
	if not condition:
		failures.append(context)


func _finish() -> void:
	if failures.is_empty():
		print("Raised pipe module visual verification passed (%d assertions)." % assertion_count)
		quit(0)
		return
	for failure in failures:
		push_error(failure)
	quit(1)
