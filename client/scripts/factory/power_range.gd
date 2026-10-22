extends Node3D

## Transient connection-distance guidance; no entity, network or save mutations.
const Grid := preload("res://scripts/factory/power_grid.gd")
const Parts := preload("res://scripts/factory/overlays.gd")
const STEPS := 128
const CONSUMER_COLOR := Color("73ddd0")
const NODE_COLOR := Color("f0c16b")
var key := ""
var targets := Node3D.new()


static func origin(model: RefCounted, ui: Dictionary) -> Dictionary:
	if not model.has_method("power_state"):
		return {}
	if not ui.tool.is_empty():
		return {"type": ui.tool, "x": ui.cell.x, "z": ui.cell.y} if Grid.is_node({"type": ui.tool}) else {}
	var e: Dictionary = model.by_id(ui.power_from if ui.get("power_from", 0) != 0 else ui.selected)
	return e if Grid.is_node(e) else {}


static func legend(automatic := false) -> String:
	return "青色实圈：设备 %d 格 · 金色虚圈：节点 %d 格 · 灰段：矿壳阻挡 · %s" % [Grid.Rules.CONSUMER_RANGE, Grid.Rules.NODE_RANGE,
		"范围内自动接电，需连通启用电源" if automatic else "放置后需接线"]


func _ready() -> void:
	add_child(targets)


func sync(model: RefCounted, actor: Dictionary, ui: Dictionary, enabled: bool) -> void:
	var e := origin(model, ui) if enabled else {}
	visible = not e.is_empty()
	if not visible:
		key = ""
		_clear()
		return
	var valid: bool = ui.tool.is_empty() or model.placement(ui.tool, ui.cell, actor).ok
	var next := str([model.get_instance_id(), model.revision, e, valid, model.discovery.passages])
	if next == key:
		return
	key = next
	_clear()
	var center := Grid.center(e)
	_ring(center, Grid.Rules.CONSUMER_RANGE, CONSUMER_COLOR, false, valid, model.discovery.passages, model.map_id)
	_ring(center, Grid.Rules.NODE_RANGE, NODE_COLOR, true, valid, model.discovery.passages, model.map_id)
	if not valid:
		return
	for candidate in model.entities:
		if candidate.id == e.get("id", -1) or not Grid.reachability(e, candidate, model.discovery.passages, model.map_id).ok:
			continue
		var hint := Node3D.new()
		hint.set_meta("entity_id", candidate.id)
		targets.add_child(hint)
		var size: Dictionary = Grid.Rules.CATALOG[candidate.type]
		var mat := Parts.material("f0c16b" if Grid.is_node(candidate) else "73ddd0")
		mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
		for side in [-1, 1]:
			var at := Grid.center(candidate)
			_box(hint, Vector3(at.x, 0.12, at.y + side * size.d * 0.5), Vector3(size.w + 0.12, 0.025, 0.09), mat)
			_box(hint, Vector3(at.x + side * size.w * 0.5, 0.12, at.y), Vector3(0.09, 0.025, size.d + 0.12), mat)


func _clear() -> void:
	for child in get_children():
		if child != targets:
			remove_child(child)
			child.queue_free()
	for child in targets.get_children():
		targets.remove_child(child)
		child.queue_free()


func _ring(center: Vector2, radius: float, color: Color, dashed: bool, valid: bool, passages: Dictionary, map_id: String) -> void:
	var shape := ImmediateMesh.new()
	var mat := StandardMaterial3D.new()
	mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	mat.vertex_color_use_as_albedo = true
	mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	mat.cull_mode = BaseMaterial3D.CULL_DISABLED
	shape.surface_begin(Mesh.PRIMITIVE_TRIANGLES)
	var blocked := 0
	for i in STEPS:
		if dashed and i % 2 != 0:
			continue
		var a := Vector2.from_angle(TAU * i / STEPS)
		var b := Vector2.from_angle(TAU * (i + 1) / STEPS)
		var open := Grid.line_open(center, center + (a + b).normalized() * radius, passages, map_id)
		if not open:
			blocked += 1
		var tint := color if open else Color("637a77", 0.55)
		if not valid:
			tint = Color("dc8065", 0.7)
		shape.surface_set_color(tint)
		var points := [a * (radius - 0.045), a * (radius + 0.045), b * (radius + 0.045), b * (radius - 0.045)]
		for index in [0, 1, 2, 0, 2, 3]:
			shape.surface_add_vertex(Vector3(points[index].x, 0, points[index].y))
	shape.surface_end()
	var ring := Parts.mesh(self, shape, Vector3(center.x, 0.105, center.y), mat)
	ring.name = "NodeRange" if dashed else "ConsumerRange"
	ring.set_meta("radius", radius)
	ring.set_meta("blocked_segments", blocked)
	ring.set_meta("valid", valid)
	ring.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF


func _box(parent: Node3D, at: Vector3, size: Vector3, mat: Material) -> void:
	var part := Parts.box(parent, at, size, mat)
	part.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
