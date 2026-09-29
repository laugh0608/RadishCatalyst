extends Control

const DemoModel := preload("res://scripts/prototypes/factory_refinement/model.gd")
const DemoView := preload("res://scripts/prototypes/factory_refinement/view.gd")
const FONT := preload("res://assets/fonts/NotoSansSC-wght.ttf")
var model := DemoModel.new()
var view := DemoView.new()
var viewport := SubViewport.new()
var surface := SubViewportContainer.new()
var ui := {"build": false, "tool": "", "cell": Vector2i(-14, -2), "dir": 0, "stroke": [], "selected": -1}
var guide: Label
var guide_detail: Label
var notice: Label
var device_title: Label
var state: Label
var input_slot := Label.new()
var output_slot := Label.new()
var power_info := Label.new()
var progress := ProgressBar.new()
var action: Button
var remove_button: Button
var buttons := {}
var hovered := false
var paused := false
var panel_clock := 0.0
var guide_index := -1
var thumbnail := SubViewport.new()
var sample_root := Node3D.new()
var thumbnail_id := -2


func style(bg: String, border: String = "405553") -> StyleBoxFlat:
	var box := StyleBoxFlat.new()
	box.bg_color = Color(bg)
	box.border_color = Color(border)
	box.set_border_width_all(1)
	box.set_corner_radius_all(10)
	box.content_margin_left = 16
	box.content_margin_right = 16
	box.content_margin_top = 12
	box.content_margin_bottom = 12
	return box


func text(value: String, size := 18, color := "dae4dc") -> Label:
	var label := Label.new()
	label.text = value
	label.add_theme_font_size_override("font_size", size)
	label.add_theme_color_override("font_color", Color(color))
	return label


func button(parent: Node, title: String, callback: Callable) -> Button:
	var result := Button.new()
	result.text = title
	result.custom_minimum_size.y = 40
	result.pressed.connect(callback)
	parent.add_child(result)
	return result


