class_name SliceCoreStoragePanel
extends CanvasLayer

## Categorized central-warehouse panel. Every ordinary or compatibility item is
## selected explicitly, then moved losslessly through SliceWorld's authoritative
## partial-transfer API. Quest items are deliberately absent from this surface.

const COLOR_TEXT := Color(0.118, 0.145, 0.149)
const COLOR_MUTED := Color(0.24, 0.28, 0.28)
const COLOR_READY := Color(0.035, 0.42, 0.4)
const COLOR_WARNING := Color(0.702, 0.392, 0.102)

var _world: Node
var _open := false
var _result := ""
var _selected_item_id := ""
var _item_buttons: Dictionary = {}

@onready var _root: Control = $Root
@onready var _groups: VBoxContainer = (
	$Root/Window/Margin/Layout/Body/Inventory/InventoryScroll/Groups
)
@onready var _summary: Label = (
	$Root/Window/Margin/Layout/Body/Inventory/Summary
)
@onready var _selected_icon: TextureRect = (
	$Root/Window/Margin/Layout/Body/Detail/Margin/Layout/Icon
)
@onready var _selected_name: Label = (
	$Root/Window/Margin/Layout/Body/Detail/Margin/Layout/Name
)
@onready var _selected_category: Label = (
	$Root/Window/Margin/Layout/Body/Detail/Margin/Layout/Category
)
@onready var _counts: Label = (
	$Root/Window/Margin/Layout/Body/Detail/Margin/Layout/Counts
)
@onready var _deposit: Button = (
	$Root/Window/Margin/Layout/Body/Detail/Margin/Layout/Deposit
)
@onready var _withdraw: Button = (
	$Root/Window/Margin/Layout/Body/Detail/Margin/Layout/Withdraw
)
@onready var _result_text: Label = (
	$Root/Window/Margin/Layout/Body/Detail/Margin/Layout/Result
)
@onready var _close_button: Button = (
	$Root/Window/Margin/Layout/Header/Margin/Row/Close
)


func setup(world: Node) -> void:
	_world = world
	_root.visible = false
	_close_button.pressed.connect(close)
	_deposit.pressed.connect(_on_deposit_pressed)
	_withdraw.pressed.connect(_on_withdraw_pressed)
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
	_root.visible = false


func is_open() -> bool:
	return _open


func selected_item_id() -> String:
	return _selected_item_id


func item_button(item_id: String) -> Button:
	return _item_buttons.get(item_id) as Button


func item_row_count() -> int:
	return _item_buttons.size()


func result_text() -> String:
	return _result_text.text


func deposit_button() -> Button:
	return _deposit


func withdraw_button() -> Button:
	return _withdraw


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


func _refresh() -> void:
	var groups := SliceInventoryReadModel.paired_inventory_groups(
		_world.pocket, _world.core_storage, true
	)
	_reconcile_selection(groups)
	_rebuild_rows(groups)
	_refresh_detail(groups)
	_summary.text = "背包不限种类 · 每类 %d    核心仓库不限种类 · 每类 %d" % [
		_world.pocket.profile().per_item_capacity,
		_world.core_storage.profile().per_item_capacity,
	]


func _reconcile_selection(groups: Array[Dictionary]) -> void:
	var first_id := ""
	var first_owned_id := ""
	var selected_exists := false
	for group in groups:
		for item in group["items"]:
			var item_id := String(item["item_id"])
			if first_id.is_empty():
				first_id = item_id
			if (
				first_owned_id.is_empty()
				and (
					int(item["left_count"]) > 0
					or int(item["right_count"]) > 0
				)
			):
				first_owned_id = item_id
			if item_id == _selected_item_id:
				selected_exists = true
	if not selected_exists:
		_selected_item_id = first_owned_id if not first_owned_id.is_empty() else first_id


func _rebuild_rows(groups: Array[Dictionary]) -> void:
	for child in _groups.get_children():
		_groups.remove_child(child)
		child.queue_free()
	_item_buttons.clear()
	for group in groups:
		var section := VBoxContainer.new()
		section.name = "Category_%s" % String(group["category"])
		section.add_theme_constant_override("separation", 3)
		_groups.add_child(section)

		var title := Label.new()
		title.add_theme_color_override("font_color", COLOR_MUTED)
		title.add_theme_font_size_override("font_size", 15)
		title.text = String(group["title"])
		section.add_child(title)

		for item in group["items"]:
			var button := _create_item_button(item)
			section.add_child(button)
			_item_buttons[String(item["item_id"])] = button


func _create_item_button(item: Dictionary) -> Button:
	var item_id := String(item["item_id"])
	var button := Button.new()
	button.name = "Item_%s" % item_id.replace(".", "_")
	button.custom_minimum_size = Vector2(0, 54)
	button.toggle_mode = true
	button.button_pressed = item_id == _selected_item_id
	button.alignment = HORIZONTAL_ALIGNMENT_LEFT
	button.add_theme_font_size_override("font_size", 16)
	button.icon = _read_model_icon(item)
	button.expand_icon = true
	button.text = "%s    背包 %d / %d    核心 %d / %d" % [
		String(item["display_name"]),
		int(item["left_count"]),
		int(item["left_capacity"]),
		int(item["right_count"]),
		int(item["right_capacity"]),
	]
	button.tooltip_text = String(item["item_id"])
	button.pressed.connect(_on_item_selected.bind(item_id))
	return button


func _refresh_detail(groups: Array[Dictionary]) -> void:
	var selected := _find_item(groups, _selected_item_id)
	if selected.is_empty():
		_selected_icon.texture = null
		_selected_name.text = "没有可管理的物品"
		_selected_category.text = ""
		_counts.text = ""
		_deposit.disabled = true
		_withdraw.disabled = true
		return
	_selected_icon.texture = _read_model_icon(selected)
	_selected_name.text = String(selected["display_name"])
	_selected_category.text = SliceItemCatalog.category_title(
		String(selected["category"])
	)
	_counts.text = "背包 %d / %d\n核心仓库 %d / %d" % [
		int(selected["left_count"]),
		int(selected["left_capacity"]),
		int(selected["right_count"]),
		int(selected["right_capacity"]),
	]
	_deposit.disabled = (
		int(selected["left_count"]) <= 0
		or _world.core_storage.free_space_for(_selected_item_id) <= 0
	)
	_withdraw.disabled = (
		int(selected["right_count"]) <= 0
		or _world.pocket.free_space_for(_selected_item_id) <= 0
	)
	_deposit.text = "全部存入核心"
	_withdraw.text = "尽量取回背包"
	_result_text.text = (
		_result if not _result.is_empty() else "选择一种物品进行存取"
	)


func _find_item(groups: Array[Dictionary], item_id: String) -> Dictionary:
	for group in groups:
		for item in group["items"]:
			if String(item["item_id"]) == item_id:
				return item
	return {}


func _on_item_selected(item_id: String) -> void:
	_selected_item_id = item_id
	_result = ""
	_refresh()


func _on_deposit_pressed() -> void:
	if _selected_item_id.is_empty():
		return
	var moved: int = _world.transfer_pocket_to_core(_selected_item_id)
	_result = _result_for("存入", moved)
	_refresh()


func _on_withdraw_pressed() -> void:
	if _selected_item_id.is_empty():
		return
	var moved: int = _world.transfer_core_to_pocket(_selected_item_id)
	_result = _result_for("取出", moved)
	_refresh()


func _result_for(action: String, moved: int) -> String:
	if moved <= 0:
		return "%s失败：没有可转移物品或目标类别已满" % action
	return "%s %d 件" % [action, moved]


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
