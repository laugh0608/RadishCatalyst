class_name SliceHud
extends CanvasLayer

## Slice HUD combines inventory / placement with compact player and durable
## encounter state. Enemy details appear only while the encounter is nearby.

var _world: Node
var _player: SlicePlayer

@onready var crystal_label: Label = $CrystalCount
@onready var part_label: Label = $PartCount
@onready var kit_label: Label = $KitCount
@onready var goal_label: Label = $Goal
@onready var health_label: Label = $Health
@onready var combat_label: Label = $CombatState
@onready var prompt_panel: ColorRect = $PromptPanel
@onready var enemy_panel: ColorRect = $EnemyPanel
@onready var enemy_label: Label = $EnemyPanel/EnemyState
@onready var notice_label: Label = $CombatNotice
@onready var prompt_label: Label = $Prompt


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
	crystal_label.text = "背包晶体：%d/%d" % [
		_world.pocket.count(SliceWorld.ITEM_CRYSTAL), SliceWorld.POCKET_CAPACITY
	]
	part_label.text = "背包催化剂：%d｜零件：%d" % [
		_world.pocket.count(SliceWorld.ITEM_CATALYST),
		_world.pocket.count(SliceWorld.ITEM_PART),
	]
	kit_label.text = "套件：地%d 采%d 反%d 中%d 带%d 箱%d" % [
		_world.pocket.count(SliceWorld.ITEM_FLOOR_KIT),
		_world.pocket.count(SliceWorld.ITEM_COLLECTOR_KIT),
		_world.pocket.count(SliceWorld.ITEM_REACTOR_KIT),
		_world.pocket.count(SliceWorld.ITEM_POWER_RELAY_KIT),
		_world.pocket.count(SliceWorld.ITEM_CONVEYOR_KIT),
		_world.pocket.count(SliceWorld.ITEM_STORAGE_KIT),
	]
	health_label.text = "生命 %d/%d" % [
		_world.combat_controller.health,
		_world.combat_controller.max_health,
	]
	combat_label.text = "核心：%s｜%s｜闪避：%s" % [
		"已充能" if _world.is_core_charged() else "未充能",
		_world.combat_controller.attack_status_text(),
		_world.combat_controller.dodge_status_text(),
	]
	goal_label.text = _world.current_journey_goal_text()
	if _world.core_repaired:
		goal_label.text += "｜核心仓库 %d/%d" % [
			_world.core_storage.total(),
			SliceWorld.CORE_STORAGE_CAPACITY,
		]
	enemy_panel.visible = _world.combat_controller.enemy_hud_visible()
	if enemy_panel.visible:
		var enemy: SliceFieldEnemy = (
			_world.combat_controller.field_enemy
		)
		enemy_label.text = "裂晶爬兽  %d/%d｜%s" % [
			enemy.health,
			SliceFieldEnemy.MAX_HEALTH,
			enemy.state_text(),
		]
	notice_label.text = _world.combat_controller.notice_text
	notice_label.visible = not notice_label.text.is_empty()


func _process(_delta: float) -> void:
	if _world == null or _player == null:
		return
	if _world.is_placement_active():
		prompt_panel.visible = true
		prompt_label.visible = true
		if _world.is_place_target_valid():
			prompt_label.text = "按 E 放置%s｜R 旋转｜Esc 取消" % (
				_world.selected_building_name()
			)
		else:
			prompt_label.text = "%s：%s｜R 旋转｜Esc 取消" % [
				_world.selected_building_name(),
				_world.placement_invalid_reason()
			]
		return
	if _world.is_combat_input_blocked():
		prompt_panel.visible = false
		prompt_label.visible = false
		return
	var target := _player.current_interact_target()
	var prompt := "" if target == null else str(target.get_prompt(_world))
	prompt_label.visible = not prompt.is_empty()
	prompt_panel.visible = prompt_label.visible
	prompt_label.text = prompt
