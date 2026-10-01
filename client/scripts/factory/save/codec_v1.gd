extends RefCounted

const Model := preload("res://scripts/factory/model.gd")
const Rules := Model.Rules
const SCHEMA := 1
const MAX_NUMBER := 9007199254740991
const TOP_FIELDS := ["world_kind", "save_schema_version", "ruleset_id", "map_id",
	"supply_id", "world_id", "name", "sequence", "state"]
const STATE_FIELDS := ["time", "remainder", "next_id", "next_batch", "generated",
	"completed", "delivered", "delivered_batch", "kits", "bag", "actor", "entities"]


static func failure(reason: String, unsupported := false) -> Dictionary:
	return {"ok": false, "reason": reason, "unsupported": unsupported}


static func valid_id(value: Variant) -> bool:
	if not value is String or value.length() != 32:
		return false
	for c in value:
		if c not in "0123456789abcdef":
			return false
	return true


static func integer(value: Variant, low := 0, high := MAX_NUMBER) -> bool:
	return (value is int or value is float) and is_finite(value) and value == floor(value) and value >= low and value <= high


static func number(value: Variant, low: float, high: float) -> bool:
	return (value is int or value is float) and is_finite(value) and value >= low and value <= high


static func fields(value: Variant, names: Array) -> bool:
	if not value is Dictionary or value.size() != names.size():
		return false
	for key in names:
		if not value.has(key):
			return false
	return true


static func snapshot(model: RefCounted, id: String, title: String, sequence: int) -> Dictionary:
	var entities: Array = []
	for source in model.entities:
		var e: Dictionary = source.duplicate(true)
		if e.type == "belt":
			e.entry = [e.entry.x, e.entry.y]
		entities.append(e)
	return {
		"world_kind": "factory_3d", "save_schema_version": SCHEMA,
		"ruleset_id": Rules.RULESET_ID, "map_id": Rules.MAP_ID,
		"supply_id": model.supply_id, "world_id": id, "name": title, "sequence": sequence,
		"state": {
			"time": model.time, "remainder": model.remainder, "next_id": model.next_id,
			"next_batch": model.next_batch, "generated": model.generated,
			"completed": model.completed, "delivered": model.delivered,
			"delivered_batch": model.delivered_batch, "kits": model.kits.duplicate(),
			"bag": model.bag.duplicate(),
			"actor": {"x": model.actor.x, "z": model.actor.z, "angle": model.actor.angle},
			"entities": entities,
		}
	}


static func decode(value: Variant, expected_id: String) -> Dictionary:
	if not value is Dictionary:
		return failure("存档必须是对象。")
	# Unsupported versions are fatal even when an older backup exists.
	if value.has("save_schema_version") and integer(value.save_schema_version) and value.save_schema_version > SCHEMA:
		return failure("此工厂来自更新版本，当前版本不能读取。", true)
	for pair in [["ruleset_id", Rules.RULESET_ID], ["map_id", Rules.MAP_ID]]:
		if value.has(pair[0]) and value[pair[0]] != pair[1]:
			return failure("不支持的工厂规则或地图版本。", true)
	if not fields(value, TOP_FIELDS) or value.world_kind != "factory_3d" or value.save_schema_version != SCHEMA:
		return failure("不是受支持的工厂存档，或字段不完整。")
	if not valid_id(value.world_id) or value.world_id != expected_id:
		return failure("存档身份与世界目录不一致。")
	if not value.name is String or value.name.strip_edges().is_empty() or value.name.length() > 48 or "\n" in value.name:
		return failure("世界名称无效。")
	if not integer(value.sequence, 1) or not value.supply_id is String or not Rules.SUPPLIES.has(value.supply_id):
		return failure("存档序号或构件供给版本无效。")
	var s: Variant = value.state
	if not fields(s, STATE_FIELDS):
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
	if not fields(s.kits, Rules.CATALOG.keys()) or not fields(s.bag, ["crystal", "catalyst"]):
		return failure("构件或回收箱字段无效。")
	for key in s.kits:
		if not integer(s.kits[key], 0, Rules.SUPPLIES[value.supply_id][key]):
			return failure("剩余构件数量无效。")
	if not integer(s.bag.crystal, 0, 200) or not integer(s.bag.catalyst, 0, 200) or s.bag.crystal + s.bag.catalyst > 200:
		return failure("回收箱数量超出容量。")
	if not fields(s.actor, ["x", "z", "angle"]) or not number(s.actor.x, -31.7, 31.7) or not number(s.actor.z, -31.7, 31.7) or not number(s.actor.angle, -PI, PI):
		return failure("人物位置或朝向无效。")
	if not s.entities is Array or s.entities.size() > 1100:
		return failure("设备列表无效或超出本包供给。")
	var model := Model.new(value.supply_id)
	var seen := {}
	var active_batches := {}
	for source in s.entities:
		var valid := validate_entity(source, s.next_id, s.next_batch)
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
		for key in ["id", "x", "z", "dir", "buffer", "input", "output", "crystal", "catalyst", "cursor", "batch", "active_batch", "output_batch"]:
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
	return {"ok": true, "model": model, "document": value}


