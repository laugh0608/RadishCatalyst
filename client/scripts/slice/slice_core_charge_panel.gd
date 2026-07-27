class_name SliceCoreChargePanel
extends CanvasLayer

## Explicit first-charge confirmation. It consumes no materials itself; the
## world owns deterministic core-storage-then-backpack deduction and saving.

var _world: Node
var _open := false

@onready var _root: Control = $Root
@onready var _body: Label = $Root/Box/Body
@onready var _confirm: Button = $Root/Box/Confirm
@onready var _cancel: Button = $Root/Box/Cancel


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
	_body.text = (
		"将 %d 份催化剂注入前哨核心？\n"
		+ "优先使用核心仓库，再使用背包。\n"
		+ "充能完成后永久解锁工具攻击与短距闪避。"
	) % required
	_cancel.grab_focus()


func close() -> void:
	_open = false
	_root.visible = false


func is_open() -> bool:
	return _open


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
