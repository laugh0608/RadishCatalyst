extends SceneTree

## Formal Boot entry with isolated saves. This fixture creates no working pipe.

const BOOT_SCENE := preload("res://scenes/boot/Boot.tscn")
const STUDY_SCENE := preload("res://scenes/visual_studies/IndustrialVolumeStudy.tscn")
const ORIGIN := Vector2(1280, 320)
const PLAYER_START := ORIGIN + Vector2(120, 160)

var failures: Array[String] = []
var assertion_count := 0
var verify_mode := false
var save_root := ""
var shot_root := ""
var boot: Node
var world: SliceWorld
var study: IndustrialVolumeStudy


func _init() -> void:
	verify_mode = "--verify" in OS.get_cmdline_user_args()
	var run_name := "run-%d" % Time.get_unix_time_from_system()
	save_root = SliceCheckPaths.check_run("industrial-volume-visual/" + run_name) if verify_mode else SliceCheckPaths.review_worlds("industrial-volume-visual")
	shot_root = SliceCheckPaths.repository_root().path_join("assets/art-intake/2026-09-06-industrial-volume-assets/runtime-preview").path_join(run_name)
	call_deferred("_execute")


func _execute() -> void:
	if verify_mode:
		create_timer(55.0).timeout.connect(func():
			push_error("Volume visual verification exceeded 55 seconds.")
			quit(1)
		)
	await _open_world(not verify_mode)
	if world == null:
		_finish()
		return
	_prepare_fixture()
	await _settle_camera()
	_expect(world.save_now(), "isolated floor fixture saves through the standard service")
	if not failures.is_empty():
		_finish()
		return
	print("Industrial volume review save root: %s" % save_root)
	print("Industrial volume screenshots: %s" % shot_root)
	if not verify_mode:
		print("Industrial volume study is open. WASD and the existing build button remain available.")
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
		menu.world_name_input.text = "局部体积视觉样板"
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
	for y in range(9, 17):
		for x in range(38, 50):
			var cell := Vector2i(x, y)
			if world._industrial_floor.get_cell_source_id(cell) < 0:
				world._spawn_building(floor_definition, "", cell, 0, {})
	_mount_study()
	world.player.position = PLAYER_START


