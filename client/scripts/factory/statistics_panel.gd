extends Control

signal locate_requested(id: int)
signal pause_requested
const Query := preload("res://scripts/factory/statistics_query.gd")
const Chart := preload("res://scripts/factory/statistics_chart.gd")
const Rules := Query.Rules
var model: RefCounted
var elapsed := 0.0
var last_revision := -1
var page := OptionButton.new()
var window_choice := OptionButton.new()
var filter := OptionButton.new()
var sort_choice := OptionButton.new()
var status := Label.new()
var coverage := Label.new()
var body := VBoxContainer.new()
var material_legend := Label.new()
var empty_label := Label.new()
var material_rows := VBoxContainer.new()
var detail := VBoxContainer.new()
var detail_summary := Label.new()
var device_list := VBoxContainer.new()
var power_body := VBoxContainer.new()
var power_summary := Label.new()
var power_chart := Chart.new()
var network_list := VBoxContainer.new()
var rows := {}
var selected_item := ""
var buttons := {}
var detail_ids: Array = []
var network_key := ""


func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_STOP
	var background := ColorRect.new()
	background.color = Color(0.025, 0.055, 0.055, 0.98)
	background.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(background)
	var margin := MarginContainer.new()
	margin.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	for side in ["left", "right", "top", "bottom"]:
		margin.add_theme_constant_override("margin_" + side, 24)
	add_child(margin)
	var stack := VBoxContainer.new()
	stack.add_theme_constant_override("separation", 12)
	margin.add_child(stack)
	var header := HBoxContainer.new()
	stack.add_child(header)
	label(header, "生产统计", 24)
	status.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	header.add_child(status)
	button(header, "pause", "暂停 / 继续", func(): pause_requested.emit())
	button(header, "close", "返回工厂 · Esc", hide)
	var options := HBoxContainer.new()
	stack.add_child(options)
	for entry in ["物料", "电力"]:
		page.add_item(entry)
	options.add_child(page)
	page.item_selected.connect(func(_i): refresh())
	for minutes in [1, 5, 10]:
		window_choice.add_item("最近 %d 分钟" % minutes)
	options.add_child(window_choice)
	window_choice.item_selected.connect(func(i):
		model.statistics_ui.window_seconds = [60, 300, 600][i]
		model.revision += 1
		refresh())
	for entry in ["全部已掌握", "当前有活动", "仅收藏"]:
		filter.add_item(entry)
	options.add_child(filter)
	filter.item_selected.connect(func(_i): refresh())
	for entry in ["名称", "净缺口优先", "仓库存量从少到多"]:
		sort_choice.add_item(entry)
	options.add_child(sort_choice)
	sort_choice.item_selected.connect(func(_i): refresh())
	stack.add_child(coverage)
	coverage.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	var scroll := ScrollContainer.new()
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	stack.add_child(scroll)
	body.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	body.add_theme_constant_override("separation", 14)
	scroll.add_child(body)
	material_legend.text = "青实线：生产　金虚线：消耗 · 点击物料查看库存与设备，悬停曲线查看区间数量与均值。"
	body.add_child(material_legend)
	empty_label.text = "当前筛选下没有物料。可切回全部已掌握，或收藏需要关注的物料。"
	body.add_child(empty_label)
	body.add_child(material_rows)
	material_rows.add_theme_constant_override("separation", 14)
	body.add_child(detail)
	detail.add_child(detail_summary)
	detail_summary.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	detail.add_child(device_list)
	body.add_child(power_body)
	power_body.add_child(power_summary)
	power_summary.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	power_chart.custom_minimum_size.y = 180
	power_body.add_child(power_chart)
	label(power_body, "青实线：供电＝用电　金虚线：请求　灰实线：装机　红虚线：缺口")
	power_body.add_child(network_list)
	var foot := label(stack, "只读统计 · 理论值为当前配置上限；历史曲线不代表当前故障原因。搬运不计产消，试制与开路不计持续理论速率。")
	foot.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	hide()


func label(parent: Node, text: String, size := 15) -> Label:
	var control := Label.new()
	control.text = text
	control.add_theme_font_size_override("font_size", size)
	parent.add_child(control)
	return control


