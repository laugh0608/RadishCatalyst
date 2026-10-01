class_name TransparentPipeStudy
extends Node2D

## Isolated art study: never instantiated by the normal game entry or catalog.

const UI_THEME := preload("res://assets/themes/slice_ui_theme.tres")
const STUDY_FONT := preload("res://assets/themes/ui_font_medium.tres")

var primary_path: PipeVisualPath
var comparison_path: PipeVisualPath
var empty_path: PipeVisualPath
var flow_button: Button
var idle_button: Button
var empty_button: Button
var color_button: Button
var reverse_button: Button
var pause_button: Button
var status_label: Label
var _primary_label: Label


func _ready() -> void:
	texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	primary_path = _add_path("Primary", Vector2.ZERO, PipeVisualPath.ContentState.FLOW, PipeVisualPath.MATERIAL_A)
	comparison_path = _add_path("Comparison", Vector2(256, 0), PipeVisualPath.ContentState.IDLE, PipeVisualPath.MATERIAL_B)
	empty_path = _add_path("Empty", Vector2(512, 0), PipeVisualPath.ContentState.EMPTY, PipeVisualPath.MATERIAL_A)
	_primary_label = _world_label("A · 输送", Vector2(0, -28))
	_world_label("B · 有料停流", Vector2(256, -28))
	_world_label("空管", Vector2(512, -28))
	_build_controls()
	_refresh_controls()


func _add_path(node_name: String, at: Vector2, state: PipeVisualPath.ContentState, color: Color) -> PipeVisualPath:
	var path := PipeVisualPath.new()
	path.name = node_name
	path.position = at
	path.configure(state, color)
	add_child(path)
	return path


func _world_label(text: String, at: Vector2) -> Label:
	var label := Label.new()
	label.text = text
	label.position = at
	label.add_theme_font_override("font", STUDY_FONT)
	label.add_theme_font_size_override("font_size", 14)
	label.add_theme_color_override("font_color", Color("e2e3d6"))
	label.add_theme_color_override("font_outline_color", Color("151c1e"))
	label.add_theme_constant_override("outline_size", 3)
	label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(label)
	return label


func _build_controls() -> void:
	var layer := CanvasLayer.new()
	layer.name = "StudyControls"
	layer.layer = 30
	add_child(layer)
	var panel := PanelContainer.new()
	panel.name = "Panel"
	panel.theme = UI_THEME
	panel.set_anchors_and_offsets_preset(Control.PRESET_CENTER_BOTTOM)
	panel.offset_left = -430
	panel.offset_right = 430
	panel.offset_top = -205
	panel.offset_bottom = -115
	layer.add_child(panel)
	var layout := VBoxContainer.new()
	panel.add_child(layout)
	status_label = Label.new()
	status_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	layout.add_child(status_label)
	var buttons := HBoxContainer.new()
	buttons.alignment = BoxContainer.ALIGNMENT_CENTER
	layout.add_child(buttons)
	flow_button = _button(buttons, "输送", func(): _set_state(PipeVisualPath.ContentState.FLOW))
	idle_button = _button(buttons, "停流", func(): _set_state(PipeVisualPath.ContentState.IDLE))
	empty_button = _button(buttons, "空管", func(): _set_state(PipeVisualPath.ContentState.EMPTY))
	color_button = _button(buttons, "切换物质", _toggle_color)
	reverse_button = _button(buttons, "反向", _reverse)
	pause_button = _button(buttons, "暂停预览", _toggle_pause)


func _button(parent: HBoxContainer, text: String, callback: Callable) -> Button:
	var button := Button.new()
	button.text = text
	button.focus_mode = Control.FOCUS_ALL
	button.pressed.connect(callback)
	parent.add_child(button)
	return button


func _set_state(state: PipeVisualPath.ContentState) -> void:
	primary_path.configure(state, primary_path.fluid_color, primary_path.flow_direction)
	_refresh_controls()


func _toggle_color() -> void:
	var color := PipeVisualPath.MATERIAL_B if primary_path.fluid_color == PipeVisualPath.MATERIAL_A else PipeVisualPath.MATERIAL_A
	primary_path.configure(primary_path.content_state, color, primary_path.flow_direction)
	_refresh_controls()


func _reverse() -> void:
	primary_path.configure(primary_path.content_state, primary_path.fluid_color, -primary_path.flow_direction)
	_refresh_controls()


func _toggle_pause() -> void:
	primary_path.animation_paused = not primary_path.animation_paused
	_refresh_controls()


func _refresh_controls() -> void:
	var state_name: String = ["输送", "停流", "空管"][primary_path.content_state]
	var material_name := "A" if primary_path.fluid_color == PipeVisualPath.MATERIAL_A else "B"
	var direction_name := "沿线向下" if primary_path.flow_direction == 1 else "沿线返回"
	_primary_label.text = "%s · %s" % [material_name, state_name]
	status_label.text = "视觉样板 · 非真实产线  |  %s · %s · %s" % [material_name, state_name, direction_name]
	flow_button.disabled = primary_path.content_state == PipeVisualPath.ContentState.FLOW
	idle_button.disabled = primary_path.content_state == PipeVisualPath.ContentState.IDLE
	empty_button.disabled = primary_path.content_state == PipeVisualPath.ContentState.EMPTY
	pause_button.text = "继续预览" if primary_path.animation_paused else "暂停预览"
