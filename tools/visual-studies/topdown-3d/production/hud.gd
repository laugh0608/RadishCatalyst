extends Control

signal action(name: String, value: Variant)

const Model := preload("res://production/model.gd")
const DIRECTIONS := ["东 →", "南 ↓", "西 ←", "北 ↑"]
var buttons := {}
var world_slot := Control.new()
var world_container := SubViewportContainer.new()
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
var placement_reason := Label.new()
var tool_row := HBoxContainer.new()
var placement_row := HBoxContainer.new()
var build_help := Label.new()
var cell_x := SpinBox.new()
var cell_z := SpinBox.new()
var restart := ConfirmationDialog.new()
var help_panel: PanelContainer


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
	world_container.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	world_container.stretch = true
	world_container.mouse_filter = Control.MOUSE_FILTER_IGNORE
	world_slot.add_child(world_container)
	subviewport.size = Vector2i(1440, 650)
	subviewport.handle_input_locally = false
	subviewport.gui_disable_input = true
	subviewport.own_world_3d = true
	subviewport.msaa_3d = Viewport.MSAA_4X
	world_container.add_child(subviewport)
	_build_world_panels()
	_build_footer(stack)
	restart.title = "重新开始"
	restart.dialog_text = "清空当前厂坪和物品，重新发放构件？\n本 Demo 关闭后也不会保留进度。"
	restart.ok_button_text = "重新开始"
	restart.cancel_button_text = "继续试玩"
	restart.confirmed.connect(func(): action.emit("restart_confirmed", null))
	add_child(restart)


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
	var subtitle := _label(row, "第一条产线  /  Godot 3D 对照")
	subtitle.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	subtitle.add_theme_color_override("font_color", Color("a8bdb0"))
	row.add_child(totals)
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
	_button(mission_stack, "mission", "收起目标")
	inspector = _panel(world_slot)
	inspector.set_anchors_and_offsets_preset(Control.PRESET_TOP_RIGHT)
	inspector.offset_left = -286
	inspector.offset_right = -20
	inspector.offset_top = 22
	var detail_stack := VBoxContainer.new()
	inspector.add_child(detail_stack)
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
	_label(help_panel, "WASD / 方向键移动 · 点空地移动\n1–4 选构件 · R 转带向 · Enter 精确放置\n按住鼠标拖铺，松开确认；回拖可缩短\nEsc 依次取消拖铺 / 构件 / 详情 / 建造\nQ / E 转相机 · 滚轮缩放\n金色出口 → 传送带 → 青色入口\n关闭窗口后重置；失焦自动暂停")
	help_panel.hide()


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
	_button(first, "restart", "重新开始")
	tool_row.add_theme_constant_override("separation", 10)
	rows.add_child(tool_row)
	for type in ["collector", "reactor", "storage", "belt"]:
		_button(tool_row, type, Model.CATALOG[type].name)
	_button(tool_row, "guides", "参考框：开")
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
	spin.min_value = -20
	spin.max_value = 20
	spin.step = 1
	spin.custom_minimum_size.x = 92
	spin.value_changed.connect(func(value): action.emit(id, int(value)))
	placement_row.add_child(spin)


func world_point(screen: Vector2) -> Variant:
	if restart.visible or not world_container.get_global_rect().has_point(screen):
		return null
	for panel in [mission_panel, inspector, help_panel, world_slot.get_node("CameraPanel")]:
		if panel.visible and panel.get_global_rect().has_point(screen):
			return null
	return screen - world_container.global_position


func announce(message: String, error := false) -> void:
	notice.text = message
	notice.add_theme_color_override("font_color", Color("efab86" if error else "d4dfc7"))


func refresh(model: RefCounted, actor: Dictionary, ui: Dictionary, focused: bool) -> void:
	totals.text = "催化剂入仓  %d    %02d:%02d" % [model.delivered, int(model.time) / 60, int(model.time) % 60]
	buttons.pause.text = "继续" if ui.paused else ("失焦暂停" if not focused else "暂停")
	buttons.build.text = "建造中 B" if ui.build else "进入建造 B"
	tool_row.visible = ui.build
	placement_row.visible = not ui.tool.is_empty()
	for type in ["collector", "reactor", "storage", "belt"]:
		buttons[type].text = "%s  %d" % [Model.CATALOG[type].name, model.kits[type]]
		buttons[type].modulate = Color("eac178" if ui.tool == type else "ffffff")
	buttons.guides.text = "参考框：开" if ui.guides else "参考框：关"
	if not ui.tool.is_empty():
		cell_x.set_value_no_signal(ui.cell.x)
		cell_z.set_value_no_signal(ui.cell.y)
		buttons.rotate.visible = ui.tool == "belt"
		buttons.rotate.text = "方向：" + DIRECTIONS[ui.dir]
		var valid: Dictionary = model.placement(ui.tool, ui.cell, actor)
		placement_reason.text = "可放置" if valid.ok else valid.reason
		buttons.place.disabled = not valid.ok
	bag.text = "回收箱：晶体 %d / 催化剂 %d" % [model.bag.crystal, model.bag.catalyst]
	coordinates.text = "X %.1f / Z %.1f" % [actor.x, actor.z]
	var e: Dictionary = model.by_id(ui.selected)
	inspector.visible = not e.is_empty()
	if not e.is_empty():
		var info := ""
		match e.type:
			"collector": info = "晶体缓冲 %d / 50\n采集速度 1 个 / 秒\n金色出口位于右侧" % e.buffer
			"reactor": info = "晶体输入 %d / 2\n催化剂输出 %d / 1\n%s\n左进右出，接口在前排" % [e.input, e.output, "加工 %.1f / 10 秒" % e.progress if e.processing else "每批 2 晶体 → 1 催化剂"]
			"storage": info = "晶体 %d · 催化剂 %d\n容量 %d / 200\n青色入口位于左侧" % [e.crystal, e.catalyst, e.crystal + e.catalyst]
			"belt": info = "方向 %s\n带上物品：%s\n速度 1 格 / 秒" % [DIRECTIONS[e.dir], {"": "空", "crystal": "晶体", "catalyst": "催化剂"}[e.cargo]]
		details.text = "%s\n%s\n\n%s" % [Model.CATALOG[e.type].name, model.feedback(e).label, info]
		buttons.rotate_selected.visible = e.type == "belt"
		buttons.deposit.visible = e.type != "belt"
		buttons.deposit.disabled = model.bag.crystal + model.bag.catalyst == 0
	var l: Dictionary = model.lesson
	var text := "01 / 搭建\n从青色矿点开始\n\n选择采集器覆盖矿点，再放下反应器和终端仓。"
	if model.entities.filter(func(entity): return entity.type != "belt").size() == 3:
		text = "02 / 接通\n把三台设备连起来\n\n金色出口 → 带 → 青色入口。2 晶体加工 10 秒，1 催化剂送入终端仓。"
	if l.first_delivery:
		text = "03 / 断路\n试着拆开输入线路\n\n点击采集器和反应器之间的一段带，拆回后观察真实缺料。"
	if l.cut:
		text = "03 / 等待耗尽\n输入线路已断开\n\n已有存料会继续加工，等待反应器耗尽供料。"
	if l.starved:
		text = "04 / 修复\n补回输入缺口\n\n接回采集器和反应器，等待新的催化剂进入终端仓。"
	if l.recovered:
		text = "04 / 已恢复\n产线重新运转了\n\n新批次已入仓。可以继续改布局，比较画面与操作感受。"
	mission.text = text if ui.mission else text.split("\n")[0]
	buttons.mission.text = "收起目标" if ui.mission else "展开目标"
