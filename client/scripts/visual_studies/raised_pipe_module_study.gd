class_name RaisedPipeModuleStudy
extends Node2D

## Finite visual fixture, without placement, collision, fluid inventory or recipes.

const VOLUME_ASSETS := "res://assets/sprites/visual_studies/industrial_volume_v1/"
const QUIET_FLOOR := preload("res://assets/tiles/demo_presentation_rebuild/metal_platform_floor.png")
const UI_THEME := preload("res://assets/themes/slice_ui_theme.tres")

var pipe: RaisedPipeVisualPath
var ground: Node2D
var shadows: Node2D
var machine: Sprite2D
var quiet_floor: Sprite2D
var flow_button: Button
var idle_button: Button
var empty_button: Button
var color_button: Button
var reverse_button: Button
var pause_button: Button
var shadow_button: Button
var floor_button: Button


func _ready() -> void:
	y_sort_enabled = true
	texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	ground = Node2D.new()
	ground.name = "RaisedPipeGround"
	add_child(ground)
	quiet_floor = Sprite2D.new()
	quiet_floor.texture = QUIET_FLOOR
	quiet_floor.centered = false
	quiet_floor.region_enabled = true
	quiet_floor.region_rect = Rect2(0, 0, 416, 288)
	quiet_floor.position = Vector2(-32, -32)
	ground.add_child(quiet_floor)
	shadows = Node2D.new()
	shadows.name = "GroundShadows"
	ground.add_child(shadows)
	var machine_shadow := _sprite(shadows, "machine_shadow", Vector2(14, 70))
	machine_shadow.scale.y = 0.5
	machine_shadow.modulate.a = 0.34
	var machine_contact := Node2D.new()
	machine_contact.name = "MachineContact"
	machine_contact.position = Vector2(64, 106)
	add_child(machine_contact)
	machine = _sprite(machine_contact, "machine", Vector2(-64, -106))
	pipe = RaisedPipeVisualPath.new()
	pipe.name = "RaisedPipe"
	pipe.position = Vector2(96, 64)
	add_child(pipe)
	pipe.ground_shadows.reparent(shadows)
	_build_controls()
	_refresh_controls()


func configure_build_view(world: SliceWorld) -> void:
	ground.reparent(world._map.get_node("GroundStructures"))
	var bodies: Array[CanvasItem] = [machine]
	bodies.append_array(pipe.body_visuals)
	world._build_mode.register_compound_visual(self, bodies)
	world._build_mode.set_ground_grid_enabled(true)


func _exit_tree() -> void:
	if is_instance_valid(ground) and ground.get_parent() != self:
		ground.queue_free()


func _sprite(parent: Node2D, asset: String, at: Vector2) -> Sprite2D:
	var result := Sprite2D.new()
	result.centered = false
	result.texture = load(VOLUME_ASSETS + asset + ".png") as Texture2D
	assert(result.texture != null, "The raised pipe study requires the existing volume parts.")
	result.position = at
	parent.add_child(result)
	return result


func _build_controls() -> void:
	var layer := CanvasLayer.new()
	layer.layer = 30
	add_child(layer)
	var panel := PanelContainer.new()
	panel.theme = UI_THEME
	panel.set_anchors_and_offsets_preset(Control.PRESET_CENTER_BOTTOM)
	panel.offset_left = -650
	panel.offset_right = 650
	panel.offset_top = -205
	panel.offset_bottom = -115
	layer.add_child(panel)
	var layout := VBoxContainer.new()
	panel.add_child(layout)
	var title := Label.new()
	title.text = "架空管道模块 · 视觉样板  |  WASD 观察前后遮挡"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	layout.add_child(title)
	var row := HBoxContainer.new()
	row.alignment = BoxContainer.ALIGNMENT_CENTER
	layout.add_child(row)
	flow_button = _button(row, "流动", func(): _set_state(PipeVisualPath.ContentState.FLOW))
	idle_button = _button(row, "停流", func(): _set_state(PipeVisualPath.ContentState.IDLE))
	empty_button = _button(row, "空管", func(): _set_state(PipeVisualPath.ContentState.EMPTY))
	color_button = _button(row, "", func():
		var color := PipeVisualPath.MATERIAL_B if pipe.fluid_color == PipeVisualPath.MATERIAL_A else PipeVisualPath.MATERIAL_A
		pipe.configure(pipe.content_state, color, pipe.flow_direction)
		_refresh_controls()
	)
	reverse_button = _button(row, "", func():
		pipe.configure(pipe.content_state, pipe.fluid_color, -pipe.flow_direction)
		_refresh_controls()
	)
	pause_button = _button(row, "", func():
		pipe.animation_paused = not pipe.animation_paused
		_refresh_controls()
	)
	shadow_button = _button(row, "", func():
		shadows.visible = not shadows.visible
		_refresh_controls()
	)
	floor_button = _button(row, "", func():
		quiet_floor.visible = not quiet_floor.visible
		_refresh_controls()
	)


func _set_state(state: PipeVisualPath.ContentState) -> void:
	pipe.configure(state, pipe.fluid_color, pipe.flow_direction)
	_refresh_controls()


func _button(parent: HBoxContainer, label: String, callback: Callable) -> Button:
	var button := Button.new()
	button.text = label
	button.pressed.connect(callback)
	parent.add_child(button)
	return button


func _refresh_controls() -> void:
	flow_button.disabled = pipe.content_state == PipeVisualPath.ContentState.FLOW
	idle_button.disabled = pipe.content_state == PipeVisualPath.ContentState.IDLE
	empty_button.disabled = pipe.content_state == PipeVisualPath.ContentState.EMPTY
	color_button.text = "内容：青色" if pipe.fluid_color == PipeVisualPath.MATERIAL_A else "内容：琥珀"
	reverse_button.text = "方向：正向" if pipe.flow_direction == 1 else "方向：反向"
	pause_button.text = "演示：暂停" if pipe.animation_paused else "演示：播放"
	shadow_button.text = "投影：开" if shadows.visible else "投影：关"
	floor_button.text = "地面：低纹理" if quiet_floor.visible else "地面：现有地板"
