class_name SliceCoreStoragePanel
extends CanvasLayer

## Two-column drag-and-drop surface for the authoritative pocket/core pair.
## The panel decides only the requested amount; SliceWorld and Inventory still
## own lossless capacity-limited transfer, signals, autosave, and persistence.

const SOURCE_POCKET := "pocket"
const SOURCE_CORE := "core"
const COLOR_TEXT := Color(0.863, 0.886, 0.878)
const COLOR_MUTED := Color(0.537, 0.576, 0.588)
const COLOR_ACCENT := Color(0.498, 0.573, 0.722)
const COLOR_WARNING := Color(0.83, 0.59, 0.28)
const DRAG_START_DISTANCE := 6.0

class StorageSlot:
	extends Button

	signal drag_pressed(
		item_id: String,
		display_name: String,
		source: String,
		item_count: int,
		mouse_button: MouseButton,
		control_pressed: bool
	)

	var item_id := ""
	var display_name := ""
	var source := ""
	var item_count := 0


	func configure(
		configured_item_id: String,
		configured_display_name: String,
		configured_source: String,
		configured_count: int
	) -> void:
		item_id = configured_item_id
		display_name = configured_display_name
		source = configured_source
		item_count = configured_count


	func _gui_input(event: InputEvent) -> void:
		if not (event is InputEventMouseButton):
			return
		var mouse_event := event as InputEventMouseButton
		if (
			mouse_event.pressed
			and item_count > 0
			and mouse_event.button_index in [
				MOUSE_BUTTON_LEFT,
				MOUSE_BUTTON_RIGHT,
			]
		):
			drag_pressed.emit(
				item_id,
				display_name,
				source,
				item_count,
				mouse_event.button_index,
				mouse_event.ctrl_pressed
			)


class StorageDropArea:
	extends ColorRect


var _world: Node
var _open := false
var _result := ""
var _pocket_slots: Dictionary = {}
var _core_slots: Dictionary = {}
var _pocket_drop_area: StorageDropArea
var _core_drop_area: StorageDropArea
var _drag_pending := false
var _drag_active := false
var _drag_item_id := ""
var _drag_display_name := ""
var _drag_source := ""
var _drag_available := 0
var _drag_selected_amount := 0
var _drag_mouse_button := MOUSE_BUTTON_NONE
var _drag_origin := Vector2.ZERO
var _drag_preview: PanelContainer
var _drag_preview_label: Label

@onready var _root: Control = $Root
@onready var _pocket_groups: VBoxContainer = (
	$Root/Window/Margin/Layout/Body/Pocket/Margin/Layout/Scroll/Groups
)
@onready var _core_groups: VBoxContainer = (
	$Root/Window/Margin/Layout/Body/Core/Margin/Layout/Scroll/Groups
)
@onready var _pocket_summary: Label = (
	$Root/Window/Margin/Layout/Body/Pocket/Margin/Layout/Header/Summary
)
@onready var _core_summary: Label = (
	$Root/Window/Margin/Layout/Body/Core/Margin/Layout/Header/Summary
)
@onready var _result_text: Label = $Root/Window/Margin/Layout/Footer/Result
@onready var _close_button: Button = (
	$Root/Window/Margin/Layout/Header/Margin/Row/Close
)
@onready var _pocket_panel: PanelContainer = (
	$Root/Window/Margin/Layout/Body/Pocket
)
@onready var _core_panel: PanelContainer = (
	$Root/Window/Margin/Layout/Body/Core
)


func setup(world: Node) -> void:
	_world = world
	_root.visible = false
	_pocket_drop_area = _create_drop_area(_pocket_panel)
	_core_drop_area = _create_drop_area(_core_panel)
	set_process(false)
	_close_button.pressed.connect(close)
	_world.inventory_changed.connect(_on_inventory_changed)
	_world.core_storage_changed.connect(_on_inventory_changed)


