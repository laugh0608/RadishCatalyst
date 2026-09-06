extends Node3D

const Parts := preload("res://geometry.gd")
var glass_parts: Array[MeshInstance3D] = []
var liquid_parts: Array[MeshInstance3D] = []
var glass := Parts.material("b1e0dc", 0.05, 0.13)
var opaque := Parts.material("82afac", 0.25, 0.3)
var steel := Parts.material("789291", 0.65, 0.32)
var dark := Parts.material("253c42", 0.5, 0.55)
var paint := Parts.material("477476", 0.22, 0.48)
var pale := Parts.material("ccd0ba", 0.2, 0.48)
var amber := Parts.material("d7a047", 0.25, 0.5)
var liquid_mat := Parts.material("168d9a", 0.25, 0.2)


func _ready() -> void:
	glass.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	glass.albedo_color.a = 0.17
	_build_floor()
	_build_machine()
	_build_pipes()


func _build_floor() -> void:
	Parts.box(self, Vector3(0, -0.26, 0), Vector3(14, 0.44, 10), Parts.material("777d74"))
	Parts.collider(self, Vector3(0, -0.24, 0), Vector3(14, 0.48, 10))
	var floor_a := Parts.material("93978a", 0.0, 0.95)
	var floor_b := Parts.material("8c9186", 0.0, 0.95)
	for x in 7:
		for z in 5:
			Parts.box(self, Vector3(-6 + x * 2, -0.02, -4 + z * 2), Vector3(1.982, 0.04, 1.982), floor_a if (x + z) % 3 else floor_b)
	var line := Parts.material("c1b888", 0.0, 0.9)
	for x in 12:
		Parts.box(self, Vector3(-5.5 + x, 0.005, 3.35), Vector3(0.48, 0.009, 0.075), line)
	for z in [-3.8, 3.8]:
		Parts.box(self, Vector3(0, 0.005, z), Vector3(12.3, 0.009, 0.05), line)


func _build_machine() -> void:
	var machine := Node3D.new()
	machine.name = "Reactor"
	add_child(machine)
	machine.position = Vector3(-3.15, 0, -0.8)
	Parts.box(machine, Vector3(0, 0.16, 0), Vector3(3.0, 0.28, 2.65), dark)
	Parts.box(machine, Vector3(0, 0.36, 0), Vector3(2.8, 0.15, 2.45), steel)
	Parts.collider(machine, Vector3(0, 1.4, 0), Vector3(2.9, 2.8, 2.5))
	for x in [-1.12, 1.12]:
		for z in [-0.93, 0.93]:
			Parts.box(machine, Vector3(x, 0.11, z), Vector3(0.46, 0.22, 0.5), steel)
			Parts.box(machine, Vector3(x, 1.26, z), Vector3(0.15, 1.82, 0.15), dark)
	Parts.cylinder(machine, Vector3(-0.22, 1.5, 0), 0.92, 1.75, paint)
	Parts.sphere(machine, Vector3(-0.22, 2.35, 0), Vector3(1.84, 0.52, 1.84), pale)
	Parts.sphere(machine, Vector3(-0.22, 0.64, 0), Vector3(1.84, 0.48, 1.84), steel)
	for y in [0.72, 2.22]:
		Parts.cylinder(machine, Vector3(-0.22, y, 0), 0.95, 0.12, steel)
	Parts.cylinder(machine, Vector3(-0.22, 2.63, 0), 0.52, 0.13, dark)
	Parts.cylinder(machine, Vector3(-0.22, 2.73, 0), 0.47, 0.09, steel)
	for i in 8:
		var angle := TAU * float(i) / 8.0
		Parts.cylinder(machine, Vector3(-0.22 + cos(angle) * 0.39, 2.8, sin(angle) * 0.39), 0.045, 0.07, pale)
	Parts.box(machine, Vector3(0.9, 1.28, 0.55), Vector3(0.72, 1.6, 0.67), paint)
	Parts.box(machine, Vector3(0.9, 1.3, 0.9), Vector3(0.58, 1.3, 0.04), pale)
	Parts.box(machine, Vector3(0.9, 1.67, 0.94), Vector3(0.43, 0.28, 0.045), dark)
	var lamp := Parts.material("72cbbb", 0.1, 0.2)
	lamp.emission_enabled = true
	lamp.emission = Color("53b8a6")
	lamp.emission_energy_multiplier = 0.4
	Parts.box(machine, Vector3(0.9, 1.67, 0.97), Vector3(0.3, 0.12, 0.01), lamp)
	for y in [0.86, 0.98, 1.1]:
		Parts.box(machine, Vector3(0.9, y, 0.93), Vector3(0.4, 0.025, 0.025), dark)
	Parts.box(machine, Vector3(-0.3, 1.64, 0.9), Vector3(0.62, 0.35, 0.11), dark)
	Parts.box(machine, Vector3(-0.3, 1.64, 0.963), Vector3(0.48, 0.23, 0.02), amber)
	# Service pipes and a safety hoop provide overlapping silhouettes at the same light angle.
	for x in [-0.95, 0.45]:
		Parts.cylinder(machine, Vector3(x, 1.35, -0.82), 0.08, 1.45, steel)
	var wheel := Parts.ring(machine, Vector3(0.0, 1.22, 1.11), 0.18, 0.24, amber)
	wheel.rotation.x = PI / 2
	Parts.box(machine, Vector3(0, 1.22, 1.11), Vector3(0.4, 0.035, 0.035), amber)
	Parts.box(machine, Vector3(0, 1.22, 1.11), Vector3(0.035, 0.4, 0.035), amber)


