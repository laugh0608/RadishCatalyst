class_name SlicePairedContainerView
extends VBoxContainer

## Shared session-only presentation and direct-manipulation surface for two
## authoritative containers. It never mutates inventories: callers provide a
## read model and handle transfer_requested through their existing world APIs.

signal transfer_requested(item_id: String, source: String, requested: int)
signal feedback_changed(message: String, warning: bool)

const FILTER_ALL := "all"
const COLOR_TEXT := Color(0.863, 0.886, 0.878)
const COLOR_MUTED := Color(0.537, 0.576, 0.588)
const COLOR_ACCENT := Color(0.498, 0.573, 0.722)
const COLOR_WARNING := Color(0.83, 0.59, 0.28)
const DRAG_START_DISTANCE := 6.0

@export var compact := false

class ItemSlot:
	extends Button

	signal drag_started(
		item_id: String,
		display_name: String,
		source: String,
		item_count: int,
		control_pressed: bool
	)

	var item_id := ""
	var display_name := ""
	var source := ""
	var item_count := 0


	func configure(item: Dictionary, source_id: String, count: int) -> void:
		item_id = String(item["item_id"])
		display_name = String(item["display_name"])
		source = source_id
		item_count = count


	func _gui_input(event: InputEvent) -> void:
		if not (event is InputEventMouseButton):
			return
		var mouse_event := event as InputEventMouseButton
		if (
			mouse_event.pressed
			and mouse_event.button_index == MOUSE_BUTTON_LEFT
			and item_count > 0
		):
			drag_started.emit(
				item_id,
				display_name,
				source,
				item_count,
				mouse_event.ctrl_pressed
			)


var _snapshot: Dictionary = {}
var _filter_id := FILTER_ALL
var _selected_item_id := ""
var _selected_source := ""
var _selected_amount := 0
var _left_slots: Dictionary = {}
var _right_slots: Dictionary = {}
var _filter_buttons: Dictionary = {}
var _left_panel: PanelContainer
var _right_panel: PanelContainer
var _left_title: Label
var _right_title: Label
var _left_summary: Label
var _right_summary: Label
var _left_grid: GridContainer
var _right_grid: GridContainer
var _left_empty: Label
var _right_empty: Label
var _action_button: Button
var _selection_text: Label
var _result_text: Label
var _filter_row: HBoxContainer
var _drag_pending := false
var _drag_active := false
var _drag_origin := Vector2.ZERO
var _drag_preview: PanelContainer
var _drag_preview_label: Label


func _ready() -> void:
	_build_surface()
	set_process(false)
	set_process_input(true)


func set_snapshot(snapshot: Dictionary) -> void:
	_snapshot = snapshot.duplicate(true)
	var available_filters := available_filter_ids()
	if not available_filters.has(_filter_id):
		_filter_id = FILTER_ALL
	if not _selection_still_available():
		clear_selection()
	_rebuild_filters()
	_rebuild_items()
	_update_header()
	_update_action()


func snapshot() -> Dictionary:
	return _snapshot.duplicate(true)


func set_result(message: String, warning: bool = false) -> void:
	_result_text.text = message
	_result_text.add_theme_color_override(
		"font_color", COLOR_WARNING if warning else COLOR_TEXT
	)
	feedback_changed.emit(message, warning)


func reset_result() -> void:
	_result_text.text = (
		"只显示实际持有物 · Ctrl / Control 逐次减半 · Enter / Space 转移"
	)
	_result_text.add_theme_color_override("font_color", COLOR_TEXT)


func result_text() -> String:
	return _result_text.text


func filter_id() -> String:
	return _filter_id


func set_filter(next_filter_id: String) -> void:
	if not available_filter_ids().has(next_filter_id):
		return
	_filter_id = next_filter_id
	_rebuild_filters()
	_rebuild_items()


func available_filter_ids() -> Array[String]:
	var result: Array[String] = [FILTER_ALL]
	for item_variant in _snapshot.get("items", []):
		var item: Dictionary = item_variant
		var category := String(item.get("category", ""))
		if not category.is_empty() and not result.has(category):
			result.append(category)
	return result


