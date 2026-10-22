extends Control

signal device_action(name: String, id: int)
signal closed
const Rules := preload("res://data/factory/discovery_rules.gd")
const Items := preload("res://scripts/factory/items.gd")
const DeviceSummary := preload("res://scripts/factory/device_summary.gd")
const ItemSlot := preload("res://scripts/factory/item_slot.gd")
const Guidance := preload("res://scripts/factory/discovery_guidance.gd")
var model: RefCounted
var selected := -1
var device_only := false
var inventory_only := false
var bag_item := ""
var device_item := ""
var bag_slots := {}
var bag_grid := GridContainer.new()
var bag_frame := PanelContainer.new()
var body := HBoxContainer.new()
var frame := PanelContainer.new()
var heading := Label.new()
var runtime := Label.new()
var summary := Label.new()
var inventory := Label.new()
var result_label := Label.new()
var recipe := OptionButton.new()
var recipe_ids: Array[String] = []
var recipe_key := ""
var rows := {}
var bag_rows := {}
var bag_labels := {}
var recipe_row := HBoxContainer.new()
var buttons := {}
var device_summary := DeviceSummary.new()
var discovery_content := VBoxContainer.new()
var device_content := VBoxContainer.new()
var bag_content := VBoxContainer.new()
var actions := HBoxContainer.new()
var scroll := ScrollContainer.new()
var item_labels := {}
var guide_overview := Label.new()
var elapsed := 0.0
var admission_controls := preload("res://scripts/factory/admission_controls.gd").new()


