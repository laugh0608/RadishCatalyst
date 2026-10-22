extends "res://scripts/factory/save/codec_v1.gd"

const Routing := preload("res://scripts/factory/save/routing_validator.gd")
const Admission := preload("res://scripts/factory/admission.gd")


static func validate(e: Dictionary, next_id: int, next_batch: int) -> Dictionary:
	if not fields(e, ["id", "type", "x", "z", "dir", "cargo", "progress", "entry", "batch", "filter_item", "quota_mode", "quota_limit", "quota_used", "accepting"]):
		return failure("准入口字段无效。")
	if not integer(e.id, 1, next_id - 1) or not integer(e.x, -32, 31) or not integer(e.z, -32, 31) or not integer(e.dir, 0, 3):
		return failure("准入口身份或方向无效。")
	var cargo := Routing.validate_cargo(e, next_batch, [2])
	if not cargo.ok: return cargo
	if not e.filter_item is String or e.filter_item not in [""] + Admission.ALLOWED_ITEMS or e.quota_mode not in ["unlimited", "quota"] or not e.accepting is bool:
		return failure("准入口物品、模式或接收开关无效。")
	if not integer(e.quota_limit, 0, Admission.MAX_QUOTA) or not integer(e.quota_used, 0, e.quota_limit):
		return failure("准入口配额无效或超额。")
	if e.filter_item.is_empty() and (not e.cargo.is_empty() or e.quota_mode != "unlimited" or e.accepting):
		return failure("未配置准入口必须为空槽、不限量且停止接收。")
	if e.quota_mode == "unlimited" and (e.quota_limit != 0 or e.quota_used != 0):
		return failure("不限量准入口不能含配额计数。")
	if e.quota_mode == "quota" and (e.quota_limit < 1 or e.quota_used + (0 if e.cargo.is_empty() else 1) > e.quota_limit):
		return failure("准入口在途物料超过剩余额度。")
	if not e.cargo.is_empty() and e.cargo != e.filter_item:
		return failure("准入口持货不符合白名单。")
	return {"ok": true}
