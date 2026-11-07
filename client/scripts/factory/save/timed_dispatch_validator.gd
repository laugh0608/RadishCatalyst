extends "res://scripts/factory/save/codec_v1.gd"

const Timed := preload("res://data/factory/timed_dispatch_rules.gd")
const Entity := preload("res://scripts/factory/save/expansion_entity_validator.gd")
const Routing := preload("res://scripts/factory/save/routing_validator.gd")


static func validate(e: Dictionary, next_batch: int, model: RefCounted) -> Dictionary:
	if not fields(e, ["id", "type", "x", "z", "dir", "cargo", "progress", "entry", "batch",
		"filter_item", "period_s", "window_s", "quota", "active", "phase_ticks", "sent"]):
		return failure("节拍器字段无效。")
	if not integer(e.x, -32, 31) or not integer(e.z, -32, 31) or not integer(e.dir, 0, 3) or not e.active is bool or not e.filter_item is String:
		return failure("节拍器位置、方向或启停状态无效。")
	var cargo := Routing.validate_cargo(e, next_batch, [2], model.admission_items, Entity.MINERALS, true, true)
	if not cargo.ok:
		return cargo
	if e.filter_item.is_empty():
		if e.active or not e.cargo.is_empty():
			return failure("未设置的节拍器不能启用或持货。")
		for key in ["period_s", "window_s", "quota", "phase_ticks", "sent"]:
			if not integer(e[key], 0, 0):
				return failure("未设置的节拍器不能有节拍状态。")
		return {"ok": true}
	if e.filter_item not in model.admission_items or not model.item_known(e.filter_item) or (not e.cargo.is_empty() and e.cargo != e.filter_item):
		return failure("节拍器允许物品未掌握，或槽内货物不符。")
	if not integer(e.period_s, Timed.MIN_PERIOD_S, Timed.MAX_PERIOD_S) or not integer(e.window_s, 1, int(e.period_s)):
		return failure("节拍器周期或放行窗口无效。")
	var window_ticks := int(e.window_s) * Timed.TICKS_PER_SECOND
	if not integer(e.quota, 1, Timed.quota_limit(int(e.window_s))) or not integer(e.phase_ticks, 0, int(e.period_s) * Timed.TICKS_PER_SECOND - 1):
		return failure("节拍器额度或周期相位无效。")
	if not integer(e.sent, 0, mini(int(e.quota), Timed.departure_limit(mini(window_ticks, int(e.phase_ticks))))):
		return failure("节拍器计数超过额度或可放行步数。")
	return {"ok": true}