func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_STOP
	var shade := ColorRect.new()
	shade.color = Color(0.015, 0.035, 0.035, 0.4)
	shade.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(shade)
	add_child(frame)
	frame.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	frame.offset_left = 40
	frame.offset_right = -40
	frame.offset_top = 40
	frame.offset_bottom = -40
	frame.add_theme_stylebox_override("panel", _style("142928", 20))
	var layout := VBoxContainer.new()
	layout.add_theme_constant_override("separation", 16)
	frame.add_child(layout)
	var header := HBoxContainer.new()
	header.add_theme_constant_override("separation", 16)
	layout.add_child(header)
	heading.add_theme_font_size_override("font_size", 24)
	heading.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	header.add_child(heading)
	header.add_child(runtime)
	button(header, "pause", "暂停", func(): device_action.emit("pause", selected))
	button(header, "close", "关闭  ×  Esc", close_panel)
	layout.add_child(admission_controls)
	admission_controls.applied.connect(apply)
	body.add_theme_constant_override("separation", 24)
	body.size_flags_vertical = Control.SIZE_EXPAND_FILL
	layout.add_child(body)
	bag_frame.custom_minimum_size.x = 348
	bag_frame.add_theme_stylebox_override("panel", _style("1c3231", 16))
	body.add_child(bag_frame)
	var bag_scroll := ScrollContainer.new()
	bag_scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	bag_frame.add_child(bag_scroll)
	bag_content.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	bag_scroll.add_child(bag_content)
	bag_content.add_theme_constant_override("separation", 12)
	bag_content.add_child(inventory)
	inventory.add_theme_font_size_override("font_size", 20)
	bag_grid.columns = 3
	bag_grid.size_flags_horizontal = Control.SIZE_SHRINK_BEGIN
	bag_grid.add_theme_constant_override("h_separation", 10)
	bag_grid.add_theme_constant_override("v_separation", 10)
	bag_content.add_child(bag_grid)
	for item in Items.NAMES:
		var slot := ItemSlot.new()
		slot.item_id = item
		bag_grid.add_child(slot)
		bag_slots[item] = slot
		slot.pressed.connect(func(): select_item(item, true))
		var detail := VBoxContainer.new()
		detail.add_theme_constant_override("separation", 10)
		bag_content.add_child(detail)
		bag_rows[item] = detail
		var count := Label.new()
		count.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		detail.add_child(count)
		bag_labels[item] = count
		var put := HBoxContainer.new()
		detail.add_child(put)
		button(put, item + "_put_one", "放入 1 →", func(): apply(model.transfer(selected, item, true, false)))
		button(put, item + "_put_all", "放入全部 →", func(): apply(model.transfer(selected, item, true, true)))
		for suffix in ["put_one", "put_all"]:
			buttons[item + "_" + suffix].set_meta("item_id", item)
			buttons[item + "_" + suffix].set_meta("bag_side", true)
	scroll.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	body.add_child(scroll)
	var content := VBoxContainer.new()
	content.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	content.add_theme_constant_override("separation", 14)
	scroll.add_child(content)
	content.add_child(discovery_content)
	discovery_content.add_theme_constant_override("separation", 16)
	discovery_content.add_child(summary)
	var discovery_row := HBoxContainer.new()
	discovery_content.add_child(discovery_row)
	button(discovery_row, "survey", "调查样本", func(): apply(model.survey_sample()))
	button(discovery_row, "sample", "拾取样本", func(): apply(model.survey_sample(true)))
	button(discovery_row, "outer", "外矿道：用 4 份", func(): apply(model.open_passage("outer")))
	button(discovery_row, "inner", "内矿道：用 8 份", func(): apply(model.open_passage("inner")))
	discovery_content.add_child(guide_overview)
	guide_overview.add_theme_font_size_override("font_size", 18)
	content.add_child(device_content)
	device_content.add_theme_constant_override("separation", 16)
	device_summary.compact = false
	device_content.add_child(device_summary)
	device_summary.heading.hide()
	device_summary.item_selected.connect(func(item): select_item(item, false))
	device_content.add_child(recipe_row)
	recipe_row.add_theme_constant_override("separation", 8)
	recipe.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	recipe_row.add_child(recipe)
	button(recipe_row, "recipe", "切换配方", func():
		if recipe.selected >= 0:
			apply(model.change_recipe(selected, recipe_ids[recipe.selected])))
	button(recipe_row, "cancel_batch", "取消本批并返料", func(): apply(model.cancel_batch(selected)))
	for item in Items.NAMES:
		var row := HBoxContainer.new()
		row.add_theme_constant_override("separation", 8)
		device_content.add_child(row)
		rows[item] = row
		var label := Label.new()
		label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		row.add_child(label)
		item_labels[item] = label
		button(row, item + "_take_one", "←  取出 1", func(): apply(model.transfer(selected, item, false, false)))
		button(row, item + "_take_all", "←  取出全部", func(): apply(model.transfer(selected, item, false, true)))
		for suffix in ["take_one", "take_all"]:
			buttons[item + "_" + suffix].set_meta("item_id", item)
			buttons[item + "_" + suffix].set_meta("bag_side", false)
	device_content.add_child(actions)
	actions.add_theme_constant_override("separation", 8)
	for option in [["power_toggle", "启用 / 关闭电源"], ["power_connect", "从此节点接线"], ["power_disconnect", "选择连接并断开"], ["rotate_selected", "旋转物流构件"], ["salvage", "回收设备与物料"]]:
		button(actions, option[0], option[1], func(): device_action.emit(option[0], selected))
	for label in [summary, inventory, result_label, guide_overview]:
		label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	result_label.custom_minimum_size.y = 44
	layout.add_child(result_label)
	hide()


static func _style(color: String, padding: int) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = Color(color)
	style.border_color = Color("607b70")
	style.set_border_width_all(1)
	style.set_corner_radius_all(6)
	for side in ["left", "right", "top", "bottom"]:
		style.set("content_margin_" + side, padding)
	return style


func button(parent: Node, id: String, text: String, callback: Callable) -> void:
	var control := Button.new()
	control.text = text
	control.pressed.connect(callback)
	parent.add_child(control)
	buttons[id] = control


func show_for(world: RefCounted) -> void:
	_open(world, -1, false)


func show_inventory(world: RefCounted) -> void:
	_open(world, -1, false, true)


func pauses_production() -> bool:
	return visible and not device_only and not inventory_only


func select_item(item: String, from_bag: bool) -> void:
	if from_bag:
		bag_item = item
	else:
		device_item = item
	refresh()


