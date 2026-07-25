class_name SliceBuildingActionPanel
extends CanvasLayer

## Short operation panel for a placed building. Demolition requires pressing 2
## twice; rule failures remain visible and never remove or drop player property.

var _world: Node
var _target: SliceBuildingInstance
var _open := false
var _confirming_demolition := false
var _result := ""

@onready var _root: Control = $Root
@onready var _list: Label = $Root/Box/List


func setup(world: Node) -> void:
	_world = world
	_root.visible = false


func open(instance: SliceBuildingInstance) -> void:
	if instance == null or instance.definition == null:
		return
	_target = instance
	_open = true
	_confirming_demolition = false
	_result = ""
	_root.visible = true
	_refresh()


func close() -> void:
	_target = null
	_open = false
	_confirming_demolition = false
	_result = ""
	_root.visible = false


func is_open() -> bool:
	return _open


func target_instance() -> SliceBuildingInstance:
	return _target


func _unhandled_input(event: InputEvent) -> void:
	if not _open or not (event is InputEventKey):
		return
	var key_event := event as InputEventKey
	if not key_event.pressed or key_event.echo:
		return
	match key_event.keycode:
		KEY_ESCAPE:
			close()
		KEY_1:
			_confirming_demolition = false
			var reason: String = _world.adjustment_block_reason(_target)
			if not reason.is_empty():
				_result = reason
				_refresh()
			elif _world.begin_building_adjustment(_target):
				close()
		KEY_2:
			var reason: String = _world.demolition_block_reason(_target)
			if not reason.is_empty():
				_confirming_demolition = false
				_result = reason
				_refresh()
			elif not _confirming_demolition:
				_confirming_demolition = true
				_result = "再次按 2 确认拆除并返还套件"
				_refresh()
			elif _world.demolish_building(_target):
				close()
		_:
			return
	get_viewport().set_input_as_handled()


func _refresh() -> void:
	if _target == null or _target.definition == null:
		close()
		return
	var lines: Array[String] = [
		"【%s】  Esc 返回" % _target.definition.display_name,
		"[1] 调整位置",
		"[2] 拆除并返还 1 个套件",
	]
	if not _result.is_empty():
		lines.append("")
		lines.append(_result)
	_list.text = "\n".join(lines)
