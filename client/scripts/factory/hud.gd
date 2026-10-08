extends Control

signal action(name: String, value: Variant)

const Model := preload("res://scripts/factory/model.gd")
const Items := preload("res://scripts/factory/items.gd")
const PowerRange := preload("res://scripts/factory/power_range.gd")
const Guidance := preload("res://scripts/factory/discovery_guidance.gd")
const DIRECTIONS := ["东 →", "南 ↓", "西 ←", "北 ↑"]
var buttons := {}
var world_slot := Control.new()
var world_image := TextureRect.new()
var subviewport := SubViewport.new()
var mission_panel: PanelContainer
var inspector: PanelContainer
var footer: PanelContainer
var mission := Label.new()
var totals := Label.new()
var notice := Label.new()
var bag := Label.new()
var coordinates := Label.new()
var details := Label.new()
var inspector_scroll := ScrollContainer.new()
var placement_reason := Label.new()
var tool_row := HFlowContainer.new()
var placement_row := HBoxContainer.new()
var build_help := Label.new()
var power_help := Label.new()
var cell_x := SpinBox.new()
var cell_z := SpinBox.new()
var help_panel: PanelContainer
var sample_button: Button
var interaction_button: Button


func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	_build_theme()
	var stack := VBoxContainer.new()
	stack.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	stack.add_theme_constant_override("separation", 0)
	stack.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(stack)
	_build_header(stack)
	world_slot.size_flags_vertical = Control.SIZE_EXPAND_FILL
	world_slot.mouse_filter = Control.MOUSE_FILTER_IGNORE
	stack.add_child(world_slot)
	world_image.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	world_image.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR
	world_image.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	world_image.mouse_filter = Control.MOUSE_FILTER_IGNORE
	world_slot.add_child(world_image)
	subviewport.size = Vector2i(1440, 650)
	subviewport.handle_input_locally = false
	subviewport.gui_disable_input = true
	subviewport.own_world_3d = true
	subviewport.msaa_3d = Viewport.MSAA_4X
	world_image.add_child(subviewport)
	world_image.texture = subviewport.get_texture()
	world_image.resized.connect(_sync_render_resolution)
	get_window().size_changed.connect(_sync_render_resolution.call_deferred)
	_sync_render_resolution.call_deferred()
	_build_world_panels()
	_build_footer(stack)


func _build_theme() -> void:
	theme = Theme.new()
	var font := SystemFont.new()
	font.font_names = PackedStringArray(["PingFang SC", "Noto Sans CJK SC", "Microsoft YaHei"])
	theme.default_font = font
	theme.default_font_size = 15
	theme.set_color("font_color", "Label", Color("e2e5d5"))
	for state in ["normal", "hover", "pressed", "disabled"]:
		var style := StyleBoxFlat.new()
		style.bg_color = Color({"normal": "293f3f", "hover": "405b56", "pressed": "d3ac65", "disabled": "293635"}[state])
		style.border_color = Color("60766b")
		style.set_border_width_all(1)
		style.set_corner_radius_all(5)
		style.content_margin_left = 13
		style.content_margin_right = 13
		style.content_margin_top = 9
		style.content_margin_bottom = 9
		theme.set_stylebox(state, "Button", style)
	theme.set_color("font_color", "Button", Color("e2e5d5"))
	theme.set_color("font_pressed_color", "Button", Color("223833"))
	theme.set_color("font_hover_color", "Button", Color("ffffff"))
	theme.set_color("font_disabled_color", "Button", Color("718079"))


func _panel(parent: Node, padded := true) -> PanelContainer:
	var panel := PanelContainer.new()
	var style := StyleBoxFlat.new()
	style.bg_color = Color(0.075, 0.145, 0.148, 0.95)
	style.set_corner_radius_all(6)
	if padded:
		style.content_margin_left = 16
		style.content_margin_right = 16
		style.content_margin_top = 12
		style.content_margin_bottom = 12
	panel.add_theme_stylebox_override("panel", style)
	parent.add_child(panel)
	return panel


func _button(parent: Node, id: String, text: String) -> Button:
	var button := Button.new()
	button.text = text
	button.focus_mode = Control.FOCUS_NONE
	button.pressed.connect(func(): action.emit(id, null))
	parent.add_child(button)
	buttons[id] = button
	return button


func _label(parent: Node, text: String, size := 15) -> Label:
	var label := Label.new()
	label.text = text
	label.add_theme_font_size_override("font_size", size)
	parent.add_child(label)
	return label


