extends Node3D

const Model := preload("res://scripts/factory/model.gd")
const Parts := preload("res://scripts/factory/overlays.gd")
const ASSET_ROOT := "res://assets/factory/"
const STATUS := {"running": "77d8c6", "ready": "b2c5b3", "waiting": "e2b365", "blocked": "e58864"}
var resource_error := ""
var prepared := false
var camera := Camera3D.new()
var sun := DirectionalLight3D.new()
var environment := Environment.new()
var target := Vector3(0, 0.25, 0.3)
var world_model: RefCounted
var yaw := 25.0
var zoom := 1.0
var models := {}
var assets := {}
var mesh_faces := {}
var engineer: Node3D
var body: Node3D
var limbs: Array[Node3D] = []
var grid := Node3D.new()
var ghost := Node3D.new()
var selection := Node3D.new()
var last_revision := -1
var ghost_key := ""
var selection_key := ""
var valid_mat := Parts.material("73d0b3", 0, 0.7)
var invalid_mat := Parts.material("dc8065", 0, 0.7)
var select_mat := Parts.material("edc576", 0.1, 0.65)
var crystal_mat := Parts.material("70c8d1", 0.32, 0.24)
var catalyst_mat := Parts.material("deb25b", 0.5, 0.3)
var cyan_mat := Parts.material("5bd6c8", 0, 0.32)
var dark_mat := Parts.material("273b40", 0.5, 0.42)


func _ready() -> void:
	for name in ["yard", "ore", "collector", "reactor", "storage", "engineer", "cargo",
		"belt-2", "belt-4", "belt-6", "belt-8", "belt-10", "belt-12", "belt-14"]:
		assets[name] = load(ASSET_ROOT + name + ".glb")
		if not assets[name] is PackedScene:
			resource_error = "缺少工厂模型：" + name
			return
	var yard: Node3D = assets.yard.instantiate()
	add_child(yard)
	yard.scale = Vector3(64.0 / 20.0, 1, 64.0 / 13.0)
	yard.position.z = -0.5 * yard.scale.z
	for cell in Model.Rules.ore_sites():
		var ore: Node3D = assets.ore.instantiate()
		add_child(ore)
		ore.position = Vector3(cell.x + 8, 0, cell.y + 1)
	# Imported transparent glass is decorative, as in the Web production yard.
	_disable_transparent_shadows(self)
	engineer = assets.engineer.instantiate()
	add_child(engineer)
	body = engineer.find_child("Body", true, false)
	for i in 4:
		limbs.append(engineer.find_child("Limb%d" % i, true, false))
	_build_lighting()
	add_child(camera)
	camera.current = true
	camera.projection = Camera3D.PROJECTION_ORTHOGONAL
	camera.keep_aspect = Camera3D.KEEP_HEIGHT
	camera.near = 0.1
	camera.far = 120
	get_viewport().size_changed.connect(sync_camera)
	sync_camera()
	for node in [grid, ghost, selection]:
		add_child(node)
	var grid_mat := Parts.material("89958a", 0, 1)
	for x in range(-32, 33):
		_overlay_box(grid, Vector3(x, 0.035, 0), Vector3(0.014, 0.006, 64), grid_mat)
	for z in range(-32, 33):
		_overlay_box(grid, Vector3(0, 0.035, z), Vector3(64, 0.006, 0.014), grid_mat)
	for mat in [valid_mat, invalid_mat]:
		mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
		mat.albedo_color.a = 0.6
	prepared = true


func _disable_transparent_shadows(node: Node) -> void:
	if node is MeshInstance3D:
		for surface in node.mesh.get_surface_count():
			var mat = node.get_active_material(surface)
			if mat is BaseMaterial3D and mat.transparency != BaseMaterial3D.TRANSPARENCY_DISABLED:
				node.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	for child in node.get_children():
		_disable_transparent_shadows(child)


