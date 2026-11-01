extends "res://scripts/factory/model.gd"

## Geometry-only review fixture; never advanced, serialized or passed to a Store.
var board_id := "P"
var core_reserved := Rect2(-3, -3, 6, 6)


func _init() -> void:
	super()
	set_board("P")


func set_board(value: String) -> void:
	assert(value in ["P", "D"])
	board_id = value
	entities.clear()
	next_id = 1
	if value == "P":
		add_sample("collector", -9, -2)
		add_sample("reactor", 5, -1)
		add_sample("storage", 1, 6)
		add_sample("cell_generator", 7, 5)
		add_sample("power_junction", 2, 3)
		for x in range(-2, 2): add_sample("belt", x, -4, 1)
		for z in range(-2, 2):
			add_sample("belt", -4, z, 0 if z in [-2, 1] else 2)
			add_sample("belt", 3, z, 0)
		actor.x = -1.0
		actor.z = 5.0
	else:
		for x in [-8, -4, 0, 4]:
			for z in [-8, -4, 0, 4]: add_sample("reactor", x, z)
		for x in range(-8, 7): add_sample("belt", x, 8, 0)
		actor.x = 0.0
		actor.z = 9.5
	actor.angle = 0.0
	actor.walk = 0.0
	actor.moving = false
	actor.target = null
	rebuild_indexes()
	revision += 1


func add_sample(type: String, x: int, z: int, dir := 0) -> void:
	entities.append({"id": next_id, "type": type, "x": x, "z": z, "dir": dir})
	next_id += 1


func blocked_for_actor(x: float, z: float) -> bool:
	if absf(x) > 11.7 or absf(z) > 11.7: return true
	if board_id == "P" and rect_distance(Vector2(x, z), core_reserved) < 0.29: return true
	return super.blocked_for_actor(x, z)


static func rect_distance(point: Vector2, rect: Rect2) -> float:
	return Vector2(maxf(maxf(rect.position.x - point.x, 0), point.x - rect.end.x),
		maxf(maxf(rect.position.y - point.y, 0), point.y - rect.end.y)).length()


func measure_cell(cell: Vector2i) -> String:
	if cell.x < -12 or cell.x >= 12 or cell.y < -12 or cell.y >= 12: return "评估区外"
	if board_id == "P" and core_reserved.has_point(Vector2(cell) + Vector2.ONE * 0.5): return "核心预留占地"
	if not entity_at(cell).is_empty(): return "已有样板设备 / 带"
	if Rect2(Vector2(cell) - Vector2.ONE * 0.3, Vector2.ONE * 1.6).has_point(Vector2(actor.x, actor.z)): return "角色站在这里"
	return "空格 · 仅测量，不放置"


func distance_to_sample(e: Dictionary) -> float:
	if e.is_empty(): return INF
	var shape: Dictionary = CATALOG[e.type]
	return rect_distance(Vector2(actor.x, actor.z), Rect2(e.x, e.z, shape.w, shape.d))


func nearest_sample() -> int:
	var found := -1
	var distance := 2.00001
	for e in entities:
		if e.type == "belt": continue
		var next := distance_to_sample(e)
		if next < distance:
			distance = next
			found = e.id
	return found
