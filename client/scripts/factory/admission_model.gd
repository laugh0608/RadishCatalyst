extends "res://scripts/factory/routing_model.gd"

const Admission := preload("res://scripts/factory/admission.gd")


func _init() -> void:
	super()
	supply_id = DiscoveryRules.ADMISSION_SUPPLY_ID
	kits = DiscoveryRules.admission_supply()


func place(type: String, cell: Vector2i, dir := 0, player: Variant = null) -> Dictionary:
	var result := super.place(type, cell, dir, player)
	if result.ok and type == "admission_gate":
		var e: Dictionary = result.entity
		e.dir = dir
		e.merge({"cargo": "", "progress": 0.0, "entry": -DIRS[dir], "batch": 0})
		e.merge(Admission.defaults())
		_refresh_neighbors(e)
	return result


func rotate(id: int) -> Dictionary:
	var e := by_id(id)
	if e.get("type", "") != "admission_gate": return super.rotate(id)
	if not e.cargo.is_empty(): return failure("准入口中有货物；请停止接收并等待排空，或无损回收")
	e.dir = (e.dir + 1) % 4
	e.entry = -DIRS[e.dir]
	_refresh_neighbors(e)
	revision += 1
	return success()


func _admission_target(id: int) -> Dictionary:
	var e := by_id(id)
	if e.get("type", "") != "admission_gate": return failure("准入口不存在")
	if not near_entity(e): return failure("请走到准入口两格内操作")
	return success({"entity": e})


func configure_admission(id: int, item: Variant, mode: Variant, limit: Variant) -> Dictionary:
	var target := _admission_target(id)
	if not target.ok: return target
	if item not in Admission.ALLOWED_ITEMS or mode not in ["unlimited", "quota"]:
		return failure("请选择有效允许物品与数量模式，样本不能自动运输")
	if not limit is int or (mode == "unlimited" and limit != 0) or (mode == "quota" and (limit < 1 or limit > Admission.MAX_QUOTA)):
		return failure("本轮配额须为 1–1,000,000 的整数；不限量不设置配额")
	var e: Dictionary = target.entity
	if not e.cargo.is_empty(): return failure("准入口持货时不能改配置；请停止接收并等待排空")
	if e.filter_item == item and e.quota_mode == mode and e.quota_limit == limit:
		return success({"message": "设置没有变化，本轮计数保留。"})
	e.filter_item = item
	e.quota_mode = mode
	e.quota_limit = limit
	e.quota_used = 0
	revision += 1
	return success({"message": "设置已应用，本轮计数重置；接收开关保持。"})


func set_admission_accepting(id: int, enabled: Variant) -> Dictionary:
	var target := _admission_target(id)
	if not target.ok: return target
	if not enabled is bool: return failure("接收开关必须是布尔值")
	var e: Dictionary = target.entity
	if enabled and e.filter_item.is_empty(): return failure("先选择允许物品并应用设置")
	if e.accepting != enabled:
		e.accepting = enabled
		revision += 1
	return success({"message": "已允许新来料，计数保留。" if enabled else "已停止接收，槽内货物继续排空；计数保留。"})


func reset_admission(id: int) -> Dictionary:
	var target := _admission_target(id)
	if not target.ok: return target
	var e: Dictionary = target.entity
	if e.filter_item.is_empty() or e.quota_mode != "quota": return failure("只有已配置的本轮总配额可以重置")
	if not e.cargo.is_empty(): return failure("准入口持货时不能重置；请等待排空")
	if e.quota_used != 0:
		e.quota_used = 0
		revision += 1
	return success({"message": "本轮计数已重置，物品、限额与接收开关保持。"})
