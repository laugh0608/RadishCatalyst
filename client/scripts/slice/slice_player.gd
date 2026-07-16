class_name SlicePlayer
extends CharacterBody2D

## Slice base first screen player: free 8-way movement on the 32px grid
## world. Side walk uses the 4-frame single-direction cycle with horizontal
## flip for left / right; vertical movement uses dedicated back / front
## 4-frame cycles; the static d1 frame plays when idle.

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
