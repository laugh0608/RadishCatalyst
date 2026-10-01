extends Control

const Model := preload("res://production/model.gd")
const View := preload("res://production/view.gd")
const Hud := preload("res://production/hud.gd")
const MOVE_KEYS := {
	KEY_A: Vector2(-1, 0), KEY_LEFT: Vector2(-1, 0),
	KEY_D: Vector2(1, 0), KEY_RIGHT: Vector2(1, 0),
	KEY_W: Vector2(0, -1), KEY_UP: Vector2(0, -1),
	KEY_S: Vector2(0, 1), KEY_DOWN: Vector2(0, 1),
}
var model := Model.new()
var view := View.new()
var hud := Hud.new()
var actor := {"x": -3.5, "z": 5.7, "angle": 0.0, "walk": 0.0, "moving": false, "target": null}
var ui := {"build": true, "tool": "", "cell": Vector2i(-6, 0), "dir": 0, "selected": -1,
	"guides": true, "paused": false, "stroke": Array([], TYPE_VECTOR2I, "", null), "mission": true}
var keys := {}
var pointer := false
var pointer_start := Vector2.ZERO
var focused := true
var ui_elapsed := 0.0
var initialized := false
var frame_samples: Array[float] = []
var simulation_samples: Array[float] = []
var sample_enabled := false
var last_frame_usec := 0


func _ready() -> void:
	get_window().title = "异星催化 · Godot 3D 产线 Demo"
	get_window().content_scale_size = Vector2i(1440, 900)
	get_window().min_size = Vector2i(1100, 720)
	add_child(hud)
	hud.subviewport.add_child(view)
	hud.action.connect(_action)
	get_window().focus_exited.connect(_focus_lost)
	get_window().focus_entered.connect(func(): focused = true)
	get_window().mouse_exited.connect(func(): _stop_pointer())
	hud.announce("从青色矿点开始，选择采集器放下第一台设备。")
	initialized = true
	_refresh()
	view.draw(model, actor, ui)
	if "--verify-resolution" in OS.get_cmdline_user_args():
		var review = load("res://production/verify-resolution.gd").new()
		add_child(review)
		review.call_deferred("run", self)
	elif "--verify-navigation" in OS.get_cmdline_user_args():
		var review = load("res://production/verify-navigation.gd").new()
		add_child(review)
		review.call_deferred("run", self)
	elif "--verify-production" in OS.get_cmdline_user_args():
		var review = load("res://production/verify-window.gd").new()
		add_child(review)
		review.call_deferred("run", self)


func _process(delta: float) -> void:
	if not initialized:
		return
	var frame_usec := Time.get_ticks_usec()
	var frame_interval_ms := (frame_usec - last_frame_usec) / 1000.0 if last_frame_usec > 0 else 0.0
	last_frame_usec = frame_usec
	var dt := minf(delta, 0.1)
	if focused and not hud.restart.visible:
		if not ui.paused:
			var before := Time.get_ticks_usec()
			model.advance(dt)
			if sample_enabled:
				simulation_samples.append((Time.get_ticks_usec() - before) / 1000.0)
		_movement(minf(dt, 0.06))
	else:
		actor.moving = false
	if sample_enabled and focused:
		frame_samples.append(frame_interval_ms)
	ui_elapsed += delta
	if ui_elapsed >= 0.12:
		_refresh()
		ui_elapsed = 0
	view.draw(model, actor, ui)


func _movement(dt: float) -> void:
	var input := Vector2.ZERO
	for key in keys:
		input += MOVE_KEYS[key]
	var angle := deg_to_rad(view.yaw)
	var direction := Vector2(input.x * cos(angle) + input.y * sin(angle), -input.x * sin(angle) + input.y * cos(angle))
	if input != Vector2.ZERO:
		actor.target = null
	elif actor.target != null:
		direction = actor.target - Vector2(actor.x, actor.z)
		if direction.length() < 0.07:
			actor.target = null
			direction = Vector2.ZERO
	model.move_actor(actor, direction.x, direction.y, dt)
	if actor.target != null and not actor.moving:
		actor.target = null


func _focus_lost() -> void:
	focused = false
	_stop_pointer()
	keys.clear()
	actor.target = null


func _refresh() -> void:
	hud.refresh(model, actor, ui, focused)


func _stop_pointer() -> void:
	pointer = false
	ui.stroke.clear()


func _choose(type: String) -> void:
	_stop_pointer()
	ui.build = true
	ui.tool = type
	ui.selected = -1
	ui.cell = Model.REFERENCE[type]
	actor.target = null
	hud.announce("按住拖动铺带，松开确认；R 转向，Esc 取消。" if type == "belt" else "移动鼠标选择落位，点击放置；也可在下方 X / Z 精确调整。")


func _commit() -> void:
	if ui.tool.is_empty():
		return
	var result := model.place(ui.tool, ui.cell, ui.dir, actor)
	if not result.ok:
		hud.announce(result.reason, true)
		return
	var e: Dictionary = result.entity
	hud.announce(Model.CATALOG[e.type].name + "已放置。")
	if e.type == "belt":
		ui.cell = Vector2i(e.x, e.z) + Model.DIRS[ui.dir]
	else:
		ui.tool = ""
		ui.selected = e.id


func _cancel() -> void:
	if pointer:
		_stop_pointer()
		hud.announce("已取消本次拖动铺带。")
	elif not ui.tool.is_empty():
		ui.tool = ""
		hud.announce("已取消放置。")
	elif ui.selected != -1:
		ui.selected = -1
	elif ui.build:
		ui.build = false
		hud.announce("观察模式：点击地面移动，点击设备查看。")


