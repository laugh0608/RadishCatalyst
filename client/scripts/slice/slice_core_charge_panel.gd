class_name SliceCoreChargePanel
extends CanvasLayer

## Explicit first-charge confirmation. It consumes no materials itself; the
## world owns deterministic core-storage-then-backpack deduction and saving.

var _world: Node
var _open := false

@onready var _root: Control = $Root
@onready var _amount: Label = (
	$Root/Window/Margin/Layout/Decision/Cost/Margin/Layout/Amount
)
@onready var _source: Label = (
	$Root/Window/Margin/Layout/Decision/Cost/Margin/Layout/Source
)
@onready var _confirm: Button = $Root/Window/Margin/Layout/Actions/Confirm
@onready var _cancel: Button = $Root/Window/Margin/Layout/Actions/Cancel


func _ready() -> void:
	_root.visible = false
	_confirm.pressed.connect(_confirm_charge)
	_cancel.pressed.connect(close)


func setup(world: Node) -> void:
	_world = world


func open() -> void:
	if _world == null or not _world.can_charge_core():
		return
	_open = true
	_root.visible = true
	var required: int = _world.core_charge_required()
	var stored: int = _world.core_storage.count(SliceWorld.ITEM_CATALYST)
	var carried: int = _world.pocket.count(SliceWorld.ITEM_CATALYST)
	_amount.text = "%d 份催化剂" % required
	_source.text = (
		"扣除顺序：核心仓库 %d → 随身背包 %d\n当前可用 %d / %d"
		% [stored, carried, stored + carried, required]
	)
	_confirm.text = "确认充能 · 消耗 %d 份" % required
	_cancel.grab_focus()


func close() -> void:
	_open = false
	_root.visible = false


func is_open() -> bool:
	return _open


func source_text() -> String:
	return _source.text


func confirm_text() -> String:
	return _confirm.text


func cancel_text() -> String:
	return _cancel.text


func _unhandled_input(event: InputEvent) -> void:
	if not _open:
		return
	if event.is_action_pressed("ui_cancel"):
		close()
		get_viewport().set_input_as_handled()
	elif event.is_action_pressed("ui_accept"):
		_confirm_charge()
		get_viewport().set_input_as_handled()


func _confirm_charge() -> void:
	if _world != null and _world.confirm_core_charge():
		close()
