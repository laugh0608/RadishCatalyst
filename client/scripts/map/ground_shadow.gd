extends Sprite2D
class_name GroundShadow

@export_node_path("Sprite2D") var target_path: NodePath
@export_range(0.05, 0.5, 0.01) var vertical_compression := 0.18
@export_range(0.0, 0.2, 0.01) var horizontal_offset_ratio := 0.08
@export var ground_offset := Vector2(2.0, 2.0)
@export var shadow_color := Color(0.08, 0.11, 0.12, 0.26)

var target_sprite: Sprite2D


func _ready() -> void:
	z_as_relative = false
	target_sprite = get_node_or_null(target_path) as Sprite2D
	if target_sprite == null:
		visible = false
		set_process(false)
		push_warning("GroundShadow target is missing: %s" % target_path)
		return
	_sync_from_target()


func _process(_delta: float) -> void:
	_sync_from_target()


func _sync_from_target() -> void:
	if target_sprite == null or target_sprite.texture == null:
		visible = false
		return

	texture = target_sprite.texture
	centered = target_sprite.centered
	offset = target_sprite.offset
	flip_h = target_sprite.flip_h
	flip_v = target_sprite.flip_v
	hframes = target_sprite.hframes
	vframes = target_sprite.vframes
	frame = target_sprite.frame

	var target_scale := target_sprite.scale
	var source_height := float(texture.get_height()) * absf(target_scale.y)
	var foot_alignment_offset := source_height * (1.0 - vertical_compression) * 0.5
	position = target_sprite.position + Vector2(
		source_height * horizontal_offset_ratio + ground_offset.x,
		foot_alignment_offset + ground_offset.y
	)
	rotation = 0.0
	scale = Vector2(absf(target_scale.x), absf(target_scale.y) * vertical_compression)

	var target_alpha := target_sprite.modulate.a * target_sprite.self_modulate.a
	self_modulate = Color(
		shadow_color.r,
		shadow_color.g,
		shadow_color.b,
		shadow_color.a * target_alpha
	)
	visible = target_sprite.visible