func open() -> void:
	if _world == null or not _world.core_repaired:
		return
	_open = true
	_result = ""
	_root.visible = true
	_refresh()


func close() -> void:
	_open = false
	_clear_drag_session()
	_root.visible = false


func is_open() -> bool:
	return _open


func item_row_count() -> int:
	return _pocket_slots.size()


func pocket_slot(item_id: String) -> StorageSlot:
	return _pocket_slots.get(item_id) as StorageSlot


func core_slot(item_id: String) -> StorageSlot:
	return _core_slots.get(item_id) as StorageSlot


func result_text() -> String:
	return _result_text.text


func transfer_drag(item_id: String, source: String, split_half: bool) -> int:
	var available: int = _available_count(item_id, source)
	var requested := available
	if split_half:
		requested = ceili(float(available) / 2.0)
	return transfer_drag_amount(item_id, source, requested)


func transfer_drag_amount(item_id: String, source: String, requested: int) -> int:
	if _world == null or not _open or item_id.is_empty():
		return 0
	var available := _available_count(item_id, source)
	if available <= 0:
		_result = "该栏没有可转移的物品"
		_refresh()
		return 0
	requested = clampi(requested, 1, available)
	var moved: int
	var action: String
	if source == SOURCE_POCKET:
		moved = _world.transfer_pocket_to_core(item_id, requested)
		action = "存入核心"
	elif source == SOURCE_CORE:
		moved = _world.transfer_core_to_pocket(item_id, requested)
		action = "取回背包"
	else:
		return 0
	_result = _transfer_result(action, moved, requested, requested < available)
	_refresh()
	return moved


func drag_selected_amount() -> int:
	return _drag_selected_amount


func drag_is_pending() -> bool:
	return _drag_pending


func cancel_drag() -> void:
	_clear_drag_session()


func _on_inventory_changed(_changed_value = null) -> void:
	if _open:
		_refresh()


func _unhandled_input(event: InputEvent) -> void:
	if not _open or not (event is InputEventKey):
		return
	var key_event := event as InputEventKey
	if key_event.pressed and not key_event.echo and key_event.keycode == KEY_ESCAPE:
		close()
		get_viewport().set_input_as_handled()


func _input(event: InputEvent) -> void:
	if not _open:
		return
	if event is InputEventKey:
		var key_event := event as InputEventKey
		if (
			(_drag_pending or _drag_active)
			and key_event.pressed
			and not key_event.echo
			and (
				key_event.keycode == KEY_CTRL
				or key_event.physical_keycode == KEY_CTRL
			)
		):
			_halve_drag_selection()
		return
	if not (event is InputEventMouseButton):
		return
	var mouse_event := event as InputEventMouseButton
	if (
		(_drag_pending or _drag_active)
		and not mouse_event.pressed
		and mouse_event.button_index == _drag_mouse_button
	):
		_finish_drag(get_viewport().get_mouse_position())
		get_viewport().set_input_as_handled()


func _process(_delta: float) -> void:
	var mouse_position := get_viewport().get_mouse_position()
	if (
		_drag_pending
		and mouse_position.distance_to(_drag_origin) >= DRAG_START_DISTANCE
	):
		_activate_drag()
	if _drag_active:
		_position_drag_preview(mouse_position)


func _refresh() -> void:
	var groups := SliceInventoryReadModel.paired_inventory_groups(
		_world.pocket,
		_world.core_storage,
		true,
		SliceItemCatalog.visible_ids(_world.is_core_charged())
	)
	_rebuild_side(_pocket_groups, _pocket_slots, groups, SOURCE_POCKET)
	_rebuild_side(_core_groups, _core_slots, groups, SOURCE_CORE)
	_pocket_summary.text = (
		"常规每类 %d · 步枪 1"
		% _world.pocket.profile().per_item_capacity
		if _world.is_core_charged()
		else "每类 %d" % _world.pocket.profile().per_item_capacity
	)
	_core_summary.text = (
		"常规每类 %d · 步枪 1 · 电池 200"
		% _world.core_storage.profile().per_item_capacity
		if _world.is_core_charged()
		else "每类 %d" % _world.core_storage.profile().per_item_capacity
	)
	_result_text.text = (
		_result
		if not _result.is_empty()
		else "直接拖拽整堆；拖动前或拖动中每按一次 Ctrl / Control，选中数量减半"
	)
	_result_text.add_theme_color_override(
		"font_color",
		COLOR_WARNING if _result.begins_with("容量受限") else COLOR_TEXT
	)


