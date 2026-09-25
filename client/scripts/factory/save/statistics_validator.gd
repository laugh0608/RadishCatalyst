extends "res://scripts/factory/save/codec_v1.gd"

const Stats := preload("res://scripts/factory/statistics.gd")
const Config := preload("res://data/factory/discovery_rules.gd")


static func near(a: float, b: float) -> bool:
	return absf(a - b) <= 1e-7 + 1e-10 * maxf(absf(a), absf(b))


static func items(value: Variant, limit := MAX_NUMBER) -> bool:
	if not value is Dictionary:
		return false
	for item in value:
		if item not in Config.ITEMS or not integer(value[item], 1, limit):
			return false
	return true


static func valid_record(r: Variant, duration: float) -> bool:
	if not fields(r, Stats.ENERGY + Stats.MATERIAL):
		return false
	for key in Stats.ENERGY:
		if not number(r[key], 0, 1e15):
			return false
	for key in Stats.MATERIAL:
		if not items(r[key]):
			return false
	return near(r.supplied_kj, r.used_kj) and near(r.requested_kj, r.used_kj + r.deficit_kj) and r.used_kj <= r.available_kj + 1e-7 and r.available_kj <= r.installed_kj + 1e-7 and r.installed_kj <= 240 * duration + 1e-7 and r.requested_kj <= 800 * duration + 1e-7


static func validate(value: Variant, time: float, model: RefCounted) -> Dictionary:
	if not fields(value, ["ticks", "totals", "buckets", "current"]) or not integer(value.ticks, 0, 20000000000000):
		return failure("统计字段或模拟步计数无效。")
	if absf(time - value.ticks * 0.05) > 1e-6 or not valid_record(value.totals, time):
		return failure("统计累计量与时钟或能量不一致。")
	if not value.buckets is Array or value.buckets.size() != mini(600, int(value.ticks) / 20):
		return failure("近期统计完整秒数量不一致。")
	var expected: int = int(value.ticks) - int(value.ticks) % 20 - value.buckets.size() * 20
	var summed := Stats.record()
	var records: Array = value.buckets.duplicate()
	records.append(value.current)
	for i in records.size():
		var b: Variant = records[i]
		var count := 20 if i < value.buckets.size() else int(value.ticks) % 20
		if not fields(b, Stats.ENERGY + Stats.MATERIAL + ["start_tick", "ticks"]) or not integer(b.start_tick) or b.start_tick != expected or not integer(b.ticks, 0, 20) or b.ticks != count:
			return failure("统计桶重叠、缺失或超长。")
		var r: Dictionary = b.duplicate(true)
		r.erase("start_tick")
		r.erase("ticks")
		if not valid_record(r, count * 0.05):
			return failure("统计桶数值或能量不守恒。")
		for kind in Stats.MATERIAL:
			for item in r[kind]:
				summed[kind][item] = summed[kind].get(item, 0) + r[kind][item]
		for key in Stats.ENERGY:
			summed[key] += r[key]
		expected += count
	for key in Stats.ENERGY:
		if summed[key] > value.totals[key] and not near(summed[key], value.totals[key]):
			return failure("近期电量超过累计电量。")
		if value.ticks < 12020 and not near(summed[key], value.totals[key]):
			return failure("未截断历史与累计电量不同。")
	for kind in Stats.MATERIAL:
		for item in Config.ITEMS:
			var total: Variant = value.totals[kind].get(item, 0)
			var recent: Variant = summed[kind].get(item, 0)
			if recent > total or (value.ticks < 12020 and recent != total):
				return failure("近期物料与累计量不一致。")
	var totals: Dictionary = value.totals
	if totals.produced.get("crystal", 0) != model.generated or totals.produced.get("catalyst", 0) != model.completed or totals.consumed.get("crystal", 0) != 2 * model.completed or totals.delivered.get("catalyst", 0) != model.delivered:
		return failure("产消记账与世界生产计数不一致。")
	if not totals.acquired.is_empty() or totals.consumed.size() != (1 if model.completed > 0 else 0):
		return failure("基础生产记账含未实现的取得或消耗。")
	for kind in Stats.MATERIAL:
		for item in totals[kind]:
			if item not in ["crystal", "catalyst"]:
				return failure("当前版本尚不能运行此发现内容。", true)
	return {"ok": true}
