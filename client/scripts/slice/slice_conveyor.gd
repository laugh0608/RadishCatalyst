class_name SliceConveyor
extends SliceBuildingInstance

## One L4 belt cell owns at most one transported item. The logistics grid owns
## transfer rules and derived topology; this instance owns serializable cargo
## state plus fixed-frame topology and orthogonal cargo presentation.

const CARGO_TEXTURES := {
	"crystal": preload("res://assets/sprites/slice/cargo_crystal.png"),
	"catalyst": preload("res://assets/sprites/slice/cargo_catalyst.png"),
}
const TRAVEL_EDGE_OFFSET := 12.0
const TOPOLOGY_STRAIGHT := "straight"
const TOPOLOGY_TURN := "turn"
const TOPOLOGY_MERGE := "merge"
const TOPOLOGY_SOURCE_ENDPOINT := "source_endpoint"
const TOPOLOGY_SINK_ENDPOINT := "sink_endpoint"
const DIRECTION_ORDER := [
	Vector2i.UP,
	Vector2i.RIGHT,
	Vector2i.DOWN,
	Vector2i.LEFT,
]
const DIRECTION_NAMES := {
	Vector2i.UP: "up",
	Vector2i.RIGHT: "right",
	Vector2i.DOWN: "down",
	Vector2i.LEFT: "left",
}

var cargo_item_id := ""
var cargo_progress := 0.0
var merge_cursor := 0
var _topology_kind := TOPOLOGY_STRAIGHT
var _entry_direction := Vector2i.ZERO
var _topology_input_directions: Array[Vector2i] = []
var _cargo_entry_direction := Vector2i.ZERO


func apply_definition(
	next_definition: SliceBuildingDefinition,
	tile_size: float
) -> void:
	super.apply_definition(next_definition, tile_size)
	_refresh_cargo_visual()


func has_cargo() -> bool:
	return not cargo_item_id.is_empty()


func set_cargo(
	item_id: String,
	progress: float,
	entry_direction: Vector2i = Vector2i.ZERO
) -> void:
	cargo_item_id = item_id
	cargo_progress = clampf(progress, 0.0, 1.0)
	_cargo_entry_direction = entry_direction
	_refresh_cargo_visual()


func set_cargo_progress(progress: float) -> void:
	cargo_progress = clampf(progress, 0.0, 1.0)
	_refresh_cargo_visual()


func clear_cargo() -> void:
	cargo_item_id = ""
	cargo_progress = 0.0
	_cargo_entry_direction = Vector2i.ZERO
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


func set_topology_visual(
	kind: String,
	input_directions: Array[Vector2i]
) -> void:
	_topology_kind = kind
	_topology_input_directions = input_directions.duplicate()
	_topology_input_directions.sort_custom(_direction_before)
	_entry_direction = (
		_topology_input_directions[0]
		if not _topology_input_directions.is_empty()
		else -output_direction()
	)
	if (
		not has_cargo()
		or not _topology_input_directions.has(_cargo_entry_direction)
	):
		_cargo_entry_direction = _entry_direction
	_refresh_topology_texture()
	_refresh_cargo_visual()


func topology_kind() -> String:
	return _topology_kind


func entry_direction() -> Vector2i:
	return _entry_direction


func topology_input_directions() -> Array[Vector2i]:
	return _topology_input_directions.duplicate()


func cargo_entry_direction() -> Vector2i:
	return _cargo_entry_direction


func set_cargo_entry_direction(direction: Vector2i) -> void:
	_cargo_entry_direction = direction
	_refresh_cargo_visual()


func cargo_local_position_for_progress(progress: float) -> Vector2:
	var center := definition.local_footprint_center_offset(
		_tile_size, building_rotation
	)
	var output := output_direction()
	var entry := (
		_cargo_entry_direction
		if _cargo_entry_direction != Vector2i.ZERO
		else -output
	)
	var start := center + Vector2(entry) * TRAVEL_EDGE_OFFSET
	var finish := center + Vector2(output) * TRAVEL_EDGE_OFFSET
	var clamped := clampf(progress, 0.0, 1.0)
	if entry.x * output.x + entry.y * output.y == 0:
		if clamped <= 0.5:
			return start.lerp(center, clamped * 2.0)
		return center.lerp(finish, (clamped - 0.5) * 2.0)
	return start.lerp(finish, clamped)


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
		sprite.z_index = 4
		add_child(sprite)
	sprite.texture = CARGO_TEXTURES.get(cargo_item_id) as Texture2D
	sprite.visible = true
	sprite.position = cargo_local_position_for_progress(cargo_progress)


func _refresh_topology_texture() -> void:
	var sprite := get_node_or_null("Sprite") as Sprite2D
	if sprite == null or definition == null:
		return
	var output_name := String(DIRECTION_NAMES.get(output_direction(), ""))
	var texture_path := ""
	match _topology_kind:
		TOPOLOGY_TURN:
			var entry_name := String(
				DIRECTION_NAMES.get(_entry_direction, "")
			)
			if not entry_name.is_empty() and not output_name.is_empty():
				texture_path = (
					"res://assets/sprites/slice/"
					+ "conveyor_in_%s_out_%s.png"
					% [entry_name, output_name]
				)
		TOPOLOGY_MERGE:
			var input_names: Array[String] = []
			for direction in _topology_input_directions:
				input_names.append(
					String(DIRECTION_NAMES.get(direction, ""))
				)
			if input_names.size() >= 2 and not output_name.is_empty():
				texture_path = (
					"res://assets/sprites/slice/"
					+ "conveyor_merge_in_%s_out_%s.png"
					% ["_".join(input_names), output_name]
				)
		TOPOLOGY_SOURCE_ENDPOINT:
			texture_path = (
				"res://assets/sprites/slice/conveyor_source_%s.png"
				% output_name
			)
		TOPOLOGY_SINK_ENDPOINT:
			texture_path = (
				"res://assets/sprites/slice/conveyor_sink_%s.png"
				% output_name
			)
	if texture_path.is_empty():
		texture_path = definition.texture_path_for_rotation(
			building_rotation
		)
	sprite.z_index = (
		-1
		if _topology_kind in [
			TOPOLOGY_SOURCE_ENDPOINT,
			TOPOLOGY_SINK_ENDPOINT,
		]
		else 0
	)
	sprite.texture = load(texture_path) as Texture2D


func _direction_before(left: Vector2i, right: Vector2i) -> bool:
	return DIRECTION_ORDER.find(left) < DIRECTION_ORDER.find(right)
