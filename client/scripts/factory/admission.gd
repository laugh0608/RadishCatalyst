extends RefCounted

const Rules := preload("res://data/factory/discovery_rules.gd")
const ALLOWED_ITEMS := ["crystal", "catalyst", "crust_solvent", "rich_crystal"]
const MAX_QUOTA := 1000000


static func defaults() -> Dictionary:
	return {"filter_item": "", "quota_mode": "unlimited", "quota_limit": 0, "quota_used": 0, "accepting": false}


static func receive_reason(e: Dictionary, item: String) -> String:
	if e.filter_item.is_empty(): return "未选择允许物品"
	if not e.accepting: return "已停止接收"
	if not item.is_empty() and item != e.filter_item:
		return "只收%s，当前来料为%s" % [Rules.NAMES[e.filter_item], Rules.NAMES.get(item, item)]
	if not e.cargo.is_empty(): return "目标已满"
	if e.quota_mode == "quota" and e.quota_used >= e.quota_limit: return "本轮额度已用完"
	return ""


static func quantities(e: Dictionary) -> String:
	if e.filter_item.is_empty(): return "选择允许物品后应用设置，再允许新来料。"
	if e.quota_mode == "unlimited": return "不限数量 · 只收" + Rules.NAMES[e.filter_item]
	return "本轮已放行 %d / %d\n剩余额度 %d（槽内占用 %d）" % [e.quota_used, e.quota_limit, e.quota_limit - e.quota_used, 0 if e.cargo.is_empty() else 1]
