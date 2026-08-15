class_name SliceHud
extends CanvasLayer

## The slice HUD keeps the center playfield open while presenting journey,
## inventory, player, encounter and context state as separate game components.

const ACCENT_COLOR := Color("7f92b8")
const DANGER_COLOR := Color("d85d4d")
const AMMO_WARNING_COLOR := Color("d6a24f")
const SECONDARY_TEXT_COLOR := Color("8f9d9d")
const PRIMARY_TEXT_COLOR := Color("f2f4f2")
const DIMMED_HUD_COLOR := Color(1.0, 1.0, 1.0, 0.42)
const ACTIVE_HUD_COLOR := Color.WHITE

var _world: Node
var _player: SlicePlayer
var _context_is_dimmed := false

@onready var left_status_panel: Panel = $LeftStatusPanel
@onready var right_status_panel: Panel = $RightStatusPanel
@onready var crystal_label: Label = (
	$RightStatusPanel/CrystalSlot/CrystalCount
)
@onready var catalyst_label: Label = (
	$RightStatusPanel/CatalystSlot/CatalystCount
)
@onready var part_label: Label = $RightStatusPanel/PartSlot/PartCount
@onready var kit_label: Label = $KitCount
@onready var goal_label: Label = $LeftStatusPanel/Goal
@onready var player_status_panel: Panel = $PlayerStatusPanel
@onready var health_label: Label = $PlayerStatusPanel/Health
@onready var health_bar: ProgressBar = $PlayerStatusPanel/HealthBar
@onready var combat_label: Label = $PlayerStatusPanel/CombatState
@onready var prompt_panel: Panel = $PromptPanel
@onready var prompt_key_label: Label = $PromptPanel/PromptKey/Label
@onready var prompt_meta_label: Label = $PromptPanel/PromptMeta
@onready var prompt_label: Label = $PromptPanel/Prompt
@onready var enemy_panel: Panel = $EnemyPanel
@onready var enemy_label: Label = $EnemyPanel/EnemyState
@onready var enemy_health_bar: ProgressBar = $EnemyPanel/HealthBar
@onready var notice_panel: Panel = $CombatNotice
@onready var notice_accent: ColorRect = $CombatNotice/Accent
@onready var notice_label: Label = $CombatNotice/Text
@onready var combat_action_panel: Panel = $CombatActionPanel
@onready var cutter_action_label: Label = (
	$CombatActionPanel/CutterSlot/CutterAction
)
@onready var cutter_active_line: ColorRect = (
	$CombatActionPanel/CutterSlot/ActiveLine
)
@onready var rifle_action_label: Label = (
	$CombatActionPanel/RifleSlot/RifleAction
)
@onready var rifle_active_line: ColorRect = (
	$CombatActionPanel/RifleSlot/ActiveLine
)
@onready var dodge_action_label: Label = (
	$CombatActionPanel/DodgeSlot/DodgeAction
)


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
		_world.pocket.profile().item_capacity(SliceWorld.ITEM_CRYSTAL),
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
	enemy_panel.visible = _world.combat_controller.enemy_hud_visible()
	var controller: SliceCombatController = _world.combat_controller
	var rifle_status := controller.pulse_rifle_status_text()
	combat_label.text = "核心：%s  ·  当前：%s  ·  %s" % [
		"已充能" if _world.is_core_charged() else "未充能",
		controller.current_weapon_name(),
		("步枪%s" % rifle_status if rifle_status == "未持有" else rifle_status),
	]
	_refresh_combat_actions(controller)
	if enemy_panel.visible:
		var enemy: SliceFieldEnemy = (
			controller.field_enemy
		)
		enemy_label.text = "裂晶爬兽  ·  %s  ·  %d/%d" % [
			enemy.state_text(),
			enemy.health,
			SliceFieldEnemy.MAX_HEALTH,
		]
		enemy_health_bar.max_value = SliceFieldEnemy.MAX_HEALTH
		enemy_health_bar.value = enemy.health
	goal_label.text = _world.current_journey_goal_text()
	_refresh_notice()


func _refresh_combat_actions(controller: SliceCombatController) -> void:
	var rifle_selected := (
		controller.current_weapon
		== SliceCombatController.WEAPON_PULSE_RIFLE
	)
	cutter_active_line.visible = not rifle_selected
	rifle_active_line.visible = rifle_selected
	cutter_action_label.text = "切割器  ·  LMB"
	dodge_action_label.text = "闪避  ·  %s" % controller.dodge_status_text()
	if not controller.has_pulse_rifle():
		rifle_action_label.text = "步枪  ·  未持有"
		rifle_action_label.modulate = SECONDARY_TEXT_COLOR
		return
	if controller.pulse_cell_count() <= 0:
		rifle_action_label.text = "步枪  ·  电池耗尽"
		rifle_action_label.modulate = AMMO_WARNING_COLOR
		return
	rifle_action_label.text = "步枪  ·  电池 %d  ·  LMB" % (
		controller.pulse_cell_count()
	)
	rifle_action_label.modulate = PRIMARY_TEXT_COLOR


