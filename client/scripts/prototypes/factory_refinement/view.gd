extends "res://scripts/factory/view.gd"

## Imported shape samples; only transient affordances are drawn at runtime.
var cues := Node3D.new()
var cue_key := ""
var input_mat := Parts.material("73ddd0", 0, 0.7)
var output_mat := Parts.material("f0c16b", 0, 0.7)


func _ready() -> void:
	super._ready()
	assets.reactor = preload("res://assets/factory/refinement/reactor.glb")
	assets.power_junction = preload("res://assets/factory/refinement/power-junction.glb")
	add_child(cues)


func _sync_wiring(_model: RefCounted, _ui: Dictionary) -> void:
	# Coverage and selection cues replace the old always-connected wire diagram.
	pass


func label_at(text: String, point: Vector3, tint: Color) -> void:
	var label := Label3D.new()
	label.text = text
	label.font = preload("res://assets/fonts/NotoSansSC-wght.ttf")
	label.font_size = 34
	label.pixel_size = 0.012
	label.outline_size = 8
	label.modulate = tint
	label.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	label.no_depth_test = true
	cues.add_child(label)
	label.position = point


func port_cues(e: Dictionary) -> void:
	for role in ["input", "output"]:
		var port := Model.port(e, role)
		if port.is_empty():
			continue
		var cell := Vector2i(port.x + port.dx, port.z)
		var mat := input_mat if role == "input" else output_mat
		footprint(cues, cell, {"w": 1, "d": 1}, mat)
		arrow(cues, cell, 0, mat)
		label_at("输入 →" if role == "input" else "输出 →", Vector3(cell.x + .5, .45, cell.y + .5), mat.albedo_color)


func circle(e: Dictionary, radius: float) -> void:
	var center: Vector2 = world_model.Grid.center(e)
	for i in 96:
		var a := TAU * i / 96
		var b := TAU * (i + 1) / 96
		var p := Vector3(center.x + cos(a) * radius, .1, center.y + sin(a) * radius)
		var q := Vector3(center.x + cos(b) * radius, .1, center.y + sin(b) * radius)
		var part := _overlay_box(cues, (p + q) / 2, Vector3(.045, .025, p.distance_to(q)), input_mat)
		part.look_at(q)
	for device in world_model.entities:
		if (world_model.Grid.is_node(device) or world_model.DiscoveryRules.POWER.has(device.type)) and world_model.covers(e, device):
			footprint(cues, Vector2i(device.x, device.z), Model.CATALOG[device.type], input_mat)
	label_at("自动供电 · 6 格", Vector3(center.x, 2.7, center.y), Color("a7eee1"))


func draw(model: RefCounted, actor: Dictionary, ui: Dictionary) -> void:
	super.draw(model, actor, ui)
	var key := str([model.revision, ui.tool, ui.cell, ui.selected, ui.dir])
	if key == cue_key:
		return
	cue_key = key
	clear_node(cues)
	for e in model.entities:
		if ui.build or e.id == ui.selected:
			port_cues(e)
	if not ui.tool.is_empty():
		var e := {"type": ui.tool, "x": ui.cell.x, "z": ui.cell.y}
		port_cues(e)
		if ui.tool != "belt":
			var asset: Node3D = assets[ui.tool].instantiate()
			cues.add_child(asset)
			var def: Dictionary = Model.CATALOG[ui.tool]
			asset.position = Vector3(ui.cell.x + def.w * .5, .1, ui.cell.y + def.d * .5)
			for mesh in asset.find_children("*", "MeshInstance3D", true, false):
				mesh.transparency = .45
		if model.Grid.is_node(e):
			circle(e, model.RADIUS)
	else:
		var e: Dictionary = model.by_id(ui.selected)
		if model.Grid.is_node(e):
			circle(e, model.RADIUS)
