class_name IndustrialVolumeStudy
extends Node2D

## Independently normalized art assembled at world-pixel scale. No gameplay state.

const ASSET_ROOT := "res://assets/sprites/visual_studies/industrial_volume_v1/"
const UI_THEME := preload("res://assets/themes/slice_ui_theme.tres")
const QUIET_FLOOR := preload("res://assets/tiles/demo_presentation_rebuild/metal_platform_floor.png")

var machine_root: Node2D
var pipe_root: Node2D
var shadows: Node2D
var quiet_floor: Sprite2D
var supports: Array[Sprite2D] = []
var shadow_button: Button
var support_button: Button
var floor_button: Button


func _ready() -> void:
	y_sort_enabled = true
	texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	var ground := Node2D.new()
	ground.name = "GroundPresentation"
	add_child(ground)
	quiet_floor = Sprite2D.new()
	quiet_floor.name = "ExistingQuietFloor"
	quiet_floor.texture = QUIET_FLOOR
	quiet_floor.centered = false
	quiet_floor.region_enabled = true
	quiet_floor.region_rect = Rect2(0, 0, 384, 256)
	quiet_floor.position = Vector2(-64, -32)
	ground.add_child(quiet_floor)
	shadows = Node2D.new()
	shadows.name = "GeneratedGroundShadows"
	ground.add_child(shadows)
	var machine_shadow := _sprite(shadows, "machine_shadow", Vector2(14, 70))
	machine_shadow.scale.y = 0.5
	machine_shadow.modulate.a = 0.34
	_sprite(shadows, "pipe_shadow", Vector2(108, 86)).modulate.a = 0.32
	for x in [118, 163]:
		_sprite(shadows, "support_shadow", Vector2(x + 3, 81)).modulate.a = 0.30
	# These roots sort by contact depth alongside the real player. Their children
	# retain authored draw order so the tube occludes the upper cradle edges.
	machine_root = _sort_root("MachineContact", Vector2(64, 106))
	_sprite(machine_root, "machine", Vector2(-64, -106))
	pipe_root = _sort_root("PipeContact", Vector2(150, 86))
	for x in [118, 163]:
		supports.append(_sprite(pipe_root, "support", Vector2(x, 55) - pipe_root.position))
	_sprite(pipe_root, "pipe", Vector2(100, 44) - pipe_root.position)
	_build_controls()
	_refresh_controls()


func _sort_root(node_name: String, at: Vector2) -> Node2D:
	var node := Node2D.new()
	node.name = node_name
	node.position = at
	add_child(node)
	return node


func _sprite(parent: Node2D, asset: String, at: Vector2) -> Sprite2D:
	var sprite := Sprite2D.new()
	sprite.name = asset.to_pascal_case()
	sprite.texture = load(ASSET_ROOT + asset + ".png") as Texture2D
	assert(sprite.texture != null, "Volume specimen requires its normalized raster assets.")
	sprite.centered = false
	sprite.position = at
	parent.add_child(sprite)
	return sprite


func _build_controls() -> void:
	var layer := CanvasLayer.new()
	layer.name = "VolumeStudyControls"
	layer.layer = 30
	add_child(layer)
	var panel := PanelContainer.new()
	panel.theme = UI_THEME
	panel.set_anchors_and_offsets_preset(Control.PRESET_CENTER_BOTTOM)
	panel.offset_left = -390
	panel.offset_right = 390
	panel.offset_top = -205
	panel.offset_bottom = -115
	layer.add_child(panel)
	var layout := VBoxContainer.new()
	panel.add_child(layout)
	var label := Label.new()
	label.text = "体积样板 · 视觉演示  |  WASD 观察前后遮挡"
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	layout.add_child(label)
	var row := HBoxContainer.new()
	row.alignment = BoxContainer.ALIGNMENT_CENTER
	layout.add_child(row)
	shadow_button = _button(row, func():
		shadows.visible = not shadows.visible
		_refresh_controls()
	)
	support_button = _button(row, func():
		for support in supports:
			support.visible = not support.visible
		_refresh_controls()
	)
	floor_button = _button(row, func():
		quiet_floor.visible = not quiet_floor.visible
		_refresh_controls()
	)


func _button(parent: HBoxContainer, callback: Callable) -> Button:
	var button := Button.new()
	button.pressed.connect(callback)
	parent.add_child(button)
	return button


func _refresh_controls() -> void:
	shadow_button.text = "阴影：开" if shadows.visible else "阴影：关"
	support_button.text = "支撑：开" if supports[0].visible else "支撑：关"
	floor_button.text = "地面：低纹理" if quiet_floor.visible else "地面：现有工业地板"