func visible_item_ids(source: String) -> Array[String]:
	var result: Array[String] = []
	var count_key := _count_key(source)
	if count_key.is_empty():
		return result
	for item_variant in _filtered_items():
		var item: Dictionary = item_variant
		if int(item.get(count_key, 0)) > 0:
			result.append(String(item["item_id"]))
	return result


func item_row_count() -> int:
	return (_snapshot.get("items", []) as Array).size()


func slot(source: String, item_id: String) -> ItemSlot:
	if source == String(_snapshot.get("left_source", "left")):
		return _left_slots.get(item_id) as ItemSlot
	if source == String(_snapshot.get("right_source", "right")):
		return _right_slots.get(item_id) as ItemSlot
	return null


func select_item(item_id: String, source: String, split_half := false) -> bool:
	var item := _find_item(item_id)
	var count_key := _count_key(source)
	if item.is_empty() or count_key.is_empty():
		return false
	var available := int(item.get(count_key, 0))
	if available <= 0:
		return false
	_selected_item_id = item_id
	_selected_source = source
	_selected_amount = (
		ceili(float(available) / 2.0)
		if split_half and not bool(item.get("fixed_request", false))
		else available
	)
	_update_slot_selection()
	_update_action()
	return true


func selected_amount() -> int:
	return _selected_amount


func selected_item_id() -> String:
	return _selected_item_id


func selected_source() -> String:
	return _selected_source


func halve_selection() -> void:
	if _selected_amount <= 0:
		return
	if bool(_find_item(_selected_item_id).get("fixed_request", false)):
		return
	_selected_amount = ceili(float(_selected_amount) / 2.0)
	_update_action()
	_update_drag_preview()


func clear_selection() -> void:
	_selected_item_id = ""
	_selected_source = ""
	_selected_amount = 0
	_update_slot_selection()
	_update_action()


func request_selected_transfer() -> bool:
	if _selected_item_id.is_empty() or _selected_amount <= 0:
		set_result("请先选择持有物", true)
		return false
	var item := _find_item(_selected_item_id)
	var reason := _transfer_reason(item, _selected_source)
	if not reason.is_empty():
		set_result(reason, true)
		return false
	transfer_requested.emit(
		_selected_item_id, _selected_source, _selected_amount
	)
	return true


func cancel_interaction() -> void:
	_clear_drag()
	clear_selection()
	set_result("已取消，物品未移动")


func drag_is_pending() -> bool:
	return _drag_pending


func _input(event: InputEvent) -> void:
	if not is_visible_in_tree():
		return
	if event is InputEventKey:
		var key_event := event as InputEventKey
		if not key_event.pressed or key_event.echo:
			return
		if (
			key_event.keycode == KEY_CTRL
			or key_event.physical_keycode == KEY_CTRL
		):
			halve_selection()
		elif key_event.keycode in [KEY_ENTER, KEY_KP_ENTER, KEY_SPACE]:
			request_selected_transfer()
		elif key_event.keycode == KEY_ESCAPE and (_drag_pending or _drag_active):
			cancel_interaction()
		return
	if not (event is InputEventMouseButton):
		return
	var mouse_event := event as InputEventMouseButton
	if (
		mouse_event.pressed
		and mouse_event.button_index == MOUSE_BUTTON_RIGHT
		and (
			_drag_pending
			or _drag_active
			or not _selected_item_id.is_empty()
		)
	):
		cancel_interaction()
		return
	if (
		not mouse_event.pressed
		and mouse_event.button_index == MOUSE_BUTTON_LEFT
		and (_drag_pending or _drag_active)
	):
		_finish_drag(get_viewport().get_mouse_position())


func _process(_delta: float) -> void:
	var mouse_position := get_viewport().get_mouse_position()
	if (
		_drag_pending
		and mouse_position.distance_to(_drag_origin) >= DRAG_START_DISTANCE
	):
		_activate_drag()
	if _drag_active:
		_drag_preview.position = mouse_position + Vector2(18, 18)