func _mount_study() -> void:
	_expect(world._build_mode._overlay.draw_ground and not world._build_mode._ground_overlay.visible, "ordinary Boot retains its original overlay policy before study opt-in")
	study = STUDY_SCENE.instantiate() as IndustrialVolumeStudy
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
	_expect(camera.zoom == Vector2(2, 2), "normal camera remains at its existing 2.0 zoom")
	_expect(study.scale == Vector2.ONE and world.player.scale == Vector2.ONE, "specimen and real player retain world-pixel scale")
	_expect(study.y_sort_enabled and study.get_parent().y_sort_enabled, "volume roots participate in the real world depth sort")
	_expect(study.machine_root.get_node("Machine").texture.get_size() == Vector2(128, 128), "machine uses its declared canvas without runtime enlargement")
	_expect(study.pipe_root.get_node("Pipe").texture.get_size() == Vector2(96, 32), "pipe uses its declared three-cell canvas")
	await _screenshot("01-normal-volume.png")
	root.size = Vector2i(960, 540)
	await _screenshot("02-native-960.png")
	root.size = Vector2i(1440, 810)
	await _click(study.shadow_button)
	_expect(not study.shadows.visible, "real input toggles separate shadow sprites")
	await _click(study.support_button)
	_expect(not study.supports[0].visible and not study.supports[1].visible, "real input hides both independent supports")
	await _screenshot("03-without-support-and-shadow.png")
	await _click(study.shadow_button)
	await _click(study.support_button)
	await _click(study.floor_button)
	_expect(not study.quiet_floor.visible, "real input restores the current industrial floor appearance")
	await _screenshot("04-current-floor.png")
	await _click(study.floor_button)
	# Position the real player behind the tube, then walk across its contact depth.
	world.player.position = ORIGIN + Vector2(152, 77)
	await _settle_camera()
	_expect(world.player.position.y < study.pipe_root.global_position.y, "real player begins behind the pipe depth anchor")
	await _screenshot("05-player-behind.png")
	Input.action_press("move_down")
	var frames := 0
	while world.player.position.y < ORIGIN.y + 124 and frames < 120:
		await physics_frame
		frames += 1
	Input.action_release("move_down")
	_expect(world.player.position.y >= ORIGIN.y + 124, "real movement crosses from behind to in front of the specimen")
	await _settle_camera()
	await _screenshot("06-player-front.png")
	world.player.position = PLAYER_START
	await _settle_camera()
	var hud := world.get_node("SliceHud") as SliceHud
	await _click(hud.build_mode_button)
	_expect(world.is_build_mode_active() and camera.zoom == Vector2(1.5, 1.5), "existing HUD enters the 1.5 construction view")
	_expect(study.modulate == Color.WHITE and study.ground.modulate == Color.WHITE, "layered build view preserves compound root and ground opacity")
	_expect(study.bodies[0].self_modulate == SliceBuildModeController.BODY_COLOR, "only the registered machine body uses the existing building fade")
	_expect(world._build_mode._ground_overlay.visible and not world._build_mode._overlay.draw_ground, "ordinary grid is on the ground while structure hints retain their overlay")
	await _screenshot("07-build-layered.png")
	root.size = Vector2i(960, 540)
	await _screenshot("09-build-native-960.png")
	root.size = Vector2i(1440, 810)
	await _click(study.presentation_button)
	_expect(study.modulate == SliceBuildModeController.OBSTRUCTION_COLOR, "legacy comparison retains the original compound fade")
	_expect(not world._build_mode._ground_overlay.visible and world._build_mode._overlay.draw_ground, "legacy comparison restores the default grid rendering")
	await _screenshot("10-build-legacy.png")
	await _click(study.presentation_button)
	await _click(study.floor_button)
	await _screenshot("11-build-current-floor.png")
	await _click(study.floor_button)
	world.pocket.add(SliceWorld.ITEM_STORAGE_KIT, 1)
	_expect(world.begin_building_placement(SliceBuildingCatalog.STORAGE_ID), "existing kit entry starts a real placement preview")
	var target := ORIGIN + Vector2(240, 128)
	var pointer := InputEventMouseMotion.new()
	pointer.position = root.get_final_transform() * (world.get_canvas_transform() * target)
	pointer.global_position = pointer.position
	Input.parse_input_event(pointer)
	await physics_frame
	await process_frame
	_expect(world._placement._overlay.visible and world._placement._preview.visible, "placement feedback stays visible with the ground grid separated")
	await _screenshot("12-build-placement.png")
	world.cancel_building_placement()
	world.pocket.remove(SliceWorld.ITEM_STORAGE_KIT, 1)
	await _click(hud.build_mode_button)
	_expect(not world.is_build_mode_active() and camera.zoom == Vector2(2, 2), "existing HUD restores normal view")
	_expect(study.modulate == Color.WHITE, "existing obstruction policy restores the sample opacity")
	_expect(study.bodies[0].self_modulate == Color.WHITE and study.ground.modulate == Color.WHITE, "leaving build view restores body and ground independently")
	_expect(world._building_instances.size() == initial_count, "presentation controls never create gameplay buildings")
	_expect(world.save_now(), "visual specimen requires no new save data")
	boot.free()
	world = null
	await process_frame
	await _open_world(true)
	if world == null:
		return
	_expect(world._building_instances.size() == initial_count, "formal reload restores the floor fixture")
	_mount_study()
	await _settle_camera()
	_expect(world.player.position.distance_to(PLAYER_START) < 1.0, "formal reload restores the review position")
	await _screenshot("08-reloaded-normal.png")


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
		print("Industrial volume visual verification passed (%d assertions)." % assertion_count)
		quit(0)
		return
	for failure in failures:
		push_error(failure)
	quit(1)
