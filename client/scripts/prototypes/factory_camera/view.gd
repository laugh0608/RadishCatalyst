extends "res://scripts/factory/view.gd"

## Reuses production light, picking, movement visuals and imported resources only.
const CAMERAS := [
	{"id": "C0", "label": "正交 · 斜向", "pitch": 50.0, "yaw": 25.0, "fov": 0.0},
	{"id": "C1", "label": "正交 · 正向", "pitch": 50.0, "yaw": 0.0, "fov": 0.0},
	{"id": "C2", "label": "透视 · 正向", "pitch": 50.0, "yaw": 0.0, "fov": 35.0},
]
const MIN_SPAN := 16.0
const DEFAULT_SPAN := 21.0
const MAX_SPAN := 28.0
var preset := 2
var span := DEFAULT_SPAN
var follow := true
var board_target := Vector3(0, 0.25, 1)
var reserved := Node3D.new()
var preview := Node3D.new()
var grid_enabled := false
var core_study := false
var core: Node3D
var core_frame := true


func _ready() -> void:
	var files := {"yard": "yard", "collector": "collector", "reactor": "refinement/reactor",
		"storage": "storage", "cell_generator": "energy/cell_generator",
		"power_junction": "power/power-junction", "engineer": "engineer"}
	for mask in [2, 4, 6, 8, 10, 12, 14]: files["belt-%d" % mask] = "belt-%d" % mask
	for key in files:
		var resource = load(ASSET_ROOT + files[key] + ".glb")
		if not resource is PackedScene:
			resource_error = "镜头样板缺少模型：" + files[key]
			push_error(resource_error)
			return
		assets[key] = resource
	var yard: Node3D = assets.yard.instantiate()
	add_child(yard)
	yard.scale = Vector3(64.0 / 20.0, 1, 64.0 / 13.0)
	yard.position.z = -0.5 * yard.scale.z
	_disable_transparent_shadows(yard)
	_build_lighting()
	add_child(camera)
	camera.current = true
	camera.keep_aspect = Camera3D.KEEP_HEIGHT
	camera.near = 0.1
	camera.far = 120
	engineer = assets.engineer.instantiate()
	add_child(engineer)
	body = engineer.find_child("Body", true, false)
	for i in 4: limbs.append(engineer.find_child("Limb%d" % i, true, false))
	# The inherited view allocates these helpers before _ready; own all of them.
	for node in [grid, selection, ghost, wiring, port_hints, build_model, power_range, reserved, preview]: add_child(node)
	var mat := Parts.material("89958a", 0, 1)
	for i in range(-12, 13):
		_overlay_box(grid, Vector3(i, 0.035, 0), Vector3(0.014, 0.006, 24), mat)
		_overlay_box(grid, Vector3(0, 0.035, i), Vector3(24, 0.006, 0.014), mat)
	get_viewport().size_changed.connect(sync_camera)
	if core_study:
		core = preload("res://scripts/prototypes/factory_camera/core_outline.gd").new()
		add_child(core)
		if not core.prepared:
			resource_error = core.resource_error
			return
	prepared = true
	sync_camera()


func _exit_tree() -> void:
	focus_highlight.clear()


func sync_camera() -> void:
	if not is_inside_tree(): return
	var spec: Dictionary = CAMERAS[preset]
	var pitch := deg_to_rad(spec.pitch)
	var angle := deg_to_rad(spec.yaw)
	var distance := 40.0 if spec.fov == 0 else span / (2.0 * tan(deg_to_rad(spec.fov) / 2.0))
	camera.projection = Camera3D.PROJECTION_ORTHOGONAL if spec.fov == 0 else Camera3D.PROJECTION_PERSPECTIVE
	if spec.fov > 0: camera.fov = spec.fov
	camera.size = span
	camera.position = target + Vector3(sin(angle) * cos(pitch), sin(pitch), cos(angle) * cos(pitch)) * distance
	camera.look_at(target)


