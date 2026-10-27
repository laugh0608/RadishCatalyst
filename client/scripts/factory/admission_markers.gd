extends Control

## Read-only, screen-sized annotations. Input is resolved by the same world picker.
const Items := preload("res://scripts/factory/items.gd")
const Slots := preload("res://scripts/factory/item_slot.gd")
const RADIUS := 16.0
const HIT_SIZE := 40.0
const SPACING := 44.0
var markers: Array[Dictionary] = []
var focused_id := -1


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	clip_contents = true


static func status(e: Dictionary) -> String:
	if e.filter_item.is_empty(): return "configure"
	if e.quota_mode == "quota" and e.quota_used >= e.quota_limit: return "complete"
	if not e.accepting: return "closed"
	return "open"


func sync(view: Node3D, model: RefCounted, hud: Control, ui: Dictionary) -> void:
	markers.clear()
	focused_id = ui.get("focus_device", -1)
	var candidates: Array[Dictionary] = []
	for e in model.entities:
		if e.type != "admission_gate": continue
		var top := Vector3(e.x + 0.5, 1.0, e.z + 0.5)
		if view.camera.is_position_behind(top): continue
		var anchor: Vector2 = hud.viewport_to_screen(view.project(top)) - global_position
		if not Rect2(Vector2.ZERO, size).has_point(anchor): continue
		candidates.append({"id": e.id, "item": e.filter_item, "state": status(e), "anchor": anchor,
			"distance": view.camera.global_position.distance_squared_to(top)})
	# Reserve the enlarged footprint for every icon; hover never shuffles neighbors.
	candidates.sort_custom(func(a, b): return a.id < b.id if is_equal_approx(a.distance, b.distance) else a.distance < b.distance)
	var occupied: Array[Rect2] = []
	var hidden: Array[Dictionary] = []
	for candidate in candidates:
		if not _place(candidate, occupied, hud): hidden.append(candidate)
	# If a tightly packed far view hides the selected gate, show it in place of
	# conflicting annotations. This changes visibility, never the target geometry.
	for candidate in hidden:
		if candidate.id not in [focused_id, ui.selected]: continue
		var center: Vector2 = candidate.anchor - Vector2(0, 28)
		var rect := Rect2(center - Vector2.ONE * SPACING * 0.5, Vector2.ONE * SPACING)
		if not _inside(rect, hud): continue
		markers = markers.filter(func(m): return not m.layout.intersects(rect) or m.id == focused_id)
		if markers.any(func(m): return m.layout.intersects(rect)): continue
		candidate.merge({"center": center, "layout": rect})
		markers.append(candidate)
	queue_redraw()


func _inside(rect: Rect2, hud: Control) -> bool:
	if not Rect2(Vector2.ZERO, size).encloses(rect): return false
	for panel in hud.world_panels():
		if panel.visible and rect.intersects(Rect2(panel.global_position - global_position, panel.size)): return false
	return true


func _place(candidate: Dictionary, occupied: Array[Rect2], hud: Control) -> bool:
	for level in 3:
		var center: Vector2 = candidate.anchor - Vector2(0, 28 + level * 36)
		var rect := Rect2(center - Vector2.ONE * SPACING * 0.5, Vector2.ONE * SPACING)
		if not _inside(rect, hud) or occupied.any(func(r): return r.intersects(rect)): continue
		candidate.merge({"center": center, "layout": rect})
		markers.append(candidate)
		occupied.append(rect)
		return true
	return false


func hit(screen: Vector2) -> int:
	for marker in markers:
		if Rect2(marker.center - Vector2.ONE * HIT_SIZE * 0.5, Vector2.ONE * HIT_SIZE).has_point(screen - global_position):
			return marker.id
	return -1


func _draw() -> void:
	for marker in markers:
		var active: bool = marker.id == focused_id
		var radius := 20.0 if active else RADIUS
		var at: Vector2 = marker.center
		var color := Color("d9fff8") if active else Color("9abeb8")
		draw_line(marker.anchor, at + Vector2(0, radius), Color("698f89"), 1.5, true)
		draw_circle(at, radius + 1, Color("102b2e"), true, -1, true)
		draw_arc(at, radius, 0, TAU, 48, color, 2, true)
		if marker.item.is_empty():
			draw_string(get_theme_default_font(), at + Vector2(-5, 6), "?", HORIZONTAL_ALIGNMENT_LEFT, -1, 18, color)
		else:
			var icon_size := 30.0 if active else 24.0
			draw_texture_rect(Slots.TEXTURES[marker.item], Rect2(at - Vector2.ONE * icon_size * 0.5, Vector2.ONE * icon_size), false)
		if marker.state in ["closed", "complete"]:
			var badge := at + Vector2(radius - 3, radius - 3)
			draw_circle(badge, 6, Color("102b2e"), true, -1, true)
			if marker.state == "complete":
				draw_line(badge + Vector2(-3, 0), badge + Vector2(-1, 2), Color("eac575"), 2, true)
				draw_line(badge + Vector2(-1, 2), badge + Vector2(3, -3), Color("eac575"), 2, true)
			else:
				for x in [-2, 2]: draw_line(badge + Vector2(x, -3), badge + Vector2(x, 3), color, 2, true)
