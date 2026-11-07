extends PanelContainer

const Core := preload("res://data/factory/integrated_rules.gd")
const Items := preload("res://scripts/factory/items.gd")
const Slots := preload("res://scripts/factory/item_slot.gd")
const Logistics := preload("res://scripts/factory/logistics.gd")

signal closed
signal pause_requested

var model: RefCounted
var tabs := TabContainer.new()
var inventory: OptionButton
var inventory_counts: Label
var inventory_summary: Label
var transfer_buttons := {}
var outputs := {}
var inputs := {}
var result := Label.new()
var pause_button := Button.new()
var close_button := Button.new()


func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_RIGHT_WIDE)
	offset_left = -560
	offset_right = -20
	offset_top = 74
	offset_bottom = -202
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
	var title := _label(header, "基地核心 I")
	title.add_theme_font_size_override("font_size", 24)
	title.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	pause_button.text = "暂停生产"
	pause_button.pressed.connect(func(): pause_requested.emit())
	header.add_child(pause_button)
	close_button.text = "关闭 Esc"
	close_button.pressed.connect(close)
	header.add_child(close_button)
	_label(stack, "基础供电 %.0f kW · 下一阶段：研究与核心升级" % Core.BASE_KW)
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


func _item_options(choice: OptionButton, allow_sample: bool) -> void:
	choice.add_theme_constant_override("icon_max_width", 22)
	if not allow_sample:
		choice.add_item("未配置")
		choice.set_item_metadata(0, "")
	for item in model.item_ids:
		if item == "crust_sample" and not allow_sample:
			continue
		choice.add_icon_item(Slots.TEXTURES[item], Items.NAMES[item])
		choice.set_item_metadata(choice.item_count - 1, item)


func _build_inventory() -> void:
	inventory = OptionButton.new()
	inventory_counts = Label.new()
	inventory_summary = Label.new()
	var content := _tab("库存")
	_label(content, "每种物品最多 99,999 件 · 可近身手动取放")
	inventory_summary.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	content.add_child(inventory_summary)
	_item_options(inventory, true)
	inventory.item_selected.connect(func(_index): refresh())
	content.add_child(inventory)
	content.add_child(inventory_counts)
	var row := HBoxContainer.new()
	content.add_child(row)
	for mode in ["存入 1", "存入全部", "取出 1", "取出全部"]:
		var button := Button.new()
		button.text = mode
		row.add_child(button)
		var putting: bool = mode.begins_with("存入")
		var all_items: bool = mode.ends_with("全部")
		button.pressed.connect(func(): _transfer(putting, all_items))
		transfer_buttons[mode] = button


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
		_item_options(item, false)
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


func refresh(paused := false) -> void:
	if model == null:
		return
	pause_button.text = "恢复生产" if paused else "暂停生产"
	var item: String = inventory.get_selected_metadata()
	var available: int = model.core.items.get(item, 0)
	var in_bag: int = model.bag.get(item, 0)
	inventory_summary.text = "核心：%s" % Items.describe(model.core.items)
	inventory_counts.text = "核心 %d 件　背包 %d 件（%d / 200）" % [available, in_bag, Items.count(model.bag)]
	for mode in transfer_buttons:
		transfer_buttons[mode].disabled = (in_bag == 0 or available >= Core.ITEM_LIMIT) if mode.begins_with("存入") else (available == 0 or Items.count(model.bag) >= 200)
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


func _transfer(putting: bool, all_items: bool) -> void:
	var changed: Dictionary = model.transfer(model.core.id, inventory.get_selected_metadata(), putting, all_items)
	result.text = ("已%s %d 件" % ["存入" if putting else "取出", changed.amount]) if changed.ok else changed.reason
	refresh()


func _apply(id: String) -> void:
	var row: Dictionary = outputs[id]
	var changed: Dictionary = model.configure_output(model.core.id, id, row.item.get_selected_metadata(), row.enabled.button_pressed)
	result.text = "已应用 · " + row.port.name if changed.ok else changed.reason
	refresh()