func _rebuild(model: RefCounted) -> void:
	focus_highlight.clear()
	for v in models.values():
		remove_child(v.root)
		v.root.queue_free()
	models.clear()
	clear_node(reserved)
	for e in model.entities:
		var root := Node3D.new()
		add_child(root)
		var shape: Dictionary = Model.CATALOG[e.type]
		root.position = Vector3(e.x + shape.w * 0.5, 0, e.z + shape.d * 0.5)
		var asset: Node3D = assets["belt-2" if e.type == "belt" else e.type].instantiate()
		root.add_child(asset)
		if e.type == "belt": asset.rotation.y = -e.dir * PI / 2
		var parts := asset.find_children("*", "MeshInstance3D", true, false)
		for part in parts:
			if not mesh_faces.has(part.mesh.get_instance_id()): mesh_faces[part.mesh.get_instance_id()] = part.mesh.get_faces()
		models[e.id] = {"root": root, "focus_parts": parts, "hit_parts": parts}
	if model.board_id == "P":
		footprint(reserved, Vector2i(-3, -3), {"w": 6, "d": 6}, select_mat)
		if not core_study:
			var caption := Label3D.new()
			caption.font = preload("res://assets/fonts/NotoSansSC-wght.ttf")
			caption.text = "核心预留 6×6\n轮廓模型尚未制作"
			caption.font_size = 28
			caption.pixel_size = 0.014
			caption.position = Vector3(0, 0.08, 0)
			caption.rotation_degrees.x = -90
			reserved.add_child(caption)
	if core_study: core.visible = model.board_id == "P"
	last_revision = model.revision


func draw_board(model: RefCounted, selected: int, measure: bool, cell: Vector2i, dir: int) -> void:
	world_model = model
	if last_revision != model.revision: _rebuild(model)
	if follow:
		target = Vector3(model.actor.x, 0.25, model.actor.z + 0.3)
	else:
		target = board_target
	sync_camera()
	var actor: Dictionary = model.actor
	engineer.position = Vector3(actor.x, 0, actor.z)
	engineer.rotation.y = actor.angle
	var gait: float = sin(actor.walk * 7) * 0.48 if actor.moving else 0.0
	for i in limbs.size(): limbs[i].rotation.x = gait * (1 if i < 2 else -1) * (1 if i % 2 == 0 else -1)
	body.position.y = absf(sin(actor.walk * 7)) * 0.035 if actor.moving else 0
	var selected_visual: Dictionary = models.get(selected, {})
	if core_study and selected == -2 and core.visible: selected_visual = core.visual()
	focus_highlight.sync(selected_visual, logical_pixel_scale)
	grid.visible = measure or grid_enabled
	if core_study: reserved.visible = core_frame or measure or grid_enabled
	var key := str([measure, cell, dir, model.revision])
	if key != ghost_key:
		ghost_key = key
		clear_node(preview)
		if measure:
			var mat := valid_mat if model.measure_cell(cell).begins_with("空格") else invalid_mat
			footprint(preview, cell, {"w": 1, "d": 1}, mat)
			arrow(preview, cell, dir, mat)


func hit(screen: Vector2) -> int:
	var candidate := super.hit(screen)
	if not core_study or not core.is_visible_in_tree(): return candidate
	var origin := camera.project_ray_origin(screen)
	var direction := camera.project_ray_normal(screen)
	var nearest: float = core.ray_distance(core.parts, origin, direction)
	if nearest == INF: return candidate
	if candidate < 0 or nearest < core.ray_distance(models[candidate].hit_parts, origin, direction): return -2
	return candidate


func set_board_target(value: String) -> void:
	board_target = Vector3(0, 0.25, 1 if value == "P" else 0)
	target = board_target


func camera_state() -> Dictionary:
	return {"preset": CAMERAS[preset].id, "span": span, "pitch": CAMERAS[preset].pitch,
		"yaw": CAMERAS[preset].yaw, "vfov": CAMERAS[preset].fov, "follow": follow,
		"target": [target.x, target.y, target.z], "position": [camera.position.x, camera.position.y, camera.position.z],
		"viewport": [get_viewport().size.x, get_viewport().size.y]}
