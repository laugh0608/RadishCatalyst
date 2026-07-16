class_name SlicePlayer
extends CharacterBody2D

## Slice base first screen player: free 8-way movement on the 32px grid
## world, 4-frame single-direction walk cycle with horizontal flip for
## left / right facing, static d1 frame when idle.

const MOVE_SPEED := 140.0

@onready var sprite: AnimatedSprite2D = $Sprite


func _physics_process(_delta: float) -> void:
	var input := Input.get_vector("move_left", "move_right", "move_up", "move_down")
	velocity = input * MOVE_SPEED
	move_and_slide()
	_update_animation(input)


func _update_animation(input: Vector2) -> void:
	if input == Vector2.ZERO:
		sprite.play("idle")
		return

	sprite.play("walk")
	# Source frames face left; flip to express rightward movement.
	if input.x != 0.0:
		sprite.flip_h = input.x > 0.0
