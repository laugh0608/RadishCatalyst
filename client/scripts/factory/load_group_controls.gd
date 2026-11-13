extends VBoxContainer

signal applied(result: Dictionary)

const Loads := preload("res://data/factory/load_group_rules.gd")
var model: RefCounted
var selected := -1
var config_key := ""
var status := Label.new()
var reserve := SpinBox.new()
var members := VBoxContainer.new()
var saved_members := HFlowContainer.new()
var apply_button := Button.new()
var enable_button := Button.new()
var clear_button := Button.new()
var preview := Label.new()
var choices := {}
var draft: Array[int] = []
var list_key := ""


func _ready() -> void:
	add_theme_constant_override("separation", 8)
	var title := Label.new()
	title.text = "可推迟负载组"
	title.add_theme_font_size_override("font_size", 18)
	add_child(title)
	for label in [status, preview]:
		label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	add_child(status)
	var row := HBoxContainer.new()
	add_child(row)
	var caption := Label.new()
	caption.text = "开工估算保留量（kJ）"
	row.add_child(caption)
	reserve.max_value = 3600
	reserve.step = 1
	reserve.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	row.add_child(reserve)
	var actions := HFlowContainer.new()
	add_child(actions)
	apply_button.text = "应用负载组"
	clear_button.text = "清空组"
	for button in [apply_button, enable_button, clear_button]:
		actions.add_child(button)
	apply_button.pressed.connect(func(): applied.emit(model.configure_load_group(selected, draft, int(reserve.value) * 1000)))
	enable_button.pressed.connect(func(): applied.emit(model.set_load_group_enabled(selected, not model.by_id(selected).load_group.enabled)))
	clear_button.pressed.connect(func(): applied.emit(model.clear_load_group(selected)))
	var expand := CheckButton.new()
	expand.text = "展开当前预算预览"
	add_child(expand)
	add_child(preview)
	preview.hide()
	expand.toggled.connect(func(on): preview.visible = on)
	var hint := Label.new()
	hint.text = "最多 8 台；只推迟新批，保留在制与本机停机。每秒评估一次，余量至少 20 kW 才恢复。保留量不锁住实际放电。"
	hint.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	add_child(hint)
	add_child(saved_members)
	add_child(members)
	hide()


func refresh(world: RefCounted, e: Dictionary) -> void:
	model = world
	selected = e.id
	var g: Dictionary = e.load_group
	var key := str([e.id, g.member_ids, g.reserve_j])
	if key != config_key:
		config_key = key
		draft.assign(g.member_ids)
		reserve.set_value_no_signal(g.reserve_j / 1000)
		list_key = ""
	var rows := []
	for entity in model.entities:
		if not Loads.eligible(entity):
			continue
		var owner: Dictionary = model.load_group_owner(entity.id)
		if (owner.is_empty() or owner.id == e.id) and model.load_network(entity) == model.load_network(e) and model.load_network(e) >= 0:
			rows.append([entity.id, entity.recipe_id, entity.enabled])
	var signature := str([key, rows])
	if signature != list_key:
		list_key = signature
		for parent in [members, saved_members]:
			for child in parent.get_children():
				parent.remove_child(child)
				child.queue_free()
		choices.clear()
		for id in g.member_ids:
			var remove := Button.new()
			remove.text = "移除 #%d" % id
			saved_members.add_child(remove)
			remove.pressed.connect(func(): applied.emit(model.remove_load_member(selected, id)))
		for row in rows:
			var member: Dictionary = model.by_id(row[0])
			var choice := CheckBox.new()
			choice.text = "#%d (%d,%d) · %s · %s" % [member.id, member.x, member.z, model.recipes[member.recipe_id].name, "启用" if member.enabled else "本机停机"]
			choice.set_pressed_no_signal(member.id in draft)
			members.add_child(choice)
			choices[member.id] = choice
			choice.toggled.connect(func(on):
				if on and member.id not in draft: draft.append(member.id)
				elif not on: draft.erase(member.id)
				_candidate())
	status.text = "储能 #%d · 已配置 %d / 8 台 · %s\n上次决定：%s · 距下次评估 %.2f 秒" % [
		e.id, g.member_ids.size(), "控制启用" if g.enabled else "控制关闭",
		{"pending": "待评估", "allow": "允许新批", "block": "等待功率余量"}[g.latch], (g.evaluation_ticks_left + 1) * 0.05 if g.enabled else 0.0]
	var reason: String = model.load_group_reason(e)
	if not reason.is_empty(): status.text += "\n" + reason
	if not model.researched.has(Loads.RESEARCH): status.text += "\n请先在核心 III 研究负载管理"
	enable_button.text = "关闭控制，恢复普通开工" if g.enabled else "启用负载组"
	enable_button.disabled = not model.researched.has(Loads.RESEARCH) or (not g.enabled and g.member_ids.is_empty())
	clear_button.disabled = g.member_ids.is_empty()
	var budget: Dictionary = model.load_group_budget(e)
	preview.text = "当前配置预算预览（不是上次样本）：" + ("%.2f 秒 · 需求 %.3f kW / 可持续 %.3f kW / 余量 %.3f kW" % [budget.horizon_ticks * 0.05, budget.demand_w / 1000.0, budget.supply_w / 1000.0, budget.margin_w / 1000.0] if budget.ok else budget.reason)
	_candidate()


func _candidate() -> void:
	apply_button.disabled = model == null or not model.researched.has(Loads.RESEARCH) or draft.is_empty() or draft.size() > Loads.MAX_MEMBERS
