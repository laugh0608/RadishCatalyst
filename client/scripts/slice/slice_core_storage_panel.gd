class_name SliceCoreStoragePanel
extends CanvasLayer

## Core warehouse shell over the shared paired-container surface. Quantity,
## capacity-limited movement, save scheduling, and signals stay in SliceWorld.

const SOURCE_POCKET := "pocket"
const SOURCE_CORE := "core"

var _world: Node
var _open := false

@onready var _root: Control = $Root
@onready var _container_view: SlicePairedContainerView = (
	$Root/Window/Margin/Layout/ContainerView
)
@onready var _close_button: Button = (
	$Root/Window/Margin/Layout/Header/Margin/Row/Close
)


func setup(world: Node) -> void:
	_world = world
	_root.visible = false
	_close_button.pressed.connect(close)
	_container_view.transfer_requested.connect(_on_transfer_requested)
	_world.inventory_changed.connect(_on_inventory_changed)
	_world.core_storage_changed.connect(_on_inventory_changed)


func open() -> void:
	if _world == null or not _world.core_repaired:
		return
	_open = true
	_root.visible = true
	_container_view.set_result(
		"只显示实际持有物 · Ctrl / Control 逐次减半 · Enter / Space 转移"
	)
	_refresh()


func close() -> void:
	_open = false
	_container_view.cancel_interaction()
	_root.visible = false


func is_open() -> bool:
	return _open


func item_row_count() -> int:
	return _container_view.item_row_count()


func pocket_slot(item_id: String) -> SlicePairedContainerView.ItemSlot:
	return _container_view.slot(SOURCE_POCKET, item_id)


func core_slot(item_id: String) -> SlicePairedContainerView.ItemSlot:
	return _container_view.slot(SOURCE_CORE, item_id)


func result_text() -> String:
	return _container_view.result_text()


func filter_id() -> String:
	return _container_view.filter_id()


func set_filter(category_id: String) -> void:
	_container_view.set_filter(category_id)


func visible_item_ids(source: String) -> Array[String]:
	return _container_view.visible_item_ids(source)


func halve_drag_selection() -> void:
	_container_view.halve_selection()


func transfer_drag(item_id: String, source: String, split_half: bool) -> int:
	var available := _available_count(item_id, source)
	var requested := (
		ceili(float(available) / 2.0) if split_half else available
	)
	return transfer_drag_amount(item_id, source, requested)


func transfer_drag_amount(item_id: String, source: String, requested: int) -> int:
	if _world == null or not _open or item_id.is_empty():
		return 0
	var available := _available_count(item_id, source)
	if available <= 0:
		_container_view.set_result("该栏没有可转移的物品", true)
		return 0
	requested = clampi(requested, 1, available)
	var moved := 0
	var action := ""
	if source == SOURCE_POCKET:
		moved = _world.transfer_pocket_to_core(item_id, requested)
		action = "存入核心"
	elif source == SOURCE_CORE:
		moved = _world.transfer_core_to_pocket(item_id, requested)
		action = "取回背包"
	else:
		return 0
	_container_view.set_result(
		_transfer_result(action, moved, requested), moved <= 0 or moved < requested
	)
	_refresh()
	return moved


func drag_selected_amount() -> int:
	return _container_view.selected_amount()


func drag_is_pending() -> bool:
	return _container_view.drag_is_pending()


func cancel_drag() -> void:
	_container_view.cancel_interaction()


func _unhandled_input(event: InputEvent) -> void:
	if not _open or not (event is InputEventKey):
		return
	var key_event := event as InputEventKey
	if key_event.pressed and not key_event.echo and key_event.keycode == KEY_ESCAPE:
		close()
		get_viewport().set_input_as_handled()


func _on_inventory_changed(_changed_value = null) -> void:
	if _open:
		_refresh()


func _on_transfer_requested(item_id: String, source: String, requested: int) -> void:
	transfer_drag_amount(item_id, source, requested)


func _refresh() -> void:
	var items := SliceInventoryReadModel.paired_inventory_items(
		_world.pocket, _world.core_storage
	)
	for item in items:
		var item_id := String(item["item_id"])
		item["left_to_right"] = _world.core_storage.free_space_for(item_id) > 0
		item["left_to_right_reason"] = "核心仓库中该类已满"
		item["right_to_left"] = _world.pocket.free_space_for(item_id) > 0
		item["right_to_left_reason"] = "随身背包中该类已满"
	_container_view.set_snapshot({
		"left_source": SOURCE_POCKET,
		"right_source": SOURCE_CORE,
		"left_title": "随身背包",
		"right_title": "核心仓库",
		"left_summary": "每类 %d" % _world.pocket.profile().per_item_capacity,
		"right_summary": "每类 %d" % _world.core_storage.profile().per_item_capacity,
		"items": items,
	})


func _available_count(item_id: String, source: String) -> int:
	if source == SOURCE_POCKET:
		return _world.pocket.count(item_id)
	if source == SOURCE_CORE:
		return _world.core_storage.count(item_id)
	return 0


func _transfer_result(action: String, moved: int, requested: int) -> String:
	if moved <= 0:
		return "%s失败：目标栏不接受该物品或已满" % action
	if moved < requested:
		return "容量受限：%s %d / %d 件" % [action, moved, requested]
	return "%s %d 件" % [action, moved]
