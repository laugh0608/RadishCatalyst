extends "res://scripts/factory/save/codec_v1.gd"

const V2 := preload("res://scripts/factory/save/codec_v2.gd")
const V6 := preload("res://scripts/factory/save/codec_v6.gd")
const Definitions := preload("res://scripts/factory/save/integrated_definitions.gd")
const Integrated := Definitions.Rules
const IntegratedModel := Definitions.Model
const Tech := Definitions.Tech
const Energy := Definitions.Energy
const Stats := V6.Stats
const Entity := V6.Entity
const Ledger := V6.Ledger
const Burn := preload("res://scripts/factory/save/fixed_burn_validator.gd")
const VERSION := 9
const EXTRA := ["extracted_by_item", "completed_by_recipe", "assembly_counts", "batch_recipes", "core", "research"]
const STATE := ["simulation_tick", "remainder_s", "next_id", "next_batch", "generated", "completed",
	"delivered", "delivered_batch", "kits", "bag", "actor", "entities", "power_links", "discovery", "statistics", "statistics_ui"] + EXTRA


static func snapshot(model: RefCounted, id: String, title: String, sequence: int) -> Dictionary:
	var doc := V2.snapshot(model, id, title, sequence)
	doc.save_schema_version = VERSION
	doc.ruleset_id = Integrated.RULESET_ID
	doc.definitions_sha256 = Definitions.sha256()
	var s: Dictionary = doc.state
	s.erase("time")
	s.erase("remainder")
	s.simulation_tick = model.statistics.ticks
	s.remainder_s = model.remainder
	s.discovery.erase("trial_completed")
	for key in ["extracted_by_item", "completed_by_recipe", "assembly_counts", "batch_recipes"]:
		s[key] = model.get(key).duplicate()
	var nodes: Array = model.researched.keys()
	nodes.sort()
	s.research = {"completed": nodes}
	s.core = {"entity_id": model.core.id}
	for e in s.entities:
		if e.type == Integrated.CORE:
			for key in ["level", "items", "outputs", "input_cursors", "output_cursors"]:
				s.core[key] = e[key]
				e.erase(key)
	for port_id in s.core.outputs:
		s.core.outputs[port_id].id = port_id
	s.entities.sort_custom(func(a, b): return a.id < b.id)
	return doc


static func decode(value: Variant, expected_id: String) -> Dictionary:
	if not value is Dictionary: return failure("存档必须是对象。")
	if value.get("world_kind") != "factory_3d" or value.get("save_schema_version") != VERSION or value.get("ruleset_id") != Integrated.RULESET_ID or value.get("map_id") != Integrated.MAP_ID or value.get("supply_id") != Integrated.SUPPLY_ID:
		return failure("不支持的整合工厂身份。", true)
	if value.get("definitions_sha256") != Definitions.PIN or Definitions.sha256() != Definitions.PIN:
		return failure("整合工厂定义摘要不匹配，不能按其他规则读取。", true)
	return decode_state(value, expected_id, IntegratedModel.new())


