class_name SliceCoreVisual
extends Node2D

## Y-sorted presentation shell for the fixed map core. The logical core stays
## at its frozen world position; this sibling shell sorts at the footprint
## front edge so belts remain behind it and the player can still pass in front.

const SORT_ANCHOR_OFFSET := Vector2(0, 33)
const SPRITE_POSITION := Vector2(0, -33)
const REPAIRED_SPRITE_OFFSET := Vector2(0, -32)
const INPUT_DOCKING_POSITION := Vector2(-66, 13)
const OUTPUT_DOCKING_POSITION := Vector2(66, 13)
const DOCKING_PATCH_SIZE := Vector2(12, 24)
const INPUT_DOCKING_TEXTURE_LOCAL_ANCHOR := Vector2i(0, 97)
const OUTPUT_DOCKING_TEXTURE_LOCAL_ANCHOR := Vector2i(132, 97)
const LEFT_DOCKING_TEXTURE := preload(
	"res://assets/sprites/slice/docking_left_connected_patch.png"
)
const RIGHT_DOCKING_TEXTURE := preload(
	"res://assets/sprites/slice/docking_right_connected_patch.png"
)


func apply_repaired_texture(texture: Texture2D) -> void:
	var sprite := _sprite()
	if sprite == null:
		return
	sprite.texture = texture
	sprite.offset = REPAIRED_SPRITE_OFFSET


func set_connected_logistics_port_visuals(
	connected_port_ids: Array[String]
) -> void:
	_set_docking_patch(
		"InputDockingPatch",
		LEFT_DOCKING_TEXTURE,
		INPUT_DOCKING_POSITION,
		connected_port_ids.has("input")
	)
	_set_docking_patch(
		"OutputDockingPatch",
		RIGHT_DOCKING_TEXTURE,
		OUTPUT_DOCKING_POSITION,
		connected_port_ids.has("output")
	)


func set_core_modulate(color: Color) -> void:
	var sprite := _sprite()
	if sprite != null:
		sprite.self_modulate = color


func core_sprite() -> Sprite2D:
	return _sprite()


func _set_docking_patch(
	node_name: String,
	texture: Texture2D,
	local_position: Vector2,
	shown: bool
) -> void:
	var sprite := _sprite()
	if sprite == null:
		return
	var patch := sprite.get_node_or_null(node_name) as Sprite2D
	if patch == null and shown:
		patch = Sprite2D.new()
		patch.name = node_name
		patch.texture = texture
		patch.position = local_position
		patch.z_index = 0
		sprite.add_child(patch)
	if patch != null:
		patch.visible = shown


func _sprite() -> Sprite2D:
	return get_node_or_null("Sprite") as Sprite2D
