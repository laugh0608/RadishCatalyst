extends "res://scripts/factory/save/codec_v1.gd"

const Stats := preload("res://scripts/factory/save/statistics_validator.gd")
const BaseStats := preload("res://scripts/factory/statistics.gd")
const BurnStats := preload("res://scripts/factory/fixed_burn_statistics.gd")
const Integrated := preload("res://data/factory/integrated_rules.gd")
const Energy := preload("res://data/factory/energy_rules.gd")
const EXTRA := BurnStats.EXTRA + ["cells_activated"]


static func statistics(value: Variant, model: RefCounted, generator_count: int, request_kw: float, standby_kw: float) -> Dictionary:
	if not fields(value, ["ticks", "totals", "buckets", "current"]) or not integer(value.ticks, 0, 20000000000000) or not value.buckets is Array or value.buckets.size() > 600:
		return failure("固定燃烧统计结构无效。")
	var base: Dictionary = value.duplicate(true)
	var originals: Array = [value.totals] + value.buckets + [value.current]
	var copies: Array = [base.totals] + base.buckets + [base.current]
	for i in originals.size():
		var names := BaseStats.ENERGY + BaseStats.MATERIAL + EXTRA + ([] if i == 0 else ["start_tick", "ticks"])
		if not fields(originals[i], names): return failure("固定燃烧统计字段无效。")
		for key in BurnStats.EXTRA:
			if not number(originals[i][key], 0, 1e15): return failure("固定燃烧电量无效。")
		if not integer(originals[i].cells_activated): return failure("激活电芯次数无效。")
		for key in EXTRA:
			copies[i].erase(key)
	var generator_kw := generator_count * Energy.GENERATOR_KW
	var common := Stats.validate_timeline(base, model.time, Integrated.BASE_KW + generator_kw, request_kw, model.item_ids)
	if not common.ok:
		return common
	var research_cells := 0
	if model.researched.has(Integrated.Frontier.RESEARCH):
		research_cells = Integrated.Frontier.NODE.cost[Energy.CELL]
	var recent_research_cells := 0
	var sums := {}
	for key in EXTRA:
		sums[key] = 0
	for i in originals.size():
		var r: Dictionary = originals[i]
		var duration: float = model.time if i == 0 else r.ticks * model.STEP
		if not _record(r, duration, generator_kw, standby_kw):
			return failure("固定燃烧分项、弃能或待机电量不守恒。")
		var non_fuel_cells: int = int(r.consumed.get(Energy.CELL, 0)) - int(r.cells_activated)
		if (i == 0 and non_fuel_cells != research_cells) or (i > 0 and non_fuel_cells not in [0, research_cells]):
			return failure("电芯消费与激活、开拓研究不一致。")
		if i > 0:
			recent_research_cells += non_fuel_cells
			for key in EXTRA:
				sums[key] += r[key]
	if recent_research_cells > research_cells or (value.ticks < 12020 and recent_research_cells != research_cells):
		return failure("近期电芯研究消费与累计量不一致。")
	for key in EXTRA:
		var same: bool = sums[key] == value.totals[key] if key == "cells_activated" else Stats.near(sums[key], value.totals[key])
		if (sums[key] > value.totals[key] and not same) or (value.ticks < 12020 and not same):
			return failure("近期固定燃烧账与累计量不一致。")
	for pair in [["used_kj", "standby_kj"], ["fuel_released_kj", "spill_kj"]]:
		var recent := 0.0
		for r in value.buckets + [value.current]:
			recent += r[pair[0]] - r[pair[1]]
		if not _at_most(recent, value.totals[pair[0]] - value.totals[pair[1]]):
			return failure("近期运行用电或燃料获用量超过累计量。")
	return {"ok": true}


static func _at_most(amount: float, limit: float) -> bool:
	return amount <= limit or Stats.near(amount, limit)


static func _record(r: Dictionary, duration: float, generator_kw: float, standby_kw: float) -> bool:
	return (Stats.near(r.base_supplied_kj + r.fuel_released_kj, r.used_kj + r.spill_kj)
		and _at_most(r.spill_kj, r.fuel_released_kj)
		and _at_most(r.base_supplied_kj, Integrated.BASE_KW * duration)
		and _at_most(r.fuel_released_kj, generator_kw * duration)
		and _at_most(r.standby_kj, minf(r.used_kj, standby_kw * duration))
		and _at_most(r.available_kj, r.enabled_kj) and _at_most(r.enabled_kj, r.installed_kj))


static func balance(model: RefCounted) -> Dictionary:
	var ledger: Dictionary = model.energy_balance()
	if ledger.activated > model.completed_by_recipe[Energy.RECIPE] or not Stats.near(
		ledger.activated * Energy.CELL_KJ, ledger.released_kj + ledger.discarded_kj + ledger.remaining_kj):
		return failure("电芯激活、释能、现存余能和回收损失不守恒。")
	return {"ok": true}
