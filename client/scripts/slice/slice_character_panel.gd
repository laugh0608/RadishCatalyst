class_name SliceCharacterPanel
extends Control

## Minimal one-slot character equipment surface. Combat remains the authority;
## this panel only exposes click and drag equivalents for the existing weapons.

var _world: Node
var _open := false

@onready var _open_button: Button = $OpenButton
@onready var _window: Control = $Window
@onready var _close_button: Button = $Window/Panel/Margin/Layout/Header/Close
@onready var _slot: PanelContainer = $Window/Panel/Margin/Layout/EquippedSlot
@onready var _slot_icon: TextureRect = (
	$Window/Panel/Margin/Layout/EquippedSlot/Margin/Row/Icon
)
@onready var _slot_name: Label = (
	$Window/Panel/Margin/Layout/EquippedSlot/Margin/Row/Identity/Name
)
@onready var _slot_state: Label = (
	$Window/Panel/Margin/Layout/EquippedSlot/Margin/Row/Identity/State
)
@onready var _cutter_button: Button = (
	$Window/Panel/Margin/Layout/Available/Cutter
)
@onready var _rifle_button: Button = (
	$Window/Panel/Margin/Layout/Available/Rifle
)
@onready var _missing_rifle: Label = (
	$Window/Panel/Margin/Layout/Available/MissingRifle
)
@onready var _cutter_icon: Texture2D = _cutter_button.icon
@onready var _rifle_icon: Texture2D = _rifle_button.icon


func setup(world: Node) -> void:
	_world = world
	_open_button.pressed.connect(open)
	_close_button.pressed.connect(close)
	_cutter_button.pressed.connect(
		_equip.bind(SliceCombatController.WEAPON_CUTTER)
	)
	_rifle_button.pressed.connect(
		_equip.bind(SliceCombatController.WEAPON_PULSE_RIFLE)
	)
	_cutter_button.set_drag_forwarding(
		_drag_weapon.bind(SliceCombatController.WEAPON_CUTTER),
		_never_can_drop,
		_ignore_drop
	)
	_rifle_button.set_drag_forwarding(
		_drag_weapon.bind(SliceCombatController.WEAPON_PULSE_RIFLE),
		_never_can_drop,
		_ignore_drop
	)
	_slot.set_drag_forwarding(
		_no_drag_data,
		_can_drop_weapon,
		_drop_weapon
	)
	world.inventory_changed.connect(_refresh)
	world.combat_controller.state_changed.connect(_refresh)
	_window.visible = false
	_refresh()


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("character_menu"):
		if _open:
			close()
		else:
			open()
		get_viewport().set_input_as_handled()
	elif _open and event.is_action_pressed("ui_cancel"):
		close()
		get_viewport().set_input_as_handled()


func open() -> void:
	if (
		_open
		or _world == null
		or get_tree().paused
		or _world.is_combat_input_blocked()
		or _world.is_placement_active()
	):
		return
	_open = true
	_window.visible = true
	get_tree().paused = true
	_refresh()


func close() -> void:
	if not _open:
		return
	_open = false
	_window.visible = false
	get_tree().paused = false


func is_open() -> bool:
	return _open


func _equip(weapon_id: String) -> void:
	if _world.combat_controller.equip_weapon(weapon_id):
		_refresh()


func _refresh(_changed_value = null) -> void:
	if _world == null:
		return
	var controller: SliceCombatController = _world.combat_controller
	var rifle_owned := controller.has_pulse_rifle()
	var rifle_equipped := (
		controller.current_weapon
		== SliceCombatController.WEAPON_PULSE_RIFLE
	)
	_slot_icon.texture = _rifle_icon if rifle_equipped else _cutter_icon
	_slot_name.text = "前哨脉冲步枪" if rifle_equipped else "工程切割器"
	_slot_state.text = (
		"已装备 · 电池 %d" % controller.pulse_cell_count()
		if rifle_equipped
		else "已装备 · 内建工具不可移除"
	)
	_cutter_button.text = "切割器 · %s" % (
		"已装备" if not rifle_equipped else "点击装备"
	)
	_rifle_button.visible = rifle_owned
	_rifle_button.disabled = not rifle_owned
	_rifle_button.text = "脉冲步枪 · %s" % (
		"已装备" if rifle_equipped else "点击装备"
	)
	_missing_rifle.visible = not rifle_owned


func _drag_weapon(_position: Vector2, weapon_id: String) -> Variant:
	if (
		weapon_id == SliceCombatController.WEAPON_PULSE_RIFLE
		and not _world.combat_controller.has_pulse_rifle()
	):
		return null
	var preview := Label.new()
	preview.text = "  %s  " % (
		"脉冲步枪"
		if weapon_id == SliceCombatController.WEAPON_PULSE_RIFLE
		else "工程切割器"
	)
	set_drag_preview(preview)
	return {"weapon_id": weapon_id}


func _no_drag_data(_position: Vector2) -> Variant:
	return null


func _never_can_drop(_position: Vector2, _data: Variant) -> bool:
	return false


func _ignore_drop(_position: Vector2, _data: Variant) -> void:
	pass


func _can_drop_weapon(_position: Vector2, data: Variant) -> bool:
	return (
		data is Dictionary
		and String(data.get("weapon_id", "")) in [
			SliceCombatController.WEAPON_CUTTER,
			SliceCombatController.WEAPON_PULSE_RIFLE,
		]
	)


func _drop_weapon(_position: Vector2, data: Variant) -> void:
	_equip(String(data.get("weapon_id", "")))
