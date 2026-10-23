extends "res://scripts/factory/save/codec_v1.gd"

const Energy := preload("res://data/factory/energy_rules.gd")
const Stats := preload("res://scripts/factory/save/statistics_validator.gd")
const BaseStats := preload("res://scripts/factory/statistics.gd")


static func origin(value: Variant, world_id: String) -> Dictionary:
	if not value is Dictionary: return failure("能源世界来源必须是对象。")
	if value.is_empty(): return {"ok": true}
	if not fields(value, ["source_id", "source_sequence", "source_sha256"]) or not valid_id(value.source_id) or value.source_id == world_id or not integer(value.source_sequence, 1):
		return failure("能源复制来源身份或序号无效。")
	if not value.source_sha256 is String or value.source_sha256.length() != 64: return failure("能源复制来源哈希无效。")
	for c in value.source_sha256:
		if c not in "0123456789abcdef": return failure("能源复制来源哈希无效。")
	return {"ok": true}


static func statistics(value: Variant, model: RefCounted, request_kw: float) -> Dictionary:
	if not fields(value, ["ticks", "totals", "buckets", "current"]) or not value.buckets is Array or value.buckets.size() > 600:
		return failure("能源统计结构无效。")
	var core: Dictionary = value.duplicate(true)
	var originals: Array = [value.totals] + value.buckets + [value.current]
	var copies: Array = [core.totals] + core.buckets + [core.current]
	var extra := Energy.EXTRA_ENERGY + Energy.EXTRA_COUNTS
	for i in originals.size():
		var names := BaseStats.ENERGY + BaseStats.MATERIAL + extra + ([] if i == 0 else ["start_tick", "ticks"])
		if not fields(originals[i], names): return failure("能源统计字段不完整或含未知字段。")
		for key in Energy.EXTRA_ENERGY:
			if not number(originals[i][key], 0, 1e15): return failure("能源统计必须是有限非负电量。")
		for key in Energy.EXTRA_COUNTS:
			if not integer(originals[i][key]): return failure("激活电芯计数无效。")
		for key in extra: copies[i].erase(key)
	var generator_kw: float = model.assembly_counts[Energy.GENERATOR] * Energy.GENERATOR_KW
	var result := Stats.validate_timeline(core, model.time, 240.0 + generator_kw, request_kw, model.item_ids)
	if not result.ok: return result
	var sums := {}
	for key in extra: sums[key] = 0 if key in Energy.EXTRA_COUNTS else 0.0
	for i in originals.size():
		var r: Dictionary = originals[i]
		var duration: float = model.time if i == 0 else r.ticks * 0.05
		if not Stats.near(r.base_supplied_kj + r.cell_supplied_kj, r.supplied_kj) or r.base_supplied_kj > 240.0 * duration + 1e-7 or r.cell_supplied_kj > generator_kw * duration + 1e-7:
			return failure("基础与电芯供能分项不守恒或超装机上限。")
		if r.available_kj > r.enabled_kj + 1e-7 or r.enabled_kj > r.installed_kj + 1e-7:
			return failure("当前可供、启用额定与装机额定关系无效。")
		if r.consumed.get(Energy.CELL, 0) != r.cells_activated: return failure("电芯消费必须在激活时恰记一次。")
		if i > 0:
			for key in extra: sums[key] += r[key]
	for key in extra:
		var same: bool = sums[key] == value.totals[key] if key in Energy.EXTRA_COUNTS else Stats.near(sums[key], value.totals[key])
		if (sums[key] > value.totals[key] and not same) or (value.ticks < 12020 and not same):
			return failure("近期能源账与累计量不一致。")
	return {"ok": true}


static func balance(model: RefCounted) -> Dictionary:
	if not model.first_expansion_placed and (model.assembly_counts[Energy.GENERATOR] > 0 or model.completed_by_recipe[Energy.RECIPE] > 0):
		return failure("电芯或发电机制造早于首次扩建。")
	var ledger: Dictionary = model.energy_balance()
	if not Stats.near(ledger.activated * Energy.CELL_KJ, ledger.supplied_kj + ledger.discarded_kj + ledger.remaining_kj):
		return failure("激活电芯、实际供能、回收损失与现存余能不守恒。")
	if ledger.activated > model.completed_by_recipe[Energy.RECIPE]: return failure("电芯激活超过真实产量。")
	return {"ok": true}
