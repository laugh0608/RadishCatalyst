extends Control

signal return_requested
signal load_failed(reason: String)

const Model := preload("res://scripts/factory/model.gd")
const View := preload("res://scripts/factory/view.gd")
const Hud := preload("res://scripts/factory/hud.gd")
const ActiveClock := preload("res://scripts/factory/active_clock.gd")
const MOVE_KEYS := {
	KEY_A: Vector2(-1, 0), KEY_LEFT: Vector2(-1, 0),
	KEY_D: Vector2(1, 0), KEY_RIGHT: Vector2(1, 0),
	KEY_W: Vector2(0, -1), KEY_UP: Vector2(0, -1),
	KEY_S: Vector2(0, 1), KEY_DOWN: Vector2(0, 1),
}
var model := Model.new()
var view := View.new()
var hud := Hud.new()
var actor: Dictionary
var store: RefCounted
var candidate := {}
var dirty := false
var dirty_elapsed := 0.0
var saved_active_usec := 0
var saved_revision := 0
var save_failed := false
var exit_intent := ""
var failure_dialog := ConfirmationDialog.new()
var unsaved_dialog := ConfirmationDialog.new()
var original_content_size := Vector2i.ZERO
var original_min_size := Vector2i.ZERO
var ui := {"build": true, "tool": "", "cell": Vector2i(-6, 0), "dir": 0, "selected": -1,
	"paused": false, "stroke": Array([], TYPE_VECTOR2I, "", null), "mission": true}
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
var production_clock := ActiveClock.new()
var engine_active_seconds := 0.0
var save_samples: Array[Dictionary] = []


func _ready() -> void:
	get_window().title = "异星催化 · 工厂世界"
	original_content_size = get_window().content_scale_size
	original_min_size = get_window().min_size
	actor = model.actor
	get_tree().auto_accept_quit = false
	get_window().content_scale_size = Vector2i(1440, 900)
	get_window().min_size = Vector2i(1100, 720)
	add_child(hud)
	hud.subviewport.add_child(view)
	if not view.prepared:
		load_failed.emit(view.resource_error if not view.resource_error.is_empty() else "工厂视图未能完整重建。")
		return
	hud.action.connect(_action)
	get_window().focus_exited.connect(_focus_lost)
	get_window().focus_entered.connect(_focus_gained)
	get_window().mouse_exited.connect(func(): _stop_pointer())
	hud.announce("从青色矿点开始，选择采集器放下第一台设备。")
	_refresh()
	view.draw(model, actor, ui)
	_build_save_dialogs()
	if not candidate.is_empty():
		var accepted: Dictionary = store.accept(candidate)
		if not accepted.ok:
			initialized = false
			load_failed.emit(accepted.reason)
			return
		if accepted.has("recovered_from"):
			hud.announce("已从备份恢复：" + accepted.recovered_from.get_file())
	if store != null and not store.last_warning.is_empty():
		hud.announce(store.last_warning)
	saved_revision = model.revision
	initialized = true
	focused = get_window().has_focus()
	production_clock.start(Time.get_ticks_usec(), _producing())
	last_frame_usec = production_clock.last_usec


func _process(delta: float) -> void:
	if not initialized:
		return
	var frame_usec := Time.get_ticks_usec()
	var frame_interval_ms := (frame_usec - last_frame_usec) / 1000.0 if last_frame_usec > 0 else 0.0
	last_frame_usec = frame_usec
	_capture_active_time(frame_usec)
	var dt := delta
	if focused and not failure_dialog.visible and not unsaved_dialog.visible:
		if not ui.paused:
			var before := Time.get_ticks_usec()
			engine_active_seconds += delta
			model.advance(0, 8)
			if sample_enabled:
				simulation_samples.append((Time.get_ticks_usec() - before) / 1000.0)
			_movement(minf(dt, 0.06))
		else:
			actor.moving = false
	else:
		actor.moving = false
	if sample_enabled and focused:
		frame_samples.append(frame_interval_ms)
	_tick_save(frame_interval_ms / 1000.0)
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
	_capture_active_time()
	_stop_pointer()
	keys.clear()
	actor.target = null


func _focus_gained() -> void:
	focused = true
	_capture_active_time()


func _producing() -> bool:
	return initialized and focused and not ui.paused and not failure_dialog.visible and not unsaved_dialog.visible


func _capture_active_time(now_usec: int = -1) -> void:
	if not initialized:
		return
	production_clock.sample(Time.get_ticks_usec() if now_usec < 0 else now_usec, _producing())
	# 状态切换 / 保存时只归集余量；固定步仍在活动帧按预算处理。
	model.advance(production_clock.consume(), 0)


