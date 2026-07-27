class_name SliceCombatController
extends Node2D

## Package-1 combat runtime: owns player health, attack timing, dodge timing,
## invulnerability and approved effect playback. Enemy and sample business
## remain outside this controller until package 2.

const ATTACK_WINDUP := 0.12
const ATTACK_ACTIVE := 0.10
const ATTACK_RECOVERY := 0.23
const DODGE_DISTANCE := 96.0
const DODGE_DURATION := 0.18
const DODGE_INVULNERABLE := 0.22
const DODGE_COOLDOWN := 0.8

signal state_changed

var health := 100
var max_health := 100
var attack_phase := "idle"
var attack_phase_remaining := 0.0
var dodge_cooldown_remaining := 0.0
var invulnerable_remaining := 0.0

var _world: Node
var _player: SlicePlayer
var _attack_held := false
var _requires_fresh_attack_press := false
var _last_state_key := ""

@onready var _attack_pivot: Node2D = $AttackPivot
@onready var _attack_effect: Sprite2D = $AttackPivot/AttackEffect
@onready var _attack_collision: CollisionShape2D = (
	$AttackPivot/AttackArea/Collision
)


func setup(world: Node, player: SlicePlayer) -> void:
	_world = world
	_player = player
	player.attack_pressed.connect(_on_attack_pressed)
	player.attack_released.connect(_on_attack_released)
	player.dodge_requested.connect(_on_dodge_requested)
	_refresh_effect_transform()
	_emit_state_if_changed()


func _physics_process(delta: float) -> void:
	if _world == null or _player == null:
		return
	_refresh_effect_transform()
	dodge_cooldown_remaining = maxf(
		0.0, dodge_cooldown_remaining - delta
	)
	invulnerable_remaining = maxf(0.0, invulnerable_remaining - delta)
	if _world.is_combat_input_blocked():
		_attack_held = false
		_requires_fresh_attack_press = true
		if attack_phase == "windup":
			_finish_attack()
	_tick_attack(delta)
	_emit_state_if_changed()


func _on_attack_pressed() -> void:
	_requires_fresh_attack_press = false
	_attack_held = true
	if _can_start_attack():
		_begin_attack()


func _on_attack_released() -> void:
	_attack_held = false


func _on_dodge_requested() -> void:
	if (
		not _world.is_core_charged()
		or _world.is_combat_input_blocked()
		or dodge_cooldown_remaining > 0.0
		or _player.is_dodging()
	):
		return
	_attack_held = false
	_requires_fresh_attack_press = true
	var direction := _player.movement_input
	if direction == Vector2.ZERO:
		direction = _player.aim_direction
	if direction == Vector2.ZERO:
		direction = Vector2.DOWN
	_player.start_dodge(direction, DODGE_DISTANCE, DODGE_DURATION)
	dodge_cooldown_remaining = DODGE_COOLDOWN
	invulnerable_remaining = DODGE_INVULNERABLE
	if attack_phase != "active":
		_finish_attack()
	_emit_state_if_changed()


func _can_start_attack() -> bool:
	return (
		attack_phase == "idle"
		and _world != null
		and _world.is_core_charged()
		and not _world.is_combat_input_blocked()
		and not _requires_fresh_attack_press
		and not _player.is_dodging()
	)


func _begin_attack() -> void:
	attack_phase = "windup"
	attack_phase_remaining = ATTACK_WINDUP
	_attack_effect.visible = true
	_attack_effect.frame = 0
	_attack_collision.disabled = true


func _tick_attack(delta: float) -> void:
	if attack_phase == "idle":
		return
	attack_phase_remaining -= delta
	while attack_phase != "idle" and attack_phase_remaining <= 0.0:
		match attack_phase:
			"windup":
				attack_phase = "active"
				attack_phase_remaining += ATTACK_ACTIVE
				_attack_effect.frame = 1
				_attack_collision.disabled = false
			"active":
				attack_phase = "recovery"
				attack_phase_remaining += ATTACK_RECOVERY
				_attack_effect.frame = 2
				_attack_collision.disabled = true
			"recovery":
				if _attack_held and _can_repeat_attack():
					_begin_attack()
				else:
					_finish_attack()
	if (
		attack_phase == "recovery"
		and attack_phase_remaining <= ATTACK_RECOVERY * 0.45
	):
		_attack_effect.frame = 3


func _can_repeat_attack() -> bool:
	return (
		not _requires_fresh_attack_press
		and not _world.is_combat_input_blocked()
		and not _player.is_dodging()
	)


func _finish_attack() -> void:
	attack_phase = "idle"
	attack_phase_remaining = 0.0
	if _attack_effect != null:
		_attack_effect.visible = false
	if _attack_collision != null:
		_attack_collision.disabled = true


func _refresh_effect_transform() -> void:
	_attack_pivot.position = _player.position + Vector2(0, -32)
	_attack_pivot.rotation = _player.aim_direction.angle()


func can_receive_damage() -> bool:
	return invulnerable_remaining <= 0.0


func dodge_ready() -> bool:
	return dodge_cooldown_remaining <= 0.0


func dodge_status_text() -> String:
	if not _world.is_core_charged():
		return "未解锁"
	if dodge_ready():
		return "就绪"
	return "%.1fs" % dodge_cooldown_remaining


func attack_status_text() -> String:
	if not _world.is_core_charged():
		return "工具锁定"
	match attack_phase:
		"windup":
			return "预备"
		"active":
			return "切割"
		"recovery":
			return "恢复"
		_:
			return "工具就绪"


func _emit_state_if_changed() -> void:
	var state_key := "%d/%d|%s|%.2f|%.2f|%s" % [
		health,
		max_health,
		attack_phase,
		dodge_cooldown_remaining,
		invulnerable_remaining,
		_player.is_dodging(),
	]
	if state_key == _last_state_key:
		return
	_last_state_key = state_key
	state_changed.emit()