func _build_pipes() -> void:
	# Pipe centerline is 2.05 m; a character can pass beneath straight spans.
	for pair in [Vector2(-1.7, -0.35), Vector2(-0.35, 1.2), Vector2(1.2, 2.75)]:
		_span(Vector3((pair.x + pair.y) / 2.0, 2.05, -0.8), pair.y - pair.x, false)
	for x in [-1.7, -0.35, 1.2, 2.75]:
		_flange(Vector3(x, 2.05, -0.8), false)
	for x in [-0.35, 2.75]:
		_support(Vector3(x, 0, -0.8), false)
	# Cast elbow is deliberately opaque; no intersecting transparent elbow surfaces.
	var corner := Node3D.new()
	add_child(corner)
	corner.position = Vector3(2.75, 2.05, -0.8)
	Parts.sphere(corner, Vector3.ZERO, Vector3(0.73, 0.73, 0.73), steel)
	for pair in [Vector2(-0.8, 0.85), Vector2(0.85, 2.5)]:
		_span(Vector3(2.75, 2.05, (pair.x + pair.y) / 2.0), pair.y - pair.x, true)
	for z in [-0.8, 0.85, 2.5]:
		_flange(Vector3(2.75, 2.05, z), true)
	_support(Vector3(2.75, 0, 2.5), true)
	# Terminal has a rim and open bore, not a solid end cap.
	var end := Parts.ring(self, Vector3(2.75, 2.05, 2.56), 0.30, 0.4, pale)
	end.rotation.x = PI / 2


func _span(at: Vector3, length: float, longitudinal: bool) -> void:
	var span := Node3D.new()
	add_child(span)
	span.position = at
	if longitudinal:
		span.rotation.y = -PI / 2
	glass_parts.append(Parts.tube(span, length - 0.08, glass))
	liquid_parts.append(Parts.liquid(span, length - 0.06, liquid_mat))
	Parts.collider(span, Vector3.ZERO, Vector3(length, 0.66, 0.66))


func _flange(at: Vector3, longitudinal: bool) -> void:
	var flange := Node3D.new()
	add_child(flange)
	flange.position = at
	flange.rotation.z = PI / 2
	if longitudinal:
		flange.rotation = Vector3(PI / 2, 0, 0)
	Parts.ring(flange, Vector3.ZERO, 0.295, 0.43, steel)
	for i in 6:
		var angle := TAU * float(i) / 6.0
		Parts.cylinder(flange, Vector3(cos(angle) * 0.37, 0, sin(angle) * 0.37), 0.042, 0.17, pale)


func _support(at: Vector3, longitudinal: bool) -> void:
	var support := Node3D.new()
	add_child(support)
	support.position = at
	if longitudinal:
		support.rotation.y = PI / 2
	for z in [-0.47, 0.47]:
		Parts.box(support, Vector3(0, 0.08, z), Vector3(0.5, 0.16, 0.42), steel)
		Parts.box(support, Vector3(0, 0.89, z), Vector3(0.15, 1.58, 0.14), dark)
		Parts.collider(support, Vector3(0, 0.88, z), Vector3(0.22, 1.76, 0.23))
		Parts.cylinder(support, Vector3(0.14, 0.19, z), 0.038, 0.08, pale)
	Parts.box(support, Vector3(0, 1.64, 0), Vector3(0.2, 0.13, 1.07), steel)
	Parts.collider(support, Vector3(0, 1.64, 0), Vector3(0.2, 0.13, 1.07))


func set_glass(enabled: bool) -> void:
	for part in glass_parts:
		part.material_override = glass if enabled else opaque
		part.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF if enabled else GeometryInstance3D.SHADOW_CASTING_SETTING_ON


func set_filled(enabled: bool) -> void:
	for part in liquid_parts:
		part.visible = enabled
