extends "res://scripts/factory/save/codec_v1.gd"

const V1 := preload("res://scripts/factory/save/codec_v1.gd")
const NewModel := preload("res://scripts/factory/discovery_model.gd")
const Config := preload("res://data/factory/discovery_rules.gd")
const Validator := preload("res://scripts/factory/save/statistics_validator.gd")


static func item_map(crystal: int, catalyst := 0) -> Dictionary:
	var result := {}
	if crystal > 0:
		result.crystal = crystal
	if catalyst > 0:
		result.catalyst = catalyst
	return result


static func snapshot(model: RefCounted, id: String, title: String, sequence: int) -> Dictionary:
	var doc := V1.snapshot(model, id, title, sequence)
	doc.save_schema_version = 2
	doc.ruleset_id = Config.RULESET_ID
	doc.map_id = Config.MAP_ID
	var s: Dictionary = doc.state
	s.bag = item_map(model.bag.crystal, model.bag.catalyst)
	for e in s.entities:
		match e.type:
			"collector":
				e.mineral = "crystal"
				e.buffer = item_map(e.buffer)
			"reactor":
				e.recipe_id = "basic_catalyst"
				e.input = item_map(e.input)
				e.output = item_map(0, e.output)
				e.invested = item_map(2 if e.processing else 0)
			"storage":
				e.items = item_map(e.crystal, e.catalyst)
				e.erase("crystal")
				e.erase("catalyst")
	s.power_links = model.power_links.duplicate(true)
	s.discovery = model.discovery.duplicate(true)
	s.statistics = model.statistics.snapshot()
	s.statistics_ui = model.statistics_ui.duplicate(true)
	return doc


static func unpack_state(value: Variant) -> Dictionary:
	if not fields(value, STATE_FIELDS + ["power_links", "discovery", "statistics", "statistics_ui"]):
		return failure("联合工厂状态字段无效。")
	var s: Dictionary = value.duplicate(true)
	if not fields(s.discovery, ["surveyed", "sample_taken", "trial_completed", "passages"]) or not fields(s.discovery.passages, ["outer", "inner"]):
		return failure("发现状态字段无效。")
	for flag in [s.discovery.surveyed, s.discovery.sample_taken, s.discovery.trial_completed, s.discovery.passages.outer, s.discovery.passages.inner]:
		if not flag is bool:
			return failure("发现状态必须是布尔值。")
		if flag:
			return failure("当前版本尚不能运行多配方与开拓状态。", true)
	if not s.power_links is Array or s.power_links.size() > 91:
		return failure("电力连接列表超限。")
	if not fields(s.statistics_ui, ["window_seconds", "favorites"]) or not integer(s.statistics_ui.window_seconds) or int(s.statistics_ui.window_seconds) not in [60, 300, 600] or not s.statistics_ui.favorites is Array:
		return failure("统计偏好无效。")
	var favorites := {}
	for item in s.statistics_ui.favorites:
		if item not in ["crystal", "catalyst"] or favorites.has(item):
			return failure("收藏物料未知或重复。")
		favorites[item] = true
	var bag_result := unpack_items(s.bag)
	if not bag_result.ok:
		return bag_result
	s.bag = bag_result.items
	if not s.entities is Array:
		return failure("设备列表无效。")
	for e in s.entities:
		if not e is Dictionary or not e.has("type"):
			return failure("设备无效。")
		match e.type:
			"collector":
				if not e.has_all(["mineral", "buffer"]):
					return failure("采集器字段不完整。")
				if e.mineral != "crystal":
					return failure("当前版本尚不能运行此矿物。", true)
				var items := unpack_items(e.buffer)
				if not items.ok:
					return items
				if items.items.catalyst != 0:
					return failure("普通采集器含非矿物缓冲。")
				e.buffer = items.items.crystal
				e.erase("mineral")
			"reactor":
				if not e.has_all(["recipe_id", "input", "output", "invested", "processing"]):
					return failure("反应器字段不完整。")
				if e.recipe_id != "basic_catalyst":
					return failure("当前版本尚不能运行此配方。", true)
				for key in ["input", "output", "invested"]:
					var items := unpack_items(e[key])
					if not items.ok:
						return items
					if (key == "output" and items.items.crystal != 0) or (key != "output" and items.items.catalyst != 0):
						return failure("配方缓冲物料无效。")
					e[key] = items.items.catalyst if key == "output" else items.items.crystal
				if not e.processing is bool or e.invested != (2 if e.processing else 0):
					return failure("在制原投入不一致。")
				e.erase("invested")
				e.erase("recipe_id")
			"storage":
				if not e.has("items") or e.has("crystal") or e.has("catalyst"):
					return failure("仓储字段无效。")
				var items := unpack_items(e.items)
				if not items.ok:
					return items
				e.merge(items.items)
				e.erase("items")
	return {"ok": true, "state": s}