func _build_header(parent: Node) -> void:
	var header := _panel(parent)
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 20)
	header.add_child(row)
	_label(row, "RC  异星催化", 24)
	var subtitle := _label(row, "工厂世界")
	subtitle.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	subtitle.add_theme_color_override("font_color", Color("a8bdb0"))
	row.add_child(totals)
	_button(row, "inventory", "背包 I")
	_button(row, "statistics", "生产统计")
	_button(row, "pause", "暂停")


func _build_world_panels() -> void:
	mission_panel = _panel(world_slot)
	mission_panel.position = Vector2(20, 22)
	mission_panel.custom_minimum_size.x = 230
	var mission_stack := VBoxContainer.new()
	mission_panel.add_child(mission_stack)
	mission.custom_minimum_size.x = 198
	mission.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	mission_stack.add_child(mission)
	_button(mission_stack, "guide_action", "开始首条产线")
	_button(mission_stack, "mission", "收起目标")
	_button(mission_stack, "discovery", "工艺、物料与矿道")
	inspector = _panel(world_slot)
	inspector.set_anchors_and_offsets_preset(Control.PRESET_TOP_RIGHT)
	inspector.anchor_bottom = 1.0
	inspector.offset_left = -350
	inspector.offset_right = -20
	inspector.offset_top = 22
	inspector.offset_bottom = -72
	inspector_scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	inspector.add_child(inspector_scroll)
	var detail_stack := VBoxContainer.new()
	detail_stack.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	detail_stack.add_theme_constant_override("separation", 8)
	inspector_scroll.add_child(detail_stack)
	details.custom_minimum_size.x = 234
	details.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	detail_stack.add_child(details)
	_button(detail_stack, "deposit", "投入回收物品")
	_button(detail_stack, "rotate_selected", "旋转传送带 R")
	_button(detail_stack, "salvage", "拆回构件和全部货物")
	_button(detail_stack, "close_inspector", "关闭详情")
	var camera_panel := _panel(world_slot, false)
	camera_panel.set_anchors_and_offsets_preset(Control.PRESET_BOTTOM_RIGHT)
	camera_panel.offset_left = -250
	camera_panel.offset_right = -20
	camera_panel.offset_top = -52
	camera_panel.offset_bottom = -12
	var camera_row := HBoxContainer.new()
	camera_panel.add_child(camera_row)
	_button(camera_row, "camera_left", "↶ Q")
	_button(camera_row, "camera_right", "E ↷")
	_button(camera_row, "zoom_out", "−")
	_button(camera_row, "zoom_in", "+")
	camera_panel.name = "CameraPanel"
	help_panel = _panel(world_slot)
	help_panel.position = Vector2(265, 22)
	_label(help_panel, "WASD / 方向键移动 · 点空地移动\n1–4 选构件 · R 转带向 · Enter 精确放置\n按住鼠标拖铺，松开确认；回拖可缩短\nEsc 依次取消拖铺 / 构件 / 详情 / 建造\nQ / E 转相机 · 滚轮缩放\nF 近身交互 · Tab 切换目标 · I 背包\n金色出口 → 传送带 → 青色入口\n关闭窗口自动保存；后台继续生产")
	help_panel.hide()
	sample_button = _button(world_slot, "sample", "矿壳样本 · F 拾取")
	sample_button.hide()
	interaction_button = _button(world_slot, "interact", "F  查看设备")
	interaction_button.set_anchors_and_offsets_preset(Control.PRESET_CENTER_BOTTOM)
	interaction_button.offset_top = -64
	interaction_button.offset_bottom = -18
	interaction_button.hide()



