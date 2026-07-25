class_name SliceBuildingDefinition
extends RefCounted

## Immutable rules for one placeable slice building. Directional devices use
## four approved fixed sprites in up / right / down / left order; runtime
## rotation only selects a frame and never rotates pixel art.

const SURFACE_BUILDABLE_ROCK := "buildable_rock"
const SURFACE_CRYSTAL := "crystal"
const SURFACE_INDUSTRIAL_FLOOR := "industrial_floor"
const POWER_PASSIVE := "passive"
const POWER_RELAY := "relay"
const POWER_CONSUMER := "consumer"

var building_id: String
var kit_item_id: String
var display_name: String
var footprint: Vector2i
var allows_rotation: bool
var surface_rule: String
var blocks_movement: bool
var is_floor: bool
var scene_path: String
var texture_paths: Array[String]
var sprite_offset: Vector2
var texture_region: Rect2
var state_keys: Array[String]
var power_role: String
var power_port_cell: Vector2i
var powered_texture_path: String
var power_indicator_offset: Vector2
var logistics_port_cell: Vector2i
var logistics_port_direction: Vector2i


func _init(
	id: String,
	kit_id: String,
	label: String,
	base_footprint: Vector2i,
	can_rotate: bool,
	required_surface: String,
	blocks: bool,
	floor_layer: bool,
	scene: String = "",
	textures: Array[String] = [],
	visual_offset: Vector2 = Vector2.ZERO,
	region: Rect2 = Rect2(),
	allowed_state_keys: Array[String] = [],
	role: String = POWER_PASSIVE,
	port_cell: Vector2i = Vector2i(-1, -1),
	powered_texture: String = "",
	indicator_offset: Vector2 = Vector2(-8, -8),
	logistics_cell: Vector2i = Vector2i(-1, -1),
	logistics_direction: Vector2i = Vector2i.ZERO
) -> void:
	building_id = id
	kit_item_id = kit_id
	display_name = label
	footprint = base_footprint
	allows_rotation = can_rotate
	surface_rule = required_surface
	blocks_movement = blocks
	is_floor = floor_layer
	scene_path = scene
	texture_paths = textures.duplicate()
	sprite_offset = visual_offset
	texture_region = region
	state_keys = allowed_state_keys.duplicate()
	power_role = role
	power_port_cell = port_cell
	powered_texture_path = powered_texture
	power_indicator_offset = indicator_offset
	logistics_port_cell = logistics_cell
	logistics_port_direction = logistics_direction


func normalized_rotation(rotation: int) -> int:
	return posmod(rotation, 4) if allows_rotation else 0


func rotated_footprint(rotation: int) -> Vector2i:
	var normalized := normalized_rotation(rotation)
	if normalized % 2 == 1:
		return Vector2i(footprint.y, footprint.x)
	return footprint


func occupied_cells(origin_cell: Vector2i, rotation: int) -> Array[Vector2i]:
	var size := rotated_footprint(rotation)
	var result: Array[Vector2i] = []
	for y in range(size.y):
		for x in range(size.x):
			result.append(origin_cell + Vector2i(x, y))
	return result


func origin_for_target(target_position: Vector2, tile_size: float, rotation: int) -> Vector2i:
	var size := Vector2(rotated_footprint(rotation))
	return Vector2i(
		roundi(target_position.x / tile_size - size.x * 0.5),
		roundi(target_position.y / tile_size - size.y * 0.5)
	)


func block_center(origin_cell: Vector2i, tile_size: float, rotation: int) -> Vector2:
	var size := Vector2(rotated_footprint(rotation))
	return Vector2(origin_cell) * tile_size + size * tile_size * 0.5


func sort_anchor_world_position(
	origin_cell: Vector2i,
	tile_size: float,
	rotation: int
) -> Vector2:
	var size := Vector2(rotated_footprint(rotation))
	return Vector2(
		(float(origin_cell.x) + size.x * 0.5) * tile_size,
		(float(origin_cell.y) + size.y) * tile_size
	)


func local_footprint_center_offset(
	tile_size: float,
	rotation: int
) -> Vector2:
	var size := Vector2(rotated_footprint(rotation))
	return Vector2(0.0, -size.y * tile_size * 0.5)


func texture_path_for_rotation(rotation: int) -> String:
	if texture_paths.is_empty():
		return ""
	if texture_paths.size() == 1:
		return texture_paths[0]
	return texture_paths[normalized_rotation(rotation) % texture_paths.size()]


func rotated_power_port_cell(rotation: int) -> Vector2i:
	return _rotated_local_cell(power_port_cell, rotation)


func rotated_logistics_port_cell(rotation: int) -> Vector2i:
	return _rotated_local_cell(logistics_port_cell, rotation)


func logistics_direction_for_rotation(rotation: int) -> Vector2i:
	var direction := logistics_port_direction
	for _step in range(normalized_rotation(rotation)):
		direction = Vector2i(-direction.y, direction.x)
	return direction


func logistics_port_world_cell(
	origin_cell: Vector2i,
	rotation: int
) -> Vector2i:
	var port := rotated_logistics_port_cell(rotation)
	return origin_cell + port


func logistics_connection_world_cell(
	origin_cell: Vector2i,
	rotation: int
) -> Vector2i:
	return (
		logistics_port_world_cell(origin_cell, rotation)
		+ logistics_direction_for_rotation(rotation)
	)


func _rotated_local_cell(cell: Vector2i, rotation: int) -> Vector2i:
	if cell.x < 0 or cell.y < 0:
		return cell
	var point := cell
	var size := footprint
	for _step in range(normalized_rotation(rotation)):
		point = Vector2i(size.y - 1 - point.y, point.x)
		size = Vector2i(size.y, size.x)
	return point


func power_port_world_position(
	origin_cell: Vector2i,
	tile_size: float,
	rotation: int
) -> Vector2:
	var port := rotated_power_port_cell(rotation)
	if port.x < 0 or port.y < 0:
		return block_center(origin_cell, tile_size, rotation)
	return (Vector2(origin_cell + port) + Vector2(0.5, 0.5)) * tile_size