func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	theme = Theme.new()
	var readable_font := FontVariation.new()
	readable_font.base_font = FONT
	readable_font.variation_opentype = {"wght": 450.0}
	theme.default_font = readable_font
	theme.default_font_size = 18
	for state_name in ["normal", "hover", "pressed", "focus", "disabled"]:
		theme.set_stylebox(state_name, "Button", style("344b4b" if state_name in ["hover", "pressed"] else "253638", "79c6b3" if state_name == "pressed" else "49605c"))
	var bg := ColorRect.new()
	bg.color = Color("17282c")
	bg.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(bg)
	var margin := MarginContainer.new()
	margin.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	for side in ["left", "right", "top", "bottom"]:
		margin.add_theme_constant_override("margin_" + side, 18)
	add_child(margin)
	var column := VBoxContainer.new()
	column.add_theme_constant_override("separation", 12)
	margin.add_child(column)
	var heading := HBoxContainer.new()
	column.add_child(heading)
	var title := text("异星催化  /  首线交互样板", 26, "f1e5c7")
	title.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	heading.add_child(title)
	heading.add_child(text("低投入造型验证 · 独立沙盒 · 不保存", 16, "a7bbb4"))
	button(heading, "重置样板", reset_demo)
	var toolbar := HBoxContainer.new()
	toolbar.add_theme_constant_override("separation", 10)
	column.add_child(toolbar)
	for type in ["reactor", "power_junction", "belt"]:
		var title_text: String = {"reactor": "01  反应器\n3×3 · 40 kW · 晶体加工", "power_junction": "02  供电节点\n1×1 · 6 格覆盖 · 自动接入", "belt": "03  传送带\n1×1 · 被动运输 · R 转向"}[type]
		var build_button := button(toolbar, title_text, choose_tool.bind(type))
		build_button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		build_button.custom_minimum_size.y = 76
		buttons[type] = build_button
	button(toolbar, "查看设备\nEsc 取消建造", choose_tool.bind(""))
	button(toolbar, "转向 R", rotate_belt)
	var body := HBoxContainer.new()
	body.size_flags_vertical = Control.SIZE_EXPAND_FILL
	body.add_theme_constant_override("separation", 14)
	column.add_child(body)
	surface.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	surface.stretch = true
	surface.mouse_filter = Control.MOUSE_FILTER_STOP
	surface.gui_input.connect(scene_input)
	surface.mouse_entered.connect(func(): hovered = true)
	surface.mouse_exited.connect(func(): hovered = false)
	body.add_child(surface)
	viewport.own_world_3d = true
	viewport.msaa_3d = Viewport.MSAA_4X
	viewport.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	surface.add_child(viewport)
	view.world_model = model
	viewport.add_child(view)
	view.inspection_target = Vector3(-14.5, .25, 1.5)
	view.zoom = 1.4
	view.yaw = 10
	view.sync_camera()
	var panel := PanelContainer.new()
	panel.custom_minimum_size.x = 350
	panel.add_theme_stylebox_override("panel", style("213438"))
	body.add_child(panel)
	var details := VBoxContainer.new()
	details.add_theme_constant_override("separation", 8)
	panel.add_child(details)
	device_title = text("设备", 23, "f1e5c7")
	details.add_child(device_title)
	var preview := SubViewportContainer.new()
	preview.custom_minimum_size = Vector2(310, 110)
	preview.stretch = true
	preview.mouse_filter = Control.MOUSE_FILTER_IGNORE
	details.add_child(preview)
	thumbnail.own_world_3d = true
	thumbnail.transparent_bg = true
	thumbnail.msaa_3d = Viewport.MSAA_4X
	preview.add_child(thumbnail)
	thumbnail.add_child(sample_root)
	var camera := Camera3D.new()
	thumbnail.add_child(camera)
	camera.position = Vector3(5, 4, 6)
	camera.look_at(Vector3(0, 1.3, 0))
	camera.projection = Camera3D.PROJECTION_ORTHOGONAL
	camera.size = 4.0
	var sun := DirectionalLight3D.new()
	thumbnail.add_child(sun)
	sun.rotation_degrees = Vector3(-45, -30, 0)
	sun.light_energy = 2.0
	var env := WorldEnvironment.new()
	env.environment = Environment.new()
	env.environment.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	env.environment.ambient_light_color = Color("c6ddd6")
	env.environment.ambient_light_energy = .65
	thumbnail.add_child(env)
	state = text("", 18, "8bddc5")
	state.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	details.add_child(state)
	var slots := HBoxContainer.new()
	slots.add_theme_constant_override("separation", 8)
	details.add_child(slots)
	for label in [input_slot, output_slot]:
		var slot := PanelContainer.new()
		slot.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		slot.add_theme_stylebox_override("panel", style("17292d"))
		slots.add_child(slot)
		label.custom_minimum_size = Vector2(120, 78)
		label.add_theme_font_size_override("font_size", 18)
		label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		slot.add_child(label)
		if label == input_slot:
			slots.add_child(text("→", 22, "e8be75"))
	progress.custom_minimum_size.y = 18
	progress.show_percentage = false
	progress.add_theme_stylebox_override("background", style("14272b"))
	progress.add_theme_stylebox_override("fill", style("69bca6", "69bca6"))
	details.add_child(progress)
	power_info.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	power_info.size_flags_vertical = Control.SIZE_EXPAND_FILL
	power_info.add_theme_font_size_override("font_size", 17)
	details.add_child(power_info)
	action = button(details, "关闭电源", toggle_source)
	remove_button = button(details, "回收选中设备", salvage_selected)
	var guide_panel := PanelContainer.new()
	guide_panel.add_theme_stylebox_override("panel", style("273c3b", "7aa991"))
	column.add_child(guide_panel)
	var guide_column := VBoxContainer.new()
	guide_panel.add_child(guide_column)
	guide = text("", 22, "f1e5c7")
	guide_column.add_child(guide)
	guide_detail = text("", 18)
	guide_detail.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	guide_column.add_child(guide_detail)
	notice = text("", 16, "dcc9a6")
	notice.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	column.add_child(notice)
	reset_demo()


func reset_demo() -> void:
	model = DemoModel.new()
	for spec in [["collector", Vector2i(-20, -1)], ["storage", Vector2i(-8, -1)], ["power_source", Vector2i(-20, 4)]]:
		var result := model.place(spec[0], spec[1])
		assert(result.ok, str(result))
	model.actor.x = -11.5
	model.actor.z = 4.2
	view.invalidate()
	view.world_model = model
	ui.selected = model.entities[0].id
	ui.tool = ""
	ui.build = false
	thumbnail_id = -2
	guide_index = -1
	notice.text = "已预置采集器、电源和仓库；物料从零生产。点击设备查看 · WASD 移动 · 滚轮缩放 · 关闭即结束。"
	refresh_panel()


