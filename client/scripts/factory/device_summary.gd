extends VBoxContainer

## Read-only live device presentation inside the unified operation panel.
const Rules := preload("res://data/factory/discovery_rules.gd")
const Model := preload("res://scripts/factory/model.gd")
const Items := preload("res://scripts/factory/items.gd")
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
		if role == "process":
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
		"reactor":
			var recipe: Dictionary = Rules.RECIPES[e.recipe_id]
			_card("input", "01  输入 · 下一批" if e.processing else "01  输入", _quantities(e.input, recipe.input))
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
				production.text = "输出尚未清空；取出或接带送走后才能开下一批。"
		"collector":
			_card("output", "采集缓冲 →", "%s\n%d / 50 件" % [Items.describe(e.buffer), Items.count(e.buffer)])
			production.text = "采集：%s · 满供电 1 件 / 秒" % Rules.NAMES[e.mineral]
		"storage":
			_card("input", "库存", "%s\n%d / 200 件" % [Items.describe(e.items), Items.count(e.items)])
			production.text = "终端仓库 · 只接收物流，可近身取放。"
		"belt":
			_card("process", "运输 →", "%s\n带上：%s" % [["东 →", "南 ↓", "西 ←", "北 ↑"][e.dir], Rules.NAMES.get(e.cargo, "空")])
	if e.type in ["collector", "reactor"]:
		var device: Dictionary = model.power_state().devices[e.id]
		power.text = "供电：%s\n请求 %.1f / 获供 %.1f kW" % [feedback.power, device.request_kw, device.supplied_kw]
		if e.power_node_id != 0:
			power.text += " · 节点 #%d" % e.power_node_id
	elif model.Grid.is_node(e):
		var network: Dictionary = model.grid.groups[model.grid.membership[e.id]]
		_card("process", "当前电网", "容量 %.0f kW\n请求 %.1f / 获供 %.1f kW" % [network.capacity_kw, network.request_kw, network.supplied_kw])
		production.text = ("范围自动供电 · %d 条连接" if model.automatic_power else "显式接线 · %d 条直接连接") % model.connections(e.id).size()
		if e.type == "power_source":
			power.text = "本机实际输出 %.1f kW" % model.power_state().sources[e.id]
	else:
		power.text = "被动物流 · 无需供电"
	ports.text = port_text(model, e)
	for label in [production, power, ports]:
		label.visible = not label.text.is_empty()


func _card(role: String, caption: String, value: String) -> void:
	cards[role].show()
	captions[role].text = caption
	values[role].text = value


static func _quantities(stock: Dictionary, batch: Dictionary) -> String:
	var lines := PackedStringArray()
	for item in batch:
		lines.append("%s  %d / %d" % [Rules.NAMES[item], int(stock.get(item, 0)), batch[item]])
	return "\n".join(lines)


static func port_text(model: RefCounted, e: Dictionary) -> String:
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