func button(parent: Node, id: String, text: String, callback: Callable) -> Button:
	var control := Button.new()
	control.text = text
	control.pressed.connect(callback)
	parent.add_child(control)
	buttons[id] = control
	return control


func show_for(world: RefCounted) -> void:
	model = world
	window_choice.select([60, 300, 600].find(int(model.statistics_ui.window_seconds)))
	show()
	refresh()
	buttons.close.grab_focus()


func _process(delta: float) -> void:
	if not visible or model == null:
		return
	elapsed += delta
	if elapsed >= 1.0 or model.revision != last_revision:
		refresh()


func _input(event: InputEvent) -> void:
	if visible and event is InputEventKey and event.pressed and event.physical_keycode == KEY_ESCAPE:
		hide()
		get_viewport().set_input_as_handled()


func refresh() -> void:
	if model == null:
		return
	elapsed = 0
	last_revision = model.revision
	var seconds: int = model.statistics_ui.window_seconds
	var result := Query.materials(model, seconds) if page.selected == 0 else Query.electricity(model, seconds)
	var window: Dictionary = result.window
	coverage.text = "暂无样本：等待第一个完整模拟秒。" if not window.has_samples else "最近 %d 分钟 · 已采样 %d 秒 · 截止模拟 %.0f 秒；暂停、失焦和离线时间不计入。" % [seconds / 60, window.seconds, window.through_tick * 0.05]
	material_legend.visible = page.selected == 0
	empty_label.hide()
	material_rows.visible = page.selected == 0
	detail.visible = page.selected == 0 and not selected_item.is_empty()
	power_body.visible = page.selected == 1
	filter.visible = page.selected == 0
	sort_choice.visible = page.selected == 0
	if page.selected == 0:
		refresh_materials(result)
	else:
		refresh_power(result)


func create_row(item: String) -> Dictionary:
	var box := VBoxContainer.new()
	material_rows.add_child(box)
	var line := HBoxContainer.new()
	line.add_theme_constant_override("separation", 14)
	box.add_child(line)
	var name_button := button(line, item, Rules.NAMES[item], func():
		selected_item = item
		detail_ids = [-1]
		refresh())
	name_button.custom_minimum_size.x = 130
	var star := button(line, item + "_favorite", "☆", func():
		var favorites: Array = model.statistics_ui.favorites
		if item in favorites:
			favorites.erase(item)
		else:
			favorites.append(item)
		model.revision += 1
		refresh())
	var stock := label(line, "")
	stock.custom_minimum_size.x = 130
	var chart := Chart.new()
	chart.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	line.add_child(chart)
	var rates := label(line, "")
	rates.custom_minimum_size.x = 230
	return {"box": box, "star": star, "stock": stock, "chart": chart, "rates": rates}


func refresh_materials(result: Dictionary) -> void:
	var ids: Array = result.rows.keys()
	ids.sort_custom(func(a, b):
		var left: Dictionary = result.rows[a]
		var right: Dictionary = result.rows[b]
		if sort_choice.selected == 1 and left.net != right.net:
			return left.net < right.net
		if sort_choice.selected == 2 and left.storage != right.storage:
			return left.storage < right.storage
		return Rules.NAMES[a] < Rules.NAMES[b])
	for item in ids:
		if not rows.has(item):
			rows[item] = create_row(item)
		var controls: Dictionary = rows[item]
		var r: Dictionary = result.rows[item]
		controls.box.visible = (filter.selected != 1 or r.active) and (filter.selected != 2 or item in model.statistics_ui.favorites)
		material_rows.move_child(controls.box, material_rows.get_child_count() - 1)
		controls.star.text = "★" if item in model.statistics_ui.favorites else "☆"
		controls.stock.text = "仓库 %d 件\n总持有 %d 件" % [r.storage, r.held]
		controls.chart.show_points(r.points)
		controls.rates.text = ("实际 产 %.1f / 耗 %.1f\n净增减 %+.1f 件/分" % [r.produced, r.consumed, r.net] if result.window.has_samples else "实际：暂无样本\n净增减：暂无样本") + "\n理论 产 %.1f / 需 %.1f 件/分" % [r.theory_produced, r.theory_consumed]
	empty_label.visible = not rows.values().any(func(r): return r.box.visible)
	if selected_item.is_empty():
		return
	var r: Dictionary = result.rows[selected_item]
	detail_summary.text = "%s · 库存分解（件）\n仓库 %d　背包 %d　设备可取缓冲 %d　在途 %d　在制原投入 %d　合计 %d\n本窗口外部取得 %d 件；工业生产 / 消耗见青实线 / 金虚线。以下为当前设备状态。" % [Rules.NAMES[selected_item], r.storage, r.bag, r.buffer, r.transit, r.invested, r.held, r.acquired]
	if detail_ids != r.devices:
		detail_ids = r.devices.duplicate()
		clear_children(device_list)
		if detail_ids.is_empty():
			label(device_list, "当前没有相关设备，可能尚未建造或已经拆除。")
		for id in detail_ids:
			device_button(device_list, id)
	update_devices(device_list)


