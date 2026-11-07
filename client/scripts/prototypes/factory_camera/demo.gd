extends Control

const Board := preload("res://scripts/prototypes/factory_camera/board.gd")
const View := preload("res://scripts/prototypes/factory_camera/view.gd")
const Hud := preload("res://scripts/prototypes/factory_camera/hud.gd")
var board := Board.new()
var view := View.new()
var hud := Hud.new()
var selected := -1
var measuring := false
var cell := Vector2i.ZERO
var direction := 0
var paused := false
var notice := ""
var notice_until := 0
var output_root := ""
var screenshot_root := ""
var events: Array[Dictionary] = []
var captures := 0
var input_moves := 0
var core_study := false
var selected_port := ""


func _ready() -> void:
	name = "CameraStudy"
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	view.core_study = core_study
	hud.core_study = core_study
	add_child(hud)
	hud.viewport.add_child(view)
	if core_study and view.prepared:
		board.core_ports = view.core.ports
		board.set_board("P")
		hud.add_core_markers(view.core.ports)
	view.set_board_target(board.board_id)
	hud.action.connect(act)
	hud.world_input.connect(world_input)
	get_window().close_requested.connect(write_review)
	print("CORE_OUTLINE_READY" if core_study else "CAMERA_STUDY_READY", ": isolated Boot; P/D fixtures; no world save")


func _process(delta: float) -> void:
	if not view.prepared: return
	var axis := Vector2.ZERO
	if get_window().has_focus() and not paused:
		axis = Vector2(float(Input.is_physical_key_pressed(KEY_D)) - float(Input.is_physical_key_pressed(KEY_A)),
			float(Input.is_physical_key_pressed(KEY_S)) - float(Input.is_physical_key_pressed(KEY_W)))
	var yaw := deg_to_rad(float(view.CAMERAS[view.preset].yaw))
	var motion := axis.rotated(-yaw)
	board.move_actor(board.actor, motion.x, motion.y, delta)
	if axis != Vector2.ZERO: input_moves += 1
	view.logical_pixel_scale = float(hud.viewport.size.y) / maxf(hud.image.size.y, 1)
	view.draw_board(board, selected, measuring, cell, direction)
	if Time.get_ticks_msec() > notice_until: notice = ""
	hud.refresh(view, board, selected, measuring, cell, direction, paused, notice, selected_port)


func _unhandled_key_input(event: InputEvent) -> void:
	if not event is InputEventKey or not event.pressed or event.echo: return
	match event.physical_keycode:
		KEY_1: act("camera", 0)
		KEY_2: act("camera", 1)
		KEY_3: act("camera", 2)
		KEY_B: act("measure", null)
		KEY_R: act("rotate", null)
		KEY_F: act("nearest", null)
		KEY_ESCAPE: act("cancel", null)


func act(kind: String, value: Variant) -> void:
	match kind:
		"camera": view.preset = int(value)
		"board":
			board.set_board(str(value))
			view.set_board_target(board.board_id)
			selected = -1
			selected_port = ""
		"span": view.span = clampf(float(value), View.MIN_SPAN, View.MAX_SPAN)
		"follow": view.follow = not view.follow
		"reset":
			board.set_board(board.board_id)
			selected = -1
			selected_port = ""
		"measure": measuring = not measuring
		"rotate": direction = (direction + 1) % 4
		"nearest":
			selected = board.nearest_sample(core_study)
			selected_port = ""
		"grid": view.grid_enabled = not view.grid_enabled
		"ports": hud.ports_visible = not hud.ports_visible
		"pause": paused = not paused
		"tier":
			assert(core_study)
			view.focus_highlight.clear()
			view.core.set_tier(int(value))
		"core_belts":
			assert(core_study)
			board.toggle_core_belts()
		"core_names":
			assert(core_study)
			view.core.toggle_names()
		"core_frame":
			assert(core_study)
			view.core_frame = not view.core_frame
		"approach":
			assert(core_study)
			if board.board_id == "P":
				var points := {"S": Vector2(0, 4.6), "N": Vector2(0, -4.6), "W": Vector2(-4.6, 0), "E": Vector2(4.6, 0)}
				var point: Vector2 = points[str(value)]
				assert(not board.blocked_for_actor(point.x, point.y))
				board.actor.x = point.x
				board.actor.z = point.y
				board.actor.target = null
				selected = -1
				selected_port = ""
		"window":
			get_window().mode = Window.MODE_WINDOWED
			get_window().size = value
		"cancel":
			measuring = false
			selected = -1
			selected_port = ""
		"capture": capture.call_deferred()
		_: push_error("Unknown camera study action: " + kind)
	record(kind, value)


