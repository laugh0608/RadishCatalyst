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
const LOGISTICS_PORT_COLOR := Color(0.42, 0.92, 0.88, 0.96)
const INPUT_PORT_COLOR := Color(0.2, 0.95, 0.92, 0.98)
const OUTPUT_PORT_COLOR := Color(1.0, 0.66, 0.2, 0.98)
const PORT_MATCH_COLOR := Color(0.42, 1.0, 0.5, 1.0)
const PORT_MISMATCH_COLOR := Color(1.0, 0.3, 0.24, 1.0)
const PORT_TEXT_COLOR := Color(0.03, 0.08, 0.1, 1.0)
const CONTEXT_PORT_RADIUS_CELLS := 8

var _definition: SliceBuildingDefinition
var _origin_cell := Vector2i.ZERO
var _rotation := 0
var _tile_size := 32.0
var _valid := false
var _missing_floor_cells: Array[Vector2i] = []
var _power_nodes: Array[Dictionary] = []
var _context_logistics_ports: Array[Dictionary] = []


func configure(
	definition: SliceBuildingDefinition,
	origin_cell: Vector2i,
	rotation: int,
	tile_size: float,
	validation: Dictionary,
	power_nodes: Array[Dictionary],
	logistics_ports: Array[Dictionary] = []
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
	_context_logistics_ports = logistics_ports.duplicate(true)
	visible = definition != null
	queue_redraw()


func clear() -> void:
	_definition = null
	_missing_floor_cells.clear()
	_power_nodes.clear()
	_context_logistics_ports.clear()
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


func logistics_port_marker_count() -> int:
	if _definition == null:
		return 0
	return _definition.resolved_logistics_port_descriptors(
		_origin_cell, _rotation
	).size()


func context_logistics_port_marker_count() -> int:
	return _nearby_context_logistics_ports().size()


func matched_context_logistics_port_marker_count() -> int:
	var count := 0
	for port in _nearby_context_logistics_ports():
		if _context_port_state(port) == "matched":
			count += 1
	return count


func _draw() -> void:
	if _definition == null:
		return
	for cell in _definition.occupied_cells(_origin_cell, _rotation):
		_draw_cell(cell)
	if _definition.power_role == SliceBuildingDefinition.POWER_RELAY:
		_draw_relay_ranges()
	elif _definition.power_role == SliceBuildingDefinition.POWER_CONSUMER:
		_draw_consumer_ranges()
	_draw_logistics_ports()
	_draw_context_logistics_ports()


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


func _draw_logistics_ports() -> void:
	for port in _definition.resolved_logistics_port_descriptors(
		_origin_cell, _rotation
	):
		var role := String(port["role"])
		var color := (
			LOGISTICS_PORT_COLOR
			if role == SliceLogisticsPortDefinition.ROLE_BIDIRECTIONAL
			else INPUT_PORT_COLOR
			if role == SliceLogisticsPortDefinition.ROLE_INPUT
			else OUTPUT_PORT_COLOR
		)
		var flow_direction := (
			0
			if role == SliceLogisticsPortDefinition.ROLE_BIDIRECTIONAL
			else -1
			if role == SliceLogisticsPortDefinition.ROLE_INPUT
			else 1
		)
		_draw_port_marker(
			Vector2i(port["port_cell"]),
			Vector2i(port["connection_cell"]),
			color,
			String(port["label"]),
			flow_direction
		)


func _draw_context_logistics_ports() -> void:
	if (
		_definition.building_id
		!= SliceBuildingCatalog.CONVEYOR_ID
	):
		return
	for port in _nearby_context_logistics_ports():
		var kind := String(port.get("kind", ""))
		var color := (
			LOGISTICS_PORT_COLOR
			if kind == "storage"
			else INPUT_PORT_COLOR if kind == "input"
			else OUTPUT_PORT_COLOR
		)
		var label := String(port.get("label", ""))
		var state := _context_port_state(port)
		if state == "matched":
			color = PORT_MATCH_COLOR
			label += " ✓"
		elif state == "wrong_direction":
			color = PORT_MISMATCH_COLOR
			label += " ×"
		_draw_port_marker(
			Vector2i(port["port_cell"]),
			Vector2i(port["connection_cell"]),
			color,
			label,
			0 if kind == "storage" else -1 if kind == "input" else 1,
			_context_label_offset(port)
		)


func _nearby_context_logistics_ports() -> Array[Dictionary]:
	var result: Array[Dictionary] = []
	if (
		_definition == null
		or _definition.building_id
		!= SliceBuildingCatalog.CONVEYOR_ID
	):
		return result
	for port in _context_logistics_ports:
		var connection_cell := Vector2i(port["connection_cell"])
		var offset := connection_cell - _origin_cell
		if (
			absi(offset.x) <= CONTEXT_PORT_RADIUS_CELLS
			and absi(offset.y) <= CONTEXT_PORT_RADIUS_CELLS
		):
			result.append(port)
	return result


func _context_port_state(port: Dictionary) -> String:
	if Vector2i(port["connection_cell"]) != _origin_cell:
		return ""
	var outward := Vector2i(port["outward_direction"])
	var output: Vector2i = (
		SliceConveyor.DIRECTION_ORDER[posmod(_rotation, 4)]
	)
	var kind := String(port["kind"])
	if kind == "storage":
		return (
			"matched"
			if output == outward or output == -outward
			else "wrong_direction"
		)
	if kind == "input":
		return "matched" if output == -outward else "wrong_direction"
	return "matched" if output == outward else "wrong_direction"


func _context_label_offset(port: Dictionary) -> Vector2:
	var same_cell: Array[Dictionary] = []
	var connection_cell := Vector2i(port["connection_cell"])
	for candidate in _nearby_context_logistics_ports():
		if Vector2i(candidate["connection_cell"]) == connection_cell:
			same_cell.append(candidate)
	if same_cell.size() <= 1:
		return Vector2.ZERO
	for index in range(same_cell.size()):
		var candidate := same_cell[index]
		if (
			String(candidate["instance_id"])
			== String(port["instance_id"])
			and String(candidate["kind"]) == String(port["kind"])
		):
			return Vector2(
				0.0,
				(float(index) - float(same_cell.size() - 1) * 0.5)
				* 12.0
			)
	return Vector2.ZERO


func _draw_port_marker(
	port_cell: Vector2i,
	connection_cell: Vector2i,
	color: Color,
	label: String,
	flow_direction: int,
	label_offset: Vector2 = Vector2.ZERO
) -> void:
	var port_center := _cell_center(port_cell)
	var connection_center := _cell_center(connection_cell)
	draw_circle(port_center, 7.0, color)
	draw_arc(port_center, 9.0, 0.0, TAU, 20, Color.WHITE, 1.5)
	var marker_rect := Rect2(
		connection_center - Vector2(11, 11),
		Vector2(22, 22)
	)
	var marker_fill := color
	marker_fill.a = 0.78
	draw_rect(marker_rect, marker_fill, true)
	draw_rect(marker_rect, Color.WHITE, false, 1.5)
	if flow_direction <= 0:
		_draw_arrow(connection_center, port_center, color)
	if flow_direction >= 0:
		_draw_arrow(port_center, connection_center, color)
	draw_string(
		ThemeDB.fallback_font,
		connection_center + Vector2(-10, 4) + label_offset,
		label,
		HORIZONTAL_ALIGNMENT_CENTER,
		20.0,
		10,
		PORT_TEXT_COLOR
	)


func _draw_arrow(
	from_point: Vector2,
	to_point: Vector2,
	color: Color
) -> void:
	var direction := (to_point - from_point).normalized()
	if direction == Vector2.ZERO:
		return
	var perpendicular := Vector2(-direction.y, direction.x)
	var arrow_base := to_point - direction * 10.0
	draw_line(from_point, to_point, color, 3.0)
	draw_colored_polygon(
		PackedVector2Array([
			to_point,
			arrow_base + perpendicular * 5.0,
			arrow_base - perpendicular * 5.0,
		]),
		color
	)


func _cell_center(cell: Vector2i) -> Vector2:
	var parent_position: Vector2 = (get_parent() as Node2D).position
	return (
		(Vector2(cell) + Vector2(0.5, 0.5)) * _tile_size
		- parent_position
	)
