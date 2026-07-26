class_name SliceCoreStoragePanel
extends CanvasLayer

## Core central warehouse panel (arc L2,
## docs/features/slice-core-functionalization-v1.md). The repaired core opens
## this panel through its world interaction. Number keys move each currently
## supported item in one direction; Inventory capacity bounds every transfer.

var _world: Node
var _open := false
var _result := ""

@onready var _root: Control = $Root
@onready var _list: Label = $Root/Box/List


func setup(world: Node) -> void:
	_world = world
	_root.visible = false
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


func _on_inventory_changed() -> void:
	if _open:
		_refresh()


func _unhandled_input(event: InputEvent) -> void:
	if not _open or not (event is InputEventKey):
		return
	var key_event := event as InputEventKey
	if not key_event.pressed or key_event.echo:
		return
	if key_event.keycode == KEY_ESCAPE:
		close()
		get_viewport().set_input_as_handled()
		return

	var moved := 0
	match key_event.keycode:
		KEY_1:
			moved = _world.transfer_pocket_to_core(SliceWorld.ITEM_CRYSTAL)
			_result = _result_text("存入晶体", moved)
		KEY_2:
			moved = _world.transfer_core_to_pocket(SliceWorld.ITEM_CRYSTAL)
			_result = _result_text("取出晶体", moved)
		KEY_3:
			moved = _world.transfer_pocket_to_core(SliceWorld.ITEM_PART)
			_result = _result_text("存入机械零件", moved)
		KEY_4:
			moved = _world.transfer_core_to_pocket(SliceWorld.ITEM_PART)
			_result = _result_text("取出机械零件", moved)
		KEY_5:
			moved = _world.transfer_all_building_kits_to_core()
			_result = _result_text("存入全部建筑套件", moved)
		KEY_6:
			moved = _world.transfer_all_building_kits_to_pocket()
			_result = _result_text("取出全部建筑套件", moved)
		_:
			return
	_refresh()
	get_viewport().set_input_as_handled()


func _refresh() -> void:
	var pocket: Inventory = _world.pocket
	var storage: Inventory = _world.core_storage
	var lines: Array[String] = [
		"【前哨核心 · 中央仓库】  Esc 关闭",
		"核心直供：在线（%d 格）" % int(SliceWorld.CORE_DIRECT_POWER_RANGE / SliceWorld.TILE_SIZE),
		"背包：%d/%d    仓库：%d/%d" % [
			pocket.total(), pocket.capacity, storage.total(), storage.capacity
		],
		"",
		"晶体       背包 %d    仓库 %d" % [
			pocket.count(SliceWorld.ITEM_CRYSTAL), storage.count(SliceWorld.ITEM_CRYSTAL)
		],
		"[1] 全部存入    [2] 尽量取出",
		"机械零件   背包 %d    仓库 %d" % [
			pocket.count(SliceWorld.ITEM_PART), storage.count(SliceWorld.ITEM_PART)
		],
		"[3] 全部存入    [4] 尽量取出",
		"建筑套件   背包 %d    仓库 %d" % [
			_building_kit_total(pocket), _building_kit_total(storage)
		],
		"[5] 全部存入    [6] 尽量取出",
	]
	if not _result.is_empty():
		lines.append("")
		lines.append(_result)
	_list.text = "\n".join(lines)


func _result_text(action: String, moved: int) -> String:
	if moved <= 0:
		return "%s：没有可转移物品或目标空间不足" % action
	return "%s：%d" % [action, moved]


func _building_kit_total(inventory: Inventory) -> int:
	var total := 0
	for definition in SliceBuildingCatalog.all():
		total += inventory.count(definition.kit_item_id)
	return total
