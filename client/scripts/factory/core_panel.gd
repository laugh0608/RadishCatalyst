extends PanelContainer

const Core := preload("res://data/factory/integrated_rules.gd")
const Progression := preload("res://data/factory/integrated_progression.gd")
const Rules := preload("res://data/factory/discovery_rules.gd")
const Items := preload("res://scripts/factory/items.gd")
const Slots := preload("res://scripts/factory/item_slot.gd")
const Logistics := preload("res://scripts/factory/logistics.gd")

signal closed
signal pause_requested

var model: RefCounted
var tabs := TabContainer.new()
var inventory_slots := {"core": {}, "bag": {}}
var inventory_empty := {}
var inventory_selection: Label
var bag_capacity: Label
var selected_item := ""
var transfer_buttons := {}
var outputs := {}
var inputs := {}
var result := Label.new()
var pause_button := Button.new()
var close_button := Button.new()
var title: Label
var research_choice: OptionButton
var research_details: Label
var research_button: Button
var upgrade_details: Label
var upgrade_button: Button
var assembly_choice: OptionButton
var assembly_details: Label
var assembly_button: Button


func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_RIGHT_WIDE)
	offset_left = -850
	offset_right = -20
	offset_top = 74
	offset_bottom = -142
	var frame := StyleBoxFlat.new()
	frame.bg_color = Color("142528")
	frame.border_color = Color("60766b")
	frame.set_border_width_all(1)
	frame.set_corner_radius_all(6)
	frame.set_content_margin_all(14)
	add_theme_stylebox_override("panel", frame)
	var stack := VBoxContainer.new()
	stack.add_theme_constant_override("separation", 10)
	add_child(stack)
	var header := HBoxContainer.new()
	stack.add_child(header)
	title = _label(header, "基地核心 I")
	title.add_theme_font_size_override("font_size", 24)
	title.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	pause_button.text = "暂停生产"
	pause_button.pressed.connect(func(): pause_requested.emit())
	header.add_child(pause_button)
	close_button.text = "关闭 Esc"
	close_button.pressed.connect(close)
	header.add_child(close_button)
	_label(stack, "基础供电 %.0f kW" % Core.BASE_KW)
	tabs.size_flags_vertical = Control.SIZE_EXPAND_FILL
	stack.add_child(tabs)
	stack.add_child(result)
	result.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	visibility_changed.connect(func(): if not visible: closed.emit())
	hide()


func open(world_model: RefCounted) -> void:
	model = world_model
	if outputs.is_empty():
		_build_inventory()
		_build_interfaces()
		_build_progression()
	for id in outputs:
		var row: Dictionary = outputs[id]
		var config: Dictionary = model.core.outputs[id]
		for i in row.item.item_count:
			if row.item.get_item_metadata(i) == config.item:
				row.item.select(i)
				break
		row.enabled.set_pressed_no_signal(config.enabled)
	result.text = ""
	refresh()
	show()


func close() -> void:
	hide()


func _unhandled_key_input(event: InputEvent) -> void:
	if visible and event.is_action_pressed("ui_cancel"):
		close()
		get_viewport().set_input_as_handled()


func _tab(title: String) -> VBoxContainer:
	var scroll := ScrollContainer.new()
	scroll.name = title
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	tabs.add_child(scroll)
	var content := VBoxContainer.new()
	content.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	content.add_theme_constant_override("separation", 6)
	scroll.add_child(content)
	return content


func _label(parent: Node, caption: String) -> Label:
	var label := Label.new()
	label.text = caption
	parent.add_child(label)
	return label


func _output_items(choice: OptionButton) -> void:
	choice.add_theme_constant_override("icon_max_width", 22)
	choice.add_item("未配置")
	choice.set_item_metadata(0, "")
	for item in model.item_ids:
		if item == "crust_sample":
			continue
		choice.add_icon_item(Slots.TEXTURES[item], Items.NAMES[item])
		choice.set_item_metadata(choice.item_count - 1, item)