func device_button(parent: Node, id: int) -> void:
	var control := button(parent, "device_%d" % id, "", func():
		if model.by_id(id).is_empty():
			refresh()
			return
		locate_requested.emit(id))
	control.set_meta("entity_id", id)
	control.alignment = HORIZONTAL_ALIGNMENT_LEFT


func update_devices(parent: Node) -> void:
	for control in parent.get_children():
		if not control.has_meta("entity_id"):
			continue
		var id: int = control.get_meta("entity_id")
		var e: Dictionary = model.by_id(id)
		control.disabled = e.is_empty()
		if e.is_empty():
			control.text = "设备 #%d 已拆除" % id
			continue
		var feedback: Dictionary = model.feedback(e)
		control.text = "定位 %s #%d (%d, %d) · %s%s" % [Rules.CATALOG[e.type].name, id, e.x, e.z, feedback.get("production", feedback.label), " · " + feedback.power if feedback.has("power") else ""]


func refresh_power(result: Dictionary) -> void:
	var p: Dictionary = result.current
	var w: Dictionary = result.window
	power_summary.text = "当前：装机 %.1f / 可用 %.1f / 请求 %.1f / 实际供用 %.1f / 分网缺口 %.1f kW" % [p.installed_kw, p.available_kw, p.request_kw, p.supplied_kw, p.deficit_kw]
	if w.has_samples:
		power_summary.text += "\n窗口均值：装机 %.1f / 请求 %.1f / 供用 %.1f / 缺口 %.1f kW\n窗口供电＝用电 %.2f kJ；累计用电 %.2f kJ" % [w.installed_kj / w.seconds, w.requested_kj / w.seconds, w.used_kj / w.seconds, w.deficit_kj / w.seconds, w.used_kj, model.statistics.totals.used_kj]
	power_chart.show_points(result.points, true)
	# Rebuild only when membership changes; stable buttons retain keyboard focus.
	var signature := []
	for group in result.groups:
		signature.append(group.devices)
	signature.append(result.unplugged)
	var key := str(signature)
	if key != network_key:
		network_key = key
		clear_children(network_list)
		for i in result.groups.size():
			var heading := label(network_list, "")
			heading.set_meta("group_index", i)
			for id in result.groups[i].devices:
				device_button(network_list, id)
		if not result.unplugged.is_empty():
			label(network_list, "未接入电网（孤网富余不能抵消此处缺口）")
			for id in result.unplugged:
				device_button(network_list, id)
	for child in network_list.get_children():
		if child.has_meta("group_index"):
			var group: Dictionary = result.groups[child.get_meta("group_index")]
			child.text = "电网节点 %s · 可用 %.1f / 请求 %.1f / 供用 %.1f / 缺口 %.1f kW" % [str(group.nodes), group.capacity, group.request, group.supply, group.deficit]
	update_devices(network_list)


func clear_children(parent: Node) -> void:
	for child in parent.get_children():
		parent.remove_child(child)
		child.queue_free()