func _rebuild_side(
	root: VBoxContainer,
	slots: Dictionary,
	groups: Array[Dictionary],
	source: String
) -> void:
	for child in root.get_children():
		root.remove_child(child)
		child.queue_free()
	slots.clear()
	for group in groups:
		var section := VBoxContainer.new()
		section.name = "%s_%s" % [source, String(group["category"])]
		section.add_theme_constant_override("separation", 4)
		root.add_child(section)

		var title := Label.new()
		title.add_theme_color_override("font_color", COLOR_MUTED)
		title.add_theme_font_size_override("font_size", 14)
		title.text = String(group["title"])
		section.add_child(title)

		var grid := GridContainer.new()
		grid.columns = 2
		grid.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		grid.add_theme_constant_override("h_separation", 7)
		grid.add_theme_constant_override("v_separation", 7)
		section.add_child(grid)
		for item in group["items"]:
			var slot := _create_slot(item, source)
			grid.add_child(slot)
			slots[String(item["item_id"])] = slot


func _create_slot(item: Dictionary, source: String) -> StorageSlot:
	var item_id := String(item["item_id"])
	var is_pocket := source == SOURCE_POCKET
	var count := int(item["left_count"] if is_pocket else item["right_count"])
	var capacity := int(
		item["left_capacity"] if is_pocket else item["right_capacity"]
	)
	var slot := StorageSlot.new()
	slot.name = "%s_%s" % [source, item_id.replace(".", "_")]
	slot.custom_minimum_size = Vector2(244, 76)
	slot.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	slot.focus_mode = Control.FOCUS_NONE
	slot.alignment = HORIZONTAL_ALIGNMENT_LEFT
	slot.add_theme_font_size_override("font_size", 14)
	slot.add_theme_color_override(
		"font_color", COLOR_TEXT if count > 0 else COLOR_MUTED
	)
	slot.icon = _read_model_icon(item)
	slot.expand_icon = true
	slot.text = "%s\n%d / %d" % [String(item["display_name"]), count, capacity]
	slot.tooltip_text = "直接拖到%s；每按一次 Ctrl / Control，选中数量减半" % (
		"核心仓库" if is_pocket else "随身背包"
	)
	slot.configure(item_id, String(item["display_name"]), source, count)
	slot.drag_pressed.connect(_on_slot_drag_pressed)
	return slot


func _on_slot_drag_pressed(
	item_id: String,
	display_name: String,
	source: String,
	available: int,
	mouse_button: MouseButton,
	control_pressed: bool
) -> void:
	_clear_drag_session()
	_drag_pending = true
	_drag_item_id = item_id
	_drag_display_name = display_name
	_drag_source = source
	_drag_available = available
	_drag_selected_amount = (
		ceili(float(available) / 2.0) if control_pressed else available
	)
	_drag_mouse_button = mouse_button
	_drag_origin = get_viewport().get_mouse_position()
	set_process(true)


func _activate_drag() -> void:
	_drag_pending = false
	_drag_active = true
	_pocket_drop_area.visible = _drag_source == SOURCE_CORE
	_core_drop_area.visible = _drag_source == SOURCE_POCKET
	_create_drag_preview()


func _halve_drag_selection() -> void:
	_drag_selected_amount = ceili(float(_drag_selected_amount) / 2.0)
	_update_drag_preview()


