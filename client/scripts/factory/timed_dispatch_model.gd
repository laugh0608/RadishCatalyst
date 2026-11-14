extends "res://scripts/factory/grid_storage_model.gd"

const Dispatch := Integrated.Timed


func _init() -> void:
	super()
	supply_id = Dispatch.SUPPLY_ID
	research_nodes = research_nodes.merged({Dispatch.TYPE: Dispatch.NODE})
	kits[Dispatch.TYPE] = 0
	assembly_costs[Dispatch.TYPE] = Dispatch.ASSEMBLY_PACKS
	assembly_counts[Dispatch.TYPE] = 0


func place(type: String, cell: Vector2i, dir := -1, player: Variant = null) -> Dictionary:
	dir = placement_direction(type, cell, dir)
	var result := super.place(type, cell, dir, player)
	if result.ok and type == Dispatch.TYPE:
		var e: Dictionary = result.entity
		e.merge({"cargo": "", "progress": 0.0, "entry": -DIRS[dir], "batch": 0,
			"filter_item": "", "period_s": 0, "window_s": 0, "quota": 0,
			"active": false, "phase_ticks": 0, "sent": 0})
		_refresh_neighbors(e)
	return result


func rotate(id: int) -> Dictionary:
	var e := by_id(id)
	if e.get("type", "") != Dispatch.TYPE:
		return super.rotate(id)
	if not e.cargo.is_empty():
		return failure("节拍器持货期间请先等待送出或回收")
	e.dir = (e.dir + 1) % 4
	e.entry = -DIRS[e.dir]
	_refresh_neighbors(e)
	revision += 1
	return success()


func configure_dispatch(id: int, item: Variant, period_s: Variant, window_s: Variant, quota: Variant) -> Dictionary:
	var e := by_id(id)
	if e.get("type", "") != Dispatch.TYPE or not near_entity(e):
		return failure("请走到节拍器两格内设置")
	if not item is String or item not in admission_items or not item_known(item):
		return failure("请选择已掌握的允许物品，样本不能自动运输")
	if not period_s is int or period_s < Dispatch.MIN_PERIOD_S or period_s > Dispatch.MAX_PERIOD_S:
		return failure("周期须为 5–600 的整数秒")
	if not window_s is int or window_s < 1 or window_s > period_s:
		return failure("放行窗口须为 1 秒至周期长度")
	if not quota is int or quota < 1 or quota > Dispatch.quota_limit(window_s):
		return failure("该窗口可设置 1–%d 件" % Dispatch.quota_limit(window_s))
	if e.filter_item == item and e.period_s == period_s and e.window_s == window_s and e.quota == quota:
		return success({"message": "配置相同，节拍和已送计数保留。"})
	if not e.cargo.is_empty():
		return failure("持货时不能更改设置；可继续放行，或回收设备和货物")
	e.merge({"filter_item": item, "period_s": period_s, "window_s": window_s, "quota": quota,
		"phase_ticks": 0, "sent": 0}, true)
	revision += 1
	return success({"message": "设置已应用，下个模拟步从新周期开始。"})


func set_dispatch_active(id: int, active: bool) -> Dictionary:
	var e := by_id(id)
	if e.get("type", "") != Dispatch.TYPE or not near_entity(e):
		return failure("请走到节拍器两格内操作")
	if active and e.filter_item.is_empty():
		return failure("先应用节拍设置")
	if e.active != active:
		e.active = active
		revision += 1
	return success({"message": "节拍已启用，按当前相位运行。" if active else "节拍已停用，保留相位、计数和槽内货物。"})


func _logistics(dt: float) -> void:
	super._logistics(dt)
	for e in entities:
		if e.type == Dispatch.TYPE and e.active:
			e.phase_ticks += 1
			if e.phase_ticks == e.period_s * Dispatch.TICKS_PER_SECOND:
				e.phase_ticks = 0
				e.sent = 0
