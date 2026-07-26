extends Sprite2D
class_name GroundShadow

@export_node_path("Node2D") var target_path: NodePath
@export_range(0.05, 0.5, 0.01) var vertical_compression := 0.18
@export_range(0.0, 0.2, 0.01) var horizontal_offset_ratio := 0.08
@export var ground_offset := Vector2(2.0, 2.0)
@export var shadow_color := Color(0.08, 0.11, 0.12, 0.26)

var target_node: Node2D


func _ready() -> void:
	target_node = get_node_or_null(target_path) as Node2D
	if target_node == null:
		visible = false
		set_process(false)
		push_warning("GroundShadow target is missing: %s" % target_path)
		return
	if not target_node is Sprite2D and not target_node is AnimatedSprite2D:
		visible = false
		set_process(false)
		push_warning("GroundShadow target must be Sprite2D or AnimatedSprite2D.")
		return
	_sync_from_target()


func _process(_delta: float) -> void:
	_sync_from_target()


func _sync_from_target() -> void:
	var target_texture := _target_texture()
	if target_node == null or target_texture == null:
		visible = false
		return

	texture = target_texture
	hframes = 1
	vframes = 1
	frame = 0
	if target_node is Sprite2D:
		var sprite := target_node as Sprite2D
		centered = sprite.centered
		offset = sprite.offset
		flip_h = sprite.flip_h
		flip_v = sprite.flip_v
		hframes = sprite.hframes
		vframes = sprite.vframes
		frame = sprite.frame
	else:
		var animated := target_node as AnimatedSprite2D
		centered = animated.centered
		offset = animated.offset
		flip_h = animated.flip_h
		flip_v = animated.flip_v

	var target_scale := target_node.scale
	var source_height := float(texture.get_height()) * absf(target_scale.y)
	var foot_alignment_offset := source_height * (1.0 - vertical_compression) * 0.5
	var target_position := (
		Vector2.ZERO
		if target_node == get_parent()
		else target_node.position
	)
	position = target_position + Vector2(
		source_height * horizontal_offset_ratio + ground_offset.x,
		foot_alignment_offset + ground_offset.y
	)
	rotation = 0.0
	scale = Vector2(absf(target_scale.x), absf(target_scale.y) * vertical_compression)

	var target_alpha := target_node.modulate.a * target_node.self_modulate.a
	self_modulate = Color(
		shadow_color.r,
		shadow_color.g,
		shadow_color.b,
		shadow_color.a * target_alpha
	)
	visible = target_node.visible


func _target_texture() -> Texture2D:
	if target_node is Sprite2D:
		return (target_node as Sprite2D).texture
	if target_node is AnimatedSprite2D:
		var animated := target_node as AnimatedSprite2D
		if animated.sprite_frames == null:
			return null
		return animated.sprite_frames.get_frame_texture(
			animated.animation, animated.frame
		)
	return null
