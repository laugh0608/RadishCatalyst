class_name SliceHud
extends CanvasLayer

## The slice HUD keeps the center playfield open while presenting journey,
## inventory, player, encounter and context state as separate game components.

var _world: Node
var _player: SlicePlayer

@onready var crystal_label: Label = (
	$RightStatusPanel/CrystalSlot/CrystalCount
)
@onready var catalyst_label: Label = (
	$RightStatusPanel/CatalystSlot/CatalystCount
)
@onready var part_label: Label = $RightStatusPanel/PartSlot/PartCount
@onready var kit_label: Label = $KitCount
@onready var goal_label: Label = $LeftStatusPanel/Goal
@onready var health_label: Label = $PlayerStatusPanel/Health
@onready var health_bar: ProgressBar = $PlayerStatusPanel/HealthBar
@onready var combat_label: Label = $PlayerStatusPanel/CombatState
@onready var prompt_panel: Panel = $PromptPanel
@onready var enemy_panel: Panel = $EnemyPanel
@onready var enemy_label: Label = $EnemyPanel/EnemyState
@onready var enemy_health_bar: ProgressBar = $EnemyPanel/HealthBar
@onready var notice_label: Label = $CombatNotice
@onready var prompt_key_label: Label = $PromptPanel/PromptKey/Label
@onready var prompt_label: Label = $PromptPanel/Prompt


func setup(world: Node, player: SlicePlayer) -> void:
	_world = world
	_player = player
	world.inventory_changed.connect(_refresh_state)
	world.core_storage_changed.connect(_refresh_state)
	world.core_repair_completed.connect(_refresh_state)
	world.core_charge_changed.connect(_refresh_state)
	world.placement_changed.connect(_refresh_state)
	world.building_storage_changed.connect(_refresh_state)
	world.combat_controller.state_changed.connect(_refresh_state)
	_refresh_state()


func _refresh_state(_changed_value = null) -> void:
	crystal_label.text = "%d/%d" % [
		_world.pocket.count(SliceWorld.ITEM_CRYSTAL),
		SliceWorld.POCKET_CAPACITY,
	]
	catalyst_label.text = str(
		_world.pocket.count(SliceWorld.ITEM_CATALYST)
	)
	part_label.text = str(_world.pocket.count(SliceWorld.ITEM_PART))
	kit_label.text = "套件：地%d 采%d 反%d 中%d 带%d 箱%d" % [
		_world.pocket.count(SliceWorld.ITEM_FLOOR_KIT),
		_world.pocket.count(SliceWorld.ITEM_COLLECTOR_KIT),
		_world.pocket.count(SliceWorld.ITEM_REACTOR_KIT),
		_world.pocket.count(SliceWorld.ITEM_POWER_RELAY_KIT),
		_world.pocket.count(SliceWorld.ITEM_CONVEYOR_KIT),
		_world.pocket.count(SliceWorld.ITEM_STORAGE_KIT),
	]
	kit_label.visible = false
	health_label.text = "生命 %d/%d" % [
		_world.combat_controller.health,
		_world.combat_controller.max_health,
	]
	health_bar.max_value = _world.combat_controller.max_health
	health_bar.value = _world.combat_controller.health
	combat_label.text = "核心：%s  ·  %s  ·  闪避：%s" % [
		"已充能" if _world.is_core_charged() else "未充能",
		_world.combat_controller.attack_status_text(),
		_world.combat_controller.dodge_status_text(),
	]
	goal_label.text = _world.current_journey_goal_text()
	enemy_panel.visible = _world.combat_controller.enemy_hud_visible()
	if enemy_panel.visible:
		var enemy: SliceFieldEnemy = (
			_world.combat_controller.field_enemy
		)
		enemy_label.text = "裂晶爬兽  ·  %s  ·  %d/%d" % [
			enemy.state_text(),
			enemy.health,
			SliceFieldEnemy.MAX_HEALTH,
		]
		enemy_health_bar.max_value = SliceFieldEnemy.MAX_HEALTH
		enemy_health_bar.value = enemy.health
	notice_label.text = _world.combat_controller.notice_text
	notice_label.visible = not notice_label.text.is_empty()


func _process(_delta: float) -> void:
	if _world == null or _player == null:
		return
	if _world.is_placement_active():
		prompt_panel.visible = true
		prompt_label.visible = true
		prompt_key_label.text = "LMB"
		var definition := SliceBuildingCatalog.find(
			_world.selected_building_id()
		)
		var remaining: int = (
			0
			if definition == null
			else _world.pocket.count(definition.kit_item_id)
		)
		if _world.is_place_target_valid():
			prompt_label.text = "放置 %s  ·  剩余 %d  ·  E 兼容  ·  R 旋转  ·  Esc 取消" % [
				_world.selected_building_name(),
				remaining,
			]
		else:
			prompt_label.text = "%s  ·  剩余 %d  ·  %s  ·  R 旋转  ·  Esc 取消" % [
				_world.selected_building_name(),
				remaining,
				_world.placement_invalid_reason()
			]
		return
	if _world.is_combat_input_blocked():
		prompt_panel.visible = false
		prompt_label.visible = false
		return
	var target := _player.current_interact_target()
	var prompt := "" if target == null else str(target.get_prompt(_world))
	prompt_key_label.text = "E"
	prompt_label.visible = not prompt.is_empty()
	prompt_panel.visible = prompt_label.visible
	prompt_label.text = _without_interact_prefix(prompt)


func _without_interact_prefix(prompt: String) -> String:
	if prompt.begins_with("按 E "):
		return prompt.trim_prefix("按 E ")
	return prompt