func item_button(item: String, from_bag: bool) -> Button:
	if from_bag:
		return bag_slots[item]
	for role in device_summary.slots:
		var slot: Button = device_summary.slots[role][item]
		if slot.is_visible_in_tree():
			return slot
	return null


func show_device(world: RefCounted, id: int) -> bool:
	var e: Dictionary = world.by_id(id)
	if e.is_empty() or not world.near_entity(e):
		return false
	_open(world, id, true)
	return true


func _open(world: RefCounted, id: int, only_device: bool, only_inventory := false) -> void:
	model = world
	selected = id
	device_only = only_device
	inventory_only = only_inventory
	bag_item = ""
	device_item = ""
	recipe_key = ""
	admission_controls.config_key = ""
	discovery_content.visible = not device_only and not inventory_only
	device_content.visible = device_only
	result_label.text = "点选物品，再取出或放入。产线持续运行；在制材料需取消本批后返还。" if device_only else "背包按物料汇总；容量按件数计算。走近设备后可取放物品。" if inventory_only else "工艺回查期间生产暂停；关闭后保持原暂停偏好。"
	if device_only and model.by_id(selected).type in ["splitter", "merger", "admission_gate"]:
		result_label.text = "物料自动通过附件；空载时可旋转，回收时整件返还内部物料。"
	result_label.remove_theme_color_override("font_color")
	scroll.scroll_vertical = 0
	scroll.visible = not inventory_only
	bag_grid.columns = 5 if inventory_only else 3
	bag_frame.size_flags_horizontal = Control.SIZE_EXPAND_FILL if inventory_only else Control.SIZE_FILL
	var warehouse: bool = device_only and model.by_id(selected).type == "storage"
	body.move_child(bag_frame, 1 if warehouse else 0)
	show()
	refresh()
	buttons.close.grab_focus()


func close_panel() -> void:
	var owner := get_viewport().gui_get_focus_owner()
	if owner != null and is_ancestor_of(owner):
		owner.release_focus()
	hide()
	closed.emit()


func _input(event: InputEvent) -> void:
	if visible and event is InputEventKey and event.pressed and (event.physical_keycode == KEY_ESCAPE or (inventory_only and event.physical_keycode == KEY_I)):
		close_panel()
		get_viewport().set_input_as_handled()


func _process(delta: float) -> void:
	if not visible or model == null:
		return
	elapsed += delta
	if elapsed >= 0.1:
		refresh()


func sync_session(paused: bool, focused: bool) -> void:
	if not is_node_ready():
		return
	buttons.pause.visible = device_only or inventory_only
	buttons.pause.text = "继续" if paused else "暂停"
	runtime.text = "已手动暂停" if paused else ("生产继续运行" if focused else "后台生产中") if device_only or inventory_only else "工艺回查 · 暂停"
	runtime.add_theme_color_override("font_color", Color("77d8c6" if (device_only or inventory_only) and not paused else "e2b365"))


func apply(result: Dictionary) -> void:
	result_label.text = ("已转移 %d 件。" % result.amount if result.has("amount") else result.get("message", "操作完成。")) if result.ok else result.reason
	result_label.add_theme_color_override("font_color", Color("77d8c6" if result.ok else "efab86"))
	refresh()


