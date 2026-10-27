extends VBoxContainer

signal item_selected(item: String)
## Read-only live device presentation inside the unified operation panel.
const Rules := preload("res://data/factory/discovery_rules.gd")
const Model := preload("res://scripts/factory/model.gd")
const Items := preload("res://scripts/factory/items.gd")
const ItemSlot := preload("res://scripts/factory/item_slot.gd")
const DevicePreview := preload("res://scripts/factory/device_preview.gd")
const COLORS := {"running": "77d8c6", "ready": "b2c5b3", "waiting": "e2b365", "blocked": "e58864"}
var compact := true
var heading := Label.new()
var status := Label.new()
var flow: BoxContainer
var cards := {}
var captions := {}
var values := {}
var progress := ProgressBar.new()
var production := Label.new()
var power := Label.new()
var ports := Label.new()
var slots := {}
var grids := {}
var preview: SubViewportContainer


func _ready() -> void:
	add_theme_constant_override("separation", 8)
	add_child(heading)
	heading.add_theme_font_size_override("font_size", 20)
	add_child(status)
	status.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	flow = VBoxContainer.new() if compact else HBoxContainer.new()
	flow.add_theme_constant_override("separation", 8)
	add_child(flow)
	for role in ["input", "process", "output"]:
		var card := PanelContainer.new()
		card.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		var style := StyleBoxFlat.new()
		style.bg_color = Color("233a3b")
		style.border_color = Color("63998f" if role == "input" else "b99b61" if role == "output" else "637a76")
		style.border_width_left = 3
		style.set_corner_radius_all(5)
		style.content_margin_left = 10
		style.content_margin_right = 10
		style.content_margin_top = 7
		style.content_margin_bottom = 7
		card.add_theme_stylebox_override("panel", style)
		flow.add_child(card)
		cards[role] = card
		var stack := VBoxContainer.new()
		card.add_child(stack)
		var caption := Label.new()
		caption.add_theme_font_size_override("font_size", 13)
		caption.add_theme_color_override("font_color", style.border_color.lightened(0.3))
		stack.add_child(caption)
		captions[role] = caption
		var value := Label.new()
		value.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		stack.add_child(value)
		values[role] = value
		if not compact and role in ["input", "output"]:
			var grid := GridContainer.new()
			grid.columns = 1
			grid.size_flags_horizontal = Control.SIZE_SHRINK_BEGIN
			grid.add_theme_constant_override("h_separation", 10)
			grid.add_theme_constant_override("v_separation", 10)
			stack.add_child(grid)
			grids[role] = grid
			slots[role] = {}
			for item in Items.NAMES:
				var slot := ItemSlot.new()
				slot.item_id = item
				grid.add_child(slot)
				slot.pressed.connect(func(): item_selected.emit(item))
				slots[role][item] = slot
		if role == "process":
			if not compact:
				preview = DevicePreview.new()
				stack.add_child(preview)
			progress.custom_minimum_size.y = 18
			stack.add_child(progress)
	for label in [production, power, ports]:
		label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		label.add_theme_font_size_override("font_size", 13 if compact else 15)
		add_child(label)
	ports.add_theme_color_override("font_color", Color("b2c5b3"))


