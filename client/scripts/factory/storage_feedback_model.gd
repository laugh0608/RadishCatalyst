extends "res://scripts/factory/timed_dispatch_model.gd"

const Feedback := preload("res://data/factory/storage_feedback_rules.gd")


func _init() -> void:
	super()
	supply_id = Feedback.SUPPLY_ID
	research_nodes = research_nodes.merged({Feedback.RESEARCH: Feedback.NODE})


func place(type: String, cell: Vector2i, dir := -1, player: Variant = null) -> Dictionary:
	var result := super.place(type, cell, dir, player)
	if result.ok and type == Dispatch.TYPE:
		result.entity.feedback = Feedback.defaults()
	return result


func configure_dispatch(id: int, item: Variant, period_s: Variant, window_s: Variant, quota: Variant) -> Dictionary:
	var e := by_id(id)
	if e.get("type", "") == Dispatch.TYPE and e.feedback.mode == "storage" and item != Energy.CELL:
		return failure("请先退出储能反馈，再更改允许物品")
	return super.configure_dispatch(id, item, period_s, window_s, quota)


func configure_storage_feedback(id: int, source_id: Variant, low_j: Variant, high_j: Variant) -> Dictionary:
	var e := by_id(id)
	if e.get("type", "") != Dispatch.TYPE or not near_entity(e):
		return failure("请走到节拍器两格内设置")
	if not researched.has(Feedback.RESEARCH):
		return failure("请先在核心 III 完成储能反馈研究")
	if e.filter_item != Energy.CELL:
		return failure("请先将节拍器允许物品设为工业电芯")
	if not source_id is int or source_id <= 0:
		return failure("请选择同网储能")
	if not Feedback.valid_thresholds(low_j, high_j):
		return failure("阈值须为 0–3600 的整数 kJ，低值严格小于高值")
	var binding := storage_feedback_binding(e, source_id)
	if not binding.ok:
		return binding
	var f: Dictionary = e.feedback
	if f.mode == "storage" and f.source_id == source_id and f.low_j == low_j and f.high_j == high_j:
		return success({"message": "配置相同，回差决定和节拍保留。"})
	e.feedback = {"mode": "storage", "source_id": source_id, "low_j": low_j, "high_j": high_j, "latch": "pending"}
	revision += 1
	return success({"message": "储能反馈已应用，下个启用且绑定有效的模拟步首次采样。"})


func exit_storage_feedback(id: int) -> Dictionary:
	var e := by_id(id)
	if e.get("type", "") != Dispatch.TYPE or not near_entity(e):
		return failure("请走到节拍器两格内操作")
	if e.feedback.mode != "timed":
		e.feedback = Feedback.defaults()
		revision += 1
	return success({"message": "已使用纯节拍；相位、已送额度与槽内货物保留。"})


func storage_feedback_binding(e: Dictionary, source_id: int) -> Dictionary:
	if source_id == 0:
		return failure("来源已移除，请重新绑定或退出反馈")
	var source := by_id(source_id)
	if source.get("type", "") != Buffer.TYPE:
		return failure("储能来源不存在")
	var output: Dictionary = Logistics.ports(self, e, "output")[0]
	var connection := Logistics.output_connection(self, output)
	if not connection.ok or connection.target.type != Energy.GENERATOR:
		return failure("节拍器出口须直连发电机入料口")
	if not source.enabled:
		return failure("绑定储能已停用")
	grid.rebuild(self)
	var network: int = grid.membership.get(source.power_node_id, -1)
	if network < 0:
		return failure("绑定储能未接网")
	if network != grid.membership.get(connection.target.id, -1):
		return failure("发电机与绑定储能不在同一电网")
	return success({"source": source, "generator": connection.target})


func storage_feedback_reason(e: Dictionary) -> String:
	var f: Dictionary = e.feedback
	if f.mode == "timed":
		return ""
	var binding := storage_feedback_binding(e, f.source_id)
	if not binding.ok:
		return binding.reason
	if f.latch == "pending":
		return "储能反馈待首次采样"
	return "高电量等待 · 回差决定停止" if f.latch == "block" else ""


func _step(dt: float) -> void:
	# All decisions observe the same energy state, before super commits power.
	for e in entities:
		if e.type == Dispatch.TYPE and e.active and e.feedback.mode == "storage":
			var binding := storage_feedback_binding(e, e.feedback.source_id)
			if binding.ok:
				e.feedback.latch = Feedback.decision(e.feedback, binding.source.stored_j)
	super._step(dt)


func salvage(id: int, confirmed := false) -> Dictionary:
	var removes_source: bool = by_id(id).get("type", "") == Buffer.TYPE
	var result := super.salvage(id, confirmed)
	if result.ok and removes_source:
		for e in entities:
			if e.type == Dispatch.TYPE and e.feedback.source_id == id:
				e.feedback.source_id = 0
				e.feedback.latch = "pending"
	return result
