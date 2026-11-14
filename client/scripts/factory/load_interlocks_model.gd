extends "res://scripts/factory/load_groups_model.gd"

const Interlocks := preload("res://data/factory/load_interlock_rules.gd")


func _init() -> void:
	super()
	supply_id = Interlocks.SUPPLY_ID


func place(type: String, cell: Vector2i, dir := -1, player: Variant = null) -> Dictionary:
	var result := super.place(type, cell, dir, player)
	if result.ok:
		if type == Buffer.TYPE:
			result.entity.load_group.interlocks = []
		elif type in process_types:
			result.entity.batch_outcome = "none"
	return result


func configure_load_group(id: int, members: Variant, reserve_j: Variant, conditions: Variant = null) -> Dictionary:
	var found := _load_source(id)
	if not found.ok:
		return found
	if not members is Array:
		return failure("负载组成员无效。")
	var owner: Dictionary = found.entity
	for member in members:
		if member is int and _interlock_source_in_use(member):
			return failure("设备 #%d 正作为开工联锁来源，请先解除引用。" % member)
	var previous: Array = owner.load_group.interlocks
	var proposed: Variant = conditions
	if proposed == null:
		proposed = previous.filter(func(rule): return rule.member_id in members)
	if not proposed is Array or proposed.size() > Loads.MAX_MEMBERS:
		return failure("开工条件列表无效。")
	var rules: Array = []
	var network := load_network(owner)
	for rule in proposed:
		if not rule is Dictionary or rule.size() != 3 or rule.get("condition") != Interlocks.CONDITION 			or not rule.get("member_id") is int or rule.member_id not in members or not rule.get("source_id") is int 			or rules.any(func(saved): return saved.member_id == rule.member_id):
			return failure("每个成员只能配置一个有效的开工条件。")
		var source := by_id(rule.source_id)
		if source.get("type") not in process_types or rule.source_id in members 			or not load_group_owner(rule.source_id).is_empty() or network < 0 or load_network(source) != network:
			return failure("请选择同网且未加入负载组的加工设备。")
		rules.append(rule.duplicate())
	rules.sort_custom(func(a, b): return a.member_id < b.member_id)
	var result := super.configure_load_group(id, members, reserve_j)
	if result.ok and rules != previous:
		owner.load_group.interlocks = rules
		_reset_load_group(owner.load_group)
		revision += 1
		return success({"message": "负载组和开工条件已应用。"})
	return result


func set_load_group_enabled(id: int, enabled: bool) -> Dictionary:
	var found := _load_source(id)
	if not found.ok:
		return found
	if enabled:
		var owner: Dictionary = found.entity
		for rule in owner.load_group.interlocks:
			if load_network(by_id(rule.source_id)) != load_network(owner):
				return failure("联锁来源 #%d 已断网，请恢复接线或修改开工条件。" % rule.source_id)
	return super.set_load_group_enabled(id, enabled)


func clear_load_group(id: int) -> Dictionary:
	var result := super.clear_load_group(id)
	if result.ok:
		by_id(id).load_group.interlocks.clear()
	return result


func _remove_member(group: Dictionary, id: int) -> void:
	super._remove_member(group, id)
	group.interlocks = group.interlocks.filter(func(rule): return rule.member_id != id)


func _interlock_source_in_use(id: int) -> bool:
	for e in entities:
		if e.type == Buffer.TYPE and e.load_group.interlocks.any(func(rule): return rule.source_id == id):
			return true
	return false


func salvage(id: int, confirmed := false) -> Dictionary:
	if _interlock_source_in_use(id) and near_entity(by_id(id)):
		return failure("设备仍是开工联锁来源，请先解除或改绑条件。")
	return super.salvage(id, confirmed)


func set_device_enabled(id: int, enabled: bool) -> Dictionary:
	var result := super.set_device_enabled(id, enabled)
	if result.ok and enabled:
		var e := by_id(id)
		if e.type in process_types:
			e.batch_outcome = "none"
	return result


func _batch_started(e: Dictionary) -> void:
	super._batch_started(e)
	e.batch_outcome = "none"


func _batch_completed(e: Dictionary) -> void:
	super._batch_completed(e)
	e.batch_outcome = "completed"


func cancel_batch(id: int) -> Dictionary:
	var result := super.cancel_batch(id)
	if result.ok:
		by_id(id).batch_outcome = "cancelled"
	return result


func start_interlock_reason(member_id: int) -> String:
	var owner := load_group_owner(member_id)
	if owner.is_empty() or not owner.load_group.enabled:
		return ""
	for rule in owner.load_group.interlocks:
		if rule.member_id != member_id:
			continue
		var source := by_id(rule.source_id)
		var network := load_network(owner)
		if source.is_empty() or network < 0 or load_network(source) != network:
			return "联锁来源 #%d 已断网" % rule.source_id
		if source.processing or source.batch_outcome != "completed":
			return "等设备 #%d 完成尾批" % source.id
		if source.enabled:
			return "设备 #%d 尾批已完成，等设备停机" % source.id
	return ""


func work_spec(e: Dictionary) -> Dictionary:
	var spec := super.work_spec(e)
	if spec.ready and Loads.eligible(e) and not e.processing and not start_interlock_reason(e.id).is_empty():
		spec.ready = false
	return spec


func feedback(e: Dictionary) -> Dictionary:
	var result := super.feedback(e)
	if Loads.eligible(e) and e.enabled and not e.processing:
		var reason := start_interlock_reason(e.id)
		if not reason.is_empty():
			result.kind = "waiting"
			result.label = reason
			result.production = reason
	return result
