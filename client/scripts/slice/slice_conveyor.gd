class_name SliceConveyor
extends SliceBuildingInstance

## One L4 belt cell owns at most one transported item. The logistics grid owns
## transfer rules; this instance owns serializable state and its world sprite.

const CARGO_TEXTURE := preload(
	"res://assets/sprites/slice/cargo_crystal.png"
)
const TRAVEL_EDGE_OFFSET := 12.0

var cargo_item_id := ""
var cargo_progress := 0.0
var merge_cursor := 0


func apply_definition(
	next_definition: SliceBuildingDefinition,
	tile_size: float
) -> void:
	super.apply_definition(next_definition, tile_size)
	_refresh_cargo_visual()


func has_cargo() -> bool:
	return not cargo_item_id.is_empty()


func set_cargo(item_id: String, progress: float) -> void:
	cargo_item_id = item_id
	cargo_progress = clampf(progress, 0.0, 1.0)
	_refresh_cargo_visual()


func set_cargo_progress(progress: float) -> void:
	cargo_progress = clampf(progress, 0.0, 1.0)
	_refresh_cargo_visual()


func clear_cargo() -> void:
	cargo_item_id = ""
	cargo_progress = 0.0
	_refresh_cargo_visual()


func output_direction() -> Vector2i:
	match posmod(building_rotation, 4):
		0:
			return Vector2i.UP
		1:
			return Vector2i.RIGHT
		2:
			return Vector2i.DOWN
		_:
			return Vector2i.LEFT


func output_cell() -> Vector2i:
	return origin_cell + output_direction()


func content_block_reason() -> String:
	return "" if not has_cargo() else "先清空传送带"


func state_dict(allowed_keys: Array[String]) -> Dictionary:
	var result := {}
	if allowed_keys.has("cargo"):
		result["cargo"] = (
			{}
			if not has_cargo()
			else {
				"item_id": cargo_item_id,
				"progress": cargo_progress,
			}
		)
	if allowed_keys.has("merge_cursor"):
		result["merge_cursor"] = merge_cursor
	return result


func _refresh_cargo_visual() -> void:
	var sprite := get_node_or_null("Cargo") as Sprite2D
	if not has_cargo():
		if sprite != null:
			sprite.visible = false
		return
	if sprite == null:
		sprite = Sprite2D.new()
		sprite.name = "Cargo"
		sprite.texture = CARGO_TEXTURE
		sprite.z_index = 4
		add_child(sprite)
	sprite.visible = true
	var center := definition.local_footprint_center_offset(
		_tile_size, building_rotation
	)
	var direction := Vector2(output_direction())
	var start := center - direction * TRAVEL_EDGE_OFFSET
	var finish := center + direction * TRAVEL_EDGE_OFFSET
	sprite.position = start.lerp(finish, cargo_progress)
