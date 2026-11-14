extends "res://scripts/factory/save/codec_v1.gd"

const Interlocks := preload("res://data/factory/load_interlock_rules.gd")
const Loads := preload("res://data/factory/load_group_rules.gd")


static func validate(e: Dictionary, model: RefCounted, next_id: int) -> Dictionary:
	var g: Variant = e.get("load_group")
	var interlocks: bool = model.supply_id == Interlocks.SUPPLY_ID
	if not fields(g, ["enabled", "member_ids", "reserve_j", "latch", "evaluation_ticks_left"] + (["interlocks"] if interlocks else [])):
		return failure("负载组字段无效。")
	if not g.enabled is bool or not g.member_ids is Array or g.member_ids.size() > Loads.MAX_MEMBERS:
		return failure("负载组启停或成员数量无效。")
	if not integer(g.reserve_j, 0, Loads.Storage.CAPACITY_J) or int(g.reserve_j) % Loads.PRECISION_J != 0 \
		or g.latch not in ["pending", "allow", "block"] or not integer(g.evaluation_ticks_left, 0, Loads.INTERVAL - 1):
		return failure("负载组保留量、决定或倒计时无效。")
	var previous := 0
	for id in g.member_ids:
		if not integer(id, previous + 1, next_id - 1):
			return failure("负载组成员 ID 无效、重复或未排序。")
		previous = int(id)
	if (not g.enabled and (g.latch != "pending" or g.evaluation_ticks_left != 0)) or (g.enabled and g.member_ids.is_empty()):
		return failure("关闭或空负载组的决定 / 倒计时组合无效。")
	if not model.researched.has(Loads.RESEARCH) and (g.enabled or not g.member_ids.is_empty() or g.reserve_j != Loads.RESERVE_J or g.latch != "pending" or g.evaluation_ticks_left != 0):
		return failure("未研究负载管理却有组配置。")
	if interlocks:
		if not g.interlocks is Array or g.interlocks.size() > g.member_ids.size():
			return failure("联锁列表无效。")
		previous = 0
		for rule in g.interlocks:
			if not fields(rule, ["member_id", "source_id", "condition"]) or rule.condition != Interlocks.CONDITION \
				or not integer(rule.member_id, previous + 1, next_id - 1) or rule.member_id not in g.member_ids \
				or not integer(rule.source_id, 1, next_id - 1):
				return failure("联锁条件、成员或来源 ID 无效。")
			previous = int(rule.member_id)
	return {"ok": true}


static func restore_references(model: RefCounted) -> Dictionary:
	var assigned := {}
	for e in model.entities:
		if e.type != Loads.Storage.TYPE:
			continue
		var g: Dictionary = e.load_group
		for key in ["reserve_j", "evaluation_ticks_left"]:
			g[key] = int(g[key])
		var ids: Array[int] = []
		for member in g.member_ids:
			var id := int(member)
			if assigned.has(id) or not Loads.eligible(model.by_id(id)):
				return failure("负载组成员不存在、类型 / 配方不符或重复归属。")
			assigned[id] = e.id
			ids.append(id)
		g.member_ids = ids
	if model.supply_id == Interlocks.SUPPLY_ID:
		for e in model.entities:
			if e.type != Loads.Storage.TYPE:
				continue
			for rule in e.load_group.interlocks:
				rule.member_id = int(rule.member_id)
				rule.source_id = int(rule.source_id)
				if assigned.has(rule.source_id) or model.by_id(rule.source_id).get("type") not in model.process_types:
					return failure("联锁来源不存在、类型不符或已加入负载组。")
	return {"ok": true}
