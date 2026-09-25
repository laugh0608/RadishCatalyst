extends "res://scripts/factory/save/codec_v1.gd"

const V1 := preload("res://scripts/factory/save/codec_v1.gd")
const NewModel := preload("res://scripts/factory/discovery_model.gd")
const Config := preload("res://data/factory/discovery_rules.gd")
const Validator := preload("res://scripts/factory/save/statistics_validator.gd")


static func snapshot(model: RefCounted, id: String, title: String, sequence: int) -> Dictionary:
	var doc := V1.snapshot(model, id, title, sequence)
	doc.save_schema_version = 2
	doc.ruleset_id = Config.RULESET_ID
	doc.map_id = Config.MAP_ID
	for key in ["power_links", "discovery", "statistics_ui"]:
		doc.state[key] = model.get(key).duplicate(true)
	doc.state.statistics = model.statistics.snapshot()
	return doc


static func unpack_state(value: Variant) -> Dictionary:
	if not fields(value, STATE_FIELDS + ["power_links", "discovery", "statistics", "statistics_ui"]):
		return failure("联合工厂状态字段无效。")
	var s: Dictionary = value.duplicate(true)
	if not fields(s.discovery, ["surveyed", "sample_taken", "trial_completed", "passages"]) or not fields(s.discovery.passages, ["outer", "inner"]):
		return failure("发现状态字段无效。")
	var d: Dictionary = s.discovery
	for flag in [d.surveyed, d.sample_taken, d.trial_completed, d.passages.outer, d.passages.inner]:
		if not flag is bool:
			return failure("发现状态必须是布尔值。")
	if (d.sample_taken and not d.surveyed) or (d.trial_completed and not d.sample_taken) or (d.passages.outer and not d.trial_completed) or (d.passages.inner and not d.passages.outer):
		return failure("发现与矿道前置事实矛盾。")
	if not s.power_links is Array or s.power_links.size() > 91:
		return failure("电力连接列表超限。")
	if not fields(s.statistics_ui, ["window_seconds", "favorites"]) or not integer(s.statistics_ui.window_seconds) or int(s.statistics_ui.window_seconds) not in [60, 300, 600] or not s.statistics_ui.favorites is Array:
		return failure("统计偏好无效。")
	var favorites := {}
	for item in s.statistics_ui.favorites:
		var known: bool = item in ["crystal", "catalyst"] or (item == "crust_sample" and d.sample_taken) or (item in ["crust_solvent", "rich_crystal"] and d.trial_completed)
		if not known or favorites.has(item):
			return failure("收藏物料尚未掌握或重复。")
		favorites[item] = true
	if not Validator.items(s.bag, 200) or NewModel.Items.count(s.bag) > 200:
		return failure("背包物品或容量无效。")
	return {"ok": true, "state": s}


static func normalize_items(items: Dictionary) -> Dictionary:
	var result := {}
	for key in items:
		result[key] = int(items[key])
	return result


