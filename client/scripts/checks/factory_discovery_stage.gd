extends "res://scripts/factory/view.gd"

## Static D1 composition, intentionally separate from the production model and saves.
const LAYOUT_PATH := "res://scripts/checks/fixtures/factory_discovery_layout.json"
const SIZES := {"collector": Vector2(2, 2), "reactor": Vector2(3, 3), "storage": Vector2(2, 2),
	"power_source": Vector2(3, 3), "power_junction": Vector2(1, 1)}
var layout: Dictionary
var content := Node3D.new()
var mode := 0
var show_connections := true
var all_connections: Node3D
var labels: Array[Dictionary] = []
var label_layer := CanvasLayer.new()


func _ready() -> void:
	for helper in [grid, ghost, selection]:
		add_child(helper)
	add_child(label_layer)
	layout = JSON.parse_string(FileAccess.get_file_as_string(LAYOUT_PATH))
	for key in ["yard", "ore", "collector", "reactor", "storage", "engineer", "belt-4", "belt-6", "belt-12"]:
		assets[key] = load(ASSET_ROOT + key + ".glb")
	assets.power_source = load(ASSET_ROOT + "power/power-source.glb")
	assets.power_junction = load(ASSET_ROOT + "power/power-junction.glb")
	_build_lighting()
	add_child(camera)
	camera.current = true
	camera.projection = Camera3D.PROJECTION_ORTHOGONAL
	camera.keep_aspect = Camera3D.KEEP_HEIGHT
	camera.far = 180
	get_viewport().size_changed.connect(sync_camera)
	prepared = true
	show_mode(0)


func _asset(key: String, at: Vector3, scale_by := Vector3.ONE) -> Node3D:
	var node: Node3D = assets[key].instantiate()
	content.add_child(node)
	node.position = at
	node.scale = scale_by
	return node


func _label(text: String, at: Vector3, color := Color("eef2da")) -> void:
	var label := Label.new()
	label.text = text
	label.add_theme_font_size_override("font_size", 17)
	label.add_theme_color_override("font_color", color)
	label.add_theme_color_override("font_outline_color", Color("1a2627"))
	label.add_theme_constant_override("outline_size", 6)
	label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	label_layer.add_child(label)
	label.reset_size()
	labels.append({"node": label, "at": at})


func sync_camera() -> void:
	super.sync_camera()
	for item in labels:
		item.node.position = camera.unproject_position(item.at) - item.node.size / 2


func _ore(x: float, z: float, scale_by := Vector3.ONE) -> void:
	# Existing ore GLB keeps the old source origin; recenter inside a wrapper.
	var wrapper := Node3D.new()
	content.add_child(wrapper)
	wrapper.position = Vector3(x, 0, z)
	wrapper.scale = scale_by
	var ore: Node3D = assets.ore.instantiate()
	wrapper.add_child(ore)
	ore.position = Vector3(8, 0, 1)


func _center(e: Dictionary, height := 0.06) -> Vector3:
	var size: Vector2 = SIZES[e.type]
	return Vector3(e.x + size.x / 2, height, e.z + size.y / 2)


func _line(a: Vector3, b: Vector3) -> void:
	# Connection overlay only; machinery remains imported GLB geometry.
	var material := Parts.material("f0c879", 0, 1)
	var box := MeshInstance3D.new()
	var shape := BoxMesh.new()
	shape.size = Vector3(0.055, 0.025, a.distance_to(b))
	box.mesh = shape
	box.material_override = material
	all_connections.add_child(box)
	box.position = (a + b) / 2
	box.look_at(b, Vector3.UP)


func show_mode(value: int) -> void:
	for item in labels:
		item.node.free()
	labels.clear()
	mode = value
	if is_instance_valid(content):
		content.free()
	content = Node3D.new()
	add_child(content)
	all_connections = Node3D.new()
	content.add_child(all_connections)
	var yard := _asset("yard", Vector3(0, 0, -2.46), Vector3(3.2, 1, 64.0 / 13.0))
	_disable_transparent_shadows(yard)
	if mode == 0:
		_gallery()
	else:
		_map(mode - 1)
	all_connections.visible = show_connections
	sync_camera()


func _gallery() -> void:
	for item in [["power_source", -5.0, "封装电源 · 3×3"], ["power_junction", -1.3, "配电节点 · 1×1"],
		["collector", 2.0, "采集器"], ["reactor", 5.5, "反应器"], ["storage", 9.0, "终端仓"]]:
		_asset(item[0], Vector3(item[1], 0, 0))
		_label(item[2], Vector3(item[1], 3.9, 0))
	_asset("engineer", Vector3(-1.6, 0, 3.2))
	target = Vector3(1.6, 0.7, 0)
	yaw = 15
	zoom = 1.25


func _map(open_count: int) -> void:
	var by_id := {}
	for e in layout.entities:
		if e.stage > open_count:
			continue
		by_id[int(e.id)] = e
		_asset(e.type, _center(e, 0))
	for site in layout.ore_sites:
		var stage := 0 if site[0] < 4 else (1 if site[0] < 20 else 2)
		_ore(site[0], site[1], Vector3(1, 1.7 if stage > 0 else 1.0, 1))
	for wall_index in 2:
		var start: float = layout.walls[wall_index][0]
		for z in range(-32, 32, 2):
			if wall_index < open_count and z >= -2 and z < 2:
				continue
			for x in [start, start + 2]:
				_ore(x, z, Vector3(1, 2.0 + 0.3 * (posmod(z, 3)), 1))
		_label("矿道 %d · %s" % [wall_index + 1, "已打开" if wall_index < open_count else "矿壳封闭"], Vector3(start + 2, 2.3, -3.2))
	for b in layout.belts:
		if b.stage > open_count:
			continue
		var entry := Vector2i(b.entry[0], b.entry[1])
		var side: int = posmod(Model.DIRS.find(entry) - int(b.dir), 4)
		var mask: int = 4 | (1 << side)
		var belt := _asset("belt-%d" % mask, Vector3(b.x + 0.5, 0, b.z + 0.5))
		belt.rotation.y = -int(b.dir) * PI / 2
	for pair in layout.links + layout.feeds:
		if by_id.has(int(pair[0])) and by_id.has(int(pair[1])):
			_line(_center(by_id[int(pair[0])]), _center(by_id[int(pair[1])]))
	_ore(2.25, 2.25, Vector3(0.22, 1.4, 0.22))
	_label("矿壳样本", Vector3(2.5, 1.15, 2.5), Color("f0c879"))
	_asset("engineer", Vector3(layout.actor[0], 0, layout.actor[1]))
	_label("基础制剂线", Vector3(-10, 3.7, -3))
	if open_count > 0:
		_label("富集回流线", Vector3(14, 3.7, -3))
	target = Vector3(3.5 if open_count < 2 else 1, 0.2, 0)
	yaw = 0
	zoom = 0.6 if open_count < 2 else 0.39


func set_connections(enabled: bool) -> void:
	show_connections = enabled
	all_connections.visible = enabled