func _finish_drag(mouse_position: Vector2) -> void:
	if not _drag_active:
		_clear_drag_session()
		return
	var item_id := _drag_item_id
	var source := _drag_source
	var selected_amount := _drag_selected_amount
	var target_source := _target_source_at(mouse_position)
	_clear_drag_session()
	if target_source.is_empty() or target_source == source:
		_result = "未放入目标栏，物品未移动"
		_refresh()
		return
	transfer_drag_amount(item_id, source, selected_amount)


func _target_source_at(mouse_position: Vector2) -> String:
	if _pocket_panel.get_global_rect().has_point(mouse_position):
		return SOURCE_POCKET
	if _core_panel.get_global_rect().has_point(mouse_position):
		return SOURCE_CORE
	return ""


func _create_drag_preview() -> void:
	_drag_preview = PanelContainer.new()
	_drag_preview.name = "DragPreview"
	_drag_preview.custom_minimum_size = Vector2(190, 48)
	_drag_preview.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_drag_preview.z_index = 40
	var style := StyleBoxFlat.new()
	style.bg_color = Color(0.055, 0.075, 0.09, 0.96)
	style.border_color = COLOR_ACCENT
	style.set_border_width_all(2)
	style.corner_radius_top_left = 4
	style.corner_radius_top_right = 4
	style.corner_radius_bottom_left = 4
	style.corner_radius_bottom_right = 4
	style.content_margin_left = 12
	style.content_margin_right = 12
	style.content_margin_top = 8
	style.content_margin_bottom = 8
	_drag_preview.add_theme_stylebox_override("panel", style)
	_drag_preview_label = Label.new()
	_drag_preview_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_drag_preview_label.add_theme_color_override("font_color", COLOR_TEXT)
	_drag_preview_label.add_theme_font_size_override("font_size", 16)
	_drag_preview.add_child(_drag_preview_label)
	_root.add_child(_drag_preview)
	_update_drag_preview()


func _update_drag_preview() -> void:
	if _drag_preview_label == null:
		return
	_drag_preview_label.text = "%s  × %d" % [
		_drag_display_name,
		_drag_selected_amount,
	]


func _position_drag_preview(mouse_position: Vector2) -> void:
	if _drag_preview == null:
		return
	_drag_preview.position = mouse_position + Vector2(18, 18)


func _create_drop_area(
	parent: PanelContainer
) -> StorageDropArea:
	var area := StorageDropArea.new()
	area.name = "DropArea"
	area.color = Color(COLOR_ACCENT, 0.12)
	area.mouse_filter = Control.MOUSE_FILTER_IGNORE
	area.z_index = 20
	area.visible = false
	parent.add_child(area)
	area.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	parent.move_child(area, parent.get_child_count() - 1)
	return area


func _clear_drag_session() -> void:
	if _pocket_drop_area != null:
		_pocket_drop_area.visible = false
	if _core_drop_area != null:
		_core_drop_area.visible = false
	if _drag_preview != null:
		_drag_preview.queue_free()
	_drag_preview = null
	_drag_preview_label = null
	_drag_pending = false
	_drag_active = false
	_drag_item_id = ""
	_drag_display_name = ""
	_drag_source = ""
	_drag_available = 0
	_drag_selected_amount = 0
	_drag_mouse_button = MOUSE_BUTTON_NONE
	set_process(false)


func _available_count(item_id: String, source: String) -> int:
	if _world == null:
		return 0
	if source == SOURCE_POCKET:
		return _world.pocket.count(item_id)
	if source == SOURCE_CORE:
		return _world.core_storage.count(item_id)
	return 0


func _transfer_result(
	action: String,
	moved: int,
	requested: int,
	split_half: bool
) -> String:
	if moved <= 0:
		return "%s失败：目标栏该物品已满" % action
	if moved < requested:
		return "容量受限：%s %d / %d 件" % [action, moved, requested]
	return "%s%s %d 件" % ["半堆" if split_half else "整堆", action, moved]


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