static func decode_state(value: Dictionary, expected_id: String, model: RefCounted) -> Dictionary:
	var frontier: bool = model.supply_id == Integrated.Frontier.SUPPLY_ID
	if not fields(value, TOP_FIELDS + ["definitions_sha256"]) or not valid_id(value.world_id) or value.world_id != expected_id:
		return failure("整合世界字段或目录身份无效。")
	if not value.name is String or value.name.strip_edges().is_empty() or value.name.length() > 48 or "\n" in value.name or not integer(value.sequence, 1):
		return failure("世界名称或序号无效。")
	var s: Variant = value.state
	if not fields(s, STATE + (["frontier_extracted"] if frontier else [])) or not integer(s.simulation_tick, 0, 20000000000000) or not number(s.remainder_s, 0, 3600):
		return failure("整合世界状态或时钟无效。")
	if not integer(s.next_id, 2) or not integer(s.next_batch, 1):
		return failure("实例或批次序号无效。")
	for key in ["generated", "completed", "delivered", "delivered_batch"]:
		if not integer(s[key]): return failure("累计计数无效。")
	if s.completed >= s.next_batch or s.delivered_batch >= s.next_batch:
		return failure("累计计数与批次序列矛盾。")
	model.automatic_power = false
	if not Ledger.counts(s.extracted_by_item, model.extracted_by_item.keys()) or not Ledger.counts(s.completed_by_recipe, model.recipes.keys()) or not integer(s.completed_by_recipe.solvent_trial, 0, 1):
		return failure("采集、配方或唯一次试制计数无效。")
	if not fields(s.discovery, ["surveyed", "sample_taken", "passages"]):
		return failure("发现字段无效。")
	var common: Dictionary = s.duplicate(true)
	common.erase("simulation_tick")
	common.erase("remainder_s")
	var frontier_open := false
	if frontier:
		if not fields(s.discovery.passages, ["outer", "inner", Integrated.Frontier.PASSAGE]) or not s.discovery.passages[Integrated.Frontier.PASSAGE] is bool:
			return failure("开拓支路状态无效。")
		frontier_open = s.discovery.passages[Integrated.Frontier.PASSAGE]
		var max_extracted := mini(int(s.extracted_by_item.carbon_ore),
			floori(s.simulation_tick * model.STEP / Integrated.Frontier.ORE_SECONDS))
		if not integer(s.frontier_extracted, 0, max_extracted) or (s.frontier_extracted > 0 and not frontier_open):
			return failure("高产炭矿累计与矿区状态矛盾。")
		model.frontier_extracted = int(s.frontier_extracted)
		common.erase("frontier_extracted")
		common.discovery.passages.erase(Integrated.Frontier.PASSAGE)
	common.time = int(s.simulation_tick) * model.STEP
	common.remainder = s.remainder_s
	common.discovery.trial_completed = s.completed_by_recipe.solvent_trial == 1
	var unpacked := V2.unpack_state(common, Tech.MAX_OWNED * (Tech.MAX_OWNED - 1) / 2, EXTRA, model.item_ids.filter(func(item): return item not in V2.Config.ITEMS))
	if not unpacked.ok:
		return unpacked
	model.discovery = unpacked.state.discovery
	var progression := _load_progression(model, s.core, s.research)
	if not progression.ok:
		return progression
	if frontier:
		if frontier_open and (not model.discovery.passages.outer or not model.researched.has(Integrated.Frontier.RESEARCH)):
			return failure("已开拓支路缺少外矿道或开拓工具研究。")
		model.discovery.passages[Integrated.Frontier.PASSAGE] = frontier_open
		if not model.item_known(Integrated.Frontier.CAPSULE):
			for port in model.core.outputs.values():
				if port.item == Integrated.Frontier.CAPSULE:
					return failure("未研究的破岩胶囊不能配置出料。")
	for item in s.statistics_ui.favorites:
		if not model.item_known(item): return failure("统计收藏物品尚未掌握。")
	var owned := _owned_budget(model, s)
	if not owned.ok:
		return owned
	var entities := _load_entities(model, s)
	if not entities.ok:
		return entities
	model.bag = V2.normalize_items(s.bag)
	if not fields(s.actor, ["x", "z", "angle"]) or not number(s.actor.x, -31.7, 31.7) or not number(s.actor.z, -31.7, 31.7) or not number(s.actor.angle, -PI, PI):
		return failure("人物位置或朝向无效。")
	model.actor.merge(s.actor, true)
	if model.blocked_for_actor(model.actor.x, model.actor.z): return failure("人物位于阻挡中。")
	model.time = common.time
	model.remainder = float(s.remainder_s)
	for key in ["next_id", "next_batch", "generated", "completed", "delivered", "delivered_batch"]:
		model.set(key, int(s[key]))
	for key in ["extracted_by_item", "completed_by_recipe", "assembly_counts"]:
		model.set(key, V2.normalize_items(s[key]))
	model.batch_recipes = s.batch_recipes.duplicate()
	var topology := V6.power(model, s.power_links)
	if not topology.ok:
		return topology
	if not s.statistics is Dictionary or s.statistics.get("ticks") != s.simulation_tick:
		return failure("统计与世界模拟时钟不一致。")
	var statistics := Burn.statistics(s.statistics, model, owned.generator_count, owned.request_kw, owned.standby_kw)
	if not statistics.ok:
		return statistics
	model.statistics.restore(s.statistics)
	var fuel := Burn.balance(model)
	if not fuel.ok:
		return fuel
	var ledger := Ledger.validate(model, s.statistics, true)
	if not ledger.ok:
		return ledger
	model.statistics_ui = s.statistics_ui.duplicate(true)
	model.statistics_ui.window_seconds = int(model.statistics_ui.window_seconds)
	return {"ok": true, "model": model, "document": value}


