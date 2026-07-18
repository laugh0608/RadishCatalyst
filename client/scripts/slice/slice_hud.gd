class_name SliceHud
extends CanvasLayer

## Minimal slice HUD: crystal count, current goal line, and the nearest
## interactable's prompt. Plain prototype text on the 1920x1080 UI canvas;
## pixel-styled HUD art is a later topic.

var _world: Node
var _player: SlicePlayer

@onready var crystal_label: Label = $CrystalCount
@onready var goal_label: Label = $Goal
@onready var prompt_label: Label = $Prompt


func setup(world: Node, player: SlicePlayer) -> void:
	_world = world
	_player = player
	world.crystals_changed.connect(func(_count: int) -> void: _refresh_state())
	world.core_repair_completed.connect(_refresh_state)
	_refresh_state()


func _refresh_state() -> void:
	crystal_label.text = "晶体：%d" % _world.crystal_count
	if _world.core_repaired:
		goal_label.text = "前哨核心已修复"
	else:
		goal_label.text = "采集晶体修复前哨核心（%d/%d）" % [
			_world.crystal_count, CoreRepairSite.REPAIR_COST
		]


func _process(_delta: float) -> void:
	if _world == null or _player == null:
		return
	if _world.carrying_collector:
		prompt_label.visible = true
		if _world.is_place_target_valid():
			prompt_label.text = "按 E 放置采集器"
		else:
			prompt_label.text = "需在空旷晶体地放置采集器"
		return
	var target := _player.current_interact_target()
	var prompt := "" if target == null else str(target.get_prompt(_world))
	prompt_label.visible = not prompt.is_empty()
	prompt_label.text = prompt
