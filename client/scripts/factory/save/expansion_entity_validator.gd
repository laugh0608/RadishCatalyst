extends "res://scripts/factory/save/codec_v1.gd"

const Energy := preload("res://data/factory/energy_rules.gd")
const V2 := preload("res://scripts/factory/save/codec_v2.gd")
const Stats := preload("res://scripts/factory/save/statistics_validator.gd")
const Expansion := preload("res://data/factory/expansion_rules.gd")
const Routing := preload("res://scripts/factory/save/routing_validator.gd")
const Admission := preload("res://scripts/factory/save/admission_validator.gd")
const MINERALS := ["crystal", "rich_crystal", "iron_ore", "carbon_ore"]


static func bounded(value: Variant, limits: Dictionary, model: RefCounted) -> bool:
	if not Stats.items(value, 200, model.item_ids): return false
	for item in value:
		if value[item] > limits.get(item, 0): return false
	return true


static func validate(e: Variant, next_id: int, next_batch: int, model: RefCounted, energy := false) -> Dictionary:
	if not e is Dictionary or not e.get("type") is String or not model.kits.has(e.type):
		return failure("未知 E1 设备类型。")
	if e.type == Energy.GENERATOR: return generator(e, next_id, model) if energy else failure("旧世界不能含发电机。")
	if e.type == "admission_gate": return Admission.validate(e, next_id, next_batch, model.admission_items, MINERALS)
	if e.type in ["splitter", "merger"]: return Routing.validate(e, next_id, next_batch, model.admission_items, MINERALS)
	if e.type in ["power_source", "power_junction"]: return V2.validate_power_entity(e, next_id, next_batch, model)
	var extra: Array
	if e.type in model.process_types:
		extra = ["recipe_id", "input", "output", "invested", "processing", "progress", "active_batch", "output_batch", "power_node_id"]
		if e.type in Expansion.PROCESSORS: extra.append("output_cursor")
	else:
		extra = {"collector": ["mineral", "buffer", "progress", "power_node_id"], "storage": ["items"], "belt": ["cargo", "progress", "entry", "cursor", "batch"]}[e.type]
	if energy and model.DiscoveryRules.POWER.has(e.type):
		extra.append("enabled")
		if not e.get("enabled") is bool: return failure("设备启停必须是布尔值。")
	if not fields(e, ["id", "type", "x", "z", "dir"] + extra) or not integer(e.id, 1, next_id - 1) or not integer(e.x, -32, 31) or not integer(e.z, -32, 31) or not integer(e.dir, 0, 3):
		return failure("E1 设备字段、身份或位置无效。")
	if e.type != "belt" and e.dir != 0: return failure("加工设备不支持旋转。")
	if e.has("power_node_id") and not integer(e.power_node_id, 0, next_id - 1): return failure("供电引用无效。")
	if e.type == "collector":
		var mineral: String = model.mineral_at(Vector2i(e.x, e.z))
		var cycle := Expansion.cycle(mineral)
		if mineral.is_empty() or e.mineral != mineral or not bounded(e.buffer, {mineral: 50}, model) or not number(e.progress, 0, cycle) or e.progress >= cycle:
			return failure("矿物、采集缓冲或周期进度无效。")
	elif e.type in model.process_types:
		return processor(e, next_batch, model)
	elif e.type == "storage":
		if not Stats.items(e.items, 200, model.item_ids) or model.Items.count(e.items) > 200: return failure("仓储物料或容量无效。")
	elif e.type == "belt":
		if not integer(e.cursor, 0, next_id - 1): return failure("传送带仲裁游标无效。")
		return Routing.validate_cargo(e, next_batch, [2, 3, 1], model.admission_items, MINERALS, false)
	return {"ok": true}


static func processor(e: Dictionary, next_batch: int, model: RefCounted) -> Dictionary:
	if not e.recipe_id is String or not model.recipes.has(e.recipe_id): return failure("未知加工配方。")
	var recipe: Dictionary = model.recipes[e.recipe_id]
	if recipe.get("machine", "reactor") != e.type: return failure("配方与设备不匹配。")
	if not model.recipe_available(e.recipe_id) and not (e.recipe_id == "solvent_trial" and model.discovery.trial_completed): return failure("配方尚未掌握。")
	var limits: Dictionary = recipe.input.duplicate()
	for item in limits: limits[item] *= 1 if e.type == "reactor" else 2
	if not bounded(e.input, limits, model) or not bounded(e.output, recipe.output, model) or not bounded(e.invested, recipe.input, model) or not e.processing is bool or not number(e.progress, 0, recipe.seconds) or e.progress >= recipe.seconds:
		return failure("输入、输出、在制或进度超出配方容量。")
	if not integer(e.active_batch, 0, next_batch - 1) or not integer(e.output_batch, 0, next_batch - 1): return failure("加工批次无效。")
	if e.type in Expansion.PROCESSORS and not integer(e.output_cursor, 0, Expansion.PORTS[e.type].output.size() - 1): return failure("出口轮询游标无效。")
	if e.processing:
		if not model.recipe_available(e.recipe_id) or e.active_batch == 0 or not e.output.is_empty() or V2.normalize_items(e.invested) != recipe.input: return failure("在制投入或批次状态矛盾。")
	elif e.progress != 0 or e.active_batch != 0 or not e.invested.is_empty(): return failure("空闲设备含在制。")
	if e.output.is_empty() != (e.output_batch == 0): return failure("输出与批次引用矛盾。")
	return {"ok": true}


static func generator(e: Dictionary, next_id: int, model: RefCounted) -> Dictionary:
	if not fields(e, ["id", "type", "x", "z", "dir", "enabled", "fuel", "remaining_kj"]) or not integer(e.id, 1, next_id - 1) or not integer(e.x, -32, 31) or not integer(e.z, -32, 31) or not integer(e.dir, 0, 0):
		return failure("发电机字段、身份、位置或方向无效。")
	if not e.enabled is bool or not bounded(e.fuel, {Energy.CELL: Energy.FUEL_CAPACITY}, model) or not number(e.remaining_kj, 0, Energy.CELL_KJ):
		return failure("发电机燃料、余能或启停无效。")
	return {"ok": true}
