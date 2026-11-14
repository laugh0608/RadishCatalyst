extends "res://scripts/factory/save/codec_v1.gd"

const V7 := preload("res://scripts/factory/save/codec_v7.gd")


static func snapshot(model: RefCounted, id: String, title: String, sequence: int) -> Dictionary:
	var doc := V7.snapshot(model, id, title, sequence)
	doc.save_schema_version = 8
	doc.ruleset_id = V7.Energy.STANDBY_RULESET_ID
	return doc


static func decode(value: Variant, expected_id: String) -> Dictionary:
	if not value is Dictionary: return failure("存档必须是对象。")
	if value.get("world_kind") != "factory_3d" or value.get("save_schema_version") != 8 or value.get("ruleset_id") != V7.Energy.STANDBY_RULESET_ID or value.get("map_id") != V7.V6.Expansion.MAP_ID or value.get("supply_id") != V7.Energy.SUPPLY_ID:
		return failure("不支持的待机耗电世界、规则、地图或供给组合。", true)
	return V7.V6.decode_content(value, expected_id, V7.EnergyModel.new(true), true)


## Historical energy remains work energy. Standby starts at this explicit copy.
static func copy_from(source: Dictionary, id: String, title: String, source_hash: String) -> Dictionary:
	var valid: Dictionary
	if source.get("save_schema_version") == 6:
		valid = V7.copy_from_e1(source, id, title, source_hash)
	elif source.get("save_schema_version") == 7:
		valid = V7.decode(source, str(source.get("world_id", "")))
	else:
		return failure("只能从有效 E1 或旧 E2 复制待机耗电新版。")
	if not valid.ok: return valid
	if id == source.world_id: return failure("新版能源世界必须使用独立身份。")
	var model: RefCounted = valid.model
	model.standby_power = true
	model.energy_origin = {"source_id": source.world_id, "source_sequence": source.sequence, "source_sha256": source_hash}
	var history: Dictionary = model.statistics.snapshot()
	for r in [history.totals] + history.buckets + [history.current]: r.standby_kj = 0.0
	model.statistics = model.EnergyStatistics.new(true)
	model.statistics.restore(history)
	return decode(snapshot(model, id, title, 1), id)
