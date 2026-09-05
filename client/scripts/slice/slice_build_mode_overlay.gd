class_name SliceBuildModeOverlay
extends Node2D

## Read-only construction context for the fixed camera view. The overlay derives
## footprints and logistics direction from placed building definitions.

const GRID_COLOR := Color(0.42, 0.72, 0.78, 0.2)
const FOOTPRINT_FILL := Color(0.08, 0.16, 0.18, 0.18)
const FOOTPRINT_EDGE := Color(0.52, 0.9, 0.88, 0.72)
const INPUT_COLOR := Color(0.2, 0.95, 0.92, 0.96)
const OUTPUT_COLOR := Color(1.0, 0.66, 0.2, 0.98)
const FLOW_COLOR := Color(1.0, 0.82, 0.38, 0.92)

var _map_size := Vector2i.ZERO
var _tile_size := 32.0
var _instances: Array[SliceBuildingInstance] = []


func configure(
	map_size: Vector2i,
	tile_size: float,
	instances: Array[SliceBuildingInstance]
) -> void:
	_map_size = map_size
	_tile_size = tile_size
	_instances = instances
	queue_redraw()


func refresh_instances(instances: Array[SliceBuildingInstance]) -> void:
	_instances = instances
	queue_redraw()


func _draw() -> void:
	if _map_size == Vector2i.ZERO:
		return
	for x in range(0, _map_size.x + 1, int(_tile_size)):
		draw_line(Vector2(x, 0), Vector2(x, _map_size.y), GRID_COLOR, 1.0)
	for y in range(0, _map_size.y + 1, int(_tile_size)):
		draw_line(Vector2(0, y), Vector2(_map_size.x, y), GRID_COLOR, 1.0)
	for instance in _instances:
		_draw_instance(instance)


func _draw_instance(instance: SliceBuildingInstance) -> void:
	if instance == null or instance.definition == null or not instance.visible:
		return
	var definition := instance.definition
	for cell in definition.occupied_cells(
		instance.origin_cell, instance.building_rotation
	):
		var rect := Rect2(Vector2(cell) * _tile_size, Vector2.ONE * _tile_size).grow(-1.5)
		draw_rect(rect, FOOTPRINT_FILL, true)
		draw_rect(rect, FOOTPRINT_EDGE, false, 1.5)
	for endpoint in instance.logistics_endpoints():
		_draw_port(endpoint.preview_descriptor())
	if instance is SliceConveyor:
		_draw_conveyor_flow(instance as SliceConveyor)


func _draw_port(port: Dictionary) -> void:
	var role := String(port.get("role", ""))
	var direction := Vector2(Vector2i(port.get("outward_direction", Vector2i.ZERO)))
	if role == SliceLogisticsPortDefinition.ROLE_INPUT:
		direction = -direction
	var center := (Vector2(Vector2i(port["port_cell"])) + Vector2.ONE * 0.5) * _tile_size
	var color := INPUT_COLOR if role == SliceLogisticsPortDefinition.ROLE_INPUT else OUTPUT_COLOR
	draw_circle(center, 5.0, color)
	if direction != Vector2.ZERO:
		_draw_arrow(center, center + direction * 13.0, color)


func _draw_conveyor_flow(conveyor: SliceConveyor) -> void:
	var center := (Vector2(conveyor.origin_cell) + Vector2.ONE * 0.5) * _tile_size
	var direction := Vector2(conveyor.output_direction())
	_draw_arrow(center - direction * 8.0, center + direction * 9.0, FLOW_COLOR)


func _draw_arrow(from: Vector2, to: Vector2, color: Color) -> void:
	draw_line(from, to, color, 2.0)
	var direction := (to - from).normalized()
	var side := direction.orthogonal()
	draw_colored_polygon(PackedVector2Array([
		to,
		to - direction * 6.0 + side * 4.0,
		to - direction * 6.0 - side * 4.0,
	]), color)
