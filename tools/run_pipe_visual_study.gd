extends SceneTree

## Boots an isolated world and mounts the explicitly labelled art specimen.
## --verify performs bounded real-input checks; default leaves it open for review.

const BOOT_SCENE := preload("res://scenes/boot/Boot.tscn")
const STUDY_SCENE := preload("res://scenes/visual_studies/TransparentPipeStudy.tscn")
const ORIGIN := Vector2(1024.0, 320.0)
const WORLD_NAME := "管道模块视觉样板"
const REVIEW_DIR := "pipe-module-visual"

var failures: Array[String] = []
var assertion_count := 0
var verify_mode := false
var repo_root := ""
var save_root := ""
var shot_root := ""
var boot: Node
var world: SliceWorld
var study: TransparentPipeStudy


func _init() -> void:
	verify_mode = "--verify" in OS.get_cmdline_user_args()
	repo_root = SliceCheckPaths.repository_root()
	var run_name := "run-%d" % Time.get_unix_time_from_system()
	save_root = SliceCheckPaths.check_run("pipe-module-visual/" + run_name) if verify_mode else SliceCheckPaths.review_worlds(REVIEW_DIR)
	shot_root = repo_root.path_join("assets/art-intake/2026-09-06-pipe-modules/runtime-preview").path_join(run_name)
	call_deferred("_execute")


func _execute() -> void:
	if verify_mode:
		create_timer(55.0).timeout.connect(func():
			push_error("Pipe visual verification exceeded 55 seconds.")
			quit(1)
		)
	await _open_world()
	if world == null:
		_finish()
		return
	await _prepare_fixture()
	if not world.save_now():
		failures.append("isolated specimen world saves through the standard service")
		_finish()
		return
	print("Pipe visual review save root: %s" % save_root)
	print("Pipe visual screenshots: %s" % shot_root)
	if not verify_mode:
		print("Pipe visual study is open. Controls affect the specimen only; use the real HUD to enter build mode.")
		return
	_verify_geometry()
	await _verify_inputs_and_frames()
	_finish()


func _open_world() -> void:
	root.mode = Window.MODE_WINDOWED
	root.size = Vector2i(1440, 810)
	await process_frame
	boot = BOOT_SCENE.instantiate()
	boot.slice_save_catalog = SliceSaveCatalog.new(save_root)
	root.add_child(boot)
	await process_frame
	await process_frame
	var menu := boot.get_node_or_null("StartupMenu") as StartupMenu
	_expect(menu != null, "formal Boot opens the startup menu")
	if menu == null:
		return
	if not verify_mode:
		menu.load_game_button.pressed.emit()
		await process_frame
		if menu.world_item_list.item_count > 0:
			menu.world_item_list.select(0)
			menu.world_item_list.item_selected.emit(0)
			menu.load_world_button.pressed.emit()
		else:
			await _create_world_from_menu(menu)
	else:
		await _create_world_from_menu(menu)
	await process_frame
	await physics_frame
	await process_frame
	world = boot.get_node_or_null("SliceWorld") as SliceWorld
	_expect(world != null, "formal menu enters the isolated SliceWorld")
	root.mode = Window.MODE_WINDOWED
	root.size = Vector2i(1440, 810)
	await process_frame
	_expect(root.mode == Window.MODE_WINDOWED and root.size == Vector2i(1440, 810), "visual verification uses an explicit 1440x810 window")


func _create_world_from_menu(menu: StartupMenu) -> void:
	menu.new_game_button.pressed.emit()
	await process_frame
	menu.world_name_input.text = WORLD_NAME
	menu.create_world_button.pressed.emit()