func _build_surface() -> void:
	add_theme_constant_override("separation", 7)
	_filter_row = HBoxContainer.new()
	_filter_row.name = "Filters"
	_filter_row.add_theme_constant_override("separation", 6)
	add_child(_filter_row)

	var body := HBoxContainer.new()
	body.name = "ContainerPair"
	body.size_flags_vertical = Control.SIZE_EXPAND_FILL
	body.add_theme_constant_override("separation", 7)
	add_child(body)

	var left := _create_side("Left")
	_left_panel = left["panel"]
	_left_title = left["title"]
	_left_summary = left["summary"]
	_left_grid = left["grid"]
	_left_empty = left["empty"]
	body.add_child(_left_panel)

	var guide := VBoxContainer.new()
	guide.custom_minimum_size = Vector2(44 if compact else 70, 0)
	guide.alignment = BoxContainer.ALIGNMENT_CENTER
	var to_right := Label.new()
	to_right.text = "→"
	to_right.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	to_right.add_theme_color_override("font_color", COLOR_ACCENT)
	to_right.add_theme_font_size_override("font_size", 20)
	guide.add_child(to_right)
	var to_left := Label.new()
	to_left.text = "←"
	to_left.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	to_left.add_theme_color_override("font_color", COLOR_ACCENT)
	to_left.add_theme_font_size_override("font_size", 20)
	guide.add_child(to_left)
	body.add_child(guide)

	var right := _create_side("Right")
	_right_panel = right["panel"]
	_right_title = right["title"]
	_right_summary = right["summary"]
	_right_grid = right["grid"]
	_right_empty = right["empty"]
	body.add_child(_right_panel)

	var action_row := HBoxContainer.new()
	action_row.name = "SelectedAction"
	action_row.add_theme_constant_override("separation", 8)
	add_child(action_row)
	_selection_text = Label.new()
	_selection_text.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_selection_text.add_theme_color_override("font_color", COLOR_MUTED)
	_selection_text.add_theme_font_size_override("font_size", 13 if compact else 14)
	_selection_text.text = "点击物品格选择；拖拽为主路径"
	action_row.add_child(_selection_text)
	_action_button = Button.new()
	_action_button.custom_minimum_size = Vector2(164 if compact else 220, 42)
	_action_button.text = "选择后转移"
	_action_button.disabled = true
	_action_button.pressed.connect(request_selected_transfer)
	action_row.add_child(_action_button)

	_result_text = Label.new()
	_result_text.name = "Result"
	_result_text.add_theme_color_override("font_color", COLOR_TEXT)
	_result_text.add_theme_font_size_override("font_size", 13 if compact else 14)
	_result_text.text = "只显示实际持有物 · Ctrl / Control 逐次减半 · Enter / Space 转移"
	_result_text.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_result_text.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	add_child(_result_text)


func _create_side(side_name: String) -> Dictionary:
	var panel := PanelContainer.new()
	panel.name = side_name
	panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	panel.size_flags_vertical = Control.SIZE_EXPAND_FILL
	panel.custom_minimum_size = Vector2(190 if compact else 360, 250)
	var margin := MarginContainer.new()
	margin.add_theme_constant_override("margin_left", 9)
	margin.add_theme_constant_override("margin_top", 7)
	margin.add_theme_constant_override("margin_right", 9)
	margin.add_theme_constant_override("margin_bottom", 7)
	panel.add_child(margin)
	var layout := VBoxContainer.new()
	layout.add_theme_constant_override("separation", 6)
	margin.add_child(layout)
	var header := HBoxContainer.new()
	layout.add_child(header)
	var title := Label.new()
	title.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	title.add_theme_color_override("font_color", COLOR_TEXT)
	title.add_theme_font_size_override("font_size", 16 if compact else 19)
	header.add_child(title)
	var summary := Label.new()
	summary.add_theme_color_override("font_color", COLOR_MUTED)
	summary.add_theme_font_size_override("font_size", 12 if compact else 13)
	summary.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	header.add_child(summary)
	var scroll := ScrollContainer.new()
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	layout.add_child(scroll)
	var stack := VBoxContainer.new()
	stack.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	stack.add_theme_constant_override("separation", 6)
	scroll.add_child(stack)
	var empty := Label.new()
	empty.add_theme_color_override("font_color", COLOR_MUTED)
	empty.add_theme_font_size_override("font_size", 14)
	empty.text = "容器为空"
	empty.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	empty.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	empty.custom_minimum_size = Vector2(0, 100)
	stack.add_child(empty)
	var grid := GridContainer.new()
	grid.columns = 1 if compact else 2
	grid.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	grid.add_theme_constant_override("h_separation", 6)
	grid.add_theme_constant_override("v_separation", 6)
	stack.add_child(grid)
	return {
		"panel": panel,
		"title": title,
		"summary": summary,
		"grid": grid,
		"empty": empty,
	}