func _set_paused(paused: bool) -> void:
	ui.paused = paused
	_capture_active_time()
	if paused:
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
			"mission": ui.mission = not ui.mission
			"pause": _set_paused(not ui.paused)
			"help": hud.help_panel.visible = not hud.help_panel.visible
			"save": _save_now()
			"return": _request_exit("return")
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
			"zoom_out": view.zoom = maxf(0.45, view.zoom - 0.1)
			"zoom_in": view.zoom = minf(1.5, view.zoom + 0.1)
	view.sync_camera()
	_refresh()


func _preview(cell: Vector2i) -> void:
	var result := model.extend_path(ui.stroke, cell)
	ui.stroke = result.path
	hud.announce("预览 %d 段 · 松开铺设，回拖缩短，Esc 取消" % ui.stroke.size() if result.ok else result.reason, not result.ok)


func _input(event: InputEvent) -> void:
	if not initialized or failure_dialog.visible or unsaved_dialog.visible:
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
	if not event is InputEventKey or not event.pressed or event.echo or failure_dialog.visible or unsaved_dialog.visible:
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


func _build_save_dialogs() -> void:
	failure_dialog.title = "保存未完成"
	failure_dialog.ok_button_text = "重试保存"
	failure_dialog.cancel_button_text = "取消退出 / 留在世界"
	failure_dialog.confirmed.connect(_retry_save)
	failure_dialog.canceled.connect(func(): exit_intent = "")
	failure_dialog.add_button("不保存退出…", true, "discard")
	failure_dialog.custom_action.connect(func(_name): unsaved_dialog.popup_centered(Vector2i(480, 180)))
	add_child(failure_dialog)
	unsaved_dialog.title = "确认放弃未保存进度"
	unsaved_dialog.dialog_text = "本次未保存的改动将丢失。确认退出？"
	unsaved_dialog.ok_button_text = "确认不保存退出"
	unsaved_dialog.cancel_button_text = "返回"
	unsaved_dialog.confirmed.connect(func(): _finish_exit())
	# 二次确认属于失败对话框，避免两个独占弹窗同时竞争根窗口。
	failure_dialog.add_child(unsaved_dialog)


func _tick_save(delta: float) -> void:
	if store == null or not initialized:
		return
	if model.revision != saved_revision or actor.moving:
		dirty = true
	var periodic_elapsed := (production_clock.active_usec - saved_active_usec) / 1000000.0
	if dirty:
		dirty_elapsed += delta
	if not save_failed and (dirty_elapsed >= 2.0 or periodic_elapsed >= 30.0):
		_save_now()


func _save_now() -> bool:
	if store == null:
		return false
	_capture_active_time()
	var save_begin := Time.get_ticks_usec()
	var result: Dictionary = store.save(model)
	if sample_enabled:
		save_samples.append({"at_usec": save_begin, "duration_ms": (Time.get_ticks_usec() - save_begin) / 1000.0, "ok": result.ok})
	if not result.ok:
		save_failed = true
		dirty = true
		_set_paused(true)
		failure_dialog.dialog_text = result.reason + "\n当前进度仍保留在内存，可重试保存。"
		failure_dialog.popup_centered(Vector2i(550, 220))
		hud.announce(result.reason, true)
		return false
	save_failed = false
	dirty = false
	dirty_elapsed = 0
	saved_active_usec = production_clock.active_usec
	saved_revision = model.revision
	hud.announce("已保存 · " + store.world_name if result.warning.is_empty() else result.warning)
	return true


func _request_exit(intent: String) -> void:
	exit_intent = intent
	_set_paused(true)
	if _save_now():
		_finish_exit()


func _retry_save() -> void:
	if _save_now() and not exit_intent.is_empty():
		_finish_exit()


func _finish_exit() -> void:
	var result: Dictionary = store.release()
	if not result.ok:
		hud.announce(result.reason, true)
		return
	initialized = false
	if exit_intent == "quit":
		get_tree().quit()
	else:
		return_requested.emit()


func _notification(what: int) -> void:
	if what == NOTIFICATION_WM_CLOSE_REQUEST and initialized:
		_request_exit("quit")


func _exit_tree() -> void:
	keys.clear()
	if store != null:
		store.release()
	get_window().content_scale_size = original_content_size
	get_window().min_size = original_min_size
	get_tree().auto_accept_quit = true