func refresh() -> void:
	if model == null:
		return
	elapsed = 0
	var d: Dictionary = model.discovery
	var e: Dictionary = model.by_id(selected)
	if device_only and (e.is_empty() or not model.near_entity(e)):
		close_panel()
		return
	heading.text = "%s  #%d" % [Rules.CATALOG[e.type].name, e.id] if device_only else "背包" if inventory_only else "工艺、物料与矿道"
	inventory.text = "背包  ·  %d / 200 件" % Items.count(model.bag)
	guide_overview.text = Guidance.overview(model)
	summary.text = "外矿道：%s　内矿道：%s\n试制掌握量产方法；携带解壳剂在矿道西侧使用。" % ["已打通" if d.passages.outer else "未打通", "已打通" if d.passages.inner else "未打通"]
	buttons.sample.disabled = d.sample_taken or not model.near_sample() or Items.count(model.bag) >= 200
	buttons.outer.disabled = d.passages.outer or not model.near_passage("outer") or model.bag.get("crust_solvent", 0) < 4 or not d.trial_completed
	buttons.inner.disabled = d.passages.inner or not d.passages.outer or not model.near_passage("inner") or model.bag.get("crust_solvent", 0) < 8 or not d.trial_completed
	var stores_items: bool = device_only and e.type in model.process_types + ["collector", "storage"]
	admission_controls.visible = device_only and e.type == "admission_gate"
	if admission_controls.visible: admission_controls.refresh(model, e)
	bag_frame.visible = not device_only or stores_items
	if device_only:
		device_summary.refresh(model, e)
	if stores_items and not device_item.is_empty() and item_button(device_item, false) == null:
		device_item = ""
	recipe_row.visible = device_only and e.type in model.process_types
	if recipe_row.visible:
		_sync_recipes(e)
		buttons.recipe.disabled = e.processing or not e.input.is_empty() or not e.output.is_empty()
		buttons.recipe.tooltip_text = "切换前须结束本批，并取空输入和输出。"
		buttons.cancel_batch.disabled = not e.processing
	var contents := Items.contents(e) if stores_items else {}
	for item in Items.NAMES:
		var known: bool = item in model.item_ids and (item in Rules.Expansion.NAMES or item in ["crystal", "catalyst"] or (item == "crust_sample" and d.sample_taken) or d.trial_completed)
		var available: int = contents.get(item, 0) - e.get("invested", {}).get(item, 0)
		if bag_item.is_empty() and known:
			bag_item = item
		bag_slots[item].visible = known
		bag_slots[item].update_amount(model.bag.get(item, 0))
		bag_slots[item].mark_selected(bag_item == item)
		bag_rows[item].visible = known and bag_item == item
		bag_labels[item].text = "%s   ×%d" % [Items.NAMES[item], model.bag.get(item, 0)]
		for action in ["put_one", "put_all"]:
			buttons[item + "_" + action].visible = stores_items
			buttons[item + "_" + action].disabled = not stores_items or model.bag.get(item, 0) == 0 or model.input_room(e, item, true) <= 0
		var has_slot: bool = stores_items and item_button(item, false) != null
		if device_item.is_empty() and has_slot:
			device_item = item
		rows[item].visible = has_slot and device_item == item
		item_labels[item].text = "%s · 可取 %d" % [Items.NAMES[item], available]
		for action in ["take_one", "take_all"]:
			buttons[item + "_" + action].disabled = available <= 0 or Items.count(model.bag) >= 200
	device_summary.select_item(device_item)
	if not device_only:
		return
	buttons.power_toggle.visible = e.type == "power_source"
	buttons.power_toggle.text = "关闭电源" if e.get("enabled", false) else "启用电源"
	buttons.power_connect.visible = not model.automatic_power and model.Grid.is_node(e)
	buttons.power_disconnect.visible = not model.automatic_power and not model.connections(e.id).is_empty()
	buttons.rotate_selected.visible = e.type in ["belt", "splitter", "merger", "admission_gate"]
	buttons.salvage.text = "回收传送带与货物" if e.type == "belt" else "回收设备与物料"


func _sync_recipes(e: Dictionary) -> void:
	var available: Array[String] = []
	for id in model.recipes:
		if model.recipe_available(id) and model.recipes[id].get("machine", "reactor") == e.type:
			available.append(id)
	var key := str([available, e.recipe_id])
	if key == recipe_key:
		return
	# Production refresh must not overwrite a player's uncommitted menu choice.
	recipe_key = key
	recipe_ids = available
	recipe.clear()
	for id in recipe_ids:
		var r: Dictionary = model.recipes[id]
		recipe.add_item("%s · %.0fs / %.0fkW" % [r.name, r.seconds, r.kw])
		if e.recipe_id == id:
			recipe.select(recipe_ids.find(id))
