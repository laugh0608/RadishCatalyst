extends CharacterBody3D

const Parts := preload("res://geometry.gd")
const SPEED := 3.0
var camera: Camera3D
var model := Node3D.new()
var left_leg := Node3D.new()
var right_leg := Node3D.new()
var phase := 0.0


func _ready() -> void:
	var collision := CollisionShape3D.new()
	var capsule := CapsuleShape3D.new()
	capsule.radius = 0.23
	capsule.height = 1.55
	collision.shape = capsule
	collision.position.y = 0.775
	add_child(collision)
	add_child(model)
	var suit := Parts.material("d7a34e", 0.05, 0.75)
	var dark := Parts.material("293b40", 0.1, 0.65)
	var visor := Parts.material("253f4b", 0.4, 0.18)
	var pale := Parts.material("dfdcc7", 0.15, 0.45)
	Parts.sphere(model, Vector3(0, 0.84, 0), Vector3(0.58, 0.68, 0.38), suit)
	Parts.box(model, Vector3(0, 0.88, 0.23), Vector3(0.39, 0.45, 0.22), dark)
	Parts.sphere(model, Vector3(0, 1.31, 0), Vector3(0.53, 0.48, 0.49), pale)
	Parts.sphere(model, Vector3(0, 1.31, -0.17), Vector3(0.44, 0.25, 0.21), visor)
	Parts.box(model, Vector3(0, 0.8, -0.21), Vector3(0.3, 0.16, 0.04), pale)
	for side in [-1.0, 1.0]:
		Parts.sphere(model, Vector3(side * 0.35, 0.84, 0), Vector3(0.22, 0.48, 0.24), suit)
		Parts.sphere(model, Vector3(side * 0.36, 0.59, -0.03), Vector3(0.19, 0.19, 0.2), dark)
	for leg: Node3D in [left_leg, right_leg]:
		model.add_child(leg)
		leg.position = Vector3(-0.15 if leg == left_leg else 0.15, 0.56, 0)
		Parts.box(leg, Vector3(0, -0.19, 0), Vector3(0.22, 0.37, 0.26), dark)
		Parts.box(leg, Vector3(0, -0.46, -0.06), Vector3(0.24, 0.17, 0.38), dark)


func _physics_process(delta: float) -> void:
	var input := Input.get_vector("left", "right", "up", "down")
	var right := camera.global_basis.x
	var forward := camera.global_basis.z
	right.y = 0
	forward.y = 0
	var direction := (right.normalized() * input.x + forward.normalized() * input.y)
	velocity.x = direction.x * SPEED
	velocity.z = direction.z * SPEED
	velocity.y -= 18.0 * delta
	move_and_slide()
	if direction.length_squared() > 0.001:
		model.rotation.y = lerp_angle(model.rotation.y, atan2(-direction.x, -direction.z), 12.0 * delta)
		phase += delta * 11.0
	else:
		phase = 0.0
	left_leg.rotation.x = sin(phase) * 0.42
	right_leg.rotation.x = -sin(phase) * 0.42
	position.x = clampf(position.x, -6.8, 6.8)
	position.z = clampf(position.z, -4.8, 4.8)
