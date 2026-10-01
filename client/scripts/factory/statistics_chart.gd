extends Control

var points: Array = []
var power := false
var peak := 1.0
const COLORS := [Color("79d7c5"), Color("edc575"), Color("a9b8d7"), Color("ef947e")]


func _ready() -> void:
	custom_minimum_size = Vector2(230, 90)
	mouse_filter = Control.MOUSE_FILTER_STOP
	resized.connect(queue_redraw)
	mouse_exited.connect(func(): tooltip_text = "")


func show_points(value: Array, electricity := false) -> void:
	points = value
	power = electricity
	peak = 1.0
	for point in points:
		for key in (["a", "b", "c", "d"] if power else ["a", "b"]):
			peak = maxf(peak, point[key] / point.seconds * (1.0 if power else 60.0))
	queue_redraw()


func _draw() -> void:
	var font := get_theme_default_font()
	var area := Rect2(4, 22, maxf(1, size.x - 8), maxf(1, size.y - 42))
	draw_line(area.position, Vector2(area.position.x, area.end.y), Color("637974"))
	draw_line(Vector2(area.position.x, area.end.y), area.end, Color("637974"))
	draw_string(font, Vector2(4, 15), "0–%.1f %s" % [peak, "kW" if power else "件/分"], HORIZONTAL_ALIGNMENT_LEFT, -1, 12)
	if points.is_empty():
		draw_string(font, Vector2(12, 50), "暂无完整秒样本", HORIZONTAL_ALIGNMENT_LEFT, -1, 14)
		return
	var keys := ["a", "b", "c", "d"] if power else ["a", "b"]
	for k in keys.size():
		var previous := Vector2.ZERO
		for i in points.size():
			var value: float = points[i][keys[k]] / points[i].seconds * (1.0 if power else 60.0)
			var at := Vector2(area.position.x + area.size.x * i / maxi(1, points.size() - 1), area.end.y - area.size.y * value / peak)
			if i > 0:
				if k % 2 == 1:
					draw_dashed_line(previous, at, COLORS[k], 1.5, 4)
				else:
					draw_line(previous, at, COLORS[k], 1.5, true)
			else:
				draw_circle(at, 2, COLORS[k])
			previous = at
	var start: float = points[0].start
	var end: float = points.back().start + points.back().seconds
	draw_string(font, Vector2(4, size.y - 3), "%.0fs → %.0fs · 模拟时间" % [start, end], HORIZONTAL_ALIGNMENT_LEFT, -1, 12)


func _gui_input(event: InputEvent) -> void:
	if not event is InputEventMouseMotion or points.is_empty():
		return
	var index := clampi(roundi((event.position.x - 4) / maxf(1, size.x - 8) * (points.size() - 1)), 0, points.size() - 1)
	var p: Dictionary = points[index]
	if power:
		tooltip_text = "(%.0f, %.0f] 秒\n供用电 %.2f kJ / 均值 %.2f kW\n请求 %.2f kJ / 均值 %.2f kW\n装机均值 %.2f kW · 缺口均值 %.2f kW" % [p.start, p.start + p.seconds, p.a, p.a / p.seconds, p.b, p.b / p.seconds, p.c / p.seconds, p.d / p.seconds]
	else:
		tooltip_text = "(%.0f, %.0f] 秒\n生产 %d 件 / %.1f 件每分\n消耗 %d 件 / %.1f 件每分" % [p.start, p.start + p.seconds, p.a, p.a * 60 / p.seconds, p.b, p.b * 60 / p.seconds]