static func decode(value: Variant, expected_id: String) -> Dictionary:
	if not value is Dictionary:
		return failure("存档必须是对象。")
	# Unsupported versions are fatal even when an older backup exists.
	if value.has("save_schema_version") and integer(value.save_schema_version) and value.save_schema_version > 2:
		return failure("此工厂来自更新版本，当前版本不能读取。", true)
	for pair in [["ruleset_id", Config.RULESET_ID], ["map_id", Config.MAP_ID]]:
		if value.has(pair[0]) and value[pair[0]] != pair[1]:
			return failure("不支持的工厂规则或地图版本。", true)
	if not fields(value, TOP_FIELDS) or value.world_kind != "factory_3d" or value.save_schema_version != 2:
		return failure("不是受支持的工厂存档，或字段不完整。")
	if not valid_id(value.world_id) or value.world_id != expected_id:
		return failure("存档身份与世界目录不一致。")
	if not value.name is String or value.name.strip_edges().is_empty() or value.name.length() > 48 or "\n" in value.name:
		return failure("世界名称无效。")
	if not integer(value.sequence, 1) or not value.supply_id is String or value.supply_id != Config.SUPPLY_ID:
		return failure("存档序号或构件供给版本无效。", value.supply_id != Config.SUPPLY_ID)
	var decoded := unpack_state(value.state)
	if not decoded.ok:
		return decoded
	var s: Variant = decoded.state
	if not fields(s, STATE_FIELDS + ["power_links", "discovery", "statistics", "statistics_ui"]):
		return failure("工厂状态字段不完整或含未知字段。")
	if not number(s.time, 0, 1e12) or not number(s.remainder, 0, 3600):
		return failure("工厂时钟无效或活动积压超过一小时。")
	for key in ["next_id", "next_batch"]:
		if not integer(s[key], 1):
			return failure("实例或批次序列无效。")
	for key in ["generated", "completed", "delivered", "delivered_batch"]:
		if not integer(s[key]):
			return failure("生产统计必须是非负整数。")
	if s.completed >= s.next_batch or s.delivered_batch >= s.next_batch:
		return failure("生产统计与批次序列不一致。")
	if not fields(s.kits, Config.CATALOG.keys()):
		return failure("构件或回收箱字段无效。")
	for key in s.kits:
		if not integer(s.kits[key], 0, Config.SUPPLY[key]):
			return failure("剩余构件数量无效。")
	if not fields(s.actor, ["x", "z", "angle"]) or not number(s.actor.x, -31.7, 31.7) or not number(s.actor.z, -31.7, 31.7) or not number(s.actor.angle, -PI, PI):
		return failure("人物位置或朝向无效。")
	if not s.entities is Array or s.entities.size() > 302:
		return failure("设备列表无效或超出本包供给。")
	var model := NewModel.new()
	var seen := {}
	var active_batches := {}
	var output_batches := {}
	model.discovery = s.discovery.duplicate(true)
	for source in s.entities:
		var valid := validate_power_entity(source, s.next_id, s.next_batch, model)
		if not valid.ok:
			return valid
		if seen.has(source.id):
			return failure("实例 ID 重复。")
		seen[source.id] = true
		var placed := model.place(source.type, Vector2i(source.x, source.z), int(source.dir))
		if not placed.ok:
			return failure("设备布局无效：" + placed.reason)
		var e: Dictionary = placed.entity
		e.merge(source.duplicate(true), true)
		for key in ["id", "x", "z", "dir", "cursor", "batch", "active_batch", "output_batch", "power_node_id"]:
			if e.has(key):
				e[key] = int(e[key])
		if e.type == "belt":
			e.entry = Vector2i(source.entry[0], source.entry[1])
		for key in ["buffer", "input", "output", "invested", "items"]:
			if e.has(key):
				e[key] = normalize_items(e[key])
		if e.type == "reactor" and e.processing:
			if active_batches.has(e.active_batch):
				return failure("在制批次重复。")
			active_batches[e.active_batch] = true
		var batch := int(e.output_batch) if e.type == "reactor" and not e.output.is_empty() else int(e.batch) if e.type == "belt" else 0
		if batch > 0:
			var item: String = e.output.keys()[0] if e.type == "reactor" else e.cargo
			var amount: int = NewModel.Items.count(e.output) if e.type == "reactor" else 1
			var limit := (3 if e.recipe_id == "rich_catalyst" else 1) if e.type == "reactor" else (3 if item == "catalyst" and model.discovery.trial_completed else 1)
			var record: Dictionary = output_batches.get(batch, {"item": item, "count": 0, "limit": limit})
			if record.item != item:
				return failure("同批次混入不同产物。")
			record.count += amount
			record.limit = mini(record.limit, limit)
			output_batches[batch] = record
	for batch in output_batches:
		if active_batches.has(batch) or output_batches[batch].count > output_batches[batch].limit:
			return failure("批次既在制又出料，或多件输出超额。")
	model.rebuild_indexes()
	for key in s.kits:
		if s.kits[key] != model.kits[key]:
			return failure("剩余构件与在场设备不守恒。")
	model.bag = normalize_items(s.bag)
	model.actor.merge(s.actor, true)
	if model.blocked_for_actor(model.actor.x, model.actor.z):
		return failure("人物被保存在设备阻挡中。")
	model.time = float(s.time)
	model.remainder = float(s.remainder)
	for key in ["next_id", "next_batch", "generated", "completed", "delivered", "delivered_batch"]:
		model.set(key, int(s[key]))
	model.power_links = s.power_links.duplicate(true)
	var last_a := 0
	var last_b := 0
	for pair in model.power_links:
		if not pair is Array or pair.size() != 2 or not integer(pair[0], 1, model.next_id - 1) or not integer(pair[1], 1, model.next_id - 1) or pair[0] >= pair[1]:
			return failure("电网连接格式无效。")
		if pair[0] < last_a or (pair[0] == last_a and pair[1] <= last_b):
			return failure("电网连接未规范排序或重复。")
		pair[0] = int(pair[0])
		pair[1] = int(pair[1])
		last_a = int(pair[0])
		last_b = int(pair[1])
		if not NewModel.Grid.is_node(model.by_id(pair[1])) or not NewModel.Grid.connection(model, pair[0], pair[1]).ok:
			return failure("电网连接端点、距离或地形无效。")
	for e in model.entities:
		if e.get("power_node_id", 0) != 0 and not NewModel.Grid.connection(model, e.power_node_id, e.id).ok:
			return failure("用电接入无效。")
	var stats := Validator.validate(s.statistics, model.time, model)
	if not stats.ok:
		return stats
	model.statistics.restore(s.statistics)
	model.statistics_ui = s.statistics_ui.duplicate(true)
	model.statistics_ui.window_seconds = int(model.statistics_ui.window_seconds)
	model.grid.rebuild(model)
	return {"ok": true, "model": model, "document": value}


