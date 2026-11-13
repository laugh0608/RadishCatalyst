extends "res://scripts/factory/save/codec_v1.gd"

const Loads := preload("res://data/factory/load_group_rules.gd")


static func validate(e: Dictionary, model: RefCounted, next_id: int) -> Dictionary:
	var g: Variant = e.get("load_group")
	if not fields(g, ["enabled", "member_ids", "reserve_j", "latch", "evaluation_ticks_left"]):
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
	return {"ok": true}