func _build_inventory() -> void:
	var content := VBoxContainer.new()
	content.name = "库存"
	tabs.add_child(content)
	_label(content, "拖到对侧转移物品，按剩余容量移动。点击物品也可用下方按钮单件取放。")
	inventory_selection = _label(content, "")
	var row := HBoxContainer.new()
	content.add_child(row)
	for mode in ["存入 1", "存入全部", "取出 1", "取出全部"]:
		var button := Button.new()
		button.text = mode
		row.add_child(button)
		var putting: bool = mode.begins_with("存入")
		var all_items: bool = mode.ends_with("全部")
		button.pressed.connect(func(): _transfer(selected_item, putting, all_items))
		transfer_buttons[mode] = button
	var scroll := ScrollContainer.new()
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	content.add_child(scroll)
	var sides := HBoxContainer.new()
	sides.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	sides.size_flags_vertical = Control.SIZE_EXPAND_FILL
	sides.add_theme_constant_override("separation", 12)
	scroll.add_child(sides)
	_inventory_side(sides, "core", "核心库存")
	_inventory_side(sides, "bag", "背包")


func _inventory_side(parent: Control, side: String, caption: String) -> void:
	var frame := PanelContainer.new()
	frame.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	frame.custom_minimum_size.y = 150
	var style := StyleBoxFlat.new()
	style.bg_color = Color("1c3231")
	style.border_color = Color("4a6963")
	style.set_border_width_all(1)
	style.set_content_margin_all(10)
	style.set_corner_radius_all(5)
	frame.add_theme_stylebox_override("panel", style)
	frame.set_drag_forwarding(Callable(), _can_drop_inventory.bind(side), _drop_inventory.bind(side))
	parent.add_child(frame)
	var contents := VBoxContainer.new()
	contents.mouse_filter = Control.MOUSE_FILTER_IGNORE
	frame.add_child(contents)
	var header := _label(contents, caption)
	header.add_theme_font_size_override("font_size", 20)
	var capacity := _label(contents, "单种最多 99,999 件" if side == "core" else "")
	if side == "bag":
		bag_capacity = capacity
	var grid := GridContainer.new()
	grid.columns = 4
	grid.size_flags_horizontal = Control.SIZE_SHRINK_BEGIN
	grid.mouse_filter = Control.MOUSE_FILTER_IGNORE
	grid.add_theme_constant_override("h_separation", 6)
	grid.add_theme_constant_override("v_separation", 6)
	contents.add_child(grid)
	for item in model.item_ids:
		var slot := Slots.new()
		slot.item_id = item
		slot.pressed.connect(_select_inventory_item.bind(item))
		slot.set_drag_forwarding(_drag_inventory.bind(side, item), _can_drop_inventory.bind(side), _drop_inventory.bind(side))
		grid.add_child(slot)
		slot.custom_minimum_size = Vector2(78, 80)
		inventory_slots[side][item] = slot
	var empty := _label(contents, "暂无物品")
	empty.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	empty.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	empty.size_flags_vertical = Control.SIZE_EXPAND_FILL
	inventory_empty[side] = empty


func _drag_inventory(_position: Vector2, side: String, item: String) -> Variant:
	var stock: Dictionary = model.core.items if side == "core" else model.bag
	if stock.get(item, 0) <= 0:
		return null
	var preview := TextureRect.new()
	preview.texture = Slots.TEXTURES[item]
	preview.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	preview.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	preview.size = Vector2(52, 52)
	preview.mouse_filter = Control.MOUSE_FILTER_IGNORE
	set_drag_preview(preview)
	return {"panel": get_instance_id(), "side": side, "item": item}


func _can_drop_inventory(_position: Vector2, data: Variant, side: String) -> bool:
	var source := "bag" if side == "core" else "core"
	return (is_visible_in_tree() and tabs.current_tab == 0 and data is Dictionary and data.get("panel") == get_instance_id()
		and data.get("side") == source and data.get("item") in model.item_ids)


func _drop_inventory(position: Vector2, data: Variant, side: String) -> void:
	if _can_drop_inventory(position, data, side):
		selected_item = data.item
		_transfer(selected_item, side == "core", true)


func _select_inventory_item(item: String) -> void:
	selected_item = item
	_refresh_inventory()


