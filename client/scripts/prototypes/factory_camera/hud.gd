extends Control

signal action(kind: String, value: Variant)
signal world_input(event: InputEvent)

var viewport := SubViewport.new()
var image := TextureRect.new()
var summary := Label.new()
var detail := Label.new()
var markers: Array[Control] = []
var marker_points: Array[Vector3] = []
var ports_visible := true
var camera_buttons: Array[Button] = []
var board_buttons: Array[Button] = []


func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	var theme_font := FontVariation.new()
	theme_font.base_font = preload("res://assets/fonts/NotoSansSC-wght.ttf")
	theme_font.variation_opentype = {"wght": 450}
	theme = Theme.new()
	theme.default_font = theme_font
	theme.default_font_size = 17
	var background := ColorRect.new()
	background.color = Color("172522")
	background.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	background.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(background)
	var column := VBoxContainer.new()
	add_child(column)
	column.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	column.add_theme_constant_override("separation", 6)
	var title := Label.new()
	title.text = "  异星催化 · 镜头与尺度试玩    R1-A / 隔离样板 / 不保存世界"
	column.add_child(title)
	var row := HFlowContainer.new()
	column.add_child(row)
	for i in 3:
		camera_buttons.append(button(row, ["1 正交·斜向", "2 正交·正向", "3 透视·正向"][i], "camera", i))
	for id in ["P", "D"]:
		board_buttons.append(button(row, "主板 P" if id == "P" else "密集板 D", "board", id))
	button(row, "固定 / 跟随", "follow", null)
	button(row, "回到起点", "reset", null)
	var tools := HFlowContainer.new()
	column.add_child(tools)
	for span in [16, 21, 28]:
		var zoom_button := button(tools, "默认 21 格" if span == 21 else "%d 格" % span, "span", span)
		zoom_button.tooltip_text = "观察距离：滚轮向上拉近 / 降低，向下拉远 / 升高；俯角与透视强度保持不变。"
	button(tools, "B 格位测量", "measure", null)
	button(tools, "网格", "grid", null)
	button(tools, "口位标尺", "ports", null)
	button(tools, "暂停移动", "pause", null)
	button(tools, "截图与记录", "capture", null)
	button(tools, "1100×720", "window", Vector2i(1100, 720))
	button(tools, "1440×900", "window", Vector2i(1440, 900))
	viewport.name = "CameraStudyViewport"
	viewport.own_world_3d = true
	viewport.gui_disable_input = true
	viewport.handle_input_locally = false
	viewport.msaa_3d = Viewport.MSAA_4X
	add_child(viewport)
	image.name = "WorldImage"
	image.texture = viewport.get_texture()
	image.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	image.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR
	image.size_flags_vertical = Control.SIZE_EXPAND_FILL
	image.mouse_filter = Control.MOUSE_FILTER_STOP
	column.add_child(image)
	image.resized.connect(sync_resolution)
	image.gui_input.connect(func(event: InputEvent): world_input.emit(event))
	get_window().size_changed.connect(sync_resolution)
	for x in [-1.5, -0.5, 0.5, 1.5]: add_marker(Vector3(x, 0.31, -3), "", false)
	for z in [-1.5, 1.5]: add_marker(Vector3(-3, 0.31, z), "", false)
	var outputs := ["iron_ore", "carbon_ore", "metal_plate", "industrial_cell", "porous_carrier", "construction_pack"]
	var output := 0
	for z in [-1.5, -0.5, 0.5, 1.5]:
		add_marker(Vector3(3, 0.31, z), outputs[output], true)
		output += 1
	for z in [-0.5, 0.5]:
		add_marker(Vector3(-3, 0.31, z), outputs[output], true)
		output += 1
	column.add_child(summary)
	column.add_child(detail)
	var help := Label.new()
	help.text = "  WASD 移动 · 左键选中 · F 选近处设备（2格） · 滚轮调距离 / 高度 · R 旋转测量 · Esc 取消"
	column.add_child(help)
	for label in [summary, detail, help]:
		label.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
	call_deferred("sync_resolution")


func button(parent: Control, caption: String, kind: String, value: Variant) -> Button:
	var result := Button.new()
	result.text = caption
	result.focus_mode = Control.FOCUS_NONE
	result.pressed.connect(func(): action.emit(kind, value))
	parent.add_child(result)
	return result


func add_marker(point: Vector3, item: String, output: bool) -> void:
	var marker := Panel.new()
	marker.size = Vector2(18, 18) if output else Vector2(8, 8)
	var style := StyleBoxFlat.new()
	style.bg_color = Color("1b2d29") if output else Color("a0dfc2")
	style.border_color = Color("f6c878") if output else Color("172522")
	style.set_border_width_all(1)
	style.set_corner_radius_all(2)
	marker.add_theme_stylebox_override("panel", style)
	marker.mouse_filter = Control.MOUSE_FILTER_IGNORE
	if output:
		var icon := TextureRect.new()
		icon.texture = preload("res://scripts/factory/item_slot.gd").TEXTURES[item]
		icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		icon.position = Vector2.ONE
		icon.size = Vector2(16, 16)
		icon.mouse_filter = Control.MOUSE_FILTER_IGNORE
		marker.add_child(icon)
	image.add_child(marker)
	markers.append(marker)
	marker_points.append(point)


func sync_resolution() -> void:
	if not is_inside_tree(): return
	var pixel_scale := get_viewport().get_stretch_transform().get_scale()
	viewport.size = Vector2i((image.size * pixel_scale).round()).max(Vector2i(2, 2))


func world_point(local: Vector2) -> Vector2:
	return local * Vector2(viewport.size) / image.size


func ui_point(point: Vector2) -> Vector2:
	return point * image.size / Vector2(viewport.size)


func refresh(view: Node3D, board: RefCounted, selected: int, measure: bool,
		cell: Vector2i, direction: int, paused: bool, notice: String) -> void:
	for i in 3: camera_buttons[i].disabled = view.preset == i
	for i in 2: board_buttons[i].disabled = board.board_id == ["P", "D"][i]
	for i in markers.size():
		var point: Vector2 = ui_point(view.project(marker_points[i]))
		markers[i].visible = ports_visible and board.board_id == "P" \
			and not view.camera.is_position_behind(marker_points[i]) and Rect2(Vector2.ZERO, image.size).has_point(point)
		markers[i].position = point - markers[i].size * 0.5
	summary.text = "  %s | %s | %.0f 格 | %s | 3D %d×%d | 角色 %.1f, %.1f%s" % [
		view.CAMERAS[view.preset].id, board.board_id, view.span,
		"跟随角色" if view.follow else "固定对照", viewport.size.x, viewport.size.y,
		board.actor.x, board.actor.z, " | 移动已暂停" if paused else ""]
	var selected_text := "点击设备查看轮廓；核心口位仅为密度标尺，非运行核心。"
	if selected == -2: selected_text = "核心预留 6×6：本批仅检查占地与 12 口标尺，实际模型和遮挡留待 R1-B。"
	for entity in board.entities:
		if entity.id == selected:
			selected_text = "%s (%d, %d) · 距离 %.1f 格 · %s" % [entity.type, entity.x, entity.z,
				board.distance_to_sample(entity), "可接近" if board.distance_to_sample(entity) <= 2 else "需走近"]
	if measure: selected_text = "测量 (%d,%d) / 方向 %d：%s" % [cell.x, cell.y, direction, board.measure_cell(cell)]
	detail.text = "  " + (notice if not notice.is_empty() else selected_text)
