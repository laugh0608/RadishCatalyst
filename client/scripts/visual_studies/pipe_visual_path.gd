class_name PipeVisualPath
extends Node2D

## One deterministic visual specimen. It owns no inventory or network state.

enum ContentState { FLOW, IDLE, EMPTY }

const TILE_SIZE := 32.0
const MARKER_PITCH := 48.0
const PREVIEW_SPEED := 18.0
const CORNER_RADIUS := 8.0
const CORNER_LENGTH := 16.0 + PI * CORNER_RADIUS * 0.5
const ASSET_ROOT := "res://assets/sprites/visual_studies/transparent_pipe_v1/"
const FLOW_SHADER := preload("res://scripts/visual_studies/pipe_flow_visual.gdshader")
const MATERIAL_A := Color("56c8c4")
const MATERIAL_B := Color("e0a43c")
const SEGMENTS := [
	["port_right", Vector2i(0, 0), 0, 19.0],
	["horizontal", Vector2i(1, 0), 0, 32.0],
	["horizontal", Vector2i(2, 0), 0, 32.0],
	["horizontal", Vector2i(3, 0), 0, 32.0],
	["horizontal", Vector2i(4, 0), 0, 32.0],
	["elbow_left_down", Vector2i(5, 0), 2, CORNER_LENGTH],
	["vertical", Vector2i(5, 1), 1, 32.0],
	["vertical", Vector2i(5, 2), 1, 32.0],
	["vertical", Vector2i(5, 3), 1, 32.0],
]

var content_state := ContentState.FLOW
var fluid_color := MATERIAL_A
var flow_direction := 1
var phase := 0.0
var animation_paused := false
var path_length := 0.0
var _materials: Array[ShaderMaterial] = []


func _ready() -> void:
	texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	_build_segments()
	_sync_materials()


func _process(delta: float) -> void:
	advance_preview(delta)


func configure(state: ContentState, color: Color, direction: int = 1) -> bool:
	if state not in [ContentState.FLOW, ContentState.IDLE, ContentState.EMPTY]:
		push_error("Unknown pipe specimen content state.")
		return false
	if direction not in [-1, 1] or not (is_finite(color.r) and is_finite(color.g) and is_finite(color.b) and is_finite(color.a)) or color.a <= 0.0:
		push_error("Invalid pipe specimen color or direction.")
		return false
	content_state = state
	fluid_color = color
	flow_direction = direction
	_sync_materials()
	return true


func advance_preview(delta: float) -> void:
	if animation_paused or content_state != ContentState.FLOW:
		return
	phase = fposmod(phase + maxf(delta, 0.0) * PREVIEW_SPEED * flow_direction, MARKER_PITCH)
	for material in _materials:
		material.set_shader_parameter("phase", phase)


func set_preview_phase(value: float) -> void:
	phase = fposmod(value, MARKER_PITCH)
	_sync_materials()


func segment_offsets() -> PackedFloat32Array:
	var result := PackedFloat32Array()
	for material in _materials:
		result.append(float(material.get_shader_parameter("path_offset")))
	return result


func sample_path(distance: float) -> Dictionary:
	var remaining := clampf(distance, 0.0, path_length)
	for index in SEGMENTS.size():
		var definition: Array = SEGMENTS[index]
		var length := float(definition[3])
		if remaining > length and index < SEGMENTS.size() - 1:
			remaining -= length
			continue
		var origin := Vector2(definition[1]) * TILE_SIZE
		var point := Vector2(remaining, 16.0)
		var tangent := Vector2.RIGHT
		if index == 0:
			point.x += 13.0
		elif int(definition[2]) == 1:
			point = Vector2(16.0, remaining)
			tangent = Vector2.DOWN
		elif int(definition[2]) == 2:
			if remaining <= 8.0:
				point = Vector2(remaining, 16.0)
			elif remaining < 8.0 + CORNER_RADIUS * PI * 0.5:
				var angle := (remaining - 8.0) / CORNER_RADIUS
				point = Vector2(8.0 + sin(angle) * CORNER_RADIUS, 24.0 - cos(angle) * CORNER_RADIUS)
				tangent = Vector2(cos(angle), sin(angle))
			else:
				point = Vector2(16.0, 24.0 + remaining - 8.0 - CORNER_RADIUS * PI * 0.5)
				tangent = Vector2.DOWN
		return {"position": origin + point, "tangent": tangent, "segment": index}
	return {}


func _build_segments() -> void:
	path_length = 0.0
	for index in SEGMENTS.size():
		var definition: Array = SEGMENTS[index]
		var module_name := String(definition[0])
		var position_in_path := Vector2(definition[1]) * TILE_SIZE
		var body_texture := load(ASSET_ROOT + module_name + ".png") as Texture2D
		var mask_texture := load(ASSET_ROOT + module_name + "_content_mask.png") as Texture2D
		assert(body_texture != null and mask_texture != null, "Pipe specimen textures must exist.")
		var content := Sprite2D.new()
		content.name = "Content%d" % index
		content.centered = false
		content.position = position_in_path
		content.texture = mask_texture
		var material := ShaderMaterial.new()
		material.shader = FLOW_SHADER
		material.set_shader_parameter("segment_kind", int(definition[2]))
		material.set_shader_parameter("path_offset", path_length - (13.0 if index == 0 else 0.0))
		content.material = material
		_materials.append(material)
		add_child(content)
		var body := Sprite2D.new()
		body.name = "Body%d" % index
		body.centered = false
		body.position = position_in_path
		body.texture = body_texture
		body.z_index = 1
		add_child(body)
		path_length += float(definition[3])


func _sync_materials() -> void:
	for material in _materials:
		material.set_shader_parameter("fluid_color", fluid_color)
		material.set_shader_parameter("direction", float(flow_direction))
		material.set_shader_parameter("phase", phase)
		material.set_shader_parameter("has_content", content_state != ContentState.EMPTY)
		material.set_shader_parameter("marker_opacity", 0.26 if content_state == ContentState.IDLE else 1.0)