static func _load_progression(model: RefCounted, core: Variant, research: Variant) -> Dictionary:
	if not fields(core, ["entity_id", "level", "items", "outputs", "input_cursors", "output_cursors"]) or not integer(core.entity_id, model.core.id, model.core.id) or not integer(core.level, 1, 2):
		return failure("核心身份、字段或等级无效。")
	if not Stats.items(core.items, Integrated.ITEM_LIMIT, model.item_ids) or not fields(core.outputs, model.core.outputs.keys()):
		return failure("核心库存超限或出料口集合无效。")
	for role in ["input", "output"]:
		var cursors: Variant = core[role + "_cursors"]
		if not cursors is Dictionary: return failure("核心轮询游标无效。")
		var limit := Integrated.ports(Vector2i.ZERO, role).size()
		for item in cursors:
			if item not in model.admission_items or not integer(cursors[item], 0, limit - 1):
				return failure("核心轮询游标引用越界。")
		model.core[role + "_cursors"] = V2.normalize_items(cursors)
	for id in core.outputs:
		var port: Variant = core.outputs[id]
		if not fields(port, ["id", "item", "enabled", "cooldown_ticks"]) or port.id != id or not port.item is String or port.item not in [""] + model.admission_items or not port.enabled is bool or (port.item.is_empty() and port.enabled) or not integer(port.cooldown_ticks, 0, Integrated.COOLDOWN_TICKS):
			return failure("核心出料物品、开关或冷却无效。")
		model.core.outputs[id] = {"item": port.item, "enabled": port.enabled, "cooldown_ticks": int(port.cooldown_ticks)}
	if not fields(research, ["completed"]) or not research.completed is Array or research.completed.size() > model.research_nodes.size():
		return failure("研究集合无效。")
	model.researched.clear()
	var last := ""
	for id in research.completed:
		if not id is String or not model.research_nodes.has(id) or id <= last:
			return failure("研究未知、重复或顺序无效。")
		last = id
		model.researched[id] = true
	if not model.researched.has(Tech.BASE):
		return failure("缺少起步研究。")
	for id in model.researched:
		var node: Dictionary = model.research_nodes[id]
		if core.level < node.level or not node.requires.all(func(dep): return model.researched.has(dep)) or not model.research_fact_missing(id).is_empty():
			return failure("已完成研究缺少等级、前置或发现。")
	if core.level == 2 and not Tech.II_REQUIRES.all(func(id): return model.researched.has(id)):
		return failure("核心 II 缺少研究前置。")
	model.core.level = int(core.level)
	model.core.items = V2.normalize_items(core.items)
	return {"ok": true}