func _build_interfaces() -> void:
	var content := _tab("接口")
	_label(content, "四面各三进一出 · 出口每秒至多一件")
	_label(content, "选择物品、勾选启用，再点应用。")
	for port in Logistics.ports(model, model.core, "output"):
		var group := VBoxContainer.new()
		group.add_theme_constant_override("separation", 1)
		content.add_child(group)
		var row := HBoxContainer.new()
		group.add_child(row)
		_label(row, port.name)
		var item := OptionButton.new()
		item.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		_output_items(item)
		row.add_child(item)
		var enabled := CheckBox.new()
		enabled.text = "启用"
		row.add_child(enabled)
		var apply := Button.new()
		apply.text = "应用"
		row.add_child(apply)
		var id: String = port.id
		apply.pressed.connect(func(): _apply(id))
		outputs[id] = {"port": port, "item": item, "enabled": enabled, "apply": apply, "status": _label(group, "")}
	_label(content, "输入状态")
	var grid := GridContainer.new()
	grid.columns = 4
	grid.add_theme_constant_override("h_separation", 14)
	content.add_child(grid)
	for port in Logistics.ports(model, model.core, "input"):
		if port.index % 3 == 0:
			_label(grid, Core.FACE_NAMES[port.index / 3] + "侧")
		inputs[port.id] = {"port": port, "status": _label(grid, "")}


func _build_progression() -> void:
	var content := _tab("研究")
	_label(content, "从核心库存一次提交材料")
	research_choice = OptionButton.new()
	content.add_child(research_choice)
	for id in model.research_nodes:
		research_choice.add_item(model.research_nodes[id].name)
		research_choice.set_item_metadata(research_choice.item_count - 1, id)
	research_choice.select(1)
	research_choice.item_selected.connect(func(_index): _refresh_progression())
	research_details = _details(content)
	research_button = _action_button(content, "提交研究", func():
		_progress_result(model.research(research_choice.get_selected_metadata()), "研究完成"))
	content = _tab("等级")
	upgrade_details = _details(content)
	upgrade_button = _action_button(content, "升至核心 II", func():
		var result: Dictionary = model.upgrade_core()
		_progress_result(result, "已升至核心 " + Progression.TIER_LABELS[model.core.level]))
	content = _tab("装配")
	_label(content, "构件包从核心扣除，成品进入建造库存")
	assembly_choice = OptionButton.new()
	content.add_child(assembly_choice)
	for type in model.assembly_costs:
		assembly_choice.add_item(Rules.CATALOG[type].name)
		assembly_choice.set_item_metadata(assembly_choice.item_count - 1, type)
	assembly_choice.item_selected.connect(func(_index): _refresh_progression())
	assembly_details = _details(content)
	assembly_button = _action_button(content, "装配构件", func():
		var outcome: Dictionary = model.assemble(assembly_choice.get_selected_metadata())
		_progress_result(outcome, "已装配 %d 件" % outcome.get("quantity", 0)))


func _details(parent: Control) -> Label:
	var label := _label(parent, "")
	label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	return label


func _action_button(parent: Control, caption: String, action: Callable) -> Button:
	var button := Button.new()
	button.text = caption
	button.pressed.connect(action)
	parent.add_child(button)
	return button


func _requirements(ids: Array) -> String:
	var names := PackedStringArray()
	for id in ids:
		names.append(model.research_nodes[id].name + (" ✓" if model.researched.has(id) else " 待完成"))
	return "、".join(names) if not names.is_empty() else "无"


func _refresh_progression() -> void:
	var level: String = Progression.TIER_LABELS[model.core.level]
	title.text = "基地核心 " + level
	var id: String = research_choice.get_selected_metadata()
	var node: Dictionary = model.research_nodes[id]
	var state: Dictionary = model.research_status(id)
	var done: bool = model.researched.has(id)
	var sample := ""
	if node.sample:
		sample = "
外矿道入口的矿壳样本：%s" % ("已拾取" if model.discovery.sample_taken else "待拾取")
	if id == Rules.Integrated.Frontier.RESEARCH:
		sample = "\n矿壳试制：%s" % ("已完成" if model.discovery.trial_completed else "待完成")
	var stock: Dictionary = model.missing_stock(node.cost)
	var payment := "材料齐备" if stock.is_empty() else "缺少 " + Items.describe(stock)
	if done:
		payment = "开局已有" if node.cost.is_empty() else "已提交材料"
	research_details.text = "%s

