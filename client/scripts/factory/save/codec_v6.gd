extends "res://scripts/factory/save/codec_v1.gd"

const V2 := preload("res://scripts/factory/save/codec_v2.gd")
const V3 := preload("res://scripts/factory/save/codec_v3.gd")
const Expansion := preload("res://data/factory/expansion_rules.gd")
const ExpansionModel := preload("res://scripts/factory/expansion_model.gd")
const Entity := preload("res://scripts/factory/save/expansion_entity_validator.gd")
const Ledger := preload("res://scripts/factory/save/expansion_ledger_validator.gd")
const Stats := preload("res://scripts/factory/save/statistics_validator.gd")
const EXTRA := ["extracted_by_item", "completed_by_recipe", "assembly_counts", "batch_recipes", "first_expansion_placed"]


static func snapshot(model: RefCounted, id: String, title: String, sequence: int) -> Dictionary:
	var doc := V2.snapshot(model, id, title, sequence)
	doc.save_schema_version = 6
	doc.ruleset_id = Expansion.RULESET_ID
	for key in EXTRA:
		var value: Variant = model.get(key)
		doc.state[key] = value.duplicate(true) if value is Dictionary else value
	doc.state.entities.sort_custom(func(a, b): return a.id < b.id)
	return doc


static func decode(value: Variant, expected_id: String) -> Dictionary:
	if not value is Dictionary: return failure("存档必须是对象。")
	if value.get("world_kind") != "factory_3d" or value.get("save_schema_version") != 6 or value.get("ruleset_id") != Expansion.RULESET_ID or value.get("map_id") != Expansion.MAP_ID or value.get("supply_id") != Expansion.SUPPLY_ID:
		return failure("不支持的 E1 世界、规则、地图或供给组合。", true)
	if not fields(value, TOP_FIELDS) or not valid_id(value.world_id) or value.world_id != expected_id: return failure("世界字段或目录身份无效。")
	if not value.name is String or value.name.strip_edges().is_empty() or value.name.length() > 48 or "\n" in value.name or not integer(value.sequence, 1): return failure("世界名称或序号无效。")
	# Derived upper bound is tightened to actual node count after entity validation.
	var decoded := V2.unpack_state(value.state, Expansion.MAX_OWNED * (Expansion.MAX_OWNED - 1) / 2, EXTRA, Expansion.NAMES.keys())
	if not decoded.ok: return decoded
	var s: Dictionary = decoded.state
	var model := ExpansionModel.new()
	model.automatic_power = false
	if not number(s.time, 0, 1e12) or not number(s.remainder, 0, 3600): return failure("工厂时钟或积压无效。")
	for key in ["next_id", "next_batch"]:
		if not integer(s[key], 1): return failure("实例或批次序列无效。")
	for key in ["generated", "completed", "delivered", "delivered_batch"]:
		if not integer(s[key]): return failure("累计生产计数无效。")
	if s.completed >= s.next_batch or s.delivered_batch >= s.next_batch: return failure("累计计数与批次序列矛盾。")
	if not Ledger.counts(s.assembly_counts, Expansion.ASSEMBLY_COST.keys(), Expansion.MAX_OWNED) or not Ledger.counts(s.kits, Expansion.SUPPLY.keys(), Expansion.MAX_OWNED): return failure("构件库存或装配账无效。")
	var owned := 0
	for type in model.kits:
		model.kits[type] += int(s.assembly_counts.get(type, 0)) * Expansion.yield_for(type)
		owned += model.kits[type]
	if owned > Expansion.MAX_OWNED: return failure("构件总拥有量超过 326。")
	if not Ledger.counts(s.extracted_by_item, model.extracted_by_item.keys()) or not Ledger.counts(s.completed_by_recipe, model.recipes.keys()): return failure("生产账字段或计数无效。")
	if not s.first_expansion_placed is bool or (s.first_expansion_placed and s.assembly_counts.refinery == 0): return failure("首次扩建事实缺少精炼炉装配。")
	if not s.batch_recipes is Dictionary: return failure("活批来源表无效。")
	if not fields(s.actor, ["x", "z", "angle"]) or not number(s.actor.x, -31.7, 31.7) or not number(s.actor.z, -31.7, 31.7) or not number(s.actor.angle, -PI, PI): return failure("人物位置或朝向无效。")
	if not s.entities is Array or s.entities.size() > owned: return failure("实体数量超过总拥有量。")
	model.discovery = s.discovery.duplicate(true)
	var seen := {}
	for source in s.entities:
		var valid := Entity.validate(source, int(s.next_id), int(s.next_batch), model)
		if not valid.ok: return valid
		if seen.has(source.id): return failure("实体 ID 重复。")
		seen[source.id] = true
		var placed := model.place(source.type, Vector2i(source.x, source.z), int(source.dir))
		if not placed.ok: return failure("设备布局无效：" + placed.reason)
		var e: Dictionary = placed.entity
		e.merge(source.duplicate(true), true)
		for key in ["id", "x", "z", "dir", "cursor", "output_cursor", "input_cursor", "batch", "active_batch", "output_batch", "power_node_id", "quota_limit", "quota_used"]:
			if e.has(key): e[key] = int(e[key])
		for key in ["buffer", "input", "output", "invested", "items"]:
			if e.has(key): e[key] = V2.normalize_items(e[key])
		if e.has("entry"): e.entry = Vector2i(source.entry[0], source.entry[1])
	model.rebuild_indexes()
	for type in model.kits:
		if model.kits[type] != s.kits[type]: return failure("构件库存、放置和制造不守恒。")
	model.bag = V2.normalize_items(s.bag)
	model.actor.merge(s.actor, true)
	if model.blocked_for_actor(model.actor.x, model.actor.z): return failure("人物位于阻挡中。")
	model.time = float(s.time)
	model.remainder = float(s.remainder)
	for key in ["next_id", "next_batch", "generated", "completed", "delivered", "delivered_batch"]:
		model.set(key, int(s[key]))
	for key in ["extracted_by_item", "completed_by_recipe", "assembly_counts"]:
		model.set(key, V2.normalize_items(s[key]))
	model.batch_recipes = s.batch_recipes.duplicate()
	model.first_expansion_placed = s.first_expansion_placed
	if model.entities.filter(func(e): return e.type == "refinery").size() >= 2 and not model.first_expansion_placed: return failure("已放置第二炉但首次扩建事实缺失。")
	var topology := power(model, s.power_links)
	if not topology.ok: return topology
	# All owned consumers can be placed; historical demand cannot be bounded by today's layout.
	var request_kw := 0.0
	for type in Expansion.SUPPLY:
		var count: int = Expansion.SUPPLY[type] + model.assembly_counts.get(type, 0) * Expansion.yield_for(type)
		request_kw += count * (80.0 if type == "reactor" else model.DiscoveryRules.POWER.get(type, 0.0))
	var stats := Stats.validate_timeline(s.statistics, model.time, 240.0, request_kw, model.item_ids)
	if not stats.ok: return stats
	var ledger := Ledger.validate(model, s.statistics)
	if not ledger.ok: return ledger
	model.statistics.restore(s.statistics)
	model.statistics_ui = s.statistics_ui.duplicate(true)
	model.statistics_ui.window_seconds = int(model.statistics_ui.window_seconds)
	return {"ok": true, "model": model, "document": value}


static func power(model: RefCounted, links: Array) -> Dictionary:
	var n: int = model.entities.filter(model.Grid.is_node).size()
	if links.size() > n * (n - 1) / 2: return failure("电力连接数超过实际节点组合数。")
	var previous := [0, 0]
	for pair in links:
		if not pair is Array or pair.size() != 2 or not integer(pair[0], 1, model.next_id - 1) or not integer(pair[1], 1, model.next_id - 1) or pair[0] >= pair[1]: return failure("电力连接格式无效。")
		if pair[0] < previous[0] or (pair[0] == previous[0] and pair[1] <= previous[1]): return failure("电力连接重复或顺序无效。")
		previous = pair
	model.power_links = links.duplicate(true)
	for pair in model.power_links:
		pair[0] = int(pair[0])
		pair[1] = int(pair[1])
	return V3.verify_automatic({"ok": true, "model": model}, {})