func _prepare_fixture() -> void:
	var floor_definition := SliceBuildingCatalog.find(SliceBuildingCatalog.FLOOR_ID)
	for y in range(7, 18):
		for x in range(31, 55):
			var cell := Vector2i(x, y)
			if world._industrial_floor.get_cell_source_id(cell) < 0:
				world._spawn_building(floor_definition, "", cell, 0, {})
	var storage_exists := false
	for instance in world._building_instances:
		if instance is SliceStorage and instance.origin_cell == Vector2i(33, 15):
			storage_exists = true
	if not storage_exists:
		world._spawn_building(SliceBuildingCatalog.find(SliceBuildingCatalog.STORAGE_ID), "", Vector2i(33, 15), 0, {})
	world.player.position = Vector2(1392.0, 480.0)
	var camera := world.player.get_node("Camera") as Camera2D
	camera.reset_smoothing()
	study = STUDY_SCENE.instantiate() as TransparentPipeStudy
	study.position = ORIGIN
	study.z_index = 2
	world._map.add_child(study)
	await process_frame
	await process_frame
	var scale_label := Label.new()
	scale_label.text = "现有储物箱 · 比例参考"
	scale_label.position = Vector2(1020.0, 555.0)
	scale_label.add_theme_font_override("font", TransparentPipeStudy.STUDY_FONT)
	scale_label.add_theme_font_size_override("font_size", 12)
	scale_label.add_theme_color_override("font_color", Color("e2e3d6"))
	scale_label.add_theme_color_override("font_outline_color", Color("151c1e"))
	scale_label.add_theme_constant_override("outline_size", 3)
	scale_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	world._map.add_child(scale_label)
	_expect(camera.zoom == Vector2(2.0, 2.0), "normal world camera retains its existing 2.0 zoom")


func _verify_geometry() -> void:
	var path := study.primary_path
	_expect(PipeVisualPath.SEGMENTS.size() == 9, "representative route contains the port, straight modules and one bend")
	_expect(path._materials.size() == PipeVisualPath.SEGMENTS.size(), "each segment has its own clipped dynamic layer")
	for index in PipeVisualPath.SEGMENTS.size():
		var body := path.get_node("Body%d" % index) as Sprite2D
		var content := path.get_node("Content%d" % index) as Sprite2D
		_expect(body.texture.get_size() == Vector2(32, 32) and content.texture.get_size() == Vector2(32, 32), "segment %d uses matching 32px body and mask textures" % index)
		_expect(body.z_index > content.z_index, "segment %d metal artwork occludes the dynamic layer" % index)
	var traveled := 0.0
	var offsets := path.segment_offsets()
	for index in PipeVisualPath.SEGMENTS.size():
		var expected := traveled - (13.0 if index == 0 else 0.0)
		_expect(absf(offsets[index] - expected) < 0.001, "segment %d shares continuous path distance with the shader" % index)
		traveled += float(PipeVisualPath.SEGMENTS[index][3])
	var maximum_step := 0.0
	var last: Vector2 = path.sample_path(0.0)["position"]
	var distance := 0.5
	while distance <= path.path_length:
		var point: Vector2 = path.sample_path(distance)["position"]
		maximum_step = maxf(maximum_step, point.distance_to(last))
		last = point
		distance += 0.5
	_expect(maximum_step <= 0.501, "all straight and curved path samples remain continuous at 0.5px steps")
	var bend_start := 19.0 + 4.0 * 32.0
	var incoming: Vector2 = path.sample_path(bend_start + 1.0)["tangent"]
	var outgoing: Vector2 = path.sample_path(bend_start + PipeVisualPath.CORNER_LENGTH - 1.0)["tangent"]
	_expect(incoming == Vector2.RIGHT and outgoing == Vector2.DOWN, "the representative bend turns from rightward to downward")
	path.set_process(false)
	path.set_preview_phase(0.0)
	path.advance_preview(0.25)
	_expect(is_equal_approx(path.phase, 4.5), "an explicit interval advances the visual phase at the declared demonstration speed")
	path.configure(PipeVisualPath.ContentState.IDLE, PipeVisualPath.MATERIAL_A)
	path.advance_preview(1.0)
	_expect(is_equal_approx(path.phase, 4.5), "idle retains its phase")
	_expect(bool(path._materials[0].get_shader_parameter("has_content")), "idle retains content")
	_expect(is_equal_approx(float(path._materials[0].get_shader_parameter("marker_opacity")), 0.26), "idle markers become faint")
	path.configure(PipeVisualPath.ContentState.FLOW, PipeVisualPath.MATERIAL_A, -1)
	path.advance_preview(0.1)
	_expect(is_equal_approx(path.phase, 2.7), "reverse advances back along the same path")
	path.configure(PipeVisualPath.ContentState.FLOW, PipeVisualPath.MATERIAL_A)
	path.set_preview_phase(14.0)
	path.set_process(true)
	_expect(study.empty_path.content_state == PipeVisualPath.ContentState.EMPTY and not bool(study.empty_path._materials[0].get_shader_parameter("has_content")), "the empty control hides both content and directional marks")
	_expect(not study.get_parent() == world._map.get_node("World"), "specimen is separate from the device obstruction layer")