要求核心 %s · 当前 %s
前置：%s%s
成本 %s
%s
%s" % [
		node.effect, Progression.TIER_LABELS[node.level], level, _requirements(node.requires), sample,
		Items.describe(node.cost), payment,
		"可提交" if state.ok else state.reason]
	research_button.disabled = not state.ok
	state = model.upgrade_status()
	var target: int = model.core.level + 1
	var upgrade: Dictionary = model.core_upgrades.get(target, {})
	upgrade_button.visible = not upgrade.is_empty()
	upgrade_button.disabled = not state.ok
	upgrade_details.text = "当前核心 " + level
	if not upgrade.is_empty():
		upgrade_button.text = "升至核心 " + Progression.TIER_LABELS[target]
		var effect := "核心 II 开放工业电芯、混料冶炼与矿渣回用研究。" if target == 2 else "核心 III 为电网测控做准备，核心额定功率仍为 360 kW。"
		if target == 3 and model.kits.has(Core.Storage.TYPE):
			effect = "核心 III 开放电网缓冲研究，核心额定功率仍为 360 kW。"
		upgrade_details.text += "\n\n%s\n前置：%s\n成本：%s\n%s" % [
			effect, _requirements(upgrade.requires), Items.describe(upgrade.cost), "可升级" if state.ok else state.reason]
	var type: String = assembly_choice.get_selected_metadata()
	state = model.assembly_status(type)
	var owner: String = model.device_research(type)
	var materials := {"construction_pack": model.assembly_costs[type]}
	if type == Core.Storage.TYPE:
		materials.industrial_cell = Core.Storage.ASSEMBLY_CELLS
	assembly_details.text = "要求：%s
%s → %d 件 · 核心现有 %d 包
总拥有量 %d / %d
%s" % [
		_requirements([Progression.ASSEMBLY] if owner in [Progression.BASE, Progression.ASSEMBLY] else [Progression.ASSEMBLY, owner]),
		Items.describe(materials), Rules.Expansion.yield_for(type), model.core.items.get("construction_pack", 0),
		model.owned_count(), Progression.MAX_OWNED, "可装配" if state.ok else state.reason]
	assembly_button.disabled = not state.ok


func _progress_result(outcome: Dictionary, message: String) -> void:
	result.text = message if outcome.ok else outcome.reason
	_refresh_progression()


func refresh(paused := false) -> void:
	if model == null:
		return
	pause_button.text = "恢复生产" if paused else "暂停生产"
	_refresh_progression()
	_refresh_inventory()
	for id in outputs:
		var row: Dictionary = outputs[id]
		var config: Dictionary = model.core.outputs[id]
		row.status.text = "已应用：%s · %s" % [Items.NAMES.get(config.item, "无"), Logistics.core_output_feedback(model, model.core, row.port)]
	for id in inputs:
		var row: Dictionary = inputs[id]
		var status := Logistics.input_connection(model, model.core, row.port)
		var text: String = status.reason
		if status.ok and Logistics.transport(status.source) and not status.source.cargo.is_empty() and model.input_room(model.core, status.source.cargo) == 0:
			text = "样本禁运" if status.source.cargo == "crust_sample" else "该物品已满"
		row.status.text = "%d · %s" % [row.port.index % 3 + 1, text]


func _refresh_inventory() -> void:
	var bag_count := Items.count(model.bag)
	bag_capacity.text = "容量 %d / 200 件" % bag_count
	var in_core: int = model.core.items.get(selected_item, 0)
	var in_bag: int = model.bag.get(selected_item, 0)
	if in_core == 0 and in_bag == 0:
		selected_item = ""
	for side in inventory_slots:
		var stock: Dictionary = model.core.items if side == "core" else model.bag
		inventory_empty[side].visible = stock.is_empty()
		for item in inventory_slots[side]:
			var slot: Button = inventory_slots[side][item]
			var amount: int = stock.get(item, 0)
			slot.visible = amount > 0
			if slot.amount != amount:
				slot.update_amount(amount)
			slot.mark_selected(item == selected_item)
	inventory_selection.text = "请选择物品" if selected_item.is_empty() else "已选：" + Items.NAMES[selected_item]
	for mode in transfer_buttons:
		transfer_buttons[mode].disabled = (in_bag == 0 or in_core >= Core.ITEM_LIMIT) if mode.begins_with("存入") else (in_core == 0 or bag_count >= 200)


func _transfer(item: String, putting: bool, all_items: bool) -> void:
	var changed: Dictionary = model.transfer(model.core.id, item, putting, all_items)
	result.text = ("已%s %s ×%d" % ["存入" if putting else "取出", Items.NAMES[item], changed.amount]) if changed.ok else changed.reason
	_refresh_inventory()


func _apply(id: String) -> void:
	var row: Dictionary = outputs[id]
	var changed: Dictionary = model.configure_output(model.core.id, id, row.item.get_selected_metadata(), row.enabled.button_pressed)
	result.text = "已应用 · " + row.port.name if changed.ok else changed.reason
	refresh()