func _update_header() -> void:
	_left_title.text = String(_snapshot.get("left_title", "随身背包"))
	_right_title.text = String(_snapshot.get("right_title", "目标容器"))
	_left_summary.text = String(_snapshot.get("left_summary", ""))
	_right_summary.text = String(_snapshot.get("right_summary", ""))


func _rebuild_filters() -> void:
	for child in _filter_row.get_children():
		_filter_row.remove_child(child)
		child.queue_free()
	_filter_buttons.clear()
	for category_id in available_filter_ids():
		var button := Button.new()
		button.toggle_mode = true
		button.button_pressed = category_id == _filter_id
		button.text = (
			"全部"
			if category_id == FILTER_ALL
			else SliceItemCatalog.category_title(category_id)
		)
		button.pressed.connect(set_filter.bind(category_id))
		_filter_row.add_child(button)
		_filter_buttons[category_id] = button


func _rebuild_items() -> void:
	_rebuild_side(
		_left_grid,
		_left_empty,
		_left_slots,
		String(_snapshot.get("left_source", "left")),
		"left_count",
		"left_capacity"
	)
	_rebuild_side(
		_right_grid,
		_right_empty,
		_right_slots,
		String(_snapshot.get("right_source", "right")),
		"right_count",
		"right_capacity"
	)
	_update_slot_selection()


func _rebuild_side(
	grid: GridContainer,
	empty: Label,
	slots: Dictionary,
	source: String,
	count_key: String,
	capacity_key: String
) -> void:
	for child in grid.get_children():
		grid.remove_child(child)
		child.queue_free()
	slots.clear()
	for item_variant in _filtered_items():
		var item: Dictionary = item_variant
		var count := int(item.get(count_key, 0))
		if count <= 0:
			continue
		var slot := ItemSlot.new()
		slot.custom_minimum_size = Vector2(154 if compact else 220, 64)
		slot.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		slot.alignment = HORIZONTAL_ALIGNMENT_LEFT
		slot.focus_mode = Control.FOCUS_ALL
		slot.add_theme_font_size_override("font_size", 13 if compact else 14)
		slot.text = "%s\n%d / %d" % [
			String(item["display_name"]),
			count,
			int(item.get(capacity_key, count)),
		]
		slot.icon = _read_model_icon(item)
		slot.expand_icon = true
		slot.tooltip_text = "点击选择，或拖到另一栏"
		slot.configure(item, source, count)
		slot.pressed.connect(select_item.bind(String(item["item_id"]), source, false))
		slot.drag_started.connect(_on_slot_drag_started)
		grid.add_child(slot)
		slots[String(item["item_id"])] = slot
	empty.visible = slots.is_empty()
	empty.text = "当前分类没有持有物" if _filter_id != FILTER_ALL else "容器为空"


func _on_slot_drag_started(
	item_id: String,
	display_name: String,
	source: String,
	_available: int,
	control_pressed: bool
) -> void:
	if not select_item(item_id, source, control_pressed):
		return
	_drag_pending = true
	_drag_active = false
	_drag_origin = get_viewport().get_mouse_position()
	set_process(true)
	set_meta("drag_display_name", display_name)


func _activate_drag() -> void:
	_drag_pending = false
	_drag_active = true
	_drag_preview = PanelContainer.new()
	_drag_preview.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_drag_preview.z_index = 40
	var style := StyleBoxFlat.new()
	style.bg_color = Color(0.055, 0.075, 0.09, 0.96)
	style.border_color = COLOR_ACCENT
	style.set_border_width_all(2)
	style.set_corner_radius_all(4)
	style.set_content_margin_all(8)
	_drag_preview.add_theme_stylebox_override("panel", style)
	_drag_preview_label = Label.new()
	_drag_preview_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_drag_preview_label.add_theme_color_override("font_color", COLOR_TEXT)
	_drag_preview_label.add_theme_font_size_override("font_size", 15)
	_drag_preview.add_child(_drag_preview_label)
	add_child(_drag_preview)
	_update_drag_preview()


