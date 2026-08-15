class_name SliceMinimapOverlay
extends Control

## Dynamic fog and marker layer over a live, shared-world minimap viewport.

const MAP_PIXEL_SIZE := Vector2(2560, 768)
const CRYSTAL_SIGNAL_POSITION := Vector2(1984, 384)
const CORE_POSITION := Vector2(640, 320)
const FOG_COLOR := Color(0.035, 0.055, 0.064, 0.96)
const FOG_GRID_COLOR := Color(0.10, 0.14, 0.15, 0.34)
const PLAYER_COLOR := Color(0.72, 0.92, 0.94)
const INTEL_COLOR := Color(0.29, 0.78, 0.84, 0.82)
const CORE_COLOR := Color(0.84, 0.70, 0.38)

var _world: SliceWorld
var _player: SlicePlayer
var _state: SliceExplorationState


func setup(
	world: SliceWorld,
	player: SlicePlayer,
	state: SliceExplorationState
) -> void:
	_world = world
	_player = player
	_state = state
	queue_redraw()


func _process(_delta: float) -> void:
	if _player != null:
		queue_redraw()


func _draw() -> void:
	if _world == null or _player == null or _state == null:
		return
	var cell_size := Vector2(
		size.x / SliceExplorationState.GRID_SIZE.x,
		size.y / SliceExplorationState.GRID_SIZE.y
	)
	for y in range(SliceExplorationState.GRID_SIZE.y):
		for x in range(SliceExplorationState.GRID_SIZE.x):
			var cell := Vector2i(x, y)
			if _state.is_revealed(cell):
				continue
			var rect := Rect2(Vector2(x, y) * cell_size, cell_size)
			draw_rect(rect, FOG_COLOR)
			draw_rect(rect, FOG_GRID_COLOR, false, 0.5)
	_draw_discovered_crystals()
	_draw_task_intel()
	_draw_player()


func _draw_discovered_crystals() -> void:
	var world_root := _world.get_node_or_null("SliceMap/World")
	if world_root == null:
		return
	for child in world_root.get_children():
		if not String(child.name).begins_with("Crystal"):
			continue
		var crystal := child as Node2D
		if crystal == null:
			continue
		var cell := SliceExplorationState.world_to_cell(crystal.position)
		if _state.is_revealed(cell):
			draw_circle(_to_map(crystal.position), 1.4, INTEL_COLOR)


func _draw_task_intel() -> void:
	var stage := String(
		_world.current_journey_guidance().get("stage", "")
	)
	if stage == "find_crystals":
		var signal_center := _to_map(CRYSTAL_SIGNAL_POSITION)
		draw_circle(
			signal_center,
			8.0,
			Color(INTEL_COLOR.r, INTEL_COLOR.g, INTEL_COLOR.b, 0.16)
		)
		draw_arc(signal_center, 8.0, 0.0, TAU, 24, INTEL_COLOR, 1.0)
		draw_circle(signal_center, 2.0, INTEL_COLOR)
	if stage == "repair_core" or _state.is_revealed(
		SliceExplorationState.world_to_cell(CORE_POSITION)
	):
		var core_center := _to_map(CORE_POSITION)
		draw_rect(Rect2(core_center - Vector2(2, 2), Vector2(4, 4)), CORE_COLOR)


func _draw_player() -> void:
	var center := _to_map(_player.position)
	var direction := _player.facing.normalized()
	if direction == Vector2.ZERO:
		direction = Vector2.DOWN
	var perpendicular := Vector2(-direction.y, direction.x)
	var points := PackedVector2Array([
		center + direction * 4.0,
		center - direction * 2.5 + perpendicular * 2.5,
		center - direction * 2.5 - perpendicular * 2.5,
	])
	draw_colored_polygon(points, PLAYER_COLOR)
	draw_polyline(
		PackedVector2Array([points[0], points[1], points[2], points[0]]),
		Color("20363c"),
		1.0
	)


func _to_map(world_position: Vector2) -> Vector2:
	return Vector2(
		world_position.x / MAP_PIXEL_SIZE.x * size.x,
		world_position.y / MAP_PIXEL_SIZE.y * size.y
	)