func _build_footer(parent: Node) -> void:
	footer = _panel(parent)
	var rows := VBoxContainer.new()
	rows.add_theme_constant_override("separation", 8)
	footer.add_child(rows)
	var first := HBoxContainer.new()
	first.add_theme_constant_override("separation", 12)
	rows.add_child(first)
	_button(first, "build", "建造中 B")
	notice.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	notice.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	first.add_child(notice)
	_button(first, "help", "操作说明")
	_button(first, "save", "保存")
	_button(first, "return", "保存并返回")
	tool_row.add_theme_constant_override("separation", 10)
	rows.add_child(tool_row)
	for type in ["collector", "reactor", "storage", "belt", "power_source", "power_junction", "splitter", "merger"]:
		var button := _button(tool_row, type, Model.CATALOG[type].name)
		if type in ["splitter", "merger"]:
			button.icon = load("res://assets/icons/factory_" + type + ".svg")
			button.add_theme_constant_override("icon_max_width", 22)
			button.tooltip_text = "一入三出，跳过堵塞出口；单件行程 1 秒" if type == "splitter" else "三入一出，轮流接收；单件行程 1 秒"

	rows.add_child(placement_row)
	placement_row.add_theme_constant_override("separation", 10)
	_label(placement_row, "落位 X")
	_configure_spin(cell_x, "cell_x")
	_label(placement_row, "Z")
	_configure_spin(cell_z, "cell_z")
	_button(placement_row, "rotate", "方向：东 →")
	_button(placement_row, "place", "放置 Enter")
	_button(placement_row, "cancel", "取消 Esc")
	placement_row.add_child(placement_reason)
	power_help.text = PowerRange.legend()
	power_help.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	power_help.add_theme_color_override("font_color", Color("b1d5cb"))
	rows.add_child(power_help)
	power_help.hide()
	var last := HBoxContainer.new()
	rows.add_child(last)
	build_help.text = "WASD 移动 · 拖动铺带 · Q / E 转角 · 滚轮缩放"
	build_help.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	build_help.add_theme_font_size_override("font_size", 13)
	last.add_child(build_help)
	bag.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	bag.add_theme_font_size_override("font_size", 13)
	last.add_child(bag)
	coordinates.add_theme_font_size_override("font_size", 13)
	last.add_child(coordinates)


func _configure_spin(spin: SpinBox, id: String) -> void:
	spin.min_value = -32
	spin.max_value = 31
	spin.step = 1
	spin.custom_minimum_size.x = 92
	spin.value_changed.connect(func(value): action.emit(id, int(value)))
	placement_row.add_child(spin)


func _sync_render_resolution() -> void:
	# Canvas stretching enlarges the UI without resizing nested render targets.
	# Render the world at its displayed pixel size, including Retina/window scaling.
	var pixel_scale := get_viewport().get_stretch_transform().get_scale()
	var resolution := Vector2i((world_image.size * pixel_scale).round()).max(Vector2i(2, 2))
	if subviewport.size != resolution:
		subviewport.size = resolution


func viewport_to_screen(point: Vector2) -> Vector2:
	return world_image.global_position + point * world_image.size / Vector2(subviewport.size)


func world_point(screen: Vector2) -> Variant:
	if not world_image.get_global_rect().has_point(screen):
		return null
	for panel in [mission_panel, inspector, help_panel, sample_button, interaction_button, world_slot.get_node("CameraPanel")]:
		if panel.visible and panel.get_global_rect().has_point(screen):
			return null
	return (screen - world_image.global_position) * Vector2(subviewport.size) / world_image.size


func sync_sample(view: Node3D, model: RefCounted, ui: Dictionary) -> void:
	sample_button.visible = model.has_method("near_sample") and not model.discovery.sample_taken \
		and model.near_sample() and not ui.get("blocked", false) and ui.get("focus_device", -1) == -1 and ui.tool.is_empty() and ui.get("power_from", 0) == 0
	if not sample_button.visible:
		return
	var at := viewport_to_screen(view.sample_screen()) - world_slot.global_position
	var lower := Vector2(8, 8)
	var upper := (world_slot.size - sample_button.size - Vector2(8, 8)).max(lower)
	sample_button.position = (at + Vector2(20, -sample_button.size.y * 0.5)).clamp(lower, upper)
	sample_button.text = "矿壳样本 · F 拾取"
	if ui.get("interaction_count", 0) > 1:
		sample_button.text += " · Tab 切换"
	sample_button.tooltip_text = "背包已满，请先腾出空间" if Items.count(model.bag) >= 200 else "拾取并记录调查结果"


func announce(message: String, error := false) -> void:
	notice.text = message
	notice.add_theme_color_override("font_color", Color("efab86" if error else "d4dfc7"))