func _finish_drag(mouse_position: Vector2) -> void:
	if not _drag_active:
		_clear_drag()
		return
	var target_source := _source_at(mouse_position)
	var source := _selected_source
	_clear_drag()
	if target_source.is_empty() or target_source == source:
		set_result("未放入目标栏，物品未移动")
		return
	request_selected_transfer()


func _source_at(mouse_position: Vector2) -> String:
	if _left_panel.get_global_rect().has_point(mouse_position):
		return String(_snapshot.get("left_source", "left"))
	if _right_panel.get_global_rect().has_point(mouse_position):
		return String(_snapshot.get("right_source", "right"))
	return ""


func _clear_drag() -> void:
	if _drag_preview != null:
		_drag_preview.queue_free()
	_drag_preview = null
	_drag_preview_label = null
	_drag_pending = false
	_drag_active = false
	set_process(false)


func _update_drag_preview() -> void:
	if _drag_preview_label == null:
		return
	_drag_preview_label.text = "%s × %d" % [
		String(get_meta("drag_display_name", _selected_item_id)),
		_selected_amount,
	]


func _update_slot_selection() -> void:
	for source_slots in [_left_slots, _right_slots]:
		for slot_variant in source_slots.values():
			var item_slot := slot_variant as ItemSlot
			item_slot.button_pressed = (
				item_slot.item_id == _selected_item_id
				and item_slot.source == _selected_source
			)


func _update_action() -> void:
	if _action_button == null:
		return
	if _selected_item_id.is_empty():
		_selection_text.text = "点击物品格选择；拖拽为主路径"
		_action_button.text = "选择后转移"
		_action_button.disabled = true
		return
	var item := _find_item(_selected_item_id)
	var display_name := String(item.get("display_name", _selected_item_id))
	var left_source := String(_snapshot.get("left_source", "left"))
	var is_left := _selected_source == left_source
	var custom_label_key := (
		"left_action_label" if is_left else "right_action_label"
	)
	var default_label := "→ 转移选中" if is_left else "← 转移选中"
	var reason := _transfer_reason(item, _selected_source)
	_selection_text.text = "%s × %d" % [display_name, _selected_amount]
	_action_button.text = String(_snapshot.get(custom_label_key, default_label))
	_action_button.disabled = not reason.is_empty()
	_action_button.tooltip_text = reason


func _selection_still_available() -> bool:
	if _selected_item_id.is_empty():
		return true
	var item := _find_item(_selected_item_id)
	var count_key := _count_key(_selected_source)
	return not item.is_empty() and int(item.get(count_key, 0)) > 0


func _filtered_items() -> Array[Dictionary]:
	var result: Array[Dictionary] = []
	for item_variant in _snapshot.get("items", []):
		var item: Dictionary = item_variant
		if (
			_filter_id == FILTER_ALL
			or String(item.get("category", "")) == _filter_id
		):
			result.append(item)
	return result


func _find_item(item_id: String) -> Dictionary:
	for item_variant in _snapshot.get("items", []):
		var item: Dictionary = item_variant
		if String(item.get("item_id", "")) == item_id:
			return item
	return {}


func _count_key(source: String) -> String:
	if source == String(_snapshot.get("left_source", "left")):
		return "left_count"
	if source == String(_snapshot.get("right_source", "right")):
		return "right_count"
	return ""


func _transfer_reason(item: Dictionary, source: String) -> String:
	if item.is_empty():
		return "物品已不存在"
	var left_source := String(_snapshot.get("left_source", "left"))
	var direction := "left_to_right" if source == left_source else "right_to_left"
	if not bool(item.get(direction, true)):
		return String(item.get("%s_reason" % direction, "该方向不可转移"))
	return ""


func _read_model_icon(item: Dictionary) -> Texture2D:
	var icon_path := String(item.get("icon_path", ""))
	if icon_path.is_empty():
		return null
	var texture := load(icon_path) as Texture2D
	var icon_region: Rect2 = item.get("icon_region", Rect2())
	if icon_region.has_area():
		var atlas := AtlasTexture.new()
		atlas.atlas = texture
		atlas.region = icon_region
		return atlas
	return texture