static func validate_entity(e: Variant, next_id: int, next_batch: int) -> Dictionary:
	if not e is Dictionary or not e.has("type") or not e.type is String or not Rules.CATALOG.has(e.type):
		return failure("未知设备类型。")
	var extra: Array = {
		"collector": ["buffer", "progress"],
		"reactor": ["input", "output", "processing", "progress", "active_batch", "output_batch"],
		"storage": ["crystal", "catalyst"],
		"belt": ["cargo", "progress", "entry", "cursor", "batch"],
	}[e.type]
	if not fields(e, ["id", "type", "x", "z", "dir"] + extra):
		return failure("设备字段不完整或含未知字段。")
	if not integer(e.id, 1, next_id - 1) or not integer(e.x, -32, 31) or not integer(e.z, -32, 31) or not integer(e.dir, 0, 3):
		return failure("实例身份、位置或方向无效。")
	if e.type != "belt" and e.dir != 0:
		return failure("本版本不支持设备旋转。")
	match e.type:
		"collector":
			if not integer(e.buffer, 0, 50) or not number(e.progress, -1e-8, 1 - 1e-8):
				return failure("采集器缓冲或进度无效。")
		"reactor":
			if not integer(e.input, 0, 2) or not integer(e.output, 0, 1) or not e.processing is bool or not number(e.progress, 0, 10 - 1e-8):
				return failure("反应器缓冲或进度无效。")
			if not integer(e.active_batch, 0, next_batch - 1) or not integer(e.output_batch, 0, next_batch - 1):
				return failure("反应器批次无效。")
			if e.processing and (e.active_batch == 0 or e.output != 0):
				return failure("加工中批次与缓冲不一致。")
			if not e.processing and (e.progress != 0 or e.active_batch != 0):
				return failure("空闲反应器仍有加工状态。")
			if e.output > 0 and e.output_batch == 0:
				return failure("反应器产物缺少批次。")
		"storage":
			if not integer(e.crystal, 0, 200) or not integer(e.catalyst, 0, 200) or e.crystal + e.catalyst > 200:
				return failure("终端仓超容量。")
		"belt":
			if not e.cargo is String or e.cargo not in ["", "crystal", "catalyst"] or not number(e.progress, 0, 1):
				return failure("带上物品或进度无效。")
			if not e.entry is Array or e.entry.size() != 2 or not integer(e.entry[0], -1, 1) or not integer(e.entry[1], -1, 1):
				return failure("货物入口方向无效。")
			var entry := Vector2i(e.entry[0], e.entry[1])
			if entry not in Model.DIRS or entry == Model.DIRS[int(e.dir)]:
				return failure("货物入口与带出口冲突。")
			if not integer(e.cursor, 0, next_id - 1) or not integer(e.batch, 0, next_batch - 1):
				return failure("带汇流游标或批次无效。")
			if e.cargo == "" and (e.progress != 0 or e.batch != 0):
				return failure("空带仍有货物状态。")
			# Manually recycled catalysts lose batch provenance, represented by zero.
			if e.cargo == "crystal" and e.batch != 0:
				return failure("晶体不能带有催化剂批次。")
	return {"ok": true}