func refresh(model: RefCounted, e: Dictionary) -> void:
	visible = not e.is_empty()
	if e.is_empty():
		return
	heading.text = "%s  #%d" % [Rules.CATALOG[e.type].name, e.id]
	var feedback: Dictionary = model.feedback(e)
	status.text = feedback.label
	status.add_theme_color_override("font_color", Color(COLORS[feedback.kind]))
	for role in cards:
		cards[role].hide()
	progress.hide()
	production.text = ""
	power.text = ""
	match e.type:
		"reactor", "crusher", "refinery", "assembler":
			var recipe: Dictionary = model.recipes[e.recipe_id]
			var capacity: Dictionary = recipe.input.duplicate()
			if e.type != "reactor":
				for item in capacity: capacity[item] *= 2
			_card("input", "01  输入 · 两批缓存" if e.type != "reactor" else "01  输入", _quantities(e.input, capacity))
			_card("process", "02  加工 →", "%s\n%.1f / %.0f 秒" % [recipe.name, e.progress, recipe.seconds])
			_card("output", "03  输出 →", _quantities(e.output, recipe.output))
			progress.show()
			progress.value = 100.0 * e.progress / recipe.seconds if e.processing else 0.0
			production.text = "本批已投入：" + Items.describe(e.invested) if e.processing else "生产：" + feedback.production
			if not e.processing and e.output.is_empty() and model.recipe_available(e.recipe_id):
				var missing := {}
				for item in recipe.input:
					if int(e.input.get(item, 0)) < recipe.input[item]:
						missing[item] = recipe.input[item] - int(e.input.get(item, 0))
				if not missing.is_empty():
					production.text = "还需：" + Items.describe(missing)
			elif not e.output.is_empty():
				production.text = "副口矿渣积压；主口可继续排出，全部清空后再开批。" if e.type == "refinery" and e.output.has("mineral_slag") else "输出尚未清空；取出或接带送走后才能开下一批。"
		"collector":
			_card("output", "采集缓冲 →", "%s\n%d / 50 件" % [Items.describe(e.buffer), Items.count(e.buffer)])
			production.text = "采集：%s · 满供电 1 件 / %.0f 秒" % [Items.NAMES[e.mineral], model.collector_cycle(e)]
		"storage":
			_card("input", "库存", "%s\n%d / 200 件" % [Items.describe(e.items), Items.count(e.items)])
			production.text = "终端仓库 · 只接收物流，可近身取放。"
		"belt":
			_card("process", "运输 →", "%s\n带上：%s" % [["东 →", "南 ↓", "西 ←", "北 ↑"][e.dir], Items.NAMES.get(e.cargo, "空")])
	if e.type == "admission_gate":
		_card("process", "物品准入", "只允许：%s\n单件行程 1 秒 · 容量 1" % Items.NAMES.get(e.filter_item, "未配置"))
		_card("output", "在途物料", Items.NAMES.get(e.cargo, "空"))
		progress.show()
		progress.value = e.progress * 100
		production.text = model.Admission.quantities(e)
	elif e.type in ["splitter", "merger"]:
		_card("process", "分流调度" if e.type == "splitter" else "汇合调度", "单件行程 1 秒 · 容量 1\n货物：" + Items.NAMES.get(e.cargo, "空"))
		_card("output", "在途物料", "")
		progress.show()
		progress.value = e.progress * 100
		production.text = "下一次先尝试%s%s" % [(model.Logistics.OUTPUT_NAMES[e.output_cursor] if e.type == "splitter" else model.Logistics.INPUT_NAMES[e.input_cursor]), "出口" if e.type == "splitter" else "入口"]
	if e.type in model.process_types + ["collector"]:
		var device: Dictionary = model.power_state().devices[e.id]
		power.text = "供电：%s\n请求 %.1f / 实际用电 %.1f kW" % [feedback.power, device.request_kw, device.supplied_kw]
		if model.supply_id == Rules.Energy.SUPPLY_ID and model.standby_power:
			power.text += "\n运行额定 %.0f / 待机额定 %.0f kW" % [device.running_kw, Rules.Energy.STANDBY_KW[e.type]]
			production.text = ("已停机 · 0 kW" if not e.enabled else "运行" if model.work_spec(e).ready else "待机") + " · " + production.text
		if e.power_node_id != 0:
			power.text += " · 节点 #%d" % e.power_node_id
	elif e.type == "cell_generator":
		var state: Dictionary = model.power_state()
		var network: Dictionary = model.grid.groups[model.grid.membership[e.id]]
		var output: float = state.sources[e.id]
		_card("input", "完整电芯 · 最多 5 件", "%d / 5 件" % Items.count(e.fuel))
		_card("process", "已激活余能", "%.1f / 7,200 kJ" % e.remaining_kj)
		_card("output", "实际输出", "%.1f / 120 kW" % output)
		progress.show()
		progress.value = e.remaining_kj / 72.0
		production.text = "当前余能约 %.1f 秒；负载变化会改变估计。" % (e.remaining_kj / output) if output > 0 else "当前不消耗 · 余能保留；完整电芯可取回。"
		power.text = "同网请求 %.1f · 基础容量 %.0f · 供后缺口 %.1f kW" % [network.request_kw, network.base_capacity_kw, maxf(0, network.request_kw - network.supplied_kw)]
	elif model.Grid.is_node(e):
		var network: Dictionary = model.grid.groups[model.grid.membership[e.id]]
		_card("process", "当前电网", "容量 %.0f kW\n请求 %.1f / 获供 %.1f kW" % [network.capacity_kw, network.request_kw, network.supplied_kw])
		production.text = ("范围自动供电 · %d 条连接" if model.automatic_power else "显式接线 · %d 条直接连接") % model.connections(e.id).size()
		if e.type == "power_source":
			power.text = "本机实际输出 %.1f kW" % model.power_state().sources[e.id]
	else:
		power.text = "被动物流 · 无需供电"
	ports.text = port_text(model, e)
	if not compact:
		_sync_slots(model, e)
	for label in [production, power, ports]:
		label.visible = not label.text.is_empty()


