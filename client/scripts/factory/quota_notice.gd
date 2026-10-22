extends PanelContainer

signal locate(id: int)

const Items := preload("res://scripts/factory/items.gd")
var title := Label.new()
var detail := Label.new()
var locate_button := Button.new()
var candidates: Array[int] = []
var next_index := 0


static func summary(model: RefCounted) -> Dictionary:
	var gates: Array = []
	var remaining := false
	for e in model.entities:
		if e.type == "admission_gate" and e.quota_mode == "quota" and not e.filter_item.is_empty() and e.quota_used >= e.quota_limit:
			gates.append(e)
		if e.get("processing", false) or not e.get("cargo", "").is_empty() or not e.get("output", {}).is_empty(): remaining = true
	gates.sort_custom(func(a, b): return a.id < b.id)
	return {"gates": gates, "remaining": remaining}


func _ready() -> void:
	var style := StyleBoxFlat.new()
	style.bg_color = Color("193334", 0.96)
	style.border_color = Color("cba966")
	style.set_border_width_all(1)
	style.set_corner_radius_all(5)
	style.content_margin_left = 12
	style.content_margin_right = 12
	style.content_margin_top = 8
	style.content_margin_bottom = 8
	add_theme_stylebox_override("panel", style)
	var stack := VBoxContainer.new()
	add_child(stack)
	title.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	title.add_theme_color_override("font_color", Color("f0c16b"))
	stack.add_child(title)
	detail.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	detail.add_theme_font_size_override("font_size", 13)
	stack.add_child(detail)
	locate_button.text = "定位已完成准入口"
	locate_button.size_flags_horizontal = Control.SIZE_SHRINK_BEGIN
	locate_button.focus_mode = Control.FOCUS_NONE
	locate_button.pressed.connect(func():
		if candidates.is_empty(): return
		locate.emit(candidates[next_index % candidates.size()])
		next_index = (next_index + 1) % candidates.size())
	stack.add_child(locate_button)
	hide()


func refresh(model: RefCounted) -> void:
	if not model.has_method("power_state"):
		hide()
		return
	var state := summary(model)
	visible = not state.gates.is_empty()
	if not visible: return
	var ids: Array[int] = []
	var lines := PackedStringArray()
	for e in state.gates:
		ids.append(e.id)
		lines.append("%s #%d：%d/%d" % [Items.NAMES[e.filter_item], e.id, e.quota_used, e.quota_limit])
	if ids != candidates: next_index = 0
	candidates = ids
	title.text = "配额完成 · %d 个准入口已停收新料\n%s" % [ids.size(), "余料仍在加工 / 输出 / 运输" if state.remaining else "当前加工与运输已空闲"]
	detail.text = " · ".join(lines.slice(0, 3)) + (" · 另 %d 个" % (lines.size() - 3) if lines.size() > 3 else "")
	detail.text += "\n继续不会重置配额；下一轮请走近准入口，点击「重置本轮」。"
	locate_button.text = "定位已完成准入口" + ("（再次点击切换）" if ids.size() > 1 else "")