func refresh(model: RefCounted, actor: Dictionary, ui: Dictionary, _focused: bool) -> void:
	totals.text = "催化剂入仓  %d    %02d:%02d" % [model.delivered, int(model.time) / 60, int(model.time) % 60]
	buttons.pause.text = "继续" if ui.paused else "暂停"
	buttons.build.text = "建造中 B" if ui.build else "进入建造 B"
	tool_row.visible = ui.build
	placement_row.visible = not ui.tool.is_empty()
	power_help.visible = not PowerRange.origin(model, ui).is_empty()
	if power_help.visible:
		power_help.text = PowerRange.legend(model.automatic_power)
	for type in ["collector", "reactor", "storage", "belt", "power_source", "power_junction", "splitter", "merger"]:
		buttons[type].visible = model.kits.has(type)
		if not model.kits.has(type):
			continue
		buttons[type].text = "%s  %d" % [Model.CATALOG[type].name, model.kits[type]]
		buttons[type].modulate = Color("eac178" if ui.tool == type else "ffffff")
	if not ui.tool.is_empty():
		cell_x.set_value_no_signal(ui.cell.x)
		cell_z.set_value_no_signal(ui.cell.y)
		buttons.rotate.visible = ui.tool in ["belt", "splitter", "merger"]
		buttons.rotate.text = "方向：" + DIRECTIONS[ui.dir]
		var valid: Dictionary = model.placement(ui.tool, ui.cell, actor)
		placement_reason.text = "可放置" if valid.ok else valid.reason
		buttons.place.disabled = not valid.ok
	bag.text = "背包：" + Items.describe(model.bag) if model.has_method("power_state") else "回收箱：晶体 %d / 催化剂 %d" % [model.bag.crystal, model.bag.catalyst]
	buttons.discovery.visible = model.has_method("power_state")
	buttons.inventory.visible = model.has_method("power_state")
	buttons.statistics.visible = model.has_method("power_state")
	coordinates.text = "X %.1f / Z %.1f" % [actor.x, actor.z]
	var e: Dictionary = model.by_id(ui.selected)
	var powered: bool = model.has_method("power_state")
	inspector.visible = not powered and not e.is_empty()
	inspector.anchor_bottom = 0.0
	inspector.offset_bottom = 22
	inspector.offset_left = -286
	inspector_scroll.vertical_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	if not powered and not e.is_empty():
		var info := ""
		match e.type:
			"collector": info = "晶体缓冲 %d / 50\n采集速度 1 个 / 秒\n金色出口位于右侧" % e.buffer
			"reactor": info = "晶体输入 %d / 2\n催化剂输出 %d / 1\n%s\n左进右出，接口在前排" % [e.input, e.output, "加工 %.1f / 10 秒" % e.progress if e.processing else "每批 2 晶体 → 1 催化剂"]
			"storage": info = "晶体 %d · 催化剂 %d\n容量 %d / 200\n青色入口位于左侧" % [e.crystal, e.catalyst, e.crystal + e.catalyst]
			"belt": info = "方向 %s\n带上物品：%s\n速度 1 格 / 秒" % [DIRECTIONS[e.dir], {"": "空", "crystal": "晶体", "catalyst": "催化剂"}[e.cargo]]
		details.text = "%s\n%s\n\n%s" % [Model.CATALOG[e.type].name, model.feedback(e).label, info]
		buttons.rotate_selected.visible = e.type in ["belt", "splitter", "merger"]
		buttons.deposit.visible = e.type in ["collector", "reactor", "storage"]
		buttons.deposit.disabled = Items.count(model.bag) == 0
	var target: Dictionary = model.by_id(ui.get("focus_device", -1))
	interaction_button.visible = powered and not ui.get("blocked", false) and not target.is_empty()
	if interaction_button.visible:
		interaction_button.text = "F  查看 %s #%d" % [Model.CATALOG[target.type].name, target.id]
		if ui.get("interaction_count", 0) > 1:
			interaction_button.text += "  ·  Tab 切换 %d/%d" % [ui.interaction_index + 1, ui.interaction_count]
		interaction_button.position.x = (world_slot.size.x - interaction_button.size.x) * 0.5
		interaction_button.disabled = not ui.focus_ready
	var text := "建立产线\n晶体 → 催化剂\n\n采集器覆盖青色矿点。金色出口接带，送入青色入口；反应器每批消耗 2 晶体，加工 10 秒。"
	if model.delivered > 0:
		text = "继续扩建\n已有 %d 件催化剂入仓\n\n走到其他青色矿点建立第二条产线。保存后可从启动菜单继续这个世界。" % model.delivered
	if model.has_method("power_state"):
		var step := Guidance.current(model)
		text = Guidance.describe(step)
		buttons.guide_action.text = step.action_label
		buttons.guide_action.tooltip_text = step.next
	buttons.guide_action.visible = powered and ui.mission
	mission.text = text if ui.mission else text.split("\n")[0]
	buttons.mission.text = "收起目标" if ui.mission else "展开目标"