func _build_lighting() -> void:
	environment.background_mode = Environment.BG_COLOR
	environment.background_color = Color("344643")
	environment.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	environment.ambient_light_color = Color("d7ebef")
	environment.ambient_light_energy = 0.4
	environment.reflected_light_source = Environment.REFLECTION_SOURCE_SKY
	var sky := Sky.new()
	var sky_material := ProceduralSkyMaterial.new()
	sky_material.sky_top_color = Color("b6caca")
	sky_material.sky_horizon_color = Color("d7ebef")
	sky_material.ground_bottom_color = Color("536052")
	sky_material.ground_horizon_color = Color("88958a")
	sky.sky_material = sky_material
	environment.sky = sky
	environment.tonemap_mode = Environment.TONE_MAPPER_ACES
	environment.tonemap_exposure = 0.8
	environment.ssao_enabled = true
	environment.ssao_radius = 0.6
	environment.ssao_intensity = 1.2
	var world_environment := WorldEnvironment.new()
	world_environment.environment = environment
	add_child(world_environment)
	add_child(sun)
	sun.position = Vector3(-9, 16, 9)
	sun.look_at(Vector3.ZERO)
	sun.light_color = Color("fff0ce")
	sun.light_energy = 1.0
	sun.light_angular_distance = 0.5
	sun.shadow_enabled = true
	sun.directional_shadow_mode = DirectionalLight3D.SHADOW_ORTHOGONAL
	sun.directional_shadow_max_distance = 65
	sun.shadow_bias = 0.025
	sun.shadow_normal_bias = 0.06


func sync_camera() -> void:
	var viewport_size := get_viewport().get_visible_rect().size
	if viewport_size.y <= 0:
		return
	var pitch := deg_to_rad(50)
	var angle := deg_to_rad(yaw)
	camera.position = target + Vector3(sin(angle) * cos(pitch), sin(pitch), cos(angle) * cos(pitch)) * 40
	camera.look_at(target)
	camera.size = maxf(21, 31 / (viewport_size.x / viewport_size.y)) / zoom


func ground(screen: Vector2) -> Variant:
	return Plane(Vector3.UP, 0).intersects_ray(camera.project_ray_origin(screen), camera.project_ray_normal(screen))


func project(point: Vector3) -> Vector2:
	return camera.unproject_position(point)


## Broad-phase bounds followed by triangles, so empty model corners do not steal clicks.
func hit(screen: Vector2) -> int:
	var origin := camera.project_ray_origin(screen)
	var direction := camera.project_ray_normal(screen)
	var distance := INF
	var found := -1
	var ground_point = ground(screen)
	if ground_point == null or world_model == null:
		return -1
	var candidates := {}
	# Tall machines project toward the camera, bounded by maximum model height.
	for x in range(floori(ground_point.x) - 5, floori(ground_point.x) + 6):
		for z in range(floori(ground_point.z) - 5, floori(ground_point.z) + 6):
			var e: Dictionary = world_model.entity_at(Vector2i(x, z))
			if not e.is_empty():
				candidates[e.id] = true
	for id in candidates:
		for part in models[id].hit_parts:
			if not part.is_visible_in_tree():
				continue
			var inverse: Transform3D = part.global_transform.affine_inverse()
			var local_origin: Vector3 = inverse * origin
			var local_direction: Vector3 = inverse.basis * direction
			if part.get_aabb().intersects_ray(local_origin, local_direction) == null:
				continue
			var faces: PackedVector3Array = mesh_faces[part.mesh.get_instance_id()]
			for index in range(0, faces.size(), 3):
				var at = Geometry3D.ray_intersects_triangle(local_origin, local_direction, faces[index], faces[index + 1], faces[index + 2])
				if at == null:
					continue
				var point: Vector3 = part.global_transform * at
				var d := origin.distance_squared_to(point)
				if d < distance:
					distance = d
					found = id
	return found


static func travel_position(entry: Vector2i, dir: int, progress: float) -> Vector2:
	var out: Vector2i = Model.DIRS[dir]
	if (entry.x * out.x + entry.y * out.y) == 0:
		var center := Vector2(entry + out) * 0.5
		var start := atan2(-out.y, -out.x)
		var sweep := atan2(out.x * entry.y - out.y * entry.x, (out.x * entry.x + out.y * entry.y))
		var angle := start + sweep * progress
		return center + Vector2(cos(angle), sin(angle)) * 0.5
	return Vector2(entry) * (0.5 - progress) if progress < 0.5 else Vector2(out) * (progress - 0.5)