func _turn() -> void:
	if ui.tool == "belt":
		ui.dir = (ui.dir + 1) % 4
	elif ui.selected != -1:
		var result := model.rotate(ui.selected)
		hud.announce("传送带已转向。" if result.ok else result.reason, not result.ok)


func _action(name: String, value: Variant) -> void:
	if name in ["collector", "reactor", "storage", "belt"]:
		_choose(name)
	else:
		match name:
			"build":
				_stop_pointer()
				ui.build = not ui.build
				ui.tool = ""
			"place": _commit()
			"cancel": _cancel()
			"rotate", "rotate_selected": _turn()
			"close_inspector": ui.selected = -1
			"cell_x": ui.cell.x = value
			"cell_z": ui.cell.y = value
			"guides": ui.guides = not ui.guides
			"mission": ui.mission = not ui.mission
			"pause": ui.paused = not ui.paused
			"help": hud.help_panel.visible = not hud.help_panel.visible
			"restart":
				_stop_pointer()
				keys.clear()
				hud.restart.popup_centered(Vector2i(440, 180))
			"restart_confirmed":
				_stop_pointer()
				model = Model.new()
				actor = {"x": -3.5, "z": 5.7, "angle": 0.0, "walk": 0.0, "moving": false, "target": null}
				ui.merge({"build": true, "tool": "", "selected": -1, "paused": false}, true)
				keys.clear()
				view.invalidate()
				hud.announce("新厂坪已准备好。")
			"salvage":
				var result := model.salvage(ui.selected)
				if result.ok:
					ui.selected = -1
					hud.announce("已回收%s、%d 晶体、%d 催化剂。" % [Model.CATALOG[result.type].name, result.items.crystal, result.items.catalyst])
				else:
					hud.announce(result.reason, true)
			"deposit":
				var result := model.deposit(ui.selected)
				hud.announce("已投入 %d 件回收物品。" % result.amount if result.ok else result.reason, not result.ok)
			"camera_left": view.yaw -= 15
			"camera_right": view.yaw += 15
			"zoom_out": view.zoom = maxf(0.8, view.zoom - 0.1)
			"zoom_in": view.zoom = minf(1.5, view.zoom + 0.1)
	view.sync_camera()
	_refresh()


func _preview(cell: Vector2i) -> void:
	var result := model.extend_path(ui.stroke, cell)
	ui.stroke = result.path
	hud.announce("预览 %d 段 · 松开铺设，回拖缩短，Esc 取消" % ui.stroke.size() if result.ok else result.reason, not result.ok)


func _input(event: InputEvent) -> void:
	if not initialized:
		return
	if event is InputEventKey:
		if not event.pressed:
			keys.erase(event.physical_keycode)
		return
	if not event is InputEventMouse:
		return
	var screen = hud.world_point(event.position)
	if screen == null:
		if pointer:
			_stop_pointer()
			hud.announce("已离开场地，本次铺带预览已取消。")
		return
	var point = view.ground(screen)
	if point == null:
		return
	var cell := Vector2i(floori(point.x), floori(point.z))
	if event is InputEventMouseMotion:
		if not ui.tool.is_empty():
			ui.cell = cell
			if pointer and ui.tool == "belt":
				if not event.button_mask & MOUSE_BUTTON_MASK_LEFT:
					_stop_pointer()
				else:
					_preview(cell)
			_refresh()
	elif event is InputEventMouseButton:
		if event.button_index in [MOUSE_BUTTON_WHEEL_UP, MOUSE_BUTTON_WHEEL_DOWN] and event.pressed:
			_action("zoom_in" if event.button_index == MOUSE_BUTTON_WHEEL_UP else "zoom_out", null)
			return
		if event.button_index != MOUSE_BUTTON_LEFT:
			return
		if event.pressed:
			# Release precision-field focus so movement/shortcuts work from the field.
			var owner := get_viewport().gui_get_focus_owner()
			if owner:
				owner.release_focus()
			pointer = true
			pointer_start = event.position
			actor.target = null
			if ui.tool == "belt":
				ui.cell = cell
				ui.stroke.clear()
				_preview(cell)
		elif pointer:
			if ui.tool == "belt":
				var path: Array[Vector2i] = ui.stroke.duplicate()
				_stop_pointer()
				var result := model.place_path(path, ui.dir)
				hud.announce("已铺设 %d 段传送带。" % result.entities.size() if result.ok else result.reason, not result.ok)
			else:
				_stop_pointer()
				if pointer_start.distance_to(event.position) > 8:
					return
				if not ui.tool.is_empty():
					ui.cell = cell
					_commit()
				else:
					var id := view.hit(screen)
					var e := model.entity_at(cell)
					ui.selected = id if id != -1 else e.get("id", -1)
					if ui.selected == -1:
						actor.target = Vector2(point.x, point.z)
		_refresh()


func _unhandled_key_input(event: InputEvent) -> void:
	if not event is InputEventKey or not event.pressed or event.echo or hud.restart.visible:
		return
	if event.physical_keycode == KEY_ESCAPE:
		_cancel()
		_refresh()
		return
	if MOVE_KEYS.has(event.physical_keycode):
		keys[event.physical_keycode] = true
		return
	if pointer:
		return
	match event.physical_keycode:
		KEY_1: _action("collector", null)
		KEY_2: _action("reactor", null)
		KEY_3: _action("storage", null)
		KEY_4: _action("belt", null)
		KEY_B: _action("build", null)
		KEY_R: _action("rotate", null)
		KEY_Q: _action("camera_left", null)
		KEY_E: _action("camera_right", null)
		KEY_ENTER: _action("place", null)
