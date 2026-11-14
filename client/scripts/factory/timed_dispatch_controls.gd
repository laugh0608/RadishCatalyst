extends VBoxContainer

signal applied(result: Dictionary)

const Dispatch := preload("res://data/factory/timed_dispatch_rules.gd")
const Items := preload("res://scripts/factory/items.gd")

var model: RefCounted
var selected := -1
var config_key := ""
var allowed: Array = []
var item := OptionButton.new()
var period := SpinBox.new()
var window := SpinBox.new()
var quota := SpinBox.new()
var apply_button := Button.new()
var toggle_button := Button.new()
var hint := Label.new()


func _ready() -> void:
	add_theme_constant_override("separation", 8)
	var item_row := HBoxContainer.new()
	add_child(item_row)
	var caption := Label.new()
	caption.text = "允许物品"
	item_row.add_child(caption)
	item.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	item_row.add_child(item)
	var grid := GridContainer.new()
	grid.columns = 3
	add_child(grid)
	for name in ["周期（秒）", "放行窗口（秒）", "每周期额度（件）"]:
		var label := Label.new()
		label.text = name
		grid.add_child(label)
	for field in [period, window, quota]:
		field.min_value = 1
		field.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		grid.add_child(field)
		field.value_changed.connect(func(_value): _candidate())
	period.min_value = Dispatch.MIN_PERIOD_S
	period.max_value = Dispatch.MAX_PERIOD_S
	item.item_selected.connect(func(_index): _candidate())
	var buttons := HBoxContainer.new()
	add_child(buttons)
	apply_button.text = "应用节拍设置"
	buttons.add_child(apply_button)
	buttons.add_child(toggle_button)
	apply_button.pressed.connect(func(): applied.emit(model.configure_dispatch(selected, _item(), int(period.value), int(window.value), int(quota.value))))
	toggle_button.pressed.connect(func(): applied.emit(model.set_dispatch_active(selected, not model.by_id(selected).active)))
	hint.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	hint.add_theme_font_size_override("font_size", 13)
	add_child(hint)
	hide()


func _item() -> String:
	return allowed[item.selected - 1] if item.selected > 0 else ""


func refresh(world: RefCounted, e: Dictionary) -> void:
	model = world
	selected = e.id
	var choices: Array = model.admission_items.filter(func(id): return model.item_known(id))
	if allowed != choices or item.item_count == 0:
		allowed = choices
		item.clear()
		item.add_item("选择允许物品")
		for id in allowed:
			item.add_item(Items.NAMES[id])
		config_key = ""
	var key := str([e.id, e.filter_item, e.period_s, e.window_s, e.quota])
	if key != config_key:
		config_key = key
		item.select(allowed.find(e.filter_item) + 1)
		period.set_value_no_signal(e.period_s if e.period_s > 0 else 120)
		window.set_max(period.value)
		window.set_value_no_signal(e.window_s if e.window_s > 0 else 10)
		quota.set_max(Dispatch.quota_limit(int(window.value)))
		quota.set_value_no_signal(maxi(1, e.quota))
	toggle_button.text = "停用节拍" if e.active else "启用节拍"
	toggle_button.disabled = e.filter_item.is_empty()
	_candidate()


func _candidate() -> void:
	window.set_max(period.value)
	quota.set_max(Dispatch.quota_limit(int(window.value)))
	if model == null:
		return
	var e: Dictionary = model.by_id(selected)
	if e.is_empty():
		return
	apply_button.disabled = _item().is_empty() or not e.cargo.is_empty()
	hint.text = "持货时保留当前配置。启用后等货物送出，或回收设备并取回货物。" if not e.cargo.is_empty() else "该窗口最多放行 %d 件。更改设置后，相位和已送数量归零。" % int(quota.max_value)
