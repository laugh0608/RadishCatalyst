extends Control

## Review-only UI. Not a gameplay entry, schema 2 implementation, or save writer.
const Stage := preload("res://scripts/checks/factory_discovery_stage.gd")
var viewport := SubViewport.new()
var stage := Stage.new()
var buttons: Array[Button] = []
var note := Label.new()


func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	var background := ColorRect.new()
	background.color = Color("202e30")
	background.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(background)
	var column := VBoxContainer.new()
	column.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	column.add_theme_constant_override("separation", 8)
	add_child(column)
	var title := Label.new()
	title.text = "  异星催化 · D1 场景与资产预览（静态布局，无生产与存档）"
	title.add_theme_font_size_override("font_size", 22)
	column.add_child(title)
	var bar := HBoxContainer.new()
	column.add_child(bar)
	for i in 4:
		var button := Button.new()
		button.text = ["设备对照", "矿道关闭", "第一段打开", "两段打开"][i]
		button.custom_minimum_size = Vector2(160, 42)
		button.pressed.connect(func(): select_mode(i))
		bar.add_child(button)
		buttons.append(button)
	var connections := CheckButton.new()
	connections.text = "接线预览"
	connections.button_pressed = true
	connections.toggled.connect(func(enabled: bool): stage.set_connections(enabled))
	bar.add_child(connections)
	var container := SubViewportContainer.new()
	container.size_flags_vertical = Control.SIZE_EXPAND_FILL
	container.stretch = true
	column.add_child(container)
	viewport.size = Vector2i(1440, 760)
	viewport.msaa_3d = Viewport.MSAA_4X
	viewport.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	container.add_child(viewport)
	viewport.add_child(stage)
	note.custom_minimum_size.y = 44
	note.add_theme_font_size_override("font_size", 18)
	column.add_child(note)
	select_mode(0)


func select_mode(value: int) -> void:
	stage.show_mode(value)
	for i in buttons.size():
		buttons[i].disabled = i == value
	note.text = "  " + ["同一材质家族；低矮封装电源、细杆配电节点，与原三机对照。",
		"关闭状态：主厂可建，样本可达；矿壳区域不可通行。",
		"开第一段：富集产线与回流带、第二电源就位；金线仅表示接线设计。",
		"全图：两段矿道开放；10 / 12 配电节点，2 / 2 电源，预留双侧行走空间。"][value]
