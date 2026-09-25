extends AcceptDialog

const Rules := preload("res://data/factory/discovery_rules.gd")
const Items := preload("res://scripts/factory/items.gd")
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


func _ready() -> void:
	title = "工艺、物料与矿道"
	ok_button_text = "返回工厂"
	exclusive = true
	var content := VBoxContainer.new()
	content.custom_minimum_size = Vector2(700, 0)
	content.add_theme_constant_override("separation", 10)
	add_child(content)
	for label in [summary, inventory, result_label]:
		label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		label.custom_minimum_size.x = 700
	content.add_child(summary)
	var discovery_row := HBoxContainer.new()
	content.add_child(discovery_row)
	button(discovery_row, "survey", "调查样本", func(): apply(model.survey_sample()))
	button(discovery_row, "sample", "拾取唯一样本", func(): apply(model.survey_sample(true)))
	button(discovery_row, "outer", "外矿道：用 4 份", func(): apply(model.open_passage("outer")))
	button(discovery_row, "inner", "内矿道：用 8 份", func(): apply(model.open_passage("inner")))
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
		label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		row.add_child(label)
		for option in [["take_one", "取 1", false, false], ["take_all", "取全部", false, true], ["put_one", "放 1", true, false], ["put_all", "放全部", true, true]]:
			button(row, item + "_" + option[0], option[1], func(): apply(model.transfer(selected, item, option[2], option[3])))
	content.add_child(result_label)


func button(parent: Node, id: String, text: String, callback: Callable) -> void:
	var control := Button.new()
	control.text = text
	control.pressed.connect(callback)
	parent.add_child(control)
	buttons[id] = control


func show_for(world: RefCounted, id: int) -> void:
	model = world
	selected = id
	result_label.text = "取放、切配方与取消需在设备两格内；开路需靠近西侧入口，成功永久打通。"
	refresh()
	popup_centered(Vector2i(740, 660))


func apply(result: Dictionary) -> void:
	result_label.text = ("已转移 %d 件。" % result.amount if result.has("amount") else "操作完成。") if result.ok else result.reason
	refresh()


func refresh() -> void:
	var d: Dictionary = model.discovery
	var stage := "前往外矿道 (2, 2) 调查碎片。" if not d.surveyed else "拾样后用 1 样本 + 2 催化剂试制；需要接电。" if not d.trial_completed else "解壳剂可永久处理矿壳；富集晶体一批产 3 件催化剂。"
	summary.text = "%s\n外矿道：%s　内矿道：%s\n背包 %d / 200：%s" % [stage, "已打通" if d.passages.outer else "未打通", "已打通" if d.passages.inner else "未打通", Items.count(model.bag), Items.describe(model.bag)]
	buttons.sample.disabled = d.sample_taken
	buttons.outer.disabled = d.passages.outer
	buttons.inner.disabled = d.passages.inner
	var e: Dictionary = model.by_id(selected)
	inventory.text = "先在场景选中设备，可查看并按物品取放。"
	if not e.is_empty():
		inventory.text = "%s #%d · %s\n%s" % [Rules.CATALOG[e.type].name, e.id, "近身可操作" if model.near_entity(e) else "请靠近至两格内", describe_entity(e)]
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


static func describe_entity(e: Dictionary) -> String:
	match e.type:
		"collector": return "%s缓冲：%s / 50" % [Rules.NAMES[e.mineral], Items.describe(e.buffer)]
		"reactor":
			var r: Dictionary = Rules.RECIPES[e.recipe_id]
			return "%s：%s → %s\n输入：%s\n输出：%s\n在制：%s · %.1f / %.0f 秒" % [r.name, Items.describe(r.input), Items.describe(r.output), Items.describe(e.input), Items.describe(e.output), Items.describe(e.invested), e.progress, r.seconds]
		"storage": return "仓储 %d / 200：%s" % [Items.count(e.items), Items.describe(e.items)]
		"belt": return "带上物品：%s" % Rules.NAMES.get(e.cargo, "空")
	return ""