func _process(_delta: float) -> void:
	if _world == null or _player == null:
		return
	var input_is_blocked: bool = _world.is_combat_input_blocked()
	_set_context_weight(input_is_blocked)
	if _world.is_placement_active():
		_show_placement_prompt()
		combat_action_panel.visible = false
		return
	if input_is_blocked:
		prompt_panel.visible = false
		prompt_label.visible = false
		combat_action_panel.visible = false
		return
	var target := _player.current_interact_target()
	var prompt := "" if target == null else str(target.get_prompt(_world))
	_set_prompt_layout(false)
	prompt_key_label.text = "E"
	prompt_meta_label.text = "交互"
	prompt_label.visible = not prompt.is_empty()
	prompt_panel.visible = prompt_label.visible
	prompt_label.text = _without_interact_prefix(prompt)
	combat_action_panel.visible = (
		enemy_panel.visible and not prompt_panel.visible
	)


func _show_placement_prompt() -> void:
	_set_prompt_layout(true)
	prompt_panel.visible = true
	prompt_label.visible = true
	prompt_key_label.text = "LMB"
	prompt_meta_label.text = "放置"
	var definition := SliceBuildingCatalog.find(
		_world.selected_building_id()
	)
	var remaining: int = (
		0
		if definition == null
		else _world.pocket.count(definition.kit_item_id)
	)
	var rotation_hint := (
		"  ·  R 旋转"
		if definition != null and definition.allows_rotation
		else ""
	)
	var logistics_feedback: String = (
		_world.placement_logistics_feedback()
	)
	if not logistics_feedback.is_empty():
		prompt_label.text = (
			"%s  ·  %s  ·  %s%s  ·  Esc 取消"
			% [
				_world.selected_building_name(),
				logistics_feedback,
				(
					"LMB 放置"
					if _world.is_place_target_valid()
					else _world.placement_invalid_reason()
				),
				rotation_hint,
			]
		)
		return
	if _world.is_place_target_valid():
		var auto_floor_count: int = (
			_world.placement_auto_floor_count()
		)
		var floor_text := (
			"  ·  自动铺地 %d 格" % auto_floor_count
			if auto_floor_count > 0
			else ""
		)
		prompt_label.text = (
			"放置 %s%s  ·  剩余 %d  ·  E 兼容%s  ·  Esc 取消"
			% [
				_world.selected_building_name(),
				floor_text,
				remaining,
				rotation_hint,
			]
		)
	else:
		prompt_label.text = (
			"%s  ·  剩余 %d  ·  %s%s  ·  Esc 取消"
			% [
				_world.selected_building_name(),
				remaining,
				_world.placement_invalid_reason(),
				rotation_hint,
			]
		)


func _refresh_notice() -> void:
	var notice_text: String = _world.combat_controller.notice_text
	if notice_text.is_empty():
		notice_panel.visible = false
		notice_label.text = ""
		return
	var is_danger := (
		notice_text.begins_with("受到")
		or notice_text.begins_with("生命归零")
	)
	var is_ammo_warning := (
		notice_text.begins_with("电池耗尽")
		or notice_text.begins_with("未持有")
		or notice_text.begins_with("步枪不在")
		or notice_text.begins_with("步枪已离开")
	)
	notice_accent.color = (
		DANGER_COLOR
		if is_danger
		else AMMO_WARNING_COLOR if is_ammo_warning else ACCENT_COLOR
	)
	if notice_text.begins_with("受到"):
		notice_label.text = "%s  ·  生命 %d/%d" % [
			notice_text,
			_world.combat_controller.health,
			_world.combat_controller.max_health,
		]
	elif notice_text == "闪避成功":
		notice_label.text = "闪避成功  ·  %s" % (
			_world.combat_controller.dodge_status_text()
		)
	else:
		notice_label.text = notice_text
	notice_panel.visible = true


func _set_prompt_layout(wide: bool) -> void:
	if wide:
		prompt_panel.offset_left = -390.0
		prompt_panel.offset_right = 924.0
		prompt_label.offset_right = 1294.0
		return
	prompt_panel.offset_left = -360.0
	prompt_panel.offset_right = 360.0
	prompt_label.offset_right = 700.0


func _set_context_weight(dimmed: bool) -> void:
	if _context_is_dimmed == dimmed:
		return
	_context_is_dimmed = dimmed
	var hud_color := DIMMED_HUD_COLOR if dimmed else ACTIVE_HUD_COLOR
	for component: CanvasItem in [
		left_status_panel,
		right_status_panel,
		player_status_panel,
		enemy_panel,
		notice_panel,
		combat_action_panel,
	]:
		component.modulate = hud_color


func _without_interact_prefix(prompt: String) -> String:
	if prompt.begins_with("按 E "):
		return prompt.trim_prefix("按 E ")
	return prompt