func _verify_inputs_and_frames() -> void:
	var path := study.primary_path
	var initial_building_count := world._building_instances.size()
	await _screenshot("01-normal-flow.png")
	await _click_control(study.pause_button)
	_expect(path.animation_paused, "real pause click freezes preview animation")
	for index in 6:
		path.set_preview_phase(12.0 + index * 4.0)
		await _screenshot("motion-%02d.png" % index)
	var before_wait := path.phase
	await create_timer(0.15).timeout
	_expect(is_equal_approx(path.phase, before_wait), "paused preview remains stationary across real frames")
	await _click_control(study.pause_button)
	await create_timer(0.15).timeout
	_expect(not is_equal_approx(path.phase, before_wait), "resuming the preview advances actual rendered-frame phase")
	await _click_control(study.idle_button)
	_expect(path.content_state == PipeVisualPath.ContentState.IDLE, "real click changes the primary specimen to idle")
	await _screenshot("02-normal-idle.png")
	await _click_control(study.empty_button)
	_expect(path.content_state == PipeVisualPath.ContentState.EMPTY, "real click changes the primary specimen to empty")
	await _screenshot("03-normal-empty.png")
	await _click_control(study.flow_button)
	await _click_control(study.color_button)
	_expect(path.content_state == PipeVisualPath.ContentState.FLOW and path.fluid_color == PipeVisualPath.MATERIAL_B, "real controls restore flow and change material color")
	await _click_control(study.reverse_button)
	_expect(path.flow_direction == -1, "real direction control reverses the specimen")
	await _screenshot("04-normal-reverse-amber.png")
	var hud := world.get_node("SliceHud") as SliceHud
	await _click_control(hud.build_mode_button)
	var camera := world.player.get_node("Camera") as Camera2D
	_expect(world.is_build_mode_active() and camera.zoom == Vector2(1.5, 1.5), "real HUD enters the existing 1.5 construction zoom")
	_expect(study.modulate == Color.WHITE, "ground-level pipe specimen retains readable opacity in construction view")
	await _screenshot("05-build-reverse-amber.png")
	await _click_control(study.color_button)
	await _click_control(study.reverse_button)
	await _screenshot("06-build-forward-cyan.png")
	await _click_control(hud.build_mode_button)
	_expect(not world.is_build_mode_active() and camera.zoom == Vector2(2.0, 2.0), "real HUD restores the normal zoom")
	_expect(world._building_instances.size() == initial_building_count, "specimen controls never create or remove real buildings")
	_expect(world.save_now(), "the base fixture remains saveable with no pipe schema")
	await _screenshot("07-final-normal.png")


func _click_control(control: Control) -> void:
	var point := control.get_global_rect().get_center()
	_expect(control.is_visible_in_tree() and root.get_visible_rect().has_point(point), "clicked control is visible within the viewport")
	var window_point := root.get_final_transform() * point
	root.warp_mouse(point)
	await process_frame
	var motion := InputEventMouseMotion.new()
	motion.position = window_point
	motion.global_position = window_point
	Input.parse_input_event(motion)
	await process_frame
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
	var image := root.get_texture().get_image()
	_expect(not image.is_empty(), "window produces a rendered image for %s" % file_name)
	var error := image.save_png(shot_root.path_join(file_name))
	_expect(error == OK, "screenshot writes successfully: %s" % file_name)


func _expect(condition: bool, context: String) -> void:
	assertion_count += 1
	if not condition:
		failures.append(context)


func _finish() -> void:
	if failures.is_empty():
		print("Pipe module visual verification passed (%d assertions)." % assertion_count)
		quit(0)
		return
	for failure in failures:
		push_error(failure)
	quit(1)