func world_input(event: InputEvent) -> void:
	if event is InputEventMouseMotion or event is InputEventMouseButton:
		var point: Vector2 = hud.world_point(event.position)
		var ground: Variant = view.ground(point)
		if ground != null: cell = Vector2i(floori(ground.x), floori(ground.z))
		if event is InputEventMouseButton and event.pressed:
			match event.button_index:
				MOUSE_BUTTON_WHEEL_UP: act("span", view.span - 1)
				MOUSE_BUTTON_WHEEL_DOWN: act("span", view.span + 1)
				MOUSE_BUTTON_RIGHT: act("cancel", null)
				MOUSE_BUTTON_LEFT:
					if not measuring:
						selected = view.hit(point)
						if not core_study and selected < 0 and ground != null and board.board_id == "P" \
								and board.core_reserved.has_point(Vector2(ground.x, ground.z)): selected = -2
						selected_port = view.core.port_at(view.camera, point, 14 * view.logical_pixel_scale) \
							if core_study and selected == -2 else ""
					record("measure_click" if measuring else "select", [cell.x, cell.y, selected])


func record(kind: String, value: Variant) -> void:
	events.append({"ms": Time.get_ticks_msec(), "kind": kind, "value": value,
		"actor": [board.actor.x, board.actor.z], "board": board.board_id,
		"camera": view.CAMERAS[view.preset].id})
	print("CAMERA_STUDY_ACTION ", JSON.stringify(events.back()))


func state() -> Dictionary:
	var minimum_gap := INF
	for a in hud.marker_points.size():
		for b in range(a + 1, hud.marker_points.size()):
			minimum_gap = minf(minimum_gap, view.project(hud.marker_points[a]).distance_to(view.project(hud.marker_points[b])))
	var snapshot := {"camera": view.camera_state(), "board": board.board_id,
		"actor": [board.actor.x, board.actor.z], "selected": selected, "measuring": measuring,
		"cell": [cell.x, cell.y], "direction": direction, "paused": paused,
		"window": [get_window().size.x, get_window().size.y],
		"image_ui": [hud.image.size.x, hud.image.size.y], "movement_frames": input_moves,
		"port_marker_min_gap_3d_pixels": minimum_gap,
		"port_output_marker_ui_size": 18, "port_icons_are_density_examples": true,
		"renderer": RenderingServer.get_current_rendering_method(),
		"world_saved": false, "events": events}
	if core_study:
		snapshot["core"] = view.core.review(view.camera, board.actor) if board.board_id == "P" \
			else {"model": view.core.MODEL_PATH, "tier": view.core.tier, "probe_scope": "not sampled: core hidden on dense board", "gameplay_connected": false}
		snapshot["core"]["shown_on_board"] = board.board_id == "P"
		snapshot["core"]["belts_connected"] = board.belts_connected
		snapshot["core"]["selected_port"] = selected_port
		snapshot["core"]["frame_visible"] = view.core_frame
	return snapshot


func write_review() -> void:
	if output_root.is_empty(): return
	if DirAccess.make_dir_recursive_absolute(output_root) != OK:
		push_error("Cannot create camera review directory: " + output_root)
		return
	var file := FileAccess.open(output_root.path_join("review.json"), FileAccess.WRITE)
	if file == null:
		push_error("Cannot write camera review: " + str(FileAccess.get_open_error()))
		return
	file.store_string(JSON.stringify(state(), "\t") + "\n")


func capture() -> void:
	if screenshot_root.is_empty():
		push_error("Camera screenshot directory is not configured")
		return
	await RenderingServer.frame_post_draw
	if DirAccess.make_dir_recursive_absolute(screenshot_root) != OK:
		push_error("Cannot create screenshot directory: " + screenshot_root)
		return
	captures += 1
	var path := screenshot_root.path_join("%02d-%s-%s.png" % [captures, board.board_id, view.CAMERAS[view.preset].id])
	var frame := get_viewport().get_texture().get_image()
	var error := frame.save_png(path)
	if error != OK:
		push_error("Cannot capture camera study: " + str(error))
		return
	var metadata := state()
	metadata["rendered_frame"] = [frame.get_width(), frame.get_height()]
	metadata["rendered_3d"] = [hud.viewport.get_texture().get_image().get_width(), hud.viewport.get_texture().get_image().get_height()]
	var sidecar := FileAccess.open(path.get_basename() + ".json", FileAccess.WRITE)
	if sidecar == null:
		push_error("Cannot write screenshot metadata: " + str(FileAccess.get_open_error()))
		return
	sidecar.store_string(JSON.stringify(metadata, "\t") + "\n")
	record("capture", path)
	write_review()
	notice = "截图已保存：" + path.get_file()
	notice_until = Time.get_ticks_msec() + 3000
	print("CAMERA_STUDY_CAPTURE ", path)
