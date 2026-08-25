class_name SliceDemoCompletionCard
extends CanvasLayer

## Session-only completion acknowledgement. Durable completion remains derived
## from field_encounter.state == delivered, so loading a completed world keeps
## the HUD result without replaying this card.

var _world: Node
var _open := false

@onready var root_control: Control = $Root
@onready var continue_button: Button = $Root/Card/Buttons/ContinueButton
@onready var return_button: Button = $Root/Card/Buttons/ReturnButton
@onready var status_label: Label = $Root/Card/Status


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_WHEN_PAUSED
	root_control.visible = false
	continue_button.pressed.connect(close)
	return_button.pressed.connect(_save_and_return)


func setup(world: Node) -> void:
	_world = world
	_world.combat_controller.demo_completed.connect(open)


func _exit_tree() -> void:
	if _open and get_tree() != null:
		get_tree().paused = false


func open() -> void:
	if _open:
		return
	_open = true
	status_label.text = ""
	root_control.visible = true
	get_tree().paused = true
	continue_button.grab_focus()


func close() -> void:
	if not _open:
		return
	_open = false
	root_control.visible = false
	get_tree().paused = false


func is_open() -> bool:
	return _open


func _unhandled_input(event: InputEvent) -> void:
	if not _open or not event.is_action_pressed("ui_cancel"):
		return
	close()
	get_viewport().set_input_as_handled()


func _save_and_return() -> void:
	if not _world.save_now():
		status_label.text = "保存失败，仍停留在当前世界；请检查存档目录后重试。"
		return
	close()
	_world.return_to_startup_requested.emit()
