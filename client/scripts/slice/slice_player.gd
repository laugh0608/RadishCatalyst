class_name SlicePlayer
extends CharacterBody2D

## Slice player locomotion and combat intentions. Movement and continuous
## mouse aim are independent: movement controls velocity and the existing
## building target direction, while aim selects the four-direction player art
## and emits unconsumed attack / dodge intentions to SliceCombatController.

const MOVE_SPEED := 140.0

signal attack_pressed
signal attack_released
signal dodge_requested
signal weapon_selection_requested(weapon_id: String)

var world: Node
## Last non-zero facing, used by SliceWorld to pick the building target cells.
var facing := Vector2.DOWN
var aim_direction := Vector2.DOWN
var movement_input := Vector2.ZERO
var _dodge_remaining := 0.0
var _dodge_velocity := Vector2.ZERO

@onready var sprite: AnimatedSprite2D = $Sprite
@onready var rifle_sprite: Sprite2D = $RifleSprite
@onready var interact_scan: Area2D = $InteractScan


func _physics_process(delta: float) -> void:
	movement_input = Input.get_vector(
		"move_left", "move_right", "move_up", "move_down"
	)
	_refresh_aim_direction()
	if _dodge_remaining > 0.0:
		_dodge_remaining = maxf(0.0, _dodge_remaining - delta)
		velocity = _dodge_velocity
	else:
		velocity = movement_input * MOVE_SPEED
	move_and_slide()
	if movement_input != Vector2.ZERO and _dodge_remaining <= 0.0:
		facing = movement_input.normalized()
	_update_animation(
		movement_input != Vector2.ZERO or _dodge_remaining > 0.0,
		aim_direction
	)
	if Input.is_action_just_pressed("interact"):
		if world != null and world.is_placement_active():
			world.try_place_building()
			return
		var target := current_interact_target()
		if target != null and world != null:
			target.try_interact(world)


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("select_cutter"):
		_request_weapon_selection(SliceCombatController.WEAPON_CUTTER)
		return
	if event.is_action_pressed("select_pulse_rifle"):
		_request_weapon_selection(SliceCombatController.WEAPON_PULSE_RIFLE)
		return
	if event.is_action_pressed("attack"):
		if world == null or not world.is_combat_input_blocked():
			attack_pressed.emit()
			get_viewport().set_input_as_handled()
		return
	if event.is_action_released("attack"):
		attack_released.emit()
		return
	if event.is_action_pressed("dodge"):
		if world == null or not world.is_combat_input_blocked():
			dodge_requested.emit()
			get_viewport().set_input_as_handled()


func _request_weapon_selection(weapon_id: String) -> void:
	if world != null and world.is_combat_input_blocked():
		return
	weapon_selection_requested.emit(weapon_id)
	get_viewport().set_input_as_handled()


func set_weapon_visual(weapon_id: String) -> void:
	var rifle_selected := (
		weapon_id == SliceCombatController.WEAPON_PULSE_RIFLE
	)
	sprite.visible = not rifle_selected
	rifle_sprite.visible = rifle_selected
	_refresh_weapon_visual(aim_direction)


func start_dodge(direction: Vector2, distance: float, duration: float) -> void:
	if direction == Vector2.ZERO or duration <= 0.0:
		return
	_dodge_remaining = duration
	_dodge_velocity = direction.normalized() * distance / duration


func is_dodging() -> bool:
	return _dodge_remaining > 0.0


func cancel_dodge() -> void:
	_dodge_remaining = 0.0
	_dodge_velocity = Vector2.ZERO


func current_interact_target() -> Area2D:
	var best: Area2D = null
	var best_dist := INF
	var best_priority := -1
	for area in interact_scan.get_overlapping_areas():
		if not area.has_method("try_interact"):
			continue
		var priority := (
			int(area.get_interaction_priority())
			if area.has_method("get_interaction_priority")
			else 0
		)
		var dist := global_position.distance_squared_to(area.global_position)
		if priority > best_priority or (priority == best_priority and dist < best_dist):
			best = area
			best_dist = dist
			best_priority = priority
	return best


func _refresh_aim_direction() -> void:
	var visual_origin := global_position + Vector2(0, -32)
	var candidate := get_global_mouse_position() - visual_origin
	if candidate.length_squared() > 1.0:
		aim_direction = candidate.normalized()


func _update_animation(moving: bool, visual_facing: Vector2) -> void:
	if rifle_sprite.visible:
		_refresh_weapon_visual(visual_facing)
		return
	if not moving:
		_play_directional_idle(visual_facing)
		return

	if visual_facing.y < 0.0 and -visual_facing.y >= absf(visual_facing.x):
		sprite.play("walk_up")
		sprite.flip_h = false
	elif absf(visual_facing.x) >= absf(visual_facing.y):
		sprite.play("walk")
		sprite.flip_h = visual_facing.x > 0.0
	else:
		sprite.play("walk_down")
		sprite.flip_h = false


func _play_directional_idle(visual_facing: Vector2 = aim_direction) -> void:
	if visual_facing.y < 0.0 and -visual_facing.y >= absf(visual_facing.x):
		sprite.play("idle_up")
		sprite.flip_h = false
	elif absf(visual_facing.x) >= absf(visual_facing.y):
		sprite.play("idle_side")
		sprite.flip_h = visual_facing.x > 0.0
	else:
		sprite.play("idle")
		sprite.flip_h = false


func _refresh_weapon_visual(visual_facing: Vector2) -> void:
	if not rifle_sprite.visible:
		return
	if visual_facing.y < 0.0 and -visual_facing.y >= absf(visual_facing.x):
		rifle_sprite.frame = 2
	elif absf(visual_facing.x) >= absf(visual_facing.y):
		rifle_sprite.frame = 0 if visual_facing.x > 0.0 else 1
	else:
		rifle_sprite.frame = 3