static func validate_power_entity(e: Variant, next_id: int, next_batch: int, model: RefCounted) -> Dictionary:
	if not e is Dictionary or not e.has("type") or not e.type is String:
		return failure("设备对象无效。")
	if not Config.CATALOG.has(e.type):
		return failure("未知设备类型。", true)
	var extra: Array = {
		"collector": ["mineral", "buffer", "progress", "power_node_id"],
		"reactor": ["recipe_id", "input", "output", "invested", "processing", "progress", "active_batch", "output_batch", "power_node_id"],
		"storage": ["items"], "belt": ["cargo", "progress", "entry", "cursor", "batch"],
		"power_source": ["enabled"], "power_junction": [],
	}[e.type]
	if not fields(e, ["id", "type", "x", "z", "dir"] + extra) or not integer(e.id, 1, next_id - 1) or not integer(e.x, -32, 31) or not integer(e.z, -32, 31) or not integer(e.dir, 0, 3):
		return failure("设备字段、身份或位置无效。")
	if e.type != "belt" and e.dir != 0:
		return failure("本版本不支持设备旋转。")
	if e.type == "power_source" and not e.enabled is bool:
		return failure("电源开关必须是布尔值。")
	if e.type in ["collector", "reactor"] and not integer(e.power_node_id, 0, next_id - 1):
		return failure("设备电力接入无效。")
	match e.type:
		"collector":
			var mineral := "crystal" if e.x < 4 else "rich_crystal"
			if e.mineral != mineral or not bounded_items(e.buffer, {mineral: 50}) or not number(e.progress, 0, 1) or e.progress >= 1:
				return failure("矿物、缓冲或采集进度无效。")
		"reactor":
			if not e.recipe_id is String or not Config.RECIPES.has(e.recipe_id):
				return failure("未知配方。", true)
			if not model.recipe_available(e.recipe_id) and not (e.recipe_id == "solvent_trial" and model.discovery.trial_completed):
				return failure("配方尚未解锁。")
			var recipe: Dictionary = Config.RECIPES[e.recipe_id]
			if not bounded_items(e.input, recipe.input) or not bounded_items(e.output, recipe.output) or not Validator.items(e.invested, 3) or not e.processing is bool or not number(e.progress, 0, recipe.seconds) or e.progress >= recipe.seconds:
				return failure("配方缓冲、在制或进度无效。")
			if not integer(e.active_batch, 0, next_batch - 1) or not integer(e.output_batch, 0, next_batch - 1):
				return failure("批次序号无效。")
			if e.processing:
				if not model.recipe_available(e.recipe_id) or e.active_batch == 0 or not e.output.is_empty() or normalize_items(e.invested) != recipe.input:
					return failure("加工中批次、原投入或缓冲矛盾。")
			elif e.progress != 0 or e.active_batch != 0 or not e.invested.is_empty():
				return failure("空闲设备含在制状态。")
			if not e.output.is_empty() and e.output_batch == 0:
				return failure("产物缺少批次。")
			# D2-A kept the last output batch on an empty reactor. It is harmless
			# provenance, still accepted without rewriting older schema 2 worlds.
		"storage":
			if not Validator.items(e.items, 200) or NewModel.Items.count(e.items) > 200:
				return failure("仓储物料或容量无效。")
		"belt":
			if not e.cargo is String or e.cargo not in ["", "crystal", "catalyst", "crust_solvent", "rich_crystal"]:
				return failure("传送带物料无效，样本只能显式取放。")
			if e.cargo in ["crystal", "rich_crystal"] and e.batch != 0:
				return failure("原矿不能带有加工批次。")
			if e.cargo in ["catalyst", "crust_solvent"] and not integer(e.batch, 1, next_batch - 1):
				return failure("加工产物缺少批次。")
			var shadow: Dictionary = e.duplicate(true)
			if e.cargo == "rich_crystal":
				shadow.cargo = "crystal"
			if e.cargo == "crust_solvent":
				shadow.cargo = "catalyst"
			return V1.validate_entity(shadow, next_id, next_batch)
	return {"ok": true}


static func bounded_items(value: Variant, limits: Dictionary) -> bool:
	if not Validator.items(value, 200):
		return false
	for item in value:
		if value[item] > limits.get(item, 0):
			return false
	return true
