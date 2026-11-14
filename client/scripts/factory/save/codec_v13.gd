extends "res://scripts/factory/save/codec_v1.gd"

const V12 := preload("res://scripts/factory/save/codec_v12.gd")
const TimedModel := preload("res://scripts/factory/timed_dispatch_model.gd")
const Dispatch := TimedModel.Dispatch
const VERSION := 13
const PIN := "9afe51348819c33eb2fe6008e01dc11803b6fa06d10db223baf4371a3e7d40a6"


static func definitions_sha256() -> String:
	var research := Dispatch.NODE.duplicate()
	research.erase("name")
	research.erase("effect")
	return JSON.stringify({"storage": V12.definitions_sha256(), "dispatch": {
		"footprint": [Dispatch.SHAPE.w, Dispatch.SHAPE.d],
		"schedule": [Dispatch.TICKS_PER_SECOND, Dispatch.DEPARTURE_INTERVAL, Dispatch.MIN_PERIOD_S, Dispatch.MAX_PERIOD_S, Dispatch.MAX_QUOTA],
		"assembly": Dispatch.ASSEMBLY_PACKS, "research": research}}, "", true, true).sha256_text()


static func snapshot(model: RefCounted, id: String, title: String, sequence: int) -> Dictionary:
	var doc := V12.snapshot(model, id, title, sequence)
	doc.save_schema_version = VERSION
	doc.ruleset_id = Dispatch.RULESET_ID
	doc.definitions_sha256 = definitions_sha256()
	return doc


static func decode(value: Variant, expected_id: String) -> Dictionary:
	if not value is Dictionary:
		return failure("存档必须是对象。")
	if value.get("world_kind") != "factory_3d" or value.get("save_schema_version") != VERSION or value.get("ruleset_id") != Dispatch.RULESET_ID or value.get("map_id") != V12.V11.V10.Frontier.MAP_ID or value.get("supply_id") != Dispatch.SUPPLY_ID:
		return failure("不支持的节拍调度工厂身份。", true)
	if value.get("definitions_sha256") != PIN or definitions_sha256() != PIN:
		return failure("节拍调度工厂定义摘要不匹配。", true)
	return V12.V11.V10.V9.decode_state(value, expected_id, TimedModel.new())