func choose_tool(type: String) -> void:
	ui.tool = type
	ui.build = not type.is_empty()
	if type == "reactor":
		ui.cell = Vector2i(-14, -2)
	elif type == "power_junction":
		ui.cell = Vector2i(-15, 3)
	elif type == "belt":
		ui.cell = Vector2i(-18, 0)
	for key in buttons:
		buttons[key].modulate = Color("a8e6cf") if key == type else Color.WHITE
	notice.text = "鼠标移动预览，左键放置；右键 / Esc 取消。" if ui.build else "点击设备查看状态。节点选中时显示覆盖圈。"


func rotate_belt() -> void:
	ui.dir = (ui.dir + 1) % 4
	notice.text = "传送带方向：" + ["向右 →", "向下 ↓", "向左 ←", "向上 ↑"][ui.dir]


func scene_input(event: InputEvent) -> void:
	if event is InputEventMouse:
		var point = view.ground(event.position)
		if point != null:
			ui.cell = Vector2i(floori(point.x), floori(point.z))
			if ui.build and event is InputEventMouseMotion:
				notice.text = "预览格位 (%d, %d) · 左键放置 · 右键 / Esc 取消 · 传送带 R 转向" % [ui.cell.x, ui.cell.y]
	if event is InputEventMouseButton and event.pressed:
		if event.button_index in [MOUSE_BUTTON_WHEEL_UP, MOUSE_BUTTON_WHEEL_DOWN]:
			view.zoom = clampf(view.zoom + (.1 if event.button_index == MOUSE_BUTTON_WHEEL_UP else -.1), .8, 2.0)
			view.sync_camera()
		elif event.button_index == MOUSE_BUTTON_RIGHT:
			choose_tool("")
		elif event.button_index == MOUSE_BUTTON_LEFT:
			if ui.build:
				var result := model.place(ui.tool, ui.cell, ui.dir, model.actor)
				notice.text = "已放置 " + model.CATALOG[ui.tool].name if result.ok else result.reason
				if result.ok:
					ui.selected = result.entity.id
					if ui.tool != "belt":
						choose_tool("")
			else:
				ui.selected = view.hit(event.position)
			refresh_panel()


func _unhandled_key_input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and not event.echo:
		if event.keycode == KEY_ESCAPE:
			choose_tool("")
		elif event.keycode == KEY_R:
			rotate_belt()


func _process(dt: float) -> void:
	if not view.prepared:
		return
	if get_window().has_focus() and not paused:
		model.advance(minf(dt, .1))
		var movement := Input.get_vector("move_left", "move_right", "move_up", "move_down")
		model.move_actor(model.actor, movement.x, movement.y, minf(dt, .1))
	view.draw(model, model.actor, ui)
	panel_clock += dt
	if panel_clock >= .15:
		panel_clock = 0
		refresh_panel()


func find_type(type: String) -> Dictionary:
	for e in model.entities:
		if e.type == type:
			return e
	return {}


func linked(a: Dictionary, b: Dictionary) -> bool:
	if a.is_empty() or b.is_empty():
		return false
	var port := model.port(a, "output")
	var target := model.port(b, "input")
	var cell := Vector2i(port.x + port.dx, port.z)
	var seen := {}
	while not seen.has(cell):
		seen[cell] = true
		var belt := model.entity_at(cell)
		if belt.get("type", "") != "belt":
			return false
		var next: Vector2i = cell + model.DIRS[belt.dir]
		if next == Vector2i(target.x, target.z):
			return belt.dir == 0
		cell = next
	return false


func update_guide() -> void:
	var reactor := find_type("reactor")
	var collector := find_type("collector")
	var warehouse := find_type("storage")
	var index := 0
	var heading := "放置反应器"
	var detail := "点击上方 01 反应器，在采集器右侧放置（建议左上格 −14, −2）；青色为输入、金色为输出。"
	if not reactor.is_empty():
		index = 1
		heading = "让反应器进入供电范围"
		detail = "点击 02 供电节点，在电源与反应器之间放置（建议 −15, 3）；圈内高亮对象会自动接入。"
		var network: int = model.power_state().devices[reactor.id].network
		if network >= 0 and model.grid.groups[network].capacity_kw > 0:
			index = 2
			heading = "连接原料传送带"
			detail = "点击 03 传送带，从采集器金色出口逐格向右铺到反应器青色入口；默认方向 →，R 可转向。"
			if linked(collector, reactor):
				index = 3
				heading = "接出成品至仓库"
				detail = "从反应器金色出口继续向右逐格铺带，接到仓库青色入口；Esc 退出建造后点击反应器查看加工。"
				if linked(reactor, warehouse):
					index = 4
					heading = "观察第一件催化剂入仓"
					detail = "2 份晶体加工为 1 份催化剂，每批 10 秒；面板读取真实库存和进度。可点电源测试停复电。"
					if int(warehouse.get("items", {}).get("catalyst", 0)) > 0:
						index = 5
						heading = "首条产线已运行"
						detail = "催化剂已入仓。继续查看设备、停复电或回收节点，检查反馈是否容易理解；本样板关闭后不保存。"
	var source := find_type("power_source")
	if not source.is_empty() and not source.enabled:
		index = 1
		heading = "重新开启电源"
		detail = "点击场地内封装电源，再点击右侧「开启电源」；设备保留当前物料与加工进度，恢复后继续运行。"
	if collector.is_empty() or warehouse.is_empty() or source.is_empty():
		index = 0
		heading = "起步设施已回收"
		detail = "本样板只提供反应器、节点、传送带建造卡；点击右上角「重置样板」恢复起步设施。"
	guide_index = index
	guide.text = "%02d / 06   %s" % [index + 1, heading]
	guide_detail.text = detail


