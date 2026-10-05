extends AcceptDialog

const Rules := preload("res://data/factory/discovery_rules.gd")
const Items := preload("res://scripts/factory/items.gd")
const DeviceSummary := preload("res://scripts/factory/device_summary.gd")
const Guidance := preload("res://scripts/factory/discovery_guidance.gd")
var model: RefCounted
var selected := -1
var summary := Label.new()
var inventory := Label.new()
var result_label := Label.new()
var recipe := OptionButton.new()
var recipe_ids: Array[String] = []
var rows := {}
var recipe_row := HBoxContainer.new()
var buttons := {}
var device_summary := DeviceSummary.new()
var discovery_content := VBoxContainer.new()
var scroll := ScrollContainer.new()
var item_labels := {}
var device_only := false
var guide_overview := Label.new()


func _ready() -> void:
	title = "工艺、物料与矿道"
	ok_button_text = "返回工厂"
	exclusive = true
	var layout := VBoxContainer.new()
	layout.add_theme_constant_override("separation", 10)
	add_child(layout)
	scroll.custom_minimum_size = Vector2(740, 420)
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	layout.add_child(scroll)
	var content := VBoxContainer.new()
	content.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	content.add_theme_constant_override("separation", 10)
	scroll.add_child(content)
	for label in [summary, inventory, result_label]:
		label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	content.add_child(discovery_content)
	discovery_content.add_child(summary)
	var discovery_row := HBoxContainer.new()
	discovery_content.add_child(discovery_row)
	button(discovery_row, "survey", "调查样本", func(): apply(model.survey_sample()))
	button(discovery_row, "sample", "拾取唯一样本", func(): apply(model.survey_sample(true)))
	button(discovery_row, "outer", "外矿道：用 4 份", func(): apply(model.open_passage("outer")))
	button(discovery_row, "inner", "内矿道：用 8 份", func(): apply(model.open_passage("inner")))
	guide_overview.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	discovery_content.add_child(guide_overview)
	device_summary.compact = false
	content.add_child(device_summary)
	content.add_child(inventory)
	content.add_child(recipe_row)
	recipe.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	recipe_row.add_child(recipe)
	button(recipe_row, "recipe", "切换配方", func():
		if recipe.selected >= 0:
			apply(model.change_recipe(selected, recipe_ids[recipe.selected])))
	button(recipe_row, "cancel_batch", "取消在制并返料", func(): apply(model.cancel_batch(selected)))
	for item in Rules.ITEMS:
		var row := HBoxContainer.new()
		content.add_child(row)
		rows[item] = row
		var label := Label.new()
		label.text = Rules.NAMES[item]
		label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		row.add_child(label)
		item_labels[item] = label
		for option in [["take_one", "取 1", false, false], ["take_all", "取全部", false, true], ["put_one", "放 1", true, false], ["put_all", "放全部", true, true]]:
			button(row, item + "_" + option[0], option[1], func(): apply(model.transfer(selected, item, option[2], option[3])))
	result_label.custom_minimum_size = Vector2(740, 40)
	layout.add_child(result_label)


func button(parent: Node, id: String, text: String, callback: Callable) -> void:
	var control := Button.new()
	control.text = text
	control.pressed.connect(callback)
	parent.add_child(control)
	buttons[id] = control


func show_for(world: RefCounted, id: int) -> void:
	_open(world, id, false)


func show_device(world: RefCounted, id: int) -> void:
	_open(world, id, true)


func _open(world: RefCounted, id: int, only_device: bool) -> void:
	model = world
	selected = id
	device_only = only_device
	discovery_content.visible = not device_only
	var e: Dictionary = model.by_id(selected)
	title = "%s #%d · 设备操作" % [Rules.CATALOG[e.type].name, e.id] if device_only and not e.is_empty() else "工艺、物料与矿道"
	result_label.text = "操作期间生产暂停；关闭后恢复原暂停状态。全部 = 当前可转移数量。"
	result_label.remove_theme_color_override("font_color")
	scroll.scroll_vertical = 0
	refresh()
	popup_centered(Vector2i(780, 660))


func apply(result: Dictionary) -> void:
	result_label.text = ("已转移 %d 件。" % result.amount if result.has("amount") else "操作完成。") if result.ok else result.reason
	result_label.add_theme_color_override("font_color", Color("77d8c6" if result.ok else "efab86"))
	refresh()


func refresh() -> void:
	var d: Dictionary = model.discovery
	guide_overview.text = Guidance.overview(model)
	var stage := "前往外矿道 (2, 2) 调查碎片。" if not d.surveyed else "拾样后用 1 样本 + 2 催化剂试制；需要接电。" if not d.trial_completed else "解壳剂可永久处理矿壳；富集晶体一批产 3 件催化剂。"
	summary.text = "%s\n外矿道：%s　内矿道：%s\n背包 %d / 200：%s" % [stage, "已打通" if d.passages.outer else "未打通", "已打通" if d.passages.inner else "未打通", Items.count(model.bag), Items.describe(model.bag)]
	buttons.sample.disabled = d.sample_taken
	buttons.outer.disabled = d.passages.outer
	buttons.inner.disabled = d.passages.inner
	var e: Dictionary = model.by_id(selected)
	device_summary.refresh(model, e)
	inventory.text = "先在场景选中设备，可查看并按物品取放。"
	if not e.is_empty():
		inventory.text = "%s\n背包 %d / 200：%s" % ["近身可操作" if model.near_entity(e) else "远程查看：请关闭面板，走到设备两格内且位于同一可达区域。", Items.count(model.bag), Items.describe(model.bag)]
	recipe_row.visible = e.get("type", "") == "reactor"
	recipe.clear()
	recipe_ids.clear()
	for id in Rules.RECIPES:
		if model.recipe_available(id):
			recipe_ids.append(id)
			var r: Dictionary = Rules.RECIPES[id]
			recipe.add_item("%s · %.0fs / %.0fkW" % [r.name, r.seconds, r.kw])
			if e.get("recipe_id", "") == id:
				recipe.select(recipe_ids.size() - 1)
	for item in rows:
		rows[item].visible = e.get("type", "") in ["collector", "reactor", "storage"] and (item in ["crystal", "catalyst"] or (item == "crust_sample" and d.sample_taken) or d.trial_completed)
		if rows[item].visible:
			var contents := Items.contents(e)
			# In-process inputs cannot be taken directly; cancellation returns the full batch.
			var stored := int(contents.get(item, 0)) - int(e.get("invested", {}).get(item, 0))
			item_labels[item].text = "%s · 设备 %d / 背包 %d" % [Rules.NAMES[item], stored, int(model.bag.get(item, 0))]
		for action in ["take_one", "take_all", "put_one", "put_all"]:
			buttons[item + "_" + action].disabled = not model.near_entity(e)
			buttons[item + "_" + action].tooltip_text = "需位于设备两格内且同一可达区域" if not model.near_entity(e) else "由当前库存、配方与容量决定实际数量"
	buttons.recipe.disabled = not model.near_entity(e)
	buttons.cancel_batch.disabled = not model.near_entity(e) or not e.get("processing", false)
