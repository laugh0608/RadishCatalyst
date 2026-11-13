extends "res://scripts/factory/storage_feedback_model.gd"

const Loads := preload("res://data/factory/load_group_rules.gd")


func _init() -> void:
	super()
	supply_id = Loads.SUPPLY_ID
	research_nodes = research_nodes.merged({Loads.RESEARCH: Loads.NODE})


func place(type: String, cell: Vector2i, dir := -1, player: Variant = null) -> Dictionary:
	var result := super.place(type, cell, dir, player)
	if result.ok and type == Buffer.TYPE:
		result.entity.load_group = Loads.defaults()
	return result


func load_group_owner(member_id: int) -> Dictionary:
	for e in entities:
		if e.type == Buffer.TYPE and member_id in e.load_group.member_ids:
			return e
	return {}


func load_network(e: Dictionary) -> int:
	grid.rebuild(self)
	return grid.membership.get(e.get("power_node_id", e.id), -1)


func load_group_binding(source: Dictionary) -> Dictionary:
	if not source.enabled:
		return failure("组所在储能已停用")
	var network := load_network(source)
	if network < 0:
		return failure("组所在储能未接网")
	for other in entities:
		if other.type == Buffer.TYPE and other.id != source.id and other.load_group.enabled and load_network(other) == network:
			return failure("合网冲突：储能 #%d 的负载组也已启用，请关闭一组或分网" % other.id)
	for id in source.load_group.member_ids:
		if load_network(by_id(id)) != network:
			return failure("成员 #%d 与储能不在同一电网，整组暂停新批" % id)
	return success()


func _load_source(id: int) -> Dictionary:
	var e := by_id(id)
	if e.get("type", "") != Buffer.TYPE or not near_entity(e):
		return failure("请走到所属储能两格内操作负载组")
	if not researched.has(Loads.RESEARCH):
		return failure("请先在核心 III 研究负载管理")
	return success({"entity": e})


func configure_load_group(id: int, members: Variant, reserve_j: Variant) -> Dictionary:
	var found := _load_source(id)
	if not found.ok:
		return found
	var e: Dictionary = found.entity
	if not members is Array or members.is_empty() or members.size() > Loads.MAX_MEMBERS or not Loads.valid_reserve(reserve_j):
		return failure("请选择 1–8 台设备；保留量须为 0–3600 的整数 kJ")
	var network := load_network(e)
	if network < 0:
		return failure("请先将储能接入电网")
	var ids: Array[int] = []
	for member in members:
		if not member is int or member in ids or not Loads.eligible(by_id(member)):
			return failure("成员重复或无效；只允许精炼炉和非电芯配方组装机")
		var owner := load_group_owner(member)
		if (not owner.is_empty() and owner.id != id) or load_network(by_id(member)) != network:
			return failure("成员已属于其他组，或不在同一电网")
		ids.append(member)
	ids.sort()
	var g: Dictionary = e.load_group
	if g.enabled:
		# Validate the proposed members without mutating the authoritative group.
		var proposed := e.duplicate(true)
		proposed.load_group.member_ids = ids
		var binding := load_group_binding(proposed)
		if not binding.ok:
			return binding
	if g.member_ids == ids and g.reserve_j == reserve_j:
		return success({"message": "配置相同，决定和评估节奏保留。"})
	g.member_ids = ids
	g.reserve_j = reserve_j
	_reset_load_group(g)
	revision += 1
	return success({"message": "负载组已应用。" + ("下步重新评估。" if g.enabled else "启用后开始控制。")})


func set_load_group_enabled(id: int, enabled: bool) -> Dictionary:
	var found := _load_source(id)
	if not found.ok:
		return found
	var e: Dictionary = found.entity
	var g: Dictionary = e.load_group
	if enabled:
		if g.member_ids.is_empty():
			return failure("请先配置负载组成员")
		var binding := load_group_binding(e)
		if not binding.ok:
			return binding
	if g.enabled != enabled:
		g.enabled = enabled
		_reset_load_group(g)
		revision += 1
	return success({"message": "负载组已启用，下步评估。" if enabled else "已关闭控制，保留本机启停与组配置。"})


func remove_load_member(id: int, member_id: int) -> Dictionary:
	var found := _load_source(id)
	if not found.ok:
		return found
	var g: Dictionary = found.entity.load_group
	if member_id not in g.member_ids:
		return failure("该设备不在此负载组")
	_remove_member(g, member_id)
	revision += 1
	return success({"message": "已移除成员；本机启停和在制保留。"})


func clear_load_group(id: int) -> Dictionary:
	var found := _load_source(id)
	if not found.ok:
		return found
	var g: Dictionary = found.entity.load_group
	g.member_ids.clear()
	g.enabled = false
	_reset_load_group(g)
	revision += 1
	return success({"message": "已清空并关闭负载组。"})


