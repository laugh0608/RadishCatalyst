class_name SlicePulseProjectile
extends Area2D

## One visible, fixed pulse shot. The combat controller owns damage and
## inventory; this node owns only travel, collision and range expiry.

const SPEED := 720.0
const MAX_RANGE := 320.0

var travel_direction := Vector2.RIGHT
var distance_travelled := 0.0
var _combat_controller: SliceCombatController
var _spent := false

@onready var sprite: Sprite2D = $Sprite


func setup(
	combat_controller: SliceCombatController,
	direction: Vector2,
	spawn_position: Vector2
) -> void:
	_combat_controller = combat_controller
	travel_direction = (
		direction.normalized() if direction != Vector2.ZERO else Vector2.DOWN
	)
	global_position = spawn_position
	_refresh_direction_frame()


func _ready() -> void:
	body_entered.connect(_on_body_entered)
	_refresh_direction_frame()


func _physics_process(delta: float) -> void:
	if _spent or delta <= 0.0:
		return
	var remaining := MAX_RANGE - distance_travelled
	var step := minf(SPEED * delta, remaining)
	global_position += travel_direction * step
	distance_travelled += step
	if distance_travelled >= MAX_RANGE:
		_spent = true
		queue_free()


func _on_body_entered(body: Node2D) -> void:
	if _spent or body == null:
		return
	if _combat_controller != null and body == _combat_controller.player_actor():
		return
	_spent = true
	if _combat_controller != null:
		_combat_controller.call_deferred(
			"resolve_pulse_projectile_collision", body
		)
	queue_free()


func _refresh_direction_frame() -> void:
	if sprite == null:
		return
	if (
		travel_direction.y < 0.0
		and -travel_direction.y >= absf(travel_direction.x)
	):
		sprite.frame = 2
	elif absf(travel_direction.x) >= absf(travel_direction.y):
		sprite.frame = 0 if travel_direction.x > 0.0 else 1
	else:
		sprite.frame = 3
