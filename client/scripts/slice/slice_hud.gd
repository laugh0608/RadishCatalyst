class_name SliceHud
extends CanvasLayer

## Minimal slice HUD: backpack crystal count (with capacity), catalyst count,
## current goal line, and the nearest interactable's prompt. Plain prototype
## text on the 1920x1080 UI canvas; pixel-styled HUD art is a later topic.

var _world: Node
var _player: SlicePlayer

@onready var crystal_label: Label = $CrystalCount
@onready var catalyst_label: Label = $CatalystCount
@onready var goal_label: Label = $Goal
@onready var prompt_label: Label = $Prompt


func setup(world: Node, player: SlicePlayer) -> void:
	_world = world
	_player = player
	world.inventory_changed.connect(_refresh_state)
	world.catalyst_changed.connect(func(_count: int) -> void: _refresh_state())
	world.core_charge_changed.connect(func(_energy: int) -> void: _refresh_state())
	world.core_repair_completed.connect(_refresh_state)
	_refresh_state()


func _refresh_state() -> void:
	crystal_label.text = "背包晶体：%d/%d" % [
		_world.pocket.count(SliceWorld.ITEM_CRYSTAL), SliceWorld.POCKET_CAPACITY
	]
	catalyst_label.text = "催化剂：%d/%d" % [_world.catalyst_count, SliceWorld.CATALYST_CAP]
	if not _world.core_repaired:
		goal_label.text = "采集晶体修复前哨核心（%d/%d）" % [
			_world.pocket.count(SliceWorld.ITEM_CRYSTAL), CoreRepairSite.REPAIR_COST
		]
	elif _world.is_core_charged():
		goal_label.text = "前哨核心已充能"
	else:
		goal_label.text = "加工催化剂为核心充能（%d/%d）" % [
			_world.core_energy, SliceWorld.CORE_CHARGE_TARGET
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
