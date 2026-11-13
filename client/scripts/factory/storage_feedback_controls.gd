extends VBoxContainer

signal applied(result: Dictionary)

const Feedback := preload("res://data/factory/storage_feedback_rules.gd")
var model: RefCounted
var selected := -1
var config_key := ""
var source := OptionButton.new()
var low := SpinBox.new()
var high := SpinBox.new()
var apply_button := Button.new()
var exit_button := Button.new()
var status := Label.new()
var source_ids: Array[int] = []


func _ready() -> void:
	add_theme_constant_override("separation", 8)
	var title := Label.new()
	title.text = "储能反馈"
	title.add_theme_font_size_override("font_size", 18)
	add_child(title)
	status.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	add_child(status)
	source.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	source.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
	add_child(source)
	source.item_selected.connect(func(_index): _candidate())
	var row := HBoxContainer.new()
	add_child(row)
	for pair in [["低值（kJ）", low], ["高值（kJ）", high]]:
		var label := Label.new()
		label.text = pair[0]
		row.add_child(label)
		var field: SpinBox = pair[1]
		field.min_value = 0
		field.max_value = Feedback.Storage.CAPACITY_J / Feedback.PRECISION_J
		field.step = 1
		field.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		row.add_child(field)
		field.value_changed.connect(func(_value): _candidate())
	var actions := HFlowContainer.new()
	add_child(actions)
	apply_button.text = "应用储能反馈"
	exit_button.text = "退出反馈，使用纯节拍"
	actions.add_child(apply_button)
	actions.add_child(exit_button)
	apply_button.pressed.connect(func(): applied.emit(model.configure_storage_feedback(selected, _source_id(), int(low.value) * 1000, int(high.value) * 1000)))
	exit_button.pressed.connect(func(): applied.emit(model.exit_storage_feedback(selected)))
	var hint := Label.new()
	hint.text = "低电量允许、高电量停止，中间保持上次决定。仍须等节拍开窗；发电机缓存与正在燃烧的电芯照常使用。"
	hint.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	hint.add_theme_font_size_override("font_size", 13)
	add_child(hint)
	hide()


func _source_id() -> int:
	return source_ids[source.selected] if source.selected >= 0 and source.selected < source_ids.size() else 0


func refresh(world: RefCounted, e: Dictionary) -> void:
	model = world
	selected = e.id
	var f: Dictionary = e.feedback
	var key := str([e.id, f.mode, f.source_id, f.low_j, f.high_j])
	var desired: int = f.source_id if key != config_key else _source_id()
	if key != config_key:
		config_key = key
		low.set_value_no_signal(f.low_j / 1000)
		high.set_value_no_signal(f.high_j / 1000)
	source.clear()
	source_ids.clear()
	source.add_item("选择与直连发电机同网的储能")
	source_ids.append(0)
	for entity in model.entities:
		if entity.type == Feedback.Storage.TYPE and model.storage_feedback_binding(e, entity.id).ok:
			source.add_item("储能 #%d · (%d, %d) · %.3f kJ" % [entity.id, entity.x, entity.z, entity.stored_j / 1000.0])
			source_ids.append(entity.id)
	source.select(maxi(0, source_ids.find(desired)))
	status.text = "纯节拍模式"
	if f.mode == "storage":
		var current: Dictionary = model.by_id(f.source_id)
		var reading := "来源已移除" if current.is_empty() else "储能 #%d · 当前 %.3f kJ" % [current.id, current.stored_j / 1000.0]
		var decision: String = {"pending": "待首次采样", "allow": "允许", "block": "停止"}[f.latch]
		status.text = "%s · 已设低 / 高值 %d / %d kJ\n上次采样决定：%s" % [reading, f.low_j / 1000, f.high_j / 1000, decision]
		var reason: String = model.storage_feedback_reason(e)
		if not reason.is_empty():
			status.text += " · " + reason
	if not model.researched.has(Feedback.RESEARCH):
		status.text += " · 请先在核心 III 研究储能反馈"
	elif e.filter_item != "industrial_cell":
		status.text += " · 请先配置工业电芯节拍"
	exit_button.visible = f.mode == "storage"
	_candidate()


func _candidate() -> void:
	if model == null:
		return
	var e: Dictionary = model.by_id(selected)
	apply_button.disabled = e.is_empty() or not model.researched.has(Feedback.RESEARCH) or e.filter_item != "industrial_cell" \
		or _source_id() == 0 or low.value >= high.value