static func _overlay_box(parent: Node3D, at: Vector3, size: Vector3, mat: Material) -> MeshInstance3D:
	var part := Parts.box(parent, at, size, mat)
	part.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	return part


static func footprint(parent: Node3D, cell: Vector2i, def: Dictionary, mat: Material) -> void:
	var x: float = cell.x
	var z: float = cell.y
	_overlay_box(parent, Vector3(x + def.w * 0.5, 0.075, z), Vector3(def.w, 0.025, 0.04), mat)
	_overlay_box(parent, Vector3(x + def.w * 0.5, 0.075, z + def.d), Vector3(def.w, 0.025, 0.04), mat)
	_overlay_box(parent, Vector3(x, 0.075, z + def.d * 0.5), Vector3(0.04, 0.025, def.d), mat)
	_overlay_box(parent, Vector3(x + def.w, 0.075, z + def.d * 0.5), Vector3(0.04, 0.025, def.d), mat)


static func arrow(parent: Node3D, cell: Vector2i, dir: int, mat: Material) -> void:
	var root := Node3D.new()
	parent.add_child(root)
	root.position = Vector3(cell.x + 0.5, 0.15, cell.y + 0.5)
	root.rotation.y = -dir * PI / 2
	_overlay_box(root, Vector3(-0.08, 0, 0), Vector3(0.48, 0.035, 0.065), mat)
	for sign_value in [-1, 1]:
		var branch := _overlay_box(root, Vector3(0.16, 0, sign_value * 0.07), Vector3(0.22, 0.035, 0.065), mat)
		branch.rotation.y = sign_value * PI / 4


func clear_node(node: Node) -> void:
	for child in node.get_children():
		node.remove_child(child)
		child.queue_free()


func invalidate() -> void:
	for v in models.values():
		remove_child(v.root)
		v.root.queue_free()
	models.clear()
	last_revision = -1
	ghost_key = ""
	selection_key = ""


func _build(e: Dictionary, mask: int) -> Dictionary:
	var root := Node3D.new()
	add_child(root)
	var def: Dictionary = Model.CATALOG[e.type]
	root.position = Vector3(e.x + def.w * 0.5, 0, e.z + def.d * 0.5)
	var result := {"root": root, "mask": mask, "dir": e.dir}
	if e.type == "belt":
		var belt: Node3D = assets["belt-%d" % mask].instantiate()
		root.add_child(belt)
		belt.rotation.y = -e.dir * PI / 2
		var cargo: Node3D = assets.cargo.instantiate()
		root.add_child(cargo)
		result.cargo = cargo
		result.cargo_mesh = cargo.find_children("*", "MeshInstance3D", true, false)[0]
	else:
		root.add_child(assets[e.type].instantiate())
		var lamp_mat := Parts.material(STATUS.waiting)
		lamp_mat.emission_enabled = true
		lamp_mat.emission = Color(STATUS.waiting)
		lamp_mat.emission_energy_multiplier = 0.5
		result.lamp = Parts.sphere(root, Vector3(-def.w * 0.5 + 0.22, 3.4 if e.type == "reactor" else 2.1, def.d * 0.5 - 0.2), Vector3.ONE * 0.21, lamp_mat)
		result.lamp_mat = lamp_mat
		_overlay_box(root, Vector3(0, 0.035, def.d * 0.5 + 0.15), Vector3(def.w * 0.8, 0.04, 0.12), dark_mat)
		result.bar = _overlay_box(root, Vector3(0, 0.064, def.d * 0.5 + 0.15), Vector3(def.w * 0.8, 0.025, 0.12), cyan_mat)
	result.hit_parts = root.find_children("*", "MeshInstance3D", true, false)
	for part in result.hit_parts:
		var mesh_id: int = part.mesh.get_instance_id()
		if not mesh_faces.has(mesh_id):
			mesh_faces[mesh_id] = part.mesh.get_faces()
	return result


