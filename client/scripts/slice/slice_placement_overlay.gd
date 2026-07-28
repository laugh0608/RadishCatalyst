class_name SlicePlacementOverlay
extends Node2D

## Dynamic placement-only feedback. It draws logical cells and derived ranges;
## world art remains sprite / tile based and none of this state is persisted.

const VALID_FILL := Color(0.18, 0.82, 0.66, 0.16)
const VALID_EDGE := Color(0.38, 1.0, 0.82, 0.88)
const INVALID_FILL := Color(0.9, 0.23, 0.2, 0.18)
const INVALID_EDGE := Color(1.0, 0.42, 0.34, 0.92)
const MISSING_FLOOR_FILL := Color(0.92, 0.56, 0.16, 0.22)
const MISSING_FLOOR_EDGE := Color(1.0, 0.72, 0.28, 0.96)
const LINK_RANGE_COLOR := Color(0.38, 0.94, 0.9, 0.56)
const SUPPLY_RANGE_COLOR := Color(0.94, 0.72, 0.3, 0.42)
const LINK_LINE_COLOR := Color(0.5, 1.0, 0.92, 0.82)

var _definition: SliceBuildingDefinition
var _origin_cell := Vector2i.ZERO
var _rotation := 0
var _tile_size := 32.0
var _valid := false
var _missing_floor_cells: Array[Vector2i] = []
var _power_nodes: Array[Dictionary] = []


func configure(
	definition: SliceBuildingDefinition,
	origin_cell: Vector2i,
	rotation: int,
	tile_size: float,
	validation: Dictionary,
	power_nodes: Array[Dictionary]
) -> void:
	_definition = definition
	_origin_cell = origin_cell
	_rotation = rotation
	_tile_size = tile_size
	_valid = bool(validation.get("valid", false))
	_missing_floor_cells.clear()
	for cell in validation.get("missing_floor_cells", []):
		_missing_floor_cells.append(Vector2i(cell))
	_power_nodes = power_nodes.duplicate(true)
	visible = definition != null
	queue_redraw()


func clear() -> void:
	_definition = null
	_missing_floor_cells.clear()
	_power_nodes.clear()
	visible = false
	queue_redraw()


func footprint_cell_count() -> int:
	if _definition == null:
		return 0
	return _definition.occupied_cells(_origin_cell, _rotation).size()


func missing_floor_cell_count() -> int:
	return _missing_floor_cells.size()


func power_ring_count() -> int:
	if _definition == null:
		return 0
	if _definition.power_role == SliceBuildingDefinition.POWER_RELAY:
		return 2
	if _definition.power_role == SliceBuildingDefinition.POWER_CONSUMER:
		return _nearby_power_nodes().size()
	return 0


func _draw() -> void:
	if _definition == null:
		return
	for cell in _definition.occupied_cells(_origin_cell, _rotation):
		_draw_cell(cell)
	if _definition.power_role == SliceBuildingDefinition.POWER_RELAY:
		_draw_relay_ranges()
	elif _definition.power_role == SliceBuildingDefinition.POWER_CONSUMER:
		_draw_consumer_ranges()


func _draw_cell(cell: Vector2i) -> void:
	var parent_position: Vector2 = (get_parent() as Node2D).position
	var cell_center: Vector2 = (
		(Vector2(cell) + Vector2(0.5, 0.5)) * _tile_size
		- parent_position
	)
	var rect := Rect2(
		cell_center - Vector2.ONE * _tile_size * 0.5,
		Vector2.ONE * _tile_size
	).grow(-1.0)
	var missing_floor := _missing_floor_cells.has(cell)
	var fill := (
		MISSING_FLOOR_FILL
		if missing_floor
		else VALID_FILL if _valid else INVALID_FILL
	)
	var edge := (
		MISSING_FLOOR_EDGE
		if missing_floor
		else VALID_EDGE if _valid else INVALID_EDGE
	)
	draw_rect(rect, fill, true)
	draw_rect(rect, edge, false, 2.0)
	if missing_floor:
		draw_line(rect.position + Vector2(5, 5), rect.end - Vector2(5, 5), edge, 2.0)
		draw_line(
			Vector2(rect.end.x - 5, rect.position.y + 5),
			Vector2(rect.position.x + 5, rect.end.y - 5),
			edge,
			2.0
		)


func _draw_relay_ranges() -> void:
	var link_radius := (
		SlicePowerGrid.RELAY_LINK_RANGE_CELLS * _tile_size
	)
	var supply_radius := (
		SlicePowerGrid.DEVICE_SUPPLY_RANGE_CELLS * _tile_size
	)
	draw_arc(
		Vector2.ZERO, link_radius, 0.0, TAU, 64, LINK_RANGE_COLOR, 2.0
	)
	draw_arc(
		Vector2.ZERO, supply_radius, 0.0, TAU, 48, SUPPLY_RANGE_COLOR, 2.0
	)
	var nearest := Vector2.ZERO
	var nearest_distance := INF
	var parent_position: Vector2 = (get_parent() as Node2D).position
	for node in _power_nodes:
		var node_position := Vector2(node.get("position", Vector2.ZERO))
		var distance: float = parent_position.distance_to(node_position)
		if distance <= link_radius + 0.001 and distance < nearest_distance:
			nearest = node_position
			nearest_distance = distance
	if nearest_distance < INF:
		draw_line(
			Vector2.ZERO,
			nearest - parent_position,
			LINK_LINE_COLOR,
			2.0
		)


func _draw_consumer_ranges() -> void:
	var parent_position: Vector2 = (get_parent() as Node2D).position
	for node in _nearby_power_nodes():
		var node_position := Vector2(node.get("position", Vector2.ZERO))
		var range_cells := float(node.get("device_range_cells", 0.0))
		draw_arc(
			node_position - parent_position,
			range_cells * _tile_size,
			0.0,
			TAU,
			48,
			SUPPLY_RANGE_COLOR,
			2.0
		)


func _nearby_power_nodes() -> Array[Dictionary]:
	var nearby: Array[Dictionary] = []
	var parent_position: Vector2 = (get_parent() as Node2D).position
	for node in _power_nodes:
		var node_position := Vector2(node.get("position", Vector2.ZERO))
		var range_cells := float(node.get("device_range_cells", 0.0))
		var visible_radius := (range_cells + 3.0) * _tile_size
		if parent_position.distance_to(node_position) <= visible_radius:
			nearby.append(node)
	return nearby
