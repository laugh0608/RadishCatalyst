extends VBoxContainer

signal applied(result: Dictionary)
const Admission := preload("res://scripts/factory/admission.gd")
const Items := preload("res://scripts/factory/items.gd")
var allowed_items := Admission.ALLOWED_ITEMS.duplicate()
var model: RefCounted
var selected := -1
var config_key := ""
var item := OptionButton.new()
var mode := OptionButton.new()
var limit := SpinBox.new()
var quantity_label := Label.new()
var apply_button := Button.new()
var accepting_button := Button.new()
var reset_button := Button.new()
var hint := Label.new()


func _ready() -> void:
	add_theme_constant_override("separation", 8)
	var row := HBoxContainer.new()
	add_child(row)
	var caption := Label.new()
	caption.text = "允许物品"
	row.add_child(caption)
	item.add_item("选择允许物品")
	for id in allowed_items:
		item.add_icon_item(load("res://assets/icons/factory_" + id + ".svg"), Items.NAMES[id])
	item.add_theme_constant_override("icon_max_width", 22)
	item.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	row.add_child(item)
	mode.add_item("不限数量")
	mode.add_item("本轮总配额")
	row.add_child(mode)
	quantity_label.text = "件数"
	row.add_child(quantity_label)
	limit.min_value = 1
	limit.max_value = Admission.MAX_QUOTA
	limit.step = 1
	limit.custom_minimum_size.x = 160
	row.add_child(limit)
	var actions := HBoxContainer.new()
	add_child(actions)
	apply_button.text = "应用设置"
	accepting_button.text = "允许新来料"
	reset_button.text = "重置本轮"
	for button in [apply_button, accepting_button, reset_button]: actions.add_child(button)
	apply_button.pressed.connect(func(): applied.emit(model.configure_admission(selected, _item(), "quota" if mode.selected == 1 else "unlimited", int(limit.value) if mode.selected == 1 else 0)))
	accepting_button.pressed.connect(func(): applied.emit(model.set_admission_accepting(selected, not model.by_id(selected).get("accepting", false))))
	reset_button.pressed.connect(func(): applied.emit(model.reset_admission(selected)))
	for field in [item, mode]: field.item_selected.connect(func(_index): _candidate())
	limit.value_changed.connect(func(_value): _candidate())
	hint.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	hint.add_theme_font_size_override("font_size", 13)
	add_child(hint)
	hide()


func _item() -> String:
	return allowed_items[item.selected - 1] if item.selected > 0 else ""


func refresh(world: RefCounted, e: Dictionary) -> void:
	model = world
	if allowed_items != model.admission_items:
		allowed_items = model.admission_items.duplicate()
		item.clear()
		item.add_item("选择允许物品")
		for id in allowed_items:
			item.add_icon_item(load("res://assets/icons/factory_" + id + ".svg"), Items.NAMES[id])
		config_key = ""
	selected = e.id
	var key := str([e.id, e.filter_item, e.quota_mode, e.quota_limit])
	if key != config_key:
		config_key = key
		item.select(allowed_items.find(e.filter_item) + 1)
		mode.select(1 if e.quota_mode == "quota" else 0)
		limit.set_value_no_signal(e.quota_limit if e.quota_mode == "quota" else 1)
	accepting_button.text = "停止接收并排空" if e.accepting else "允许新来料"
	accepting_button.disabled = e.filter_item.is_empty()
	reset_button.disabled = e.filter_item.is_empty() or e.quota_mode != "quota" or not e.cargo.is_empty()
	_candidate()


func _candidate() -> void:
	quantity_label.visible = mode.selected == 1
	limit.visible = mode.selected == 1
	if model == null: return
	var e: Dictionary = model.by_id(selected)
	if e.is_empty(): return
	var changed: bool = _item() != e.filter_item or ("quota" if mode.selected == 1 else "unlimited") != e.quota_mode or (int(limit.value) if mode.selected == 1 else 0) != e.quota_limit
	apply_button.disabled = _item().is_empty() or not e.cargo.is_empty()
	hint.text = "持货期间不能改设置或重置；停止接收后等待排空。" if not e.cargo.is_empty() else "应用新设置会开始新一轮并重置计数；接收开关保持。" if changed else "当前设置保持计数；只有空载时显式重置才开始下一轮。"