func _rebuild(model: RefCounted) -> void:
	for id in models.keys():
		if model.by_id(id).is_empty():
			remove_child(models[id].root)
			models[id].root.queue_free()
			models.erase(id)
	for e in model.entities:
		var mask := 0
		if e.type == "belt":
			for side in model.belt_inputs(e):
				mask |= 1 << ((side - e.dir + 4) % 4)
			if mask == 0:
				mask = 4
		if models.has(e.id) and (models[e.id].mask != mask or models[e.id].dir != e.dir):
			remove_child(models[e.id].root)
			models[e.id].root.queue_free()
			models.erase(e.id)
		if not models.has(e.id):
			models[e.id] = _build(e, mask)
	var used_meshes := {}
	for v in models.values():
		for part in v.hit_parts:
			used_meshes[part.mesh.get_instance_id()] = true
	for mesh_id in mesh_faces.keys():
		if not used_meshes.has(mesh_id):
			mesh_faces.erase(mesh_id)
	last_revision = model.revision


func draw(model: RefCounted, actor: Dictionary, ui: Dictionary) -> void:
	world_model = model
	var follow := Vector3(actor.x, 0.25, actor.z - 4.0)
	if target.distance_squared_to(follow) > 0.0001:
		target = follow
		sync_camera()
	if last_revision != model.revision:
		_rebuild(model)
	engineer.position = Vector3(actor.x, 0, actor.z)
	engineer.rotation.y = actor.angle
	var gait: float = sin(actor.walk * 7) * 0.48 if actor.moving else 0.0
	for i in limbs.size():
		limbs[i].rotation.x = gait * (1 if i < 2 else -1) * (1 if i % 2 == 0 else -1)
	body.position.y = absf(sin(actor.walk * 7)) * 0.035 if actor.moving else 0
	grid.visible = ui.build
	var valid: bool = not ui.tool.is_empty() and model.placement(ui.tool, ui.cell, actor).ok
	var next_ghost := str([ui.tool, ui.cell, ui.dir, valid, ui.stroke])
	if next_ghost != ghost_key:
		clear_node(ghost)
		ghost_key = next_ghost
		if not ui.stroke.is_empty():
			var dirs := Model.path_directions(ui.stroke, ui.dir)
			for i in ui.stroke.size():
				footprint(ghost, ui.stroke[i], Model.CATALOG.belt, valid_mat)
				arrow(ghost, ui.stroke[i], dirs[i], valid_mat)
		elif not ui.tool.is_empty():
			var def: Dictionary = Model.CATALOG[ui.tool]
			var mat := valid_mat if valid else invalid_mat
			footprint(ghost, ui.cell, def, mat)
			_overlay_box(ghost, Vector3(ui.cell.x + def.w * 0.5, 0.065, ui.cell.y + def.d * 0.5), Vector3(def.w, 0.035, def.d), mat)
			if ui.tool == "belt":
				arrow(ghost, ui.cell, ui.dir, mat)
	var next_selection := str([ui.selected, model.revision])
	if next_selection != selection_key:
		clear_node(selection)
		selection_key = next_selection
		var e: Dictionary = model.by_id(ui.selected)
		if not e.is_empty():
			footprint(selection, Vector2i(e.x, e.z), Model.CATALOG[e.type], select_mat)
	for e in model.entities:
		var v: Dictionary = models[e.id]
		var def: Dictionary = Model.CATALOG[e.type]
		if e.type == "belt":
			v.cargo.visible = not e.cargo.is_empty()
			if v.cargo.visible:
				v.cargo_mesh.material_override = crystal_mat if e.cargo == "crystal" else catalyst_mat
				var p := travel_position(e.entry, e.dir, e.progress)
				v.cargo.position = Vector3(p.x, 0.53, p.y)
				v.cargo.rotation.y = model.time * 0.4
				v.cargo.scale = Vector3.ONE * (0.9 if e.cargo == "catalyst" else 1.0)
		else:
			var f: Dictionary = model.feedback(e)
			v.lamp_mat.albedo_color = Color(STATUS[f.kind])
			v.lamp_mat.emission = Color(STATUS[f.kind])
			var progress := 0.0
			match e.type:
				"reactor": progress = e.progress / 10.0 if e.processing else (1.0 if e.output > 0 else 0.0)
				"collector": progress = e.buffer / 50.0
				"storage": progress = (e.crystal + e.catalyst) / 200.0
			v.bar.scale.x = maxf(0.001, progress)
			v.bar.position.x = -(1 - progress) * def.w * 0.4
