class_name SliceBuildingDefinition
extends RefCounted

## Immutable rules for one placeable slice building. Package 1 keeps the
## catalog intentionally small (industrial floor and collector), while the
## footprint, surface, render and state boundaries are already shared by later
## L3 building types.

const SURFACE_BUILDABLE_ROCK := "buildable_rock"
const SURFACE_CRYSTAL := "crystal"

var building_id: String
var kit_item_id: String
var display_name: String
var footprint: Vector2i
var allows_rotation: bool
var surface_rule: String
var blocks_movement: bool
var is_floor: bool
var scene_path: String
var texture_path: String
var sprite_offset: Vector2
var texture_region: Rect2
var state_keys: Array[String]


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
	texture: String = "",
	visual_offset: Vector2 = Vector2.ZERO,
	region: Rect2 = Rect2(),
	allowed_state_keys: Array[String] = []
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
	texture_path = texture
	sprite_offset = visual_offset
	texture_region = region
	state_keys = allowed_state_keys.duplicate()


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