static func _owned_budget(model: RefCounted, s: Dictionary) -> Dictionary:
	if not Ledger.counts(s.assembly_counts, model.assembly_costs.keys(), Tech.MAX_OWNED) or not Ledger.counts(s.kits, model.kits.keys(), Tech.MAX_OWNED):
		return failure("整合构件库存或装配计数无效。")
	var owned := 1
	var request_kw := 0.0
	var standby_kw := 0.0
	for type in model.kits:
		if s.assembly_counts[type] > 0 and (not model.researched.has(Tech.ASSEMBLY) or not model.device_unlocked(type)):
			return failure("装配早于实际研究。")
		var count: int = model.kits[type] + int(s.assembly_counts[type]) * V6.Expansion.yield_for(type)
		model.kits[type] = count
		owned += count
		request_kw += count * (80.0 if type == "reactor" else V2.Config.POWER.get(type, 0.0))
		standby_kw += count * Energy.STANDBY_KW.get(type, 0.0)
	if owned > Tech.MAX_OWNED or not s.entities is Array or s.entities.size() > owned:
		return failure("整合构件总拥有量超限。")
	for id in s.completed_by_recipe:
		if s.completed_by_recipe[id] > 0 and not model.recipe_available(id) and not (id == "solvent_trial" and model.researched.has(Tech.SAMPLE)):
			return failure("生产早于实际研究或发现。")
	return {"ok": true, "generator_count": model.kits[Energy.GENERATOR], "request_kw": request_kw, "standby_kw": standby_kw}


static func _load_entities(model: RefCounted, s: Dictionary) -> Dictionary:
	var last := 0
	var core_seen := false
	for source in s.entities:
		if not source is Dictionary or not integer(source.get("id"), last + 1, int(s.next_id) - 1):
			return failure("实体序号无效、重复或未排序。")
		last = int(source.id)
		var type: Variant = source.get("type")
		if type == Integrated.CORE:
			if core_seen or not fields(source, ["id", "type", "x", "z", "dir"]) or last != model.core.id or source.x != model.core.x or source.z != model.core.z or source.dir != model.core.dir:
				return failure("预置核心重复或几何无效。")
			core_seen = true
			continue
		if not type is String or not model.device_unlocked(type):
			return failure("设备类型未知或尚未研究。")
		var valid := _generator(source, model) if type == Energy.GENERATOR else Entity.validate(source, int(s.next_id), int(s.next_batch), model, true, true)
		if not valid.ok:
			return valid
		var shape: Dictionary = model.CATALOG[type]
		for x in range(int(source.x), int(source.x) + shape.w):
			for z in range(int(source.z), int(source.z) + shape.d):
				if not model.entity_at(Vector2i(x, z)).is_empty():
					return failure("设备占地重叠。")
		model.next_id = last
		var placed: Dictionary = model.place(type, Vector2i(source.x, source.z), int(source.dir))
		if not placed.ok:
			return failure("设备布局无效：" + placed.reason)
		var e: Dictionary = placed.entity
		e.merge(source.duplicate(true), true)
		for key in ["id", "x", "z", "dir", "cursor", "output_cursor", "input_cursor", "batch", "active_batch", "output_batch", "power_node_id", "quota_limit", "quota_used", "burn_remaining_ticks"]:
			if e.has(key): e[key] = int(e[key])
		for key in ["buffer", "input", "output", "invested", "items", "fuel"]:
			if e.has(key): e[key] = V2.normalize_items(e[key])
		if e.has("entry"): e.entry = Vector2i(source.entry[0], source.entry[1])
	if not core_seen or model.kits != V2.normalize_items(s.kits):
		return failure("核心缺失或构件库存与装配不守恒。")
	model.rebuild_indexes()
	if not s.batch_recipes is Dictionary:
		return failure("活批来源无效。")
	for id in s.batch_recipes.values():
		if not id is String or not model.recipes.has(id) or (not model.recipe_available(id) and not (id == "solvent_trial" and model.researched.has(Tech.SAMPLE))):
			return failure("活批使用未掌握配方。")
	return {"ok": true}


static func _generator(e: Dictionary, model: RefCounted) -> Dictionary:
	if not fields(e, ["id", "type", "x", "z", "dir", "enabled", "fuel", "burn_remaining_ticks"]) or not integer(e.x, -32, 31) or not integer(e.z, -32, 31) or not integer(e.dir, 0, 0):
		return failure("固定燃烧发电机字段、方向或位置无效。")
	if not e.enabled is bool or not Entity.bounded(e.fuel, {Energy.CELL: Energy.FUEL_CAPACITY}, model) or not integer(e.burn_remaining_ticks, 0, Integrated.BURN_TICKS):
		return failure("完整电芯容量、燃烧余时或启停无效。")
	return {"ok": true}
