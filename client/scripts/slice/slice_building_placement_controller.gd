class_name SliceBuildingPlacementController
extends Node2D

## Owns the current building selection, rotation, snapped origin and real-asset
## preview. World rules are supplied as one validation result; production,
## power and persistence remain outside this controller.

const VALID_COLOR := Color(0.45, 1.0, 0.9, 0.55)
const INVALID_COLOR := Color(1.0, 0.4, 0.35, 0.55)

var definition: SliceBuildingDefinition
var rotation_index := 0
var target_origin := Vector2i.ZERO
var target_valid := false
var invalid_reason := ""

var _overlay := SlicePlacementOverlay.new()
var _preview := Sprite2D.new()
var _validation: Dictionary = {}


func _ready() -> void:
	_overlay.visible = false
	_overlay.z_index = 1
	add_child(_overlay)
	_preview.visible = false
	add_child(_preview)


func begin(
	next_definition: SliceBuildingDefinition,
	initial_rotation: int = 0
) -> void:
	definition = next_definition
	rotation_index = definition.normalized_rotation(initial_rotation)
	target_valid = false
	invalid_reason = ""
	_validation.clear()
	_configure_preview()
	_overlay.clear()


func cancel() -> void:
	definition = null
	rotation_index = 0
	target_valid = false
	invalid_reason = ""
	_validation.clear()
	_preview.visible = false
	_overlay.clear()


func is_active() -> bool:
	return definition != null


func rotate_clockwise() -> void:
	if definition == null or not definition.allows_rotation:
		return
	rotation_index = posmod(rotation_index + 1, 4)
	_apply_preview_texture()


func update_target(
	origin_cell: Vector2i,
	world_position: Vector2,
	validation: Dictionary,
	tile_size: float = 32.0,
	power_nodes: Array[Dictionary] = [],
	logistics_ports: Array[Dictionary] = []
) -> void:
	if definition == null:
		return
	target_origin = origin_cell
	position = world_position
	target_valid = bool(validation.get("valid", false))
	invalid_reason = String(validation.get("reason", ""))
	_validation = validation.duplicate(true)
	_preview.modulate = VALID_COLOR if target_valid else INVALID_COLOR
	_preview.visible = true
	_overlay.configure(
		definition,
		origin_cell,
		rotation_index,
		tile_size,
		validation,
		power_nodes,
		logistics_ports
	)


func selected_building_id() -> String:
	return "" if definition == null else definition.building_id


func missing_floor_cells() -> Array[Vector2i]:
	var result: Array[Vector2i] = []
	for cell in _validation.get("missing_floor_cells", []):
		result.append(Vector2i(cell))
	return result


func logistics_feedback_text() -> String:
	var preview: Dictionary = _validation.get(
		"logistics_preview", {}
	)
	return String(preview.get("message", ""))


func world_position_from_screen(screen_position: Vector2) -> Vector2:
	return get_canvas_transform().affine_inverse() * screen_position


func _configure_preview() -> void:
	if definition == null:
		_preview.visible = false
		return
	_preview.position = definition.sprite_offset
	_preview.region_enabled = definition.texture_region.size != Vector2.ZERO
	if _preview.region_enabled:
		_preview.region_rect = definition.texture_region
	_apply_preview_texture()
	_preview.visible = true


func _apply_preview_texture() -> void:
	var texture_path := definition.texture_path_for_rotation(rotation_index)
	_preview.texture = (
		null if texture_path.is_empty() else load(texture_path) as Texture2D
	)
