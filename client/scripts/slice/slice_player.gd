class_name SlicePlayer
extends CharacterBody2D

## Slice base first screen player: free 8-way movement on the 32px grid
## world. Side walk uses the 4-frame single-direction cycle with horizontal
## flip for left / right; vertical movement uses dedicated back / front
## 4-frame cycles; the static d1 frame plays when idle. Interactables
## (crystal nodes, core repair site) are picked up by the InteractScan area;
## `world` is injected by SliceWorld and passed through to targets.

const MOVE_SPEED := 140.0

var world: Node
## Last non-zero facing, used by SliceWorld to pick the collector place cell.
var facing := Vector2.DOWN

@onready var sprite: AnimatedSprite2D = $Sprite
@onready var interact_scan: Area2D = $InteractScan


func _physics_process(_delta: float) -> void:
	var input := Input.get_vector("move_left", "move_right", "move_up", "move_down")
	velocity = input * MOVE_SPEED
	move_and_slide()
	if input != Vector2.ZERO:
		facing = input.normalized()
	_update_animation(input)
	if Input.is_action_just_pressed("interact"):
		# Carrying a collector: interact places it; otherwise it drives the
		# nearest interactable (harvest, repair, workbench build).
		if world != null and world.carrying_collector:
			world.try_place_collector()
			return
		var target := current_interact_target()
		if target != null and world != null:
			target.try_interact(world)


func current_interact_target() -> Area2D:
	var best: Area2D = null
	var best_dist := INF
	for area in interact_scan.get_overlapping_areas():
		if not area.has_method("try_interact"):
			continue
		var dist := global_position.distance_squared_to(area.global_position)
		if dist < best_dist:
			best = area
			best_dist = dist
	return best


func _update_animation(input: Vector2) -> void:
	if input == Vector2.ZERO:
		sprite.play("idle")
		return

	# The side sheet is drawn leaning toward the viewer (3/4 front), so it
	# reads as downward-diagonal motion: upward diagonals therefore prefer
	# the back-view cycle, downward diagonals keep the side cycle.
	if input.y < 0.0 and -input.y >= absf(input.x):
		sprite.play("walk_up")
		sprite.flip_h = false
	elif absf(input.x) >= absf(input.y):
		sprite.play("walk")
		# Side source frames face left; flip to express rightward movement.
		sprite.flip_h = input.x > 0.0
	else:
		sprite.play("walk_down")
		sprite.flip_h = false