func refresh_panel() -> void:
	var e := model.by_id(ui.selected)
	if ui.selected != thumbnail_id:
		view.clear_node(sample_root)
		if not e.is_empty() and e.type != "belt":
			sample_root.add_child(view.assets[e.type].instantiate())
		thumbnail_id = ui.selected
	if e.is_empty():
		device_title.text = "选择一台设备"
		state.text = "点击场地内设备查看"
		input_slot.text = "输入\n—"
		output_slot.text = "输出\n—"
		power_info.text = "建造时可预览接口和节点覆盖。"
		progress.value = 0
	else:
		device_title.text = model.CATALOG[e.type].name
		var label: String = model.feedback(e).label
		state.text = {"有在制，可推进": "正在加工", "缓冲可用，可采集": "正在采集", "原料齐全，可开批": "准备加工"}.get(label, label)
		input_slot.text = "输入\n—"
		output_slot.text = "输出\n—"
		progress.value = 0
		power_info.text = "被动设施 · 无需供电"
		if e.type == "reactor":
			input_slot.text = "晶体 · 输入\n%d 份\n每批需要 2" % e.input.get("crystal", 0)
			output_slot.text = "催化剂 · 输出\n%d 份\n每批产出 1" % e.output.get("catalyst", 0)
			progress.value = e.progress * 10
		elif e.type == "collector":
			input_slot.text = "矿点\n晶体矿"
			output_slot.text = "缓冲\n%d / 50" % e.buffer.get("crystal", 0)
			progress.value = e.progress * 100
		elif e.type == "storage":
			input_slot.text = "晶体库存\n%d" % e.items.get("crystal", 0)
			output_slot.text = "催化剂库存\n%d" % e.items.get("catalyst", 0)
		elif e.type == "belt":
			input_slot.text = "货物\n" + model.DiscoveryRules.NAMES.get(e.cargo, "空")
			output_slot.text = "方向\n" + ["→", "↓", "←", "↑"][e.dir]
		if model.DiscoveryRules.POWER.has(e.type):
			var device: Dictionary = model.power_state().devices[e.id]
			power_info.text = "%s\n实际 %.0f / 需求 %.0f kW\n%s" % [model.feedback(e).power, device.supplied_kw, device.request_kw, "加工中已投入 2 份晶体" if e.get("processing", false) else "缺料或出口满时不消耗加工功率"]
		elif model.Grid.is_node(e):
			model.power_state()
			var group: Dictionary = model.grid.groups[model.grid.membership[e.id]]
			input_slot.text = "本网容量\n%.0f kW" % group.capacity_kw
			output_slot.text = "本网供给\n%.0f kW" % group.supplied_kw
			power_info.text = "覆盖半径 6 格\n圈内设备自动接入；节点可中继。\n覆盖与功率容量分别计算。"
	action.visible = e.get("type", "") == "power_source"
	action.text = "关闭电源" if e.get("enabled", false) else "开启电源"
	remove_button.disabled = e.is_empty()
	update_guide()


func toggle_source() -> void:
	var e := model.by_id(ui.selected)
	if e.get("type", "") != "power_source":
		return
	var result := model.set_source_enabled(e.id, not e.enabled)
	notice.text = "电源状态已更新，覆盖内设备同步响应。" if result.ok else result.reason
	refresh_panel()


func salvage_selected() -> void:
	if model.by_id(ui.selected).is_empty():
		return
	var result := model.salvage(ui.selected, true)
	notice.text = "已回收；关联设备供电已重新计算。" if result.ok else result.reason
	if result.ok:
		ui.selected = -1
	refresh_panel()
