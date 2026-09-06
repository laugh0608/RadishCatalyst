class_name RaisedPipeVisualPath
extends PipeVisualPath

## Shares the tested path metric and animation semantics with the flat study;
## this specimen supplies independently generated volume art and contact sorting.

const RAISED_ASSETS := "res://assets/sprites/visual_studies/raised_pipe_v1/"
const SUPPORT_TEXTURE := preload("res://assets/sprites/visual_studies/industrial_volume_v1/support.png")
const SUPPORT_SHADOW := preload("res://assets/sprites/visual_studies/industrial_volume_v1/support_shadow.png")
const ELEVATION := 16.0

var body_visuals: Array[CanvasItem] = []
var support_visuals: Array[Sprite2D] = []
var ground_shadows: Node2D
var segment_roots: Array[Node2D] = []


func _build_segments() -> void:
	y_sort_enabled = true
	ground_shadows = Node2D.new()
	ground_shadows.name = "PipeGroundShadows"
	add_child(ground_shadows)
	path_length = 0.0
	for index in SEGMENTS.size():
		var definition: Array = SEGMENTS[index]
		var module_name := String(definition[0])
		var cell_origin := Vector2(definition[1]) * TILE_SIZE
		var contact := Node2D.new()
		contact.name = "SegmentContact%d" % index
		contact.position = cell_origin + Vector2(16, 24)
		add_child(contact)
		segment_roots.append(contact)
		var shadow := _sprite(ground_shadows, module_name + "_shadow", cell_origin + Vector2(4, 10))
		shadow.modulate.a = 0.30
		if index in [1, 3, 5, 7]:
			var offsets := [-8, 8] if int(definition[2]) == 1 else [0]
			for x in offsets:
				var support := Sprite2D.new()
				support.name = "Support%d" % support_visuals.size()
				support.centered = false
				support.texture = SUPPORT_TEXTURE
				support.position = Vector2(x - 16, -28)
				contact.add_child(support)
				support_visuals.append(support)
				body_visuals.append(support)
				var support_shadow := Sprite2D.new()
				support_shadow.centered = false
				support_shadow.texture = SUPPORT_SHADOW
				support_shadow.position = cell_origin + Vector2(x + 3, 24)
				support_shadow.modulate.a = 0.30
				ground_shadows.add_child(support_shadow)
		var image_position := Vector2(-16, -24 - ELEVATION)
		var content := _sprite(contact, module_name + "_content_mask", image_position)
		content.name = "Content"
		var material := ShaderMaterial.new()
		material.shader = FLOW_SHADER
		material.set_shader_parameter("segment_kind", int(definition[2]))
		material.set_shader_parameter("path_offset", path_length - (13.0 if index == 0 else 0.0))
		material.set_shader_parameter("layered_content", true)
		content.material = material
		_materials.append(material)
		body_visuals.append(content)
		var body := _sprite(contact, module_name, image_position)
		body.name = "Body"
		body_visuals.append(body)
		path_length += float(definition[3])


func _sprite(parent: Node2D, asset: String, at: Vector2) -> Sprite2D:
	var result := Sprite2D.new()
	result.centered = false
	result.texture = load(RAISED_ASSETS + asset + ".png") as Texture2D
	assert(result.texture != null, "Raised pipe specimen requires its declared raster assets.")
	result.position = at
	parent.add_child(result)
	return result