static func unpack_items(value: Variant) -> Dictionary:
	if not Validator.items(value, 200):
		return failure("物料映射包含非法数量或未知物品。")
	for item in value:
		if item not in ["crystal", "catalyst"]:
			return failure("当前版本尚不能运行此发现物料。", true)
	return {"ok": true, "items": {"crystal": value.get("crystal", 0), "catalyst": value.get("catalyst", 0)}}


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
	if s.completed >= s.next_batch or s.delivered > s.completed or s.delivered_batch >= s.next_batch:
		return failure("生产统计与批次序列不一致。")
	if not fields(s.kits, Config.CATALOG.keys()) or not fields(s.bag, ["crystal", "catalyst"]):
		return failure("构件或回收箱字段无效。")
	for key in s.kits:
		if not integer(s.kits[key], 0, Config.SUPPLY[key]):
			return failure("剩余构件数量无效。")
	if not integer(s.bag.crystal, 0, 200) or not integer(s.bag.catalyst, 0, 200) or s.bag.crystal + s.bag.catalyst > 200:
		return failure("回收箱数量超出容量。")
	if not fields(s.actor, ["x", "z", "angle"]) or not number(s.actor.x, -31.7, 31.7) or not number(s.actor.z, -31.7, 31.7) or not number(s.actor.angle, -PI, PI):
		return failure("人物位置或朝向无效。")
	if not s.entities is Array or s.entities.size() > 302:
		return failure("设备列表无效或超出本包供给。")
	var model := NewModel.new()
	var seen := {}
	var active_batches := {}
	for source in s.entities:
		var valid := validate_power_entity(source, s.next_id, s.next_batch)
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
		for key in ["id", "x", "z", "dir", "buffer", "input", "output", "crystal", "catalyst", "cursor", "batch", "active_batch", "output_batch", "power_node_id"]:
			if e.has(key):
				e[key] = int(e[key])
		if e.type == "belt":
			e.entry = Vector2i(source.entry[0], source.entry[1])
		var batch := int(e.active_batch) if e.type == "reactor" and e.processing else 0
		if e.type == "reactor" and e.output > 0:
			batch = e.output_batch
		if e.type == "belt" and e.cargo == "catalyst":
			batch = e.batch
		if batch > 0:
			if active_batches.has(batch):
				return failure("在途或加工批次重复。")
			active_batches[batch] = true
	model.rebuild_indexes()
	for key in s.kits:
		if s.kits[key] != model.kits[key]:
			return failure("剩余构件与在场设备不守恒。")
	model.bag = {"crystal": int(s.bag.crystal), "catalyst": int(s.bag.catalyst)}
	model.actor.merge(s.actor, true)
	if model.blocked_for_actor(model.actor.x, model.actor.z):
		return failure("人物被保存在设备阻挡中。")
	model.time = float(s.time)
	model.remainder = float(s.remainder)
	for key in ["next_id", "next_batch", "generated", "completed", "delivered", "delivered_batch"]:
		model.set(key, int(s[key]))
	var balance: Dictionary = model.material_balance()
	if balance.catalyst != model.completed:
		return failure("完成批次与现存催化剂不守恒。")
	if balance.equivalent != model.generated:
		return failure("存档物料不守恒。")
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


static func validate_power_entity(e: Variant, next_id: int, next_batch: int) -> Dictionary:
	if not e is Dictionary or not e.has("type"):
		return failure("设备对象无效。")
	if e.type in ["power_source", "power_junction"]:
		var extra := ["enabled"] if e.type == "power_source" else []
		if not fields(e, ["id", "type", "x", "z", "dir"] + extra) or not integer(e.id, 1, next_id - 1) or not integer(e.x, -32, 31) or not integer(e.z, -32, 31) or not integer(e.dir, 0, 0):
			return failure("电力设备字段无效。")
		if e.type == "power_source" and not e.enabled is bool:
			return failure("电源启用状态必须为布尔值。")
		return {"ok": true}
	var base: Dictionary = e.duplicate(true)
	if e.type in ["collector", "reactor"]:
		if not e.has("power_node_id") or not integer(e.power_node_id, 0, next_id - 1):
			return failure("用电接入 ID 无效。")
		base.erase("power_node_id")
		var cycle: float = Config.CYCLE[e.type]
		if not base.has("progress") or not number(base.progress, 0, cycle) or base.progress >= cycle:
			return failure("加工进度必须有限、非负且严格小于周期。")
		if e.type == "reactor" and not base.get("processing", false) and base.progress != 0:
			return failure("空闲反应器仍有加工进度。")
		# Validate fractional powered progress above; the legacy check deliberately
		# retains its original fixed-speed epsilon bounds. Do not rewrite the state.
		base.progress = 0.0
	return V1.validate_entity(base, next_id, next_batch)