func _reset_load_group(g: Dictionary) -> void:
	g.latch = "pending"
	g.evaluation_ticks_left = 0


func _remove_member(g: Dictionary, id: int) -> void:
	g.member_ids.erase(id)
	if g.member_ids.is_empty():
		g.enabled = false
	_reset_load_group(g)


func uncontrolled_work_spec(e: Dictionary) -> Dictionary:
	return super.work_spec(e)


func load_group_budget(source: Dictionary) -> Dictionary:
	var binding := load_group_binding(source)
	if not binding.ok:
		return binding
	var g: Dictionary = source.load_group
	var candidates: Array[int] = []
	var horizon := 0
	for id in g.member_ids:
		var e := by_id(id)
		var spec := uncontrolled_work_spec(e)
		if not e.processing and spec.ready:
			candidates.append(id)
			horizon = maxi(horizon, ceili(spec.seconds / STEP))
	if candidates.is_empty():
		return failure("暂无可开工批次")
	var network := load_network(source)
	var demand_w := 0
	for e in entities:
		if not DiscoveryRules.POWER.has(e.type) or load_network(e) != network:
			continue
		var spec := uncontrolled_work_spec(e)
		demand_w += roundi((spec.kw if spec.ready else spec.standby_kw) * 1000)
	var power_group: Dictionary = grid.groups[network]
	var supply_w := roundi(power_group.base_capacity_kw * 1000)
	for id in power_group.generators:
		if by_id(id).burn_remaining_ticks >= horizon:
			supply_w += roundi(Energy.GENERATOR_KW * 1000)
	var buffer_w := Loads.buffer_w(source.stored_j, g.reserve_j, horizon)
	supply_w += buffer_w
	return success({"horizon_ticks": horizon, "candidate_ids": candidates, "demand_w": demand_w,
		"supply_w": supply_w, "buffer_w": buffer_w, "margin_w": supply_w - demand_w})


func load_group_reason(source: Dictionary) -> String:
	if not source.load_group.enabled:
		return ""
	var binding := load_group_binding(source)
	if not binding.ok:
		return binding.reason
	match source.load_group.latch:
		"pending": return "负载组待评估 · 暂停新批"
		"block": return "负载组等待功率余量 · 暂停新批"
	return ""


func work_spec(e: Dictionary) -> Dictionary:
	var spec := super.work_spec(e)
	if Loads.eligible(e) and not e.processing:
		var owner := load_group_owner(e.id)
		if not owner.is_empty() and not load_group_reason(owner).is_empty():
			spec.ready = false
	return spec


func _step(dt: float) -> void:
	var decisions := {}
	for e in entities:
		if e.type != Buffer.TYPE or not e.load_group.enabled or e.load_group.evaluation_ticks_left != 0:
			continue
		var budget := load_group_budget(e)
		if budget.ok:
			decisions[e.id] = Loads.decision(e.load_group.latch, budget.margin_w)
	for e in entities:
		if e.type == Buffer.TYPE and e.load_group.enabled:
			var g: Dictionary = e.load_group
			g.evaluation_ticks_left = Loads.INTERVAL - 1 if g.evaluation_ticks_left == 0 else g.evaluation_ticks_left - 1
			if decisions.has(e.id):
				g.latch = decisions[e.id]
	super._step(dt)


func change_recipe(id: int, recipe_id: String) -> Dictionary:
	var owner := load_group_owner(id)
	var result := super.change_recipe(id, recipe_id)
	if result.ok and not owner.is_empty():
		if recipe_id == Loads.EXCLUDED_RECIPE:
			_remove_member(owner.load_group, id)
		else:
			_reset_load_group(owner.load_group)
	return result


func salvage(id: int, confirmed := false) -> Dictionary:
	var e := by_id(id)
	var owner := load_group_owner(id)
	if e.get("type", "") == Buffer.TYPE and not e.load_group.member_ids.is_empty() and not confirmed:
		if not near_entity(e):
			return failure("请走到储能设施两格内回收")
		if e.enabled and e.stored_j > 0:
			return failure("请先停用储能，锁定回收时将损失的电量")
		return failure("回收将解除负载组控制，并损失 %.3f kJ 电量；成员下步恢复普通开工，本机停机保留。" % (e.stored_j / 1000.0)).merged({"needs_confirmation": true})
	var result := super.salvage(id, confirmed)
	if result.ok and not owner.is_empty():
		_remove_member(owner.load_group, id)
	return result


func feedback(e: Dictionary) -> Dictionary:
	var result := super.feedback(e)
	if Loads.eligible(e):
		var owner := load_group_owner(e.id)
		if not owner.is_empty():
			var state := "本机停机" if not e.enabled else "在制继续" if e.processing else load_group_reason(owner)
			if not state.is_empty():
				result.label = state + " · 储能 #%d 负载组" % owner.id
				result.kind = "running" if e.enabled and e.processing else "waiting"
	return result