func _sync_slots(model: RefCounted, e: Dictionary) -> void:
	preview.show_device(e.type, e.get("dir", 0))
	for role in slots:
		grids[role].columns = 3 if e.type == "storage" else 1
		for item in slots[role]:
			var stock := {}
			var required := {}
			match e.type:
				"reactor", "crusher", "refinery", "assembler":
					stock = e[role]
					required = model.recipes[e.recipe_id][role]
				"splitter", "merger", "admission_gate":
					if role == "output" and not e.cargo.is_empty():
						stock = {e.cargo: 1}
				"cell_generator":
					if role == "input":
						stock = e.fuel
						required = {"industrial_cell": 0}
				"collector":
					if role == "output":
						stock = e.buffer
						required = {e.mineral: 0}
				"storage":
					if role == "input":
						stock = e.items
						for known in model.item_ids:
							if model.item_known(known):
								required[known] = 0
			var slot: Button = slots[role][item]
			slot.visible = stock.has(item) or required.has(item)
			slot.update_amount(stock.get(item, 0), required.get(item, 0) if role == "input" and e.type in model.process_types else 0)
		values[role].visible = false
		if e.type == "storage" and role == "input":
			values[role].text = "%d / 200 件" % Items.count(e.items)
			values[role].show()
		elif e.type == "cell_generator":
			values[role].show()
		elif e.type == "collector" and role == "output":
			values[role].text = "%d / 50 件" % Items.count(e.buffer)
			values[role].show()
	if e.type == "collector":
		_card("process", "矿物采集器", "采集缓冲")


func select_item(item: String) -> void:
	for role in slots:
		for key in slots[role]:
			slots[role][key].mark_selected(key == item)


func _card(role: String, caption: String, value: String) -> void:
	cards[role].show()
	captions[role].text = caption
	values[role].text = value


static func _quantities(stock: Dictionary, batch: Dictionary) -> String:
	var lines := PackedStringArray()
	for item in batch:
		lines.append("%s  %d / %d" % [Items.NAMES[item], int(stock.get(item, 0)), batch[item]])
	return "\n".join(lines)


static func port_text(model: RefCounted, e: Dictionary) -> String:
	if Rules.routing_world(model.supply_id):
		return model.Logistics.port_text(model, e)
	var lines := PackedStringArray()
	for role in ["input", "output"]:
		var port := Model.port(e, role)
		if port.is_empty():
			continue
		var cell := Vector2i(port.x + port.dx, port.z + port.dz)
		var other: Dictionary = model.entity_at(cell)
		var connection := "未接带"
		if not other.is_empty():
			if other.type != "belt":
				connection = "被%s占用" % Rules.CATALOG[other.type].name
			elif (role == "input" and other.dir != 0) or (role == "output" and not Model.accepts_belt(other, Vector2i.RIGHT)):
				connection = "带 #%d 方向不接通" % other.id
			else:
				connection = "传送带 #%d" % other.id
		lines.append("%s (%d, %d)：%s" % ["输入接带" if role == "input" else "输出接带", cell.x, cell.y, connection])
	return "\n".join(lines)
