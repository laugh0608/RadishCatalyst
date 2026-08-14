class_name SliceFieldEnemy
extends CharacterBody2D

## Fixed package-2 encounter actor. It owns only local movement, readable AI
## phases and health; the combat controller owns encounter/sample transitions.

const MAX_HEALTH := 60
const CHASE_SPEED := 80.0
const ALERT_RANGE := 220.0
const LEASH_RANGE := 320.0
const ATTACK_RANGE := 58.0
const ATTACK_DAMAGE := 20
const TELEGRAPH_DURATION := 0.4
const RECOVERY_DURATION := 0.8
const HIT_DURATION := 0.14

signal state_changed
signal attack_landed(damage: int)
signal defeated

var health := MAX_HEALTH
var state := "locked"
var anchor_position := Vector2.ZERO

var _player: SlicePlayer
var _state_remaining := 0.0
var _return_after_hit := "chase"
var _last_state_key := ""

@onready var sprite: Sprite2D = $Sprite
@onready var collision: CollisionShape2D = $Collision


func setup(player: SlicePlayer, anchor: Vector2, enabled: bool) -> void:
	_player = player
	anchor_position = anchor
	position = anchor
	set_encounter_enabled(enabled)


func _physics_process(delta: float) -> void:
	if _player == null or state in ["locked", "defeated"]:
		return
	match state:
		"alert":
			velocity = Vector2.ZERO
			if _player.global_position.distance_to(global_position) <= ALERT_RANGE:
				_set_state("chase")
		"chase":
			_tick_chase()
		"telegraph":
			velocity = Vector2.ZERO
			_state_remaining -= delta
			if _state_remaining <= 0.0:
				_finish_telegraph()
		"recovery":
			velocity = Vector2.ZERO
			_state_remaining -= delta
			if _state_remaining <= 0.0:
				_set_state("chase")
		"hit":
			velocity = Vector2.ZERO
			_state_remaining -= delta
			if _state_remaining <= 0.0:
				_set_state(_return_after_hit)
		"return":
			_tick_return()
	move_and_slide()
	_refresh_sprite()
	_emit_state_if_changed()


func set_encounter_enabled(enabled: bool) -> void:
	if state == "defeated":
		return
	if enabled:
		visible = true
		collision.disabled = false
		if state == "locked":
			_set_state("alert")
	else:
		visible = false
		collision.disabled = true
		_set_state("locked")


func take_damage(amount: int) -> bool:
	if amount <= 0 or state in ["locked", "defeated"]:
		return false
	health = maxi(0, health - amount)
	if health <= 0:
		velocity = Vector2.ZERO
		collision.set_deferred("disabled", true)
		_set_state("defeated")
		defeated.emit()
		return true
	_return_after_hit = (
		"return"
		if state == "return"
		else "chase"
	)
	_state_remaining = HIT_DURATION
	_set_state("hit")
	return true


func reset_after_evacuation() -> void:
	if state == "defeated":
		return
	position = anchor_position
	velocity = Vector2.ZERO
	health = MAX_HEALTH
	_set_state("alert")


func restore_durable_state(
	encounter_state: String,
	saved_health: int
) -> void:
	position = anchor_position
	velocity = Vector2.ZERO
	match encounter_state:
		"locked":
			health = saved_health
			visible = false
			collision.disabled = true
			_set_state("locked")
		"hostile":
			health = saved_health
			visible = true
			collision.disabled = false
			_set_state("alert")
		_:
			health = 0
			visible = true
			collision.disabled = true
			_set_state("defeated")


func state_text() -> String:
	match state:
		"alert":
			return "警戒"
		"chase":
			return "追击"
		"telegraph":
			return "蓄势"
		"recovery":
			return "恢复"
		"hit":
			return "受击"
		"return":
			return "回巢"
		"defeated":
			return "败亡"
		_:
			return "未激活"


func is_hud_visible() -> bool:
	if _player == null or state in ["locked", "defeated"]:
		return false
	return (
		state in ["chase", "telegraph", "recovery", "hit", "return"]
		or _player.global_position.distance_to(global_position) <= ALERT_RANGE
	)


func _tick_chase() -> void:
	if _player.global_position.distance_to(anchor_position) > LEASH_RANGE:
		_set_state("return")
		return
	var offset := _player.global_position - global_position
	if offset.length() <= ATTACK_RANGE:
		_set_state("telegraph")
		_state_remaining = TELEGRAPH_DURATION
		return
	velocity = offset.normalized() * CHASE_SPEED


func _finish_telegraph() -> void:
	var in_range := (
		_player.global_position.distance_to(global_position)
		<= ATTACK_RANGE + 10.0
	)
	_set_state("recovery")
	_state_remaining = RECOVERY_DURATION
	if in_range:
		attack_landed.emit(ATTACK_DAMAGE)


func _tick_return() -> void:
	var offset := anchor_position - position
	if offset.length() <= 4.0:
		position = anchor_position
		velocity = Vector2.ZERO
		health = MAX_HEALTH
		_set_state("alert")
		return
	velocity = offset.normalized() * CHASE_SPEED


func _set_state(next_state: String) -> void:
	if state == next_state:
		return
	state = next_state
	_refresh_sprite()
	_emit_state_if_changed()


func _refresh_sprite() -> void:
	if state == "defeated":
		sprite.frame = 12
		sprite.flip_h = false
		return
	var direction := (
		_player.global_position - global_position
		if _player != null
		else Vector2.DOWN
	)
	var row := 0
	if direction.y < 0.0 and -direction.y >= absf(direction.x):
		row = 2
		sprite.flip_h = false
	elif absf(direction.x) >= absf(direction.y):
		row = 1
		sprite.flip_h = direction.x > 0.0
	else:
		row = 0
		sprite.flip_h = false
	var column := 0
	match state:
		"telegraph":
			column = 1
		"recovery":
			column = 2
		"hit":
			column = 3
	sprite.frame = row * 4 + column


func _emit_state_if_changed() -> void:
	var state_key := "%s|%d" % [state, health]
	if state_key == _last_state_key:
		return
	_last_state_key = state_key
	state_changed.emit()
