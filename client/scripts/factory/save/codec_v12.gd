extends "res://scripts/factory/save/codec_v1.gd"

const V11 := preload("res://scripts/factory/save/codec_v11.gd")
const StorageModel := preload("res://scripts/factory/grid_storage_model.gd")
const Buffer := StorageModel.Buffer
const VERSION := 12
const PIN := "19120c8ce903a5372591c89d7e0591f159181a916d056dabc738146d1813eb71"


static func definitions_sha256() -> String:
	var research := Buffer.NODE.duplicate()
	research.erase("name")
	research.erase("effect")
	return JSON.stringify({"core_iii": V11.definitions_sha256(), "buffer": {
		"capacity_j": Buffer.CAPACITY_J, "power_kw": [Buffer.CHARGE_KW, Buffer.DISCHARGE_KW],
		"charge": [Buffer.CHARGE_INPUT_J, Buffer.CHARGE_STORED_J],
		"footprint": [Buffer.SHAPE.w, Buffer.SHAPE.d],
		"assembly": [Buffer.ASSEMBLY_PACKS, Buffer.ASSEMBLY_CELLS], "research": research}},
		"", true, true).sha256_text()


static func snapshot(model: RefCounted, id: String, title: String, sequence: int) -> Dictionary:
	var doc := V11.snapshot(model, id, title, sequence)
	doc.save_schema_version = VERSION
	doc.ruleset_id = Buffer.RULESET_ID
	doc.definitions_sha256 = definitions_sha256()
	return doc


static func decode(value: Variant, expected_id: String) -> Dictionary:
	if not value is Dictionary:
		return failure("存档必须是对象。")
	if value.get("world_kind") != "factory_3d" or value.get("save_schema_version") != VERSION or value.get("ruleset_id") != Buffer.RULESET_ID or value.get("map_id") != V11.V10.Frontier.MAP_ID or value.get("supply_id") != Buffer.SUPPLY_ID:
		return failure("不支持的储能工厂身份。", true)
	if value.get("definitions_sha256") != PIN or definitions_sha256() != PIN:
		return failure("储能工厂定义摘要不匹配。", true)
	return V11.V10.V9.decode_state(value, expected_id, StorageModel.new())
